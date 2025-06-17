import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/entities/cus_llm_model.dart';
import '../../../../core/utils/image_picker_utils.dart';
import '../../../../shared/constants/constant_llm_enum.dart';
import '../../../../shared/services/model_manager_service.dart';
import '../../../../shared/widgets/cus_dropdown_button.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../data/services/food_nutrition_recognition_service.dart';
import '../viewmodels/diet_diary_viewmodel.dart';
import 'food_edit_page.dart';

class FoodRecognitionPage extends StatefulWidget {
  const FoodRecognitionPage({super.key});

  @override
  State<FoodRecognitionPage> createState() => _FoodRecognitionPageState();
}

class _FoodRecognitionPageState extends State<FoodRecognitionPage> {
  // 大模型相关状态
  List<CusLLMSpec> modelList = [];
  CusLLMSpec? selectedModel;

  // 图片相关状态
  File? _selectedImage;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initModels();
  }

  Future<void> _initModels() async {
    // 获取支持视觉功能的模型列表
    final availableModels = await ModelManagerService.getAvailableModelByTypes([
      LLModelType.vision,
    ]);

    setState(() {
      modelList = availableModels;
      selectedModel = availableModels.isNotEmpty ? availableModels.first : null;
    });
  }

  // 从相册选择图片
  Future<void> _pickImage() async {
    final imageFile = await ImagePickerUtils.pickSingleImage(
      quality: 90,
      maxWidth: 1200,
    );

    if (imageFile != null) {
      setState(() {
        _selectedImage = imageFile;
        _errorMessage = null;
      });
    }
  }

  // 拍摄照片
  Future<void> _takePhoto() async {
    final imageFile = await ImagePickerUtils.takePhotoAndSave(
      quality: 90,
      maxWidth: 1200,
    );

    if (imageFile != null) {
      setState(() {
        _selectedImage = imageFile;
        _errorMessage = null;
      });
    }
  }

  // 识别营养成分表
  Future<void> _recognizeNutritionLabel() async {
    if (_selectedImage == null) {
      ToastUtils.showError('请先选择或拍摄食品营养成分表图片', align: Alignment.center);
      return;
    }

    if (selectedModel == null) {
      ToastUtils.showError('请先选择用于识别的视觉大模型', align: Alignment.center);
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final service = FoodNutritionRecognitionService();
      final foodItem = await service.recognizeNutritionLabel(
        imageFile: _selectedImage!,
        model: selectedModel!,
      );

      if (!mounted) return;

      // 识别成功，跳转到食品编辑页面
      if (foodItem != null) {
        // 获取ViewModel
        final viewModel = Provider.of<DietDiaryViewModel>(
          context,
          listen: false,
        );

        // 跳转到食品编辑页面，并传入识别结果
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => FoodEditPage(
                  foodItem: foodItem,
                  onSave: (newFoodItem) {
                    viewModel.addFood(newFoodItem).then((_) {
                      if (!context.mounted) return;
                      Navigator.pop(context); // 返回到食品管理页面
                    });
                  },
                ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = '未检测到食品营养成分表，请重试或手动输入';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '识别失败: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('识别食品营养成分表')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 说明卡片
            Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '使用说明',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. 选择支持视觉理解的大模型\n'
                      '2. 拍摄或选择食品包装上的营养成分表图片\n'
                      '3. 点击"识别营养成分表"按钮，等待识别结果\n'
                      '4. 识别完成后，在编辑页面修改或补充信息',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            // 选择大模型
            Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.smart_toy,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '选择视觉大模型',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    buildDropdownButton2<CusLLMSpec?>(
                      value: selectedModel,
                      items: modelList,
                      height: 56,
                      hintLabel: "选择支持视觉功能的模型",
                      alignment: Alignment.centerLeft,
                      onChanged:
                          (value) => setState(() => selectedModel = value!),
                      itemToString:
                          (e) =>
                              "${CP_NAME_MAP[(e as CusLLMSpec).platform]} - ${e.name}",
                    ),
                  ],
                ),
              ),
            ),

            // 图片选择区域
            Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.image,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '营养成分表图片',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 图片预览区域
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child:
                          _selectedImage != null
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.contain,
                                ),
                              )
                              : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '未选择图片',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                    ),

                    const SizedBox(height: 16),

                    // 图片选择按钮
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _takePhoto,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('拍照'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isProcessing ? null : _pickImage,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('从相册选择'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 错误信息
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red[900]),
                ),
              ),

            // 识别按钮
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed:
                    _isProcessing ||
                            _selectedImage == null ||
                            selectedModel == null
                        ? null
                        : _recognizeNutritionLabel,
                icon:
                    _isProcessing
                        ? Container(
                          width: 24,
                          height: 24,
                          padding: const EdgeInsets.all(2.0),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                        : const Icon(Icons.search),
                label: Text(_isProcessing ? '正在识别...' : '识别营养成分表'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
