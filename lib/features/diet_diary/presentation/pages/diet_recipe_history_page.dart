import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../../../shared/widgets/toast_utils.dart';
import '../../domain/entities/diet_recipe.dart';
import '../viewmodels/diet_diary_viewmodel.dart';

class DietRecipeHistoryPage extends StatefulWidget {
  const DietRecipeHistoryPage({super.key});

  @override
  State<DietRecipeHistoryPage> createState() => _DietRecipeHistoryPageState();
}

class _DietRecipeHistoryPageState extends State<DietRecipeHistoryPage> {
  List<DietRecipe> _recipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final viewModel = Provider.of<DietDiaryViewModel>(context, listen: false);
      final recipes = await viewModel.getAllDietRecipes();

      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ToastUtils.showError('加载食谱历史失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('食谱历史')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _recipes.isEmpty
              ? const Center(child: Text('暂无食谱记录'))
              : ListView.builder(
                itemCount: _recipes.length,
                itemBuilder: (context, index) {
                  final recipe = _recipes[index];

                  final viewModel = Provider.of<DietDiaryViewModel>(
                    context,
                    listen: false,
                  );

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: ListTile(
                      title: Text(
                        '${recipe.days}天${recipe.mealsPerDay}餐食谱',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '日期: ${_formatDate(recipe.date)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '使用模型: ${recipe.modelName}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '生成时间: ${_formatDateTime(recipe.gmtCreate)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (recipe.dietaryPreference != null &&
                              recipe.dietaryPreference!.isNotEmpty)
                            Text(
                              '饮食偏好: ${recipe.dietaryPreference}',
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy),
                            tooltip: '复制内容',
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: recipe.content),
                              );
                              ToastUtils.showInfo('已复制到剪贴板');
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(context, recipe);
                      },
                      onLongPress: () async {
                        var result = await showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('删除分析'),
                                content: const Text('确定要删除该分析吗？'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context, false);
                                    },
                                    child: const Text('取消'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context, true);
                                    },
                                    child: const Text('确定'),
                                  ),
                                ],
                              ),
                        );

                        if (result == true) {
                          await viewModel.deleteDietRecipe(recipe.id!);
                          await _loadRecipes();
                        }
                      },
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                    ),
                  );
                },
              ),
    );
  }

  String _formatDate(DateTime date) {
    final viewModel = Provider.of<DietDiaryViewModel>(context, listen: false);
    return viewModel.getFormattedDate(date);
  }

  String _formatDateTime(DateTime dateTime) {
    final viewModel = Provider.of<DietDiaryViewModel>(context, listen: false);
    return viewModel.getFormattedDateTime(dateTime);
  }
}
