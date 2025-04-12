import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import '../../../../common/utils/screen_helper.dart';
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
      left: widget.left,
      bottom: widget.bottom,
      child: GestureDetector(
        onTap: () => _showFullScreenPreview(context),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.white, width: 2),
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
    // 使用OverlayPortal替代直接的Overlay，以便更好地处理窗口大小变化
    showDialog(
      context: context,
      barrierDismissible: true,
      useSafeArea: false, // 允许全屏显示
      builder: (BuildContext dialogContext) {
        // 实时获取屏幕尺寸，确保在窗口大小变化时能正确响应
        final screenSize = MediaQuery.of(dialogContext).size;
        
        // 计算预览窗口的尺寸
        var previewWidth = screenSize.width * 0.66;
        var previewHeight = (_imageHeight != null && _imageWidth != null)
            ? (_imageHeight! / _imageWidth!) * previewWidth
            : 16 / 9 * previewWidth;

        // 桌面端特殊处理
        if (ScreenHelper.isDesktop()) {
          previewWidth = min(screenSize.width - 280, screenSize.height) * 0.60;
          previewHeight = (_imageHeight != null && _imageWidth != null)
              ? (_imageHeight! / _imageWidth!) * previewWidth
              : 16 / 9 * previewWidth;
        }

        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              // 半透明背景，点击时关闭预览
              GestureDetector(
                onTap: () => Navigator.of(dialogContext).pop(),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  width: screenSize.width,
                  height: screenSize.height,
                ),
              ),

              // 预览窗口，放置在左下角
              Positioned(
                left: widget.left,
                bottom: widget.bottom,
                child: Container(
                  width: previewWidth,
                  height: previewHeight,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 3),
                          child: buildAvatarClipOval(
                            widget.character.avatar,
                            clipBehavior: Clip.none,
                          ),
                        ),
                      ),

                      // 关闭按钮
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
