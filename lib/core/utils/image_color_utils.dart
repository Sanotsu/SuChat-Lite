import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../shared/widgets/toast_utils.dart';
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
}
