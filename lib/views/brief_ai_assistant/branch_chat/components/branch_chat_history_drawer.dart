import 'package:flutter/material.dart';
import '../../../../models/brief_ai_tools/branch_chat/branch_chat_session.dart';
import 'branch_chat_history_panel.dart';

class BranchChatHistoryDrawer extends StatelessWidget {
  // 历史对话列表
  final List<BranchChatSession> sessions;
  // 当前选中的对话
  final int? currentSessionId;
  // 选中对话的回调
  final Function(BranchChatSession) onSessionSelected;
  // 删除或重命名对话后，要刷新对话列表
  final Function({BranchChatSession? session, String? action}) onRefresh;

  const BranchChatHistoryDrawer({
    super.key,
    required this.sessions,
    this.currentSessionId,
    required this.onSessionSelected,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: BranchChatHistoryPanel(
        sessions: sessions,
        currentSessionId: currentSessionId,
        onSessionSelected: onSessionSelected,
        onRefresh: onRefresh,
        needCloseDrawer: true, // 在抽屉中需要关闭
      ),
    );
  }
}
