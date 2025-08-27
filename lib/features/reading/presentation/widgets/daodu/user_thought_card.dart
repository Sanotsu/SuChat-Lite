import 'package:flutter/material.dart';
import '../../../../../core/utils/datetime_formatter.dart';
import '../../../../../shared/constants/constants.dart';
import '../../../../../shared/widgets/expandable_text.dart';
import '../../../data/models/daodu_models.dart';

/// 用户想法卡片组件
class UserThoughtCard extends StatelessWidget {
  final DaoduUserThoughtsProfile thought;

  const UserThoughtCard({super.key, required this.thought});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 想法内容
              if (thought.thought?.content?.isNotEmpty == true)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ExpandableText(
                    text: thought.thought!.content!,
                    maxLines: 5,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                    buttonStyle: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // 相关文章信息
              if (thought.lesson != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.article,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '相关文章',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (thought.lesson!.title?.isNotEmpty == true)
                        Text(
                          thought.lesson!.title!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (thought.lesson!.provenance?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          '出自：《${thought.lesson!.provenance!}》',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // 底部信息
              Row(
                children: [
                  Icon(Icons.lightbulb, size: 14, color: Colors.purple[400]),
                  const SizedBox(width: 4),
                  Text(
                    '想法',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.purple[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    thought.thought?.createdAt != null
                        ? formatTimestampToString(
                            thought.thought!.createdAt.toString(),
                            format: formatToYMD,
                          )
                        : '未知时间',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const Spacer(),
                  if (thought.thought?.likeCount != null &&
                      thought.thought!.likeCount! > 0) ...[
                    Icon(Icons.favorite, size: 14, color: Colors.red[400]),
                    const SizedBox(width: 4),
                    Text(
                      '${thought.thought!.likeCount}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
