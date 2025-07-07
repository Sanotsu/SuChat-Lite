import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/screen_helper.dart';
import '../../../../shared/constants/constants.dart';
import '../../data/training_dao.dart';
import '../../domain/entities/training_record.dart';

class TrainingStatistics extends StatelessWidget {
  final List<TrainingRecord> records;
  final DateTime startDate;
  final DateTime endDate;
  final Function(TrainingRecord)? onRecordTap;

  const TrainingStatistics({
    super.key,
    required this.records,
    required this.startDate,
    required this.endDate,
    this.onRecordTap,
  });

  @override
  Widget build(BuildContext context) {
    // 如果没有记录，显示空状态
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.secondary.withValues(alpha: .5),
            ),
            const SizedBox(height: 16),
            Text('暂无训练记录', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '完成训练后记录您的进度',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    // 计算统计数据
    final stats = _calculateStatistics();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text('训练统计', style: Theme.of(context).textTheme.headlineSmall),
          Text(
            '${DateFormat(formatToYMD).format(startDate)} 至 ${DateFormat(formatToYMD).format(endDate)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 24),

          // 统计卡片
          _buildStatsGrid(context, stats),
          const SizedBox(height: 24),

          // 训练记录列表
          Text('训练记录', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),

          // 训练记录列表
          ...records.map((record) => _buildRecordCard(context, record)),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, dynamic> stats) {
    var time = stats['totalDuration'] as int;
    var timeStr = '${stats['totalDuration']}分钟';
    if (time > 999) {
      timeStr = '${(time / 60).toStringAsFixed(1)}小时';
    }

    var width = MediaQuery.of(context).size.width;

    double childAspectRatio = 1;
    if (ScreenHelper.isMobile()) {
      childAspectRatio = 1;
    } else if (width <= 720) {
      childAspectRatio = 1;
    } else if (width <= 900 || width > 1080) {
      // 这里注意桌面端1行2个或4个时，可能在过大的4个或者稍微小但不是非常小的2个时，增大宽高比
      childAspectRatio = 1.8;
    }

    return GridView.count(
      crossAxisCount: (ScreenHelper.isMobile() || width <= 900) ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: childAspectRatio,
      children: [
        _buildStatCard(
          context,
          '总训练次数',
          '${stats['totalSessions']}',
          Icons.repeat,
        ),
        _buildStatCard(context, '总训练时长', timeStr, Icons.timer),
        _buildStatCard(
          context,
          '平均完成率',
          '${(stats['avgCompletionRate'] * 100).toStringAsFixed(1)}%',
          Icons.check_circle_outline,
        ),
        _buildStatCard(
          context,
          '消耗卡路里',
          stats['totalCalories'] > 0 ? '${stats['totalCalories']} 千卡' : '未记录',
          Icons.local_fire_department_outlined,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(BuildContext context, TrainingRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onRecordTap != null ? () => onRecordTap!(record) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 日期和完成率
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat(formatToYMDHM).format(record.date),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Chip(
                    label: Text(
                      '${(record.completionRate * 100).toStringAsFixed(0)}% 完成',
                    ),
                    backgroundColor: _getCompletionColor(record.completionRate),
                    labelStyle: TextStyle(
                      color:
                          record.completionRate > 0.5
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),

              // 训练计划名称
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  FutureBuilder(
                    future: TrainingDao().getTrainingPlan(record.planId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return Text(
                        '计划名称: ${snapshot.data?.planName}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      );
                    },
                  ),
                ],
              ),

              // 训练时长
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '训练时长: ${record.duration} 分钟',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),

              // 卡路里（如果有）
              if (record.caloriesBurned != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_fire_department_outlined,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '消耗卡路里: ${record.caloriesBurned} 千卡',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),

              // 反馈（如果有）
              if (record.feedback != null && record.feedback!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '反馈:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.feedback!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateStatistics() {
    int totalSessions = records.length;
    int totalDuration = 0;
    int totalCalories = 0;
    double totalCompletionRate = 0.0;

    for (var record in records) {
      totalDuration += record.duration;
      totalCompletionRate += record.completionRate;
      if (record.caloriesBurned != null) {
        totalCalories += record.caloriesBurned!;
      }
    }

    double avgCompletionRate =
        totalSessions > 0 ? totalCompletionRate / totalSessions : 0.0;

    return {
      'totalSessions': totalSessions,
      'totalDuration': totalDuration,
      'totalCalories': totalCalories,
      'avgCompletionRate': avgCompletionRate,
    };
  }

  Color _getCompletionColor(double completionRate) {
    if (completionRate >= 0.8) {
      return Colors.green;
    } else if (completionRate >= 0.5) {
      return Colors.orange;
    } else {
      return Colors.red.shade300;
    }
  }
}
