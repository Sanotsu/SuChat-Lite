import 'package:flutter/material.dart';

import '../../../data/models/tmdb/tmdb_mt_credit_resp.dart';
import 'base_widgets.dart';

/// 演职表组件
/// 卡片显示宽度图片高度等尽量和 TmdbSectionWidget 中一致
class TmdbCastCrewWidget extends StatelessWidget {
  final String title;
  final List<TmdbCredit> items;
  final Function(TmdbCredit) onItemTap;
  final bool showMoreButton;
  final VoidCallback? onShowMore;
  final int maxItems;

  const TmdbCastCrewWidget({
    super.key,
    required this.title,
    required this.items,
    required this.onItemTap,
    this.showMoreButton = false,
    this.onShowMore,
    this.maxItems = 10,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final displayItems = showMoreButton && items.length > maxItems
        ? items.take(maxItems).toList()
        : items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和查看更多按钮
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (showMoreButton &&
                  items.length > maxItems &&
                  onShowMore != null)
                TextButton(onPressed: onShowMore, child: const Text('查看更多')),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 演职表列表
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: displayItems.length,
            itemBuilder: (context, index) {
              final item = displayItems[index];
              return _buildCastCrewCard(context, item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCastCrewCard(BuildContext context, TmdbCredit item) {
    var childWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 头像
        Expanded(
          flex: 11,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: TmdbImageWidget(
              imagePath: item.profilePath,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
        ),

        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 姓名
                Text(
                  item.name ?? '',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // 角色/职务
                Text(
                  item.character ?? item.job ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: () => onItemTap(item),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
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
        child: childWidget,
      ),
    );
  }
}
