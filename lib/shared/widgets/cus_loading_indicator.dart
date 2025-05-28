import 'package:flutter/material.dart';

import '../../core/theme/style/app_colors.dart';

/// 通用加载指示器组件
class CusLoadingIndicator extends StatelessWidget {
  /// 显示的文本
  final String? text;

  /// 指示器颜色
  final Color? color;

  /// 文本颜色
  final Color? textColor;

  /// 指示器大小
  final double size;

  /// 文本大小
  final double textSize;

  /// 构造函数
  const CusLoadingIndicator({
    super.key,
    this.text,
    this.color,
    this.textColor,
    this.size = 30.0,
    this.textSize = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 3.0,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppColors.primary,
            ),
          ),
        ),
        if (text != null) ...[
          const SizedBox(height: 16.0),
          Text(
            text!,
            style: TextStyle(
              fontSize: textSize,
              color: textColor ?? AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
