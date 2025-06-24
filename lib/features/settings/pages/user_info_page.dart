import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../core/dao/user_info_dao.dart';
import '../../../core/entities/user_info.dart';
import '../../../core/utils/screen_helper.dart';
import '../../../core/viewmodels/user_info_viewmodel.dart';
import '../../../shared/widgets/simple_tool_widget.dart';
import '../../../shared/widgets/toast_utils.dart';
import '../../../shared/widgets/goal_setting_dialog.dart';

/// 用户信息页面
/// 用于显示和编辑用户信息，整合了训练助手和饮食日记的用户信息
/// 2025-06-24
/// 在这里修改用户目标卡路里、蛋白质、碳水化合物、脂肪没有用，
/// 因为在每次修改用户之后，目标值都是在 UserInfoDao 固定重新计算的
/// 暂时不允许手动修改主要营养素值了
class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key});

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  // 表单控制器
  final _formKey = GlobalKey<FormBuilderState>();

  // 视图模型
  late UserInfoViewModel _viewModel;
  bool _isLoading = false;

  // 添加状态变量
  Goal _currentGoal = Goal.maintainWeight;
  double _currentActivityLevel = 1.2;

  // 使用ValueNotifier实时更新营养目标值
  final ValueNotifier<MacrosIntake?> _intakeNotifier = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    // 初始化视图模型
    _viewModel = Provider.of<UserInfoViewModel>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _viewModel.initialize();
      // 初始化状态变量
      setState(() {
        _currentGoal = _viewModel.currentUser?.goal ?? Goal.maintainWeight;
        _currentActivityLevel = _viewModel.currentUser?.activityLevel ?? 1.2;
        _intakeNotifier.value = _viewModel.dailyRecommendedIntake;
      });
    });
  }

  @override
  void dispose() {
    _intakeNotifier.dispose();
    super.dispose();
  }

  // 保存用户信息
  Future<void> _saveUserInfo() async {
    if (_formKey.currentState!.saveAndValidate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = _viewModel.currentUser;
        if (user == null) return;

        final formValues = _formKey.currentState!.value;

        await _viewModel.updateUserInfo(
          name: formValues['name'],
          gender: formValues['gender'],
          age:
              formValues['age'] != null &&
                      formValues['age'].toString().isNotEmpty
                  ? int.parse(formValues['age'].toString())
                  : null,
          height: double.parse(formValues['height'].toString()),
          weight: double.parse(formValues['weight'].toString()),
          fitnessLevel: formValues['fitnessLevel'],
          healthConditions:
              formValues['healthConditions'] != null &&
                      formValues['healthConditions'].toString().isNotEmpty
                  ? formValues['healthConditions'].toString()
                  : null,
          goal: formValues['goal'] ?? _currentGoal,
          activityLevel: formValues['activityLevel'] ?? _currentActivityLevel,
          // targetCalories:
          //     formValues['targetCalories'] != null &&
          //             formValues['targetCalories'].toString().isNotEmpty
          //         ? double.parse(formValues['targetCalories'].toString())
          //         : null,
          // targetCarbs:
          //     formValues['targetCarbs'] != null &&
          //             formValues['targetCarbs'].toString().isNotEmpty
          //         ? double.parse(formValues['targetCarbs'].toString())
          //         : null,
          // targetProtein:
          //     formValues['targetProtein'] != null &&
          //             formValues['targetProtein'].toString().isNotEmpty
          //         ? double.parse(formValues['targetProtein'].toString())
          //         : null,
          // targetFat:
          //     formValues['targetFat'] != null &&
          //             formValues['targetFat'].toString().isNotEmpty
          //         ? double.parse(formValues['targetFat'].toString())
          //         : null,
        );

        ToastUtils.showSuccess('用户信息保存成功', align: Alignment.center);

        // 保存后不关闭当前页面，方便用户看到保存后的数据，自行手动关闭
        // if (mounted) {
        //   Navigator.of(context).pop(true);
        // }
      } catch (e) {
        if (mounted) {
          commonExceptionDialog(context, '保存用户信息失败', e.toString());
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

  // // 更新营养目标字段
  // void _updateNutritionFields() {
  //   if (_intakeNotifier.value == null || _formKey.currentState == null) return;

  //   // 更新表单字段
  //   _formKey.currentState!.patchValue({
  //     'targetCalories':
  //         _intakeNotifier.value?.calories.toStringAsFixed(0) ?? '',
  //     'targetCarbs': _intakeNotifier.value?.carbs.toStringAsFixed(1) ?? '',
  //     'targetProtein': _intakeNotifier.value?.protein.toStringAsFixed(1) ?? '',
  //     'targetFat': _intakeNotifier.value?.fat.toStringAsFixed(1) ?? '',
  //   });

  //   // 在设置值后保存表单，确保值被接受
  //   _formKey.currentState!.save();

  //   // 强制UI刷新以确保字段显示正确的值
  //   setState(() {});
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('用户信息')),
      body: Consumer<UserInfoViewModel>(
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
                    onPressed: () => viewModel.initialize(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          final user = viewModel.currentUser;
          if (user == null) {
            return const Center(child: Text('未找到用户信息'));
          }

          // 初始化表单数据
          return FormBuilder(
            key: _formKey,
            initialValue: {
              'name': user.name,
              'gender': user.gender,
              'age': user.age?.toString() ?? '',
              'height': user.height.toString(),
              'weight': user.weight.toString(),
              'fitnessLevel': user.fitnessLevel ?? '初级',
              'healthConditions': user.healthConditions ?? '',
              'goal': user.goal ?? Goal.maintainWeight,
              'activityLevel': user.activityLevel ?? 1.375,
              // 'targetCalories':
              //     user.targetCalories?.toString() ??
              //     _intakeNotifier.value?.calories.toString() ??
              //     '',
              // 'targetCarbs':
              //     user.targetCarbs?.toString() ??
              //     _intakeNotifier.value?.carbs.toString() ??
              //     '',
              // 'targetProtein':
              //     user.targetProtein?.toString() ??
              //     _intakeNotifier.value?.protein.toString() ??
              //     '',
              // 'targetFat':
              //     user.targetFat?.toString() ??
              //     _intakeNotifier.value?.fat.toString() ??
              //     '',
            },
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: ScreenHelper.isMobile() ? 16 : 64,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== 基本信息区域 =====
                  const SectionTitle(title: '个人信息'),

                  // 姓名
                  FormBuilderTextField(
                    name: 'name',
                    decoration: const InputDecoration(
                      labelText: '姓名',
                      hintText: '请输入您的姓名',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(errorText: '请输入姓名'),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // 性别
                  const Text('性别'),
                  FormBuilderRadioGroup<Gender>(
                    name: 'gender',
                    orientation: OptionsOrientation.horizontal,
                    options: const [
                      FormBuilderFieldOption(
                        value: Gender.male,
                        child: Text('男'),
                      ),
                      FormBuilderFieldOption(
                        value: Gender.female,
                        child: Text('女'),
                      ),
                    ],
                    validator: FormBuilderValidators.required(
                      errorText: '请选择性别',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 年龄
                  FormBuilderTextField(
                    name: 'age',
                    decoration: const InputDecoration(
                      labelText: '年龄',
                      hintText: '请输入您的年龄',
                      prefixIcon: Icon(Icons.cake),
                      suffixText: '岁',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: FormBuilderValidators.compose([
                      (value) {
                        if (value != null && value.isNotEmpty) {
                          final age = int.tryParse(value);
                          if (age == null || age <= 0 || age > 120) {
                            return '请输入有效的年龄';
                          }
                        }
                        return null;
                      },
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // 身高
                  FormBuilderTextField(
                    name: 'height',
                    decoration: const InputDecoration(
                      labelText: '身高',
                      hintText: '请输入您的身高',
                      prefixIcon: Icon(Icons.height),
                      suffixText: '厘米',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                    ],
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(errorText: '请输入身高'),
                      (value) {
                        if (value == null || value.isEmpty) return null;
                        final height = double.tryParse(value);
                        if (height == null || height <= 0 || height > 250) {
                          return '请输入有效的身高';
                        }
                        return null;
                      },
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // 体重
                  FormBuilderTextField(
                    name: 'weight',
                    decoration: const InputDecoration(
                      labelText: '体重',
                      hintText: '请输入您的体重',
                      prefixIcon: Icon(Icons.monitor_weight),
                      suffixText: '公斤',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                    ],
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(errorText: '请输入体重'),
                      (value) {
                        if (value == null || value.isEmpty) return null;
                        final weight = double.tryParse(value);
                        if (weight == null || weight <= 0 || weight > 300) {
                          return '请输入有效的体重';
                        }
                        return null;
                      },
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // ===== 训练设置区域 =====
                  const SectionTitle(title: '训练信息'),

                  // 健身水平
                  const Text('健身水平'),
                  FormBuilderRadioGroup<String>(
                    name: 'fitnessLevel',
                    orientation: OptionsOrientation.horizontal,
                    options: const [
                      FormBuilderFieldOption(value: '初级', child: Text('初级')),
                      FormBuilderFieldOption(value: '中级', child: Text('中级')),
                      FormBuilderFieldOption(value: '高级', child: Text('高级')),
                    ],
                    validator: FormBuilderValidators.required(
                      errorText: '请选择健身水平',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 健康状况
                  FormBuilderTextField(
                    name: 'healthConditions',
                    decoration: const InputDecoration(
                      labelText: '健康状况或限制 (可选)',
                      hintText: '例如: 膝盖受伤、高血压等',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // ===== 饮食设置区域 =====
                  const SectionTitle(title: '饮食目标'),

                  // 使用GoalSettingDialog组件进行目标设置
                  Consumer<UserInfoViewModel>(
                    builder: (context, viewModel, _) {
                      if (viewModel.currentUser == null) {
                        return const SizedBox.shrink();
                      }

                      return GoalSettingDialog(
                        userInfo: viewModel.currentUser!,
                        isDialog: false, // 以页面内嵌形式显示
                        onChanged: (goal, activityLevel) async {
                          // 更新状态变量
                          setState(() {
                            _currentGoal = goal;
                            _currentActivityLevel = activityLevel;
                          });

                          // 更新隐藏字段
                          _formKey.currentState?.patchValue({
                            'goal': goal,
                            'activityLevel': activityLevel,
                          });
                          _formKey.currentState?.save();

                          // // 更新视图模型
                          // await viewModel.updateUserInfo(
                          //   goal: goal,
                          //   activityLevel: activityLevel,
                          // );

                          // // 获取并更新推荐摄入量
                          // final newIntake = viewModel.dailyRecommendedIntake;

                          // // 更新ValueNotifier，这将触发UI更新
                          // _intakeNotifier.value = newIntake;

                          // // 使用WidgetsBinding确保在下一帧更新表单字段
                          // WidgetsBinding.instance.addPostFrameCallback((_) {
                          //   _updateNutritionFields();
                          // });
                        },
                      );
                    },
                  ),

                  // 保存选择的目标和活动水平的隐藏字段
                  FormBuilderField<Goal>(
                    name: 'goal',
                    initialValue: user.goal ?? Goal.maintainWeight,
                    validator: (value) => null, // 不需要验证
                    onChanged: (_) {}, // 添加空的 onChanged 处理器
                    builder: (FormFieldState field) {
                      return const SizedBox.shrink();
                    },
                  ),
                  FormBuilderField<double>(
                    name: 'activityLevel',
                    initialValue: user.activityLevel ?? 1.375,
                    validator: (value) => null, // 不需要验证
                    onChanged: (_) {}, // 添加空的 onChanged 处理器
                    builder: (FormFieldState field) {
                      return const SizedBox.shrink();
                    },
                  ),

                  // const SizedBox(height: 24),

                  // // 营养目标
                  // const SectionTitle(title: '自定义营养目标'),

                  // // 添加重置按钮
                  // Row(
                  //   children: [
                  //     const Expanded(
                  //       child: Text(
                  //         '您可以自定义每日营养目标，或使用基于您的目标和活动水平计算的推荐值',
                  //         style: TextStyle(fontSize: 12, color: Colors.grey),
                  //       ),
                  //     ),
                  //     TextButton.icon(
                  //       icon: const Icon(Icons.refresh),
                  //       label: const Text('重置为推荐值'),
                  //       onPressed: () {
                  //         if (_intakeNotifier.value != null) {
                  //           _updateNutritionFields();
                  //         }
                  //       },
                  //     ),
                  //   ],
                  // ),
                  // const SizedBox(height: 16),

                  // // 监听ValueNotifier并实时更新营养目标字段
                  // ValueListenableBuilder<Map<String, double>?>(
                  //   valueListenable: _intakeNotifier,
                  //   builder: (context, intake, child) {
                  //     return Column(
                  //       children: [
                  //         // 目标热量
                  //         FormBuilderTextField(
                  //           key: ValueKey('calories-${intake?['calories']}'),
                  //           name: 'targetCalories',
                  //           initialValue:
                  //               intake?['calories']?.toString() ??
                  //               user.targetCalories?.toString() ??
                  //               '',
                  //           decoration: const InputDecoration(
                  //             labelText: '目标热量',
                  //             hintText: '每日目标卡路里',
                  //             suffixText: 'kcal',
                  //           ),
                  //           keyboardType: TextInputType.number,
                  //           inputFormatters: [
                  //             FilteringTextInputFormatter.allow(
                  //               RegExp(r'^\d*\.?\d*$'),
                  //             ),
                  //           ],
                  //         ),
                  //         const SizedBox(height: 16),

                  //         Row(
                  //           children: [
                  //             Expanded(
                  //               child: FormBuilderTextField(
                  //                 key: ValueKey('carbs-${intake?['carbs']}'),
                  //                 name: 'targetCarbs',
                  //                 initialValue:
                  //                     intake?['carbs']?.toString() ??
                  //                     user.targetCarbs?.toString() ??
                  //                     '',
                  //                 decoration: const InputDecoration(
                  //                   labelText: '碳水化合物',
                  //                   suffixText: 'g',
                  //                 ),
                  //                 keyboardType: TextInputType.number,
                  //                 inputFormatters: [
                  //                   FilteringTextInputFormatter.allow(
                  //                     RegExp(r'^\d*\.?\d*$'),
                  //                   ),
                  //                 ],
                  //               ),
                  //             ),
                  //             const SizedBox(width: 16),
                  //             Expanded(
                  //               child: FormBuilderTextField(
                  //                 key: ValueKey(
                  //                   'protein-${intake?['protein']}',
                  //                 ),
                  //                 name: 'targetProtein',
                  //                 initialValue:
                  //                     intake?['protein']?.toString() ??
                  //                     user.targetProtein?.toString() ??
                  //                     '',
                  //                 decoration: const InputDecoration(
                  //                   labelText: '蛋白质',
                  //                   suffixText: 'g',
                  //                 ),
                  //                 keyboardType: TextInputType.number,
                  //                 inputFormatters: [
                  //                   FilteringTextInputFormatter.allow(
                  //                     RegExp(r'^\d*\.?\d*$'),
                  //                   ),
                  //                 ],
                  //               ),
                  //             ),
                  //             const SizedBox(width: 16),
                  //             Expanded(
                  //               child: FormBuilderTextField(
                  //                 key: ValueKey('fat-${intake?['fat']}'),
                  //                 name: 'targetFat',
                  //                 initialValue:
                  //                     intake?['fat']?.toString() ??
                  //                     user.targetFat?.toString() ??
                  //                     '',
                  //                 decoration: const InputDecoration(
                  //                   labelText: '脂肪',
                  //                   suffixText: 'g',
                  //                 ),
                  //                 keyboardType: TextInputType.number,
                  //                 inputFormatters: [
                  //                   FilteringTextInputFormatter.allow(
                  //                     RegExp(r'^\d*\.?\d*$'),
                  //                   ),
                  //                 ],
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //       ],
                  //     );
                  //   },
                  // ),
                  // const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveUserInfo,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  )
                  : const Text('保存'),
        ),
      ),
    );
  }
}

/// 分节标题组件
class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Divider(),
        const SizedBox(height: 8),
      ],
    );
  }
}
