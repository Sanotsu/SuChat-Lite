import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../shared/widgets/toast_utils.dart';
import '../../../data/models/tmdb/tmdb_mt_review_resp.dart';

/// 完整评论页面
/// 某条评论的完整内容(在详情页只显示前3行，点击之后进入此页面)
class TmdbFullReviewPage extends StatelessWidget {
  final TmdbReviewItem review;

  const TmdbFullReviewPage({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('评论详情'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // 占位用
          // IconButton(
          //   icon: const Icon(Icons.share),
          //   onPressed: () => shareReview(context),
          // ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () => _copyReview(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 作者信息
            _buildAuthorInfo(context),
            const SizedBox(height: 24),
            // 评论内容
            _buildReviewContent(context),
            const SizedBox(height: 24),
            // 操作按钮(占位用，后续有需要再完善)
            // buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 头像
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              (review.author?.isNotEmpty ?? false)
                  ? review.author!.substring(0, 1).toUpperCase()
                  : 'U',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review.author ?? '匿名用户',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (review.authorDetails?.rating != null) ...[
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${review.authorDetails!.rating}/10',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      _formatDate(review.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewContent(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '评论内容',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SelectableText(
            review.content ?? '暂无内容',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _likeReview(context),
            icon: const Icon(Icons.thumb_up_outlined),
            label: const Text('点赞'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _reportReview(context),
            icon: const Icon(Icons.flag_outlined),
            label: const Text('举报'),
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '未知时间';

    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '未知时间';
    }
  }

  void shareReview(BuildContext context) {
    // 实现分享功能
    ToastUtils.showInfo('分享功能开发中...');
  }

  void _copyReview(BuildContext context) {
    final content = '作者: ${review.author ?? '匿名用户'}\n\n${review.content ?? ''}';
    Clipboard.setData(ClipboardData(text: content));
    ToastUtils.showSuccess('已复制到剪贴板');
  }

  void _likeReview(BuildContext context) {
    // 实现点赞功能
    ToastUtils.showInfo('点赞功能开发中...');
  }

  void _reportReview(BuildContext context) {
    //  实现举报功能
    ToastUtils.showInfo('举报功能开发中...');
  }
}
