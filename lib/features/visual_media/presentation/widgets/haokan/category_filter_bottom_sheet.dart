import 'package:flutter/material.dart';

import '../../../data/models/haokan/haokan_enums.dart';

// 好看漫画的分类筛选弹窗
class CategoryFilterBottomSheet extends StatefulWidget {
  final ComicCategory selectedCategory;
  final ComicEndStatus selectedEndStatus;
  final ComicFreeStatus selectedFreeStatus;
  final ComicSortType selectedSortType;
  final ValueChanged<ComicCategory> onCategoryChanged;
  final ValueChanged<ComicEndStatus> onEndStatusChanged;
  final ValueChanged<ComicFreeStatus> onFreeStatusChanged;
  final ValueChanged<ComicSortType> onSortTypeChanged;
  final VoidCallback onApply;
  final VoidCallback onReset;

  const CategoryFilterBottomSheet({
    super.key,
    required this.selectedCategory,
    required this.selectedEndStatus,
    required this.selectedFreeStatus,
    required this.selectedSortType,
    required this.onCategoryChanged,
    required this.onEndStatusChanged,
    required this.onFreeStatusChanged,
    required this.onSortTypeChanged,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<CategoryFilterBottomSheet> createState() =>
      _CategoryFilterBottomSheetState();
}

class _CategoryFilterBottomSheetState extends State<CategoryFilterBottomSheet> {
  late ComicCategory _tempCategory;
  late ComicEndStatus _tempEndStatus;
  late ComicFreeStatus _tempFreeStatus;
  late ComicSortType _tempSortType;

  @override
  void initState() {
    super.initState();
    // 初始化临时变量，用于在弹窗内管理状态
    _tempCategory = widget.selectedCategory;
    _tempEndStatus = widget.selectedEndStatus;
    _tempFreeStatus = widget.selectedFreeStatus;
    _tempSortType = widget.selectedSortType;
  }

  void _resetTempFilters() {
    setState(() {
      _tempCategory = ComicCategory.urban;
      _tempEndStatus = ComicEndStatus.all;
      _tempFreeStatus = ComicFreeStatus.all;
      _tempSortType = ComicSortType.latest;
    });
  }

  void _applyTempFilters() {
    widget.onCategoryChanged(_tempCategory);
    widget.onEndStatusChanged(_tempEndStatus);
    widget.onFreeStatusChanged(_tempFreeStatus);
    widget.onSortTypeChanged(_tempSortType);
    widget.onApply();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.pink[50],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '筛选条件',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // 筛选内容
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterSection('分类', _buildCategoryFilter()),
                  const SizedBox(height: 20),
                  _buildFilterSection('状态', _buildEndStatusFilter()),
                  const SizedBox(height: 20),
                  _buildFilterSection('付费', _buildFreeStatusFilter()),
                  const SizedBox(height: 20),
                  _buildFilterSection('排序', _buildSortTypeFilter()),
                ],
              ),
            ),
          ),
          // 底部按钮
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _resetTempFilters();
                      widget.onReset();
                    },
                    child: const Text('重置'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyTempFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink[400],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('应用'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ComicCategory.values.map((category) {
        final isSelected = _tempCategory == category;
        return GestureDetector(
          onTap: () {
            setState(() {
              _tempCategory = category;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.pink[400] : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              category.title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEndStatusFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ComicEndStatus.values.map((status) {
        final isSelected = _tempEndStatus == status;
        return GestureDetector(
          onTap: () {
            setState(() {
              _tempEndStatus = status;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[400] : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFreeStatusFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ComicFreeStatus.values.map((status) {
        final isSelected = _tempFreeStatus == status;
        return GestureDetector(
          onTap: () {
            setState(() {
              _tempFreeStatus = status;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.green[400] : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSortTypeFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ComicSortType.values.map((sort) {
        final isSelected = _tempSortType == sort;
        return GestureDetector(
          onTap: () {
            setState(() {
              _tempSortType = sort;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.orange[400] : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              sort.title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
