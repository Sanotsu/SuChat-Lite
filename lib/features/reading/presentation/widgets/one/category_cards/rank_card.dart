import 'package:flutter/material.dart';

import '../../../../data/models/one/one_category_list.dart';

/// 热榜卡片组件
class OneRankCard extends StatelessWidget {
  final OneRank rank;
  final VoidCallback? onTap;
  final VoidCallback? onViewAll;

  const OneRankCard({
    super.key,
    required this.rank,
    this.onTap,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getHotRankColor(rank.title ?? '');
    final tag = _getHotRankTag(rank.title ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                rank.title ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                child: Text('全部 >', style: TextStyle(color: Colors.grey[600])),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.1),
                    color.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标签
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 热榜内容
                  ...((rank.contents ?? [])
                      .take(3)
                      .map(
                        (content) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '${(rank.contents?.indexOf(content) ?? 0) + 1}. ${content.title ?? ''}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 获取热榜颜色
  Color _getHotRankColor(String title) {
    if (title.contains('阅读')) {
      return Colors.blue;
    } else if (title.contains('问答')) {
      return Colors.orange;
    } else if (title.contains('春夏')) {
      return Colors.green;
    } else if (title.contains('月度')) {
      return Colors.purple;
    }
    return Colors.grey;
  }

  /// 获取热榜标签
  String _getHotRankTag(String title) {
    if (title.contains('阅读')) {
      return '#阅读';
    } else if (title.contains('问答')) {
      return '#问答';
    }
    return '#热榜';
  }
}
