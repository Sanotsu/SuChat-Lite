import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/utils/datetime_formatter.dart';
import '../../../../shared/widgets/audio_player_widget.dart';
import '../../../../shared/widgets/cus_content_width.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../../../shared/widgets/video_player_widget.dart';
import '../../data/models/media_library_item.dart';
import '../viewmodels/unified_chat_viewmodel.dart';

/// 2026-09-09 媒体面板：跨会话查看AI生成的多媒体资源及其生成条件
/// 数据源为消息记录(方案B)：图片/视频/语音产物 + 同轮prompt + 模型/参数；
/// 类型筛选 + 网格预览 + 独立详情页(内嵌播放器 + 跳转会话)
///
/// 2026-09-09 重要：viewModel由调用方传入(聊天页持有自己的局部实例，
/// 见unified_chat_page的ChangeNotifierProvider.value)——不能经全局
/// provider查找，否则loadConversation切换的是全局实例，聊天页不跟随
class MediaLibraryPage extends StatefulWidget {
  final UnifiedChatViewModel viewModel;

  const MediaLibraryPage({super.key, required this.viewModel});

  @override
  State<MediaLibraryPage> createState() => _MediaLibraryPageState();
}

class _MediaLibraryPageState extends State<MediaLibraryPage> {
  // null=全部
  MediaLibraryType? _filter;

  late Future<List<MediaLibraryItem>> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = widget.viewModel.loadMediaLibrary();
  }

  @override
  Widget build(BuildContext context) {
    return CusContentWidth.form(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('媒体面板'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '刷新',
              onPressed: () {
                setState(() {
                  _loadFuture = widget.viewModel.loadMediaLibrary();
                });
              },
            ),
          ],
        ),
        body: FutureBuilder<List<MediaLibraryItem>>(
          future: _loadFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('加载失败: ${snapshot.error}'));
            }

            final items = snapshot.data ?? const <MediaLibraryItem>[];
            final filtered = _filter == null
                ? items
                : items.where((i) => i.type == _filter).toList();

            return Column(
              children: [
                _buildFilterBar(items),
                Expanded(child: _buildGrid(filtered)),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 类型筛选条(含各类型数量)
  Widget _buildFilterBar(List<MediaLibraryItem> items) {
    int count(MediaLibraryType? type) =>
        type == null ? items.length : items.where((i) => i.type == type).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          _buildFilterChip(null, '全部', count(null)),
          _buildFilterChip(
            MediaLibraryType.image,
            '图片',
            count(MediaLibraryType.image),
          ),
          _buildFilterChip(
            MediaLibraryType.video,
            '视频',
            count(MediaLibraryType.video),
          ),
          _buildFilterChip(
            MediaLibraryType.audio,
            '语音',
            count(MediaLibraryType.audio),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(MediaLibraryType? type, String label, int count) {
    final isSelected = _filter == type;
    final theme = Theme.of(context);

    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = type),
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected ? Colors.white : null,
      ),
      selectedColor: theme.primaryColor,
    );
  }

  Widget _buildGrid(List<MediaLibraryItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.perm_media_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              _filter == null
                  ? '暂无AI生成的媒体资源\n通过图片生成/视频生成/语音合成模型生成的内容会显示在这里'
                  : '该类型下暂无媒体资源',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildGridCard(items[index]),
    );
  }

  Widget _buildGridCard(MediaLibraryItem item) {
    final theme = Theme.of(context);
    final fileExists = File(item.filePath).existsSync();

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _openDetail(item),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 预览区：图片缩略图 / 视频、音频类型图标
            Expanded(child: _buildPreview(item, fileExists)),
            // 信息区：prompt摘要 + 时间
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.prompt.isEmpty ? '(无提示词)' : item.prompt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, height: 1.3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatTimeLabel(item.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(MediaLibraryItem item, bool fileExists) {
    if (!fileExists) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.file_present, size: 32, color: Colors.grey),
            SizedBox(height: 4),
            Text('文件已移除', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      );
    }

    switch (item.type) {
      case MediaLibraryType.image:
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
          child: Image.file(
            File(item.filePath),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                const Center(child: Icon(Icons.broken_image, size: 32)),
          ),
        );
      case MediaLibraryType.video:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.play_circle_outline,
                size: 40,
                color: Theme.of(context).primaryColor,
              ),
              const Text('视频', style: TextStyle(fontSize: 11)),
            ],
          ),
        );
      case MediaLibraryType.audio:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.graphic_eq,
                size: 40,
                color: Theme.of(context).primaryColor,
              ),
              const Text('语音', style: TextStyle(fontSize: 11)),
            ],
          ),
        );
    }
  }

  /// 打开独立详情页(可内嵌播放，非弹窗)
  void _openDetail(MediaLibraryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MediaItemDetailPage(item: item, viewModel: widget.viewModel),
      ),
    );
  }
}

/// 媒体资源详情页：预览/播放 + 生成条件(prompt/模型/参数) + 跳转会话
class MediaItemDetailPage extends StatelessWidget {
  final MediaLibraryItem item;
  final UnifiedChatViewModel viewModel;

  const MediaItemDetailPage({
    super.key,
    required this.item,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileExists = File(item.filePath).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          item.type == MediaLibraryType.image
              ? '图片详情'
              : item.type == MediaLibraryType.video
              ? '视频详情'
              : '语音详情',
        ),
        elevation: 0,
      ),
      body: CusContentWidth.form(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 预览/播放区
              _buildPreviewArea(theme, fileExists),
              const SizedBox(height: 16),

              // 生成条件
              _buildSectionTitle(theme, '提示词'),
              _buildSelectableCard(
                theme,
                item.prompt.isEmpty ? '(无提示词)' : item.prompt,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(theme, '生成模型', item.modelName ?? '未记录'),
              _buildInfoRow(theme, '所属会话', item.conversationTitle),
              _buildInfoRow(theme, '生成时间', formatTimeLabel(item.createdAt)),

              // 生成参数(2026-09-09起新生成的内容才有记录)
              const SizedBox(height: 12),
              _buildSectionTitle(theme, '生成参数'),
              if (item.genParams.isNotEmpty)
                _buildParamsCard(theme, item.genParams)
              else
                Text(
                  '该内容生成于参数记录功能之前，未保存参数',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

              const SizedBox(height: 24),

              // 操作区
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: fileExists
                          ? () => _jumpToConversation(context)
                          : null,
                      icon: const Icon(Icons.chat, size: 16),
                      label: const Text('跳转到所属会话'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '跳转后可回看该资源生成时的完整对话上下文',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 预览/播放区：图片大图(可缩放)；视频/语音内嵌现有播放器直接播放
  Widget _buildPreviewArea(ThemeData theme, bool fileExists) {
    if (!fileExists) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.file_present, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              '文件已被移除或不可访问',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    switch (item.type) {
      case MediaLibraryType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: InteractiveViewer(
            maxScale: 5,
            child: Image.file(File(item.filePath), fit: BoxFit.contain),
          ),
        );
      case MediaLibraryType.video:
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: VideoPlayerWidget(videoUrl: item.filePath, dense: true),
        );
      case MediaLibraryType.audio:
        return AudioPlayerWidget(audioUrl: item.filePath);
    }
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSelectableCard(ThemeData theme, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: SelectableText(
        text,
        style: const TextStyle(fontSize: 13, height: 1.5),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildParamsCard(ThemeData theme, Map<String, dynamic> params) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: params.entries
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '${e.key}: ${e.value}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  /// 跳转回所属会话回看完整上下文
  /// 连续pop两层(详情页+面板页)回到聊天页；会话已先行加载完毕
  Future<void> _jumpToConversation(BuildContext context) async {
    // await前先取navigator，避免BuildContext跨异步间隙使用
    final navigator = Navigator.of(context);
    try {
      await viewModel.loadConversation(item.conversationId);
      navigator
        ..pop() // 关详情页
        ..pop(); // 关面板页，回到聊天页
      ToastUtils.showInfo('已跳转到所属会话');
    } catch (e) {
      ToastUtils.showError('跳转失败: $e');
    }
  }
}
