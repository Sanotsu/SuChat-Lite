import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/constants/constants.dart';
import '../../domain/entities/meal_record.dart';
import '../../domain/entities/meal_type.dart';
import '../viewmodels/diet_diary_viewmodel.dart';

/// 饮食分析和定制食谱中用到的简单指定日期餐食详情列表
class MealFoodListCard extends StatefulWidget {
  final DietDiaryViewModel viewModel;

  const MealFoodListCard({super.key, required this.viewModel});

  @override
  State<MealFoodListCard> createState() => _MealFoodListCardState();
}

class _MealFoodListCardState extends State<MealFoodListCard> {
  // 添加状态变量，用于跟踪展开的面板
  final Map<int, bool> _expandedPanels = {};

  @override
  Widget build(BuildContext context) {
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
                  '当日餐食详情 ${DateFormat(constDateFormat).format(widget.viewModel.selectedDate)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMealFoodsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMealFoodsList() {
    // 获取所有餐次记录
    final mealRecords = widget.viewModel.mealRecords;
    if (mealRecords.isEmpty) {
      return const Center(child: Text('暂无餐次记录'));
    }

    // 按餐次类型排序
    final sortedMeals = List<MealRecord>.from(mealRecords)
      ..sort((a, b) => a.mealType.index.compareTo(b.mealType.index));

    return ExpansionPanelList(
      elevation: 1,
      expandedHeaderPadding: EdgeInsets.zero,
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          _expandedPanels[index] = !(_expandedPanels[index] ?? false);
        });
      },
      children:
          sortedMeals.asMap().entries.map((entry) {
            final index = entry.key;
            final meal = entry.value;
            final mealType = meal.mealType;
            final mealId = meal.id;

            // 如果mealId为空，则显示空列表
            if (mealId == null) {
              return ExpansionPanel(
                headerBuilder:
                    (context, isExpanded) => _buildMealHeader(mealType, 0),
                body: const Center(child: Text('无法加载餐次详情')),
                isExpanded: _expandedPanels[index] ?? false,
              );
            }

            // 获取该餐次的食品详情
            final foodDetails = widget.viewModel.mealFoodDetails[mealId] ?? [];
            final hasFood = foodDetails.isNotEmpty;

            return ExpansionPanel(
              headerBuilder:
                  (context, isExpanded) => _buildMealHeader(
                    mealType,
                    foodDetails
                        .fold(0.0, (sum, food) => sum + food.calories)
                        .toInt(),
                    hasFood: hasFood,
                  ),
              body:
                  hasFood
                      ? ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: foodDetails.length,
                        itemBuilder: (context, index) {
                          final food = foodDetails[index];
                          return ListTile(
                            dense: true,
                            title: Text(
                              food.foodName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${food.quantity}${food.unit ?? '克'} · ${food.calories.toInt()}千卡',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '碳水: ${food.carbs.toInt()}克 · 蛋白质: ${food.protein.toInt()}克 · 脂肪: ${food.fat.toInt()}克',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                      : const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: Text('未记录食品')),
                      ),
              isExpanded: _expandedPanels[index] ?? false,
            );
          }).toList(),
    );
  }

  Widget _buildMealHeader(
    MealType mealType,
    int calories, {
    bool hasFood = false,
  }) {
    String title;
    IconData icon;
    Color color;

    switch (mealType) {
      case MealType.breakfast:
        title = '早餐';
        icon = Icons.breakfast_dining;
        color = Colors.orange;
        break;
      case MealType.lunch:
        title = '午餐';
        icon = Icons.lunch_dining;
        color = Colors.green;
        break;
      case MealType.dinner:
        title = '晚餐';
        icon = Icons.dinner_dining;
        color = Colors.purple;
        break;
      case MealType.snack:
        title = '加餐';
        icon = Icons.icecream;
        color = Colors.pink;
        break;
    }

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text('$calories 千卡'),
      trailing:
          hasFood
              ? null
              : const Icon(Icons.remove_circle_outline, color: Colors.grey),
    );
  }
}
