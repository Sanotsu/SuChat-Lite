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

  // 预览窗口尺寸
  double _previewWidth = 0;
  double _previewHeight = 0;

  // 悬浮层Entry
  OverlayEntry? _overlayEntry;

  // 调整大小相关 - 桌面端
  bool _isResizing = false;
  int _activeResizeCorner = -1; // -1: 没有, 0: 左上, 1: 右上, 2: 左下, 3: 右下
  double _originalWidth = 0;
  double _originalHeight = 0;
  double _originalX = 0;
  double _originalY = 0;
  double _startResizeX = 0;
  double _startResizeY = 0;

  // 移动端缩放控制
  bool _isScaling = false;
  double _initialWidth = 0;
  double _initialHeight = 0;
  Offset? _lastFocalPoint;

  // 缩放约束
  double _minPreviewWidth = 200;
  double _maxPreviewWidth = 800;

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
    // 确保宽度不超过屏幕宽度的66%
    var previewWidth = min(screenSize.width * 0.66, screenSize.width - 20);
    var previewHeight =
        (_imageHeight != null && _imageWidth != null)
            ? (_imageHeight! / _imageWidth!) * previewWidth
            : 16 / 9 * previewWidth;

    // 桌面端特殊处理
    if (ScreenHelper.isDesktop()) {
      // 确保预览宽度不超过可用空间
      double availableWidth = min(
        screenSize.width - 280,
        screenSize.width * 0.8,
      );
      previewWidth = min(availableWidth, screenSize.height * 0.6);
      previewHeight =
          (_imageHeight != null && _imageWidth != null)
              ? (_imageHeight! / _imageWidth!) * previewWidth
              : 16 / 9 * previewWidth;
    }

    // 确保高度不超过屏幕高度的80%
    if (previewHeight > screenSize.height * 0.8) {
      double aspectRatio = previewWidth / previewHeight;
      previewHeight = screenSize.height * 0.8;
      previewWidth = previewHeight * aspectRatio;
    }

    // 更新最小和最大宽度约束
    _minPreviewWidth = min(200, previewWidth * 0.5);
    _maxPreviewWidth = min(screenSize.width * 0.9, previewWidth * 2);

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

        // 调整预览尺寸，确保不超过屏幕高度的80%
        var previewSize = _calculatePreviewSize(screenSize);

        // 首次初始化或重置大小时
        if (!_isPreviewInitialized ||
            (_previewWidth == 0 || _previewHeight == 0)) {
          _previewWidth = previewSize.width;
          _previewHeight = previewSize.height;
        }

        // 初始化预览位置（如果尚未初始化）
        if (!_isPreviewInitialized) {
          _previewX = widget.left;
          _previewY = screenSize.height - widget.bottom - _previewHeight;
          if (_previewY < 0) _previewY = 0; // 防止初始位置为负值
          _isPreviewInitialized = true;
        }

        // 确保预览不会超出屏幕边界
        _previewX = _previewX.clamp(
          0.0,
          max(0.0, screenSize.width - _previewWidth),
        );
        _previewY = _previewY.clamp(
          0.0,
          max(0.0, screenSize.height - _previewHeight),
        );

        return Positioned(
          left: _previewX,
          top: _previewY,
          child: Material(
            elevation: 4, // 添加阴影
            borderRadius: BorderRadius.circular(2),
            color: Colors.white.withValues(alpha: 0.9),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 预览容器 - 移动端使用GestureDetector处理单指拖动和双指缩放
                ScreenHelper.isMobile()
                    ? _buildMobilePreviewContainer(screenSize)
                    : _buildDesktopPreviewContainer(),

                // 仅在桌面端显示调整大小手柄
                if (ScreenHelper.isDesktop()) ...[
                  /// 2025-04-19 原本设计4个角缩放大小，暂时只保留右上角

                  // 左上角调整大小手柄
                  // _buildResizeHandle(0, screenSize),

                  // 右上角调整大小手柄
                  _buildResizeHandle(1, screenSize),

                  // 左下角调整大小手柄
                  // _buildResizeHandle(2, screenSize),

                  // 右下角调整大小手柄
                  // _buildResizeHandle(3, screenSize),
                ],
              ],
            ),
          ),
        );
      },
    );

    // 添加到Overlay
    overlay.insert(_overlayEntry!);
  }

  // 移动端预览容器 - 处理单指拖动和双指缩放
  Widget _buildMobilePreviewContainer(Size screenSize) {
    return GestureDetector(
      // 使用Scale手势处理器同时处理拖动和缩放
      onScaleStart: (details) {
        if (details.pointerCount >= 2) {
          // 双指操作 - 缩放模式
          _isScaling = true;
          _initialWidth = _previewWidth;
          _initialHeight = _previewHeight;
        } else {
          // 单指操作 - 拖动模式
          _isScaling = false;
        }
        _lastFocalPoint = details.focalPoint;
      },

      onScaleUpdate: (details) {
        if (_lastFocalPoint == null) return;

        if (details.pointerCount >= 2 && _isScaling) {
          // 双指缩放 - 缩放整个预览窗口
          // 计算新的宽度和高度，保持纵横比
          double newWidth = _initialWidth * details.scale;

          // 确保宽度在最小和最大值之间
          newWidth = newWidth.clamp(_minPreviewWidth, _maxPreviewWidth);

          // 保持纵横比
          double aspectRatio = _initialWidth / _initialHeight;
          double newHeight = newWidth / aspectRatio;

          // 确保高度不超过屏幕高度的90%
          if (newHeight > screenSize.height * 0.9) {
            newHeight = screenSize.height * 0.9;
            newWidth = newHeight * aspectRatio;
          }

          // 更新窗口大小
          _previewWidth = newWidth;
          _previewHeight = newHeight;
        }

        // 移动操作 - 处理焦点变化以移动窗口
        // 无论是单指拖动还是双指缩放时的整体移动，都需要处理位置变化
        double dx = details.focalPoint.dx - _lastFocalPoint!.dx;
        double dy = details.focalPoint.dy - _lastFocalPoint!.dy;

        _previewX += dx;
        _previewY += dy;

        // 确保不超出屏幕边界
        _previewX = _previewX.clamp(
          0.0,
          max(0.0, screenSize.width - _previewWidth),
        );
        _previewY = _previewY.clamp(
          0.0,
          max(0.0, screenSize.height - _previewHeight),
        );

        // 更新焦点位置
        _lastFocalPoint = details.focalPoint;

        // 重建悬浮层以更新大小和位置
        _overlayEntry?.markNeedsBuild();
      },

      onScaleEnd: (details) {
        _isScaling = false;
        _lastFocalPoint = null;
      },

      child: Container(
        width: _previewWidth,
        height: _previewHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Stack(
          children: [
            // 图像
            Center(
              child: Padding(
                padding: const EdgeInsets.all(2),
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
            // Positioned(
            //   top: 4,
            //   left: 4,
            //   child: Container(
            //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            //     decoration: BoxDecoration(
            //       color: Colors.black26,
            //       borderRadius: BorderRadius.circular(4),
            //     ),
            //     child: Row(
            //       mainAxisSize: MainAxisSize.min,
            //       children: [
            //         Icon(Icons.drag_indicator, size: 16, color: Colors.white70),
            //         SizedBox(width: 4),
            //         Text(
            //           "单指拖动 + 双指缩放",
            //           style: TextStyle(fontSize: 10, color: Colors.white),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  // 桌面端预览容器
  Widget _buildDesktopPreviewContainer() {
    return GestureDetector(
      onPanStart: (details) {
        if (!_isResizing) {
          _activeResizeCorner = -1;
        }
      },
      onPanUpdate: (details) {
        if (!_isResizing && _activeResizeCorner == -1) {
          // 更新位置
          _previewX += details.delta.dx;
          _previewY += details.delta.dy;

          // 重建悬浮层以更新位置
          _overlayEntry?.markNeedsBuild();
        }
      },
      child: Container(
        width: _previewWidth,
        height: _previewHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Stack(
          children: [
            // 图像
            Center(
              child: Padding(
                padding: const EdgeInsets.all(2),
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
            // Positioned(
            //   top: 4,
            //   left: 4,
            //   child: Container(
            //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            //     decoration: BoxDecoration(
            //       color: Colors.black26,
            //       borderRadius: BorderRadius.circular(4),
            //     ),
            //     child: Row(
            //       mainAxisSize: MainAxisSize.min,
            //       children: [
            //         Icon(Icons.drag_indicator, size: 16, color: Colors.white70),
            //         SizedBox(width: 4),
            //         Text(
            //           "可拖动 + 调整大小",
            //           style: TextStyle(fontSize: 10, color: Colors.white),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  // 构建调整大小的手柄 - 仅用于桌面端
  Widget _buildResizeHandle(int corner, Size screenSize) {
    double handleSize = 20;

    // 确定手柄的位置
    double left, top;

    MouseCursor cursor;

    switch (corner) {
      case 0: // 左上角
        left = -handleSize / 2;
        top = -handleSize / 2;
        cursor = SystemMouseCursors.resizeUpLeft;
        break;
      case 1: // 右上角
        left = _previewWidth - handleSize / 2;
        top = -handleSize / 2;
        cursor = SystemMouseCursors.resizeUpRight;
        break;
      case 2: // 左下角
        left = -handleSize / 2;
        top = _previewHeight - handleSize / 2;
        cursor = SystemMouseCursors.resizeDownLeft;
        break;
      case 3: // 右下角
        left = _previewWidth - handleSize / 2;
        top = _previewHeight - handleSize / 2;
        cursor = SystemMouseCursors.resizeDownRight;
        break;
      default:
        return SizedBox.shrink();
    }

    return Positioned(
      left: left,
      top: top,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          onPanStart: (details) {
            _isResizing = true;
            _activeResizeCorner = corner;
            _originalWidth = _previewWidth;
            _originalHeight = _previewHeight;
            _originalX = _previewX;
            _originalY = _previewY;
            _startResizeX = details.globalPosition.dx;
            _startResizeY = details.globalPosition.dy;
          },
          onPanUpdate: (details) {
            if (_isResizing && _activeResizeCorner == corner) {
              // 计算拖动的位移
              double dx = details.globalPosition.dx - _startResizeX;
              double dy = details.globalPosition.dy - _startResizeY;

              double newWidth = _originalWidth;
              double newHeight = _originalHeight;
              double newX = _originalX;
              double newY = _originalY;

              // 根据不同角落计算新的大小和位置
              switch (corner) {
                case 0: // 左上角
                  newWidth = _originalWidth - dx;
                  newHeight = _originalHeight - dy;
                  newX = _originalX + dx;
                  newY = _originalY + dy;
                  break;
                case 1: // 右上角
                  newWidth = _originalWidth + dx;
                  newHeight = _originalHeight - dy;
                  newY = _originalY + dy;
                  break;
                case 2: // 左下角
                  newWidth = _originalWidth - dx;
                  newHeight = _originalHeight + dy;
                  newX = _originalX + dx;
                  break;
                case 3: // 右下角
                  newWidth = _originalWidth + dx;
                  newHeight = _originalHeight + dy;
                  break;
              }

              // 确保宽度在最小和最大值之间
              newWidth = newWidth.clamp(_minPreviewWidth, _maxPreviewWidth);

              // 保持纵横比 (可选)
              if (_imageWidth != null && _imageHeight != null) {
                double aspectRatio = _imageWidth! / _imageHeight!;
                newHeight = newWidth / aspectRatio;
              }

              // 确保高度也在合理范围内
              double maxHeight = screenSize.height * 0.9;
              if (newHeight > maxHeight) {
                newHeight = maxHeight;
                double aspectRatio = _previewWidth / _previewHeight;
                newWidth = newHeight * aspectRatio;
              }

              // 更新大小和位置
              _previewWidth = newWidth;
              _previewHeight = newHeight;

              // 更新位置，同时确保不会超出屏幕边界
              _previewX = newX.clamp(
                0.0,
                max(0.0, screenSize.width - newWidth),
              );
              _previewY = newY.clamp(
                0.0,
                max(0.0, screenSize.height - newHeight),
              );

              // 重建悬浮层以更新显示
              _overlayEntry?.markNeedsBuild();
            }
          },
          onPanEnd: (details) {
            _isResizing = false;
          },
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(Icons.unfold_more, size: 12, color: Colors.white),
          ),
        ),
      ),
    );
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
        _previewWidth = 0; // 重置大小
        _previewHeight = 0;
        _isScaling = false;
        _lastFocalPoint = null;
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
