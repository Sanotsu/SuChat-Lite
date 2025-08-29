import 'package:flutter/material.dart';

import '../../../../../shared/widgets/image_preview_helper.dart';
import '../../../data/models/haokan/haokan_models.dart';
import '../../pages/haokan/haokan_detail_page.dart';

/// 好看漫画卡片组件
class HaokanComicCard extends StatelessWidget {
  final HaokanComic comic;
  final VoidCallback? onTap;
  final bool showDetails;
  final bool showAuthor;

  const HaokanComicCard({
    super.key,
    required this.comic,
    this.onTap,
    this.showDetails = true,
    this.showAuthor = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面图片
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: buildNetworkOrFileImage(
                    comic.pic ?? '',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // 漫画信息
            if (showDetails)
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 漫画标题
                      Text(
                        comic.title ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // 作者
                      if (comic.author != null &&
                          comic.author!.isNotEmpty &&
                          showAuthor)
                        Text(
                          comic.author!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const Spacer(),
                      // 最新章节
                      if (comic.lastchapter != null &&
                          comic.lastchapter!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.pink[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            comic.lastchapter!,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.pink[700],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 榜单漫画卡片组件（横向布局）
class HaokanRankingCard extends StatelessWidget {
  final HaokanComic comic;
  final int ranking;
  final VoidCallback? onTap;

  const HaokanRankingCard({
    super.key,
    required this.comic,
    required this.ranking,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 封面图片
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 90,
                height: 120,
                child: buildNetworkOrFileImage(
                  comic.pic ?? '',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 漫画信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Text(
                    comic.title ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // 最新章节
                  if (comic.lastchapter != null &&
                      comic.lastchapter!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: Text(
                        '更新至: ${comic.lastchapter}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.pink[700],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  const SizedBox(height: 24),
                  // 作者
                  if (comic.author != null && comic.author!.isNotEmpty)
                    Text(
                      '作者: ${comic.author}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  // 分类标签
                  if (comic.tag != null && comic.tag!.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      children: comic.tag!.split(' ').take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue[700],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            // 排名
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _getRankingColor(ranking),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$ranking',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankingColor(int ranking) {
    switch (ranking) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.orange[300]!;
      default:
        return Colors.blue[300]!;
    }
  }
}

// 构建漫画列表，首页一行2个，榜单、搜索页面、详情的推荐页面都是一行3个

/// 漫画网格列表组件
class ComicGridView extends StatelessWidget {
  final List<HaokanComic> comics;

  // 传入是否mini(是就显示 3个，间距小点；否就显示2个，间距大点)
  final bool isMini;

  // 是否可以滚动(首页的在滚动组件内，所以不允许滚动；但其他列表的则允许滚动)
  final bool isScrollable;

  const ComicGridView({
    super.key,
    required this.comics,
    this.isMini = false,
    this.isScrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(isMini ? 8 : 16),
      shrinkWrap: isScrollable ? false : true,
      physics: isScrollable ? null : const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMini ? 3 : 2,
        childAspectRatio: isMini ? (1 / 2) : (2 / 3),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: comics.length,
      itemBuilder: (context, index) {
        return HaokanComicCard(
          comic: comics[index],
          showAuthor: isMini ? false : true,
          onTap: () => _navigateToComicDetail(context, comics[index].id ?? 0),
        );
      },
    );
  }

  void _navigateToComicDetail(BuildContext context, int comicId) {
    if (comicId > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HaokanDetailPage(comicId: comicId),
        ),
      );
    }
  }
}
