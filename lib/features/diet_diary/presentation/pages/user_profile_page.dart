import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../domain/entities/user_profile.dart';
import '../viewmodels/diet_diary_viewmodel.dart';
import '../widgets/goal_setting_dialog.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late DietDiaryViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  Gender _selectedGender = Gender.male;
  Goal _selectedGoal = Goal.maintainWeight;
  double _selectedActivityLevel = 1.4;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<DietDiaryViewModel>(context, listen: false);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProfile = _viewModel.userProfile;
      if (userProfile != null) {
        _nameController.text = userProfile.name;
        _ageController.text = userProfile.age.toString();
        _heightController.text = userProfile.height.toString();
        _weightController.text = userProfile.weight.toString();
        _selectedGender = userProfile.gender;
        _selectedGoal = userProfile.goal;
        _selectedActivityLevel = userProfile.activityLevel;
      }
    } catch (e) {
      commonExceptionDialog(context, '加载用户信息失败', e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('个人信息')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 个人信息卡片
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '基本信息',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 姓名
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: '姓名',
                                hintText: '请输入您的姓名',
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return '请输入姓名';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // 年龄
                            TextFormField(
                              controller: _ageController,
                              decoration: const InputDecoration(
                                labelText: '年龄',
                                hintText: '请输入您的年龄',
                                prefixIcon: Icon(Icons.cake),
                                suffixText: '岁',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '请输入年龄';
                                }
                                final age = int.tryParse(value);
                                if (age == null || age <= 0 || age > 120) {
                                  return '请输入有效的年龄';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // 身高
                            TextFormField(
                              controller: _heightController,
                              decoration: const InputDecoration(
                                labelText: '身高',
                                hintText: '请输入您的身高',
                                prefixIcon: Icon(Icons.height),
                                suffixText: '厘米',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,1}'),
                                ),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '请输入身高';
                                }
                                final height = double.tryParse(value);
                                if (height == null ||
                                    height <= 0 ||
                                    height > 250) {
                                  return '请输入有效的身高';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // 体重
                            TextFormField(
                              controller: _weightController,
                              decoration: const InputDecoration(
                                labelText: '体重',
                                hintText: '请输入您的体重',
                                prefixIcon: Icon(Icons.monitor_weight),
                                suffixText: '公斤',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,1}'),
                                ),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '请输入体重';
                                }
                                final weight = double.tryParse(value);
                                if (weight == null ||
                                    weight <= 0 ||
                                    weight > 300) {
                                  return '请输入有效的体重';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // 性别
                            const Text('性别'),
                            Row(
                              children: [
                                Radio<Gender>(
                                  value: Gender.male,
                                  groupValue: _selectedGender,
                                  onChanged: (Gender? value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedGender = value;
                                      });
                                    }
                                  },
                                ),
                                const Text('男'),
                                const SizedBox(width: 16),
                                Radio<Gender>(
                                  value: Gender.female,
                                  groupValue: _selectedGender,
                                  onChanged: (Gender? value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedGender = value;
                                      });
                                    }
                                  },
                                ),
                                const Text('女'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 目标设置卡片
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '目标设置',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 使用 GoalSettingDialog 作为内嵌组件
                            if (_viewModel.userProfile != null)
                              GoalSettingDialog(
                                userProfile: _viewModel.userProfile!,
                                isDialog: false, // 以页面内嵌形式显示
                                onSave: (goal, activityLevel) {
                                  setState(() {
                                    _selectedGoal = goal;
                                    _selectedActivityLevel = activityLevel;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 保存按钮
                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child:
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text('保存'),
                    ),
                  ],
                ),
              ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userProfile = _viewModel.userProfile;
      if (userProfile != null) {
        final updatedProfile = userProfile.copyWith(
          name: _nameController.text.trim(),
          age: int.tryParse(_ageController.text) ?? 25,
          height: double.tryParse(_heightController.text) ?? 170,
          weight: double.tryParse(_weightController.text) ?? 60,
          gender: _selectedGender,
          goal: _selectedGoal,
          activityLevel: _selectedActivityLevel,
        );

        await _viewModel.updateUserProfile(updatedProfile);

        ToastUtils.showInfo('个人信息更新成功');
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        commonExceptionDialog(context, '保存个人信息失败', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
