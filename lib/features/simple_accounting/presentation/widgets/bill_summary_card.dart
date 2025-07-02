import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 账单摘要卡片组件
class BillSummaryCard extends StatelessWidget {
  /// 标题
  final String title;

  /// 收入金额
  final double income;

  /// 支出金额
  final double expense;

  /// 结余金额
  final double balance;

  /// 构造函数
  const BillSummaryCard({
    super.key,
    required this.title,
    required this.income,
    required this.expense,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'zh_CN',
      symbol: '¥',
      decimalDigits: 2,
    );

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧标题（靠左）
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            // 右侧金额列表（靠右）
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end, // 整体靠右
              children: [
                // 收入红色，支出绿色
                _buildSummaryItem(
                  context,
                  '收入',
                  currencyFormat.format(income),
                  Colors.red,
                ),
                _buildSummaryItem(
                  context,
                  '支出',
                  currencyFormat.format(expense),
                  Colors.green,
                ),
                _buildSummaryItem(
                  context,
                  '结余',
                  currencyFormat.format(balance),
                  balance >= 0 ? Colors.blue : Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建摘要项（固定宽度，标签左对齐，金额右对齐）
  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String amount,
    Color color,
  ) {
    return SizedBox(
      width: 160, // 固定宽度，确保所有项对齐(正常显示千万，但几十看起来空很多)
      child: Row(
        children: [
          // 标签（左对齐）
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),

          // 金额（右对齐）
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
