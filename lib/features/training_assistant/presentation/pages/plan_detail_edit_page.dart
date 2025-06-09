import 'package:flutter/material.dart';
import '../../../../core/utils/screen_helper.dart';
import '../../../../shared/constants/constants.dart';
import '../../domain/entities/training_plan_detail.dart';

class PlanDetailEditPage extends StatefulWidget {
  final int day;
  final List<TrainingPlanDetail> details;
  final Function(List<TrainingPlanDetail>) onSave;

  const PlanDetailEditPage({
    super.key,
    required this.day,
    required this.details,
    required this.onSave,
  });

  @override
  State<PlanDetailEditPage> createState() => _PlanDetailEditPageState();
}

class _PlanDetailEditPageState extends State<PlanDetailEditPage> {
  late List<TrainingPlanDetail> _details;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 创建副本以进行编辑
    _details = List.from(widget.details);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('编辑${dayWeekMapping[widget.day]}训练'),
        actions: [TextButton(onPressed: _saveChanges, child: const Text('保存'))],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 训练动作列表
                    ..._details.asMap().entries.map((entry) {
                      final index = entry.key;
                      final detail = entry.value;
                      return _buildExerciseEditCard(index, detail);
                    }),

                    const SizedBox(height: 16),

                    // 添加新动作按钮
                    ElevatedButton.icon(
                      onPressed: _addNewExercise,
                      icon: const Icon(Icons.add),
                      label: const Text('添加动作'),
                      style:
                          ScreenHelper.isDesktop()
                              ? ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                ),
                              )
                              : null,
                    ),

                    // 底部留白，确保滚动时最后一项可以完全显示
                    // const SizedBox(height: 80),
                  ],
                ),
              ),
    );
  }

  Widget _buildExerciseEditCard(int index, TrainingPlanDetail detail) {
    final exerciseNameController = TextEditingController(
      text: detail.exerciseName,
    );
    final muscleGroupController = TextEditingController(
      text: detail.muscleGroup,
    );
    final setsController = TextEditingController(text: detail.sets.toString());
    final repsController = TextEditingController(text: detail.reps);
    final countdownController = TextEditingController(
      text: detail.countdown.toString(),
    );
    final restTimeController = TextEditingController(
      text: detail.restTime.toString(),
    );
    final instructionsController = TextEditingController(
      text: detail.instructions ?? '',
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '动作 ${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeExercise(index),
                  tooltip: '删除动作',
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 动作名称
            TextFormField(
              controller: exerciseNameController,
              decoration: const InputDecoration(labelText: '动作名称'),
              validator:
                  (value) => value == null || value.isEmpty ? '请输入动作名称' : null,
              onChanged: (value) {
                _details[index] = _details[index].copyWith(exerciseName: value);
              },
            ),

            // 肌肉群组
            TextFormField(
              controller: muscleGroupController,
              decoration: const InputDecoration(labelText: '肌肉群组'),
              validator:
                  (value) => value == null || value.isEmpty ? '请输入肌肉群组' : null,
              onChanged: (value) {
                _details[index] = _details[index].copyWith(muscleGroup: value);
              },
            ),

            // 组数和次数
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: setsController,
                    decoration: const InputDecoration(labelText: '组数'),
                    keyboardType: TextInputType.number,
                    validator:
                        (value) =>
                            value == null || value.isEmpty ? '请输入组数' : null,
                    onChanged: (value) {
                      _details[index] = _details[index].copyWith(
                        sets: int.tryParse(value) ?? 3,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: repsController,
                    decoration: const InputDecoration(
                      labelText: '次数 (如: 8-12)',
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty ? '请输入次数' : null,
                    onChanged: (value) {
                      _details[index] = _details[index].copyWith(reps: value);
                    },
                  ),
                ),
              ],
            ),

            // 单组完成耗时和休息时间
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: countdownController,
                    decoration: const InputDecoration(labelText: '单组完成耗时 (秒)'),
                    keyboardType: TextInputType.number,
                    validator:
                        (value) =>
                            value == null || value.isEmpty ? '请输入单组完成耗时' : null,
                    onChanged: (value) {
                      _details[index] = _details[index].copyWith(
                        countdown: int.tryParse(value) ?? 60,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: restTimeController,
                    decoration: const InputDecoration(labelText: '组间休息时间 (秒)'),
                    keyboardType: TextInputType.number,
                    validator:
                        (value) =>
                            value == null || value.isEmpty ? '请输入组间休息时间' : null,
                    onChanged: (value) {
                      _details[index] = _details[index].copyWith(
                        restTime: int.tryParse(value) ?? 30,
                      );
                    },
                  ),
                ),
              ],
            ),

            // 动作说明
            TextFormField(
              controller: instructionsController,
              decoration: const InputDecoration(labelText: '动作说明 (可选)'),
              maxLines: 2,
              onChanged: (value) {
                _details[index] = _details[index].copyWith(instructions: value);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 添加新动作
  void _addNewExercise() {
    setState(() {
      _details.add(
        TrainingPlanDetail(
          planId: _details.isNotEmpty ? _details.first.planId : '',
          day: widget.day,
          exerciseName: '',
          muscleGroup: '',
          sets: 3,
          reps: '8-12',
          countdown: 60,
          restTime: 30,
        ),
      );
    });
  }

  // 删除动作
  void _removeExercise(int index) {
    setState(() {
      _details.removeAt(index);
    });
  }

  // 保存更改
  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // 调用保存回调
      widget.onSave(_details);

      // 返回上一页
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
