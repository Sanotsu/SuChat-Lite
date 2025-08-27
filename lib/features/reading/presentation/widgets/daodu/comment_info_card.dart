import 'package:flutter/material.dart';

import '../../../../../core/utils/datetime_formatter.dart';
import '../../../../../shared/constants/constants.dart';
import '../../../../../shared/widgets/expandable_text.dart';
import '../../../../../shared/widgets/image_preview_helper.dart';
import '../../../data/models/daodu_models.dart';
import '../../pages/daodu/user_detail_page.dart';

/// 评论信息卡片
/// 在文章的评论列表或者每日推荐评论详情页面有用到
class CommentInfoCard extends StatelessWidget {
  final DaoduComment comment;
  final VoidCallback? onUserTap;
  final String? cardTitle;
  final String emptyContentText;
  // 评论详情不用折叠，但评论列表的单个评论内容需要可以折叠
  final bool? isExpandable;
  // 如果要折叠评论内容，可以指定显示的最大行数
  final int? maxLines;

  const CommentInfoCard({
    super.key,
    required this.comment,
    this.onUserTap,
    this.cardTitle,
    this.emptyContentText = '该评论内容为空',
    this.isExpandable = false,
    this.maxLines = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题(不传则不显示，比如评论列表不会传，评论详情页会传)
          if (cardTitle != null) _buildCardTitle(context),
          // 用户信息
          _buildUserInfo(context),

          // 评论时间和点赞信息
          _buildLikeInfo(context),

          // 评论内容
          _buildCommentContent(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // 构建卡片标题
  Widget _buildCardTitle(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.comment, size: 16, color: Theme.of(context).primaryColor),
        const SizedBox(width: 4),
        Text(
          cardTitle ?? '评论内容',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // 构建用户信息
  Widget _buildUserInfo(BuildContext context) {
    return InkWell(
      onTap: onUserTap ?? () => _navigateToUserDetail(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            // 用户头像
            _buildUserAvatar(),
            const SizedBox(width: 12),
            // 用户信息
            _buildUserDetails(context),
            // 右侧箭头
            _buildArrowIcon(),
          ],
        ),
      ),
    );
  }

  // 构建用户头像
  Widget _buildUserAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.grey[300],
      child: ClipOval(
        child: comment.user?.avatar?.isNotEmpty == true
            ? buildNetworkOrFileImage(comment.user!.avatar!)
            : const Icon(Icons.person, size: 20),
      ),
    );
  }

  // 构建用户详细信息
  Widget _buildUserDetails(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户名
          Text(
            comment.user?.nickname ?? '匿名用户',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // 构建箭头图标
  Widget _buildArrowIcon() {
    return Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]);
  }

  // 构建评论内容
  Widget _buildCommentContent(BuildContext context) {
    final hasContent = comment.content?.isNotEmpty == true;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: hasContent
            ? (Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[50])
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: isExpandable == true
          ? ExpandableText(
              text: comment.content!,
              maxLines: maxLines ?? 5, // 默认显示5行
              style: const TextStyle(fontSize: 15, height: 1.5),
              buttonStyle: TextStyle(
                fontSize: 14,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            )
          : SelectableText(
              hasContent ? comment.content! : emptyContentText,
              style: TextStyle(
                fontSize: hasContent ? 16 : 14,
                height: hasContent ? 1.6 : 1.4,
                color: hasContent ? null : Colors.grey[500],
                fontStyle: hasContent ? null : FontStyle.italic,
              ),
              textAlign: TextAlign.justify,
            ),
    );
  }

  // 构建评论时间和点赞信息
  Widget _buildLikeInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(48, 8, 4, 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (comment.createdAt != null)
            Text(
              "${formatTimestampToString(comment.createdAt.toString(), format: formatToYMD)}"
              " (${formatLatestTime(DateTime.fromMillisecondsSinceEpoch(comment.createdAt! * 1000))})",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          Spacer(),

          Icon(
            Icons.favorite_border,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            '${comment.likeCount ?? 0}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToUserDetail(BuildContext context) {
    if (comment.user?.id != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DaoduUserDetailPage(userId: comment.user!.id!),
        ),
      );
    }
  }
}
