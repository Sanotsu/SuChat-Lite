import 'package:flutter/material.dart';
import '../utils/screen_helper.dart';

/// 最小窗口大小限制组件
/// 在桌面端，当窗口大小小于指定的最小尺寸时，显示提示信息
class MinSizeLayout extends StatelessWidget {
  /// 子组件
  final Widget child;

  /// 最小宽度
  final double minWidth;

  /// 最小高度
  final double minHeight;

  /// 当窗口尺寸过小时显示的提示信息
  final String? message;

  /// 提示信息的样式
  final TextStyle? messageStyle;

  /// 自定义的提示组件
  final Widget? customMessage;

  /// 构造函数
  const MinSizeLayout({
    super.key,
    required this.child,
    this.minWidth = 640,
    this.minHeight = 360,
    this.message,
    this.messageStyle,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    // 如果不是桌面平台，直接显示内容，不做大小限制
    if (!ScreenHelper.isDesktop()) {
      return child;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 如果窗口大小小于最小尺寸，显示提示信息
        if (constraints.maxWidth < minWidth ||
            constraints.maxHeight < minHeight) {
          return _buildSizeWarning(constraints, context);
        }

        // 显示正常内容
        return child;
      },
    );
  }

  /// 构建窗口尺寸警告
  Widget _buildSizeWarning(BoxConstraints constraints, BuildContext context) {
    // 如果提供了自定义提示组件，则使用自定义组件
    if (customMessage != null) {
      return Center(child: customMessage);
    }

    // 默认提示信息
    final defaultMessage =
        message ?? '请调整窗口大小至少 ${minWidth.toInt()}x${minHeight.toInt()}';

    // 获取主题颜色
    final primaryColor = Theme.of(context).primaryColor;

    // 默认文本样式
    final defaultStyle =
        messageStyle ??
        const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF333333),
        );

    return Center(
      child: Card(
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.screen_rotation,
                  size: 48,
                  color: primaryColor.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 20),
                Text(
                  defaultMessage,
                  style: defaultStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '当前尺寸: ${constraints.maxWidth.toInt()}x${constraints.maxHeight.toInt()}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
