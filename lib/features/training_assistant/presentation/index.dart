import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/screen_helper.dart';
import '../../../shared/widgets/cus_loading_indicator.dart';
import '../../../shared/widgets/simple_tool_widget.dart';
import '../../../shared/widgets/toast_utils.dart';
import 'viewmodels/training_viewmodel.dart';
import 'widgets/user_info_form.dart';
import 'widgets/plan_generator_form.dart';
import 'widgets/plan_list.dart';
import 'widgets/plan_detail.dart';
import 'widgets/training_statistics.dart';
import 'pages/training_record_detail_page.dart';
import 'pages/workout_session_page.dart';

class TrainingAssistantPage extends StatefulWidget {
  const TrainingAssistantPage({super.key});

  @override
  State<TrainingAssistantPage> createState() => _TrainingAssistantPageState();
}

class _TrainingAssistantPageState extends State<TrainingAssistantPage> {
  // 当前步骤
  int _currentStep = 0;
  // 用户信息是否已完成
  bool _isUserInfoCompleted = false;

  // 视图模型
  late TrainingViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<TrainingViewModel>(context, listen: false);
    _loadLastUser();
  }

  // 加载上次用户信息
  Future<void> _loadLastUser() async {
    try {
      final users = await _viewModel.getAllUsers();
      if (users.isNotEmpty) {
        await _viewModel.loadUserInfo(users.first.userId);
        if (_viewModel.currentUser != null) {
          // 加载用户的训练计划
          await _viewModel.loadUserTrainingPlans(
            _viewModel.currentUser!.userId,
          );
          if (!mounted) return;
          setState(() {
            _isUserInfoCompleted = true;

            // 如果有用户信息，初始化显示"训练计划"页面
            _currentStep = 1;
          });
        }
      }
    } catch (e) {
      // 加载失败，不处理
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('训练助手')),
      body: Consumer<TrainingViewModel>(
        builder: (context, viewModel, child) {
          // 显示错误信息
          if (viewModel.error != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              commonExceptionDialog(context, "异常信息", viewModel.error!);

              viewModel.clearError();
            });
          }

          // 显示加载状态
          if (viewModel.isLoading) {
            return const Center(
              child: CusLoadingTimeIndicator(
                text: '正在为你量身打造训练计划，请稍候\n注意：如果使用推理模型耗时会较久',
              ),
            );
          }

          return ScreenHelper.isDesktop()
              ? _buildDesktopLayout(viewModel)
              : _buildMobileLayout(viewModel);
        },
      ),
    );
  }

  // 桌面布局
  Widget _buildDesktopLayout(TrainingViewModel viewModel) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧导航栏
        SizedBox(
          width: 250,
          child: Card(
            margin: const EdgeInsets.all(16),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('个人信息'),
                  selected: _currentStep == 0,
                  onTap: () => setState(() => _currentStep = 0),
                ),
                if (_isUserInfoCompleted) ...[
                  ListTile(
                    leading: const Icon(Icons.fitness_center),
                    title: const Text('训练计划'),
                    selected: _currentStep == 1,
                    onTap: () async {
                      // 确保在切换到训练计划标签时加载训练计划
                      if (viewModel.currentUser != null &&
                          viewModel.userPlans.isEmpty) {
                        await viewModel.loadUserTrainingPlans(
                          viewModel.currentUser!.userId,
                        );
                      }
                      if (!mounted) return;
                      setState(() => _currentStep = 1);
                    },
                  ),
                  if (viewModel.selectedPlan != null) ...[
                    ListTile(
                      leading: const Icon(Icons.assignment),
                      title: const Text('训练详情'),
                      selected: _currentStep == 2,
                      onTap: () => setState(() => _currentStep = 2),
                    ),
                  ],
                  ListTile(
                    leading: const Icon(Icons.bar_chart),
                    title: const Text('训练统计'),
                    selected: _currentStep == 3,
                    onTap: () => setState(() => _currentStep = 3),
                  ),
                ],
              ],
            ),
          ),
        ),

        // 右侧内容区
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            child: _buildCurrentStepContent(viewModel),
          ),
        ),
      ],
    );
  }

  // 移动端布局
  Widget _buildMobileLayout(TrainingViewModel viewModel) {
    return Column(
      children: [
        // 顶部导航栏
        SizedBox(
          height: 60,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            children: [
              _buildNavButton(0, '个人信息', Icons.person),
              if (_isUserInfoCompleted) ...[
                _buildNavButton(
                  1,
                  '训练计划',
                  Icons.fitness_center,
                  onTap: () async {
                    // 确保在切换到训练计划标签时加载训练计划
                    if (viewModel.currentUser != null &&
                        viewModel.userPlans.isEmpty) {
                      await viewModel.loadUserTrainingPlans(
                        viewModel.currentUser!.userId,
                      );
                    }
                    if (!mounted) return;
                    setState(() => _currentStep = 1);
                  },
                ),
                if (viewModel.selectedPlan != null) ...[
                  _buildNavButton(2, '训练详情', Icons.assignment),
                ],
                _buildNavButton(3, '训练统计', Icons.bar_chart),
              ],
            ],
          ),
        ),

        // 内容区
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: _buildCurrentStepContent(viewModel),
          ),
        ),
      ],
    );
  }

  // 导航按钮
  Widget _buildNavButton(
    int step,
    String title,
    IconData icon, {
    Function()? onTap,
  }) {
    final isSelected = _currentStep == step;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton.icon(
        onPressed: onTap ?? () => setState(() => _currentStep = step),
        icon: Icon(icon, size: 18),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            // 设置圆弧大小
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor:
              isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surface,
          foregroundColor:
              isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  // 根据当前步骤构建内容
  Widget _buildCurrentStepContent(TrainingViewModel viewModel) {
    switch (_currentStep) {
      case 0:
        return _buildUserInfoForm(viewModel);
      case 1:
        return _buildTrainingPlanSection(viewModel);
      case 2:
        return _buildPlanDetailSection(viewModel);
      case 3:
        return _buildTrainingStatistics(viewModel);
      default:
        return const Center(child: Text('未知步骤'));
    }
  }

  // 用户信息表单
  Widget _buildUserInfoForm(TrainingViewModel viewModel) {
    return UserInfoForm(
      userInfo: viewModel.currentUser,
      onSaved: (
        gender,
        height,
        weight,
        age,
        fitnessLevel,
        healthConditions,
      ) async {
        await viewModel.saveUserInfo(
          userId: viewModel.currentUser?.userId,
          gender: gender,
          height: height,
          weight: weight,
          age: age,
          fitnessLevel: fitnessLevel,
          healthConditions: healthConditions,
        );

        // 保存用户信息后，加载该用户的训练计划
        if (viewModel.currentUser != null) {
          await viewModel.loadUserTrainingPlans(viewModel.currentUser!.userId);
        }

        if (!mounted) return;
        setState(() {
          _isUserInfoCompleted = true;
          _currentStep = 1; // 保存后跳转到训练计划页面
        });
      },
    );
  }

  // 训练计划部分
  Widget _buildTrainingPlanSection(TrainingViewModel viewModel) {
    return Column(
      children: [
        // 标签页
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  tabs: const [Tab(text: '我的计划'), Tab(text: '新建计划')],
                  labelColor: Theme.of(context).colorScheme.primary,
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // 我的计划列表
                      Builder(
                        builder: (context) {
                          // 使用已加载的计划列表，而不是在构建过程中调用异步方法
                          return PlanList(
                            plans: viewModel.userPlans,
                            selectedPlan: viewModel.selectedPlan,
                            onPlanSelected: (plan) async {
                              await viewModel.selectTrainingPlan(plan.planId);
                              if (!mounted) return;
                              setState(() {
                                _currentStep = 2; // 选择计划后跳转到计划详情页面
                              });
                            },
                            onPlanDeleted: (plan) async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text('删除计划'),
                                      content: const Text(
                                        '确定要删除此训练计划吗？此操作不可撤销。',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, false),
                                          child: const Text('取消'),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
                                          child: const Text('删除'),
                                        ),
                                      ],
                                    ),
                              );

                              if (confirmed == true) {
                                final success = await viewModel
                                    .deleteTrainingPlan(plan.planId);

                                if (!success &&
                                    viewModel.error != null &&
                                    context.mounted) {
                                  commonExceptionDialog(
                                    context,
                                    "异常信息",
                                    viewModel.error!,
                                  );
                                }

                                // 重新加载用户的训练计划列表
                                if (viewModel.currentUser != null) {
                                  await viewModel.loadUserTrainingPlans(
                                    viewModel.currentUser!.userId,
                                  );
                                }
                              }
                            },
                          );
                        },
                      ),

                      // 新建计划表单
                      PlanGeneratorForm(
                        userInfo: viewModel.currentUser,
                        onGenerate: (
                          targetGoal,
                          muscleGroups,
                          duration,
                          frequency,
                          equipment,
                          model, {
                          String? customPrompt,
                        }) async {
                          if (customPrompt != null) {
                            // 使用自定义提示词生成
                            await viewModel
                                .generateTrainingPlanWithCustomPrompt(
                                  targetGoal: targetGoal,
                                  targetMuscleGroups: muscleGroups.split('、'),
                                  duration: duration,
                                  frequency: frequency,
                                  equipment: equipment,
                                  customPrompt: customPrompt,
                                  model: model,
                                );
                          } else {
                            // 使用标准提示词生成
                            await viewModel.generateTrainingPlan(
                              targetGoal: targetGoal,
                              // 注意和PlanGeneratorForm的_generatePlan()分隔符一致
                              targetMuscleGroups: muscleGroups.split('、'),
                              duration: duration,
                              frequency: frequency,
                              equipment: equipment,
                              model: model,
                            );
                          }

                          if (viewModel.selectedPlan != null) {
                            // 保存生成的训练计划到数据库
                            await viewModel.saveTrainingPlan();

                            // 重新加载用户的训练计划列表
                            if (viewModel.currentUser != null) {
                              await viewModel.loadUserTrainingPlans(
                                viewModel.currentUser!.userId,
                              );
                            }
                            if (!mounted) return;
                            setState(() {
                              _currentStep = 2; // 生成计划后跳转到计划详情页面
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 计划详情部分
  Widget _buildPlanDetailSection(TrainingViewModel viewModel) {
    if (viewModel.selectedPlan == null) {
      return const Center(child: Text('请先选择一个训练计划'));
    }

    return PlanDetail(
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
            result['switchToStatistics'] == true) {
          // 切换到训练统计标签
          setState(() {
            _currentStep = 3;
          });
        }
      },
    );
  }

  // 训练统计
  Widget _buildTrainingStatistics(TrainingViewModel viewModel) {
    // 默认显示最近30天的记录
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 30));

    return FutureBuilder(
      future: viewModel.getUserTrainingRecordsInDateRange(startDate, endDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return TrainingStatistics(
          records: snapshot.data ?? [],
          startDate: startDate,
          endDate: endDate,
          onRecordTap: (record) {
            // 直接导航到详情页面，将记录ID传递过去，在详情页面加载数据
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        TrainingRecordDetailPage(recordId: record.recordId),
              ),
            );
          },
        );
      },
    );
  }
}
