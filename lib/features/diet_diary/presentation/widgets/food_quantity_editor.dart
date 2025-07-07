import 'package:flutter/material.dart';
import '../../domain/entities/meal_food_detail.dart';

class FoodQuantityEditor extends StatefulWidget {
  final MealFoodDetail foodDetail;
  final Function(double) onQuantityChanged;
  final String? title;

  const FoodQuantityEditor({
    super.key,
    required this.foodDetail,
    required this.onQuantityChanged,
    this.title,
  });

  @override
  State<FoodQuantityEditor> createState() => _FoodQuantityEditorState();
}

class _FoodQuantityEditorState extends State<FoodQuantityEditor> {
  late TextEditingController _quantityController;
  late double _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.foodDetail.quantity;
    _quantityController = TextEditingController(text: _quantity.toString());
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _updateQuantity(double value) {
    if (value > 0) {
      setState(() {
        _quantity = value;
        _quantityController.text = value.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题栏
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title ?? widget.foodDetail.foodName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),

              // 营养信息
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNutrientInfo(
                      '热量',
                      widget.foodDetail.calories *
                          (_quantity / widget.foodDetail.quantity),
                      '千卡',
                      Colors.orange,
                    ),
                    _buildNutrientInfo(
                      '碳水',
                      widget.foodDetail.carbs *
                          (_quantity / widget.foodDetail.quantity),
                      '克',
                      Colors.amber,
                    ),
                    _buildNutrientInfo(
                      '蛋白质',
                      widget.foodDetail.protein *
                          (_quantity / widget.foodDetail.quantity),
                      '克',
                      Colors.blue,
                    ),
                    _buildNutrientInfo(
                      '脂肪',
                      widget.foodDetail.fat *
                          (_quantity / widget.foodDetail.quantity),
                      '克',
                      Colors.red,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 数量编辑
              Row(
                children: [
                  InkWell(
                    onTap: () => _updateQuantity(_quantity - 1),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: Icon(Icons.remove)),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 数量输入框
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        suffixText: "克",
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
                      onChanged: (value) {
                        final newQuantity = double.tryParse(value);
                        if (newQuantity != null) {
                          setState(() {
                            _quantity = newQuantity;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 增加按钮
                  InkWell(
                    onTap: () => _updateQuantity(_quantity + 1),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: Icon(Icons.add)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              const SizedBox(height: 16),

              // 确认按钮
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onQuantityChanged(_quantity);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '确认',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
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
