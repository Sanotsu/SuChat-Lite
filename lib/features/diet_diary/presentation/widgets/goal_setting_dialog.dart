import 'package:flutter/material.dart';
import '../../../../core/utils/screen_helper.dart';
import '../../domain/entities/user_profile.dart';

class GoalSettingDialog extends StatefulWidget {
  final UserProfile userProfile;
  final Function(Goal goal, double activityLevel) onSave;
  final bool isDialog; // 是否以对话框形式显示

  const GoalSettingDialog({
    super.key,
    required this.userProfile,
    required this.onSave,
    this.isDialog = true, // 默认为对话框形式
  });

  @override
  State<GoalSettingDialog> createState() => _GoalSettingDialogState();
}

class _GoalSettingDialogState extends State<GoalSettingDialog> {
  late Goal _selectedGoal;
  late double _selectedActivityLevel;
  late double _bmr; // 基础代谢率
  late double _tdee; // 总能量消耗
  late double _calorieTarget; // 目标卡路里摄入量

  // 活动水平选项
  final List<double> _activityLevels = [1.2, 1.375, 1.55, 1.725, 1.9];

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.userProfile.goal;
    _selectedActivityLevel = _findClosestActivityLevel(
      widget.userProfile.activityLevel,
    );
    _calculateNutritionValues();
  }

  // 找到最接近的活动水平值
  double _findClosestActivityLevel(double value) {
    return _activityLevels.reduce(
      (a, b) => (a - value).abs() < (b - value).abs() ? a : b,
    );
  }

  void _calculateNutritionValues() {
    // 计算BMR (基础代谢率) - 使用修订版的Harris-Benedict公式
    if (widget.userProfile.gender == Gender.male) {
      _bmr =
          88.362 +
          (13.397 * widget.userProfile.weight) +
          (4.799 * widget.userProfile.height) -
          (5.677 * widget.userProfile.age);
    } else {
      _bmr =
          447.593 +
          (9.247 * widget.userProfile.weight) +
          (3.098 * widget.userProfile.height) -
          (4.330 * widget.userProfile.age);
    }

    // 计算TDEE (总能量消耗)
    _tdee = _bmr * _selectedActivityLevel;

    // 根据目标计算卡路里目标
    switch (_selectedGoal) {
      case Goal.loseWeight:
        _calorieTarget = _tdee - 500; // 减重: 每天减少500卡路里
        break;
      case Goal.maintainWeight:
        _calorieTarget = _tdee; // 维持体重: 保持当前消耗
        break;
      case Goal.gainMuscle:
        _calorieTarget = _tdee + 500; // 增肌: 每天增加500卡路里
        break;
      case Goal.stayHealthy:
        _calorieTarget = _tdee; // 保持健康: 保持当前消耗
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    final actions = _buildActions();

    // 根据是否为对话框形式选择不同的显示方式
    if (widget.isDialog) {
      if (ScreenHelper.isMobile()) {
        return Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('目标设置'),
              actions: actions,
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(child: SingleChildScrollView(child: content)),
                ],
              ),
            ),
          ),
        );
      } else {
        // 对话框形式
        return AlertDialog(
          title: const Text('设置目标'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ScreenHelper.adaptWidth(400), // 使用屏幕适配调整宽度
              maxHeight: ScreenHelper.adaptHeight(600), // 使用屏幕适配调整高度
            ),
            child: SingleChildScrollView(child: content),
          ),
          actions: actions,
        );
      }
    } else {
      // 页面内嵌形式
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          content,
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
        ],
      );
    }
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 基础代谢率信息
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '基础代谢率 (BMR)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text('${_bmr.toInt()} 千卡/天'),
                const SizedBox(height: 12),
                const Text(
                  '总能量消耗 (TDEE)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text('${_tdee.toInt()} 千卡/天'),
                const SizedBox(height: 12),
                const Text(
                  '目标热量摄入',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_calorieTarget.toInt()} 千卡/天',
                  style: TextStyle(
                    color:
                        _selectedGoal == Goal.loseWeight
                            ? Colors.red
                            : (_selectedGoal == Goal.gainMuscle
                                ? Colors.green
                                : Colors.blue),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 目标选择
        const Text(
          '选择目标',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        SegmentedButton<Goal>(
          style: ButtonStyle(
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0), // 自定义圆角半径
              ),
            ),
          ),
          segments: [
            ButtonSegment<Goal>(
              value: Goal.loseWeight,
              label: Text(getGoalText(Goal.loseWeight)),
              icon: const Icon(Icons.trending_down),
            ),
            ButtonSegment<Goal>(
              value: Goal.maintainWeight,
              label: Text(getGoalText(Goal.maintainWeight)),
              icon: const Icon(Icons.trending_flat),
            ),
            ButtonSegment<Goal>(
              value: Goal.gainMuscle,
              label: Text(getGoalText(Goal.gainMuscle)),
              icon: const Icon(Icons.trending_up),
            ),
            ButtonSegment<Goal>(
              value: Goal.stayHealthy,
              label: Text(getGoalText(Goal.stayHealthy)),
              icon: const Icon(Icons.favorite),
            ),
          ],
          selected: {_selectedGoal},
          onSelectionChanged: (Set<Goal> newSelection) {
            setState(() {
              _selectedGoal = newSelection.first;
              _calculateNutritionValues();
            });
          },
        ),
        const SizedBox(height: 24),

        // 活动水平选择
        const Text(
          '活动水平',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<double>(
          value: _selectedActivityLevel,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          items:
              _activityLevels
                  .map(
                    (level) => DropdownMenuItem(
                      value: level,
                      child: Text(getActivityLevelText(level)),
                    ),
                  )
                  .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedActivityLevel = value;
                _calculateNutritionValues();
              });
            }
          },
        ),
        const SizedBox(height: 8),
        // 活动水平说明
        Text(
          '1.2: 久坐不动 (几乎不运动)\n'
          '1.375: 轻度活动 (每周轻度运动1-3次)\n'
          '1.55: 中度活动 (每周中等强度运动3-5次)\n'
          '1.725: 高度活动 (每周剧烈运动6-7次)\n'
          '1.9: 极高活动 (每天剧烈运动或体力劳动)',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  List<Widget> _buildActions() {
    return [
      TextButton(
        onPressed: () {
          if (widget.isDialog) {
            Navigator.pop(context);
          }
        },
        child: const Text('取消'),
      ),
      ElevatedButton(
        onPressed: () {
          widget.onSave(_selectedGoal, _selectedActivityLevel);
          if (widget.isDialog) {
            Navigator.pop(context);
          }
        },
        child: const Text('保存'),
      ),
    ];
  }
}
