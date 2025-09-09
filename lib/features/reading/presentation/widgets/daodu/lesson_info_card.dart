import 'package:flutter/material.dart';

import '../../../data/models/daodu_models.dart';
import '../../pages/daodu/lesson_detail_page.dart';

/// 关联文章信息卡片
/// 一般是评论详情和评论列表页面显示在顶部的文章信息卡片
class DaoduLessonInfoCard extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final DaoduLesson? lessonInfo;
  final VoidCallback? onTap;
  final String cardTitle;

  const DaoduLessonInfoCard({
    super.key,
    required this.isLoading,
    this.errorMessage,
    this.lessonInfo,
    this.onTap,
    this.cardTitle = '相关文章',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          // 标题区域
          _buildCardTitle(context),

          // 内容区域
          _buildContent(context),
        ],
      ),
    );
  }

  // 构建卡片标题
  Widget _buildCardTitle(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.article_outlined,
          size: 16,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 4),
        Text(
          cardTitle,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // 构建内容区域
  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    } else if (errorMessage != null) {
      return _buildErrorState(errorMessage!);
    } else if (lessonInfo != null) {
      return _buildLessonInfo(context);
    } else {
      return _buildEmptyState();
    }
  }

  // 加载状态
  Widget _buildLoadingState() {
    return const Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 8),
        Text('加载文章信息中...', style: TextStyle(fontSize: 14)),
      ],
    );
  }

  // 错误状态
  Widget _buildErrorState(String errorMessage) {
    return Row(
      children: [
        Icon(Icons.error_outline, size: 16, color: Colors.red[400]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            errorMessage,
            style: TextStyle(fontSize: 12, color: Colors.red[400]),
          ),
        ),
      ],
    );
  }

  // 空状态
  Widget _buildEmptyState() {
    return const Text(
      '无法加载文章信息',
      style: TextStyle(fontSize: 14, color: Colors.grey),
    );
  }

  // 文章信息展示
  Widget _buildLessonInfo(BuildContext context) {
    return InkWell(
      onTap:
          onTap ??
          () {
            // 跳转到文章详情页面
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DaoduLessonDetailPage(lesson: lessonInfo),
              ),
            );
          },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 文章标题
            if (lessonInfo!.title?.isNotEmpty == true)
              _buildTitle(lessonInfo!.title!),
            const SizedBox(height: 8),
            // 文章出处
            if (lessonInfo!.provenance?.isNotEmpty == true)
              _buildProvenance(lessonInfo!.provenance!),
            const SizedBox(height: 8),
            // 作者和时间信息
            _buildMetaInfo(),
            const SizedBox(height: 8),
            // 点击提示
            _buildTapHint(context),
          ],
        ),
      ),
    );
  }

  // 构建文章标题
  Widget _buildTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  // 构建文章出处
  Widget _buildProvenance(String provenance) {
    return Text(
      "出自：《$provenance》",
      style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  // 构建元信息（作者和时间）
  Widget _buildMetaInfo() {
    return Row(
      children: [
        // 作者信息
        if (lessonInfo!.author?.name?.isNotEmpty == true) ...[
          _buildAuthorInfo(),
          const SizedBox(width: 16),
        ],
        // 时间信息
        if (lessonInfo!.dateByDay != null) _buildTimeInfo(),
      ],
    );
  }

  // 构建作者信息
  Widget _buildAuthorInfo() {
    return Row(
      children: [
        Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          lessonInfo!.author!.name!,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }

  // 构建时间信息
  Widget _buildTimeInfo() {
    return Row(
      children: [
        Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          formatLessonDateByDay(lessonInfo!.dateByDay!),
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }

  String formatLessonDateByDay(int dateInt) {
    var str = dateInt.toString();
    return str.length == 8
        ? '${str.substring(0, 4)}-${str.substring(4, 6)}-${str.substring(6, 8)}'
        : "未知日期";
  }

  // 构建点击提示
  Widget _buildTapHint(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.touch_app, size: 12, color: Theme.of(context).primaryColor),
        const SizedBox(width: 4),
        Text(
          '点击查看文章详情',
          style: TextStyle(fontSize: 11, color: Theme.of(context).primaryColor),
        ),
      ],
    );
  }
}
