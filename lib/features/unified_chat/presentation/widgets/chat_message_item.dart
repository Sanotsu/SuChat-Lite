import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/datetime_formatter.dart';
import '../../../../core/utils/screen_helper.dart';
import '../../../../core/utils/simple_tools.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../../branch_chat/presentation/widgets/text_edit_dialog.dart';
import '../../../branch_chat/presentation/widgets/text_selection_dialog.dart';
import '../../data/models/unified_chat_message.dart';
import '../viewmodels/unified_chat_viewmodel.dart';
import 'multimodal_content_widget.dart';

/// 聊天消息项组件
/// 参考Chatbox简单显示全都靠右
class ChatMessageItem extends StatefulWidget {
  final UnifiedChatMessage message;
  final VoidCallback? onRegenerate;
  final VoidCallback? onResend;
  final VoidCallback? onDelete;
  final VoidCallback? onCopy;
  final Function(UnifiedChatMessage)? onUpdateMessage;
  final Function(UnifiedChatMessage)? onEditMessage;

  const ChatMessageItem({
    super.key,
    required this.message,
    this.onRegenerate,
    this.onResend,
    this.onDelete,
    this.onCopy,
    this.onUpdateMessage,
    this.onEditMessage,
  });

  @override
  State<ChatMessageItem> createState() => _ChatMessageItemState();
}

class _ChatMessageItemState extends State<ChatMessageItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI头像
          _buildAvatar(context),

          SizedBox(width: 4),
          _buildMessageBubble(),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final isUser = widget.message.isUser;
    final isSystem = widget.message.isSystem;

    return CircleAvatar(
      radius: 16,
      backgroundColor: isUser
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.6),
      child: Icon(
        isUser
            ? Icons.person
            : isSystem
            ? Icons.settings
            : Icons.smart_toy,
        size: 20,
        color: isUser
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSecondary,
      ),
    );
  }

  Widget _buildMessageBubble() {
    final isUser = widget.message.isUser;

    // 消息内容
    return GestureDetector(
      onLongPressStart: (ScreenHelper.isMobile())
          ? (details) =>
                showMessageOptions(widget.message, details.globalPosition)
          : null,
      onSecondaryTapDown: (ScreenHelper.isDesktop())
          ? (details) =>
                showMessageOptions(widget.message, details.globalPosition)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 消息气泡
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width - 56,
            ),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isUser
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 搜索结果参考链接
                _buildSearchReferences(),

                // 多模态内容渲染
                MultimodalContentWidget(
                  message: widget.message,
                  textStyle: TextStyle(
                    color: isUser
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),

                // 流式生成指示器
                _buildStreaminigInfo(),

                // 错误状态
                _buildErrorInfo(),
              ],
            ),
          ),

          // 显示模型标签、消息信息
          const SizedBox(height: 4),
          _buildNote(),
        ],
      ),
    );
  }

  Widget _buildStreaminigInfo() {
    if (widget.message.isStreaming) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.message.isUser
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '生成中...',
            style: TextStyle(
              fontSize: 12,
              color: widget.message.isUser
                  ? Theme.of(
                      context,
                    ).colorScheme.onPrimary.withValues(alpha: 0.7)
                  : Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      );
    }
    return SizedBox.shrink();
  }

  Widget _buildErrorInfo() {
    if (widget.message.isError) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 16,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 4),
          Text(
            '生成失败',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      );
    }
    return SizedBox.shrink();
  }

  Widget _buildSearchReferences() {
    if (widget.message.searchReferences == null ||
        widget.message.searchReferences!.isEmpty) {
      return SizedBox.shrink();
    }

    // 放在可折叠的容器中
    return ExpansionTile(
      title: Row(
        children: [
          Icon(
            Icons.link,
            // size: 14,
            color: widget.message.isUser
                ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7)
                : Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Text(
            '参考链接',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: widget.message.isUser
                  ? Theme.of(
                      context,
                    ).colorScheme.onPrimary.withValues(alpha: 0.8)
                  : Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const SizedBox(height: 8),
            ...widget.message.searchReferences!.map(
              (ref) => _buildSearchReferenceItem(ref),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchReferenceItem(SearchReference ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        onTap: () => launchStringUrl(ref.url),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.message.isUser
                ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.message.isUser
                  ? Theme.of(
                      context,
                    ).colorScheme.onPrimary.withValues(alpha: 0.2)
                  : Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ref.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: widget.message.isUser
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (ref.description != null && ref.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    ref.description!,
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.message.isUser
                          ? Theme.of(
                              context,
                            ).colorScheme.onPrimary.withValues(alpha: 0.7)
                          : Theme.of(context).colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  ref.url,
                  style: TextStyle(
                    fontSize: 10,
                    color: widget.message.isUser
                        ? Theme.of(
                            context,
                          ).colorScheme.onPrimary.withValues(alpha: 0.6)
                        : Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNote() {
    String note = '';
    if (widget.message.tokenCount > 0) {
      note += 'tokens used: ${widget.message.tokenCount}';
    }
    // 没有保存模型的价格，所以其实没有实际的花费
    // if (widget.message.cost > 0) {
    //   note += ', cost: ${widget.message.cost}';
    // }
    if (widget.message.responseTimeMs != null) {
      note += ', response time: ${widget.message.responseTimeMs} ms';
    }
    if (!widget.message.isUser && widget.message.modelNameUsed != null) {
      note +=
          ', model: ${widget.message.platformIdUsed ?? ''}(${widget.message.modelNameUsed!})';
    }
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 0.8.sw),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: formatRelativeDate(widget.message.createdAt),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  TextSpan(
                    text: "    $note",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  ///=============================================
  /// 长按消息，显示消息选项
  ///=============================================
  void showMessageOptions(UnifiedChatMessage message, Offset overlayPosition) {
    // 添加振动反馈
    HapticFeedback.mediumImpact();

    // 只有用户消息可以编辑
    final bool isUser = message.isUser;
    // 只有AI消息可以重新生成
    final bool isAssistant = message.isAssistant;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        overlayPosition.dx,
        overlayPosition.dy,
        overlayPosition.dx + 200,
        overlayPosition.dy + 100,
      ),
      items: [
        // 复制按钮
        PopupMenuItem<String>(
          value: 'copy',
          child: buildMenuItemWithIcon(icon: Icons.copy, text: '复制文本'),
        ),
        // 选择文本按钮
        PopupMenuItem<String>(
          value: 'select',
          child: buildMenuItemWithIcon(icon: Icons.text_fields, text: '选择文本'),
        ),
        if (isUser)
          PopupMenuItem<String>(
            value: 'edit',
            child: buildMenuItemWithIcon(icon: Icons.edit, text: '编辑消息'),
          ),
        if (isUser)
          PopupMenuItem<String>(
            value: 'resend',
            child: buildMenuItemWithIcon(icon: Icons.send, text: '重新发送'),
          ),
        if (isAssistant)
          PopupMenuItem<String>(
            value: 'regenerate',
            child: buildMenuItemWithIcon(icon: Icons.refresh, text: '重新生成'),
          ),
        if (isAssistant)
          PopupMenuItem<String>(
            value: 'update_message',
            child: buildMenuItemWithIcon(icon: Icons.edit, text: '修改消息'),
          ),
        PopupMenuItem<String>(
          value: 'delete',
          child: buildMenuItemWithIcon(
            icon: Icons.delete,
            text: '删除消息',
            color: Colors.red,
          ),
        ),
      ],
    ).then((value) async {
      if (value == 'copy') {
        Clipboard.setData(ClipboardData(text: message.displayContent));
        ToastUtils.showToast('已复制到剪贴板');
      } else if (value == 'select') {
        _handleMessageSelect(message);
      } else if (value == 'update_message') {
        _handleAIResponseUpdate(message);
      } else if (value == 'edit') {
        handleUserMessageEdit(message);
        // widget.onEditMessage?.call(message);
      } else if (value == 'resend') {
        widget.onResend?.call();
      } else if (value == 'regenerate') {
        widget.onRegenerate?.call();
      } else if (value == 'delete') {
        widget.onDelete?.call();
      }
    });
  }

  // 优化菜单项样式
  Widget buildMenuItemWithIcon({
    required IconData icon,
    required String text,
    Color? color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center, // 居中对齐
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 14, color: color)),
      ],
    );
  }

  // 消息文本自由选择复制
  void _handleMessageSelect(UnifiedChatMessage message) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => TextSelectionDialog(
        text:
            message.thinkingContent != null &&
                message.thinkingContent!.isNotEmpty
            ? '【推理过程】\n${message.thinkingContent!}\n\n【AI响应】\n${message.content ?? ""}'
            : message.content ?? "",
      ),
    );
  }

  // 修改AI响应的消息
  void _handleAIResponseUpdate(UnifiedChatMessage message) {
    // 2025-04-22 有时候AI响应的内容不完整或者不对，导致格式化显示时不美观，提供手动修改。
    // 又或者对于AI响应的内容不满意，要手动修改后继续对话。
    // 和修改用户信息不同，这个AI响应的修改不会创建新分支(但感觉修改了AI的响应会不会不严谨了？？？)。
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => TextEditDialog(
        text: message.content ?? '',
        onSaved: (updatedText) async {
          var msg = message.copyWith(content: updatedText);
          widget.onUpdateMessage?.call(msg);
        },
      ),
    );
  }

  /// 编辑用户消息(其他几个其实也可以直接在这里修改)
  void handleUserMessageEdit(UnifiedChatMessage message) {
    if (!context.mounted) return;

    // 通过Provider获取ViewModel并开始编辑
    final viewModel = Provider.of<UnifiedChatViewModel>(context, listen: false);
    viewModel.startEditingUserMessage(message);
  }
}
