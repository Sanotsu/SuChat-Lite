import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/image_preview_helper.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../domain/entities/food_item.dart';
import '../viewmodels/diet_diary_viewmodel.dart';
import 'food_edit_page.dart';

class FoodDetailPage extends StatefulWidget {
  final FoodItem foodItem;
  final int? mealRecordId;
  final bool isEditable;

  const FoodDetailPage({
    super.key,
    required this.foodItem,
    this.mealRecordId,
    this.isEditable = false,
  });

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  late DietDiaryViewModel _viewModel;
  late TextEditingController _quantityController;
  late double _quantity;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<DietDiaryViewModel>(context, listen: false);
    _quantityController = TextEditingController(text: '100');
    _quantity = 100.0;
    _isFavorite = widget.foodItem.isFavorite;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _updateQuantity(String value) {
    setState(() {
      _quantity = double.tryParse(value) ?? 100.0;
    });
  }

  void _toggleFavorite() {
    if (widget.foodItem.id != null) {
      setState(() {
        _isFavorite = !_isFavorite;
      });
      _viewModel.updateFood(widget.foodItem.copyWith(isFavorite: _isFavorite));
    }
  }

  void _addToMeal() {
    if (widget.mealRecordId != null && widget.foodItem.id != null) {
      _viewModel
          .addFoodToMeal(
            widget.mealRecordId!,
            widget.foodItem.id!,
            _quantity,
            '克',
          )
          .then((_) {
            // 添加成功后直接返回到餐次详情页，跳过食品搜索页
            if (!mounted) return;
            Navigator.of(context)
              ..pop
              ..pop();

            ToastUtils.showInfo('已添加${widget.foodItem.name}到餐次');
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.foodItem.name),
        actions: [
          if (widget.isEditable)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => FoodEditPage(
                          foodItem: widget.foodItem,
                          onSave: (updatedFood) {
                            _viewModel.updateFood(updatedFood).then((_) {
                              ToastUtils.showInfo('食品信息已更新');

                              if (!context.mounted) return;
                              Navigator.pop(context);
                            });
                          },
                        ),
                  ),
                );
              },
            ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 食品图片
                  if (widget.foodItem.imageUrl != null &&
                      widget.foodItem.imageUrl!.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: buildImageViewCarouselSlider([
                        widget.foodItem.imageUrl!,
                      ]),
                    )
                  else
                    Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(
                          Icons.restaurant,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                    ),

                  // 基本信息
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: baseInfo(),
                  ),
                ],
              ),
            ),
          ),
          if (widget.mealRecordId != null) inputBar(),
        ],
      ),
    );
  }

  // 基本信息
  Column baseInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 食品名称和卡路里
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.foodItem.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${widget.foodItem.caloriesPer100g.toInt()} 千卡/100克',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
            ),
          ],
        ),
        if (widget.foodItem.foodCode != null) ...[
          Text(
            '食品编码: ${widget.foodItem.foodCode}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],

        const SizedBox(height: 24),

        // 营养元素
        const Text(
          '营养元素',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // 三大营养素占比
        Row(
          children: [
            _buildNutrientPercentage(
              '碳水化合物',
              widget.foodItem.carbsPer100g,
              Colors.teal,
            ),
            _buildNutrientPercentage(
              '蛋白质',
              widget.foodItem.proteinPer100g,
              Colors.purple,
            ),
            _buildNutrientPercentage(
              '脂肪',
              widget.foodItem.fatPer100g,
              Colors.orange,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // 详细营养素表格
        nutrientElement(),
        const SizedBox(height: 24),

        // 单位重量
        // unitWeight(),

        // 配料
        if (widget.foodItem.otherParams['ingredients'] != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '配料',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text('${widget.foodItem.otherParams['ingredients']}'),
              ],
            ),
          ),
      ],
    );
  }

  // 营养元素
  Card nutrientElement() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '详细营养素 (每100克)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildNutrientRow(
              '热量',
              '${widget.foodItem.caloriesPer100g.toInt()} 千卡',
            ),
            _buildNutrientRow(
              '碳水化合物',
              '${widget.foodItem.carbsPer100g.toStringAsFixed(1)} 克',
            ),
            _buildNutrientRow(
              '蛋白质',
              '${widget.foodItem.proteinPer100g.toStringAsFixed(1)} 克',
            ),
            _buildNutrientRow(
              '脂肪',
              '${widget.foodItem.fatPer100g.toStringAsFixed(1)} 克',
            ),
            if (widget.foodItem.fiberPer100g != null)
              _buildNutrientRow(
                '膳食纤维',
                '${widget.foodItem.fiberPer100g!.toStringAsFixed(1)} 克',
              ),
            if (widget.foodItem.cholesterolPer100g != null)
              _buildNutrientRow(
                '胆固醇',
                '${widget.foodItem.cholesterolPer100g!.toStringAsFixed(1)} 毫克',
              ),
            if (widget.foodItem.sodiumPer100g != null)
              _buildNutrientRow(
                '钠',
                '${widget.foodItem.sodiumPer100g!.toStringAsFixed(1)} 毫克',
              ),
            if (widget.foodItem.calciumPer100g != null)
              _buildNutrientRow(
                '钙',
                '${widget.foodItem.calciumPer100g!.toStringAsFixed(1)} 毫克',
              ),
            if (widget.foodItem.ironPer100g != null)
              _buildNutrientRow(
                '铁',
                '${widget.foodItem.ironPer100g!.toStringAsFixed(1)} 毫克',
              ),
            if (widget.foodItem.vitaminAPer100g != null)
              _buildNutrientRow(
                '维生素A',
                '${widget.foodItem.vitaminAPer100g!.toStringAsFixed(1)} 微克',
              ),
            if (widget.foodItem.vitaminCPer100g != null)
              _buildNutrientRow(
                '维生素C',
                '${widget.foodItem.vitaminCPer100g!.toStringAsFixed(1)} 毫克',
              ),
            if (widget.foodItem.vitaminEPer100g != null)
              _buildNutrientRow(
                '维生素E',
                '${widget.foodItem.vitaminEPer100g!.toStringAsFixed(1)} 毫克',
              ),
          ],
        ),
      ),
    );
  }

  // 单位重量
  Card unitWeight() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '单位重量',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
              },
              children: [
                const TableRow(
                  children: [
                    Text('单位', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('重量', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('热量', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const TableRow(
                  children: [
                    SizedBox(height: 8),
                    SizedBox(height: 8),
                    SizedBox(height: 8),
                  ],
                ),
                TableRow(
                  children: [
                    const Text('杯'),
                    const Text('200 克'),
                    Text('${(widget.foodItem.caloriesPer100g * 2).toInt()} 千卡'),
                  ],
                ),
                const TableRow(
                  children: [
                    SizedBox(height: 8),
                    SizedBox(height: 8),
                    SizedBox(height: 8),
                  ],
                ),
                TableRow(
                  children: [
                    const Text('份'),
                    const Text('300 克'),
                    Text('${(widget.foodItem.caloriesPer100g * 3).toInt()} 千卡'),
                  ],
                ),
                const TableRow(
                  children: [
                    SizedBox(height: 8),
                    SizedBox(height: 8),
                    SizedBox(height: 8),
                  ],
                ),
                TableRow(
                  children: [
                    const Text('碗'),
                    const Text('300 克'),
                    Text('${(widget.foodItem.caloriesPer100g * 3).toInt()} 千卡'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 添加到餐次页面的输入栏
  Container inputBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '数量',
                suffixText: '克',
                border: OutlineInputBorder(),
              ),
              onChanged: _updateQuantity,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: ElevatedButton(
              onPressed: _addToMeal,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                '添加 (${(_quantity * widget.foodItem.caloriesPer100g / 100).toInt()} 千卡)',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientPercentage(String label, double value, Color color) {
    // 计算三大营养素的总和
    final total =
        widget.foodItem.carbsPer100g +
        widget.foodItem.proteinPer100g +
        widget.foodItem.fatPer100g;
    // 计算当前营养素占比
    final percentage = total > 0 ? (value / total * 100).toInt() : 0;

    return Expanded(
      child: Column(
        children: [
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.2),
            ),
            child: Center(
              child: Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            '${value.toStringAsFixed(1)}克',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
