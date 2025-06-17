import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/entities/cus_llm_model.dart';
import '../../../../shared/constants/constant_llm_enum.dart';
import '../../../../shared/constants/constants.dart';
import '../../../../shared/services/model_manager_service.dart';
import '../../../../shared/widgets/cus_dropdown_button.dart';
import '../../../../shared/widgets/markdown_render/cus_markdown_renderer.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../data/services/diet_analysis_service.dart';
import '../../domain/entities/diet_analysis.dart';
import '../viewmodels/diet_diary_viewmodel.dart';
import '../widgets/analysis_recipe_food_list.dart';
import 'diet_analysis_history_page.dart';
import 'diet_recipe_page.dart';

class DietAnalysisPage extends StatefulWidget {
  const DietAnalysisPage({super.key});

  @override
  State<DietAnalysisPage> createState() => _DietAnalysisPageState();
}

class _DietAnalysisPageState extends State<DietAnalysisPage> {
  // 大模型相关状态
  List<CusLLMSpec> _modelList = [];
  CusLLMSpec? _selectedModel;

  // 分析状态
  bool _isAnalyzing = false;
  StreamSubscription? _analysisSubscription;
  VoidCallback? _cancelAnalysis;
  String _analysisResult = '';

  // 当前显示的分析记录
  DietAnalysis? _displayedAnalysis;

  // 所有分析记录
  List<DietAnalysis> _analysisHistory = [];

  // 服务
  final DietAnalysisService _analysisService = DietAnalysisService();

  @override
  void initState() {
    super.initState();
    _initModels();
    _loadExistingAnalysis();
  }

  @override
  void dispose() {
    _analysisSubscription?.cancel();
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

  Future<void> _loadExistingAnalysis() async {
    final viewModel = Provider.of<DietDiaryViewModel>(context, listen: false);

    // 获取当前日期的所有分析记录
    _analysisHistory = viewModel.currentDateAnalyses;

    // 获取最新的分析记录
    final latestAnalysis = viewModel.currentDietAnalysis;

    if (latestAnalysis != null) {
      setState(() {
        _displayedAnalysis = latestAnalysis;
        _analysisResult = latestAnalysis.content;
      });
    }
  }

  void _showAnalysis(DietAnalysis analysis) {
    setState(() {
      _displayedAnalysis = analysis;
      _analysisResult = analysis.content;
      _isAnalyzing = false;
    });
  }

  Future<void> _analyzeDiet() async {
    if (_selectedModel == null) {
      ToastUtils.showError('请先选择用于分析的大模型');
      return;
    }

    final viewModel = Provider.of<DietDiaryViewModel>(context, listen: false);

    if (viewModel.userProfile == null) {
      ToastUtils.showError('未找到用户信息，请先完善个人资料');
      return;
    }

    if (viewModel.mealRecords.isEmpty) {
      ToastUtils.showError('未找到餐次记录');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisResult = '';
      _displayedAnalysis = null;
    });

    try {
      // 准备餐次ID和类型的映射
      final mealRecordIds =
          viewModel.mealRecords
              .where((meal) => meal.id != null)
              .map((meal) => meal.id!)
              .toList();

      final mealTypes = {
        for (var meal in viewModel.mealRecords)
          if (meal.id != null) meal.id!: meal.mealType,
      };

      // 调用分析服务
      final (stream, cancel) = await _analysisService.analyzeDailyDiet(
        model: _selectedModel!,
        userProfile: viewModel.userProfile!,
        mealFoodDetails: viewModel.mealFoodDetails,
        dailyNutrition: viewModel.dailyNutrition ?? {},
        dailyRecommended: viewModel.dailyRecommendedIntake ?? {},
        mealRecordIds: mealRecordIds,
        mealTypes: mealTypes,
      );

      _cancelAnalysis = cancel;

      // 订阅流式响应
      _analysisSubscription = stream.listen(
        (content) {
          setState(() {
            _analysisResult += content;
          });
        },
        onDone: () async {
          if (mounted) {
            setState(() {
              _isAnalyzing = false;
            });

            // 保存分析结果到数据库
            if (_analysisResult.isNotEmpty) {
              try {
                final savedAnalysis = await viewModel.saveDietAnalysis(
                  _analysisResult,
                  _selectedModel?.name ?? '未知模型',
                );

                setState(() {
                  _displayedAnalysis = savedAnalysis;
                  // 更新历史记录列表
                  _analysisHistory = viewModel.currentDateAnalyses;
                });

                ToastUtils.showInfo('分析结果已保存');
              } catch (e) {
                ToastUtils.showError('保存分析结果失败: $e');
              }
            }
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isAnalyzing = false;
              _analysisResult += '\n\n分析过程中出错: $error';
            });
            ToastUtils.showError('分析过程中出错: $error');
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _analysisResult += '\n\n启动分析失败: $e';
        });
        ToastUtils.showError('启动分析失败: $e');
      }
    }
  }

  void _cancelAnalysisProcess() {
    _cancelAnalysis?.call();
    _analysisSubscription?.cancel();

    setState(() {
      _isAnalyzing = false;
      _analysisResult += '\n\n[分析已取消]';
    });

    ToastUtils.showInfo('分析已取消');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('饮食分析'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            tooltip: '定制食谱',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          DietRecipePage(analysisId: _displayedAnalysis?.id),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '历史记录',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DietAnalysisHistoryPage(),
                ),
              ).then((result) {
                // 处理从历史页面返回的分析数据
                if (result != null && result is DietAnalysis) {
                  _showAnalysis(result);
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
                /// 日期显示
                dateCard(viewModel),
                const SizedBox(height: 16),

                /// 饮食摄入摘要
                summaryCard(viewModel),
                const SizedBox(height: 16),

                /// 添加当日四餐的食品列表
                MealFoodListCard(viewModel: viewModel),
                const SizedBox(height: 16),

                /// 模型选择
                modelSelectionCard(),
                const SizedBox(height: 16),

                /// 分析按钮 - 修改为始终显示，允许重复分析
                analysisButton(),
                const SizedBox(height: 16),

                /// 历史分析记录和当前显示的分析结果
                if (_analysisHistory.isNotEmpty) ...[
                  analysisHistoryCard(),
                  analysisResultCard(viewModel),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  ///
  /// 页面从上到下的部件
  ///
  Widget dateCard(DietDiaryViewModel viewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '分析日期',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              viewModel.getFormattedDate(viewModel.selectedDate),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget analysisHistoryCard() {
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
                  '历史分析记录',
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
                itemCount: _analysisHistory.length,
                itemBuilder: (context, index) {
                  final analysis = _analysisHistory[index];
                  final isSelected = _displayedAnalysis?.id == analysis.id;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      onTap: () => _showAnalysis(analysis),
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
                              DateFormat(
                                constTimeFormat,
                              ).format(analysis.createdAt),
                              style: TextStyle(
                                color: isSelected ? Colors.white : null,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              analysis.modelName,
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

  Widget summaryCard(DietDiaryViewModel viewModel) {
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
                  '饮食摄入摘要',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildNutritionSummary(viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionSummary(DietDiaryViewModel viewModel) {
    final dailyNutrition = viewModel.dailyNutrition ?? {};
    final dailyRecommended = viewModel.dailyRecommendedIntake ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNutritionRow(
          '总热量',
          dailyNutrition['calories']?.toInt() ?? 0,
          dailyRecommended['calories']?.toInt() ?? 0,
          '千卡',
          Colors.orange,
        ),
        const SizedBox(height: 8),
        _buildNutritionRow(
          '碳水',
          dailyNutrition['carbs']?.toInt() ?? 0,
          dailyRecommended['carbs']?.toInt() ?? 0,
          '克',
          Colors.teal,
        ),
        const SizedBox(height: 8),
        _buildNutritionRow(
          '蛋白质',
          dailyNutrition['protein']?.toInt() ?? 0,
          dailyRecommended['protein']?.toInt() ?? 0,
          '克',
          Colors.purple,
        ),
        const SizedBox(height: 8),
        _buildNutritionRow(
          '脂肪',
          dailyNutrition['fat']?.toInt() ?? 0,
          dailyRecommended['fat']?.toInt() ?? 0,
          '克',
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildNutritionRow(
    String label,
    int current,
    int target,
    String unit,
    Color color,
  ) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final percentage = target > 0 ? (current / target * 100).toInt() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(flex: 1, child: Text(label)),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$percentage%',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Expanded(flex: 3, child: SizedBox()),
            Expanded(
              flex: 7,
              child: Text(
                '$current / $target $unit',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ],
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
                  '选择分析模型',
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

  Widget analysisButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isAnalyzing ? _cancelAnalysisProcess : _analyzeDiet,
        icon:
            _isAnalyzing
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : const Icon(Icons.analytics),
        label: Text(_isAnalyzing ? '取消分析' : '分析饮食'),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _isAnalyzing ? Colors.red : Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget analysisResultCard(DietDiaryViewModel viewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '当前分析结果',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
              ],
            ),

            Text(
              '使用模型: ${_displayedAnalysis?.modelName ?? _selectedModel?.name ?? "未知"}',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            if (_displayedAnalysis != null) ...[
              // const SizedBox(height: 8),
              Text(
                '分析时间: ${viewModel.getFormattedDateTime(_displayedAnalysis!.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            RepaintBoundary(
              child: CusMarkdownRenderer.instance.render(
                _analysisResult,
                selectable: true,
              ),
            ),
            if (_displayedAnalysis != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => DietRecipePage(
                                analysisId: _displayedAnalysis!.id,
                              ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text('根据分析生成食谱'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
