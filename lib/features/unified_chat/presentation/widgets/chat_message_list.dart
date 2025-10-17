import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/toast_utils.dart';
import '../../data/models/unified_chat_message.dart';
import '../viewmodels/unified_chat_viewmodel.dart';
import 'chat_message_item.dart';

/// 聊天消息列表组件
class ChatMessageList extends StatefulWidget {
  const ChatMessageList({super.key});

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  final ScrollController _scrollController = ScrollController();

  // 滚动状态管理
  bool _isUserScrolling = false;
  bool _showScrollToTop = false;
  bool _showScrollToBottom = false;
  bool _autoScrollEnabled = true;
  bool _wasStreamingBefore = false;

  @override
  void initState() {
    super.initState();

    // 监听滚动事件
    _scrollController.addListener(_onScroll);

    // 监听消息变化，自动滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;

    // 检测是否在顶部或底部
    final isAtTop = currentScroll <= 50;
    final isAtBottom = currentScroll >= maxScroll - 50;

    // 检测是否可以滚动（内容高度大于视窗高度）
    final canScroll = maxScroll > 0;

    setState(() {
      _showScrollToTop = canScroll && !isAtTop;
      _showScrollToBottom = canScroll && !isAtBottom;
    });

    // 如果用户手动滚动到底部，重新启用自动滚动
    if (isAtBottom && _isUserScrolling) {
      _autoScrollEnabled = true;
      _isUserScrolling = false;
    }
  }

  void _onUserScrollStart() {
    _isUserScrolling = true;
    // 只有在用户手动滚动时才禁用自动滚动
    _autoScrollEnabled = false;
  }

  void _onScrollToBottomPressed() {
    _autoScrollEnabled = true;
    _scrollToBottom();
  }

  void _handleStreamingStateChange(UnifiedChatViewModel viewModel) {
    // 如果流式状态从 true 变为 false（流式结束），且用户没有手动滚动，则滚动到底部一次
    if (_wasStreamingBefore &&
        !viewModel.isStreaming &&
        _autoScrollEnabled &&
        !_isUserScrolling) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }

    // 更新上一次的流式状态
    _wasStreamingBefore = viewModel.isStreaming;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UnifiedChatViewModel>(
      builder: (context, viewModel, child) {
        // 监听消息变化和流式状态变化
        _handleStreamingStateChange(viewModel);

        // 仅在自动滚动启用且有消息正在流式生成时才自动滚动
        if (_autoScrollEnabled && viewModel.isStreaming) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }

        if (viewModel.messages.isEmpty) {
          return _buildEmptyState(context, viewModel);
        }

        return Stack(
          children: [
            NotificationListener<ScrollStartNotification>(
              onNotification: (notification) {
                _onUserScrollStart();
                return false;
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                itemCount: viewModel.messages.length,
                itemBuilder: (context, index) {
                  final message = viewModel.messages[index];

                  // 只有在对话开始后才隐藏系统消息，新对话时显示系统消息
                  // if (message.role == UnifiedMessageRole.system &&
                  //     viewModel.messages.length > 1) {
                  //   return const SizedBox.shrink();
                  // }
                  //   // 跳过系统消息的显示
                  // if (message.role == UnifiedMessageRole.system) {
                  //   return const SizedBox.shrink();
                  // }

                  return ChatMessageItem(
                    message: message,
                    viewModel: viewModel,
                    onRegenerate: message.isAssistant
                        ? () => viewModel.regenerateMessage(
                            message,
                            isWebSearch: viewModel.isWebSearchEnabled,
                          )
                        : null,
                    onResend: message.isUser
                        ? () => viewModel.resendUserMessage(
                            message,
                            isWebSearch: viewModel.isWebSearchEnabled,
                          )
                        : null,
                    onDelete: () =>
                        _showDeleteConfirmDialog(context, viewModel, message),
                    onCopy: () => _copyMessageContent(context, message),
                    // 修改完消息vm中已经更新了消息列表，这里应该就直接看到新的消息内容了
                    onUpdateMessage: message.isAssistant
                        ? (msg) => viewModel.updateMessage(msg)
                        : null,
                    onEditMessage: message.isUser
                        ? (msg) => viewModel.startEditingUserMessage(msg)
                        : null,
                  );
                },
              ),
            ),

            // 悬浮滚动按钮
            _buildScrollButtons(),

            // 悬浮新建对话按钮
            Positioned(
              // 小按钮尺寸为40*40,不够小，手动32*32包裹
              left: 0.5.sw - 16,
              bottom: 8,
              child: SizedBox(
                width: 32,
                height: 32,
                child: FloatingActionButton.small(
                  onPressed: () => viewModel.createNewConversation(),
                  heroTag: 'create_new_conversation',
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  tooltip: '新建对话',
                  child: const Icon(Icons.add),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    UnifiedChatViewModel viewModel,
  ) {
    return Center(
      child: SizedBox(
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Icon(
                Icons.chat_bubble_outline,
                size: 36,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 4),

            Expanded(
              child: Text(
                '今天我能为你提供什么帮助？',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    UnifiedChatViewModel viewModel,
    UnifiedChatMessage message,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除消息'),
        content: const Text('确定要删除这条消息吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.deleteMessage(message);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _copyMessageContent(BuildContext context, UnifiedChatMessage message) {
    Clipboard.setData(ClipboardData(text: message.displayContent));

    ToastUtils.showInfo('消息已复制到剪贴板');
  }

  Widget _buildScrollButtons() {
    if (!_showScrollToTop && !_showScrollToBottom) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: 8,
      bottom: 8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 回到顶部按钮
          if (_showScrollToTop)
            // Transform.scale(
            //   scale: 0.7,
            // small 也是40*40,感觉还不够小
            //   child: FloatingActionButton.small(
            //     onPressed: _scrollToTop,
            //     shape: const CircleBorder(),
            //     heroTag: 'scroll_to_top',
            //     backgroundColor: Theme.of(context).colorScheme.surface,
            //     foregroundColor: Theme.of(context).colorScheme.onSurface,
            //     tooltip: '回到顶部',
            //     child: const Icon(Icons.keyboard_arrow_up),
            //   ),
            // ),
            SizedBox(
              width: 32,
              height: 32,
              child: FloatingActionButton.small(
                onPressed: _scrollToTop,
                shape: const CircleBorder(),
                heroTag: 'scroll_to_top',
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                tooltip: '回到顶部',
                child: const Icon(Icons.keyboard_arrow_up),
              ),
            ),

          // 回到底部按钮
          if (_showScrollToBottom)
            // FloatingActionButton.small(
            //   onPressed: _onScrollToBottomPressed,
            //   shape: const CircleBorder(),
            //   heroTag: 'scroll_to_bottom',
            //   backgroundColor: Theme.of(context).colorScheme.surface,
            //   foregroundColor: Theme.of(context).colorScheme.onSurface,
            //   tooltip: '回到底部',
            //   child: const Icon(Icons.keyboard_arrow_down),
            // ),
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(top: 16),
              child: FloatingActionButton.small(
                onPressed: _onScrollToBottomPressed,
                shape: const CircleBorder(),
                heroTag: 'scroll_to_bottom',
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                tooltip: '回到底部',
                child: const Icon(Icons.keyboard_arrow_down),
              ),
            ),
        ],
      ),
    );
  }
}
