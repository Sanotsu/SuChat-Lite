import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'brief_ai_assistant/branch_chat/branch_chat_page.dart';

/// 主页面

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 点击返回键时暂停返回
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        // 如果确认弹窗点击确认返回true，否则返回false
        final bool? shouldPop = await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("退出确认"),
              content: const Text("确认退出 SuChat 吗？"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text("取消"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text("确认"),
                ),
              ],
            );
          },
        ); // 只有当对话框返回true 才 pop(返回上一层)
        if (shouldPop ?? false) {
          // 2024-05-29 已经到首页了，直接退出
          SystemNavigator.pop();
        }
      },
      child: const BranchChatPage(),
    );
  }
}
