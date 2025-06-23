import 'package:flutter/material.dart';
import '../../../../shared/widgets/image_preview_helper.dart';
import '../../domain/entities/food_item.dart';

class FoodListItem extends StatelessWidget {
  final FoodItem food;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onAddToMeal;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showManagementActions;
  final bool showAddToMealAction;
  final bool isExistingInMeal;

  const FoodListItem({
    super.key,
    required this.food,
    this.onTap,
    this.onFavoriteToggle,
    this.onAddToMeal,
    this.onEdit,
    this.onDelete,
    this.showManagementActions = false,
    this.showAddToMealAction = false,
    this.isExistingInMeal = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = food.imageUrl != null && food.imageUrl!.isNotEmpty;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 食品图片或占位图
              SizedBox(
                width: 60,
                height: 60,
                child:
                    hasImage
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: buildImageViewCarouselSlider([food.imageUrl!]),
                        )
                        : Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.restaurant,
                            color: Colors.grey[400],
                          ),
                        ),
              ),
              const SizedBox(width: 8),

              // 食品信息
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (food.foodCode != null && food.foodCode!.isNotEmpty)
                      Text(
                        '编码: ${food.foodCode}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _buildNutrientTag(
                          '热量',
                          '${food.caloriesPer100g.toInt()} 千卡',
                          Colors.red,
                        ),
                        _buildNutrientTag(
                          '碳水',
                          '${food.carbsPer100g.toStringAsFixed(1)} 克',
                          Colors.amber,
                        ),
                        _buildNutrientTag(
                          '脂肪',
                          '${food.fatPer100g.toStringAsFixed(1)} 克',
                          Colors.red,
                        ),
                        _buildNutrientTag(
                          '蛋白质',
                          '${food.proteinPer100g.toStringAsFixed(1)} 克',
                          Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 操作按钮
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onFavoriteToggle != null)
                    IconButton(
                      icon: Icon(
                        food.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: food.isFavorite ? Colors.red : Colors.grey,
                        size: 20,
                      ),
                      onPressed: onFavoriteToggle,
                      tooltip: food.isFavorite ? '取消收藏' : '收藏',
                    ),
                  if (showAddToMealAction && onAddToMeal != null)
                    IconButton(
                      icon: Icon(
                        isExistingInMeal ? Icons.edit : Icons.add_circle,
                        color: isExistingInMeal ? Colors.orange : Colors.green,
                        size: 24,
                      ),
                      onPressed: onAddToMeal,
                      tooltip: isExistingInMeal ? '修改数量' : '添加到餐次',
                    ),
                  if (showManagementActions) ...[
                    if (onEdit != null)
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.blue,
                          size: 20,
                        ),
                        onPressed: onEdit,
                        tooltip: '编辑',
                      ),
                    // 长按删除，就不直接显示删除按钮了
                    // if (onDelete != null)
                    //   IconButton(
                    //     icon: const Icon(
                    //       Icons.delete,
                    //       color: Colors.red,
                    //       size: 20,
                    //     ),
                    //     onPressed: onDelete,
                    //     tooltip: '删除',
                    //   ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientTag(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
