import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../shared/widgets/simple_tool_widget.dart';
import '../../../data/models/tmdb/tmdb_mt_review_resp.dart';
import '../../widgets/tmdb/base_widgets.dart';

/// TMDB 评论页面
class TmdbReviewsPage extends StatefulWidget {
  final String title;
  final List<TmdbReviewItem> reviews;

  const TmdbReviewsPage({
    super.key,
    required this.title,
    required this.reviews,
  });

  @override
  State<TmdbReviewsPage> createState() => _TmdbReviewsPageState();
}

class _TmdbReviewsPageState extends State<TmdbReviewsPage> {
  final Map<String, bool> _expandedReviews = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: widget.reviews.isEmpty
          ? const TmdbEmptyWidget(
              message: '暂无评论',
              icon: Icons.rate_review_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.reviews.length,
              itemBuilder: (context, index) {
                return _buildReviewCard(widget.reviews[index]);
              },
            ),
    );
  }

  /// 构建评论卡片
  Widget _buildReviewCard(TmdbReviewItem review) {
    final isExpanded = _expandedReviews[review.id] ?? false;
    final content = review.content ?? '';
    final shouldShowExpand = content.length > 300;
    final displayContent = shouldShowExpand && !isExpanded
        ? '${content.substring(0, 300)}...'
        : content;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户信息
            Row(
              children: [
                buildUserCircleAvatar(
                  _getAvatarUrl(review.authorDetails!.avatarPath ?? ''),
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.author ?? '匿名用户',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (review.authorDetails?.username?.isNotEmpty ?? false)
                        Text(
                          '@${review.authorDetails!.username}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                // 评分
                if (review.authorDetails?.rating != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getRatingColor(review.authorDetails!.rating!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${review.authorDetails!.rating}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // 发布时间
            if (review.createdAt?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _formatDate(review.createdAt!),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            // 评论内容
            if (content.isNotEmpty) ...[
              Text(
                displayContent,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              if (shouldShowExpand) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _expandedReviews[review.id!] = !isExpanded;
                    });
                  },
                  child: Text(
                    isExpanded ? '收起' : '展开',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
            // 操作按钮(占位，后续有需要在完善)
            const SizedBox(height: 12),
            // buildActionButton(review),
          ],
        ),
      ),
    );
  }

  Row buildActionButton(TmdbReviewItem review) {
    return Row(
      children: [
        // 查看原文链接
        if (review.url?.isNotEmpty ?? false)
          TextButton.icon(
            onPressed: () => _launchUrl(review.url!),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('查看原文'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        const Spacer(),
        // 点赞按钮（占位）
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('点赞功能待实现')));
          },
          icon: const Icon(Icons.thumb_up_outlined, size: 20),
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(8),
        ),
        // 分享按钮
        IconButton(
          onPressed: () {
            _shareReview(review);
          },
          icon: const Icon(Icons.share_outlined, size: 20),
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(8),
        ),
      ],
    );
  }

  /// 获取头像URL
  String _getAvatarUrl(String avatarPath) {
    if (avatarPath.isEmpty) {
      return "";
    }

    if (avatarPath.startsWith('http')) {
      return avatarPath;
    }
    if (avatarPath.startsWith('/https://')) {
      return avatarPath.substring(1);
    }
    return 'https://image.tmdb.org/t/p/w200$avatarPath';
  }

  /// 根据评分获取颜色
  Color _getRatingColor(int rating) {
    if (rating >= 8) {
      return Colors.green;
    } else if (rating >= 6) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  /// 格式化日期
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()}年前';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()}个月前';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}天前';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}小时前';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}分钟前';
      } else {
        return '刚刚';
      }
    } catch (e) {
      return dateStr;
    }
  }

  /// 启动URL
  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('无法打开链接')));
      }
    }
  }

  /// 分享评论
  void _shareReview(TmdbReviewItem review) {
    // 实现分享功能
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('分享功能待实现')));
  }
}
