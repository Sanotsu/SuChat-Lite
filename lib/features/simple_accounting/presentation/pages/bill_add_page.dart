import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/screen_helper.dart';
import '../../../../core/utils/simple_tools.dart';
import '../../../../shared/constants/constants.dart';
import '../../domain/entities/bill_item.dart';
import '../../domain/entities/bill_category.dart';
import '../viewmodels/bill_viewmodel.dart';
import '../widgets/category_icon.dart';

/// 添加账单页面
class BillAddPage extends StatefulWidget {
  final BillItem? editItem;

  const BillAddPage({super.key, this.editItem});

  @override
  State<BillAddPage> createState() => _BillAddPageState();
}

class _BillAddPageState extends State<BillAddPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _itemController = TextEditingController();
  final _remarkController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _selectedType = 1; // 默认为支出
  String _selectedCategory = '餐饮';

  BillCategory? _selectedCategoryObj;
  List<BillCategory> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // 如果是编辑模式，填充数据
    if (widget.editItem != null) {
      _selectedType = widget.editItem!.itemType;
      _selectedCategory = widget.editItem!.category;
      _amountController.text = widget.editItem!.value.toString();
      _itemController.text = widget.editItem!.item;
      _remarkController.text = widget.editItem!.remark ?? '';

      try {
        _selectedDate = DateTime.parse(widget.editItem!.date);
      } catch (e) {
        // 如果日期解析失败，使用当前日期时间
        _selectedDate = DateTime.now();
      }

      try {
        if (widget.editItem!.time != null) {
          _selectedTime = TimeOfDay(
            hour: int.parse(widget.editItem!.time!.split(':')[0]),
            minute: int.parse(widget.editItem!.time!.split(':')[1]),
          );
        }
      } catch (e) {
        // 如果时间解析失败，使用当前时间
        _selectedTime = TimeOfDay.now();
      }
    }

    // 加载分类数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _itemController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  // 加载分类数据
  Future<void> _loadCategories() async {
    final viewModel = Provider.of<BillViewModel>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedType == 0) {
        _categories = viewModel.incomeCategories;
      } else {
        _categories = viewModel.expenseCategories;
      }

      // 找到选中的分类对象
      _selectedCategoryObj = _categories.firstWhere(
        (c) => c.name == _selectedCategory,
        orElse:
            () =>
                _categories.isNotEmpty
                    ? _categories.first
                    : throw Exception('没有可用的分类'),
      );

      if (_selectedCategoryObj != null) {
        _selectedCategory = _selectedCategoryObj!.name;
      }
    } catch (e) {
      // 错误处理
      pl.e('加载分类出错: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 选择日期
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2016),
      lastDate: DateTime(DateTime.now().year + 1),
      locale: const Locale('zh', 'CN'),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  // 选择时间
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  // 保存账单
  Future<void> _saveBill() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final viewModel = Provider.of<BillViewModel>(context, listen: false);

    final amount = double.parse(_amountController.text);
    final item = _itemController.text.trim();
    final remark = _remarkController.text.trim();

    // 格式化日期
    final dateStr = DateFormat(formatToYMD).format(_selectedDate);
    final timeStr = _selectedTime.format(context);
    final now = DateTime.now();
    final gmtModified = DateFormat(formatToYMDHMS).format(now);

    final billItem = BillItem(
      billItemId: widget.editItem?.billItemId,
      category: _selectedCategory,
      date: dateStr,
      time: timeStr,
      gmtModified: gmtModified,
      item: item.isNotEmpty ? item : _selectedCategoryObj!.name,
      itemType: _selectedType,
      value: amount,
      remark: remark.isNotEmpty ? remark : null,
    );

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      if (widget.editItem != null) {
        success = await viewModel.updateBill(billItem);
      } else {
        success = await viewModel.addBill(billItem);
      }

      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      // 错误处理
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editItem != null ? '编辑账单' : '添加账单'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveBill,
            child: const Text('保存'),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 类型选择器
                      _buildTypeSelector(),

                      // 日期时间选择
                      _buildDateTimeSelector(),

                      // 金额输入
                      _buildAmountInput(),

                      // 分类选择器
                      _buildCategorySelector(),

                      // 账单名称输入
                      _buildItemInput(),

                      // 备注输入
                      _buildRemarkInput(),
                    ],
                  ),
                ),
              ),
    );
  }

  // 构建类型选择器
  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                color: _selectedType == 1 ? Colors.green : null,
              ),
              child: ElevatedButton(
                onPressed:
                    _selectedType == 1
                        ? null
                        : () {
                          setState(() => _selectedType = 1);
                          _loadCategories();
                        },

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_upward,
                      size: 18,
                      color: _selectedType == 1 ? Colors.white : null,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '支出',
                      style: TextStyle(
                        color: _selectedType == 1 ? Colors.white : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                color: _selectedType == 0 ? Colors.red : null,
              ),
              child: ElevatedButton(
                onPressed:
                    _selectedType == 0
                        ? null
                        : () {
                          setState(() => _selectedType = 0);
                          _loadCategories();
                        },

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_downward,
                      size: 18,
                      color: _selectedType == 0 ? Colors.white : null,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '收入',
                      style: TextStyle(
                        color: _selectedType == 0 ? Colors.white : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建金额输入
  Widget _buildAmountInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextFormField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: '0.00',
          hintStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              '¥',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                // 支出为绿色，收入为红色
                color: _selectedType == 0 ? Colors.red : Colors.green,
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '请输入金额';
          }
          try {
            final amount = double.parse(value);
            if (amount <= 0) {
              return '金额必须大于0';
            }
          } catch (e) {
            return '请输入有效金额';
          }
          return null;
        },
      ),
    );
  }

  // 构建分类选择器
  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(height: 16, color: Colors.grey[300]),
        ),

        Container(
          height:
              ScreenHelper.isDesktop() ? 130 : (_selectedType == 0 ? 110 : 220),
          padding: EdgeInsets.symmetric(
            horizontal: ScreenHelper.isDesktop() ? 16 : 0,
            vertical: 0,
          ),
          child:
              _categories.isEmpty
                  ? const Center(child: Text('暂无分类数据'))
                  : ScreenHelper.isDesktop()
                  ? Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children:
                        _categories.map((category) {
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedCategory = category.name;
                                _selectedCategoryObj = category;
                              });
                            },
                            child: CategoryIcon(
                              category: category,
                              size: 36,
                              showName: true,
                              selected: category.name == _selectedCategory,
                              showDefaultBgColor: false,
                              showDefaultIconColor: true,
                            ),
                          );
                        }).toList(),
                  )
                  : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6, // 每行显示5个
                          childAspectRatio: 1, // 保持正方形
                          crossAxisSpacing: 8, // 水平间距
                          mainAxisSpacing: 8, // 垂直间距
                        ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category.name == _selectedCategory;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category.name;
                            _selectedCategoryObj = category;
                          });
                        },
                        child: CategoryIcon(
                          category: category,
                          size: 30,
                          showName: true,
                          selected: isSelected,
                          showDefaultBgColor: false,
                          showDefaultIconColor: true,
                        ),
                      );
                    },
                  ),
        ),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(height: 10, color: Colors.grey[300]),
        ),
      ],
    );
  }

  // 构建日期时间选择器
  Widget _buildDateTimeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: '日期',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat(formatToYMD).format(_selectedDate)),
                    const Icon(Icons.calendar_today, size: 16),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: () => _selectTime(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: '时间',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_selectedTime.format(context)),
                    const Icon(Icons.access_time, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建账单名称输入
  Widget _buildItemInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextFormField(
        controller: _itemController,
        decoration: InputDecoration(
          labelText: '账单名称',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        // validator: (value) {
        //   if (value == null || value.isEmpty) {
        //     return '请输入账单名称';
        //   }
        //   return null;
        // },
      ),
    );
  }

  // 构建备注输入
  Widget _buildRemarkInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextFormField(
        controller: _remarkController,
        decoration: InputDecoration(
          labelText: '备注',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        maxLines: 3,
      ),
    );
  }
}
