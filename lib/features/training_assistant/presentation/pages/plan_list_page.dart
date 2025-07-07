import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/simple_tool_widget.dart';
import '../viewmodels/training_viewmodel.dart';
import '../widgets/plan_list.dart';

/// 训练计划列表页面
/// 展示用户的所有训练计划，并提供选择、删除等操作
class PlanListPage extends StatefulWidget {
  final String userId;
  final Function(String planId) onPlanSelected;
  final bool showAppBar;

  const PlanListPage({
    super.key,
    required this.userId,
    required this.onPlanSelected,
    this.showAppBar = true,
  });

  @override
  State<PlanListPage> createState() => _PlanListPageState();
}

class _PlanListPageState extends State<PlanListPage> {
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserPlans();
    });
  }

  // 加载用户训练计划
  Future<void> _loadUserPlans() async {
    if (widget.userId.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final viewModel = Provider.of<TrainingViewModel>(context, listen: false);
      await viewModel.loadUserTrainingPlans(widget.userId);
    } catch (e) {
      setState(() {
        _error = '加载训练计划失败: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TrainingViewModel>(
      builder: (context, viewModel, child) {
        // 处理页面级别的加载状态
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // 处理页面级别的错误
        if (_error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '错误: $_error',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadUserPlans,
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        // 如果没有训练计划，显示空状态
        if (viewModel.userPlans.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.fitness_center_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  '您还没有任何训练计划',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '点击"新建计划"按钮，创建您的第一个训练计划',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final content = RefreshIndicator(
          onRefresh: _loadUserPlans,
          child: PlanList(
            plans: viewModel.userPlans,
            selectedPlan: viewModel.selectedPlan,
            onPlanSelected: (plan) async {
              await widget.onPlanSelected(plan.planId);
            },
            onPlanDeleted: (plan) async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('删除计划'),
                      content: const Text('确定要删除此训练计划吗？此操作不可撤销。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('删除'),
                        ),
                      ],
                    ),
              );

              if (confirmed == true) {
                setState(() {
                  _isLoading = true;
                });

                try {
                  final success = await viewModel.deleteTrainingPlan(
                    plan.planId,
                  );

                  if (!success && viewModel.error != null && context.mounted) {
                    commonExceptionDialog(context, "删除失败", viewModel.error!);
                  }

                  // 重新加载用户的训练计划列表
                  await viewModel.loadUserTrainingPlans(widget.userId);
                } finally {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              }
            },
          ),
        );

        // 根据是否显示AppBar返回不同的布局
        return widget.showAppBar
            ? Scaffold(
              appBar: AppBar(title: const Text('训练计划列表')),
              body: content,
            )
            : content;
      },
    );
  }
}
