import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/constants/constants.dart';
import '../../domain/entities/training_plan.dart';
import '../../domain/entities/training_plan_detail.dart';
import '../viewmodels/training_viewmodel.dart';
import '../pages/plan_detail_edit_page.dart';
import '../pages/plan_calendar_page.dart';

class PlanDetail extends StatelessWidget {
  final TrainingPlan plan;
  final List<TrainingPlanDetail> planDetails;
  // 如果是点击最底部的开始训练，则只传回plan
  // 如果是点击训练日中的开始训练，则传回plan和day
  final Function(TrainingPlan, {int? day}) onStartTraining;

  const PlanDetail({
    super.key,
    required this.plan,
    required this.planDetails,
    required this.onStartTraining,
  });

  @override
  Widget build(BuildContext context) {
    // 按照训练日分组
    final Map<int, List<TrainingPlanDetail>> detailsByDay = {};
    for (var detail in planDetails) {
      if (!detailsByDay.containsKey(detail.day)) {
        detailsByDay[detail.day] = [];
      }
      detailsByDay[detail.day]!.add(detail);
    }

    // 获取所有训练日，并排序
    final days = detailsByDay.keys.toList()..sort();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 计划标题和描述
            _buildPlanHeader(context),
            const SizedBox(height: 16),

            // 训练日列表
            ...days.map(
              (day) => _buildDaySection(context, day, detailsByDay[day]!),
            ),

            const SizedBox(height: 24),

            // 开始训练按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => onStartTraining(plan),
                icon: const Icon(Icons.fitness_center),
                label: const Text('开始训练'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // 计划标题和描述
  Widget _buildPlanHeader(BuildContext context) {
    Widget buildHeaderChip(String label) {
      return Chip(
        label: Text(label),
        padding: EdgeInsets.zero, // 减少内边距
        visualDensity: VisualDensity.compact, // 增加紧凑度
        backgroundColor: Colors.grey.shade300,
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    plan.planName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Chip(
                  label: Text(plan.difficulty),
                  backgroundColor: _getDifficultyColor(plan.difficulty),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (plan.description != null && plan.description!.isNotEmpty)
              Text(plan.description!),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: [
                buildHeaderChip('目标: ${plan.targetGoal}'),
                buildHeaderChip('肌群: ${plan.targetMuscleGroups}'),
                buildHeaderChip('时长: ${plan.duration}分钟'),
                buildHeaderChip('频率: ${plan.frequency}'),
                if (plan.equipment != null && plan.equipment!.isNotEmpty)
                  buildHeaderChip('设备: ${plan.equipment}'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => PlanCalendarPage(
                              plan: plan,
                              planDetails: planDetails,
                            ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('查看日历'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 每日训练部分
  Widget _buildDaySection(
    BuildContext context,
    int day,
    List<TrainingPlanDetail> details,
  ) {
    // 按肌肉群组分组
    final Map<String, List<TrainingPlanDetail>> detailsByMuscle = {};
    for (var detail in details) {
      if (!detailsByMuscle.containsKey(detail.muscleGroup)) {
        detailsByMuscle[detail.muscleGroup] = [];
      }
      detailsByMuscle[detail.muscleGroup]!.add(detail);
    }

    // 获取当前是星期几（1-7表示周一到周日）
    final currentWeekday = DateTime.now().weekday;
    final isToday = day == currentWeekday;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '${dayWeekMapping[day]}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (isToday)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '今天',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditDialog(context, day, details),
                      tooltip: '编辑训练日',
                    ),
                    if (details.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        color: Colors.green,
                        onPressed: () => onStartTraining(plan, day: day),
                        tooltip: '开始训练',
                      ),
                  ],
                ),
              ],
            ),
            const Divider(),
            ...detailsByMuscle.entries.map(
              (entry) => _buildMuscleGroup(context, entry.key, entry.value),
            ),

            // 添加"开始今日训练"按钮
            if (details.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => onStartTraining(plan, day: day),
                    icon: const Icon(Icons.fitness_center),
                    label: Text(
                      isToday ? '开始今日训练' : '开始${dayWeekMapping[day]}的训练',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isToday ? Colors.green : null,
                      foregroundColor: isToday ? Colors.white : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 肌肉群组部分
  Widget _buildMuscleGroup(
    BuildContext context,
    String muscleGroup,
    List<TrainingPlanDetail> details,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            muscleGroup,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        ...details.map((detail) => _buildExerciseItem(context, detail)),
        const SizedBox(height: 8),
      ],
    );
  }

  // 训练动作项
  Widget _buildExerciseItem(BuildContext context, TrainingPlanDetail detail) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              detail.exerciseName,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (detail.instructions != null && detail.instructions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  detail.instructions!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),

            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildExerciseInfo(context, '组数', '${detail.sets} 组'),
                _buildExerciseInfo(context, '每组次数', detail.reps),
                _buildExerciseInfo(context, '单组耗时', '${detail.countdown} 秒'),
                _buildExerciseInfo(context, '组间休息', '${detail.restTime} 秒'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 训练动作信息项
  Widget _buildExerciseInfo(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // 显示编辑对话框
  void _showEditDialog(
    BuildContext context,
    int day,
    List<TrainingPlanDetail> details,
  ) {
    // 判断屏幕宽度，决定使用弹窗还是新页面
    final screenWidth = MediaQuery.of(context).size.width;
    final viewModel = Provider.of<TrainingViewModel>(context, listen: false);

    if (screenWidth > 600) {
      // 桌面端或平板：使用弹窗
      showDialog(
        context: context,
        builder:
            (context) => Dialog(
              child: Container(
                width: screenWidth * 0.8,
                height: MediaQuery.of(context).size.height * 0.8,
                padding: const EdgeInsets.all(16),
                child: PlanDetailEditPage(
                  day: day,
                  details: List.from(details),
                  onSave: (updatedDetails) {
                    // 创建新的planDetails列表，替换当前日期的训练详情
                    final newPlanDetails = List<TrainingPlanDetail>.from(
                      planDetails,
                    );

                    // 移除当前日期的所有训练详情
                    newPlanDetails.removeWhere((detail) => detail.day == day);

                    // 添加更新后的训练详情
                    newPlanDetails.addAll(updatedDetails);

                    // 更新训练详情
                    viewModel.updatePlanDetails(plan.planId, newPlanDetails);
                  },
                ),
              ),
            ),
      );
    } else {
      // 移动端：使用新页面
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => PlanDetailEditPage(
                day: day,
                details: List.from(details),
                onSave: (updatedDetails) {
                  // 创建新的planDetails列表，替换当前日期的训练详情
                  final newPlanDetails = List<TrainingPlanDetail>.from(
                    planDetails,
                  );

                  // 移除当前日期的所有训练详情
                  newPlanDetails.removeWhere((detail) => detail.day == day);

                  // 添加更新后的训练详情
                  newPlanDetails.addAll(updatedDetails);

                  // 更新训练详情
                  viewModel.updatePlanDetails(plan.planId, newPlanDetails);
                },
              ),
        ),
      );
    }
  }

  // 根据难度返回颜色
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case '初级':
        return Colors.green.shade100;
      case '中级':
        return Colors.orange.shade100;
      case '高级':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
}
