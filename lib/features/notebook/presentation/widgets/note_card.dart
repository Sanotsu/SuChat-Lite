import 'package:flutter/material.dart';

import '../../../../core/utils/datetime_formatter.dart';
import '../../../../core/utils/screen_helper.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/note_tag.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final bool isListView;
  final VoidCallback onTap;
  final bool isSelectable; // 是否处于选择模式
  final bool isSelected; // 是否被选中
  final ValueChanged<bool>? onSelected; // 选择回调

  const NoteCard({
    super.key,
    required this.note,
    this.isListView = false,
    required this.onTap,
    this.isSelectable = false,
    this.isSelected = false,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // 获取笔记颜色
    final noteColor = note.getNoteColor();
    // 处理归档笔记的颜色
    final cardColor =
        note.isArchived
            ? (noteColor != null
                ? _desaturateColor(noteColor)
                : Colors.grey.shade50)
            : noteColor ?? Colors.white;

    return Card(
      color: cardColor,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        // 归档笔记添加边框
        side:
            note.isArchived
                ? BorderSide(
                  color: Colors.grey.withValues(alpha: 0.5),
                  width: 1,
                  style: BorderStyle.solid,
                )
                : isSelected
                ? const BorderSide(color: Colors.blue, width: 2)
                : BorderSide.none,
      ),
      child: Stack(
        children: [
          InkWell(
            onTap: isSelectable ? () => onSelected?.call(!isSelected) : onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部信息
                  buildNoteHeader(context),

                  // 内容预览
                  if (note.content.isNotEmpty)
                    Expanded(child: buildNoteContent(context)),

                  // 底部信息
                  buildNoteBottom(context),
                ],
              ),
            ),
          ),

          // 归档水印
          if (note.isArchived) commonArchivedLabel(),
        ],
      ),
    );
  }

  // 构建归档图标
  Widget commonArchivedLabel() {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.center,
        child: IgnorePointer(
          child: Transform.rotate(
            angle: -0.5,
            child: Text(
              '已归档',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 选择框/复选框、标题、归档图标、置顶图标 放在一行
  Widget buildNoteHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 如果是选择模式，显示选择框
        if (isSelectable)
          Padding(
            padding: const EdgeInsets.only(right: 6, top: 1),
            child: Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
          ),

        // 如果是待办事项，显示复选框
        if (note.isTodo && !isSelectable)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              note.isCompleted ? Icons.check_circle : Icons.circle_outlined,
              color: note.isCompleted ? Colors.green : Colors.grey,
            ),
          ),

        // 标题
        Expanded(
          child: Text(
            note.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              // 归档笔记文字颜色降低
              color:
                  note.isArchived
                      ? Theme.of(
                        context,
                      ).textTheme.bodyLarge?.color?.withValues(alpha: 0.7)
                      : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // 归档图标
        if (note.isArchived)
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(Icons.archive, size: 16, color: Colors.grey),
          ),

        // 如果已置顶，显示置顶图标
        if (note.isPinned) const Icon(Icons.push_pin, size: 16),
      ],
    );
  }

  /// 构建笔记内容
  Widget buildNoteContent(BuildContext context) {
    return Padding(
      padding:
          isListView
              ? const EdgeInsets.only(top: 4)
              : const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        note.content,
        style: TextStyle(
          fontSize: 14,
          color:
              note.isArchived
                  ? Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6)
                  : Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
        ),
        maxLines: isListView ? 2 : 5,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// 分类、标签、更新时间放在一行
  Widget buildNoteBottom(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 显示分类
        if (note.category != null)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:
                  note.category!.getCategoryColor()?.withValues(
                    alpha: note.isArchived ? 0.6 : 1.0,
                  ) ??
                  Colors.black12,
              borderRadius: BorderRadius.circular(0),
            ),
            child: Text(
              note.category!.name,
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
          ),

        // 显示标签(移动端空间有限，不是列表模式不显示标签)
        if (note.tags.isNotEmpty)
          Expanded(child: SizedBox(height: 18, child: commonTags(note.tags))),

        // 如果分类为空且标签为空，则占满剩余空间，让时间固定居右
        if (note.category == null && note.tags.isEmpty) const Spacer(),

        // 显示更新时间
        Text(
          formatTimeAgo(note.updatedAt.toIso8601String()),
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  // 构建标签
  Widget commonTags(List<NoteTag> nTags) {
    // 移动端非列表模式不显示标签
    if (ScreenHelper.isMobile() && !isListView) return const SizedBox.shrink();

    // 如果是列表模式，移动端可以显示5个，桌面端显示8个；非列表模式最多显示2个
    int showCount = isListView ? (ScreenHelper.isMobile() ? 5 : 8) : 2;

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      // 比如最多显示2个标签（有个+1的tag，所以超过2个都显示3个标签）
      itemCount: nTags.length > showCount ? showCount + 1 : nTags.length,
      itemBuilder: (context, index) {
        // 如果是最后一个且有更多标签，显示+n
        if (index == showCount && nTags.length > showCount) {
          return Container(
            margin: const EdgeInsets.only(right: 2),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '+${nTags.length - showCount}',
              style: const TextStyle(fontSize: 10),
            ),
          );
        }

        // 显示标签
        final tag = nTags[index];
        // 标签文字最多显示5个字符
        final displayName =
            tag.name.length > 5 ? '${tag.name.substring(0, 5)}...' : tag.name;

        return Container(
          margin: const EdgeInsets.only(right: 2),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color:
                tag.getTagColor()?.withValues(
                  alpha: note.isArchived ? 0.6 : 1.0,
                ) ??
                Colors.black12,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            displayName,
            style: const TextStyle(fontSize: 10, color: Colors.white),
          ),
        );
      },
    );
  }

  // 辅助方法：降低颜色饱和度(归档笔记)
  Color _desaturateColor(Color color) {
    final hslColor = HSLColor.fromColor(color);
    return hslColor.withSaturation(hslColor.saturation * 0.3).toColor();
  }
}
