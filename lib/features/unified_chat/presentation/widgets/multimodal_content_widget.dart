import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:open_file/open_file.dart';

import '../../../../core/utils/screen_helper.dart';
import '../../../../shared/widgets/audio_player_widget.dart';
import '../../../../shared/widgets/image_preview_helper.dart';
import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../../../shared/widgets/video_player_widget.dart';
import '../../data/models/unified_chat_message.dart';
import '../../../../shared/widgets/markdown_render/cus_markdown_renderer.dart';

/// 多模态内容渲染组件
/// 支持文本、图片、音频、视频、文件等多种内容类型的渲染
class MultimodalContentWidget extends StatefulWidget {
  final UnifiedChatMessage message;
  final TextStyle? textStyle;

  /// 推理内容字体颜色(聊天背景模式下由外部传入配置色)
  final Color? thinkingColor;

  const MultimodalContentWidget({
    super.key,
    required this.message,
    this.textStyle,
    this.thinkingColor,
  });

  @override
  State<MultimodalContentWidget> createState() =>
      _MultimodalContentWidgetState();
}

class _MultimodalContentWidgetState extends State<MultimodalContentWidget> {
  /// 2026-09-14 分段工具卡片展开态(消息id#工具名，消息粒度内存级)
  final Set<String> _expandedToolSegKeys = {};

  // 预览文件（可选）
  Future<void> _previewFile(String filePath) async {
    try {
      // 如果是本地文件，直接打开
      await OpenFile.open(filePath);
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, '无法打开文件', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    // 2026-09-12 分段渲染(P3-10)：多轮工具调用的响应按段顺序渲染
    // 思考折叠块/正文/工具调用卡片交替；未分段旧消息走原逻辑
    final segs = widget.message.segments;
    if (segs != null && segs.isNotEmpty) {
      return _buildSegmentsContent(segs);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 推理内容（如果存在）
        if (widget.message.thinkingContent != null &&
            widget.message.thinkingContent!.isNotEmpty)
          _buildThinkingContent(),

        // 如果有多模态内容，优先渲染多模态内容
        if (widget.message.hasMultimodalContent)
          _buildMultimodalContent()
        else if (_hasMetadataAttachments())
          // 如果没有multimodalContent但有metadata中的附件，从metadata构建显示
          _buildMetadataContent()
        else
          // 否则渲染普通文本内容
          _buildTextContent(),
      ],
    );
  }

  /// 2026-09-12 分段内容渲染：思考折叠块/正文/工具卡片按时间序交替；
  /// 消息级多模态(音频等)附加在末尾
  Widget _buildSegmentsContent(List<MessageSegment> segs) {
    final children = <Widget>[];

    for (var i = 0; i < segs.length; i++) {
      final seg = segs[i];
      switch (seg.type) {
        case MessageSegmentType.thinking:
          if ((seg.text ?? '').trim().isNotEmpty) {
            children.add(_buildSegmentThinking(seg, i, segs));
          }
        case MessageSegmentType.text:
          final text = seg.text ?? '';
          // 打字机未推进的空段跳过
          if (text.trim().isNotEmpty) {
            children.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: CusMarkdownRenderer.instance.render(
                  text,
                  textStyle: widget.textStyle,
                  selectable: ScreenHelper.isDesktop(),
                ),
              ),
            );
          }
        case MessageSegmentType.toolCall:
          children.add(_buildSegmentToolCall(seg));
        case MessageSegmentType.notice:
          // 2026-09-16 系统提示横幅：与思考/工具折叠组件平级、恒展开、
          // 琥珀色底——轮次上限/[手动终止]等系统级事件统一视觉语言
          if ((seg.text ?? '').trim().isNotEmpty) {
            children.add(
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 15,
                      color: Colors.amber[800],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        seg.text!,
                        style: (widget.textStyle ?? const TextStyle()).copyWith(
                          fontSize: 12,
                          color: Colors.amber[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
      }
    }

    // 2026-09-14 正文重复修复：finishReason落库时最终轮正文会被同时
    // 塞进multimodalContent作text项(旧字段兼容逻辑，旧版渲染与此互斥
    // 不重复)；分段渲染下正文已在segments的text段——附加多模态时过滤
    // text项，只附加图片/音频/视频/文件，否则正文渲染两遍
    if (widget.message.hasMultimodalContent) {
      final nonTextItems = widget.message.multimodalContent!
          .where((item) => item.type != 'text')
          .toList();
      if (nonTextItems.isNotEmpty) {
        children.add(_buildMultimodalContent(items: nonTextItems));
      }
    } else if (_hasMetadataAttachments()) {
      children.add(_buildMetadataContent());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  /// 分段思考折叠块：流式末段标题"思考中"且默认展开；
  /// 历史段标题"已深度思考(用时x秒)"默认收起
  Widget _buildSegmentThinking(
    MessageSegment seg,
    int index,
    List<MessageSegment> segs,
  ) {
    final isLastSegment = index == segs.length - 1;
    final isThinkingNow = widget.message.isStreaming && isLastSegment;

    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        type: MaterialType.transparency,
        child: ExpansionTile(
          // 2026-09-14 标题与正文左对齐：ExpansionTile默认16px水平内边距
          // 会让"已深度思考"标题视觉上缩进/居中，归零后与markdown正文同起点
          tilePadding: EdgeInsets.zero,
          title: Text(
            isThinkingNow
                ? '思考中'
                : '已深度思考(用时${(seg.thinkingTime ?? 0) / 1000}秒)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: widget.thinkingColor ?? Colors.black54,
            ),
          ),
          initiallyExpanded: isThinkingNow,
          children: [
            // 2026-09-14 短思考内容居中修复：ExpansionTile内部用Column
            // (crossAxisAlignment固定center，不暴露参数)包裹children——
            // 短文本markdown宽度收缩后被水平居中；强制满宽使内容靠左
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.only(left: 24),
                child: RepaintBoundary(
                  child: CusMarkdownRenderer.instance.render(
                    seg.text ?? '',
                    textStyle: TextStyle(
                      color:
                          widget.thinkingColor ??
                          Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                    selectable: ScreenHelper.isDesktop(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 分段工具调用卡片：无结果时为折叠行；有结果时为可展开卡片
  /// (2026-09-14 哨兵携带结果持久化到段，展开查看原始终端输出/工具结果)
  Widget _buildSegmentToolCall(MessageSegment seg) {
    final hasResult = (seg.toolResult ?? '').trim().isNotEmpty;

    final header = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.construction,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '已调用工具: ${seg.toolName ?? ''}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // P3-14 工具执行耗时(旧消息无此数据不显示)
        if ((seg.toolElapsedMs ?? 0) > 0)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              seg.toolElapsedMs! >= 1000
                  ? '${(seg.toolElapsedMs! / 1000).toStringAsFixed(1)}s'
                  : '${seg.toolElapsedMs}ms',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ),
        if (hasResult)
          Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
      ],
    );

    if (!hasResult) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: header,
      );
    }

    // 有结果：可展开(展开态按消息id+段序记录，见_expandedToolSegKey)
    final expandKey = '${widget.message.id}#${seg.toolName ?? ""}';
    final expanded = _expandedToolSegKeys.contains(expandKey);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() {
              expanded
                  ? _expandedToolSegKeys.remove(expandKey)
                  : _expandedToolSegKeys.add(expandKey);
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: header,
            ),
          ),
          if (expanded) ...[
            Divider(
              height: 1,
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((seg.toolArgsSummary ?? '').trim().isNotEmpty) ...[
                    Text(
                      '参数:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 100),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).scaffoldBackgroundColor.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          seg.toolArgsSummary!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    '结果:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 240),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).scaffoldBackgroundColor.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        seg.toolResult!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMultimodalContent({List<UnifiedContentItem>? items}) {
    final list = items ?? widget.message.multimodalContent!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: list.map((item) => _buildContentItem(item)).toList(),
    );
  }

  Widget _buildContentItem(UnifiedContentItem item) {
    switch (item.type) {
      case 'text':
        return _buildTextItem(item.text ?? '');
      case 'image_url':
        return _buildImageItem(item);
      case 'audio':
        return _buildAudioItem(item);
      case 'video':
        return _buildVideoItem(item);
      case 'file':
        return _buildFileItem(item);
      default:
        return _buildUnknownItem(item);
    }
  }

  Widget _buildTextContent() {
    final content = widget.message.displayContent;
    if (content.isEmpty) return const SizedBox.shrink();

    return CusMarkdownRenderer.instance.render(
      content,
      textStyle: widget.textStyle,
      // 桌面直接选中文本，不再依赖右键→"选择文本"全屏弹窗
      selectable: ScreenHelper.isDesktop(),
    );
  }

  Widget _buildTextItem(String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return CusMarkdownRenderer.instance.render(
      text,
      textStyle: widget.textStyle,
      selectable: ScreenHelper.isDesktop(),
    );
  }

  Widget _buildImageItem(UnifiedContentItem item) {
    final imageUrl = item.imageUrl?.url;
    if (imageUrl == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      constraints: const BoxConstraints(maxWidth: 300, maxHeight: 300),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildImage(imageUrl),
      ),
    );
  }

  // 简单的图片预览
  Widget _buildImage(String imageUrl) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 0.3.sw,
          // 添加RepaintBoundary，避免图片重绘影响其他元素
          child: RepaintBoundary(
            // child: buildImageView(
            //   imageUrl,
            //   context,
            //   isFileUrl: true,
            //   imageErrorHint: '图片异常，请开启新对话',
            // ),
            child: buildImageViewCarouselSlider([imageUrl], aspectRatio: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildAudioItem(UnifiedContentItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 4),
          Icon(
            Icons.audiotrack,
            color: widget.textStyle?.color != null
                ? widget.textStyle!.color!.withValues(alpha: 0.7)
                : null,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.audioUrl ?? '音频文件',
                  style: widget.textStyle?.copyWith(fontSize: 12),
                  // style: TextStyle(
                  //   fontWeight: FontWeight.normal,
                  //   color: Theme.of(context).colorScheme.onSurfaceVariant,
                  // ),
                ),
                if (item.fileSize != null)
                  Text(
                    _formatFileSize(item.fileSize!),
                    style: widget.textStyle?.copyWith(fontSize: 12),
                    // style: TextStyle(
                    //   fontSize: 12,
                    //   color: Theme.of(
                    //     context,
                    //   ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    // ),
                  ),
              ],
            ),
          ),
          if (item.audioUrl != null)
            AudioPlayerWidget(audioUrl: item.audioUrl!, onlyIcon: true),
        ],
      ),
    );
  }

  Widget _buildVideoItem(UnifiedContentItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.fileName ?? '视频文件',
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.fileSize != null)
                Text(
                  _formatFileSize(item.fileSize!),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
          if (item.videoUrl != null)
            VideoPlayerWidget(videoUrl: item.videoUrl!, dense: true),
        ],
      ),
    );
  }

  Widget _buildFileItem(UnifiedContentItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getFileIcon(item.mimeType),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.fileName ?? '未知文件',
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                if (item.fileSize != null)
                  Text(
                    _formatFileSize(item.fileSize!),
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          if (item.fileUrl != null)
            IconButton(
              onPressed: () async {
                await _previewFile(item.fileUrl!);
              },
              icon: Icon(
                Icons.file_open_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUnknownItem(UnifiedContentItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.help_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Text(
            '未知内容类型: ${item.type}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String? mimeType) {
    if (mimeType == null) return Icons.insert_drive_file;

    if (mimeType.startsWith('image/')) return Icons.image;
    if (mimeType.startsWith('audio/')) return Icons.audiotrack;
    if (mimeType.startsWith('video/')) return Icons.videocam;
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('word') || mimeType.contains('document')) {
      return Icons.description;
    }
    if (mimeType.contains('excel') || mimeType.contains('spreadsheet')) {
      return Icons.table_chart;
    }
    if (mimeType.contains('powerpoint') || mimeType.contains('presentation')) {
      return Icons.slideshow;
    }
    if (mimeType.contains('zip') ||
        mimeType.contains('rar') ||
        mimeType.contains('archive')) {
      return Icons.archive;
    }

    return Icons.insert_drive_file;
  }

  /// 构建推理内容组件
  Widget _buildThinkingContent() {
    return Container(
      padding: EdgeInsets.only(bottom: 8),
      child: Material(
        type: MaterialType.transparency,
        child: ExpansionTile(
          title: Text(
            widget.message.content!.isEmpty
                ? '思考中'
                : '已深度思考(用时${(widget.message.thinkingTime ?? 0) / 1000}秒)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: widget.thinkingColor ?? Colors.black54,
            ),
          ),
          initiallyExpanded: true,
          children: [
            // 2026-09-14 同分段思考块：强制满宽防ExpansionTile内部
            // Column的center对齐使短内容居中
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.only(left: 24),
                // 使用高性能MarkdownRenderer来渲染深度思考内容，可以利用缓存机制
                child: RepaintBoundary(
                  child: CusMarkdownRenderer.instance.render(
                    widget.message.thinkingContent ?? '',
                    textStyle: TextStyle(
                      color:
                          widget.thinkingColor ??
                          Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                      // 不用斜体了，太斜了不好看，万一有人想看思考内容呢
                      // fontStyle: FontStyle.italic,
                    ),
                    selectable: ScreenHelper.isDesktop(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 检查是否有metadata中的附件
  bool _hasMetadataAttachments() {
    final metadata = widget.message.metadata;
    if (metadata == null) return false;

    return metadata.containsKey('images') ||
        metadata.containsKey('audio') ||
        metadata.containsKey('video') ||
        metadata.containsKey('videos') ||
        metadata.containsKey('files');
  }

  /// 从metadata构建多模态内容显示
  Widget _buildMetadataContent() {
    final metadata = widget.message.metadata!;
    final widgets = <Widget>[];

    // 首先显示文本内容（如果存在）
    if (widget.message.content != null && widget.message.content!.isNotEmpty) {
      widgets.add(_buildTextContent());
      widgets.add(const SizedBox(height: 8));
    }

    // 显示图片附件
    if (metadata.containsKey('images')) {
      final images = metadata['images'] as List<dynamic>;

      final imageWidgets = <Widget>[];

      for (final imagePath in images) {
        imageWidgets.add(_buildMetadataImage(imagePath.toString()));
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 文本内容放一行
          ...widgets,
          // 图片再放在一行
          Wrap(children: imageWidgets),
        ],
      );
    }

    // 显示音频附件
    if (metadata.containsKey('audio')) {
      final audioPath = metadata['audio'].toString();
      widgets.add(_buildMetadataAudio(audioPath));
    }

    // 显示视频附件
    if (metadata.containsKey('video')) {
      final videoPath = metadata['video'].toString();
      widgets.add(_buildMetadataVideo(videoPath));
    }

    // 显示视频生成结果(2026-09-02 媒体生成并入聊天：视频生成消息的metadata.videos)
    if (metadata.containsKey('videos')) {
      final videos = metadata['videos'] as List<dynamic>;
      for (final videoPath in videos) {
        widgets.add(_buildMetadataVideo(videoPath.toString()));
      }
    }

    // 显示文件附件
    if (metadata.containsKey('files')) {
      final files = metadata['files'] as List<dynamic>;
      for (final filePath in files) {
        widgets.add(_buildMetadataFile(filePath.toString()));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// 从metadata构建图片显示
  Widget _buildMetadataImage(String imagePath) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      constraints: const BoxConstraints(maxWidth: 300, maxHeight: 300),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildImage(imagePath),
      ),
    );
  }

  /// 从metadata构建音频显示
  Widget _buildMetadataAudio(String audioPath) {
    final fileName = audioPath.split('/').last;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // border: Border.all(color: widget.textStyle?.color ?? Colors.black),
        border: Border.all(
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 4),
          Icon(
            Icons.audiotrack,
            color: widget.textStyle?.color != null
                ? widget.textStyle!.color!.withValues(alpha: 0.7)
                : null,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              fileName,
              style: widget.textStyle?.copyWith(fontSize: 12),
            ),
          ),
          AudioPlayerWidget(audioUrl: audioPath, onlyIcon: true),
        ],
      ),
    );
  }

  /// 从metadata构建视频显示
  Widget _buildMetadataVideo(String videoPath) {
    final fileName = videoPath.split('/').last;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.videocam,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileName,
              style: TextStyle(
                fontWeight: FontWeight.normal,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              ToastUtils.showInfo('视频播放功能待实现');
            },
            icon: Icon(
              Icons.play_arrow,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// 从metadata构建文件显示
  Widget _buildMetadataFile(String filePath) {
    final fileName = filePath.split('/').last;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_drive_file,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileName,
              style: TextStyle(
                fontWeight: FontWeight.normal,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),

          if (filePath.trim().isNotEmpty)
            IconButton(
              onPressed: () async {
                await _previewFile(filePath);
              },
              icon: Icon(
                Icons.file_open_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
