import 'package:flutter/material.dart';

import '../../../../../core/utils/datetime_formatter.dart';
import '../../../../../shared/constants/constants.dart';
import '../../../../../shared/widgets/simple_tool_widget.dart';
import '../../../data/models/daodu_models.dart';
import '../../pages/daodu/lesson_detail_page.dart';
import '../../pages/daodu/lesson_single_comment_page.dart';

/// 可滑动的卡片组件
/// 支持文章和评论的卡片式展示
/// 主要是探索页面会用到
class DaoduSwipeableCardWidget extends StatefulWidget {
  final List<dynamic> items; // 文章和评论的混合列表
  final VoidCallback? onRefresh;

  const DaoduSwipeableCardWidget({
    super.key,
    required this.items,
    this.onRefresh,
  });

  @override
  State<DaoduSwipeableCardWidget> createState() =>
      _DaoduSwipeableCardWidgetState();
}

class _DaoduSwipeableCardWidgetState extends State<DaoduSwipeableCardWidget> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '暂无内容',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 卡片区域
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              if (item is DaoduLesson) {
                return _buildArticleCard(item);
              } else if (item is DaoduComment) {
                return _buildCommentCard(item);
              }
              return const SizedBox();
            },
          ),
        ),

        // 底部控制区域
        _buildBottomControls(),
      ],
    );
  }

  Widget _buildArticleCard(DaoduLesson lesson) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => _navigateToArticleDetail(lesson),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 文章标识
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.article,
                            size: 14,
                            color: Colors.blue[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '推荐文章',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (lesson.dateByDay != null)
                      Text(
                        formatLessonDateByDay(lesson.dateByDay!),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // 文章标题
                if (lesson.title?.isNotEmpty == true)
                  Text(
                    lesson.title!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 8),

                // 文章内容预览
                if (lesson.article?.isNotEmpty == true)
                  Expanded(
                    child: Text(
                      lesson.article!,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                      maxLines: 8,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                const SizedBox(height: 8),

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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentCard(DaoduComment comment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => _navigateToCommentDetail(comment),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 评论标识和日期
                Row(
                  children: [
                    // 评论标识
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '推荐评论',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // 时间
                    if (comment.createdAt != null)
                      Text(
                        formatTimestampToString(
                          comment.createdAt.toString(),
                          format: formatToYMD,
                        ),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // 用户信息
                Row(
                  children: [
                    // 用户头像
                    buildUserCircleAvatar(comment.user?.avatar),
                    const SizedBox(width: 8),

                    // 用户名
                    Expanded(
                      child: Text(
                        comment.user?.nickname ?? '匿名用户',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // 评论内容
                if (comment.content?.isNotEmpty == true)
                  Expanded(
                    child: Text(
                      comment.content!,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                      maxLines: 8,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                const SizedBox(height: 8),

                // 底部统计
                Row(
                  children: [
                    const Spacer(),
                    if (comment.likeCount != null &&
                        comment.likeCount! > 0) ...[
                      Icon(Icons.favorite, size: 16, color: Colors.red[300]),
                      const SizedBox(width: 4),
                      Text(
                        '${comment.likeCount}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 上一个
          GestureDetector(
            onTap: _currentIndex > 0 ? _previousCard : null,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _currentIndex > 0 ? Colors.white : Colors.grey[200],
                shape: BoxShape.circle,
                boxShadow: _currentIndex > 0
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.chevron_left,
                color: _currentIndex > 0 ? Colors.grey[600] : Colors.grey[400],
                size: 24,
              ),
            ),
          ),

          // 页面指示器
          Row(
            children: [
              Text(
                '${_currentIndex + 1}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                ' / ${widget.items.length}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),

          // 下一个
          GestureDetector(
            onTap: _currentIndex < widget.items.length - 1 ? _nextCard : null,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _currentIndex < widget.items.length - 1
                    ? Colors.white
                    : Colors.grey[200],
                shape: BoxShape.circle,
                boxShadow: _currentIndex < widget.items.length - 1
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.chevron_right,
                color: _currentIndex < widget.items.length - 1
                    ? Colors.grey[600]
                    : Colors.grey[400],
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextCard() {
    if (_currentIndex < widget.items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToArticleDetail(DaoduLesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DaoduLessonDetailPage(lesson: lesson),
      ),
    );
  }

  void _navigateToCommentDetail(DaoduComment comment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DaoduLessonSingleCommentPage(comment: comment),
      ),
    );
  }

  String formatLessonDateByDay(int dateInt) {
    var str = dateInt.toString();
    return str.length == 8
        ? '${str.substring(0, 4)}-${str.substring(4, 6)}-${str.substring(6, 8)}'
        : "未知日期";
  }
}
