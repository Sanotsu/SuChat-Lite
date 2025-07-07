import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/screen_helper.dart';
import '../../domain/entities/bill_category.dart';
import '../widgets/category_icon.dart';

/// 账单筛选组件
class BillFilterWidget extends StatefulWidget {
  /// 支出分类列表
  final List<BillCategory> expenseCategories;

  /// 收入分类列表
  final List<BillCategory> incomeCategories;

  /// 当前选中的分类
  final String? selectedCategory;

  /// 当前选中的类型：0-收入，1-支出，null-全部
  final int? selectedType;

  /// 当前设置的最小金额
  final double? minAmount;

  /// 当前设置的最大金额
  final double? maxAmount;

  /// 筛选回调
  final Function(
    String? category,
    int? type,
    double? minAmount,
    double? maxAmount,
  )
  onFilter;

  const BillFilterWidget({
    super.key,
    required this.expenseCategories,
    required this.incomeCategories,
    this.selectedCategory,
    this.selectedType,
    this.minAmount,
    this.maxAmount,
    required this.onFilter,
  });

  @override
  State<BillFilterWidget> createState() => _BillFilterWidgetState();
}

class _BillFilterWidgetState extends State<BillFilterWidget> {
  // 当前显示的选中分类名称
  String _getSelectedFilterName() {
    if (widget.selectedCategory != null) {
      return widget.selectedCategory!;
    } else if (widget.selectedType == 0) {
      return '收入';
    } else if (widget.selectedType == 1) {
      return '支出';
    } else {
      return '全部';
    }
  }

  // 当前显示的选中分类图标
  Widget _getSelectedFilterIcon() {
    if (widget.selectedCategory != null) {
      // 查找选中的分类
      final categories =
          widget.selectedType == 0
              ? widget.incomeCategories
              : widget.expenseCategories;

      final category = categories.firstWhere(
        (c) => c.name == widget.selectedCategory,
        orElse: () => BillCategory(name: '', icon: '', color: '', type: 0),
      );

      if (category.name.isNotEmpty) {
        return CategoryIcon(
          category: category,
          size: 24,
          showName: false,
          selected: true,
        );
      }
    }

    // 默认图标（收入红色，支出绿色）
    if (widget.selectedType == 0) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.red.withAlpha(200),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_downward, color: Colors.white, size: 14),
      );
    } else if (widget.selectedType == 1) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.green.withAlpha(200),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_upward, color: Colors.white, size: 14),
      );
    } else {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.blue.withAlpha(200),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.all_inclusive, color: Colors.white, size: 14),
      );
    }
  }

  // 显示筛选弹窗
  void _showFilterDialog() {
    if (ScreenHelper.isMobile()) {
      _showMobileFilterDialog();
    } else {
      _showDesktopFilterDialog();
    }
  }

  // 显示移动端全屏筛选弹窗
  void _showMobileFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder:
                (context, scrollController) => FilterDialogContent(
                  expenseCategories: widget.expenseCategories,
                  incomeCategories: widget.incomeCategories,
                  selectedCategory: widget.selectedCategory,
                  selectedType: widget.selectedType,
                  minAmount: widget.minAmount,
                  maxAmount: widget.maxAmount,
                  onFilter: widget.onFilter,
                  scrollController: scrollController,
                  isMobile: true,
                ),
          ),
    );
  }

  // 显示桌面端常规筛选弹窗
  void _showDesktopFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('筛选账单'),
            content: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              padding: const EdgeInsets.only(bottom: 32),
              child: FilterDialogContent(
                expenseCategories: widget.expenseCategories,
                incomeCategories: widget.incomeCategories,
                selectedCategory: widget.selectedCategory,
                selectedType: widget.selectedType,
                minAmount: widget.minAmount,
                maxAmount: widget.maxAmount,
                onFilter: widget.onFilter,
                isMobile: false,
              ),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          ),
    );
  }

  // 点击快速筛选按钮
  void _onQuickFilterTap(String? category, int? type) {
    widget.onFilter(category, type, widget.minAmount, widget.maxAmount);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        // border: Border(
        //   bottom: BorderSide(
        //     color: Theme.of(context).colorScheme.outline,
        //     width: 1,
        //   ),
        // ),
      ),
      child: Row(
        children: [
          // 当前选中的筛选条件
          Container(
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _getSelectedFilterIcon(),
                const SizedBox(width: 6),
                Text(
                  _getSelectedFilterName(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 16),

          // 快速筛选按钮
          _buildQuickFilterButton(
            label: '全部',
            isSelected:
                widget.selectedCategory == null && widget.selectedType == null,
            onTap: () => _onQuickFilterTap(null, null),
            color: Colors.blue,
          ),

          SizedBox(width: ScreenHelper.isMobile() ? 4 : 8),

          // 支出绿色，收入红色
          _buildQuickFilterButton(
            label: '支出',
            isSelected:
                widget.selectedCategory == null && widget.selectedType == 1,
            onTap: () => _onQuickFilterTap(null, 1),
            color: Colors.green,
          ),

          SizedBox(width: ScreenHelper.isMobile() ? 4 : 8),

          _buildQuickFilterButton(
            label: '收入',
            isSelected:
                widget.selectedCategory == null && widget.selectedType == 0,
            onTap: () => _onQuickFilterTap(null, 0),
            color: Colors.red,
          ),

          const Spacer(),

          // 筛选按钮
          Container(
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.filter_list),
                  if (widget.minAmount != null || widget.maxAmount != null)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: _showFilterDialog,
              tooltip: '更多筛选',
            ),
          ),
        ],
      ),
    );
  }

  // 构建快速筛选按钮
  Widget _buildQuickFilterButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.5),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// 筛选弹窗内容
class FilterDialogContent extends StatefulWidget {
  final List<BillCategory> expenseCategories;
  final List<BillCategory> incomeCategories;
  final String? selectedCategory;
  final int? selectedType;
  final double? minAmount;
  final double? maxAmount;
  final Function(
    String? category,
    int? type,
    double? minAmount,
    double? maxAmount,
  )
  onFilter;
  final ScrollController? scrollController;
  final bool isMobile;

  const FilterDialogContent({
    super.key,
    required this.expenseCategories,
    required this.incomeCategories,
    this.selectedCategory,
    this.selectedType,
    this.minAmount,
    this.maxAmount,
    required this.onFilter,
    this.scrollController,
    required this.isMobile,
  });

  @override
  State<FilterDialogContent> createState() => _FilterDialogContentState();
}

class _FilterDialogContentState extends State<FilterDialogContent> {
  late String? _selectedCategory;
  late int? _selectedType;
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    _selectedType = widget.selectedType;

    if (widget.minAmount != null) {
      _minAmountController.text = widget.minAmount.toString();
    }

    if (widget.maxAmount != null) {
      _maxAmountController.text = widget.maxAmount.toString();
    }
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  // 应用筛选
  void _applyFilter() {
    double? minAmount;
    double? maxAmount;

    if (_minAmountController.text.isNotEmpty) {
      minAmount = double.tryParse(_minAmountController.text);
    }

    if (_maxAmountController.text.isNotEmpty) {
      maxAmount = double.tryParse(_maxAmountController.text);
    }

    widget.onFilter(_selectedCategory, _selectedType, minAmount, maxAmount);
    Navigator.pop(context);
  }

  // 重置筛选
  void _resetFilter() {
    setState(() {
      _selectedCategory = null;
      _selectedType = null;
      _minAmountController.clear();
      _maxAmountController.clear();
    });
  }

  // 选择分类
  void _selectCategory(String category, int type) {
    setState(() {
      if (_selectedCategory == category && _selectedType == type) {
        // 取消选择
        _selectedCategory = null;
        _selectedType = null;
      } else {
        _selectedCategory = category;
        _selectedType = type;
      }
    });
  }

  // 选择类型
  void _selectType(int? type) {
    setState(() {
      if (_selectedType == type) {
        // 取消选择
        _selectedType = null;
        _selectedCategory = null;
      } else {
        _selectedType = type;
        _selectedCategory = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: widget.scrollController,
      shrinkWrap: true,
      padding: EdgeInsets.only(
        top: 16,
        bottom: widget.isMobile ? 16 : 0,
        left: widget.isMobile ? 16 : 0,
        right: widget.isMobile ? 16 : 0,
      ),
      children: [
        if (widget.isMobile) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '筛选账单',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
        ],

        // 类型筛选
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            '收支类型',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildTypeFilterChip(
              label: '全部',
              isSelected: _selectedType == null && _selectedCategory == null,
              onTap: () => _selectType(null),
              color: Colors.blue,
            ),
            // 支出为绿色，收入为红色
            _buildTypeFilterChip(
              label: '支出',
              isSelected: _selectedType == 1 && _selectedCategory == null,
              onTap: () => _selectType(1),
              color: Colors.green,
            ),
            _buildTypeFilterChip(
              label: '收入',
              isSelected: _selectedType == 0 && _selectedCategory == null,
              onTap: () => _selectType(0),
              color: Colors.red,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 金额范围筛选
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            '金额范围',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minAmountController,
                decoration: const InputDecoration(
                  labelText: '最小金额',
                  border: OutlineInputBorder(),
                  prefixText: '¥',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _maxAmountController,
                decoration: const InputDecoration(
                  labelText: '最大金额',
                  border: OutlineInputBorder(),
                  prefixText: '¥',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 支出分类
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            '支出分类',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              widget.expenseCategories.map((category) {
                final isSelected =
                    _selectedCategory == category.name && _selectedType == 1;
                return _buildCategoryFilterChip(
                  category: category,
                  isSelected: isSelected,
                  onTap: () => _selectCategory(category.name, 1),
                );
              }).toList(),
        ),

        const SizedBox(height: 16),

        // 收入分类
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            '收入分类',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              widget.incomeCategories.map((category) {
                final isSelected =
                    _selectedCategory == category.name && _selectedType == 0;
                return _buildCategoryFilterChip(
                  category: category,
                  isSelected: isSelected,
                  onTap: () => _selectCategory(category.name, 0),
                );
              }).toList(),
        ),

        const SizedBox(height: 16),

        const SizedBox(height: 24),

        // 按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: _resetFilter, child: const Text('重置')),
            const SizedBox(width: 16),
            ElevatedButton(onPressed: _applyFilter, child: const Text('确定')),
          ],
        ),
      ],
    );
  }

  // 构建类型筛选按钮
  Widget _buildTypeFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.5),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // 构建分类筛选按钮
  Widget _buildCategoryFilterChip({
    required BillCategory category,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    // return SizedBox(
    //   width: 48,
    //   height: 56,
    //   child: Padding(
    //     padding: const EdgeInsets.symmetric(horizontal: 4),
    //     child: InkWell(
    //       onTap: () => onTap,
    //       child: CategoryIcon(
    //         category: category,
    //         size: 32,
    //         showName: true,
    //         selected: isSelected,
    //       ),
    //     ),
    //   ),
    // );

    return SizedBox(
      width: 48,
      height: 56,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color:
                isSelected
                    ? Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : Colors.transparent,
            border: Border.all(
              color:
                  isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.withValues(alpha: 0.5),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: CategoryIcon(
              category: category,
              size: 24,
              selected: isSelected,
              showName: true,
            ),
          ),
        ),
      ),
    );
  }
}
