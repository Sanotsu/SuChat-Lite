import 'package:flutter/material.dart';
import 'package:flutter_date_pickers/flutter_date_pickers.dart' as date_pickers;
import 'package:intl/intl.dart';

import '../../../../shared/constants/constants.dart';
import '../../../../shared/widgets/toast_utils.dart';

/// 日期范围
class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  DateRange(this.startDate, this.endDate);
}

/// 自定义周选择器
class CustomWeekPicker extends StatefulWidget {
  /// 当前选中的日期
  final DateTime selectedDate;

  /// 日期改变回调
  final Function(date_pickers.DatePeriod) onChanged;

  /// 第一个可选择的日期
  final DateTime firstDate;

  /// 最后一个可选择的日期
  final DateTime lastDate;

  /// 日期格式化
  final DateFormat dateFormat;

  /// 构造函数
  const CustomWeekPicker({
    super.key,
    required this.selectedDate,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    required this.dateFormat,
  });

  @override
  State<CustomWeekPicker> createState() => _CustomWeekPickerState();
}

class _CustomWeekPickerState extends State<CustomWeekPicker> {
  late date_pickers.DatePeriod _selectedPeriod;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    // 计算所选日期所在周的开始（周日）和结束（周六）
    // 计算本周的周日（周的开始）
    final weekStart = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday % 7),
    );
    final weekEnd = weekStart.add(const Duration(days: 6));
    _selectedPeriod = date_pickers.DatePeriod(weekStart, weekEnd);
  }

  @override
  Widget build(BuildContext context) {
    // 自定义样式
    final colorScheme = Theme.of(context).colorScheme;

    // 创建自定义样式
    final styles = date_pickers.DatePickerRangeStyles(
      selectedPeriodStartDecoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10.0),
          bottomLeft: Radius.circular(10.0),
        ),
      ),
      selectedPeriodLastDecoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(10.0),
          bottomRight: Radius.circular(10.0),
        ),
      ),
      selectedPeriodMiddleDecoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.7),
      ),
      selectedDateStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      displayedPeriodTitle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      // 添加更多样式以提高可视性
      defaultDateTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.normal,
      ),
      currentDateStyle: TextStyle(
        color: colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '选择周',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            // 显示当前选中的周期
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${widget.dateFormat.format(_selectedPeriod.start)} - ${widget.dateFormat.format(_selectedPeriod.end)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            date_pickers.WeekPicker(
              selectedDate: _selectedDate,
              onChanged: _handleDateChanged,
              firstDate: widget.firstDate,
              lastDate: widget.lastDate,
              datePickerStyles: styles,
              onSelectionError: (error) {
                // 处理选择错误
                ToastUtils.showInfo('选择错误: $error');
              },
            ),
            // const SizedBox(height: 8),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_selectedPeriod),
                  child: const Text('确定'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleDateChanged(date_pickers.DatePeriod period) {
    setState(() {
      _selectedPeriod = period;
      _selectedDate = period.start; // 更新选中的日期为周的开始日期
    });
    widget.onChanged(period);
  }
}

/// 自定义月选择器
class CustomMonthPicker extends StatefulWidget {
  /// 当前选中的年份
  final int selectedYear;

  /// 当前选中的月份
  final int selectedMonth;

  /// 日期改变回调
  final Function(DateTime) onChanged;

  /// 第一个可选择的日期
  final DateTime firstDate;

  /// 最后一个可选择的日期
  final DateTime lastDate;

  /// 构造函数
  const CustomMonthPicker({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<CustomMonthPicker> createState() => _CustomMonthPickerState();
}

class _CustomMonthPickerState extends State<CustomMonthPicker> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(widget.selectedYear, widget.selectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    // 自定义样式
    final colorScheme = Theme.of(context).colorScheme;

    // 创建自定义样式
    final styles = date_pickers.DatePickerStyles(
      selectedDateStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      selectedSingleDateDecoration: BoxDecoration(
        color: colorScheme.primary,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(10),
      ),
      displayedPeriodTitle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '选择月份',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
            date_pickers.MonthPicker.single(
              selectedDate: _selectedDate,
              onChanged: _handleDateChanged,
              firstDate: widget.firstDate,
              lastDate: widget.lastDate,
              datePickerStyles: styles,
            ),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_selectedDate),
                  child: const Text('确定'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleDateChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    widget.onChanged(date);
  }
}

/// 自定义年选择器
class CustomYearPicker extends StatefulWidget {
  /// 当前选中的年份
  final int selectedYear;

  /// 日期改变回调
  final Function(DateTime) onChanged;

  /// 第一个可选择的年份
  final int firstYear;

  /// 最后一个可选择的年份
  final int lastYear;

  /// 构造函数
  const CustomYearPicker({
    super.key,
    required this.selectedYear,
    required this.onChanged,
    required this.firstYear,
    required this.lastYear,
  });

  @override
  State<CustomYearPicker> createState() => _CustomYearPickerState();
}

class _CustomYearPickerState extends State<CustomYearPicker> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(widget.selectedYear);
  }

  @override
  Widget build(BuildContext context) {
    // 自定义样式
    final colorScheme = Theme.of(context).colorScheme;

    // 创建自定义样式
    final styles = date_pickers.DatePickerStyles(
      selectedDateStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      selectedSingleDateDecoration: BoxDecoration(
        color: colorScheme.primary,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(10),
      ),
      displayedPeriodTitle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '选择年份',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
            date_pickers.YearPicker.single(
              selectedDate: _selectedDate,
              onChanged: _handleDateChanged,
              firstDate: DateTime(widget.firstYear),
              lastDate: DateTime(widget.lastYear),
              datePickerStyles: styles,
            ),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_selectedDate),
                  child: const Text('确定'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleDateChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    widget.onChanged(date);
  }
}

/// 自定义日期范围选择器
class CustomDateRangePicker extends StatefulWidget {
  /// 当前选中的开始日期
  final DateTime startDate;

  /// 当前选中的结束日期
  final DateTime endDate;

  /// 日期改变回调
  final Function(DateRange) onChanged;

  /// 第一个可选择的日期
  final DateTime firstDate;

  /// 最后一个可选择的日期
  final DateTime lastDate;

  /// 日期格式化
  final DateFormat dateFormat;

  /// 构造函数
  const CustomDateRangePicker({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    required this.dateFormat,
  });

  @override
  State<CustomDateRangePicker> createState() => _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<CustomDateRangePicker> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    // 自定义样式
    final colorScheme = Theme.of(context).colorScheme;

    // 创建自定义样式
    final styles = date_pickers.DatePickerRangeStyles(
      selectedPeriodStartDecoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10.0),
          bottomLeft: Radius.circular(10.0),
        ),
      ),
      selectedPeriodLastDecoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(10.0),
          bottomRight: Radius.circular(10.0),
        ),
      ),
      selectedPeriodMiddleDecoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.7),
      ),
      selectedDateStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      displayedPeriodTitle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      defaultDateTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.normal,
      ),
      currentDateStyle: TextStyle(
        color: colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.date_range, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '选择日期范围',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            // 显示当前选中的日期范围
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${widget.dateFormat.format(_startDate)} - ${widget.dateFormat.format(_endDate)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            date_pickers.RangePicker(
              selectedPeriod: date_pickers.DatePeriod(_startDate, _endDate),
              onChanged: _handleDateRangeChanged,
              firstDate: widget.firstDate,
              lastDate: widget.lastDate,
              datePickerStyles: styles,
              onSelectionError: (error) {
                // 处理选择错误
                ToastUtils.showInfo('选择错误: $error');
              },
            ),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed:
                      () => Navigator.of(
                        context,
                      ).pop(DateRange(_startDate, _endDate)),
                  child: const Text('确定'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleDateRangeChanged(date_pickers.DatePeriod period) {
    setState(() {
      _startDate = period.start;
      _endDate = period.end;
    });
    widget.onChanged(DateRange(_startDate, _endDate));
  }
}

/// 显示周选择器对话框
Future<date_pickers.DatePeriod?> showCustomWeekPicker({
  required BuildContext context,
  required DateTime selectedDate,
  required Function(date_pickers.DatePeriod) onChanged,
  DateTime? firstDate,
  DateTime? lastDate,
  DateFormat? dateFormat,
}) async {
  // 默认日期范围
  firstDate ??= DateTime(2016);
  lastDate ??= DateTime(DateTime.now().year + 1);

  // 显示对话框
  final result = await showDialog<date_pickers.DatePeriod>(
    context: context,
    builder:
        (context) => CustomWeekPicker(
          selectedDate: selectedDate,
          onChanged: onChanged,
          firstDate: firstDate!,
          lastDate: lastDate!,
          dateFormat: dateFormat ?? DateFormat(formatToYMDzh),
        ),
  );

  return result;
}

/// 显示月选择器对话框
Future<DateTime?> showCustomMonthPicker({
  required BuildContext context,
  required int selectedYear,
  required int selectedMonth,
  required Function(DateTime) onChanged,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  // 默认日期范围
  firstDate ??= DateTime(2016);
  lastDate ??= DateTime(DateTime.now().year + 1);

  // 显示对话框
  final result = await showDialog<DateTime>(
    context: context,
    builder:
        (context) => CustomMonthPicker(
          selectedYear: selectedYear,
          selectedMonth: selectedMonth,
          onChanged: onChanged,
          firstDate: firstDate!,
          lastDate: lastDate!,
        ),
  );

  return result;
}

/// 显示年选择器对话框
Future<DateTime?> showCustomYearPicker({
  required BuildContext context,
  required int selectedYear,
  required Function(DateTime) onChanged,
  int? firstYear,
  int? lastYear,
}) async {
  // 默认年份范围
  firstYear ??= 2016;
  lastYear ??= DateTime.now().year + 1;

  // 显示对话框
  final result = await showDialog<DateTime>(
    context: context,
    builder:
        (context) => CustomYearPicker(
          selectedYear: selectedYear,
          onChanged: onChanged,
          firstYear: firstYear!,
          lastYear: lastYear!,
        ),
  );

  return result;
}

/// 显示日期范围选择器对话框
Future<DateRange?> showCustomDateRangePicker({
  required BuildContext context,
  required DateTime startDate,
  required DateTime endDate,
  required Function(DateRange) onChanged,
  DateTime? firstDate,
  DateTime? lastDate,
  DateFormat? dateFormat,
}) async {
  // 默认日期范围
  firstDate ??= DateTime(2016);
  lastDate ??= DateTime(DateTime.now().year + 1);

  // 显示对话框
  final result = await showDialog<DateRange>(
    context: context,
    builder:
        (context) => CustomDateRangePicker(
          startDate: startDate,
          endDate: endDate,
          onChanged: onChanged,
          firstDate: firstDate!,
          lastDate: lastDate!,
          dateFormat: dateFormat ?? DateFormat(formatToYMDzh),
        ),
  );

  return result;
}
