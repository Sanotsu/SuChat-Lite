import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/simple_tools.dart';
import '../../../../shared/constants/constants.dart';
import '../../domain/entities/bill_item.dart';
import '../../domain/entities/bill_category.dart';
import '../viewmodels/bill_viewmodel.dart';
import '../widgets/category_icon.dart';
import 'bill_add_page.dart';

/// 账单详情页面
class BillDetailPage extends StatefulWidget {
  final int billItemId;

  const BillDetailPage({super.key, required this.billItemId});

  @override
  State<BillDetailPage> createState() => _BillDetailPageState();
}

class _BillDetailPageState extends State<BillDetailPage> {
  bool _isLoading = true;
  BillItem? _billItem;
  BillCategory? _category;

  @override
  void initState() {
    super.initState();
    _loadBillDetail();
  }

  // 加载账单详情
  Future<void> _loadBillDetail() async {
    final viewModel = Provider.of<BillViewModel>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      _billItem = await viewModel.getBillDetail(widget.billItemId);

      if (_billItem != null) {
        // 获取分类对象
        final categories =
            _billItem!.itemType == 0
                ? viewModel.incomeCategories
                : viewModel.expenseCategories;

        _category = categories.firstWhere(
          (c) => c.name == _billItem!.category,
          orElse:
              () =>
                  categories.isNotEmpty
                      ? categories.first
                      : throw Exception('没有可用的分类'),
        );
      }
    } catch (e) {
      // 错误处理
      pl.e('加载账单详情出错: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 编辑账单
  Future<void> _editBill() async {
    if (_billItem == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BillAddPage(editItem: _billItem)),
    );

    if (result == true) {
      _loadBillDetail();
    }
  }

  // 删除账单
  Future<void> _deleteBill() async {
    if (_billItem == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('确认删除'),
            content: const Text('确定要删除这条账单记录吗？此操作不可撤销。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('删除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      final viewModel = Provider.of<BillViewModel>(context, listen: false);

      setState(() {
        _isLoading = true;
      });

      try {
        final success = await viewModel.deleteBill(_billItem!.billItemId!);

        if (success && mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        // 错误处理
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('账单详情'),
        actions: [
          if (_billItem != null) ...[
            IconButton(icon: const Icon(Icons.edit), onPressed: _editBill),
            IconButton(icon: const Icon(Icons.delete), onPressed: _deleteBill),
          ],
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _billItem == null
              ? const Center(child: Text('未找到账单信息'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const Divider(height: 32),
                    _buildDetailItem(
                      '分类',
                      _billItem!.category,
                      icon: _category,
                    ),
                    _buildDetailItem('账单名称', _billItem!.item),
                    _buildDetailItem(
                      '日期',
                      _formatDate(_billItem!.date) +
                          (_billItem!.time != null
                              ? ' ${_billItem!.time}'
                              : ''),
                    ),
                    _buildDetailItem(
                      '创建时间',
                      _formatDateTime(_billItem!.gmtModified),
                    ),
                    if (_billItem!.remark != null &&
                        _billItem!.remark!.isNotEmpty)
                      _buildDetailItem('备注', _billItem!.remark!),
                  ],
                ),
              ),
    );
  }

  // 构建头部
  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          // 收入为红色，支出为绿色
          Text(
            _billItem!.itemType == 0 ? '收入' : '支出',
            style: TextStyle(
              fontSize: 16,
              color: _billItem!.itemType == 0 ? Colors.red : Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '¥${_billItem!.value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: _billItem!.itemType == 0 ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  // 构建详情项
  Widget _buildDetailItem(String label, String value, {BillCategory? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          if (icon != null) ...[
            CategoryIcon(category: icon, size: 24, selected: true),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  // 格式化日期
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat(formatToYMDzh).format(date);
    } catch (e) {
      return dateStr;
    }
  }

  // 格式化日期时间
  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat(formatToYMDHMSzh).format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }
}
