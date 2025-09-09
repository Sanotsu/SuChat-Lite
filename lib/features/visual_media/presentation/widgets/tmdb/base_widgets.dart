import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../data/models/tmdb/tmdb_common.dart';

/// TMDB 图片组件
class TmdbImageWidget extends StatelessWidget {
  final String? imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const TmdbImageWidget({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath == null || imagePath!.isEmpty) {
      return _buildErrorWidget();
    }

    final imageUrl = 'https://image.tmdb.org/t/p/w500$imagePath';

    // 之前封装的好像cover也不生效，是因为没有给高度吗？
    // return buildNetworkOrFileImage(imageUrl, fit: fit);

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Icon(Icons.image_not_supported, color: Colors.grey[500], size: 40),
    );
  }
}

/// TMDB 项目卡片组件
class TmdbItemCard extends StatelessWidget {
  final TmdbResultItem item;
  final VoidCallback onTap;
  final bool isHorizontal;

  const TmdbItemCard({
    super.key,
    required this.item,
    required this.onTap,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isHorizontal ? 140 : null,
        margin: EdgeInsets.only(
          right: isHorizontal ? 12 : 0,
          bottom: isHorizontal ? 0 : 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isHorizontal ? _buildHorizontalCard() : _buildVerticalCard(),
      ),
    );
  }

  Widget _buildHorizontalCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 图片
        Expanded(
          flex: 11,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: TmdbImageWidget(
              imagePath: _getImagePath(),
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
        ),
        // 信息
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getTitle(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // if (_getRating() > 0) ...[
                    //   Row(
                    //     children: [
                    //       Icon(Icons.star, color: Colors.amber, size: 12),
                    //       const SizedBox(width: 2),
                    //       Text(
                    //         _getRating().toStringAsFixed(1),
                    //         style: const TextStyle(fontSize: 10),
                    //       ),
                    //     ],
                    //   ),
                    // ],
                    // if (_getDate().isNotEmpty) ...[
                    //   const SizedBox(height: 2),
                    //   Text(
                    //     _getDate(),
                    //     style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    //   ),
                    // ],
                    Row(
                      children: [
                        if (_getRating() > 0) ...[
                          Icon(Icons.star, color: Colors.amber, size: 15),
                          const SizedBox(width: 2),
                          Text(
                            _getRating().toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                        const Spacer(),
                        if (_getDate().isNotEmpty)
                          Text(
                            _getDate(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),

                    if (_getPersonKnownFor().isNotEmpty)
                      Text(
                        _getPersonKnownFor(),
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalCard() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // 图片
          Container(
            width: 80,
            height: 120,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TmdbImageWidget(
                imagePath: _getImagePath(),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTitle(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (_getRating() > 0) ...[
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _getRating().toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${item.voteCount ?? 0})',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                // 注意，只有查询all的结果才有media_type，所以这里单独查询分类的需要显示日期
                if (_getType().isNotEmpty || _getDate().isNotEmpty) ...[
                  Row(
                    children: [
                      if (_getType().isNotEmpty)
                        Text(
                          _getType(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      const SizedBox(width: 4),
                      if (_getDate().isNotEmpty)
                        Text(
                          _getDate(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ],

                if (item.overview?.isNotEmpty ?? false) ...[
                  Text(
                    item.overview!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (_getPersonKnownFor().isNotEmpty)
                  Text(
                    _getPersonKnownFor(),
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    return item.title ?? item.name ?? '未知标题';
  }

  String? _getImagePath() {
    // TmdbResultItem 中剧集和电影的图片是 posterPath，人物的图片是 profilePath
    return item.posterPath ?? item.profilePath;
  }

  // 剧集和影片有评分
  double _getRating() {
    return item.voteAverage ?? 0.0;
  }

  // 人员没有评分，可以显示所有代表作的名称
  String _getPersonKnownFor() {
    var knowFor =
        item.knownFor
            ?.map((e) => e.title ?? e.originalTitle ?? e.name ?? e.originalName)
            .where((e) => e != null && e.isNotEmpty)
            .join(', ') ??
        '';

    return knowFor.isNotEmpty ? '代表作：$knowFor' : '';
  }

  String _getDate() {
    final date = item.releaseDate ?? item.firstAirDate;
    if (date == null || date.isEmpty) return '';

    try {
      final dateTime = DateTime.parse(date);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return date;
    }
  }

  // 获取类型
  String _getType() {
    return item.mediaType == 'tv'
        ? '剧集'
        : item.mediaType == 'movie'
        ? '电影'
        : item.mediaType == 'person'
        ? '人物'
        : '';
  }
}

/// TMDB 分区组件
class TmdbSectionWidget extends StatelessWidget {
  final String title;
  final List<TmdbResultItem> items;
  final Function(TmdbResultItem) onItemTap;
  final List<Widget>? headerActions;
  final Widget? customChild;
  final bool showMoreButton;
  final VoidCallback? onShowMore;

  const TmdbSectionWidget({
    super.key,
    required this.title,
    required this.items,
    required this.onItemTap,
    this.headerActions,
    this.customChild,
    this.showMoreButton = false,
    this.onShowMore,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和操作区域
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (headerActions != null) ...headerActions!,
              if (showMoreButton && onShowMore != null)
                TextButton(onPressed: onShowMore, child: const Text('查看更多')),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 内容区域
        if (customChild != null)
          customChild!
        else if (items.isNotEmpty)
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return TmdbItemCard(
                  item: items[index],
                  onTap: () => onItemTap(items[index]),
                  isHorizontal: true,
                );
              },
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '暂无数据',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
      ],
    );
  }
}

/// TMDB 评分组件
class TmdbRatingWidget extends StatelessWidget {
  final double rating;
  final int? voteCount;
  final double size;

  const TmdbRatingWidget({
    super.key,
    required this.rating,
    this.voteCount,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, color: Colors.amber, size: size),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(fontSize: size * 0.875, fontWeight: FontWeight.bold),
        ),
        if (voteCount != null) ...[
          const SizedBox(width: 4),
          Text(
            '($voteCount)',
            style: TextStyle(fontSize: size * 0.75, color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }
}

/// TMDB 类型标签组件
class TmdbTypeChip extends StatelessWidget {
  final String mediaType;
  final double fontSize;

  const TmdbTypeChip({super.key, required this.mediaType, this.fontSize = 10});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;

    switch (mediaType.toLowerCase()) {
      case 'movie':
        label = '电影';
        color = Colors.blue;
        break;
      case 'tv':
        label = '剧集';
        color = Colors.green;
        break;
      case 'person':
        label = '人物';
        color = Colors.orange;
        break;
      default:
        label = '未知';
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// TMDB 加载状态组件
class TmdbLoadingWidget extends StatelessWidget {
  final String? message;

  const TmdbLoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }
}

/// TMDB 空状态组件
class TmdbEmptyWidget extends StatelessWidget {
  final String message;
  final IconData? icon;
  final VoidCallback? onRetry;

  const TmdbEmptyWidget({
    super.key,
    required this.message,
    this.icon,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon ?? Icons.movie_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ],
      ),
    );
  }
}

/// TMDB 网格布局组件
class TmdbGridWidget extends StatelessWidget {
  final List<TmdbResultItem> items;
  final Function(TmdbResultItem) onItemTap;
  final int crossAxisCount;
  final double childAspectRatio;

  const TmdbGridWidget({
    super.key,
    required this.items,
    required this.onItemTap,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return TmdbItemCard(
          item: items[index],
          onTap: () => onItemTap(items[index]),
        );
      },
    );
  }
}

/// TMDB 搜索建议组件
class TmdbSearchSuggestionWidget extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onSuggestionTap;

  const TmdbSearchSuggestionWidget({
    super.key,
    required this.suggestions,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: suggestions.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.search, color: Colors.grey),
            title: Text(suggestions[index]),
            onTap: () => onSuggestionTap(suggestions[index]),
          );
        },
      ),
    );
  }
}
