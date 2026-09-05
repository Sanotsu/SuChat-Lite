import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/screen_helper.dart';
import '../../../../core/utils/simple_tools.dart';
import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../data/models/unified_chat_message.dart';
import '../../data/models/unified_model_spec.dart';
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
          return Stack(
            children: [
              _buildEmptyState(context, viewModel),
              _buildChangeInputModeButton(viewModel),
            ],
          );
        }

        return Stack(
          children: [
            // 消息文字缩放(从旧版移植)：包裹整个消息列表，
            // 元信息区域(头像/时间戳/分支切换器)在气泡内反向固定不缩放
            MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(viewModel.textScaleFactor),
              ),
              child: NotificationListener<ScrollStartNotification>(
                onNotification: (notification) {
                  _onUserScrollStart();
                  return false;
                },
                // 桌面常显滚动条，提供滚动位置反馈与拖拽定位
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: ScreenHelper.isDesktop(),
                  // 整体排除语义树：流式高频重建+自动滚动挂载语义节点会触发
                  // Windows引擎AXTree增量更新bug("Failed to update ui::AXTree"
                  // 海量刷屏)。聊天列表无屏幕阅读器场景，排除不影响视觉与
                  // 文本选择(SelectionArea在gesture层工作)
                  child: ExcludeSemantics(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
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

                        var cmItem = ChatMessageItem(
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
                          onDelete: () => _showDeleteConfirmDialog(
                            context,
                            viewModel,
                            message,
                          ),
                          onCopy: () => _copyMessageContent(context, message),
                          // 修改完消息vm中已经更新了消息列表，这里应该就直接看到新的消息内容了
                          onUpdateMessage: message.isAssistant
                              ? (msg) => viewModel.updateMessage(msg)
                              : null,
                          onEditMessage: message.isUser
                              ? (msg) => viewModel.startEditingUserMessage(msg)
                              : null,
                        );

                        // 如果是最后一个消息，下方增加40高度，给分支按钮等显示
                        if (index == viewModel.messages.length - 1) {
                          return Column(
                            children: [cmItem, SizedBox(height: 40)],
                          );
                        } else {
                          return cmItem;
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),

            // 悬浮切换输入模式按钮
            _buildChangeInputModeButton(viewModel),

            // 悬浮滚动按钮
            _buildScrollButtons(),

            // 悬浮新建对话按钮
            // 用 Align 相对消息列表区域居中(之前用 0.5.sw 按全屏宽计算，
            // 桌面有侧栏+内容列限宽时不在消息区中心)
            // 2026-09-02 媒体生成并入聊天：点击弹出类型菜单(对齐Chatbox"新图片"入口模式)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildNewConversationButton(viewModel),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 新建对话按钮：点击弹出类型菜单(普通对话/图片生成/视频生成/语音合成)
  /// 选择生成类会自动切换到对应类型的可用模型
  Widget _buildNewConversationButton(UnifiedChatViewModel viewModel) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      tooltip: '新建对话',
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme.surface,
      onSelected: (value) {
        final type = UnifiedModelType.values.firstWhere(
          (t) => t.name == value,
          orElse: () => UnifiedModelType.cc,
        );
        viewModel.createNewConversationForType(type);
        setState(() {
          _showScrollToTop = false;
          _showScrollToBottom = false;
        });
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'cc',
          height: 44,
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline, size: 20),
              SizedBox(width: 12),
              Text('普通对话'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'image',
          height: 44,
          child: Row(
            children: [
              Icon(Icons.image_outlined, size: 20),
              SizedBox(width: 12),
              Text('图片生成'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'video',
          height: 44,
          child: Row(
            children: [
              Icon(Icons.video_camera_back_outlined, size: 20),
              SizedBox(width: 12),
              Text('视频生成'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'tts',
          height: 44,
          child: Row(
            children: [
              Icon(Icons.record_voice_over, size: 20),
              SizedBox(width: 12),
              Text('语音合成'),
            ],
          ),
        ),
      ],
      child: Container(
        // 小按钮尺寸为40*40,不够小，手动32*32包裹
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(Icons.add, size: 18, color: colorScheme.onSurface),
      ),
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
        content: const Text('确定要删除这条消息吗？\n该消息之后的所有分支回复也会一并删除，此操作不可撤销。'),
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

  // 悬浮切换键盘或语音输入按钮(桌面同样可用，语音输入不再仅限移动端)
  Widget _buildChangeInputModeButton(UnifiedChatViewModel viewModel) {
    // 如果已经归档了，不显示切换输入模式按钮
    if (viewModel.isConversationArchived) {
      return const SizedBox.shrink();
    }

    return Positioned(
      // 小按钮尺寸为40*40,不够小，手动32*32包裹
      left: 16,
      bottom: 8,
      child: SizedBox(
        width: 32,
        height: 32,
        child: FloatingActionButton.small(
          shape: const CircleBorder(),
          onPressed: () async {
            // 运行时麦克风权限仅移动端需要；桌面由系统层面管理
            if (ScreenHelper.isMobile() &&
                !(await requestMicrophonePermission())) {
              if (!mounted) return;
              commonExceptionDialog(
                context,
                '未授权语音录制权限',
                '未授权语音录制权限，无法语音输入。'
                    '\n请到“设置”->“应用”中开启权限。',
              );
              return;
            }

            viewModel.toggleInputMode();
          },
          heroTag: 'switch_input_mode',
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          tooltip: '切换输入模式',
          child: Icon(
            viewModel.isKeyboardInput ? Icons.keyboard_voice : Icons.keyboard,
          ),
        ),
      ),
    );
  }

  Widget _buildScrollButtons() {
    if (!_showScrollToTop && !_showScrollToBottom) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: 16,
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
