import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/entities/cus_llm_model.dart';
import '../../../../core/entities/user_info.dart';
import '../../../../core/utils/screen_helper.dart';
import '../../../../core/viewmodels/user_info_viewmodel.dart';
import '../../../../shared/constants/constant_llm_enum.dart';
import '../../../../shared/services/model_manager_service.dart';
import '../../../../shared/widgets/cus_dropdown_button.dart';
import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../../../shared/widgets/show_tool_prompt_dialog.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../data/services/training_assistant_service.dart';
import '../viewmodels/training_viewmodel.dart';

class PlanGeneratorForm extends StatefulWidget {
  // 成功后回调
  final Function() onSuccess;

  /// 用户信息，用于生成更准确的训练计划提示词
  final UserInfo? userInfo;

  const PlanGeneratorForm({super.key, required this.onSuccess, this.userInfo});

  @override
  State<PlanGeneratorForm> createState() => _PlanGeneratorFormState();
}

class _PlanGeneratorFormState extends State<PlanGeneratorForm> {
  final _formKey = GlobalKey<FormState>();

  // 自定义生成训练计划的提示词
  String _customPrompt = '';

  // 当前步骤
  int _currentStep = 0;
  final int _totalSteps = 5;

  // 目标选择
  String _selectedGoal = '增肌';
  final List<String> _goalOptions = [
    '增肌',
    '减脂',
    '塑形',
    '力量提升',
    '耐力提升',
    '功能性训练',
    '康复/柔韧',
  ];

  // 肌肉群组
  final Map<String, bool> _muscleGroups = {
    '全身': true,
    '核心': false,
    '肩部': false,
    '手臂': false,
    '胸部': false,
    '背部': false,
    '腹部': false,
    '臀部': false,
    '腿部': false,
  };

  // 训练时长（每次训练的分钟数）
  int _duration = 60;
  final List<int> _durationOptions = [20, 30, 45, 60, 90, 120];

  // 训练频率（每周哪几天）
  final Map<String, bool> _trainingDays = {
    '周一': true,
    '周二': false,
    '周三': true,
    '周四': false,
    '周五': false,
    '周六': true,
    '周日': false,
  };

  // 训练设备
  String? _equipment = '无要求';
  final List<String> _equipmentOptions = [
    '无要求',
    '家庭健身',
    '健身房',
    '户外',
    '哑铃',
    '无器械',
  ];

  // 添加模型相关状态
  List<CusLLMSpec> modelList = [];
  CusLLMSpec? selectedModel;

  @override
  void initState() {
    super.initState();
    initModels();
  }

  Future<void> initModels() async {
    // 获取可用模型列表
    final availableModels = await ModelManagerService.getAvailableModelByTypes([
      LLModelType.cc,
      LLModelType.reasoner,
    ]);

    setState(() {
      modelList = availableModels;
      selectedModel = availableModels.isNotEmpty ? availableModels.first : null;
    });
  }

  // 生成并显示提示词对话框
  void _showPromptDialog() async {
    if (selectedModel == null) {
      ToastUtils.showError("请先选择生成训练计划的大模型", align: Alignment.center);
      return;
    }

    // 验证至少选择了一个肌肉群组
    if (!_muscleGroups.values.contains(true)) {
      ToastUtils.showError("请至少选择一个肌肉群组", align: Alignment.center);
      return;
    }

    // 验证至少选择了一天进行训练
    if (!_trainingDays.values.contains(true)) {
      ToastUtils.showError("请至少选择一天进行训练", align: Alignment.center);
      return;
    }

    // 获取选中的肌肉群组
    final selectedMuscleGroups =
        _muscleGroups.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();

    // 获取选中的训练天数
    final selectedDays =
        _trainingDays.entries
            .where((entry) => entry.value)
            .map((e) => e.key)
            .toList();

    // 将选中的天数转换为字符串，如 "周一、周三、周五"
    final frequency = selectedDays.join('、');

    // 使用用户的真实信息生成提示词
    final userInfo = widget.userInfo;
    final prompt = TrainingAssistantService().buildTrainingPlanPrompt(
      // 如果有用户信息，则使用真实信息，否则使用默认值
      gender: userInfo?.gender.name == 'male' ? '男' : '女',
      height: userInfo?.height ?? 170.0,
      weight: userInfo?.weight ?? 65.0,
      fitnessLevel: userInfo?.fitnessLevel ?? '中级',
      targetGoal: _selectedGoal,
      targetMuscleGroups: selectedMuscleGroups,
      duration: _duration,
      frequency: frequency,
      equipment: _equipment,
      // 如果有健康状况信息，也一并传入
      healthConditions: userInfo?.healthConditions,
      age: userInfo?.age,
    );

    // 使用通用的提示词对话框组件
    final result = await showToolPromptDialog(
      context: context,
      initialPrompt: prompt,
      previewTitle: '预览提示词',
      editTitle: '编辑提示词',
      confirmButtonText: '用此提示词生成',
      previewHint: '以下是根据您的选择生成的训练计划提示词，点击右上角编辑按钮可以修改。',
      editHint: '您可以根据需要修改提示词，修改后将使用您的自定义提示词生成训练计划。',
    );

    // 如果用户确认使用自定义提示词
    if (result != null) {
      if (result.useCustomPrompt) {
        setState(() {
          _customPrompt = result.customPrompt;
        });
      }

      _generatePlan();
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Card(
        margin: const EdgeInsets.all(8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题和说明
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon(
                          //   Icons.fitness_center,
                          //   color: Theme.of(context).colorScheme.primary,
                          //   size: 24,
                          // ),
                          // const SizedBox(width: 12),
                          Text(
                            '创建个性化训练计划',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '请根据下方引导，创建您的专属训练计划',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 步骤指示器
              _buildStepIndicator(),
              const SizedBox(height: 24),

              // 基于当前步骤显示不同的表单部分
              _buildCurrentStepContent(),
              const SizedBox(height: 24),

              // 导航按钮
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(_totalSteps, (index) {
        final isActive = index <= _currentStep;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getStepTitle(index),
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return '训练目标';
      case 1:
        return '目标肌群';
      case 2:
        return '训练时长';
      case 3:
        return '训练频率';
      case 4:
        return '训练设备';
      default:
        return '';
    }
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildTrainingGoalStep();
      case 1:
        return _buildMuscleGroupsStep();
      case 2:
        return _buildDurationStep();
      case 3:
        return _buildFrequencyStep();
      case 4:
        return _buildEquipmentAndModelStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildTrainingGoalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('选择您的训练目标', Icons.track_changes),
        const SizedBox(height: 16),
        Text(
          '您希望通过训练达到什么目标？请选择一项最符合您需求的目标。',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        _buildGridSelector(
          items: _goalOptions,
          isSelected: (item) => _selectedGoal == item,
          onTap: (goal) {
            setState(() {
              _selectedGoal = goal;
            });
          },
          getIcon: (item) => _getGoalIcon(item),
          color: Theme.of(context).colorScheme.primary,
          crossAxisCount: 2,
          childAspectRatio: 2.5,
        ),
      ],
    );
  }

  IconData _getGoalIcon(String goal) {
    switch (goal) {
      case '增肌':
        return Icons.fitness_center;
      case '减脂':
        return Icons.trending_down;
      case '力量提升':
        return Icons.bolt;
      case '耐力提升':
        return Icons.timer;
      case '塑形':
        return Icons.accessibility_new;
      default:
        return Icons.fitness_center;
    }
  }

  Widget _buildMuscleGroupsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('选择目标肌群', Icons.accessibility_new),
        const SizedBox(height: 16),
        Text(
          '您希望重点训练哪些肌肉群组？可以选择多个。',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        _buildGridSelector(
          items: _muscleGroups.keys.toList(),
          isSelected: (item) => _muscleGroups[item]!,
          onTap: (muscle) {
            setState(() {
              // 特殊逻辑：选择"全身"时取消其他选项，选择其他选项时取消"全身"
              if (muscle == '全身') {
                // 如果选择了"全身"，则将其他所有选项设为false
                if (!_muscleGroups[muscle]!) {
                  _muscleGroups.forEach((key, value) {
                    _muscleGroups[key] = key == '全身';
                  });
                }
              } else {
                // 如果选择了其他选项，则取消"全身"选项
                _muscleGroups[muscle] = !_muscleGroups[muscle]!;
                if (_muscleGroups[muscle]!) {
                  _muscleGroups['全身'] = false;
                }

                // 检查是否没有选中任何选项，如果是，则自动选择"全身"
                if (!_muscleGroups.values.contains(true)) {
                  _muscleGroups['全身'] = true;
                }
              }
            });
          },
          getIcon: (item) => _getMuscleIcon(item),
          color: Theme.of(context).colorScheme.secondary,
          isMultiSelect: true,
          crossAxisCount: 2,
          childAspectRatio: 2.5,
        ),
      ],
    );
  }

  IconData _getMuscleIcon(String muscle) {
    switch (muscle) {
      case '胸部':
        return Icons.accessibility_new;
      case '背部':
        return Icons.accessibility_new;
      case '肩部':
        return Icons.accessibility_new;
      case '手臂':
        return Icons.accessibility_new;
      case '腿部':
        return Icons.accessibility_new;
      case '核心':
        return Icons.accessibility_new;
      case '全身':
        return Icons.accessibility_new;
      default:
        return Icons.accessibility_new;
    }
  }

  Widget _buildDurationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('选择训练时长', Icons.timer),
        const SizedBox(height: 16),
        Text('您每次训练想要花费多长时间？', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 20),
        _buildGridSelector(
          items: _durationOptions.map((e) => e.toString()).toList(),
          isSelected: (item) => _duration == int.parse(item),
          onTap: (durationStr) {
            setState(() {
              _duration = int.parse(durationStr);
            });
          },
          getIcon: (item) => Icons.timer,
          color: Theme.of(context).colorScheme.tertiary,
          itemTextBuilder: (item) => '$item 分钟',
          crossAxisCount: 2,
          childAspectRatio: 2.5,
        ),
      ],
    );
  }

  Widget _buildFrequencyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('选择训练频率', Icons.calendar_today),
        const SizedBox(height: 16),
        Text(
          '您每周想要训练哪几天？可以选择多天。',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        _buildGridSelector(
          items: _trainingDays.keys.toList(),
          isSelected: (item) => _trainingDays[item]!,
          onTap: (day) {
            setState(() {
              _trainingDays[day] = !_trainingDays[day]!;
            });
          },
          getIcon: (item) => Icons.calendar_today,
          color: Theme.of(context).colorScheme.secondary,
          isMultiSelect: true,
          crossAxisCount: 2,
          childAspectRatio: 2.5,
        ),
      ],
    );
  }

  Widget _buildEquipmentAndModelStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 训练设备
        _buildSectionTitle('选择训练设备', Icons.fitness_center),
        const SizedBox(height: 16),
        Text('您可以使用哪些训练设备？', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 20),
        _buildGridSelector(
          items: _equipmentOptions,
          isSelected: (item) => _equipment == item,
          onTap: (equipment) {
            setState(() {
              _equipment = _equipment == equipment ? null : equipment;
            });
          },
          getIcon: (item) => _getEquipmentIcon(item),
          color: Theme.of(context).colorScheme.tertiary,
          crossAxisCount: 2,
          childAspectRatio: 2.5,
        ),

        const SizedBox(height: 32),

        // AI 模型选择
        _buildSectionTitle('选择 AI 模型', Icons.smart_toy),
        const SizedBox(height: 16),
        Text('选择用于生成训练计划的大语言模型', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        SizedBox(
          child: buildDropdownButton2<CusLLMSpec?>(
            value: selectedModel,
            items: modelList,
            height: 56,
            hintLabel: "选择模型",
            alignment: Alignment.centerLeft,
            onChanged: (value) => setState(() => selectedModel = value!),
            itemToString:
                (e) => "${CP_NAME_MAP[(e as CusLLMSpec).platform]} - ${e.name}",
          ),
        ),

        const SizedBox(height: 32),

        // 提示词编辑按钮
        ElevatedButton.icon(
          icon: const Icon(Icons.edit_note),
          label: const Text('查看/编辑提示词'),
          onPressed: _showPromptDialog,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  IconData _getEquipmentIcon(String equipment) {
    switch (equipment) {
      case '家庭健身':
        return Icons.home;
      case '健身房':
        return Icons.fitness_center;
      case '户外':
        return Icons.park;
      case '无器械':
        return Icons.accessibility_new;
      case '无要求':
        return Icons.check_circle_outline;
      default:
        return Icons.fitness_center;
    }
  }

  Widget _buildSelectionButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    bool isMultiSelect = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color:
              isSelected
                  ? color.withValues(alpha: 0.2)
                  : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              isSelected && isMultiSelect ? Icons.check_circle : icon,
              color:
                  isSelected
                      ? color
                      : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color:
                      isSelected
                          ? color
                          : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          OutlinedButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: const Text('上一步'),
            onPressed: _previousStep,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          )
        else
          const SizedBox(width: 100),

        if (_currentStep < _totalSteps - 1)
          ElevatedButton.icon(
            icon: const Icon(Icons.arrow_forward),
            label: const Text('下一步'),
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          )
        else
          ElevatedButton.icon(
            icon: const Icon(Icons.fitness_center),
            label: Text(_customPrompt.isNotEmpty ? '使用自定义提示词生成' : '生成训练计划'),
            onPressed: _generatePlan,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  /// 通用网格选择器构建方法
  Widget _buildGridSelector<T>({
    required List<T> items,
    required bool Function(T) isSelected,
    required void Function(T) onTap,
    required IconData Function(T) getIcon,
    required Color color,
    bool isMultiSelect = false,
    String Function(T)? itemTextBuilder,
    int crossAxisCount = 2,
    double childAspectRatio = 2.5,
    double crossAxisSpacing = 10,
    double mainAxisSpacing = 10,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        // crossAxisCount: crossAxisCount,
        crossAxisCount:
            ScreenHelper.isMobile()
                ? 2
                : (screenWidth < 840 ? 2 : (screenWidth > 1024 ? 5 : 4)),
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final selected = isSelected(item);
        final displayText =
            itemTextBuilder != null ? itemTextBuilder(item) : item.toString();

        return _buildSelectionButton(
          text: displayText,
          isSelected: selected,
          onTap: () => onTap(item),
          icon: getIcon(item),
          color: color,
          isMultiSelect: isMultiSelect,
        );
      },
    );
  }

  void _generatePlan() async {
    // 验证至少选择了一个肌肉群组
    if (!_muscleGroups.values.contains(true)) {
      ToastUtils.showError("请至少选择一个肌肉群组", align: Alignment.center);
      return;
    }

    // 验证至少选择了一天进行训练
    if (!_trainingDays.values.contains(true)) {
      ToastUtils.showError("请至少选择一天进行训练", align: Alignment.center);
      return;
    }

    // 验证至少选择了一个模型
    if (selectedModel == null) {
      ToastUtils.showError("请选择生成训练计划的大模型", align: Alignment.center);
      return;
    }

    // 获取选中的肌肉群组
    final selectedMuscleGroups = _muscleGroups.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .join('、');

    // 获取选中的训练天数
    final selectedDays =
        _trainingDays.entries
            .where((entry) => entry.value)
            .map((e) => e.key)
            .toList();

    // 将选中的天数转换为字符串，如 "周一、周三、周五"
    final frequency = selectedDays.join('、');

    final trainingViewModel = Provider.of<TrainingViewModel>(
      context,
      listen: false,
    );
    final userInfoViewModel = Provider.of<UserInfoViewModel>(
      context,
      listen: false,
    );

    if (userInfoViewModel.currentUser == null) {
      ToastUtils.showError('用户信息不存在，请先创建用户信息');
      return;
    }

    // 显示训练计划生成遮罩
    LoadingOverlay.showTrainingPlanGeneration(
      context,
      showTimer: true,
      onCancel: () {
        // 用户取消生成，可以在这里添加取消逻辑
        ToastUtils.showInfo("已取消训练计划生成", align: Alignment.center);
      },
    );

    try {
      // 调用生成方法
      if (_customPrompt.trim().isNotEmpty) {
        // 使用自定义提示词生成
        await trainingViewModel.generateTrainingPlanWithCustomPrompt(
          userInfo: userInfoViewModel.currentUser!,
          targetGoal: _selectedGoal,
          targetMuscleGroups: selectedMuscleGroups.split('、'),
          duration: _duration,
          frequency: frequency,
          equipment: _equipment,
          customPrompt: _customPrompt.trim(),
          model: selectedModel!,
        );
      } else {
        // 使用标准提示词生成
        await trainingViewModel.generateTrainingPlan(
          userInfo: userInfoViewModel.currentUser!,
          targetGoal: _selectedGoal,
          // 注意和PlanGeneratorForm的_generatePlan()分隔符一致
          targetMuscleGroups: selectedMuscleGroups.split('、'),
          duration: _duration,
          frequency: frequency,
          equipment: _equipment,
          model: selectedModel!,
        );
      }

      // 2025-06-24 训练计划生成失败，不要跳转到其他页面
      if (trainingViewModel.error != null &&
          mounted &&
          trainingViewModel.error!.contains('生成训练计划失败')) {
        commonExceptionDialog(context, "生成训练计划失败", trainingViewModel.error!);
        trainingViewModel.clearError();
        return;
      }

      if (trainingViewModel.selectedPlan != null &&
          userInfoViewModel.currentUser != null) {
        // 保存生成的训练计划到数据库
        await trainingViewModel.saveTrainingPlan(
          userInfoViewModel.currentUser!.userId,
        );

        // 重新加载用户的训练计划列表
        await trainingViewModel.loadUserTrainingPlans(
          userInfoViewModel.currentUser!.userId,
        );

        // 如果组件还在挂载，则调用回调
        if (!mounted) return;
        widget.onSuccess();
      }
    } catch (e) {
      // 处理生成过程中的异常
      if (mounted) {
        commonExceptionDialog(context, "生成失败", "训练计划生成过程中发生错误: $e");
      }
    } finally {
      // 无论成功还是失败，都要隐藏遮罩
      if (mounted) {
        LoadingOverlay.hide();
      }
    }
  }
}
