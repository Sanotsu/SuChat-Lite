import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/utils/screen_helper.dart';
import '../../../../shared/widgets/image_preview_helper.dart';
import '../../data/models/unified_chat_partner.dart';

/// 可拖动的搭档立绘预览（2026-09-05 移植旧版 DraggableCharacterAvatarPreview，
/// 适配统一聊天的搭档实体 UnifiedChatPartner）
///
/// 小立绘常驻聊天区左下角，点击后弹出 Overlay 悬浮大图：
/// - 桌面端：拖动移动 + 右上角手柄等比缩放
/// - 移动端：单指拖动 + 双指捏合缩放
/// 边界钳制保证预览不出屏。
class DraggablePartnerAvatarPreview extends StatefulWidget {
  final UnifiedChatPartner partner;
  // 小立绘宽度
  final double width;
  // 小立绘高度
  final double height;
  // 小立绘距离底部距离
  final double bottom;
  // 小立绘距离左边距离
  final double left;

  const DraggablePartnerAvatarPreview({
    super.key,
    required this.partner,
    this.width = 48,
    this.height = 64,
    // 距离底部距离，避免遮挡输入框展开后区域
    this.bottom = 210,
    this.left = 4,
  });

  @override
  State<DraggablePartnerAvatarPreview> createState() =>
      _DraggablePartnerAvatarPreviewState();
}

class _DraggablePartnerAvatarPreviewState
    extends State<DraggablePartnerAvatarPreview> {
  String get _avatarUrl => widget.partner.avatarUrl ?? '';

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
    _loadImageDimensions();
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
    final imageProvider = getImageProvider(_avatarUrl);

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
          debugPrint('加载搭档立绘尺寸失败: $exception');
        },
      ),
    );
  }

  // 计算预览窗口的尺寸
  Size _calculatePreviewSize(Size screenSize) {
    // 确保宽度不超过屏幕宽度的66%
    var previewWidth = min(screenSize.width * 0.66, screenSize.width - 20);
    var previewHeight = (_imageHeight != null && _imageWidth != null)
        ? (_imageHeight! / _imageWidth!) * previewWidth
        : 16 / 9 * previewWidth;

    // 桌面端特殊处理：给左侧会话侧栏(280)和右侧工具栏留出空间
    if (ScreenHelper.isDesktop()) {
      double availableWidth = min(
        screenSize.width - 280 - 76,
        screenSize.width * 0.8,
      );
      previewWidth = min(availableWidth, screenSize.height * 0.6);
      previewHeight = (_imageHeight != null && _imageWidth != null)
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
                // 预览容器 - 移动端处理单指拖动和双指缩放，桌面端拖动+手柄缩放
                ScreenHelper.isMobile()
                    ? _buildMobilePreviewContainer(screenSize)
                    : _buildDesktopPreviewContainer(),

                // 仅在桌面端显示右上角调整大小手柄
                if (ScreenHelper.isDesktop()) _buildResizeHandle(1, screenSize),
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
          double newWidth = _initialWidth * details.scale;
          newWidth = newWidth.clamp(_minPreviewWidth, _maxPreviewWidth);

          // 保持纵横比
          double aspectRatio = _initialWidth / _initialHeight;
          double newHeight = newWidth / aspectRatio;

          // 确保高度不超过屏幕高度的90%
          if (newHeight > screenSize.height * 0.9) {
            newHeight = screenSize.height * 0.9;
            newWidth = newHeight * aspectRatio;
          }

          _previewWidth = newWidth;
          _previewHeight = newHeight;
        }

        // 移动操作 - 无论单指拖动还是双指缩放时的整体移动
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

        _lastFocalPoint = details.focalPoint;

        // 重建悬浮层以更新大小和位置
        _overlayEntry?.markNeedsBuild();
      },

      onScaleEnd: (details) {
        _isScaling = false;
        _lastFocalPoint = null;
      },

      child: _buildPreviewBody(),
    );
  }

  // 桌面端预览容器 - 拖动移动
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
      child: _buildPreviewBody(),
    );
  }

  // 预览主体：立绘图片 + 关闭按钮
  Widget _buildPreviewBody() {
    return Container(
      width: _previewWidth,
      height: _previewHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Stack(
        children: [
          // 立绘图片（contain保持原始比例）
          Center(
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: buildNetworkOrFileImage(_avatarUrl, fit: BoxFit.contain),
            ),
          ),
          // 关闭按钮
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.black54),
              onPressed: _removeOverlay,
            ),
          ),
        ],
      ),
    );
  }

  // 构建调整大小的手柄 - 仅用于桌面端（右上角）
  Widget _buildResizeHandle(int corner, Size screenSize) {
    double handleSize = 20;

    double left;
    double top;
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
              double dx = details.globalPosition.dx - _startResizeX;
              double dy = details.globalPosition.dy - _startResizeY;

              double newWidth = _originalWidth;
              double newHeight = _originalHeight;
              double newX = _originalX;
              double newY = _originalY;

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

              // 保持纵横比
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

              _previewWidth = newWidth;
              _previewHeight = newHeight;

              _previewX = newX.clamp(
                0.0,
                max(0.0, screenSize.width - newWidth),
              );
              _previewY = newY.clamp(
                0.0,
                max(0.0, screenSize.height - newHeight),
              );

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
            child: const Icon(Icons.unfold_more, size: 12, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // 移除悬浮层
  void _removeOverlay() {
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
    // 当预览可见时，不显示小立绘
    if (_isPreviewVisible) {
      return SizedBox.shrink();
    }

    // 显示小立绘
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
          child: buildNetworkOrFileImage(_avatarUrl, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
