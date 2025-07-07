import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../../../shared/constants/constants.dart';
import '../../domain/entities/training_plan.dart';
import '../../domain/entities/training_plan_detail.dart';
import '../../domain/entities/training_record.dart';

class TrainingCalendar extends StatefulWidget {
  final TrainingPlan plan;
  final List<TrainingPlanDetail> planDetails;
  final List<TrainingRecord> records;
  final Function(DateTime) onDaySelected;
  final Function(TrainingRecord)? onRecordTap;

  const TrainingCalendar({
    super.key,
    required this.plan,
    required this.planDetails,
    required this.records,
    required this.onDaySelected,
    this.onRecordTap,
  });

  @override
  State<TrainingCalendar> createState() => _TrainingCalendarState();
}

class _TrainingCalendarState extends State<TrainingCalendar> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late CalendarFormat _calendarFormat;

  // 存储每天的训练计划和记录
  late final Map<DateTime, List<Object>> _events;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _calendarFormat = CalendarFormat.month;
    _events = {};

    // 初始化事件
    _initEvents();
  }

  @override
  void didUpdateWidget(TrainingCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.planDetails != widget.planDetails ||
        oldWidget.records != widget.records) {
      _initEvents();
    }
  }

  // 初始化事件数据
  void _initEvents() {
    _events.clear();

    // 添加训练计划事件
    for (var detail in widget.planDetails) {
      // 计算该训练日在一周中的哪一天
      int dayOfWeek = detail.day; // 假设day字段是1-7表示周一到周日

      // 获取当前周的对应日期
      DateTime now = DateTime.now();
      DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      DateTime planDate = startOfWeek.add(Duration(days: dayOfWeek - 1));

      // 考虑训练计划的持续时间（周）
      for (int week = 0; week < widget.plan.duration; week++) {
        DateTime eventDate = planDate.add(Duration(days: 7 * week));

        // 将日期标准化为不含时间部分
        DateTime normalizedDate = DateTime(
          eventDate.year,
          eventDate.month,
          eventDate.day,
        );

        if (!_events.containsKey(normalizedDate)) {
          _events[normalizedDate] = [];
        }

        // 添加计划事件
        _events[normalizedDate]!.add({'type': 'plan', 'detail': detail});
      }
    }

    // 添加训练记录事件
    for (var record in widget.records) {
      // 将日期标准化为不含时间部分
      DateTime recordDate = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );

      if (!_events.containsKey(recordDate)) {
        _events[recordDate] = [];
      }

      // 添加记录事件
      _events[recordDate]!.add({'type': 'record', 'record': record});
    }
  }

  // 获取特定日期的事件
  List<Object> _getEventsForDay(DateTime day) {
    // 标准化日期，只保留年月日
    DateTime normalizedDate = DateTime(day.year, day.month, day.day);
    return _events[normalizedDate] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          locale: 'zh_CN',
          firstDay: kFirstDay,
          lastDay: kLastDay,
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          eventLoader: _getEventsForDay,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            widget.onDaySelected(selectedDay);
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          availableCalendarFormats: {
            CalendarFormat.month: "展示整月",
            CalendarFormat.twoWeeks: "展示两周",
            CalendarFormat.week: "展示一周",
          },
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (events.isEmpty) return const SizedBox();

              // 计算计划和记录的数量
              int planCount = 0;
              int recordCount = 0;

              for (final event in events) {
                if (event is Map) {
                  final type = event['type'];
                  if (type == 'plan') {
                    planCount++;
                  } else if (type == 'record') {
                    recordCount++;
                  }
                }
              }

              return Positioned(
                bottom: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (planCount > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$planCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                      ],
                      if (recordCount > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$recordCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Expanded(child: _buildEventList()),
      ],
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay);

    if (events.isEmpty) {
      return const Center(child: Text('这一天没有训练计划或记录'));
    }

    // 分类事件
    final planEvents =
        events.where((e) {
          return e is Map && e['type'] == 'plan';
        }).toList();

    final recordEvents =
        events.where((e) {
          return e is Map && e['type'] == 'record';
        }).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (planEvents.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                '训练计划',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...planEvents.map((e) {
              final event = e as Map;
              final detail = event['detail'] as TrainingPlanDetail;
              return _buildPlanEventCard(detail);
            }),
          ],

          if (recordEvents.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Text(
                '训练记录',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...recordEvents.map((e) {
              final event = e as Map;
              final record = event['record'] as TrainingRecord;
              return _buildRecordEventCard(record);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanEventCard(TrainingPlanDetail detail) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.fitness_center, color: Colors.blue),
        title: Text(detail.exerciseName),
        subtitle: Text(
          '${detail.sets} 组 × ${detail.reps} | ${detail.muscleGroup}',
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // 可以添加点击事件，显示详情
        },
      ),
    );
  }

  Widget _buildRecordEventCard(TrainingRecord record) {
    final dateFormat = DateFormat('HH:mm');
    final timeString = dateFormat.format(record.date);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: Text('训练记录 ($timeString)'),
        subtitle: Text(
          '完成率: ${(record.completionRate * 100).toStringAsFixed(0)}% | 时长: ${record.duration}分钟',
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          if (widget.onRecordTap != null) {
            widget.onRecordTap!(record);
          }
        },
      ),
    );
  }
}
