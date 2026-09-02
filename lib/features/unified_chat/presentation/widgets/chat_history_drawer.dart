import 'package:flutter/material.dart';

import 'chat_history_panel.dart';

/// 聊天历史记录抽屉（移动端）：内容复用 [ChatHistoryPanel]。
/// 桌面端常驻侧栏直接使用 ChatHistoryPanel（见 unified_chat_page）。
class ChatHistoryDrawer extends StatelessWidget {
  const ChatHistoryDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        // 使用 RoundedRectangleBorder 定义形状
        borderRadius: BorderRadius.only(
          topRight: Radius.zero,
          bottomRight: Radius.zero,
        ),
      ),
      child: ChatHistoryPanel(onBeforeNavigate: () => Navigator.pop(context)),
    );
  }
}
