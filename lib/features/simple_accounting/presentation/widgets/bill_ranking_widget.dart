import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/constants/constants.dart';

/// 账单排行项
class BillRankingItem {
  final String name;
  final String category;
  final double amount;
  final DateTime date;
  final int type; // 0-收入，1-支出
  final int? id; // 账单ID，用于跳转到详情页

  BillRankingItem({
    required this.name,
    required this.category,
    required this.amount,
    required this.date,
    required this.type,
    this.id,
  });
}

/// 账单排行组件
class BillRankingWidget extends StatefulWidget {
  final List<BillRankingItem> items;
  final String title;
  final int maxItems;
  final bool showDate;
  final Function(BillRankingItem item)? onItemTap; // 点击回调
  // 列表最大高度
  final double rankMaxHeight;
  // 是否显示边框
  final bool showBorder;
  // 是否显示标题
  final bool showTitle;
  // 是否显示符号(支出为负，收入为正)
  final bool showSymbol;
  const BillRankingWidget({
    super.key,
    required this.items,
    this.title = '账单排行',
    this.maxItems = 10,
    this.showDate = true,
    this.onItemTap,
    this.rankMaxHeight = 550,
    this.showBorder = true,
    this.showTitle = true,
    this.showSymbol = false,
  });

  @override
  State<BillRankingWidget> createState() => _BillRankingWidgetState();
}

class _BillRankingWidgetState extends State<BillRankingWidget> {
  /// 水平滚动控制器
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 按金额排序
    final sortedItems = List<BillRankingItem>.from(widget.items)
      ..sort((a, b) => b.amount.compareTo(a.amount));

    // 限制显示数量
    final displayItems = sortedItems.take(widget.maxItems).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            border:
                widget.showBorder
                    ? Border.all(color: Theme.of(context).colorScheme.outline)
                    : null,
            borderRadius: BorderRadius.circular(8),
          ),
          // 使用Scrollbar包装SingleChildScrollView，显示滚动条
          child: ConstrainedBox(
            // 最大高度200，超过则滚动
            constraints: BoxConstraints(maxHeight: widget.rankMaxHeight),
            child: Scrollbar(
              controller: _scrollController,
              // 在桌面端总是显示滚动条，在移动端根据需要显示
              thumbVisibility: true,
              thickness: 8.0,
              radius: const Radius.circular(4.0),
              interactive: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                child:
                    displayItems.isEmpty
                        ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('暂无数据'),
                          ),
                        )
                        : Column(
                          children: List.generate(
                            displayItems.length,
                            (index) => _buildRankingItem(
                              context,
                              displayItems[index],
                              index + 1,
                            ),
                          ),
                        ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建排行项
  Widget _buildRankingItem(
    BuildContext context,
    BillRankingItem item,
    int rank,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'zh_CN',
      // symbol: '¥',
      symbol: widget.showSymbol ? (item.type == 1 ? '- ' : '+ ') : '',
      decimalDigits: 2,
    );

    // 排名颜色
    Color rankColor;
    if (rank == 1) {
      rankColor = Colors.red;
    } else if (rank == 2) {
      rankColor = Colors.orange;
    } else if (rank == 3) {
      rankColor = Colors.amber;
    } else {
      rankColor = Colors.grey;
    }

    return InkWell(
      onTap: widget.onItemTap != null ? () => widget.onItemTap!(item) : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            // 排名
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rankColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$rank',
                style: TextStyle(color: rankColor, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),

            // 账单信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.showDate)
                    Text(
                      '${item.category} · ${DateFormat(formatToYMD).format(item.date)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  if (!widget.showDate)
                    Text(
                      item.category,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),

            // 金额
            Text(
              currencyFormat.format(item.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                // 支出为绿色，收入为红色
                color: item.type == 1 ? Colors.green : Colors.red,
              ),
            ),

            // 添加箭头图标，表示可点击
            if (widget.onItemTap != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
