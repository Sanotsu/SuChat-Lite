import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../../../../core/utils/file_picker_utils.dart';
import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../domain/entities/food_item.dart';
import '../../data/food_item_dao.dart';
import '../widgets/food_search_bar.dart';
import '../widgets/food_list_view.dart';
import '../widgets/favorite_filter_button.dart';
import '../viewmodels/diet_diary_viewmodel.dart';
import 'food_detail_page.dart';
import 'food_edit_page.dart';
import 'food_recognition_page.dart';

class FoodManagementPage extends StatefulWidget {
  const FoodManagementPage({super.key});

  @override
  State<FoodManagementPage> createState() => _FoodManagementPageState();
}

class _FoodManagementPageState extends State<FoodManagementPage> {
  late DietDiaryViewModel _viewModel;
  final FoodItemDao _foodItemDao = FoodItemDao();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showOnlyFavorites = false;

  bool _isImporting = false;
  int _totalFoodCount = 0;

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<DietDiaryViewModel>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFoodItems();
      _loadFoodCount();
    });
  }

  Future<void> _loadFoodItems() async {
    _viewModel.reloadFoodItems();
  }

  Future<void> _loadFoodCount() async {
    final count = await _foodItemDao.count();
    setState(() {
      _totalFoodCount = count;
    });
  }

  void _navigateToAddFood({String? initialName}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FoodEditPage(
              initialName: initialName,
              onSave: (foodItem) {
                _viewModel.addFood(foodItem).then((_) {
                  _loadFoodItems();
                  _loadFoodCount();
                });
              },
            ),
      ),
    );
  }

  void _navigateToEditFood(FoodItem food) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FoodEditPage(
              foodItem: food,
              onSave: (foodItem) {
                _viewModel.updateFood(foodItem).then((_) {
                  _loadFoodItems();
                });
              },
            ),
      ),
    );
  }

  void _navigateToFoodDetail(FoodItem food) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodDetailPage(foodItem: food, isEditable: true),
      ),
    );
  }

  void _toggleFavorite(FoodItem food) {
    if (food.id != null) {
      final updatedFood = food.copyWith(isFavorite: !food.isFavorite);
      _viewModel.updateFood(updatedFood).then((_) {
        _loadFoodItems();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('食品管理'),
        actions: [
          FavoriteFilterButton(
            showOnlyFavorites: _showOnlyFavorites,
            onToggle: () {
              setState(() {
                _showOnlyFavorites = !_showOnlyFavorites;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: '导入食品数据',
            onPressed: _isImporting ? null : _importFoodData,
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt),
            tooltip: '识别食品营养成分表',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FoodRecognitionPage(),
                ),
              );
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
            hintText: '搜索食品名称或编码',
            onSearchChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _viewModel.searchFood(value);
            },
            onClearSearch: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
              _viewModel.searchFood('');
            },
          ),

          // 食品统计信息
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  '总计 $_totalFoodCount 种食品(只显示前200个)',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const Spacer(),
                // if (!_isImporting)
                //   TextButton(
                //     onPressed: () {
                //       _viewModel.clearAllFood().then((_) {
                //         _loadFoodItems();
                //         _loadFoodCount();
                //       });
                //     },
                //     child: const Text('清空'),
                //   ),
                if (_isImporting)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 食品列表
          Expanded(
            child: Consumer<DietDiaryViewModel>(
              builder: (context, viewModel, child) {
                return FoodListView(
                  viewModel: viewModel,
                  searchQuery: _searchQuery,
                  showOnlyFavorites: _showOnlyFavorites,
                  errorContext: 'food_management',
                  onFoodTap: _navigateToFoodDetail,
                  onFavoriteToggle: _toggleFavorite,
                  onFoodEdit: _navigateToEditFood,
                  onFoodDelete: _showDeleteConfirmation,
                  onAddNewFood:
                      (query) => _navigateToAddFood(initialName: query),
                  showManagementActions: true,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: buildFloatingActionButton(
        _navigateToAddFood,
        context,
        icon: Icons.add,
        tooltip: '添加食品',
      ),
    );
  }

  void _showDeleteConfirmation(FoodItem food) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('确认删除'),
            content: Text('确定要删除"${food.name}"吗？如果该食品已被使用，将无法删除。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    if (food.id != null) {
                      await _viewModel.deleteFood(food.id!);
                      _loadFoodItems();
                      _loadFoodCount();

                      ToastUtils.showInfo('食品已删除');
                    }
                  } catch (e) {
                    if (!context.mounted) return;
                    commonExceptionDialog(context, '删除失败', e.toString());
                  }
                },
                child: const Text('删除'),
              ),
            ],
          ),
    );
  }

  // 从文件导入食品数据
  Future<void> _importFoodData() async {
    try {
      List<File> result = await FilePickerUtils.pickAndSaveMultipleFiles(
        fileType: CusFileType.custom,
        allowedExtensions: ['json'],
        overwrite: true,
      );

      if (result.isEmpty) return;

      if (!mounted) return;
      setState(() {
        _isImporting = true;
      });

      var importedCount = 0;

      for (var file in result) {
        final jsonString = await file.readAsString();
        importedCount += await _foodItemDao.importFromCFCDJson(jsonString);
      }

      if (!mounted) return;
      setState(() {
        _isImporting = false;
      });

      _loadFoodItems();
      _loadFoodCount();

      ToastUtils.showInfo('成功导入 $importedCount 条食品数据');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isImporting = false;
      });

      commonExceptionDialog(context, '导入失败', e.toString());
    }
  }
}
