import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/constants/constants.dart';
import '../../../../shared/widgets/audio_player_widget.dart';
import '../../domain/entities/note_media.dart';

class NoteAudioList extends ConsumerWidget {
  final List<NoteMedia> audioList;
  final Function(NoteMedia) onDelete;
  // 是否只读
  final bool isReadOnly;
  // 初始展开状态
  final bool initiallyExpanded;

  const NoteAudioList({
    super.key,
    required this.audioList,
    required this.onDelete,
    this.isReadOnly = false,
    // 默认折叠
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioFiles = audioList.where((media) => media.isAudio).toList();

    if (audioFiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        title: Text(
          '录音列表 (${audioFiles.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 200, // 设置列表最大高度
            ),
            child: ListView.separated(
              padding: EdgeInsets.zero, // 移除默认的内边距
              shrinkWrap: true, // 根据内容调整大小
              // physics: ClampingScrollPhysics(), // 禁用过度滚动效果
              physics: const NeverScrollableScrollPhysics(),
              itemCount: audioFiles.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                final audio = audioFiles[index];
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                  leading:
                      !isReadOnly
                          ? IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () => onDelete(audio),
                          )
                          : null,
                  title: Text(
                    DateFormat(formatToYMDHMSzh).format(audio.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  subtitle: AudioPlayerWidget(
                    audioUrl: audio.mediaPath,
                    sourceType: 'file',
                    dense: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
