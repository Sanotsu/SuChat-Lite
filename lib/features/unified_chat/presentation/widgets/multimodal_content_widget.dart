import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/audio_player_widget.dart';
import '../../../../shared/widgets/image_preview_helper.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../../../shared/widgets/video_player_widget.dart';
import '../../data/models/unified_chat_message.dart';
import '../../../../shared/widgets/markdown_render/cus_markdown_renderer.dart';

/// 多模态内容渲染组件
/// 支持文本、图片、音频、视频、文件等多种内容类型的渲染
class MultimodalContentWidget extends StatefulWidget {
  final UnifiedChatMessage message;
  final TextStyle? textStyle;

  const MultimodalContentWidget({
    super.key,
    required this.message,
    this.textStyle,
  });

  @override
  State<MultimodalContentWidget> createState() =>
      _MultimodalContentWidgetState();
}

class _MultimodalContentWidgetState extends State<MultimodalContentWidget> {
  @override
  Widget build(BuildContext context) {
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

  Widget _buildMultimodalContent() {
    final items = widget.message.multimodalContent!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => _buildContentItem(item)).toList(),
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

    // 对于AI助手的回复，使用Markdown渲染
    // if (widget.message.isAssistant) {
    //   return CusMarkdownRenderer.instance.render(
    //     content,
    //     textStyle: widget.textStyle,
    //     selectable: true,
    //   );
    // }

    // // 用户消息使用普通文本
    // return SelectableText(content, style: widget.textStyle);

    return CusMarkdownRenderer.instance.render(
      content,
      textStyle: widget.textStyle,
    );
  }

  Widget _buildTextItem(String text) {
    if (text.isEmpty) return const SizedBox.shrink();

    // 对于AI助手的回复，使用Markdown渲染
    if (widget.message.isAssistant) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: CusMarkdownRenderer.instance.render(
          text,
          textStyle: widget.textStyle,
          selectable: true,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SelectableText(text, style: widget.textStyle),
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).disabledColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 4),
          Icon(Icons.audiotrack),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.fileName ?? '音频文件',
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          ),
          if (item.audioUrl != null)
            AudioPlayerWidget(audioUrl: item.audioUrl!, onlyIcon: true),
        ],
      ),
    );
  }

  Widget _buildVideoItem(UnifiedContentItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
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
      margin: const EdgeInsets.symmetric(vertical: 8),
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
          ),
          IconButton(
            onPressed: () {
              // TODO: 实现文件下载/打开功能
              ToastUtils.showInfo('文件操作功能待实现');
            },
            icon: Icon(
              Icons.download,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnknownItem(UnifiedContentItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
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
      child: ExpansionTile(
        title: Text(
          widget.message.content!.isEmpty
              ? '思考中'
              : '已深度思考(用时${(widget.message.thinkingTime ?? 0) / 1000}秒)',
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
                widget.message.thinkingContent ?? '',
                textStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        // border: Border.all(color: widget.textStyle?.color ?? Colors.black),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 4),
          Icon(Icons.audiotrack),
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
      margin: const EdgeInsets.symmetric(vertical: 8),
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
      margin: const EdgeInsets.symmetric(vertical: 8),
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
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              ToastUtils.showInfo('文件操作功能待实现');
            },
            icon: Icon(
              Icons.download,
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
