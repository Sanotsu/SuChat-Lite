import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/utils/datetime_formatter.dart';
import '../../../../../shared/widgets/image_preview_helper.dart';
import '../../../../../shared/widgets/simple_tool_widget.dart';
import '../../../data/models/one/one_daily_recommend.dart';

/// 每日推荐内容卡片
class OneRecommendCard extends StatelessWidget {
  final OneRecommendContent content;
  final VoidCallback onTap;

  const OneRecommendCard({
    super.key,
    required this.content,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          // child: AspectRatio(
          //   aspectRatio: 0.8,
          child: Column(
            children: [
              // 图片区域
              Expanded(flex: 2, child: _buildImageSection()),
              // 内容区域
              Expanded(flex: 1, child: _buildContentSection(context)),
            ],
            // ),
          ),
        ),
      ),
    );
  }

  /// 构建图片区域
  Widget _buildImageSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: _getBackgroundColor()),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 背景图片
          if (content.imgUrl != null) buildNetworkOrFileImage(content.imgUrl!),
          // 渐变遮罩
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
          // 分类标签
          Positioned(top: 16, right: 16, child: _buildCategoryChip()),
          // 标题
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Text(
              "${content.title ?? ''}"
              "${(content.picInfo != null && content.picInfo!.isNotEmpty) ? " | ${content.picInfo}" : ""}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 3,
                    color: Colors.black54,
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 如果是电台，中间加一个播放按钮意思一下
          if (content.category?.toString() == '8')
            Positioned(
              top: (200 / 2) - 24,
              // 16 是外层的左右边距
              left: (0.5.sw - 16) - 24,
              child: Icon(
                Icons.play_circle_outline,
                size: 48,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContentSection(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 副标题或简介
          if (content.forward != null || content.subtitle != null)
            Expanded(
              child: Text(
                content.forward ?? content.subtitle ?? '',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 14,
                  height: 1.2,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          const SizedBox(height: 8),

          // 作者信息
          if (content.author != null || content.textAuthorInfo != null)
            Row(
              children: [
                buildUserCircleAvatar(content.author?.webUrl, radius: 12),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    content.author?.userName ??
                        content.textAuthorInfo?.textAuthorName ??
                        '',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // 发布日期
                if (content.postDate != null)
                  Text(
                    formatRelativeDate(content.postDate!),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),

                // 点赞数
                if (content.likeCount != null)
                  Row(
                    children: [
                      const SizedBox(width: 16),
                      Icon(Icons.favorite, size: 16, color: Colors.red[300]),
                      const SizedBox(width: 4),
                      Text(
                        '${content.likeCount}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }

  /// 构建分类标签
  Widget _buildCategoryChip() {
    final categoryName = _getCategoryName(content.category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        categoryName,
        style: TextStyle(
          color: _getCategoryColor(),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 获取分类名称
  String _getCategoryName(String? category) {
    switch (category) {
      case '0':
        return '图文';
      case '1':
        return '阅读';
      case '3':
        return '问答';
      case '4':
        return '音乐';
      case '5':
        return '影视';
      case '8':
        return '电台';
      default:
        return '内容';
    }
  }

  /// 获取分类颜色
  Color _getCategoryColor() {
    switch (content.category) {
      case '0':
        return Colors.orange;
      case '1':
        return Colors.blue;
      case '3':
        return Colors.green;
      case '4':
        return Colors.purple;
      case '5':
        return Colors.red;
      case '8':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  /// 获取背景颜色
  Color _getBackgroundColor() {
    if (content.contentBgcolor != null) {
      try {
        return Color(
          int.parse(content.contentBgcolor!.replaceFirst('#', '0xFF')),
        );
      } catch (e) {
        // 解析失败时使用默认颜色
      }
    }
    return Colors.grey[200]!;
  }
}
