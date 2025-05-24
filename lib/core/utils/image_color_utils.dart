import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:palette_generator/palette_generator.dart';

import '../../shared/widgets/toast_utils.dart';
import '../../shared/constants/constants.dart';
import 'screen_helper.dart';
import 'simple_tools.dart';

/// 在隔离线程中提取图像主色调的辅助类
class ImageColorUtils {
  /// 从图像文件中提取主色调
  /// 此方法可以安全地在compute函数中调用，不依赖Flutter绑定
  static Future<Color> extractDominantColor(String imagePath) async {
    try {
      // 使用compute函数在隔离线程中执行
      // 注意里面不要使用UI相关内容，toast等，因为这里是隔离线程
      return await compute(_isolateExtractColor, imagePath);
    } catch (e) {
      // 主线程中就可以使用UI相关
      try {
        // 如果使用compute失败，在主线程中尝试处理

        final file =
            imagePath.startsWith('assets')
                ? (await getImageFileFromAssets(imagePath))
                : File(imagePath);
        if (!file.existsSync()) {
          ToastUtils.showError('文件不存在: $e');

          return Colors.blueGrey.shade100;
        }

        final bytes = await file.readAsBytes();
        final image = img.decodeImage(bytes);
        if (image == null) {
          ToastUtils.showError('图像解码失败: $e');

          return Colors.blueGrey.shade100;
        }

        return _calculateColor(image);
      } catch (e) {
        ToastUtils.showError('主线程处理图片失败: $e');
        return Colors.blueGrey.shade100;
      }
    }
  }

  /// 在隔离线程中运行的函数
  static Color _isolateExtractColor(String imagePath) {
    try {
      // 如果是移动端、且使用内置的图片，直接返回默认颜色
      // 因为移动端不能直接访问assets，但桌面端可以
      if (ScreenHelper.isMobile() && imagePath.startsWith('assets')) {
        return Colors.blueGrey.shade100;
      }

      final bytes = File(imagePath).readAsBytesSync();
      final image = img.decodeImage(bytes);
      if (image == null) {
        // Colors.blueGrey.shade100的值
        return const Color(0xFFCFD8DC);
      }
      return _calculateColor(image);
    } catch (e) {
      debugPrint('隔离线程处理图片失败: $e');
      return const Color(0xFFCFD8DC);
    }
  }

  /// 计算图像的平均颜色
  static Color _calculateColor(img.Image image) {
    // 缩小图像以提高性能
    final resizedImage = img.copyResize(
      image,
      width: 100,
      height: 100,
      interpolation: img.Interpolation.average,
    );

    int r = 0, g = 0, b = 0;
    int pixelCount = 0;

    // 遍历图像像素
    for (int y = 0; y < resizedImage.height; y++) {
      for (int x = 0; x < resizedImage.width; x++) {
        // 获取像素颜色
        final pixel = resizedImage.getPixel(x, y);

        // 累加RGB值
        r += pixel.r.toInt();
        g += pixel.g.toInt();
        b += pixel.b.toInt();
        pixelCount++;
      }
    }

    if (pixelCount == 0) {
      return const Color(0xFFCFD8DC);
    }

    // 计算平均颜色
    final avgR = (r / pixelCount).round();
    final avgG = (g / pixelCount).round();
    final avgB = (b / pixelCount).round();

    // 返回颜色
    return Color.fromARGB(255, avgR, avgG, avgB);
  }

  /// 2025-04-14 这个方法的两种实现都需要Flutter的绑定环境的API
  // 但是隔离线程isolate中不存在Flutter的绑定环境，所以这个方法不能放在隔离线程中
  static Future<Color> getImageDominantColor(String imagePath) async {
    ImageProvider imageProvider =
        imagePath.isEmpty
            ? AssetImage(defaultAvatarUrl)
            : imagePath.startsWith('http')
            ? NetworkImage(imagePath)
            : imagePath.startsWith('assets/')
            ? AssetImage(imagePath)
            : FileImage(File(imagePath));

    // 下面两种方法看起来得到的差不多
    try {
      /// 使用工具快速获取主色调
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        size: Size(100, 100), // 缩小图片以加快处理速度
      );
      // PaletteGenerator 提供了多种预定义的颜色分类，适合不同 UI 设计场景：
      // 属性	说明	示例用途
      // dominantColor	    图片中最突出的颜色（基于像素频率和视觉显著性）	 页面主色调、标题背景
      // lightVibrantColor	明亮且鲜艳的颜色（适合文字/图标）	            浅色模式下的按钮文字
      // vibrantColor	      中等亮度的鲜艳颜色（平衡可读性和视觉冲击）	    强调按钮、标签
      // darkVibrantColor	  深色且鲜艳的颜色（适合深色主题）	            深色模式下的强调色
      // lightMutedColor	  柔和的浅色（低调不刺眼）	                  卡片背景、次要文本
      // mutedColor	        中等亮度的柔和色（自然协调）	               中性背景、边框
      // darkMutedColor	    深色且柔和的颜色（适合阴影或深色UI元素）	     底部导航栏、暗色遮罩
      return paletteGenerator.lightMutedColor?.color ?? Colors.grey;

      // 测试
      // throw Exception('获取图片主色调失败');
    } catch (e) {
      /// 直接通过 Flutter 的 dart:ui 获取像素数据
      final ImageStream stream = imageProvider.resolve(
        ImageConfiguration.empty,
      );
      final Completer<ImageInfo> completer = Completer();
      stream.addListener(
        ImageStreamListener((info, _) => completer.complete(info)),
      );
      final ImageInfo imageInfo = await completer.future;
      final ByteData? byteData = await imageInfo.image.toByteData();

      if (byteData == null) return Colors.grey;

      final Uint8List pixels = byteData.buffer.asUint8List();
      int red = 0, green = 0, blue = 0, pixelCount = 0;

      for (int i = 0; i < pixels.length; i += 4) {
        red += pixels[i];
        green += pixels[i + 1];
        blue += pixels[i + 2];
        pixelCount++;
      }

      return Color.fromRGBO(
        (red / pixelCount).round(),
        (green / pixelCount).round(),
        (blue / pixelCount).round(),
        1,
      );
    }
  }
}
