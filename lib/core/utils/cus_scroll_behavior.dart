import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'screen_helper.dart';

/// 2026-09-04 桌面端适配：自定义全局滚动行为
/// 1. 允许鼠标/触控板拖拽触发 overscroll——救活 RefreshIndicator/EasyRefresh
///    以及 PageView 滑动切换在桌面上的可用性
/// 2. 桌面为自带 controller 的可滚动视图自动附加可见滚动条
class CusScrollBehavior extends MaterialScrollBehavior {
  const CusScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => PointerDeviceKind.values.toSet();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // 仅桌面且滚动视图自带controller时附加滚动条
    // (无controller的列表无法定位滚动位置，保持默认行为避免断言)
    if (ScreenHelper.isDesktop() && details.controller != null) {
      return Scrollbar(controller: details.controller, child: child);
    }
    return super.buildScrollbar(context, child, details);
  }
}
