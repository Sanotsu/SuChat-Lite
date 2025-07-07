import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../../core/utils/image_picker_utils.dart';
import '../../../../shared/widgets/image_preview_helper.dart';
import '../../domain/entities/food_item.dart';

class FoodEditPage extends StatefulWidget {
  final FoodItem? foodItem; // 如果是编辑现有食品，则提供
  final String? initialName; // 如果是从搜索页面新建，则提供初始名称
  final Function(FoodItem) onSave; // 保存回调函数

  const FoodEditPage({
    super.key,
    this.foodItem,
    this.initialName,
    required this.onSave,
  });

  @override
  State<FoodEditPage> createState() => _FoodEditPageState();
}

class _FoodEditPageState extends State<FoodEditPage> {
  final _formKey = GlobalKey<FormBuilderState>();

  String? _imageUrl;
  File? _imageFile;
  bool _isFavorite = false;
  bool _isBasicInfoExpanded = true;
  bool _isMainNutrientsExpanded = true;
  bool _isAdditionalNutrientsExpanded = false;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.foodItem?.imageUrl;
    _isFavorite = widget.foodItem?.isFavorite ?? false;
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePickerUtils.pickSingleImage();

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _imageUrl = null; // 清除旧的URL，因为我们有了新的图片文件
      });
    }
  }

  Future<void> _takePhoto() async {
    final pickedFile = await ImagePickerUtils.takePhotoAndSave();

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _imageUrl = null; // 清除旧的URL，因为我们有了新的图片文件
      });
    }
  }

  void _saveFoodItem() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;

      // 获取表单数据
      final name = formData['name'] as String;
      final calories = double.tryParse(formData['calories'].toString()) ?? 0;
      final carbs = double.tryParse(formData['carbs'].toString()) ?? 0;
      final protein = double.tryParse(formData['protein'].toString()) ?? 0;
      final fat = double.tryParse(formData['fat'].toString()) ?? 0;
      final fiber = double.tryParse(formData['fiber']?.toString() ?? '');
      final cholesterol = double.tryParse(
        formData['cholesterol']?.toString() ?? '',
      );
      final sodium = double.tryParse(formData['sodium']?.toString() ?? '');
      final calcium = double.tryParse(formData['calcium']?.toString() ?? '');
      final iron = double.tryParse(formData['iron']?.toString() ?? '');
      final vitaminA = double.tryParse(formData['vitaminA']?.toString() ?? '');
      final vitaminC = double.tryParse(formData['vitaminC']?.toString() ?? '');
      final vitaminE = double.tryParse(formData['vitaminE']?.toString() ?? '');
      final foodCode =
          (formData['foodCode'] as String?)?.trim().isEmpty == true
              ? identityHashCode(formData['name']).toString()
              : formData['foodCode'] as String?;

      final ingredients = formData['ingredients'] as String?;

      // ???这里应该实现保存图片到存储（上传到图片服务器等）并获取URL的逻辑
      // 简化起见，直接使用本地路径
      String? newImageUrl = _imageUrl;

      if (_imageFile != null) {
        newImageUrl = _imageFile!.path;
      }

      // 创建或更新食品对象
      final foodItem =
          (widget.foodItem?.copyWith(
            name: name,
            imageUrl: newImageUrl,
            caloriesPer100g: calories,
            carbsPer100g: carbs,
            proteinPer100g: protein,
            fatPer100g: fat,
            fiberPer100g: fiber,
            cholesterolPer100g: cholesterol,
            sodiumPer100g: sodium,
            calciumPer100g: calcium,
            ironPer100g: iron,
            vitaminAPer100g: vitaminA,
            vitaminCPer100g: vitaminC,
            vitaminEPer100g: vitaminE,
            foodCode: foodCode,
            isFavorite: _isFavorite,
            otherParams:
                ingredients != null ? {'ingredients': ingredients} : null,
          )) ??
          FoodItem(
            name: name,
            imageUrl: newImageUrl,
            caloriesPer100g: calories,
            carbsPer100g: carbs,
            proteinPer100g: protein,
            fatPer100g: fat,
            fiberPer100g: fiber,
            cholesterolPer100g: cholesterol,
            sodiumPer100g: sodium,
            calciumPer100g: calcium,
            ironPer100g: iron,
            vitaminAPer100g: vitaminA,
            vitaminCPer100g: vitaminC,
            vitaminEPer100g: vitaminE,
            foodCode: foodCode,
            isFavorite: _isFavorite,
            otherParams:
                ingredients != null ? {'ingredients': ingredients} : null,
          );

      // 调用保存回调
      widget.onSave(foodItem);

      // 返回上一页
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.foodItem != null;

    // 准备初始值
    final initialValues = {
      'name': widget.foodItem?.name ?? widget.initialName ?? '',
      'calories': widget.foodItem?.caloriesPer100g.toString() ?? '',
      'carbs': widget.foodItem?.carbsPer100g.toString() ?? '',
      'protein': widget.foodItem?.proteinPer100g.toString() ?? '',
      'fat': widget.foodItem?.fatPer100g.toString() ?? '',
      'fiber': widget.foodItem?.fiberPer100g?.toString() ?? '',
      'cholesterol': widget.foodItem?.cholesterolPer100g?.toString() ?? '',
      'sodium': widget.foodItem?.sodiumPer100g?.toString() ?? '',
      'calcium': widget.foodItem?.calciumPer100g?.toString() ?? '',
      'iron': widget.foodItem?.ironPer100g?.toString() ?? '',
      'vitaminA': widget.foodItem?.vitaminAPer100g?.toString() ?? '',
      'vitaminC': widget.foodItem?.vitaminCPer100g?.toString() ?? '',
      'vitaminE': widget.foodItem?.vitaminEPer100g?.toString() ?? '',
      'foodCode': widget.foodItem?.foodCode ?? '',
      'ingredients': widget.foodItem?.otherParams['ingredients'] ?? '',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑食品' : '添加食品'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveFoodItem,
            tooltip: '保存',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FormBuilder(
            key: _formKey,
            initialValue: initialValues,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 食品图片
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        _imageFile != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(_imageFile!, fit: BoxFit.cover),
                            )
                            : (_imageUrl != null && _imageUrl!.isNotEmpty
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: buildImageViewCarouselSlider([
                                    _imageUrl!,
                                  ]),
                                )
                                : const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo,
                                        size: 64,
                                        color: Colors.white,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '点击添加图片',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                  ),
                ),

                const SizedBox(height: 16),

                // 图片操作按钮
                Row(
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
                      label: const Text('从相册选择'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 基本信息
                ExpansionPanelList(
                  elevation: 2,
                  expandedHeaderPadding: EdgeInsets.zero,
                  expansionCallback: (panelIndex, isExpanded) {
                    setState(() {
                      _isBasicInfoExpanded = !_isBasicInfoExpanded;
                    });
                  },
                  children: [
                    ExpansionPanel(
                      headerBuilder: (context, isExpanded) {
                        return const ListTile(
                          title: Text(
                            '基本信息',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          leading: Icon(Icons.info_outline),
                        );
                      },
                      body: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 食品名称
                            FormBuilderTextField(
                              name: 'name',
                              decoration: InputDecoration(
                                labelText: '食品名称 *',
                                hintText: '例如：苹果',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixIcon: const Icon(Icons.fastfood),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(
                                  errorText: '请输入食品名称',
                                ),
                              ]),
                            ),

                            const SizedBox(height: 16),

                            // 收藏状态
                            SwitchListTile(
                              title: const Text('收藏此食品'),
                              subtitle: Text(
                                _isFavorite ? '已收藏' : '未收藏',
                                style: TextStyle(
                                  color:
                                      _isFavorite
                                          ? Colors.red
                                          : Colors.grey[600],
                                ),
                              ),
                              value: _isFavorite,
                              activeColor: Colors.red,
                              onChanged: (value) {
                                setState(() {
                                  _isFavorite = value;
                                });
                              },
                              secondary: Icon(
                                _isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _isFavorite ? Colors.red : null,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // 食品编码
                            FormBuilderTextField(
                              name: 'foodCode',
                              decoration: InputDecoration(
                                labelText: '食品编码',
                                hintText: '选填',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixIcon: const Icon(Icons.qr_code),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            ),
                          ],
                        ),
                      ),
                      isExpanded: _isBasicInfoExpanded,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 主要营养素
                ExpansionPanelList(
                  elevation: 2,
                  expandedHeaderPadding: EdgeInsets.zero,
                  expansionCallback: (panelIndex, isExpanded) {
                    setState(() {
                      _isMainNutrientsExpanded = !_isMainNutrientsExpanded;
                    });
                  },
                  children: [
                    ExpansionPanel(
                      headerBuilder: (context, isExpanded) {
                        return const ListTile(
                          title: Text(
                            '主要营养素 (每100克)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          leading: Icon(Icons.pie_chart),
                        );
                      },
                      body: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 热量
                            _buildNutrientFormField(
                              name: 'calories',
                              label: '热量 (千卡) *',
                              hint: '例如：52',
                              icon: Icons.local_fire_department,
                              color: Colors.red,
                              isRequired: true,
                            ),

                            const SizedBox(height: 16),

                            // 碳水化合物
                            _buildNutrientFormField(
                              name: 'carbs',
                              label: '碳水化合物 (克) *',
                              hint: '例如：13.8',
                              icon: Icons.grain,
                              color: Colors.amber,
                              isRequired: true,
                            ),

                            const SizedBox(height: 16),

                            // 蛋白质
                            _buildNutrientFormField(
                              name: 'protein',
                              label: '蛋白质 (克) *',
                              hint: '例如：0.3',
                              icon: Icons.fitness_center,
                              color: Colors.blue,
                              isRequired: true,
                            ),

                            const SizedBox(height: 16),

                            // 脂肪
                            _buildNutrientFormField(
                              name: 'fat',
                              label: '脂肪 (克) *',
                              hint: '例如：0.2',
                              icon: Icons.opacity,
                              color: Colors.orange,
                              isRequired: true,
                            ),

                            const SizedBox(height: 16),

                            // 钠
                            _buildNutrientFormField(
                              name: 'sodium',
                              label: '钠 (毫克)',
                              hint: '选填',
                              icon: Icons.grain,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                      isExpanded: _isMainNutrientsExpanded,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 附加营养素
                ExpansionPanelList(
                  elevation: 2,
                  expandedHeaderPadding: EdgeInsets.zero,
                  expansionCallback: (panelIndex, isExpanded) {
                    setState(() {
                      _isAdditionalNutrientsExpanded =
                          !_isAdditionalNutrientsExpanded;
                    });
                  },
                  children: [
                    ExpansionPanel(
                      headerBuilder: (context, isExpanded) {
                        return ListTile(
                          title: const Text(
                            '附加营养素 (每100克)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '选填',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          leading: const Icon(Icons.science),
                        );
                      },
                      body: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 膳食纤维
                            _buildNutrientFormField(
                              name: 'fiber',
                              label: '膳食纤维 (克)',
                              hint: '选填',
                              icon: Icons.grass,
                              color: Colors.green,
                            ),

                            const SizedBox(height: 16),

                            // 胆固醇
                            _buildNutrientFormField(
                              name: 'cholesterol',
                              label: '胆固醇 (毫克)',
                              hint: '选填',
                              icon: Icons.water_drop,
                              color: Colors.purple,
                            ),

                            const SizedBox(height: 16),

                            // 钙
                            _buildNutrientFormField(
                              name: 'calcium',
                              label: '钙 (毫克)',
                              hint: '选填',
                              icon: Icons.grain,
                              color: Colors.blue,
                            ),

                            const SizedBox(height: 16),

                            // 铁
                            _buildNutrientFormField(
                              name: 'iron',
                              label: '铁 (毫克)',
                              hint: '选填',
                              icon: Icons.grain,
                              color: Colors.brown,
                            ),

                            const SizedBox(height: 16),

                            // 维生素A
                            _buildNutrientFormField(
                              name: 'vitaminA',
                              label: '维生素A (微克)',
                              hint: '选填',
                              icon: Icons.brightness_7,
                              color: Colors.orange,
                            ),

                            const SizedBox(height: 16),

                            // 维生素C
                            _buildNutrientFormField(
                              name: 'vitaminC',
                              label: '维生素C (毫克)',
                              hint: '选填',
                              icon: Icons.brightness_5,
                              color: Colors.yellow,
                            ),

                            const SizedBox(height: 16),

                            // 维生素E
                            _buildNutrientFormField(
                              name: 'vitaminE',
                              label: '维生素E (毫克)',
                              hint: '选填',
                              icon: Icons.brightness_6,
                              color: Colors.green,
                            ),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                      isExpanded: _isAdditionalNutrientsExpanded,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 配料
                FormBuilderTextField(
                  name: 'ingredients',
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: '配料',
                    hintText: '例如：全麦粉、水、酵母、食用盐',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),

                const SizedBox(height: 32),

                // 保存按钮
                ElevatedButton.icon(
                  onPressed: _saveFoodItem,
                  icon: const Icon(Icons.save),
                  label: const Text('保存食品信息'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientFormField({
    required String name,
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
    bool isRequired = false,
  }) {
    return FormBuilderTextField(
      name: name,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: Icon(icon, color: color),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator:
          isRequired
              ? FormBuilderValidators.compose([
                FormBuilderValidators.required(errorText: '请输入$label'),
                FormBuilderValidators.numeric(errorText: '请输入有效的数值'),
              ])
              : null,
    );
  }
}
