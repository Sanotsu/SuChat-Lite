import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../models/brief_ai_tools/branch_chat/character_card.dart';
import '../../_chat_components/_small_tool_widgets.dart';

class CharacterAvatarPreview extends StatefulWidget {
  final CharacterCard character;
  // 头像宽度
  final double width;
  // 头像高度
  final double height;
  // 头像距离底部距离
  final double bottom;
  // 头像距离左边距离
  final double left;

  const CharacterAvatarPreview({
    super.key,
    required this.character,
    this.width = 48,
    this.height = 64,
    // 头像距离底部距离，避免遮挡输入框展开后区域
    this.bottom = 140,
    this.left = 4,
  });

  @override
  State<CharacterAvatarPreview> createState() => _CharacterAvatarPreviewState();
}

class _CharacterAvatarPreviewState extends State<CharacterAvatarPreview> {
  double? _imageWidth; // 图片宽度
  double? _imageHeight; // 图片高度

  @override
  void initState() {
    super.initState();

    _loadImageDimensions(); // 初始化时加载图片尺寸
  }

  // 加载图片尺寸
  void _loadImageDimensions() {
    final imageProvider =
        widget.character.avatar.startsWith('http')
            ? NetworkImage(widget.character.avatar) // 网络图片
            : FileImage(File(widget.character.avatar)) as ImageProvider; // 本地图片

    final stream = imageProvider.resolve(ImageConfiguration.empty);
    stream.addListener(
      ImageStreamListener(
        (ImageInfo info, bool _) {
          if (!mounted) return; // 防止组件被销毁后调用 setState
          setState(() {
            _imageWidth = info.image.width.toDouble();
            _imageHeight = info.image.height.toDouble();
          });
        },
        onError: (exception, stackTrace) {
          debugPrint('Failed to load image dimensions: $exception');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.left.sp,
      bottom: widget.bottom.sp,
      child: GestureDetector(
        onTap: () => _showFullScreenPreview(context),
        child: Container(
          width: widget.width.sp,
          height: widget.height.sp,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(2.sp),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8.sp,
                offset: Offset(0, 2.sp),
              ),
            ],
            border: Border.all(color: Colors.white, width: 2.sp),
          ),
          child: buildAvatarClipOval(
            widget.character.avatar,
            clipBehavior: Clip.none,
          ),
        ),
      ),
    );
  }

  void _showFullScreenPreview(BuildContext context) {
    // 获取屏幕尺寸
    final screenSize = MediaQuery.of(context).size;

    // // 计算预览窗口的尺寸和位置
    // final previewWidth = screenSize.width * 0.66;
    // final previewHeight = 16 / 9 * previewWidth;

    // 如果图片尺寸未加载完成，使用默认宽高
    final previewWidth = screenSize.width * 0.66;
    final previewHeight =
        (_imageHeight != null && _imageWidth != null)
            ? (_imageHeight! / _imageWidth!) * previewWidth
            : 16 / 9 * previewWidth;

    // 使用Overlay而不是Dialog，以便可以自定义位置
    final overlayState = Overlay.of(context);

    // 先声明entry变量
    late OverlayEntry entry;

    // 然后定义entry
    entry = OverlayEntry(
      builder:
          (context) => Stack(
            children: [
              // 半透明背景，点击时关闭预览
              GestureDetector(
                onTap: () => entry.remove(),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  width: screenSize.width,
                  height: screenSize.height,
                ),
              ),

              // 预览窗口，放置在左下角
              Positioned(
                left: widget.left.sp,
                bottom: widget.bottom.sp,
                child: Container(
                  width: previewWidth,
                  height: previewHeight,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    // borderRadius: BorderRadius.only(
                    //   topRight: Radius.circular(16.sp),
                    // ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Padding(
                          // 为上面关闭按钮和下面名称留出空间
                          padding: EdgeInsets.symmetric(vertical: 3.sp),
                          child: buildAvatarClipOval(
                            widget.character.avatar,
                            clipBehavior: Clip.none,
                          ),
                        ),
                      ),

                      // 关闭按钮
                      // ??? 2025-03-18 关闭按钮和角色名称是否可以不显示，改为其他互动？点击空白就关闭遮罩预览了。
                      Positioned(
                        top: 0.sp,
                        right: 0.sp,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => entry.remove(),
                        ),
                      ),

                      // 角色名称
                      // Positioned(
                      //   bottom: 8.sp,
                      //   left: 0,
                      //   right: 0,
                      //   child: Center(
                      //     child: Text(
                      //       widget.character.name,
                      //       style: TextStyle(fontSize: 12),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ],
          ),
    );

    // 显示Overlay
    overlayState.insert(entry);
  }
}
