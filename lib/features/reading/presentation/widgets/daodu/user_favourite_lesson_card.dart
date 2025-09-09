import 'package:flutter/material.dart';
import '../../../../../core/utils/datetime_formatter.dart';
import '../../../../../shared/constants/constants.dart';
import '../../../data/models/daodu_models.dart';
import '../../pages/daodu/lesson_detail_page.dart';

/// 用户喜欢文章卡片组件
class DaoduUserFavouriteLessonCard extends StatelessWidget {
  final DaoduLesson lesson;

  const DaoduUserFavouriteLessonCard({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _navigateToLessonDetail(context, lesson),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 文章标题
                if (lesson.title?.isNotEmpty == true)
                  Text(
                    lesson.title!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 12),

                // 文章内容预览
                if (lesson.article?.isNotEmpty == true)
                  Text(
                    lesson.article!,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.grey[700],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 12),

                // 底部信息
                Row(
                  children: [
                    // 出处
                    if (lesson.provenance?.isNotEmpty == true)
                      Expanded(
                        child: Text(
                          '出自：《${lesson.provenance!}》',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),

                    // 作者
                    if (lesson.author?.name?.isNotEmpty == true) ...[
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lesson.author!.name!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 8),

                // 日期
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      lesson.createdAt != null
                          ? formatTimestampToString(
                              lesson.createdAt.toString(),
                              format: formatToYMD,
                            )
                          : '未知时间',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const Spacer(),
                    Icon(Icons.favorite, size: 16, color: Colors.red[400]),
                    const SizedBox(width: 4),
                    Text(
                      '已喜欢',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToLessonDetail(BuildContext context, DaoduLesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DaoduLessonDetailPage(lesson: lesson),
      ),
    );
  }
}
