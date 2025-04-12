import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import '../../../../common/utils/screen_helper.dart';
import '../../../../models/brief_ai_tools/branch_chat/character_card.dart';
import '../../_chat_components/_small_tool_widgets.dart';

class DraggableCharacterAvatarPreview extends StatefulWidget {
  final CharacterCard character;
  // 头像宽度
  final double width;
  // 头像高度
  final double height;
  // 头像距离底部距离
  final double bottom;
  // 头像距离左边距离
  final double left;

  const DraggableCharacterAvatarPreview({
    super.key,
    required this.character,
    this.width = 48,
    this.height = 64,
    // 头像距离底部距离，避免遮挡输入框展开后区域
    this.bottom = 140,
    this.left = 4,
  });

  @override
  State<DraggableCharacterAvatarPreview> createState() =>
      _DraggableCharacterAvatarPreviewState();
}

class _DraggableCharacterAvatarPreviewState
    extends State<DraggableCharacterAvatarPreview> {
  double? _imageWidth; // 图片宽度
  double? _imageHeight; // 图片高度
  bool _isPreviewVisible = false; // 是否显示放大预览

  // 拖动位置控制
  double _previewX = 0;
  double _previewY = 0;
  bool _isPreviewInitialized = false;

  // 悬浮层Entry
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _loadImageDimensions(); // 初始化时加载图片尺寸
  }

  @override
  void dispose() {
    // 确保在组件销毁时安全地移除悬浮层，而不调用setState
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    super.dispose();
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

  // 计算预览窗口的尺寸
  Size _calculatePreviewSize(Size screenSize) {
    var previewWidth = screenSize.width * 0.66;
    var previewHeight =
        (_imageHeight != null && _imageWidth != null)
            ? (_imageHeight! / _imageWidth!) * previewWidth
            : 16 / 9 * previewWidth;

    // 桌面端特殊处理
    if (ScreenHelper.isDesktop()) {
      previewWidth = min(screenSize.width - 280, screenSize.height) * 0.60;
      previewHeight =
          (_imageHeight != null && _imageWidth != null)
              ? (_imageHeight! / _imageWidth!) * previewWidth
              : 16 / 9 * previewWidth;
    }

    return Size(previewWidth, previewHeight);
  }

  // 显示可拖动的预览
  void _showDraggablePreview() {
    // 防止重复创建
    if (_isPreviewVisible) return;

    setState(() {
      _isPreviewVisible = true;
    });

    // 获取Overlay状态
    final overlay = Overlay.of(context);

    // 创建悬浮层
    _overlayEntry = OverlayEntry(
      builder: (context) {
        // 获取屏幕尺寸
        final screenSize = MediaQuery.of(context).size;
        final previewSize = _calculatePreviewSize(screenSize);

        // 初始化预览位置（如果尚未初始化）
        if (!_isPreviewInitialized) {
          _previewX = widget.left;
          _previewY = screenSize.height - widget.bottom - previewSize.height;
          _isPreviewInitialized = true;
        }

        // 确保预览不会超出屏幕边界
        _previewX = _previewX.clamp(0, screenSize.width - previewSize.width);
        _previewY = _previewY.clamp(0, screenSize.height - previewSize.height);

        return Positioned(
          left: _previewX,
          top: _previewY,
          child: GestureDetector(
            // 处理拖动
            onPanUpdate: (details) {
              // 更新位置
              _previewX += details.delta.dx;
              _previewY += details.delta.dy;

              // 重建悬浮层以更新位置
              _overlayEntry?.markNeedsBuild();
            },
            child: Material(
              elevation: 4, // 添加阴影
              borderRadius: BorderRadius.circular(8),
              color: Colors.white.withValues(alpha: 0.9),
              child: Container(
                width: previewSize.width,
                height: previewSize.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Stack(
                  children: [
                    // 图像
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
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
                        icon: const Icon(Icons.close, color: Colors.black54),
                        onPressed: () {
                          _removeOverlay();
                        },
                      ),
                    ),
                    // 拖动提示标签
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.drag_indicator,
                              size: 16,
                              color: Colors.white70,
                            ),
                            SizedBox(width: 4),
                            Text(
                              ScreenHelper.isMobile() ? "按住拖动" : "按住鼠标拖动",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    // 添加到Overlay
    overlay.insert(_overlayEntry!);
  }

  // 移除悬浮层
  void _removeOverlay() {
    // 先检查overlay是否存在
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }

    if (mounted) {
      setState(() {
        _isPreviewVisible = false;
        _isPreviewInitialized = false; // 重置位置初始化状态
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 当预览可见时，不显示小头像
    if (_isPreviewVisible) {
      return SizedBox.shrink(); // 空组件
    }

    // 显示小头像
    return Positioned(
      left: widget.left,
      bottom: widget.bottom,
      child: GestureDetector(
        onTap: _showDraggablePreview,
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
                offset: const Offset(0, 2),
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
}
