import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

import '../../../../shared/constants/constants.dart';
import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../domain/entities/bill_item.dart';
import '../../domain/entities/bill_statistics.dart';
import '../viewmodels/bill_viewmodel.dart';
import '../widgets/bill_item_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/bill_filter_widget.dart';
import 'bill_add_page.dart';
import 'bill_detail_page.dart';
import 'bill_statistics_page.dart';

/// 账单列表页面
class BillListPage extends StatefulWidget {
  const BillListPage({super.key});

  @override
  State<BillListPage> createState() => _BillListPageState();
}

class _BillListPageState extends State<BillListPage> {
  bool _isSearchMode = false;
  String _searchKeyword = '';
  List<BillItem> _searchResults = [];
  bool _isSearching = false;
  bool _isProcessing = false;
  bool _isLoadingMore = false;
  bool _isLoadingNewer = false;

  // 分类筛选相关
  String? _selectedCategoryFilter;
  int? _selectedTypeFilter; // 0-收入, 1-支出, null-全部
  double? _minAmountFilter;
  double? _maxAmountFilter;

  // 滚动控制器
  final ScrollController _scrollController = ScrollController();

  // 账单条目Key Map
  final Map<String, GlobalKey> _billItemKeys = {};

  // 防抖定时器
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();

    // 初始化视图模型
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<BillViewModel>(context, listen: false);
      viewModel.initialize();

      // 添加滚动监听
      _scrollController.addListener(_scrollListener);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _billItemKeys.clear();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // 滚动监听
  void _scrollListener() {
    if (_isSearchMode) return;

    final viewModel = Provider.of<BillViewModel>(context, listen: false);

    // 向上滚动到顶部，加载更新的月份数据
    if (_scrollController.position.pixels <= 0 && !_isLoadingNewer) {
      _loadNewerMonthData(viewModel);
    }

    // 向下滚动到底部，加载更早的月份数据
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 50 &&
        !_isLoadingMore) {
      _loadMoreMonthData(viewModel);
    }

    // 检测当前可见的月份
    // 使用防抖，避免频繁触发
    _debounceVisibleMonthUpdate(viewModel);
  }

  // 防抖处理可见月份更新
  void _debounceVisibleMonthUpdate(BillViewModel viewModel) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        _updateVisibleMonth(viewModel);
      }
    });
  }

  // 更新当前可见的月份
  void _updateVisibleMonth(BillViewModel viewModel) async {
    if (_billItemKeys.isEmpty) return;

    String? visibleDate;
    double minVisibleTop = double.infinity;

    // 遍历所有账单条目，找出在视窗顶部最靠前的那个
    for (var entry in _billItemKeys.entries) {
      final key = entry.value;
      final context = key.currentContext;
      if (context == null) continue;

      final RenderBox box = context.findRenderObject() as RenderBox;
      final position = box.localToGlobal(Offset.zero);

      // 如果条目在视窗内且是最靠近顶部的
      if (position.dy >= 0 && position.dy < minVisibleTop) {
        minVisibleTop = position.dy;
        visibleDate = entry.key;
      }
    }

    // 如果找到了可见的账单条目，更新选中的月份
    if (visibleDate != null) {
      final monthKey = visibleDate.substring(0, 7); // 获取年月部分，如 "2025-06"
      final yearMonth = monthKey.split('-');
      final year = int.parse(yearMonth[0]);
      final month = int.parse(yearMonth[1]);

      if (year != viewModel.selectedYear || month != viewModel.selectedMonth) {
        // 更新选中的年月，但不重新加载数据
        viewModel.updateSelectedMonth(year, month);

        // 更新统计数据，但不重新加载账单列表数据
        await viewModel.updateMonthlyStatistics(
          year,
          month,
          _selectedTypeFilter,
          _selectedCategoryFilter,
          minAmount: _minAmountFilter,
          maxAmount: _maxAmountFilter,
        );
      }
    }
  }

  // 加载更早的月份数据
  Future<void> _loadMoreMonthData(BillViewModel viewModel) async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await viewModel.loadPreviousMonthData(
        _selectedTypeFilter,
        _selectedCategoryFilter,
        minAmount: _minAmountFilter,
        maxAmount: _maxAmountFilter,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  // 加载更新的月份数据
  Future<void> _loadNewerMonthData(BillViewModel viewModel) async {
    if (_isLoadingNewer) return;

    setState(() {
      _isLoadingNewer = true;
    });

    try {
      await viewModel.loadNextMonthData(
        _selectedTypeFilter,
        _selectedCategoryFilter,
        minAmount: _minAmountFilter,
        maxAmount: _maxAmountFilter,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingNewer = false;
        });
      }
    }
  }

  // 搜索账单
  Future<void> _searchBills(String keyword) async {
    if (keyword.isEmpty) {
      setState(() {
        _isSearchMode = false;
        _searchKeyword = '';
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearchMode = true;
      _searchKeyword = keyword;
      _isSearching = true;
    });

    try {
      final viewModel = Provider.of<BillViewModel>(context, listen: false);
      final results = await viewModel.searchBills(
        keyword,
        type: _selectedTypeFilter,
        category: _selectedCategoryFilter,
        minAmount: _minAmountFilter,
        maxAmount: _maxAmountFilter,
      );

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  // 清除搜索
  void _clearSearch() {
    setState(() {
      _isSearchMode = false;
      _searchKeyword = '';
      _searchResults = [];
    });
  }

  // 选择月份
  Future<void> _selectMonth(
    BuildContext context,
    BillViewModel viewModel,
  ) async {
    final DateTime? picked = await showMonthPicker(
      context: context,
      initialDate: DateTime(viewModel.selectedYear, viewModel.selectedMonth),
      firstDate: DateTime(2016),
      lastDate: DateTime(DateTime.now().year + 1),
    );

    if (picked != null) {
      await viewModel.loadMonthlyData(
        picked.year,
        picked.month,
        _selectedTypeFilter,
        _selectedCategoryFilter,
        minAmount: _minAmountFilter,
        maxAmount: _maxAmountFilter,
      );
    }
  }

  // 添加账单
  Future<void> _addBill() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BillAddPage()),
    );

    if (result == true && mounted) {
      if (_isSearchMode) {
        _searchBills(_searchKeyword);
      } else {
        // 刷新当前月份数据
        final viewModel = Provider.of<BillViewModel>(context, listen: false);
        await viewModel.refreshCurrentMonthData(
          _selectedTypeFilter,
          _selectedCategoryFilter,
          minAmount: _minAmountFilter,
          maxAmount: _maxAmountFilter,
        );
      }
    }
  }

  // 查看账单详情
  Future<void> _viewBillDetail(int billItemId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillDetailPage(billItemId: billItemId),
      ),
    );

    if (result == true && mounted) {
      if (_isSearchMode) {
        _searchBills(_searchKeyword);
      } else {
        // 刷新当前月份数据
        final viewModel = Provider.of<BillViewModel>(context, listen: false);
        await viewModel.refreshCurrentMonthData(
          _selectedTypeFilter,
          _selectedCategoryFilter,
          minAmount: _minAmountFilter,
          maxAmount: _maxAmountFilter,
        );
      }
    }
  }

  // 查看统计页面
  void _viewStatistics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BillStatisticsPage()),
    ).then((value) {
      // 从统计页面返回后，重新初始化视图模型
      // （因为汇总操作没有加载账单列表，可能导致点击了汇总按钮后返回账单列表页面时，账单列表数据为空）
      if (!mounted) return;
      final viewModel = Provider.of<BillViewModel>(context, listen: false);
      viewModel.initialize();
    });
  }

  // 导出账单数据
  Future<void> _exportBills() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });

    try {
      final viewModel = Provider.of<BillViewModel>(context, listen: false);
      final jsonData = await viewModel.exportToJson();

      if (jsonData.isEmpty) {
        _showMessage('导出失败：没有账单数据');
        return;
      }

      // 让用户选择保存位置
      final fileName =
          '极简记账数据_${DateFormat(formatToYMD).format(DateTime.now())}.json';

      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      // 如果有选中文件夹，执行导出数据库的json文件，并添加到压缩档。
      if (selectedDirectory != null) {
        // 写入文件
        final file = File("$selectedDirectory/$fileName");
        await file.writeAsString(jsonData);

        ToastUtils.showSuccess("已经保存到$selectedDirectory");
      } else {
        debugPrint('保存操作已取消');
        return;
      }
    } catch (e) {
      _showMessage('导出失败：$e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // 导入账单数据
  Future<void> _importBills() async {
    try {
      // 选择文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      setState(() {
        _isProcessing = true;
      });

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      // 检查JSON格式
      try {
        json.decode(jsonString);
      } catch (e) {
        _showMessage('导入失败：无效的JSON格式');
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // 确认导入
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('确认导入'),
              content: const Text('导入将会添加新的账单数据，确定要继续吗？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('确定'),
                ),
              ],
            ),
      );

      if (confirmed != true) {
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // 执行导入
      if (!mounted) return;
      final viewModel = Provider.of<BillViewModel>(context, listen: false);
      final count = await viewModel.importFromJson(jsonString);

      _showMessage('成功导入 $count 条账单');

      // 刷新当前数据
      await viewModel.refreshCurrentMonthData(
        _selectedTypeFilter,
        _selectedCategoryFilter,
        minAmount: _minAmountFilter,
        maxAmount: _maxAmountFilter,
      );
    } catch (e) {
      _showMessage('导入失败：$e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // 显示消息
  void _showMessage(String message) {
    if (!mounted) return;
    ToastUtils.showInfo(message);
  }

  // 应用筛选
  void _applyFilter(
    String? category,
    int? type,
    double? minAmount,
    double? maxAmount,
  ) async {
    setState(() {
      _selectedCategoryFilter = category;
      _selectedTypeFilter = type;
      _minAmountFilter = minAmount;
      _maxAmountFilter = maxAmount;
    });

    // 加载筛选后的数据
    final viewModel = Provider.of<BillViewModel>(context, listen: false);

    if (_isSearchMode && _searchKeyword.isNotEmpty) {
      // 如果在搜索模式下，重新执行搜索
      _searchBills(_searchKeyword);
    } else {
      // 否则加载筛选后的数据
      await viewModel.loadFilteredData(
        _selectedTypeFilter,
        _selectedCategoryFilter,
        minAmount: _minAmountFilter,
        maxAmount: _maxAmountFilter,
      );
    }
  }

  // 构建按月和日期分组的账单列表
  List<Widget> _buildGroupedBillList(
    List<BillItem> bills,
    BillViewModel viewModel,
  ) {
    final List<Widget> widgets = [];

    if (bills.isEmpty) {
      // 空数据时显示提示，并保持足够的空间以便触发加载
      widgets.addAll([
        const SizedBox(height: 200),
        const Center(child: Text('当前月份暂无账单数据')),
        const SizedBox(height: 200),
      ]);
    } else {
      // 清除旧的账单条目Key
      _billItemKeys.clear();

      // 按月分组
      final Map<String, List<BillItem>> groupedByMonth = {};
      final Map<String, BillStatistics> monthlyStatistics = {};

      // 首先按月份分组
      for (var bill in bills) {
        final monthKey = bill.date.substring(0, 7); // 获取年月部分，如 "2025-06"
        if (!groupedByMonth.containsKey(monthKey)) {
          groupedByMonth[monthKey] = [];
        }
        groupedByMonth[monthKey]!.add(bill);

        // 为每个账单条目创建一个Key
        _billItemKeys[bill.date] = GlobalKey();
      }

      // 计算每个月的统计数据
      for (var entry in groupedByMonth.entries) {
        double totalIncome = 0;
        double totalExpense = 0;

        for (var bill in entry.value) {
          if (bill.itemType == 0) {
            totalIncome += bill.value;
          } else {
            totalExpense += bill.value;
          }
        }

        monthlyStatistics[entry.key] = BillStatistics(
          totalIncome: totalIncome,
          totalExpense: totalExpense,
          netIncome: totalIncome - totalExpense,
          expenseByCategory: {},
          incomeByCategory: {},
          expenseByDate: {},
          incomeByDate: {},
        );
      }

      // 按月份排序（降序）
      final sortedMonths =
          groupedByMonth.keys.toList()..sort((a, b) => b.compareTo(a));

      // 构建列表
      for (var month in sortedMonths) {
        final monthBills = groupedByMonth[month]!;
        final stats = monthlyStatistics[month]!;

        // 添加月度统计卡片
        final yearMonth = month.split('-');
        final year = int.parse(yearMonth[0]);
        final monthNum = int.parse(yearMonth[1]);

        widgets.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$year年${monthNum.toString().padLeft(2, '0')}月',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Spacer(),
                    Wrap(
                      children: [
                        Text(
                          '${stats.totalExpense > 0 ? '出 ¥${stats.totalExpense.toStringAsFixed(1)}' : ''}'
                          '${stats.totalExpense > 0 && stats.totalIncome > 0 ? ' / ' : ''}'
                          '${stats.totalIncome > 0 ? '入 ¥${stats.totalIncome.toStringAsFixed(1)}' : ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

        // 按日期分组当月账单
        final Map<String, List<BillItem>> groupedByDay = {};
        final Map<String, Map<int, double>> dailyTotals = {};

        for (var bill in monthBills) {
          final date = bill.date;

          if (!groupedByDay.containsKey(date)) {
            groupedByDay[date] = [];
            dailyTotals[date] = {0: 0.0, 1: 0.0}; // 0: 收入, 1: 支出
          }

          groupedByDay[date]!.add(bill);
          dailyTotals[date]![bill.itemType] =
              dailyTotals[date]![bill.itemType]! + bill.value;
        }

        // 按日期排序（降序）
        final sortedDates =
            groupedByDay.keys.toList()..sort((a, b) => b.compareTo(a));

        // 添加每日账单
        for (var date in sortedDates) {
          final income = dailyTotals[date]![0]!;
          final expense = dailyTotals[date]![1]!;

          // 创建日期头部
          widgets.add(
            Container(
              key: _billItemKeys[date], // 添加Key
              child: BillItemCard(
                billItem: BillItem(
                  category: '',
                  date: date,
                  gmtModified: '',
                  item: '',
                  itemType: expense > 0 ? 1 : 0,
                  value: expense > 0 ? expense : income,
                ),
                isDateHeader: true,
              ),
            ),
          );

          // 添加该日期下的所有账单
          final dateItems = groupedByDay[date]!;
          for (var item in dateItems) {
            final category = viewModel.getCategoryByName(
              item.category,
              item.itemType,
            );
            widgets.add(
              BillItemCard(
                billItem: item,
                category: category,
                onTap: () => _viewBillDetail(item.billItemId!),
              ),
            );
          }
        }
      }

      // 如果数据量太少，添加底部空间以便触发加载
      if (bills.length < 15) {
        widgets.add(
          SizedBox(
            height: max(
              MediaQuery.of(context).size.height - 42 * bills.length,
              100,
            ),
          ),
        );
      }
    }

    return widgets;
  }

  // 构建月份选择器和统计信息
  Widget _buildMonthSelector(BillViewModel viewModel) {
    final stats = viewModel.currentStatistics;
    final hasStats = stats != null;
    final showIncome =
        hasStats && (stats.totalIncome > 0 || _selectedTypeFilter == 0);
    final showExpense =
        hasStats && (stats.totalExpense > 0 || _selectedTypeFilter == 1);

    return Row(
      children: [
        GestureDetector(
          onTap: () => _selectMonth(context, viewModel),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  viewModel.getFormattedMonth(
                    viewModel.selectedYear,
                    viewModel.selectedMonth,
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
        ),
        if (hasStats) ...[
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              children: [
                Text(
                  '${_selectedCategoryFilter ?? ""}'
                  '${showExpense ? '总支出 ¥${stats.totalExpense.toStringAsFixed(2)}' : ''}'
                  '${showExpense && showIncome ? ' / ' : ''}'
                  '${showIncome ? '总收入 ¥${stats.totalIncome.toStringAsFixed(2)}' : ''}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BillViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading || _isProcessing) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (viewModel.error != null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('加载失败: ${viewModel.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => viewModel.initialize(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('极简记账'),
            actions: [
              IconButton(
                icon: const Icon(Icons.bar_chart),
                onPressed: _viewStatistics,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'import') {
                    await _importBills();
                  } else if (value == 'export') {
                    await _exportBills();
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem<String>(
                        value: 'import',
                        child: Row(
                          children: [
                            Icon(Icons.upload_file),
                            SizedBox(width: 8),
                            Text('导入账单'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(Icons.download),
                            SizedBox(width: 8),
                            Text('导出账单'),
                          ],
                        ),
                      ),
                    ],
              ),
            ],
          ),
          body: Column(
            children: [
              // 搜索栏
              SearchBarWidget(onSearch: _searchBills, onClear: _clearSearch),

              // 分类筛选和月份选择器
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // 新的筛选组件
                    BillFilterWidget(
                      expenseCategories: viewModel.expenseCategories,
                      incomeCategories: viewModel.incomeCategories,
                      selectedCategory: _selectedCategoryFilter,
                      selectedType: _selectedTypeFilter,
                      minAmount: _minAmountFilter,
                      maxAmount: _maxAmountFilter,
                      onFilter: _applyFilter,
                    ),

                    const SizedBox(height: 8),

                    // 月份选择器和统计
                    _buildMonthSelector(viewModel),
                  ],
                ),
              ),

              const Divider(),

              // 账单列表
              Expanded(
                child:
                    _isSearchMode
                        ? _isSearching
                            ? const Center(child: CircularProgressIndicator())
                            : RefreshIndicator(
                              onRefresh: () async {
                                _searchBills(_searchKeyword);
                              },
                              child: ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: _buildGroupedBillList(
                                  _searchResults,
                                  viewModel,
                                ),
                              ),
                            )
                        : RefreshIndicator(
                          onRefresh: () async {
                            final viewModel = Provider.of<BillViewModel>(
                              context,
                              listen: false,
                            );
                            await viewModel.loadNextMonthData(
                              _selectedTypeFilter,
                              _selectedCategoryFilter,
                              minAmount: _minAmountFilter,
                              maxAmount: _maxAmountFilter,
                            );
                          },
                          child: ListView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              // 显示"正在加载更新数据"的提示
                              if (_isLoadingNewer)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),

                              // 账单列表
                              ...(_buildGroupedBillList(
                                viewModel.billItems,
                                viewModel,
                              )),

                              // 显示"正在加载更多"的提示
                              if (_isLoadingMore)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
              ),
            ],
          ),
          floatingActionButton: buildFloatingActionButton(
            _addBill,
            context,
            icon: Icons.add,
            tooltip: '添加账单',
          ),
        );
      },
    );
  }
}
