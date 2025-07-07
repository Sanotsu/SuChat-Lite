import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../shared/constants/constants.dart';
import '../../domain/entities/training_plan.dart';
import '../../domain/entities/training_plan_detail.dart';
import '../../domain/entities/training_record.dart';
import '../../domain/entities/training_record_detail.dart';
import '../viewmodels/training_viewmodel.dart';

class TrainingRecordDetailPage extends StatefulWidget {
  final String recordId;

  const TrainingRecordDetailPage({super.key, required this.recordId});

  @override
  State<TrainingRecordDetailPage> createState() =>
      _TrainingRecordDetailPageState();
}

class _TrainingRecordDetailPageState extends State<TrainingRecordDetailPage> {
  bool _isLoading = false;
  String? _error;

  // 详情数据
  TrainingRecord? _record;
  TrainingPlan? _plan;
  List<TrainingPlanDetail>? _planDetails;
  List<TrainingPlanDetail>? _todayPlanDetails;
  List<TrainingRecordDetail>? _recordDetails;
  int _trainingDay = 0;

  @override
  void initState() {
    super.initState();

    // 使用 addPostFrameCallback 延迟加载数据，避免在构建过程中触发状态更新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecordDetails();
    });
  }

  // 加载记录详情
  Future<void> _loadRecordDetails() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final viewModel = Provider.of<TrainingViewModel>(context, listen: false);
      final details = await viewModel.getTrainingRecordDetails(widget.recordId);

      if (!mounted) return;

      if (details.isNotEmpty) {
        setState(() {
          _record = details['record'];
          _plan = details['plan'];
          _planDetails = details['planDetails'];
          _todayPlanDetails = details['todayPlanDetails'];
          _recordDetails = details['recordDetails'];
          _trainingDay = details['trainingDay'] ?? 0;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = '无法加载训练记录详情';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = '加载训练记录详情失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 显示加载状态
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('训练记录详情'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 显示错误信息
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('训练记录详情'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  _loadRecordDetails();
                },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    // 如果没有数据
    if (_record == null ||
        _plan == null ||
        _planDetails == null ||
        _todayPlanDetails == null ||
        _recordDetails == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('训练记录详情'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: Text('无法加载训练记录详情')),
      );
    }

    // 显示详情内容
    return Scaffold(
      appBar: AppBar(
        title: const Text('训练记录详情'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 记录基本信息
            _buildRecordHeader(context),

            const SizedBox(height: 24),

            // 训练完成情况
            Text('训练完成情况', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            // 按肌肉群组分组显示训练详情
            ..._buildExerciseGroups(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordHeader(BuildContext context) {
    // 获取星期几的名称
    String weekdayName = '';
    if (_trainingDay > 0) {
      final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      weekdayName = weekdays[_trainingDay - 1];
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 训练日期和计划名称
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat(formatToYMD).format(_record!.date),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  _plan!.planName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),

            // 显示训练日信息
            if (_trainingDay > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$weekdayName训练',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // 训练时长和完成率
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    context,
                    '训练时长',
                    '${_record!.duration} 分钟',
                    Icons.timer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    context,
                    '完成率',
                    '${(_record!.completionRate * 100).toStringAsFixed(0)}%',
                    Icons.check_circle,
                    color: _getCompletionColor(_record!.completionRate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 消耗卡路里
            if (_record!.caloriesBurned != null)
              _buildInfoCard(
                context,
                '消耗卡路里',
                '${_record!.caloriesBurned} 千卡',
                Icons.local_fire_department,
              ),

            // 用户反馈
            if (_record!.feedback != null && _record!.feedback!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('训练感受:', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(
                _record!.feedback!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: color ?? Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildExerciseGroups(BuildContext context) {
    // 使用当天的训练计划详情而不是所有计划详情
    final planDetailsToShow = _todayPlanDetails!;

    // 按肌肉群组分组
    final groupedExercises = <String, List<TrainingPlanDetail>>{};
    for (var detail in planDetailsToShow) {
      if (!groupedExercises.containsKey(detail.muscleGroup)) {
        groupedExercises[detail.muscleGroup] = [];
      }
      groupedExercises[detail.muscleGroup]!.add(detail);
    }

    final List<Widget> widgets = [];

    groupedExercises.forEach((muscleGroup, exercises) {
      // 添加肌肉群组标题
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            muscleGroup,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

      // 添加该肌肉群组的训练项目
      for (var exercise in exercises) {
        // 查找对应的记录详情
        final recordDetail = _recordDetails!.firstWhere(
          (detail) => detail.detailId == exercise.detailId,
          orElse:
              () => TrainingRecordDetail(
                recordId: _record!.recordId,
                detailId: exercise.detailId,
                exerciseName: exercise.exerciseName,
                completed: false,
                actualSets: 0,
                actualReps: '0',
              ),
        );

        widgets.add(_buildExerciseItem(context, exercise, recordDetail));
      }
    });

    return widgets;
  }

  Widget _buildExerciseItem(
    BuildContext context,
    TrainingPlanDetail planDetail,
    TrainingRecordDetail recordDetail,
  ) {
    final isCompleted = recordDetail.completed;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color:
              isCompleted
                  ? Colors.green.withValues(alpha: 0.5)
                  : Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 练习名称和完成状态
            Row(
              children: [
                Expanded(
                  child: Text(
                    planDetail.exerciseName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isCompleted
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: isCompleted ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCompleted ? '已完成' : '未完成',
                        style: TextStyle(
                          color: isCompleted ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 计划与实际对比
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '计划',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${planDetail.sets} 组 × ${planDetail.reps}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.secondary.withValues(alpha: 0.5),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '实际',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        // 这里不显示 组数 x 次数是因为实际次数在跟练时无法得知
                        recordDetail.actualSets > 0
                            ? '${recordDetail.actualSets} 组'
                            : '未完成',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color:
                              isCompleted
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 休息时间
            const SizedBox(height: 8),
            Text(
              '休息时间: ${planDetail.restTime} 秒',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            // 备注
            if (recordDetail.notes != null &&
                recordDetail.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '备注:',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                recordDetail.notes!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getCompletionColor(double completionRate) {
    if (completionRate >= 0.8) {
      return Colors.green;
    } else if (completionRate >= 0.5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
