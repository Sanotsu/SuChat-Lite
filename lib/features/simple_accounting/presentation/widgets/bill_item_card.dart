import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/bill_item.dart';
import '../../domain/entities/bill_category.dart';
import 'category_icon.dart';

/// 账单条目卡片组件
class BillItemCard extends StatelessWidget {
  final BillItem billItem;
  final BillCategory? category;
  final VoidCallback? onTap;
  final bool showDate;
  final bool isDateHeader;

  const BillItemCard({
    super.key,
    required this.billItem,
    this.category,
    this.onTap,
    this.showDate = true,
    this.isDateHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    // 如果是日期头部，则显示日期和汇总信息
    if (isDateHeader) {
      return _buildDateHeader(context);
    }

    // 否则显示账单条目
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            // 分类图标
            if (category != null)
              CategoryIcon(category: category!, size: 36, selected: true)
            else
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    // 收入红色，支出绿色
                    billItem.itemType == 0
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                child: Icon(
                  billItem.itemType == 0
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  color: billItem.itemType == 0 ? Colors.red : Colors.green,
                ),
              ),
            const SizedBox(width: 8),

            // 账单信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    billItem.item,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${showDate ? '${_formatDate(billItem.time ?? billItem.date)} · ' : ''}${billItem.category}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // 金额
            Text(
              _formatAmount(billItem.value, billItem.itemType),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                // 收入红色，支出绿色
                color: billItem.itemType == 0 ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建日期头部
  Widget _buildDateHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        children: [
          Text(
            _formatDateHeader(billItem.date),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Wrap(
              children: [
                // 支出绿色，收入红色
                if (billItem.itemType == 1)
                  Text(
                    '出 ${billItem.value.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14, color: Colors.green),
                  ),
                if (billItem.itemType == 0)
                  Text(
                    '入 ${billItem.value.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14, color: Colors.red),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化日期
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  /// 格式化日期头部
  String _formatDateHeader(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        return '今天';
      } else if (date.year == yesterday.year &&
          date.month == yesterday.month &&
          date.day == yesterday.day) {
        return '昨天';
      } else {
        return DateFormat('MM月dd日 EEEE', 'zh_CN').format(date);
      }
    } catch (e) {
      return dateStr;
    }
  }

  /// 格式化金额
  String _formatAmount(double amount, int type) {
    if (type == 0) {
      return '+ ${amount.toStringAsFixed(2)}';
    } else {
      return '- ${amount.toStringAsFixed(2)}';
    }
  }
}
