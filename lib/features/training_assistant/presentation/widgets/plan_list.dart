import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/constants/constants.dart';
import '../../domain/entities/training_plan.dart';

class PlanList extends StatelessWidget {
  final List<TrainingPlan> plans;
  final TrainingPlan? selectedPlan;
  final Function(TrainingPlan) onPlanSelected;
  final Function(TrainingPlan) onPlanDeleted;

  const PlanList({
    super.key,
    required this.plans,
    this.selectedPlan,
    required this.onPlanSelected,
    required this.onPlanDeleted,
  });

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return const Center(child: Text('暂无训练计划，请先生成一个计划'));
    }

    return ListView.builder(
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        final isSelected =
            selectedPlan != null && selectedPlan!.planId == plan.planId;

        return Card(
          margin: const EdgeInsets.all(8),
          elevation: isSelected ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side:
                isSelected
                    ? BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                    : BorderSide.none,
          ),
          child: InkWell(
            onTap: () => onPlanSelected(plan),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          plan.planName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => onPlanDeleted(plan),
                        tooltip: '删除计划',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '目标: ${plan.targetGoal}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '肌肉群组: ${plan.targetMuscleGroups}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '每次 ${plan.duration} 分钟，频率：${plan.frequency}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '创建于${DateFormat(formatToYMD).format(plan.gmtCreate)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
