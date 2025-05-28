import 'dart:async';
import 'package:flutter/widgets.dart';
import '../branch_chat_state/branch_chat_state.dart';

/// 滚动处理器，用于处理滚动相关的逻辑
///
/// 1 重置对话列表内容高度
///
class ScrollHandler {
  final BranchChatState state;
  final Function setState;

  ScrollHandler(this.state, this.setState);

  /// 重置对话列表内容高度
  void resetContentHeight({int? times}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!state.scrollController.hasClients) return;

      state.lastContentHeight = state.scrollController.position.maxScrollExtent;
    });

    // 重置完了顺便滚动到底部
    _scrollToBottom(times: times);
  }

  /// 滚动到底部
  Future<void> _scrollToBottom({int? times}) async {
    await Future.delayed(Duration.zero);
    if (!state.scrollController.hasClients) return;

    final position = state.scrollController.position;
    if (!position.hasContentDimensions ||
        position.maxScrollExtent <= position.minScrollExtent) {
      return;
    }

    await state.scrollController.animateTo(
      position.maxScrollExtent,
      duration: Duration(milliseconds: times ?? 500),
      curve: Curves.easeOut,
    );

    setState(() => state.isUserScrolling = false);
  }
}
