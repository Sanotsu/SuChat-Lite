import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../constants/constants.dart';
import '../../core/utils/simple_tools.dart';
import 'simple_tool_widget.dart';
import 'toast_utils.dart';

/// 图片预览帮助
/// 各种图片预览相关的方法

/// 轮播图交互类型
enum CarouselType {
  none, // 无动作 - 单纯的轮播展示,点击图片无动作
  dialog, // 类型1 - 点击弹窗显示单张图片预览
  page, // 类型2 - 点击跳转新页面显示单张图片预览
  gallery, // 类型3 - 点击弹窗显示图片画廊(默认)
}

///
/// 构建图片轮播组件，仅仅轮播+单张点击预览，没有其他内容
///
Widget buildImageViewCarouselSlider(
  List<String> imageList, {
  double? aspectRatio,
}) {
  return CarouselSlider(
    options: CarouselOptions(
      autoPlay: true, // 自动播放
      enlargeCenterPage: true, // 居中图片放大
      aspectRatio: aspectRatio ?? 16 / 9, // 图片宽高比
      viewportFraction: 1, // 图片占屏幕宽度的比例
      // 只有一张图片时不滚动
      enableInfiniteScroll: imageList.length > 1,
    ),
    items:
        imageList.map((imageUrl) {
          return Builder(
            builder:
                (context) => GestureDetector(
                  onTap:
                      () => _handleImageTap(
                        context,
                        imageUrl,
                        imageList,
                        CarouselType.dialog,
                      ),
                  child: buildNetworkOrFileImage(imageUrl, fit: BoxFit.cover),
                ),
          );
        }).toList(),
  );
}

///
/// 构建图片轮播组件
///
Widget buildImageCarouselSlider(
  List<String> imageList, {
  bool showPlaceholder = true, // 无图片时是否显示占位图
  CarouselType type = CarouselType.gallery, // 轮播图交互类型
  double? aspectRatio,
  Directory? downloadDir, // 长按下载目录
}) {
  final items = _buildCarouselItems(
    imageList,
    // 除非指定不显示图片，否则没有图片也显示一张占位图片
    showPlaceholder: showPlaceholder,
    type: type,
    downloadDir: downloadDir,
  );

  return CarouselSlider(
    options: CarouselOptions(
      autoPlay: true, // 自动播放
      enlargeCenterPage: true, // 居中图片放大
      aspectRatio: aspectRatio ?? 16 / 9, // 图片宽高比
      viewportFraction: 1, // 图片占屏幕宽度的比例
      // 只有一张图片时不滚动
      enableInfiniteScroll: imageList.length > 1,
    ),
    items: items,
  );
}

/// 构建轮播图子项
List<Widget>? _buildCarouselItems(
  List<String> imageList, {
  required bool showPlaceholder,
  required CarouselType type,
  Directory? downloadDir,
}) {
  if (!showPlaceholder && imageList.isEmpty) return null;

  final effectiveImages = imageList.isEmpty ? [placeholderImageUrl] : imageList;

  return effectiveImages.map((imageUrl) {
    return Builder(
      builder:
          (context) => _buildCarouselItem(
            context,
            imageUrl,
            imageList,
            type: type,
            downloadDir: downloadDir,
          ),
    );
  }).toList();
}

/// 构建单个轮播图项
Widget _buildCarouselItem(
  BuildContext context,
  String imageUrl,
  List<String> imageList, {
  required CarouselType type,
  Directory? downloadDir,
}) {
  return GestureDetector(
    onTap: () => _handleImageTap(context, imageUrl, imageList, type),
    onLongPress: () => _handleImageLongPress(imageUrl, downloadDir),
    child: buildNetworkOrFileImage(imageUrl),
  );
}

/// 处理图片点击事件
void _handleImageTap(
  BuildContext context,
  String imageUrl,
  List<String> imageList,
  CarouselType type,
) {
  switch (type) {
    case CarouselType.dialog:
      showDialog(
        context: context,
        builder: (_) => _buildPhotoDialog(getImageProvider(imageUrl)),
      );
      break;
    case CarouselType.page:
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _buildPhotoView(getImageProvider(imageUrl)),
        ),
      );
      break;
    case CarouselType.gallery:
      showDialog(
        context: context,
        builder: (_) => _buildPhotoGalleryDialog(imageList),
      );
      break;
    case CarouselType.none:
      break;
  }
}

/// 处理图片长按事件
Future<void> _handleImageLongPress(
  String imageUrl,
  Directory? downloadDir,
) async {
  if (imageUrl.startsWith("/storage/")) {
    ToastUtils.showInfo("图片已存在于$imageUrl", duration: Duration(seconds: 3));
    return;
  }
  await saveImageToLocal(imageUrl, dlDir: downloadDir);
}

/// 构建图片弹窗对话框（相册和单个图片预览都有用到）
Widget _buildPhotoDialog(ImageProvider imageProvider) {
  return Dialog(
    backgroundColor: Colors.transparent,
    child: _buildPhotoView(imageProvider),
  );
}

/// 构建图片画廊弹窗
Widget _buildPhotoGalleryDialog(List<String> imageList) {
  // 这个弹窗默认是无法全屏的，上下左右会留点空，点击这些空隙可以关闭弹窗
  return Dialog(
    backgroundColor: Colors.transparent,
    child: PhotoViewGallery.builder(
      itemCount: imageList.length,
      builder:
          (context, index) => PhotoViewGalleryPageOptions(
            imageProvider: getImageProvider(imageList[index]),
            errorBuilder: (_, __, ___) => const Icon(Icons.error),
          ),
      scrollPhysics: const BouncingScrollPhysics(),
      backgroundDecoration: const BoxDecoration(color: Colors.transparent),
      loadingBuilder:
          (_, __) => const Center(child: CircularProgressIndicator()),
    ),
  );
}

/// 构建图片查看视图
Widget _buildPhotoView(
  ImageProvider imageProvider, {
  bool enableRotation = true,
}) {
  return PhotoView(
    imageProvider: imageProvider,
    // 设置图片背景为透明
    backgroundDecoration: const BoxDecoration(color: Colors.transparent),
    // 可以旋转
    enableRotation: enableRotation,
    // 缩放的最大最小限制
    minScale: PhotoViewComputedScale.contained * 0.8,
    maxScale: PhotoViewComputedScale.covered * 2,
    errorBuilder: (_, __, ___) => const Icon(Icons.error),
  );
}

/// 获取图片提供者(暂时这3种)
ImageProvider getImageProvider(String imageUrl) {
  if (imageUrl.startsWith('http')) {
    return CachedNetworkImageProvider(imageUrl);
  } else if (imageUrl.startsWith('assets')) {
    return AssetImage(imageUrl);
  } else {
    return FileImage(File(imageUrl));
  }
}

///
/// 构建图片预览组件
/// 只有base64的字符串或者文件格式
///
Widget buildImageView(
  dynamic image,
  BuildContext context, {
  bool isFileUrl = false,
  String imagePlaceholder = "请选择图片",
  String imageErrorHint = "图片异常",
}) {
  // 如果没有图片数据，直接返回文提示
  if (image == null) {
    return Center(child: Text(imagePlaceholder));
  }

  /// 获取预览图片的提供者,只有base64的字符串或者文件格式
  ImageProvider buildImageProvider(dynamic image, bool isFileUrl) {
    if (image is String && !isFileUrl) {
      return MemoryImage(base64Decode(image));
    } else if (image is String && isFileUrl) {
      return FileImage(File(image));
    } else {
      return FileImage(image as File);
    }
  }

  final imageProvider = buildImageProvider(image, isFileUrl);

  return GridTile(
    child: GestureDetector(
      onTap:
          () => showDialog(
            context: context,
            builder: (_) => _buildPhotoDialog(imageProvider),
          ),
      child: RepaintBoundary(
        child: Center(
          child: Image(
            image: imageProvider,
            fit: BoxFit.scaleDown,
            errorBuilder: (_, __, ___) => _buildErrorWidget(imageErrorHint),
          ),
        ),
      ),
    ),
  );
}

/// 构建错误提示组件
Widget _buildErrorWidget(String errorHint) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red),
          Text(errorHint, style: const TextStyle(color: Colors.red)),
        ],
      ),
    ),
  );
}

///
/// 构建网络或本地图片组件
/// 用到的地方较多
///
Widget buildNetworkOrFileImage(String imageUrl, {BoxFit? fit}) {
  if (imageUrl.startsWith('http')) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      // progressIndicatorBuilder: (context, url, progress) => Center(
      //   child: CircularProgressIndicator(
      //     value: progress.progress,
      //   ),
      // ),

      /// placeholder 和 progressIndicatorBuilder 只能2选1
      placeholder:
          (_, __) => const Center(
            child: SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(color: Colors.blue),
            ),
          ),
      errorWidget: (_, __, ___) => const Icon(Icons.error, size: 36),
    );
  } else {
    return Image(
      image: getImageProvider(imageUrl),
      fit: fit,
      errorBuilder:
          (_, __, ___) =>
              Image.asset(placeholderImageUrl, fit: BoxFit.scaleDown),
    );
  }
}

///
/// 构建文本生成的图片结果列表
/// 点击预览，长按下载
///
buildNetworkImageViewGrid(
  BuildContext context,
  List<String> urls, {
  int? crossAxisCount,
  String? prefix, // 如果有保存图片，这个可以是图片明前缀
  Directory? dlDir, // 长按下载时的文件夹
  BoxFit? fit,
}) {
  return GridView.count(
    crossAxisCount: crossAxisCount ?? 2,
    shrinkWrap: true,
    mainAxisSpacing: 5,
    crossAxisSpacing: 5,
    physics: const NeverScrollableScrollPhysics(),
    children: buildImageList(
      context,
      urls,
      prefix: prefix,
      dlDir: dlDir,
      fit: fit,
    ),
  );
}

///
/// 构建图片预览列表
///
// 2024-06-27 在小米6中此放在上面 buildNetworkImageViewGrid 没问题，但Z60U就报错；因为无法调试，错误原因不知
// 所以在文生图历史记录中点击某个记录时，不使用上面那个，而使用这个
buildImageList(
  BuildContext context,
  List<String> urls, {
  String? prefix,
  Directory? dlDir, // 长按下载时的文件夹
  BoxFit? fit,
}) {
  return List.generate(urls.length, (index) {
    return GridTile(
      child: GestureDetector(
        // 单击预览
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                backgroundColor: Colors.transparent, // 设置背景透明
                child: _buildPhotoView(getImageProvider(urls[index])),
              );
            },
          );
        },
        // 长按保存到相册
        onLongPress: () async {
          if (urls[index].startsWith("/storage/")) {
            ToastUtils.showToast("图片已保存到${urls[index]}");
            return;
          }

          // 网络图片就保存都指定位置
          await saveImageToLocal(
            urls[index],
            prefix:
                prefix == null
                    ? null
                    : (prefix.endsWith("_") ? prefix : "${prefix}_"),
            dlDir: dlDir,
          );
        },
        child: buildNetworkOrFileImage(urls[index], fit: fit ?? BoxFit.cover),
        // 默认缓存展示
        // child: SizedBox(
        //   height: 0.2.sw,
        //   child: buildNetworkOrFileImage(urls[index], fit: fit ?? BoxFit.cover),
        // ),
      ),
    );
  }).toList();
}

/// 上面那个是列表，这个是单个图片
buildImageGridTile(
  BuildContext context,
  String url, {
  String? prefix,
  BoxFit? fit,
  // 2024-09-25 不想启用长按保存和点击预览
  bool? isClickable = true,
}) {
  return GridTile(
    child:
        isClickable == true
            ? GestureDetector(
              // 单击预览
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return Dialog(
                      backgroundColor: Colors.transparent, // 设置背景透明
                      child: _buildPhotoView(getImageProvider(url)),
                    );
                  },
                );
              },
              // 长按保存到相册
              onLongPress: () async {
                if (url.startsWith("/storage/")) {
                  ToastUtils.showToast("图片已保存到$url");
                  return;
                }

                // 网络图片就保存都指定位置
                await saveImageToLocal(
                  url,
                  prefix:
                      prefix == null
                          ? null
                          : (prefix.endsWith("_") ? prefix : "${prefix}_"),
                );
              },
              // 默认缓存展示
              child: Center(
                child: buildNetworkOrFileImage(url, fit: fit ?? BoxFit.cover),
              ),
              // child: SizedBox(
              //   height: 0.2.sw,
              //   child: buildNetworkOrFileImage(url, fit: fit ?? BoxFit.cover),
              // ),
            )
            : Center(
              child: buildNetworkOrFileImage(url, fit: fit ?? BoxFit.cover),
            ),
  );
}

///
/// 显示本地路径图片，点击可弹窗显示并缩放
///
buildClickImageDialog(BuildContext context, String imageUrl) {
  return GestureDetector(
    onTap: () {
      // 在当前上下文中查找最近的 FocusScope 并使其失去焦点，从而收起键盘。
      unfocusHandle();
      // 这个直接弹窗显示图片可以缩放
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent, // 设置背景透明
            child: _buildPhotoView(FileImage(File(imageUrl))),
          );
        },
      );
    },
    child: Padding(
      padding: EdgeInsets.all(20),
      child: SizedBox(
        width: 0.8 * MediaQuery.of(context).size.width,
        child: buildNetworkOrFileImage(imageUrl),
      ),
    ),
  );
}
