import 'package:flutter/material.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../utils/screen_helper.dart';

class ToastUtils {
  // 基础配置
  static const Duration _defaultDuration = Duration(seconds: 2);

  // 获取适合当前平台的尺寸值
  static double _getRadius() {
    if (ScreenHelper.isDesktop()) {
      return 10.0; // 桌面端使用固定值
    } else {
      return 10.sp; // 移动端使用响应式单位
    }
  }

  // 获取适合当前平台的内边距
  static EdgeInsets _getPadding() {
    if (ScreenHelper.isDesktop()) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    } else {
      return EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp);
    }
  }

  // 获取适合当前平台的字体大小
  static double _getFontSize() {
    if (ScreenHelper.isDesktop()) {
      return 14.0; // 桌面端使用固定值
    } else {
      return 14.sp; // 移动端使用响应式单位
    }
  }

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
      textStyle: TextStyle(color: Colors.white, fontSize: _getFontSize()),
      duration: duration ?? _defaultDuration,
    );
  }

  /// 6. 显示加载中 (可手动关闭)
  static CancelFunc showLoading([String? message]) {
    return BotToast.showCustomLoading(
      toastBuilder:
          (_) => Container(
            padding: _getPadding(),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(_getRadius()),
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

  /// 图标提示的私有实现方法
  static void _showIconToast(
    String message, {
    required IconData icon,
    required Color backgroundColor,
    Duration? duration,
  }) {
    BotToast.showCustomNotification(
      duration: duration ?? _defaultDuration,
      toastBuilder: (cancel) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_getRadius()),
            ),
            child: Padding(
              padding: _getPadding(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: ScreenHelper.isDesktop() ? 18 : 18.sp,
                  ),
                  SizedBox(width: ScreenHelper.isDesktop() ? 8 : 8.sp),
                  Flexible(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _getFontSize(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
