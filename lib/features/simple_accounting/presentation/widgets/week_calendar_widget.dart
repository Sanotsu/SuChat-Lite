import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/screen_helper.dart';
import '../../../../shared/constants/constants.dart';

/// 周历组件，用于显示一周内每天的账单数据
class WeekCalendarWidget extends StatelessWidget {
  /// 周的开始日期
  final DateTime startDate;

  /// 每天的支出数据 Map<日期字符串, 金额>
  final Map<String, double> expenseData;

  /// 每天的收入数据 Map<日期字符串, 金额>
  final Map<String, double> incomeData;

  /// 当前选中的类型：0-收入，1-支出，null-全部
  final int? selectedType;

  /// 是否显示标题
  final bool showTitle;

  /// 点击了某个日期
  final Function(DateTime)? onDateTap;

  /// 构造函数
  const WeekCalendarWidget({
    super.key,
    required this.startDate,
    required this.expenseData,
    required this.incomeData,
    this.selectedType,
    this.showTitle = true,
    this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              // '每日数据(${DateFormat(constDateFormat).format(startDate)} ~ ${DateFormat(constDateFormat).format(startDate.add(Duration(days: 6)))})',
              '每日数据',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              // 星期标题行
              Row(
                children: [
                  _buildWeekTitle('周日', isWeekend: true),
                  _buildWeekTitle('周一'),
                  _buildWeekTitle('周二'),
                  _buildWeekTitle('周三'),
                  _buildWeekTitle('周四'),
                  _buildWeekTitle('周五'),
                  _buildWeekTitle('周六', isWeekend: true),
                ],
              ),
              const SizedBox(height: 8),

              // 日期行
              Row(
                children: List.generate(7, (index) {
                  final date = startDate.add(Duration(days: index));
                  return Expanded(
                    child: _buildDayCell(date, onDateTap: onDateTap),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeekTitle(String day, {bool? isWeekend = false}) {
    return Expanded(
      child: Center(
        child: Text(
          day,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isWeekend == true ? Colors.red : null,
          ),
        ),
      ),
    );
  }

  /// 构建日期单元格
  Widget _buildDayCell(DateTime date, {Function(DateTime)? onDateTap}) {
    final dateStr = DateFormat(formatToYMD).format(date);
    final expense = expenseData[dateStr] ?? 0;
    final income = incomeData[dateStr] ?? 0;

    // 根据选中类型显示金额
    double amount = 0;
    Color amountColor = Colors.black;

    // 收入红色，支出绿色
    if (selectedType == null) {
      amount = income - expense;
      amountColor = amount >= 0 ? Colors.red : Colors.green;
    } else if (selectedType == 0) {
      amount = income;
      amountColor = Colors.red;
    } else {
      amount = expense;
      amountColor = Colors.green;
    }

    final formattedValue =
        amount <= 0
            ? '-'
            : ScreenHelper.isDesktop()
            ? amount.toStringAsFixed(1)
            : amount >= 10000
            ? '${(amount / 10000).toStringAsFixed(1)}万'
            : amount.toStringAsFixed(1);

    // 当天高亮显示
    final isToday = _isToday(date);

    return GestureDetector(
      onTap: () {
        if (onDateTap != null) {
          onDateTap(date);
        }
      },
      child: Container(
        margin: EdgeInsets.all(ScreenHelper.isMobile() ? 2 : 4),
        padding: EdgeInsets.all(ScreenHelper.isMobile() ? 2 : 4),
        decoration: BoxDecoration(
          color:
              isToday
                  ? Colors.blue.withValues(alpha: 0.3)
                  : Colors.blue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(4),
          border: isToday ? Border.all(color: Colors.blue, width: 1) : null,
        ),
        child: Column(
          children: [
            // 日期
            Text(
              '${date.day}',
              style: TextStyle(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? Colors.blue : null,
              ),
            ),
            const SizedBox(height: 4),

            // 金额
            Text(
              formattedValue,
              style: TextStyle(
                fontSize: ScreenHelper.isMobile() ? 10 : 12,
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 判断是否是今天
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
