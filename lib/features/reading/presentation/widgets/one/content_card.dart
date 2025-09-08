import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/utils/datetime_formatter.dart';
import '../../../../../shared/constants/constants.dart';
import '../../../../../shared/widgets/image_preview_helper.dart';
import '../../../../../shared/widgets/simple_tool_widget.dart';
import '../../../data/models/one/one_category_list.dart';

/// 内容列表卡片组件
class OneContentCard extends StatelessWidget {
  final OneContent content;
  final VoidCallback onTap;
  final String displayType; // 'list' 或 'grid'
  // 是否是迷你列表(图片变小；不显示标签，只有标题和副标题各一行)
  final bool miniList;
  // 是否是迷你网格(图片变小；不显示标签，只有标题和副标题各一行)
  final bool miniGrid;

  const OneContentCard({
    super.key,
    required this.content,
    required this.onTap,
    this.displayType = 'list',
    this.miniList = false,
    this.miniGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    if (displayType == 'grid') {
      return miniGrid ? _buildMiniGridCard(context) : _buildGridCard(context);
    } else {
      return _buildListCard(context);
    }
  }

  /// 构建网格卡片(用于收音机等)
  Widget _buildGridCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图片区域（带标题叠加）
              Stack(
                children: [
                  // 图片
                  Container(
                    height: 160, // 图片区域高度
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: content.cover != null
                        ? buildNetworkOrFileImage(content.cover!)
                        : const Icon(Icons.image_not_supported, size: 48),
                  ),

                  // 如果是电台，中间有个播放图标
                  if (content.category.toString() == "8")
                    Positioned(
                      top: (160 / 2) - 24,
                      // 16 是外层的左右边距(注意，需要一行一个时才是0.5sw)
                      left: (0.5.sw - 16) - 24,
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),

                  // 标题叠加在图片上
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        content.title ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  if (content.volume != null && content.volume!.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Text(
                        content.volume ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  if (content.maketime != null && content.maketime!.isNotEmpty)
                    Positioned(
                      top: 0,
                      right: 0,
                      // 添加背景色更好与白底图片区分开来
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(2, 8, 8, 2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Text(
                          formatDateTimeString(
                            content.maketime ?? '',
                            formatType: formatToYMD,
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),

              // 内容区域
              Expanded(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 作者
                      if (content.author != null)
                        Expanded(
                          child: Row(
                            children: [
                              // 用户头像
                              buildUserCircleAvatar(content.author?.webUrl),
                              const SizedBox(width: 12),
                              Text(
                                content.author!.userName ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 点赞数
                      if (content.likeCount != null)
                        Row(
                          children: [
                            Icon(
                              Icons.favorite_border,
                              size: 16,
                              color: Colors.red[300],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${content.likeCount}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 只有图片和图片上的日期(用于图文)
  Widget _buildMiniGridCard(BuildContext context) {
    // 内容区域
    contentPart() {
      return Expanded(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 作者
              if (content.author != null)
                Expanded(
                  child: Row(
                    children: [
                      // 用户头像
                      buildUserCircleAvatar(content.author?.webUrl),
                      const SizedBox(width: 12),
                      Text(
                        content.author!.userName ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

              // 点赞数
              if (content.likeCount != null)
                Row(
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 16,
                      color: Colors.red[300],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${content.likeCount}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    }

    titlePosition(String title) {
      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
            ),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    datePosition(String dateStr) {
      return Positioned(
        top: 0,
        right: 0,
        // 添加背景色更好与白底图片区分开来
        child: Container(
          padding: const EdgeInsets.fromLTRB(2, 8, 8, 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
            ),
          ),
          child: Text(
            formatDateTimeString(dateStr, formatType: formatToYMD),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图片区域（带标题叠加）
              Stack(
                children: [
                  // 图片
                  Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: content.cover != null
                        ? buildNetworkOrFileImage(content.cover!)
                        : const Icon(Icons.image_not_supported, size: 48),
                  ),

                  if (content.maketime != null && content.maketime!.isNotEmpty)
                    datePosition(content.maketime!),

                  // 标题叠加在图片上
                  titlePosition(content.title ?? ''),
                ],
              ),
              contentPart(),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建列表卡片（用于阅读等）
  Widget _buildListCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: EdgeInsets.all(miniList ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧图片
            if (content.cover != null)
              Container(
                width: miniList ? 44 : 80,
                height: miniList ? 44 : 80,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: buildNetworkOrFileImage(content.cover!),
                ),
              ),
            // 右侧内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Text(
                    content.title ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // 副标题
                  if (content.subtitle != null)
                    Text(
                      content.subtitle!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                  // 底部信息
                  if (!miniList) const SizedBox(height: 4),
                  if (!miniList)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 分类标签
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor().withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getCategoryName(content.category),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getCategoryColor(),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // 日期
                        if (content.maketime != null)
                          Text(
                            formatDateTimeString(
                              content.maketime ?? '',
                              formatType: formatToYMD,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取分类名称
  String _getCategoryName(int? category) {
    switch (category) {
      case 0:
        return '图文';
      case 1:
        return '阅读';
      case 2:
        return '连载';
      case 3:
        return '问答';
      case 4:
        return '音乐';
      case 5:
        return '影视';
      case 8:
        return '电台';
      case 10:
        return '作者/音乐人';
      default:
        return '内容';
    }
  }

  /// 获取分类颜色
  Color _getCategoryColor() {
    switch (content.category) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.blue;
      case 3:
        return Colors.green;
      case 4:
        return Colors.purple;
      case 5:
        return Colors.red;
      case 8:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
