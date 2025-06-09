import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/training_user_info.dart';

class UserInfoForm extends StatefulWidget {
  final TrainingUserInfo? userInfo;
  final Function(
    String gender,
    double height,
    double weight,
    int? age,
    String? fitnessLevel,
    String? healthConditions,
  )
  onSaved;

  const UserInfoForm({super.key, this.userInfo, required this.onSaved});

  @override
  State<UserInfoForm> createState() => _UserInfoFormState();
}

class _UserInfoFormState extends State<UserInfoForm> {
  final _formKey = GlobalKey<FormState>();

  String _gender = '男';
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String _fitnessLevel = '初级';
  final TextEditingController _healthConditionsController =
      TextEditingController();

  final List<String> _genderOptions = ['男', '女'];
  final List<String> _fitnessLevelOptions = ['初级', '中级', '高级'];

  @override
  void initState() {
    super.initState();

    // 如果有用户信息，填充表单
    if (widget.userInfo != null) {
      _gender = widget.userInfo!.gender;
      _heightController.text = widget.userInfo!.height.toString();
      _weightController.text = widget.userInfo!.weight.toString();
      if (widget.userInfo!.age != null) {
        _ageController.text = widget.userInfo!.age.toString();
      }
      if (widget.userInfo!.fitnessLevel != null) {
        _fitnessLevel = widget.userInfo!.fitnessLevel!;
      }
      if (widget.userInfo!.healthConditions != null) {
        _healthConditionsController.text = widget.userInfo!.healthConditions!;
      }
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _healthConditionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Text('个人信息', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                '请填写您的基本信息，以便生成适合您的训练计划',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // 性别
              Text('性别', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments:
                    _genderOptions
                        .map(
                          (gender) => ButtonSegment<String>(
                            value: gender,
                            label: Text(gender),
                          ),
                        )
                        .toList(),
                selected: {_gender},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _gender = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),

              // 身高
              Text('身高 (厘米)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _heightController,
                decoration: const InputDecoration(
                  hintText: '例如: 175',
                  border: OutlineInputBorder(),
                  suffixText: 'cm',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入身高';
                  }
                  final height = double.tryParse(value);
                  if (height == null || height <= 0) {
                    return '请输入有效的身高';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 体重
              Text('体重 (公斤)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  hintText: '例如: 65',
                  border: OutlineInputBorder(),
                  suffixText: 'kg',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入体重';
                  }
                  final weight = double.tryParse(value);
                  if (weight == null || weight <= 0) {
                    return '请输入有效的体重';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 年龄（可选）
              Text('年龄 (可选)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  hintText: '例如: 30',
                  border: OutlineInputBorder(),
                  suffixText: '岁',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final age = int.tryParse(value);
                    if (age == null || age <= 0 || age > 120) {
                      return '请输入有效的年龄';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 健身水平
              Text('健身水平', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments:
                    _fitnessLevelOptions
                        .map(
                          (level) => ButtonSegment<String>(
                            value: level,
                            label: Text(level),
                          ),
                        )
                        .toList(),
                selected: {_fitnessLevel},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _fitnessLevel = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),

              // 健康状况（可选）
              Text(
                '健康状况或限制 (可选)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _healthConditionsController,
                decoration: const InputDecoration(
                  hintText: '例如: 膝盖受伤、高血压等',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // 保存按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('保存信息'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      final height = double.parse(_heightController.text);
      final weight = double.parse(_weightController.text);
      final age =
          _ageController.text.isNotEmpty
              ? int.parse(_ageController.text)
              : null;
      final healthConditions =
          _healthConditionsController.text.isNotEmpty
              ? _healthConditionsController.text
              : null;

      widget.onSaved(
        _gender,
        height,
        weight,
        age,
        _fitnessLevel,
        healthConditions,
      );
    }
  }
}
