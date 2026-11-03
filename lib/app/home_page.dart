import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../shared/widgets/toast_utils.dart';
import '../features/unified_chat/presentation/pages/unified_chat_page.dart';

///
/// 主页面
/// 2026-09-01 0.1.5：旧版 branch_chat 首页替换为新版统一聊天页面，
/// "更多功能"(AIToolPage)入口在聊天页顶部菜单
///
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 记录上次点击返回键的时间
  DateTime? _lastPressedAt;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 点击返回键时暂停返回
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }

        // 获取当前时间
        final now = DateTime.now();

        // 判断是否在3秒内连续按了两次返回键
        if (_lastPressedAt != null &&
            now.difference(_lastPressedAt!).inSeconds < 2) {
          // 第二次按返回键，退出应用
          SystemNavigator.pop();
          return;
        } else {
          // 第一次按返回键，更新时间并显示提示
          _lastPressedAt = now;
          ToastUtils.showInfo('再按一次退出应用', align: Alignment.center);
        }
      },
      child: const UnifiedChatPage(),
    );
  }
}
