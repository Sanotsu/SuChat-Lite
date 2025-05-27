import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/image_preview_helper.dart';
import '../../../../shared/widgets/voice_chat_bubble.dart';
import '../../../../shared/constants/constants.dart';
import '../../../../core/utils/document_utils.dart';
import '../../../../core/utils/screen_helper.dart';
import '../../../../shared/widgets/markdown_render/cus_markdown_renderer.dart';
import '../../domain/entities/message_font_color.dart';
import '../../domain/entities/branch_chat_message.dart';
import '../../domain/entities/character_card.dart';
import '_small_tool_widgets.dart';

class BranchMessageItem extends StatefulWidget {
  // 用于展示的消息
  final BranchChatMessage message;
  // 是否使用背景图片(如果是，则会将消息体背景色置为透明)
  final bool? isUseBgImage;
  // 是否显示头像
  final bool? isShowAvatar;
  // 如果是角色对话可以直接传入当前角色
  final CharacterCard? character;
  // 长按消息后，点击了消息体处的回调
  final Function(BranchChatMessage, Offset)? onLongPress;

  final MessageFontColor? colorConfig;

  const BranchMessageItem({
    super.key,
    required this.message,
    this.onLongPress,
    this.isUseBgImage = false,
    this.isShowAvatar = true,
    this.character,
    this.colorConfig, // 新增颜色配置参数
  });

  @override
  State<BranchMessageItem> createState() => _BranchMessageItemState();
}

class _BranchMessageItemState extends State<BranchMessageItem>
    with AutomaticKeepAliveClientMixin {
  // 添加缓存标记，避免滚动时重建
  @override
  bool get wantKeepAlive => true;

  // 添加状态缓存变量，避免重复计算
  late bool _isUser;
  late CrossAxisAlignment _crossAxisAlignment;
  late MainAxisAlignment _mainAxisAlignment;

  // 缓存当前使用的颜色配置
  MessageFontColor? _currentColorConfig;

  @override
  void initState() {
    super.initState();
    _updateInternalState();
  }

  @override
  void didUpdateWidget(BranchMessageItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 检查颜色配置是否发生变化
    if (oldWidget.colorConfig != widget.colorConfig) {
      // 如果颜色配置变了，强制更新内部状态
      _currentColorConfig = widget.colorConfig;
      if (mounted) {
        setState(() {});
      }
    }

    // 消息变化也需要更新内部状态
    if (oldWidget.message != widget.message) {
      _updateInternalState();
    }
  }

  void _updateInternalState() {
    _isUser =
        widget.message.role == CusRole.user.name ||
        widget.message.role == CusRole.system.name;

    _crossAxisAlignment =
        _isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    _mainAxisAlignment =
        _isUser ? MainAxisAlignment.end : MainAxisAlignment.start;

    _currentColorConfig = widget.colorConfig;
  }

  // 获取文本颜色
  Color _getTextColor() {
    // 如果有传入的配置，优先使用
    if (_currentColorConfig != null) {
      if (_isUser) {
        return _currentColorConfig!.userTextColor;
      } else {
        return _currentColorConfig!.aiNormalTextColor;
      }
    }

    // 否则使用默认逻辑
    return widget.message.role == CusRole.user.name
        ? (widget.isUseBgImage == true ? Colors.blue : Colors.white)
        : widget.message.role == CusRole.system.name
        ? Colors.grey
        : Colors.black;
  }

  // 如果什么内容都没有，显示等待中
  getIsWaiting() {
    var msg = widget.message;
    return (!_isUser &&
        (msg.references == null || msg.references!.isEmpty) &&
        msg.content.isEmpty &&
        (msg.reasoningContent == null || msg.reasoningContent!.isEmpty));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      margin: EdgeInsets.all(4),
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: _crossAxisAlignment,
        children: [
          // 头像、模型名、时间戳(头像旁边的时间和模型名不缩放，避免显示溢出)
          (widget.isShowAvatar == true)
              ? MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1)),
                child: _buildAvatarAndTimestamp(),
              )
              : Row(
                mainAxisAlignment: _mainAxisAlignment,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      _formatTimeLabel(widget.message.createTime),
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),

          // 显示消息内容
          _buildMessageContent(context),

          // 如果是语音输入，显示语言文件，可点击播放
          if (widget.message.contentVoicePath != null &&
              widget.message.contentVoicePath!.trim() != "")
            _buildVoicePlayer(),

          // 显示图片
          if (widget.message.imagesUrl != null) _buildImage(context),
        ],
      ),
    );
  }

  // 头像和时间戳
  Widget _buildAvatarAndTimestamp() {
    return Row(
      mainAxisAlignment: _mainAxisAlignment,
      children: [
        if (!_isUser) _buildAvatar(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 显示角色名
              if (!_isUser && widget.message.character != null)
                Text(
                  widget.message.character!.name,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),

              // 如果角色名为空，显示模型标签
              if (!_isUser &&
                  widget.message.character?.name == null &&
                  widget.message.modelLabel != null)
                Text(
                  widget.message.modelLabel!,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),

              // 显示模型响应时间
              if (widget.message.content.trim().isNotEmpty)
                Text(
                  DateFormat(
                    constDatetimeFormat,
                  ).format(widget.message.createTime),
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
        ),
        if (_isUser) _buildAvatar(),
      ],
    );
  }

  // 头像
  Widget _buildAvatar() {
    Widget avatar =
        (!_isUser && widget.character != null)
            ? SizedBox(
              width: 30,
              height: 30,
              child: buildAvatarClipOval(widget.character!.avatar),
            )
            : CircleAvatar(
              radius: 15,
              backgroundColor: _isUser ? Colors.blue : Colors.green,
              child: Icon(
                _isUser ? Icons.person : Icons.code,
                color: Colors.white,
              ),
            );

    return Container(
      margin: EdgeInsets.only(right: _isUser ? 0 : 4, left: _isUser ? 4 : 0),
      child: avatar,
    );
  }

  // 对话消息正文部分
  Widget _buildMessageContent(BuildContext context) {
    final textColor = _getTextColor();
    Color bgColor = _isUser ? Colors.lightBlue.shade50 : Colors.grey.shade50;

    Widget mainContent;

    if (getIsWaiting()) {
      mainContent = SizedBox(
        height: 24,
        width: 100,
        child: Row(
          children: [
            SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1)),
              child: Text("处理中……"),
            ),
          ],
        ),
      );
    } else {
      mainContent = Column(
        crossAxisAlignment: _crossAxisAlignment,
        children: [
          // 联网搜索结果 - 懒加载，只在有引用时才构建
          if (widget.message.references?.isNotEmpty == true)
            buildReferencesExpansionTile(widget.message.references),

          // 深度思考 - 懒加载，只在有思考内容时才构建
          if (widget.message.reasoningContent != null &&
              widget.message.reasoningContent!.isNotEmpty)
            _buildThinkingProcess(),

          GestureDetector(
            onLongPressStart:
                (widget.onLongPress != null && ScreenHelper.isMobile())
                    ? (details) => widget.onLongPress!(
                      widget.message,
                      details.globalPosition,
                    )
                    : null,
            onSecondaryTapDown:
                (widget.onLongPress != null && ScreenHelper.isDesktop())
                    ? (details) => widget.onLongPress!(
                      widget.message,
                      details.globalPosition,
                    )
                    : null,
            child: RepaintBoundary(
              child: CusMarkdownRenderer.instance.render(
                DocumentUtils.getDisplayMessage(widget.message.content),
                textStyle: TextStyle(color: textColor, fontSize: 16),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.isUseBgImage == true ? Colors.transparent : bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isUseBgImage == true ? textColor : Colors.transparent,
        ),
      ),
      child: mainContent,
    );
  }

  // DS 的 R 系列有深度思考部分，单独展示
  Widget _buildThinkingProcess() {
    final thinkingColor =
        _currentColorConfig?.aiThinkingTextColor ?? Colors.grey;

    return Container(
      padding: EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          widget.message.content.trim().isEmpty
              ? '思考中'
              : '已深度思考(用时${(widget.message.thinkingDuration ?? 0) / 1000}秒)',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        initiallyExpanded: true,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 24),
            // 使用高性能MarkdownRenderer来渲染深度思考内容，可以利用缓存机制
            child: RepaintBoundary(
              child: CusMarkdownRenderer.instance.render(
                widget.message.reasoningContent ?? '',
                textStyle: TextStyle(color: thinkingColor, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 简单的音频播放
  Widget _buildVoicePlayer() {
    return VoiceWaveBubble(path: widget.message.contentVoicePath!);
  }

  // 简单的图片预览
  Widget _buildImage(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 0.3.sw,
          // 添加RepaintBoundary，避免图片重绘影响其他元素
          child: RepaintBoundary(
            child: buildImageView(
              widget.message.imagesUrl!.split(',')[0],
              context,
              isFileUrl: true,
              imageErrorHint: '图片异常，请开启新对话',
            ),
          ),
        ),
      ),
    );
  }
}

String _formatTimeLabel(DateTime time) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final messageDate = DateTime(time.year, time.month, time.day);

  if (messageDate == today) {
    return DateFormat('HH:mm').format(time);
  } else if (messageDate == today.subtract(const Duration(days: 1))) {
    return '昨天 ${DateFormat('HH:mm').format(time)}';
  } else {
    return DateFormat('MM-dd HH:mm').format(time);
  }
}
