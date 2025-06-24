import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/toast_utils.dart';
import '../viewmodels/training_viewmodel.dart';
import '../widgets/plan_detail.dart';
import '../pages/workout_session_page.dart';

/// 训练计划详情页面
/// 展示训练计划的详细信息和训练安排
class PlanDetailPage extends StatelessWidget {
  final VoidCallback? onSwitchToStatistics;
  final bool showAppBar;

  const PlanDetailPage({
    super.key,
    this.onSwitchToStatistics,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TrainingViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (viewModel.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '加载失败: ${viewModel.error}',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (viewModel.selectedPlan != null) {
                      viewModel.selectTrainingPlan(
                        viewModel.selectedPlan!.planId,
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        if (viewModel.selectedPlan == null) {
          return const Center(child: Text('请先选择一个训练计划'));
        }

        final content = PlanDetail(
          plan: viewModel.selectedPlan!,
          planDetails: viewModel.planDetails,
          onStartTraining: (plan, {day}) async {
            // 获取当前是星期几（1-7表示周一到周日）
            // 如果day为null，则表示点击的是最底部的开始训练，则使用当前日期
            // 如果day不为null，则表示点击的是训练日中的开始训练，则使用传入的day
            final currentWeekday = day ?? DateTime.now().weekday;

            // 检查当天是否有训练内容
            final todayDetails =
                viewModel.planDetails
                    .where((detail) => detail.day == currentWeekday)
                    .toList();

            if (todayDetails.isEmpty) {
              // 如果当天没有训练内容，显示提示
              ToastUtils.showInfo("今天没有安排训练内容", align: Alignment.center);
              return;
            }

            // 导航到训练会话页面
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => WorkoutSessionPage(
                      plan: plan,
                      details: viewModel.planDetails,
                      day: currentWeekday,
                    ),
              ),
            );

            // 处理返回结果
            if (result != null &&
                result is Map &&
                result['switchToStatistics'] == true &&
                onSwitchToStatistics != null) {
              // 返回主页面并切换到训练统计标签
              if (context.mounted) {
                Navigator.pop(context);
                onSwitchToStatistics!();
              }
            }
          },
        );

        // 根据是否显示AppBar返回不同的布局
        return showAppBar
            ? Scaffold(
              appBar: AppBar(title: Text(viewModel.selectedPlan!.planName)),
              body: content,
            )
            : content;
      },
    );
  }
}
