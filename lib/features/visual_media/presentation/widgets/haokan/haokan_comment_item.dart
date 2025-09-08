import 'package:flutter/material.dart';

import '../../../../../core/utils/datetime_formatter.dart';
import '../../../../../shared/widgets/simple_tool_widget.dart';
import '../../../data/models/haokan/haokan_models.dart';

/// 评论项组件
class HaokanCommentItem extends StatelessWidget {
  final HaokanComment comment;
  // 点赞
  final VoidCallback? onLike;
  // 查看回复
  final VoidCallback? onShowReplies;
  // 是否显示回复数量
  final bool showReplyCount;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double avatarRadius;
  final double likeIconSize;
  final bool showLevelBadge;

  const HaokanCommentItem({
    super.key,
    required this.comment,
    this.onLike,
    this.onShowReplies,
    this.showReplyCount = true,
    this.margin = const EdgeInsets.only(bottom: 16),
    this.padding = const EdgeInsets.all(16),
    this.avatarRadius = 20,
    this.likeIconSize = 16,
    this.showLevelBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户信息行
          _buildUserInfoRow(),
          const SizedBox(height: 12),
          // 评论内容
          _buildCommentContent(),
          // 回复数量
          if (showReplyCount &&
              comment.replyCount != null &&
              comment.replyCount! > 0)
            _buildReplyCount(),
        ],
      ),
    );
  }

  /// 构建用户信息行
  Widget _buildUserInfoRow() {
    return Row(
      children: [
        // 头像
        buildUserCircleAvatar(comment.uhead, radius: avatarRadius),
        const SizedBox(width: 12),
        // 用户名和时间
        Expanded(child: _buildUserInfo()),
        // 点赞按钮
        _buildLikeButton(),
      ],
    );
  }

  /// 构建用户信息
  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              comment.uname ?? '匿名用户',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(width: 8),
            if (showLevelBadge && comment.ulevel != null && comment.ulevel! > 0)
              _buildLevelBadge(),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          formatTimestampAgo(comment.ctime),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  /// 构建等级徽章
  Widget _buildLevelBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Lv.${comment.ulevel}',
        style: TextStyle(
          fontSize: 10,
          color: Colors.orange[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 构建点赞按钮
  Widget _buildLikeButton() {
    return GestureDetector(
      onTap: onLike,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              comment.hasLike == 1 ? Icons.thumb_up : Icons.thumb_up_outlined,
              size: likeIconSize,
              color: comment.hasLike == 1 ? Colors.pink[400] : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              '${comment.likeCount ?? 0}',
              style: TextStyle(
                fontSize: 12,
                color: comment.hasLike == 1
                    ? Colors.pink[400]
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建评论内容
  Widget _buildCommentContent() {
    return Text(
      comment.content ?? '',
      style: const TextStyle(fontSize: 15, height: 1.4),
    );
  }

  /// 构建回复数量
  Widget _buildReplyCount() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: onShowReplies,
        child: Text(
          '查看${comment.replyCount}条回复 >',
          style: TextStyle(fontSize: 12, color: Colors.pink[600]),
        ),
      ),
    );
  }
}

/// 评论列表组件
class HaokanCommentList extends StatelessWidget {
  final List<HaokanComment> comments;
  final ValueChanged<HaokanComment>? onLikeComment;
  final ValueChanged<HaokanComment>? onShowReplies;
  final Widget? emptyWidget;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const HaokanCommentList({
    super.key,
    required this.comments,
    this.onLikeComment,
    this.onShowReplies,
    this.emptyWidget,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) {
      return emptyWidget ?? const Center(child: Text('暂无评论'));
    }

    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        return HaokanCommentItem(
          comment: comment,
          onLike: onLikeComment != null ? () => onLikeComment!(comment) : null,
          onShowReplies: onShowReplies != null
              ? () => onShowReplies!(comment)
              : null,
        );
      },
    );
  }
}
