import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/entities/user_info.dart';
import '../viewmodels/training_viewmodel.dart';
import '../widgets/plan_generator_form.dart';

/// 训练计划生成页面
/// 提供训练计划生成表单和独立的状态管理
class PlanGeneratorPage extends StatefulWidget {
  final UserInfo? userInfo;
  final Function(String planId) onPlanGenerated;
  final bool showAppBar;

  const PlanGeneratorPage({
    super.key,
    required this.userInfo,
    required this.onPlanGenerated,
    this.showAppBar = true,
  });

  @override
  State<PlanGeneratorPage> createState() => _PlanGeneratorPageState();
}

class _PlanGeneratorPageState extends State<PlanGeneratorPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<TrainingViewModel>(
      builder: (context, viewModel, child) {
        // 这里不处理viewModel的全局加载状态，让PlanGeneratorForm自己管理生成过程中的状态
        final content = SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 用户信息检查
              if (widget.userInfo == null)
                const Card(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            '用户信息不完整，可能会影响训练计划的生成质量。建议先完善个人信息。',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 训练计划生成表单
              PlanGeneratorForm(
                userInfo: widget.userInfo,
                onSuccess: () {
                  if (viewModel.selectedPlan != null) {
                    widget.onPlanGenerated(viewModel.selectedPlan!.planId);
                  }
                },
              ),
            ],
          ),
        );

        // 根据是否显示AppBar返回不同的布局
        return widget.showAppBar
            ? Scaffold(
              appBar: AppBar(title: const Text('创建训练计划')),
              body: content,
            )
            : content;
      },
    );
  }
}
