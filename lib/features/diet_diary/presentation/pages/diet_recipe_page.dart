import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/entities/cus_llm_model.dart';
import '../../../../shared/constants/constant_llm_enum.dart';
import '../../../../shared/constants/constants.dart';
import '../../../../shared/services/model_manager_service.dart';
import '../../../../shared/widgets/cus_dropdown_button.dart';
import '../../../../shared/widgets/markdown_render/cus_markdown_renderer.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../data/services/diet_recipe_service.dart';
import '../../domain/entities/index.dart';
import '../viewmodels/diet_diary_viewmodel.dart';
import '../widgets/analysis_recipe_food_list.dart';
import 'diet_recipe_history_page.dart';

class DietRecipePage extends StatefulWidget {
  // TODOorNOTTODO 2025-06-16
  // 目前虽然有从饮食分析页面带上分析编号跳转过来生成食谱的设计，
  // 但本页面还没有将分析的内容构建到生成食谱的逻辑中
  final int? analysisId;

  const DietRecipePage({super.key, this.analysisId});

  @override
  State<DietRecipePage> createState() => _DietRecipePageState();
}

class _DietRecipePageState extends State<DietRecipePage> {
  // 大模型相关状态
  List<CusLLMSpec> _modelList = [];
  CusLLMSpec? _selectedModel;

  // 食谱生成状态
  bool _isGenerating = false;
  StreamSubscription? _recipeSubscription;
  VoidCallback? _cancelGeneration;
  String _recipeResult = '';

  // 用户偏好
  final TextEditingController _preferencesController = TextEditingController();
  int _selectedMealCount = 3;
  int _selectedDays = 1;

  // 当前显示的食谱记录
  DietRecipe? _displayedRecipe;

  // 所有食谱记录
  List<DietRecipe> _recipeHistory = [];

  // 服务
  final DietRecipeService _recipeService = DietRecipeService();

  @override
  void initState() {
    super.initState();
    _initModels();
    _loadExistingRecipes();
    _preferencesController.text = '我喜欢中式料理，不喜欢太辣的食物，无食物过敏。';
  }

  @override
  void dispose() {
    _recipeSubscription?.cancel();
    _preferencesController.dispose();
    super.dispose();
  }

  Future<void> _initModels() async {
    try {
      // 获取支持文本生成的大模型列表
      final availableModels =
          await ModelManagerService.getAvailableModelByTypes([LLModelType.cc]);

      setState(() {
        _modelList = availableModels;
        _selectedModel =
            availableModels.isNotEmpty ? availableModels.first : null;
      });
    } catch (e) {
      if (mounted) {
        ToastUtils.showError('加载模型列表失败: $e');
      }
    }
  }

  Future<void> _loadExistingRecipes() async {
    final viewModel = Provider.of<DietDiaryViewModel>(context, listen: false);

    // 如果提供了分析ID，加载与该分析相关的食谱(目前仅从饮食分析页面跳转时会带上分析ID)
    if (widget.analysisId != null) {
      final recipes = await viewModel.getDietRecipesByAnalysisId(
        widget.analysisId!,
      );
      if (recipes.isNotEmpty) {
        setState(() {
          _recipeHistory = recipes;
          _displayedRecipe = recipes.first;
          _recipeResult = _displayedRecipe!.content;
        });
      }
    } else {
      // 否则加载当前日期的所有食谱
      setState(() {
        _recipeHistory = viewModel.currentDateRecipes;
        if (_recipeHistory.isNotEmpty) {
          _displayedRecipe = _recipeHistory.first;
          _recipeResult = _displayedRecipe!.content;
        }
      });
    }
  }

  void _showRecipe(DietRecipe recipe) {
    setState(() {
      _displayedRecipe = recipe;
      _recipeResult = recipe.content;
      _isGenerating = false;
    });
  }

  Future<void> _generateRecipe() async {
    if (_selectedModel == null) {
      ToastUtils.showError('请先选择用于生成食谱的大模型');
      return;
    }

    final viewModel = Provider.of<DietDiaryViewModel>(context, listen: false);

    if (viewModel.userProfile == null) {
      ToastUtils.showError('未找到用户信息，请先完善个人资料');
      return;
    }

    setState(() {
      _isGenerating = true;
      _recipeResult = '';
      _displayedRecipe = null;
    });

    try {
      // 调用食谱生成服务
      final (stream, cancel) = await _recipeService.generatePersonalizedRecipe(
        model: _selectedModel!,
        userProfile: viewModel.userProfile!,
        dailyNutrition: viewModel.dailyNutrition ?? {},
        dailyRecommended: viewModel.dailyRecommendedIntake ?? {},
        preferences: _preferencesController.text,
        mealCount: _selectedMealCount,
        days: _selectedDays,
      );

      _cancelGeneration = cancel;

      // 订阅流式响应
      _recipeSubscription = stream.listen(
        (content) {
          setState(() {
            _recipeResult += content;
          });
        },
        onDone: () async {
          if (mounted) {
            setState(() {
              _isGenerating = false;
            });

            // 保存食谱到数据库
            if (_recipeResult.isNotEmpty) {
              try {
                final savedRecipe = await viewModel.saveDietRecipe(
                  content: _recipeResult,
                  modelName: _selectedModel?.name ?? '未知模型',
                  days: _selectedDays,
                  mealsPerDay: _selectedMealCount,
                  dietaryPreference: _preferencesController.text,
                  analysisId: widget.analysisId,
                );

                setState(() {
                  _displayedRecipe = savedRecipe;
                  // 更新历史记录列表
                  _recipeHistory = viewModel.currentDateRecipes;
                });

                ToastUtils.showInfo('食谱已保存');
              } catch (e) {
                ToastUtils.showError('保存食谱失败: $e');
              }
            }
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isGenerating = false;
              _recipeResult += '\n\n生成过程中出错: $error';
            });
            ToastUtils.showError('生成过程中出错: $error');
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _recipeResult += '\n\n启动生成失败: $e';
        });
        ToastUtils.showError('启动生成失败: $e');
      }
    }
  }

  void _cancelGenerationProcess() {
    _cancelGeneration?.call();
    _recipeSubscription?.cancel();

    setState(() {
      _isGenerating = false;
      _recipeResult += '\n\n[生成已取消]';
    });

    ToastUtils.showInfo('生成已取消');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('定制食谱'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '历史记录',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DietRecipeHistoryPage(),
                ),
              ).then((result) {
                // 处理从历史页面返回的食谱数据
                if (result != null && result is DietRecipe) {
                  _showRecipe(result);
                }
              });
            },
          ),
        ],
      ),
      body: Consumer<DietDiaryViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 用户信息卡片
                if (viewModel.userProfile != null) ...[
                  userInfoCard(viewModel.userProfile!),
                  const SizedBox(height: 16),
                ],

                /// 营养摄入卡片
                nutritionCard(viewModel),
                MealFoodListCard(viewModel: viewModel),
                const SizedBox(height: 16),

                /// 食谱定制选项卡片
                recipeCustomizationCard(),
                const SizedBox(height: 16),

                // 模型选择卡片
                modelSelectionCard(),
                const SizedBox(height: 16),

                // 生成按钮
                generateButton(),
                const SizedBox(height: 16),

                /// 历史食谱记录
                if (_recipeHistory.isNotEmpty) ...[
                  recipeHistoryCard(),
                  recipeResultCard(viewModel),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget userInfoCard(UserProfile userProfile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '用户信息',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildInfoItem('姓名', userProfile.name)),
                Expanded(
                  child: _buildInfoItem(
                    '性别',
                    userProfile.gender == Gender.male ? '男' : '女',
                  ),
                ),
                Expanded(child: _buildInfoItem('年龄', '${userProfile.age}岁')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('身高', '${userProfile.height}厘米'),
                ),
                Expanded(
                  child: _buildInfoItem('体重', '${userProfile.weight}公斤'),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'BMI',
                    userProfile.bmi.toStringAsFixed(1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('目标', getGoalText(userProfile.goal)),
                ),
                Expanded(
                  child: _buildInfoItem(
                    '活动水平',
                    getActivityLevelText(userProfile.activityLevel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget nutritionCard(DietDiaryViewModel viewModel) {
    final dailyNutrition = viewModel.dailyNutrition ?? {};
    final dailyRecommended = viewModel.dailyRecommendedIntake ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.restaurant,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '营养需求',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '推荐摄入',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildNutrientItem(
                        '热量',
                        dailyRecommended['calories']?.toInt() ?? 0,
                        '千卡',
                      ),
                      _buildNutrientItem(
                        '碳水',
                        dailyRecommended['carbs']?.toInt() ?? 0,
                        '克',
                      ),
                      _buildNutrientItem(
                        '蛋白质',
                        dailyRecommended['protein']?.toInt() ?? 0,
                        '克',
                      ),
                      _buildNutrientItem(
                        '脂肪',
                        dailyRecommended['fat']?.toInt() ?? 0,
                        '克',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '当前摄入',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildNutrientItem(
                        '热量',
                        dailyNutrition['calories']?.toInt() ?? 0,
                        '千卡',
                      ),
                      _buildNutrientItem(
                        '碳水',
                        dailyNutrition['carbs']?.toInt() ?? 0,
                        '克',
                      ),
                      _buildNutrientItem(
                        '蛋白质',
                        dailyNutrition['protein']?.toInt() ?? 0,
                        '克',
                      ),
                      _buildNutrientItem(
                        '脂肪',
                        dailyNutrition['fat']?.toInt() ?? 0,
                        '克',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientItem(String label, int value, String unit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '$value $unit',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget recipeHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '历史食谱记录',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _recipeHistory.length,
                itemBuilder: (context, index) {
                  final recipe = _recipeHistory[index];
                  final isSelected = _displayedRecipe?.id == recipe.id;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      onTap: () => _showRecipe(recipe),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${recipe.mealsPerDay}餐 · ${recipe.days}天',
                              style: TextStyle(
                                color: isSelected ? Colors.white : null,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat(
                                constTimeFormat,
                              ).format(recipe.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isSelected ? Colors.white70 : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget recipeCustomizationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.restaurant_menu,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '食谱定制选项',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 餐次数量选择
            Text('每日餐次数量', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Center(
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment<int>(value: 1, label: Text('1')),
                  ButtonSegment<int>(value: 2, label: Text('2')),
                  ButtonSegment<int>(value: 3, label: Text('3')),
                  ButtonSegment<int>(value: 4, label: Text('4')),
                ],
                selected: {_selectedMealCount},
                onSelectionChanged: (Set<int> newSelection) {
                  setState(() {
                    _selectedMealCount = newSelection.first;
                  });
                },
              ),
            ),

            const SizedBox(height: 16),

            // 食谱天数选择
            Text('食谱天数', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Center(
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment<int>(value: 1, label: Text('1')),
                  ButtonSegment<int>(value: 3, label: Text('3')),
                  ButtonSegment<int>(value: 5, label: Text('5')),
                  ButtonSegment<int>(value: 7, label: Text('7')),
                ],
                selected: {_selectedDays},
                onSelectionChanged: (Set<int> newSelection) {
                  setState(() {
                    _selectedDays = newSelection.first;
                  });
                },
              ),
            ),

            const SizedBox(height: 16),

            // 饮食偏好输入
            Text('饮食偏好和禁忌', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _preferencesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '请输入您的饮食偏好、禁忌或过敏原...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget modelSelectionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.smart_toy,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '选择生成模型',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            buildDropdownButton2<CusLLMSpec?>(
              value: _selectedModel,
              items: _modelList,
              height: 56,
              hintLabel: "选择大模型",
              alignment: Alignment.centerLeft,
              onChanged: (value) => setState(() => _selectedModel = value!),
              itemToString:
                  (e) =>
                      "${CP_NAME_MAP[(e as CusLLMSpec).platform]} - ${e.name}",
            ),
          ],
        ),
      ),
    );
  }

  Widget generateButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isGenerating ? _cancelGenerationProcess : _generateRecipe,
        icon:
            _isGenerating
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : const Icon(Icons.restaurant_menu),
        label: Text(_isGenerating ? '取消生成' : '生成定制食谱'),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _isGenerating
                  ? Colors.red
                  : Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget recipeResultCard(DietDiaryViewModel viewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.menu_book,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '定制食谱',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: '复制到剪贴板',
                  onPressed: () {
                    // 复制到剪贴板
                    Clipboard.setData(ClipboardData(text: _recipeResult));
                    ToastUtils.showInfo('已复制到剪贴板');
                  },
                ),
              ],
            ),
            if (_displayedRecipe != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${_displayedRecipe!.days}天${_displayedRecipe!.mealsPerDay}餐食谱',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Text(
                    '生成时间: ${viewModel.getFormattedDateTime(_displayedRecipe!.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              if (_displayedRecipe!.dietaryPreference != null &&
                  _displayedRecipe!.dietaryPreference!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '饮食偏好: ${_displayedRecipe!.dietaryPreference}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
            const Divider(),
            RepaintBoundary(
              child: CusMarkdownRenderer.instance.render(
                _recipeResult,
                selectable: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
