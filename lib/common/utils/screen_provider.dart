import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'screen_helper.dart';

/// 布局类型枚举
enum LayoutType {
  mobile,   // 手机布局
  tablet,   // 平板布局
  desktop,  // 桌面布局
}

/// 屏幕布局提供者
/// 提供屏幕断点和布局选择功能
class ScreenProvider {
  /// 断点定义（单位：像素）
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1200;

  /// 根据当前屏幕宽度获取布局类型
  static LayoutType getLayoutType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < mobileBreakpoint) {
      return LayoutType.mobile;
    } else if (width < tabletBreakpoint) {
      return LayoutType.tablet;
    } else {
      return LayoutType.desktop;
    }
  }

  /// 检查当前是否为移动布局
  static bool isMobileLayout(BuildContext context) {
    return getLayoutType(context) == LayoutType.mobile;
  }

  /// 检查当前是否为平板布局
  static bool isTabletLayout(BuildContext context) {
    return getLayoutType(context) == LayoutType.tablet;
  }

  /// 检查当前是否为桌面布局
  static bool isDesktopLayout(BuildContext context) {
    return getLayoutType(context) == LayoutType.desktop;
  }

  /// 根据布局类型返回不同的widget
  static Widget buildResponsive({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    final layoutType = getLayoutType(context);
    
    switch (layoutType) {
      case LayoutType.mobile:
        return mobile;
      case LayoutType.tablet:
        return tablet ?? mobile;
      case LayoutType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// 获取内容最大宽度（用于限制内容在大屏幕上的宽度）
  static double getContentMaxWidth(BuildContext context) {
    final layoutType = getLayoutType(context);
    
    switch (layoutType) {
      case LayoutType.mobile:
        return double.infinity; // 移动设备不限制宽度
      case LayoutType.tablet:
        return 680.0; // 平板限制宽度
      case LayoutType.desktop:
        return 1200.0; // 桌面限制宽度
    }
  }

  /// 获取适合当前布局的水平内边距
  static double getHorizontalPadding(BuildContext context) {
    final layoutType = getLayoutType(context);
    
    switch (layoutType) {
      case LayoutType.mobile:
        return ScreenHelper.isDesktop() ? 16.0 : 16.sp;
      case LayoutType.tablet:
        return ScreenHelper.isDesktop() ? 32.0 : 32.sp;
      case LayoutType.desktop:
        return ScreenHelper.isDesktop() ? 48.0 : 48.sp;
    }
  }

  /// 获取内容水平边距（考虑平台因素）
  static EdgeInsets getContentPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: getHorizontalPadding(context),
      vertical: ScreenHelper.isDesktop() ? 16.0 : 16.sp,
    );
  }
} 