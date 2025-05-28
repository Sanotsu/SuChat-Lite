import 'package:flutter/material.dart';

import '../../domain/entities/branch_chat_message.dart';
import '../branch_chat_state/branch_chat_state.dart';
import '../branch_chat_handler/ai_response_handler.dart';
import '../branch_chat_handler/user_interaction_handler.dart';
import '../widgets/index.dart';

/// 消息列表组件
class MessageList extends StatefulWidget {
  final BranchChatState state;
  final Function setState;
  final AIResponseHandler aiResponseHandler;
  final UserInteractionHandler userInteractionHandler;

  const MessageList({
    super.key,
    required this.state,
    required this.setState,
    required this.aiResponseHandler,
    required this.userInteractionHandler,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  BranchChatState get state => widget.state;

  @override
  Widget build(BuildContext context) {
    // 构建消息体
    msgItem(BranchChatMessage message) => BranchMessageItem(
      key: ValueKey('${message.messageId}_${state.colorConfig.hashCode}'),
      message: message,
      onLongPress:
          state.isStreaming
              ? null
              : widget.userInteractionHandler.showMessageOptions,
      // 有默认对话背景图、或者有角色自定义背景图，就是有使用背景图
      isUseBgImage:
          state.backgroundImage != null && state.backgroundImage!.isNotEmpty,
      // 简洁模式不显示头像
      isShowAvatar: !state.isBriefDisplay,
      character: state.currentCharacter,
      colorConfig: state.colorConfig,
    );

    // 构建消息下方的按钮
    msgActions(
      BranchChatMessage message,
      bool hasMultipleBranches,
      bool isStreamingMessage,
    ) => BranchMessageActions(
      key: ValueKey('actions_${message.messageId}'),
      message: message,
      messages: state.allMessages,
      onRegenerate:
          () => widget.aiResponseHandler.handleResponseRegenerate(message),
      hasMultipleBranches: hasMultipleBranches,
      isRegenerating: state.isStreaming,
      currentBranchIndex:
          isStreamingMessage
              ? 0
              : state.branchManager.getBranchIndex(state.allMessages, message),
      totalBranches:
          isStreamingMessage
              ? 1
              : state.branchManager.getBranchCount(state.allMessages, message),
      onSwitchBranch: widget.userInteractionHandler.handleSwitchBranch,
    );

    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(state.textScaleFactor)),
      child: ListView.builder(
        // 启用列表缓存
        cacheExtent: 1000.0, // 增加缓存范围
        addAutomaticKeepAlives: true,
        // 让ListView自动管理RepaintBoundary
        addRepaintBoundaries: true,
        // 使用itemCount限制构建数量
        itemCount: state.displayMessages.length,
        controller: state.scrollController,
        // 列表底部留一点高度，避免工具按钮和悬浮按钮重叠
        padding: EdgeInsets.only(bottom: 50),
        itemBuilder: (context, index) {
          final message = state.displayMessages[index];

          // 如果当前消息是流式消息，说明正在追加显示中，则不显示分支相关内容
          final isStreamingMessage = message.messageId == 'streaming';
          final hasMultipleBranches =
              !isStreamingMessage &&
              state.branchManager.getBranchCount(state.allMessages, message) >
                  1;

          // 使用RepaintBoundary包装每个列表项
          return Column(
            children: [
              // 渲染消息体比较复杂，使用RepaintBoundary包装
              RepaintBoundary(child: msgItem(message)),
              // 为分支操作添加条件渲染，避免不必要的构建
              if (!state.isBriefDisplay &&
                  (!isStreamingMessage || hasMultipleBranches))
                // 操作组件渲染不复杂，不使用RepaintBoundary包装
                msgActions(message, hasMultipleBranches, isStreamingMessage),
            ],
          );
        },
      ),
    );
  }
}
