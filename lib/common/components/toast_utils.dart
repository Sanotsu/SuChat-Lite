import 'package:flutter/material.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ToastUtils {
  // 基础配置
  static const Duration _defaultDuration = Duration(seconds: 2);
  static final double _defaultRadius = 10.sp;
  static final EdgeInsets _defaultPadding = EdgeInsets.symmetric(
    horizontal: 16.sp,
    vertical: 12.sp,
  );

  /// 1. 成功提示 (✅ + 绿色)
  static void showSuccess(String message, {Duration? duration}) {
    _showIconToast(
      message,
      icon: Icons.check_circle,
      backgroundColor: Colors.green,
      duration: duration,
    );
  }

  /// 2. 错误提示 (❌ + 红色)
  static void showError(String message, {Duration? duration}) {
    _showIconToast(
      message,
      icon: Icons.error,
      backgroundColor: Colors.red,
      duration: duration,
    );
  }

  /// 3. 警告提示 (⚠️ + 橙色)
  static void showWarning(String message, {Duration? duration}) {
    _showIconToast(
      message,
      icon: Icons.warning_amber_rounded,
      backgroundColor: Colors.orange,
      duration: duration,
    );
  }

  /// 4. 信息提示 (ℹ️ + 蓝色)
  static void showInfo(String message, {Duration? duration}) {
    _showIconToast(
      message,
      icon: Icons.info,
      backgroundColor: Colors.blue,
      duration: duration,
    );
  }

  /// 5. 普通文字提示 (居中)
  static void showToast(String message, {Duration? duration, Color? bgColor}) {
    BotToast.showText(
      text: message,
      align: const Alignment(0, 0),
      contentColor: bgColor ?? Colors.black87,
      textStyle: const TextStyle(color: Colors.white),
      duration: duration ?? _defaultDuration,
    );
  }

  /// 6. 显示加载中 (可手动关闭)
  static CancelFunc showLoading([String? message]) {
    return BotToast.showCustomLoading(
      toastBuilder:
          (_) => Container(
            padding: _defaultPadding,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(_defaultRadius),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                if (message != null) ...[
                  SizedBox(height: 8.sp),
                  Text(message, style: const TextStyle(color: Colors.white)),
                ],
              ],
            ),
          ),
    );
  }

  // 私有方法：带图标的Toast
  static void _showIconToast(
    String message, {
    required IconData icon,
    required Color backgroundColor,
    Duration? duration,
  }) {
    BotToast.showCustomText(
      align: const Alignment(0, 0),
      duration: duration ?? _defaultDuration,
      toastBuilder:
          (_) => Container(
            padding: _defaultPadding,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(_defaultRadius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white),
                SizedBox(width: 8.sp),
                Text(message, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
    );
  }
}
