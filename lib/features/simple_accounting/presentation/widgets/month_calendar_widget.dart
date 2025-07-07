import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/screen_helper.dart';
import '../../../../shared/constants/constants.dart';

///
/// 月历组件，用于显示一个月内每天的账单数据
///
class MonthCalendarWidget extends StatelessWidget {
  /// 年份
  final int year;

  /// 月份
  final int month;

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
  const MonthCalendarWidget({
    super.key,
    required this.year,
    required this.month,
    required this.expenseData,
    required this.incomeData,
    this.selectedType,
    this.showTitle = true,
    this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    // 计算当月的天数
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // 计算当月第一天是星期几（0是星期日，1是星期一...）
    final firstDayOfMonth = DateTime(year, month, 1);
    int firstDayWeekday = firstDayOfMonth.weekday; // 1-7, 周一到周日

    // 调整为从周一开始的索引（0是周一，6是周日）
    if (firstDayWeekday == 7) {
      firstDayWeekday = 0;
    }

    // 构建日历网格
    final List<Widget> dayWidgets = [];

    // 添加星期标题
    dayWidgets.addAll([
      _buildWeekTitle('周日', isWeekend: true),
      _buildWeekTitle('周一'),
      _buildWeekTitle('周二'),
      _buildWeekTitle('周三'),
      _buildWeekTitle('周四'),
      _buildWeekTitle('周五'),
      _buildWeekTitle('周六', isWeekend: true),
    ]);

    // 添加月初的空白格子
    for (int i = 0; i < firstDayWeekday; i++) {
      dayWidgets.add(_buildEmptyCell());
    }

    // 添加日期格子
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      dayWidgets.add(_buildDayCell(date, onDateTap: onDateTap));
    }

    // 添加月末的空白格子，使总数为7的倍数
    final remainingCells = (7 - (dayWidgets.length % 7)) % 7;
    for (int i = 0; i < remainingCells; i++) {
      dayWidgets.add(_buildEmptyCell());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTitle)
          Padding(
            padding: EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              '${DateFormat(formatToYMzh).format(DateTime(year, month))}每日数据',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

        Container(
          padding: const EdgeInsets.all(1),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 固定每个单元格的高度
              const cellHeight = 60.0;
              // 计算单元格宽度（总宽度/7）
              final cellWidth = constraints.maxWidth / 7;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 7,
                childAspectRatio: cellWidth / cellHeight, // 动态计算宽高比
                children: dayWidgets,
              );
            },
          ),
        ),
      ],
    );
  }

  /// 构建星期标题单元格
  Widget _buildWeekTitle(String text, {bool? isWeekend = false}) {
    return Container(
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isWeekend == true ? Colors.red : null,
        ),
      ),
    );
  }

  /// 构建空白单元格
  Widget _buildEmptyCell() {
    return Container();
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 60, // 与cellHeight保持一致
        ),
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
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 均匀分布
            mainAxisSize: MainAxisSize.min,
            children: [
              // 日期
              Text(
                '${date.day}',
                style: TextStyle(
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? Colors.blue : null,
                ),
              ),
              const SizedBox(height: 2),

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
