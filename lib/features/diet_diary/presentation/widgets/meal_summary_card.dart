import 'package:flutter/material.dart';
import '../../domain/entities/meal_type.dart';
import '../../domain/entities/meal_food_detail.dart';

class MealSummaryCard extends StatefulWidget {
  final MealType mealType;
  final double calories;
  final double carbs;
  final double protein;
  final double fat;
  final int foodCount;
  // 点击跳转按钮，跳转到详情页(父组件实现)
  final VoidCallback onTap;
  final List<MealFoodDetail> foodDetails;
  // 点击食品，弹出食品数量编辑器(父组件实现)
  final Function(MealFoodDetail) onFoodTap;
  // 滑动食品，删除食品(父组件实现)
  final Function(MealFoodDetail) onFoodDismiss;
  // final VoidCallback onAddFood;

  const MealSummaryCard({
    super.key,
    required this.mealType,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.foodCount,
    required this.onTap,
    required this.foodDetails,
    required this.onFoodTap,
    required this.onFoodDismiss,
    // required this.onAddFood,
  });

  @override
  State<MealSummaryCard> createState() => _MealSummaryCardState();
}

class _MealSummaryCardState extends State<MealSummaryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // 餐次标题栏
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  _buildMealIcon(),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.mealType.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.foodCount > 0
                            ? '已记录 ${widget.foodCount} 种食物'
                            : '暂无记录',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${widget.calories.toInt()} 千卡',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.foodCount > 0)
                        Text(
                          _isExpanded ? '收起' : '展开',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                    ],
                  ),

                  // 折叠图标(不显示了，图标太多不好看)
                  // if (widget.foodCount > 0)
                  //   Icon(
                  //     _isExpanded ? Icons.expand_less : Icons.expand_more,
                  //     color: Colors.blue[700],
                  //   ),

                  // 跳转到详情页(在父组件实现)
                  IconButton(
                    onPressed: widget.onTap,
                    icon: Icon(Icons.arrow_forward),
                  ),
                ],
              ),
            ),
          ),

          // 营养素信息
          if (widget.foodCount > 0) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNutrientInfo('碳水', widget.carbs, '克', Colors.amber),
                  _buildNutrientInfo('蛋白质', widget.protein, '克', Colors.blue),
                  _buildNutrientInfo('脂肪', widget.fat, '克', Colors.red),
                ],
              ),
            ),
          ],

          // 可折叠的食品列表
          if (_isExpanded && widget.foodCount > 0) ...[
            const Divider(height: 1),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.foodDetails.length,
              itemBuilder: (context, index) {
                final food = widget.foodDetails[index];
                return Dismissible(
                  key: Key('food_${food.id}'),
                  direction: DismissDirection.horizontal,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 16.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('删除食品'),
                          content: Text('确定要删除"${food.foodName}"吗？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('删除'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) {
                    widget.onFoodDismiss(food);
                  },
                  child: ListTile(
                    dense: true,
                    title: Text(food.foodName),
                    subtitle: Text('${food.quantity} ${food.unit ?? "克"}'),
                    trailing: Text('${food.calories.toInt()} 千卡'),
                    onTap: () => widget.onFoodTap(food),
                  ),
                );
              },
            ),
          ],

          // // 底部操作区域
          // Container(
          //   decoration: BoxDecoration(
          //     color: Colors.grey[50],
          //     borderRadius: const BorderRadius.only(
          //       bottomLeft: Radius.circular(12),
          //       bottomRight: Radius.circular(12),
          //     ),
          //   ),
          //   child: Column(
          //     children: [
          //       // // 添加食品按钮
          //       // Padding(
          //       //   padding: const EdgeInsets.symmetric(
          //       //     horizontal: 16.0,
          //       //     vertical: 8.0,
          //       //   ),
          //       //   child: InkWell(
          //       //     onTap: widget.onAddFood,
          //       //     borderRadius: BorderRadius.circular(8),
          //       //     child: Container(
          //       //       padding: const EdgeInsets.symmetric(vertical: 10.0),
          //       //       decoration: BoxDecoration(
          //       //         color:
          //       //             widget.foodCount > 0
          //       //                 ? Colors.white
          //       //                 : Colors.blue.withOpacity(0.1),
          //       //         borderRadius: BorderRadius.circular(8),
          //       //         border: Border.all(
          //       //           color:
          //       //               widget.foodCount > 0
          //       //                   ? Colors.grey.withOpacity(0.3)
          //       //                   : Colors.blue.withOpacity(0.5),
          //       //         ),
          //       //       ),
          //       //       child: Row(
          //       //         mainAxisAlignment: MainAxisAlignment.center,
          //       //         children: [
          //       //           Icon(
          //       //             Icons.add,
          //       //             size: 16,
          //       //             color:
          //       //                 widget.foodCount > 0
          //       //                     ? Colors.grey[700]
          //       //                     : Colors.blue,
          //       //           ),
          //       //           const SizedBox(width: 8),
          //       //           Text(
          //       //             '添加食品',
          //       //             style: TextStyle(
          //       //               color:
          //       //                   widget.foodCount > 0
          //       //                       ? Colors.grey[700]
          //       //                       : Colors.blue,
          //       //               fontSize: 14,
          //       //               fontWeight: FontWeight.w500,
          //       //             ),
          //       //           ),
          //       //         ],
          //       //       ),
          //       //     ),
          //       //   ),
          //       // ),
          //       // // 查看详情按钮
          //       // InkWell(
          //       //   onTap: widget.onTap,
          //       //   child: Container(
          //       //     padding: const EdgeInsets.symmetric(vertical: 8.0),
          //       //     decoration: const BoxDecoration(
          //       //       borderRadius: BorderRadius.only(
          //       //         bottomLeft: Radius.circular(12),
          //       //         bottomRight: Radius.circular(12),
          //       //       ),
          //       //     ),
          //       //     child: Row(
          //       //       mainAxisAlignment: MainAxisAlignment.center,
          //       //       children: [
          //       //         Text(
          //       //           '查看详情',
          //       //           style: TextStyle(
          //       //             color: Colors.grey[700],
          //       //             fontSize: 12,
          //       //           ),
          //       //         ),
          //       //         const SizedBox(width: 4),
          //       //         Icon(
          //       //           Icons.arrow_forward_ios,
          //       //           size: 12,
          //       //           color: Colors.grey[700],
          //       //         ),
          //       //       ],
          //       //     ),
          //       //   ),
          //       // ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildMealIcon() {
    IconData iconData;
    Color iconColor;

    switch (widget.mealType) {
      case MealType.breakfast:
        iconData = Icons.breakfast_dining;
        iconColor = Colors.orange;
        break;
      case MealType.lunch:
        iconData = Icons.lunch_dining;
        iconColor = Colors.green;
        break;
      case MealType.dinner:
        iconData = Icons.dinner_dining;
        iconColor = Colors.purple;
        break;
      case MealType.snack:
        iconData = Icons.icecream;
        iconColor = Colors.pink;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  Widget _buildNutrientInfo(
    String label,
    double value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              '${value.toInt()} $unit',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}
