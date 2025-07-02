import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suchat_lite/shared/widgets/simple_tool_widget.dart';

import '../../../../core/utils/simple_tools.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/meal_type.dart';
import '../../domain/entities/meal_food_detail.dart';
import '../viewmodels/diet_diary_viewmodel.dart';
import '../widgets/food_quantity_editor.dart';
import '../widgets/food_search_bar.dart';
import '../widgets/food_list_view.dart';
import '../widgets/favorite_filter_button.dart';
import 'food_detail_page.dart';
import 'food_edit_page.dart';

class FoodSearchPage extends StatefulWidget {
  final int mealRecordId;
  final MealType mealType;

  const FoodSearchPage({
    super.key,
    required this.mealRecordId,
    required this.mealType,
  });

  @override
  State<FoodSearchPage> createState() => _FoodSearchPageState();
}

class _FoodSearchPageState extends State<FoodSearchPage> {
  late DietDiaryViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showOnlyFavorites = false;
  List<int> _existingFoodIds = []; // 当前餐次中已有的食品ID

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<DietDiaryViewModel>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingFoods();
      _viewModel.searchFood('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 加载当前餐次中已有的食品
  Future<void> _loadExistingFoods() async {
    final foodIds = await _viewModel.getMealFoodIds(widget.mealRecordId);
    setState(() {
      _existingFoodIds = foodIds;
    });
  }

  String _getMealTypeName(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return '早餐';
      case MealType.lunch:
        return '午餐';
      case MealType.dinner:
        return '晚餐';
      case MealType.snack:
        return '零食';
    }
  }

  void _toggleFavorite(FoodItem food) {
    if (food.id != null) {
      setState(() {
        // 更新本地状态
        final index = _viewModel.foodItems.indexWhere(
          (item) => item.id == food.id,
        );
        if (index != -1) {
          _viewModel.foodItems[index] = food.copyWith(
            isFavorite: !food.isFavorite,
          );
        }
      });
      // 更新数据库
      _viewModel.updateFood(food.copyWith(isFavorite: !food.isFavorite));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('添加食品到${_getMealTypeName(widget.mealType)}'),
        actions: [
          FavoriteFilterButton(
            showOnlyFavorites: _showOnlyFavorites,
            onToggle: () {
              setState(() {
                _showOnlyFavorites = !_showOnlyFavorites;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索框
          FoodSearchBar(
            controller: _searchController,
            searchQuery: _searchQuery,
            hintText: '搜索食品',
            filled: true,
            fillColor: Colors.grey[100],
            onSearchChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _viewModel.searchFood(value);
            },
            onClearSearch: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
              _viewModel.searchFood('');
            },
          ),

          // 食品列表
          Expanded(
            child: Consumer<DietDiaryViewModel>(
              builder: (context, viewModel, child) {
                return FoodListView(
                  viewModel: viewModel,
                  searchQuery: _searchQuery,
                  showOnlyFavorites: _showOnlyFavorites,
                  errorContext: 'food_management',
                  existingFoodIds: _existingFoodIds,
                  onFoodTap: _navigateToFoodDetail,
                  onFavoriteToggle: _toggleFavorite,
                  onAddToMeal: _showFoodQuantityEditor,
                  onAddNewFood: _navigateToAddFood,
                  showAddToMealAction: true,
                  padding: const EdgeInsets.all(8),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: buildFloatingActionButton(
        () => _navigateToAddFood(''),
        context,
        icon: Icons.add,
        tooltip: '添加新食品',
      ),
    );
  }

  void _navigateToFoodDetail(FoodItem food) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FoodDetailPage(
              foodItem: food,
              mealRecordId: widget.mealRecordId,
            ),
      ),
    ).then((_) {
      // 当从FoodDetailPage返回时，直接返回到餐次详情页
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  void _navigateToAddFood(String initialName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FoodEditPage(
              initialName: initialName,
              onSave: (foodItem) {
                _viewModel.addFood(foodItem).then((addedFood) {
                  if (addedFood != null && context.mounted) {
                    ToastUtils.showInfo('食品添加成功');

                    // 显示添加数量的对话框
                    _showFoodQuantityEditor(addedFood);
                  }
                });
              },
            ),
      ),
    );
  }

  void _showFoodQuantityEditor(FoodItem food) async {
    final isExistingFood = _existingFoodIds.contains(food.id);
    double initialQuantity = 100; // 默认数量

    // 如果是已存在的食品，获取其实际数量
    if (isExistingFood) {
      try {
        // 获取该餐次中该食品的记录
        final existingRecord = await _viewModel.getMealFoodRecord(
          widget.mealRecordId,
          food.id!,
        );
        if (existingRecord != null) {
          initialQuantity = existingRecord.quantity;
        }
      } catch (e) {
        pl.e('获取食品数量失败: $e');
      }
    }

    // 创建一个临时的MealFoodDetail对象
    final tempMealFood = MealFoodDetail(
      id: 0,
      mealRecordId: widget.mealRecordId,
      foodItemId: food.id!,
      foodName: food.name,
      quantity: initialQuantity,
      unit: '克',
      caloriesPer100g: food.caloriesPer100g,
      carbsPer100g: food.carbsPer100g,
      proteinPer100g: food.proteinPer100g,
      fatPer100g: food.fatPer100g,
      gmtCreate: DateTime.now(),
      gmtModified: DateTime.now(),
    );

    final dialogTitle = isExistingFood ? '更新食品数量' : '添加食品';
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (context) => FoodQuantityEditor(
            foodDetail: tempMealFood,
            title: dialogTitle,
            onQuantityChanged: (quantity) {
              _viewModel
                  .addFoodToMeal(widget.mealRecordId, food.id!, quantity, '克')
                  .then((_) {
                    // 添加成功后直接返回到餐次详情页
                    if (!context.mounted) return;
                    Navigator.of(context).pop();

                    // 如果是新添加的食品，添加到已存在列表中
                    if (!isExistingFood) {
                      setState(() {
                        _existingFoodIds.add(food.id!);
                      });
                    }
                    ToastUtils.showInfo(
                      isExistingFood
                          ? '已更新${food.name}的数量'
                          : '已添加${food.name}到${_getMealTypeName(widget.mealType)}',
                    );
                  });
            },
          ),
    );
  }
}
