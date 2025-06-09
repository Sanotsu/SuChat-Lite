import 'dart:async';

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

/// 通用加载指示器组件（带计时功能）
class CusLoadingTimeIndicator extends StatefulWidget {
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

  /// 是否显示计时
  final bool showTimer;

  /// 构造函数
  const CusLoadingTimeIndicator({
    super.key,
    this.text,
    this.color,
    this.textColor,
    this.size = 30.0,
    this.textSize = 14.0,
    this.showTimer = true,
  });

  @override
  State<CusLoadingTimeIndicator> createState() =>
      _CusLoadingTimeIndicatorState();
}

class _CusLoadingTimeIndicatorState extends State<CusLoadingTimeIndicator> {
  late DateTime _startTime;
  Duration _elapsedTime = Duration.zero;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime = DateTime.now().difference(_startTime);
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: CircularProgressIndicator(
            strokeWidth: 3.0,
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.color ?? AppColors.primary,
            ),
          ),
        ),
        if (widget.text != null || widget.showTimer) ...[
          const SizedBox(height: 16.0),
          Column(
            children: [
              if (widget.text != null)
                Text(
                  widget.text!,
                  style: TextStyle(
                    fontSize: widget.textSize,
                    color: widget.textColor ?? AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (widget.showTimer) ...[
                if (widget.text != null) const SizedBox(height: 4.0),
                Text(
                  '用时: ${_formatDuration(_elapsedTime)}',
                  style: TextStyle(
                    fontSize: widget.textSize - 1,
                    color: (widget.textColor ?? AppColors.textSecondary)
                        .withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
