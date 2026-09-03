import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/datetime_formatter.dart';
import '../../../../core/utils/screen_helper.dart';
import '../../../../core/utils/simple_tools.dart';
import '../../../../shared/widgets/toast_utils.dart';
import './text_edit_dialog.dart';
import './text_selection_dialog.dart';
import '../../data/models/unified_chat_message.dart';
import '../../data/models/unified_model_spec.dart';
import '../../data/services/unified_branch_utils.dart';
import '../viewmodels/unified_chat_viewmodel.dart';
import 'multimodal_content_widget.dart';
import 'unified_branch_tree_dialog.dart';

/// 聊天消息项组件
/// 参考Chatbox简单显示全都靠右
class ChatMessageItem extends StatefulWidget {
  final UnifiedChatMessage message;
  // 更方便直接得到一些状态
  final UnifiedChatViewModel viewModel;
  final VoidCallback? onRegenerate;
  final VoidCallback? onResend;
  final VoidCallback? onDelete;
  final VoidCallback? onCopy;
  final Function(UnifiedChatMessage)? onUpdateMessage;
  final Function(UnifiedChatMessage)? onEditMessage;

  const ChatMessageItem({
    super.key,
    required this.message,
    required this.viewModel,
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
  // 是否启用背景图(气泡透明化+字体颜色配置生效)
  bool get _hasBg => widget.viewModel.hasBackgroundImage;

  // 是否简洁显示(隐藏头像/元信息/分支切换器)
  bool get _isBrief => widget.viewModel.isBriefDisplay;

  // 消息正文颜色(背景模式下使用用户配置的字体颜色)
  Color get _contentColor {
    if (_hasBg) {
      final fc = widget.viewModel.messageFontColor;
      return widget.message.isUser ? fc.userTextColor : fc.aiNormalTextColor;
    }
    return widget.message.isUser
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurfaceVariant;
  }

  // 气泡内次要元素颜色(流式指示/参考链接等)
  Color _secondaryColor({double alpha = 0.7}) {
    if (_hasBg) {
      return _contentColor.withValues(alpha: alpha);
    }
    return widget.message.isUser
        ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: alpha)
        : Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: alpha);
  }

  // 推理内容颜色(背景模式下使用配置的思考字体颜色)
  Color get _thinkingColor => _hasBg
      ? widget.viewModel.messageFontColor.aiThinkingTextColor
      : Theme.of(context).colorScheme.primary;

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI头像(简洁显示时隐藏，保留缩进占位；区域不随文字缩放)
          _buildAvatarArea(context),

          SizedBox(width: 4),
          // Flexible(loose)约束：内容窄时气泡按内容收缩，内容宽时钳制到
          // 剩余空间换行。Row 直接给子项的横向约束是无限宽，不包 Flexible
          // 会导致气泡无法换行而溢出
          Flexible(child: _buildMessageBubble()),
        ],
      ),
    );

    // 流式中的消息高频重建，其语义节点变化会触发Windows引擎AXTree增量更新bug
    // ("Failed to update ui::AXTree... will not be in the tree"海量刷屏)。
    // 流式期间将该消息整棵子树从语义树摘除(不影响视觉/文本选择)，流完自动恢复
    if (widget.message.isStreaming) {
      content = ExcludeSemantics(child: content);
    }
    return content;
  }

  // 头像区域反向固定不缩放(避免文字放大时头像行溢出，对齐旧版处理)
  Widget _buildAvatarArea(BuildContext context) {
    Widget child;
    if (_isBrief) {
      // 简洁显示：隐藏头像，保留与头像等宽的缩进占位
      child = const SizedBox(width: 32, height: 32);
    } else {
      child = _buildAvatar(context);
    }
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1)),
      child: child,
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
          // 消息气泡(背景图模式下透明底色+描边，对齐旧版)
          // 气泡宽度取父级真实约束(桌面内容列已限宽，不能再用全屏宽计算)
          LayoutBuilder(
            builder: (context, constraints) => Container(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth - 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _hasBg
                    ? Colors.transparent
                    : isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: _hasBg ? Border.all(color: _contentColor) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 搜索结果参考链接
                  _buildSearchReferences(),

                  // 多模态内容渲染
                  MultimodalContentWidget(
                    message: widget.message,
                    textStyle: TextStyle(color: _contentColor),
                    thinkingColor: _thinkingColor,
                  ),

                  // 流式生成指示器
                  _buildStreaminigInfo(),

                  // 错误状态
                  _buildErrorInfo(),
                ],
              ),
            ),
          ),

          // 显示模型标签、消息信息(简洁显示时仅保留相对时间；区域不随文字缩放)
          const SizedBox(height: 4),
          _buildNoteArea(),

          // 分支切换器(有多个兄弟分支时显示；简洁显示时隐藏；区域不随文字缩放)
          _buildBranchSwitcherArea(),
        ],
      ),
    );
  }

  // 元信息区域反向固定不缩放
  Widget _buildNoteArea() {
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1)),
      child: _buildNote(),
    );
  }

  // 分支切换器区域反向固定不缩放；简洁显示时隐藏
  Widget _buildBranchSwitcherArea() {
    if (_isBrief) return const SizedBox.shrink();
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1)),
      child: _buildBranchSwitcher(),
    );
  }

  /// 分支切换器：‹ 当前分支号/最大分支号(实际剩余分支数) ›
  /// 显示格式与旧版 branch_chat 对齐：
  ///   使用存储时的分支编号(branch_index+1)，删除某个分支后编号不复位，
  ///   括号内为当前实际存在的分支数。
  ///   例如有分支1、2、3，删除分支2后，分支1下方显示"1/3(2)"，分支3下方显示"3/3(2)"。
  /// 非流式生成时、且该消息存在兄弟分支时显示
  Widget _buildBranchSwitcher() {
    // 流式生成中的消息不显示
    if (widget.message.isStreaming) return const SizedBox.shrink();
    // system消息无分支
    if (widget.message.isSystem) return const SizedBox.shrink();

    final info = widget.viewModel.getBranchSwitchInfo(widget.message);
    if (info == null) return const SizedBox.shrink();

    final siblings = info.siblings;
    final currentIndex = info.currentIndex;
    final total = siblings.length;

    // 兄弟中最大的存储分支索引(删除分支后索引不复位，最大编号保留)
    final maxBranchIndex = siblings
        .map((s) => s.branchIndex)
        .reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBranchArrowButton(
            icon: Icons.arrow_back_ios,
            enabled: currentIndex > 0,
            tooltip: '上一个分支',
            onTap: () =>
                widget.viewModel.switchToSiblingBranch(widget.message, -1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '${widget.message.branchIndex + 1}/${maxBranchIndex + 1}($total)',
              style: TextStyle(
                color: Theme.of(context).disabledColor,
                fontSize: 12,
              ),
            ),
          ),
          _buildBranchArrowButton(
            icon: Icons.arrow_forward_ios,
            enabled: currentIndex < total - 1,
            tooltip: '下一个分支',
            onTap: () =>
                widget.viewModel.switchToSiblingBranch(widget.message, 1),
          ),
          const SizedBox(width: 4),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showBranchTreeDialog(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_tree,
                    size: 14,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '分支树',
                    style: TextStyle(
                      color: Theme.of(context).disabledColor,
                      fontSize: 12,
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

  Widget _buildBranchArrowButton({
    required IconData icon,
    required bool enabled,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 24,
      height: 24,
      child: IconButton(
        icon: Icon(icon, size: 14),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: tooltip,
        color: Theme.of(context).disabledColor,
        onPressed: enabled ? onTap : null,
      ),
    );
  }

  // 打开分支树对话框
  void _showBranchTreeDialog() {
    final viewModel = widget.viewModel;
    final currentPath =
        viewModel.currentBranchPath ??
        UnifiedBranchUtils.defaultLatestPath(viewModel.allMessages);
    if (currentPath == null) return;

    showDialog(
      context: context,
      builder: (context) => UnifiedBranchTreeDialog(
        messages: viewModel.allMessages,
        currentPath: currentPath,
        onPathSelected: (path) {
          Navigator.pop(context);
          viewModel.switchBranch(path);
        },
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
                _hasBg ? _contentColor : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '生成中...',
            style: TextStyle(fontSize: 12, color: _secondaryColor()),
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
    return Material(
      type: MaterialType.transparency,
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(Icons.link, color: _secondaryColor()),
            const SizedBox(width: 4),
            Text(
              '参考链接',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: _secondaryColor(alpha: 0.8),
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
      ),
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
                      fontSize: ScreenHelper.metaFontSize(11),
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
                    fontSize: ScreenHelper.metaFontSize(10),
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
    // 简洁显示：只保留相对时间，隐藏tokens/耗时/模型等元信息
    if (_isBrief) {
      return Row(
        children: [
          const SizedBox(width: 8),
          Text(
            formatRelativeDate(widget.message.createdAt),
            style: TextStyle(
              fontSize: ScreenHelper.metaFontSize(12),
              color: Theme.of(context).disabledColor,
            ),
          ),
        ],
      );
    }

    String note = '';
    if (widget.message.tokenCount > 0) {
      note += 'tokens used: ${widget.message.tokenCount}; ';
    }
    // 没有保存模型的价格，所以其实没有实际的花费
    // if (widget.message.cost > 0) {
    //   note += 'cost: ${widget.message.cost}; ';
    // }
    if (widget.message.responseTimeMs != null) {
      note += 'response time: ${widget.message.responseTimeMs} ms; ';
    }
    if (!widget.message.isUser && widget.message.modelNameUsed != null) {
      note +=
          'model: ${widget.message.platformIdUsed ?? ''}(${widget.message.modelNameUsed!}).';
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
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
                      fontSize: ScreenHelper.metaFontSize(12),
                    ),
                  ),
                  TextSpan(
                    text: "    $note",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).disabledColor,
                      fontSize: ScreenHelper.metaFontSize(11),
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
    // 振动反馈仅移动端(桌面无效调用)
    if (ScreenHelper.isMobile()) {
      HapticFeedback.mediumImpact();
    }

    // 只有用户消息可以编辑
    final bool isUser = message.isUser;
    // 只有AI消息可以重新生成
    final bool isAssistant = message.isAssistant;

    // 菜单弹出坐标钳制在屏幕安全范围内(约 200x440 菜单尺寸)，
    // 避免宽窗口边缘右键时菜单被挤出屏幕
    final screenSize = MediaQuery.of(context).size;
    final dx = overlayPosition.dx.clamp(8.0, screenSize.width - 216);
    final dy = overlayPosition.dy.clamp(8.0, screenSize.height - 456);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(dx, dy, dx, dy),
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
        if (isAssistant)
          PopupMenuItem<String>(
            value: 'update_message',
            child: buildMenuItemWithIcon(icon: Icons.edit, text: '修改消息'),
          ),
        // 只有对话模型才有的按钮选项
        if (widget.viewModel.currentModel != null &&
            widget.viewModel.currentModel!.type == UnifiedModelType.cc) ...[
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
        ],
        // 分支树查看(非system消息可用)
        if (!message.isSystem)
          PopupMenuItem<String>(
            value: 'branch_tree',
            child: buildMenuItemWithIcon(
              icon: Icons.account_tree,
              text: '查看分支树',
            ),
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
      } else if (value == 'branch_tree') {
        _showBranchTreeDialog();
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
