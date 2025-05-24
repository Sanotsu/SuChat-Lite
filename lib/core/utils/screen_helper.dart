import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 屏幕适配帮助类(避免与flutter_screenutil的ScreenUtil类冲突，所以使用helper后缀)
class ScreenHelper {
  /// 判断是否为桌面平台（Windows, macOS, Linux）
  static bool isDesktop() =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  static bool isMobile() => Platform.isAndroid || Platform.isIOS;

  /// 获取当前平台的设计尺寸
  static Size getDesignSize() {
    if (isDesktop()) {
      // 桌面平台使用更大的设计尺寸
      return const Size(1280, 768);
    } else {
      // 移动平台使用标准设计尺寸
      return const Size(360, 640);
    }
  }

  /// 获取平台自适应的SP比例因子
  static double getSpRatio() {
    return isDesktop() ? 1.0 : 1.0;
  }

  /// 根据平台适配SP值
  /// 这个方法可以用于特殊情况下需要手动调整sp值的场景
  static double adaptSp(double value) {
    if (isDesktop()) {
      // 桌面平台特殊处理
      return value * 1.2;
    } else {
      // 移动平台正常返回sp值
      return value.sp;
    }
  }

  /// 根据平台获取适合的字体大小
  static double getFontSize(double mobileSize) {
    if (isDesktop()) {
      // 桌面平台字体稍大
      return mobileSize * 1.2;
    } else {
      // 移动平台使用sp单位
      return mobileSize.sp;
    }
  }

  /// 获取根据平台适配的宽度
  static double adaptWidth(double width) {
    if (isDesktop()) {
      // 桌面平台特殊处理
      return width * 1.5;
    } else {
      // 移动平台使用正常的宽度
      return width.w;
    }
  }

  /// 获取根据平台适配的高度
  static double adaptHeight(double height) {
    if (isDesktop()) {
      // 桌面平台特殊处理
      return height * 1.5;
    } else {
      // 移动平台使用正常的高度
      return height.h;
    }
  }

  /// 获取根据平台适配的内边距
  static EdgeInsets adaptPadding(EdgeInsets padding) {
    if (isDesktop()) {
      // 桌面平台手动计算内边距
      return EdgeInsets.only(
        left: padding.left * 1.5,
        top: padding.top * 1.5,
        right: padding.right * 1.5,
        bottom: padding.bottom * 1.5,
      );
    } else {
      // 移动平台使用r方法适配内边距
      return padding.r;
    }
  }

  // 获取适合当前平台的尺寸缩放因子
  static double getSizeScaleFactor(BuildContext context) {
    if (isDesktop()) {
      // 桌面端的缩放因子可以根据屏幕宽度动态调整
      final screenWidth = MediaQuery.of(context).size.width;
      return screenWidth / 1280; // 基于桌面设计尺寸
    } else {
      return 1.0; // 移动端保持原有缩放
    }
  }
}
