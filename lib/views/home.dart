import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../common/components/toast_utils.dart';

import 'brief_ai_assistant/branch_chat/branch_chat_page.dart';
import '../models/brief_ai_tools/branch_chat/character_card.dart';

/// 主页面

class HomePage extends StatefulWidget {
  // 直接启动app进入主页是不会有character的，
  // 但在角色卡列表页点击某个角色时，会传递character跳转到此home页面，并清空所有路由
  // 此时就是在home页面中将character传递给branchchatpage
  final CharacterCard? character;

  const HomePage({super.key, this.character});

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
          ToastUtils.showInfo('再按一次退出应用');
        }
      },
      child: BranchChatPage(character: widget.character),
    );
  }
}
