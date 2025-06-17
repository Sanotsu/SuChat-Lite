import 'package:flutter/material.dart';
import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../domain/entities/food_item.dart';
import '../viewmodels/diet_diary_viewmodel.dart';
import 'food_list_item.dart';

class FoodListView extends StatelessWidget {
  final DietDiaryViewModel viewModel;
  final String searchQuery;
  final bool showOnlyFavorites;
  final List<int>? existingFoodIds;
  final String errorContext;
  final Function(FoodItem) onFoodTap;
  final Function(FoodItem) onFavoriteToggle;
  final Function(FoodItem)? onFoodEdit;
  final Function(FoodItem)? onFoodDelete;
  final Function(FoodItem)? onAddToMeal;
  final Function(String)? onAddNewFood;
  final bool showManagementActions;
  final bool showAddToMealAction;
  final EdgeInsetsGeometry? padding;

  const FoodListView({
    super.key,
    required this.viewModel,
    required this.searchQuery,
    required this.showOnlyFavorites,
    required this.errorContext,
    required this.onFoodTap,
    required this.onFavoriteToggle,
    this.existingFoodIds,
    this.onFoodEdit,
    this.onFoodDelete,
    this.onAddToMeal,
    this.onAddNewFood,
    this.showManagementActions = false,
    this.showAddToMealAction = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.error != null && viewModel.errorContext == errorContext) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        commonExceptionDialog(context, "食品列表错误", viewModel.error!);
        viewModel.clearError();
      });
    }

    final foodItems =
        searchQuery.isEmpty ? viewModel.foodItems : viewModel.searchResults;

    final filteredItems =
        showOnlyFavorites
            ? foodItems.where((item) => item.isFavorite).toList()
            : foodItems;

    if (filteredItems.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final food = filteredItems[index];
        final bool isExistingFood = existingFoodIds?.contains(food.id) ?? false;

        return FoodListItem(
          food: food,
          onTap: () => onFoodTap(food),
          onFavoriteToggle: () => onFavoriteToggle(food),
          onEdit: onFoodEdit != null ? () => onFoodEdit!(food) : null,
          onDelete: onFoodDelete != null ? () => onFoodDelete!(food) : null,
          onAddToMeal:
              onAddToMeal != null && showAddToMealAction
                  ? () => onAddToMeal!(food)
                  : null,
          showManagementActions: showManagementActions,
          showAddToMealAction: showAddToMealAction,
          isExistingInMeal: isExistingFood,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_food, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty
                ? (showOnlyFavorites ? '暂无收藏的食品' : '暂无食品数据')
                : '没有找到匹配的食品',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          if (searchQuery.isNotEmpty && onAddNewFood != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton.icon(
                onPressed: () => onAddNewFood!(searchQuery),
                icon: const Icon(Icons.add),
                label: Text('添加"$searchQuery"到食品库'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
