import 'package:flutter/material.dart';
import '../../../../../core/utils/datetime_formatter.dart';
import '../../../../../shared/constants/constants.dart';
import '../../../../../shared/widgets/expandable_text.dart';
import '../../../data/models/daodu_models.dart';

/// 用户摘要卡片组件
class UserSnippetCard extends StatelessWidget {
  final DaoduUserSnippetsDetail snippet;

  const UserSnippetCard({super.key, required this.snippet});

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
              // 摘要内容
              if (snippet.snippet?.content?.isNotEmpty == true)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ExpandableText(
                    text: snippet.snippet!.content!,
                    maxLines: 5,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                    buttonStyle: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // 相关文章信息
              if (snippet.lesson != null) ...[
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
                      if (snippet.lesson!.title?.isNotEmpty == true)
                        Text(
                          snippet.lesson!.title!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (snippet.lesson!.provenance?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          '出自：《${snippet.lesson!.provenance!}》',
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
                  Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    snippet.snippet?.createdAt != null
                        ? formatTimestampToString(
                            snippet.snippet!.createdAt.toString(),
                            format: formatToYMD,
                          )
                        : '未知时间',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const Spacer(),
                  Icon(Icons.note, size: 14, color: Colors.blue[400]),
                  const SizedBox(width: 4),
                  Text(
                    '摘要',
                    style: TextStyle(fontSize: 12, color: Colors.blue[400]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
