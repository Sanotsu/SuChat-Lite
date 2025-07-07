import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/screen_helper.dart';
import '../../../../shared/constants/constants.dart';

/// 自定义日历组件，用于显示月份账单数据
class CustomMonthCalendar extends StatefulWidget {
  /// 选中的年份
  final int year;

  /// 选中的月份
  final int month;

  /// 支出数据，按日期映射
  final Map<String, double> expenseData;

  /// 收入数据，按日期映射
  final Map<String, double> incomeData;

  /// 选中的类型：0-收入，1-支出
  final int selectedType;

  /// 日期选择回调
  final Function(DateTime)? onDaySelected;

  /// 构造函数
  const CustomMonthCalendar({
    super.key,
    required this.year,
    required this.month,
    required this.expenseData,
    required this.incomeData,
    required this.selectedType,
    this.onDaySelected,
  });

  @override
  State<CustomMonthCalendar> createState() => _CustomMonthCalendarState();
}

class _CustomMonthCalendarState extends State<CustomMonthCalendar> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime(widget.year, widget.month, 1);
    _selectedDay = DateTime.now();
  }

  @override
  void didUpdateWidget(CustomMonthCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.year != widget.year || oldWidget.month != widget.month) {
      _focusedDay = DateTime(widget.year, widget.month, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 计算当月的第一天和最后一天
    final firstDay = DateTime(widget.year, widget.month, 1);
    final lastDay = DateTime(widget.year, widget.month + 1, 0);

    return TableCalendar(
      firstDay: firstDay,
      lastDay: lastDay,
      focusedDay: _focusedDay,
      calendarFormat: CalendarFormat.month,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        if (!isSameDay(_selectedDay, selectedDay)) {
          setState(() {
            _selectedDay = selectedDay;
          });

          if (widget.onDaySelected != null) {
            widget.onDaySelected!(selectedDay);
          }
        }
      },
      // 禁用页面切换
      onPageChanged: (focusedDay) {
        // 不做任何处理，保持在当前月
      },
      // 禁用格式切换
      availableCalendarFormats: const {CalendarFormat.month: '月视图'},
      calendarStyle: CalendarStyle(
        markersMaxCount: 1,
        markersAlignment: Alignment.bottomCenter,
        todayDecoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: theme.primaryColor,
          shape: BoxShape.circle,
        ),
        outsideDaysVisible: false,
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          final dateStr = DateFormat(formatToYMD).format(date);
          double value = 0;

          if (widget.selectedType == 0) {
            value = widget.incomeData[dateStr] ?? 0;
          } else {
            value = widget.expenseData[dateStr] ?? 0;
          }

          if (value <= 0) {
            return null;
          }

          // 格式化金额显示
          final formattedValue =
              value >= 10000
                  ? '${(value / 10000).toStringAsFixed(1)}万'
                  : value.toStringAsFixed(0);

          // 收入红色，支出绿色
          final color = widget.selectedType == 0 ? Colors.red : Colors.green;

          return Positioned(
            bottom: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                formattedValue,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
        dowBuilder: (context, day) {
          final text = DateFormat.E('zh_CN').format(day);

          return Center(
            child: Text(
              text,
              style: TextStyle(
                color:
                    day.weekday == DateTime.sunday ||
                            day.weekday == DateTime.saturday
                        ? Colors.red
                        : null,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
        headerTitleBuilder: (context, month) {
          return Center(
            child: Text(
              DateFormat(formatToYMzh, 'zh_CN').format(month),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
      locale: 'zh_CN',
      // 在外面有标题，所以这里不需要显示
      headerVisible: false,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        leftChevronVisible: false,
        rightChevronVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// 自定义周日历组件
class CustomWeekCalendar extends StatefulWidget {
  /// 开始日期
  final DateTime startDate;

  /// 支出数据，按日期映射
  final Map<String, double> expenseData;

  /// 收入数据，按日期映射
  final Map<String, double> incomeData;

  /// 选中的类型：0-收入，1-支出
  final int selectedType;

  /// 日期选择回调
  final Function(DateTime)? onDaySelected;

  /// 构造函数
  const CustomWeekCalendar({
    super.key,
    required this.startDate,
    required this.expenseData,
    required this.incomeData,
    required this.selectedType,
    this.onDaySelected,
  });

  @override
  State<CustomWeekCalendar> createState() => _CustomWeekCalendarState();
}

class _CustomWeekCalendarState extends State<CustomWeekCalendar> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.startDate;
    _selectedDay = DateTime.now();
  }

  @override
  void didUpdateWidget(CustomWeekCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate) {
      _focusedDay = widget.startDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 计算周的开始和结束日期
    final weekStart = widget.startDate;
    final weekEnd = weekStart.add(const Duration(days: 6));

    return TableCalendar(
      firstDay: weekStart,
      lastDay: weekEnd,
      focusedDay: _focusedDay,
      calendarFormat: CalendarFormat.week,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        if (!isSameDay(_selectedDay, selectedDay)) {
          setState(() {
            _selectedDay = selectedDay;
          });

          if (widget.onDaySelected != null) {
            widget.onDaySelected!(selectedDay);
          }
        }
      },
      // 禁用页面切换
      onPageChanged: (focusedDay) {
        // 不做任何处理，保持在当前周
      },
      // 禁用格式切换
      availableCalendarFormats: const {CalendarFormat.week: '周视图'},
      calendarStyle: CalendarStyle(
        markersMaxCount: 1,
        markersAlignment: Alignment.bottomCenter,
        todayDecoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: theme.primaryColor,
          shape: BoxShape.circle,
        ),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          final dateStr = DateFormat(formatToYMD).format(date);
          double value = 0;

          if (widget.selectedType == 0) {
            value = widget.incomeData[dateStr] ?? 0;
          } else {
            value = widget.expenseData[dateStr] ?? 0;
          }

          if (value <= 0) {
            return null;
          }

          // 格式化金额显示
          final formattedValue =
              ScreenHelper.isDesktop()
                  ? value.toStringAsFixed(2)
                  : (value >= 10000
                      ? '${(value / 10000).toStringAsFixed(1)}万'
                      : value.toStringAsFixed(0));

          // 收入红色，支出绿色
          final color = widget.selectedType == 0 ? Colors.red : Colors.green;

          // return Text(
          //   formattedValue,
          //   style: TextStyle(
          //     color: color,
          //     fontSize: 10,
          //     fontWeight: FontWeight.bold,
          //   ),
          // );
          return Positioned(
            bottom: ScreenHelper.isDesktop() ? -2 : 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                formattedValue,
                style: TextStyle(
                  color: color,
                  fontSize: ScreenHelper.isDesktop() ? 12 : 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
        dowBuilder: (context, day) {
          final text = DateFormat.E('zh_CN').format(day);

          return Center(
            child: Text(
              text,
              style: TextStyle(
                color:
                    day.weekday == DateTime.sunday ||
                            day.weekday == DateTime.saturday
                        ? Colors.red
                        : null,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
      locale: 'zh_CN',
      // 在外面有标题，所以这里不需要显示
      headerVisible: false,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        leftChevronVisible: false,
        rightChevronVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
