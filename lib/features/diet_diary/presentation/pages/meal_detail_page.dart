import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/image_picker_utils.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../domain/entities/meal_food_detail.dart';
import '../../domain/entities/meal_record.dart';
import '../../domain/entities/meal_type.dart';
import '../viewmodels/diet_diary_viewmodel.dart';
import 'food_search_page.dart';
import '../../../../shared/widgets/image_preview_helper.dart';

class MealDetailPage extends StatefulWidget {
  final MealRecord mealRecord;

  const MealDetailPage({super.key, required this.mealRecord});

  @override
  State<MealDetailPage> createState() => _MealDetailPageState();
}

class _MealDetailPageState extends State<MealDetailPage> {
  late DietDiaryViewModel _viewModel;
  late TextEditingController _descriptionController;
  List<String> _imageUrls = [];
  List<File> _imageFiles = [];
  bool _isEditing = false;
  late MealRecord _currentMealRecord;

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<DietDiaryViewModel>(context, listen: false);
    _currentMealRecord = widget.mealRecord;
    _descriptionController = TextEditingController(
      text: _currentMealRecord.description,
    );

    // 如果有多张图片，从 imageUrls 字段获取
    if (_currentMealRecord.imageUrls != null &&
        _currentMealRecord.imageUrls!.isNotEmpty) {
      _imageUrls = _currentMealRecord.imageUrls!;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
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

  Future<void> _pickImage() async {
    final pickedFile = await ImagePickerUtils.pickSingleImage();

    if (pickedFile != null) {
      setState(() {
        _imageFiles.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _takePhoto() async {
    final pickedFile = await ImagePickerUtils.takePhotoAndSave();

    if (pickedFile != null) {
      setState(() {
        _imageFiles.add(File(pickedFile.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (index < _imageUrls.length) {
        _imageUrls.removeAt(index);
      } else {
        _imageFiles.removeAt(index - _imageUrls.length);
      }
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _imageFiles = []; // 清空临时图片
      _imageUrls = []; // 重置图片URL列表

      // 恢复原始数据
      if (_currentMealRecord.imageUrls != null &&
          _currentMealRecord.imageUrls!.isNotEmpty) {
        _imageUrls = _currentMealRecord.imageUrls!;
      }

      _descriptionController.text = _currentMealRecord.description ?? '';
    });
  }

  Future<void> _saveMealRecord() async {
    // 保存新的图片文件并获取URL
    List<String> updatedImageUrls = List.from(_imageUrls);

    // 添加新上传的图片路径
    for (var file in _imageFiles) {
      // 这里应该实现上传图片的逻辑
      // 简化起见，我们假设直接使用本地路径
      updatedImageUrls.add(file.path);
    }

    final updatedMealRecord = _currentMealRecord.copyWith(
      description: _descriptionController.text.trim(),
      imageUrls: updatedImageUrls.isNotEmpty ? updatedImageUrls : null,
    );

    await _viewModel.updateMealRecord(updatedMealRecord);

    if (mounted) {
      setState(() {
        _isEditing = false;
        _imageUrls = updatedImageUrls;
        _imageFiles = [];
        _currentMealRecord = updatedMealRecord; // 更新当前餐次记录
      });

      ToastUtils.showInfo('餐次信息已保存');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_getMealTypeName(_currentMealRecord.mealType)}详情'),
        actions: [
          if (_isEditing) ...[
            // 取消按钮
            TextButton.icon(
              onPressed: _cancelEditing,
              icon: const Icon(Icons.close),
              label: const Text('取消'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
            // 保存按钮
            TextButton.icon(
              onPressed: _saveMealRecord,
              icon: const Icon(Icons.save),
              label: const Text('保存'),
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 餐次图片轮播
            _buildImageCarousel(),

            // 图片操作按钮
            if (_isEditing)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('拍照'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('选择图片'),
                    ),
                  ],
                ),
              ),

            // 餐次说明
            Padding(
              padding: const EdgeInsets.all(16.0),
              child:
                  _isEditing
                      ? TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: '餐次说明',
                          hintText: '添加关于这顿饭的说明...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '餐次说明',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentMealRecord.description?.isNotEmpty == true
                                ? _currentMealRecord.description!
                                : '暂无说明',
                            style: TextStyle(
                              color:
                                  _currentMealRecord.description?.isNotEmpty ==
                                          true
                                      ? Colors.black
                                      : Colors.grey,
                            ),
                          ),
                        ],
                      ),
            ),

            // 营养摘要
            Consumer<DietDiaryViewModel>(
              builder: (context, viewModel, child) {
                final nutrition =
                    viewModel.mealNutrition[_currentMealRecord.id!] ?? {};

                return Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '营养摘要',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildNutrientInfo(
                              '热量',
                              nutrition['calories']?.toInt() ?? 0,
                              '千卡',
                              Colors.red,
                            ),
                            _buildNutrientInfo(
                              '碳水',
                              nutrition['carbs']?.toInt() ?? 0,
                              '克',
                              Colors.teal,
                            ),
                            _buildNutrientInfo(
                              '蛋白质',
                              nutrition['protein']?.toInt() ?? 0,
                              '克',
                              Colors.purple,
                            ),
                            _buildNutrientInfo(
                              '脂肪',
                              nutrition['fat']?.toInt() ?? 0,
                              '克',
                              Colors.orange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // 食品列表
            Consumer<DietDiaryViewModel>(
              builder: (context, viewModel, child) {
                final foodDetails =
                    viewModel.mealFoodDetails[_currentMealRecord.id!] ?? [];

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '食品列表',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => FoodSearchPage(
                                        mealRecordId: _currentMealRecord.id!,
                                        mealType: _currentMealRecord.mealType,
                                      ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('添加食品'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      foodDetails.isEmpty
                          ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.no_food,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '暂无食品记录',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: foodDetails.length,
                            itemBuilder: (context, index) {
                              final food = foodDetails[index];
                              return Dismissible(
                                key: Key('food_${food.id}'),
                                direction: DismissDirection.horizontal,
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 16.0),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                secondaryBackground: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 16.0),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  return await showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('删除食品'),
                                        content: Text(
                                          '确定要删除"${food.foodName}"吗？',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(false),
                                            child: const Text('取消'),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(true),
                                            child: const Text('删除'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                onDismissed: (direction) {
                                  viewModel.removeFoodFromMeal(
                                    food.id,
                                    _currentMealRecord.id!,
                                  );

                                  ToastUtils.showInfo('已删除"${food.foodName}"');
                                },
                                child: Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        title: Text(food.foodName),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${food.quantity} ${food.unit ?? "克"}',
                                            ),
                                          ],
                                        ),
                                        trailing: Text(
                                          '${food.calories.toInt()} 千卡',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        onTap: () => _showFoodDetails(food),
                                      ),
                                      Row(
                                        children: [
                                          _buildNutrientTag(
                                            '碳水',
                                            '${food.carbs.toInt()}克',
                                            Colors.amber,
                                          ),
                                          const SizedBox(width: 8),
                                          _buildNutrientTag(
                                            '蛋白质',
                                            '${food.protein.toInt()}克',
                                            Colors.blue,
                                          ),
                                          const SizedBox(width: 8),
                                          _buildNutrientTag(
                                            '脂肪',
                                            '${food.fat.toInt()}克',
                                            Colors.red,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    final List<String> allImages = [..._imageUrls];

    // 添加本地图片文件
    for (var file in _imageFiles) {
      allImages.add(file.path);
    }

    if (allImages.isEmpty) {
      return GestureDetector(
        onTap: _isEditing ? _pickImage : null,
        child: Container(
          height: 200,
          color: Colors.grey[300],
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image, size: 64, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  '暂无图片',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isEditing) {
      // 编辑模式下显示可删除的图片列表
      return SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: allImages.length,
          itemBuilder: (context, index) {
            return Stack(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: buildNetworkOrFileImage(
                    allImages[index],
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    } else {
      // 查看模式下显示轮播图
      return SizedBox(
        height: 200,
        child: buildImageViewCarouselSlider(allImages),
      );
    }
  }

  Widget _buildNutrientInfo(String label, int value, String unit, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('$label ($unit)', style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildNutrientTag(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8)),
      ),
    );
  }

  void _showFoodDetails(MealFoodDetail food) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(food.foodName),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('数量: ${food.quantity} ${food.unit ?? "克"}'),
                const SizedBox(height: 8),
                Text('热量: ${food.calories.toInt()} 千卡'),
                const SizedBox(height: 4),
                Text('碳水化合物: ${food.carbs.toInt()} 克'),
                const SizedBox(height: 4),
                Text('蛋白质: ${food.protein.toInt()} 克'),
                const SizedBox(height: 4),
                Text('脂肪: ${food.fat.toInt()} 克'),
                if (food.fiber != null) ...[
                  const SizedBox(height: 4),
                  Text('膳食纤维: ${food.fiber!.toInt()} 克'),
                ],
                if (food.cholesterol != null) ...[
                  const SizedBox(height: 4),
                  Text('胆固醇: ${food.cholesterol!.toInt()} 毫克'),
                ],
                if (food.sodium != null) ...[
                  const SizedBox(height: 4),
                  Text('钠: ${food.sodium!.toInt()} 毫克'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();

                  // 显示数量编辑对话框
                  final TextEditingController quantityController =
                      TextEditingController(text: food.quantity.toString());

                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text('修改${food.foodName}数量'),
                            content: TextField(
                              controller: quantityController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: '数量',
                                suffixText: food.unit ?? '克',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final newQuantity = double.tryParse(
                                    quantityController.text,
                                  );
                                  if (newQuantity != null && newQuantity > 0) {
                                    // 删除原记录
                                    await _viewModel.removeFoodFromMeal(
                                      food.id,
                                      _currentMealRecord.id!,
                                    );
                                    // 添加新记录
                                    await _viewModel.addFoodToMeal(
                                      _currentMealRecord.id!,
                                      food.foodItemId,
                                      newQuantity,
                                      food.unit,
                                    );

                                    ToastUtils.showInfo(
                                      '已更新"${food.foodName}"的数量',
                                    );

                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  } else {
                                    ToastUtils.showError('请输入有效的数量');
                                  }
                                },
                                child: const Text('保存'),
                              ),
                            ],
                          ),
                    );
                  }
                },
                child: const Text('修改数量'),
              ),
            ],
          ),
    );
  }
}
