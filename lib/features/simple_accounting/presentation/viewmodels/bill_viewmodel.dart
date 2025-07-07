import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/constants/constants.dart';
import '../../data/bill_dao.dart';
import '../../domain/entities/bill_item.dart';
import '../../domain/entities/bill_category.dart';
import '../../domain/entities/bill_statistics.dart';

/// 账单视图模型
class BillViewModel extends ChangeNotifier {
  final BillDao _repository = BillDao();

  // 是否正在加载
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 错误信息
  String? _error;
  String? get error => _error;
  String? _errorContext;
  String? get errorContext => _errorContext;

  // 当前选中的年份
  int _selectedYear = DateTime.now().year;
  int get selectedYear => _selectedYear;

  // 当前选中的月份
  int _selectedMonth = DateTime.now().month;
  int get selectedMonth => _selectedMonth;

  // 当前选中的周的开始和结束日期
  DateTime _weekStartDate = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday),
  );
  DateTime get weekStartDate => _weekStartDate;

  DateTime _weekEndDate = DateTime.now().add(
    Duration(days: 7 - DateTime.now().weekday + 1),
  );
  DateTime get weekEndDate => _weekEndDate;

  // 当前的统计数据
  BillStatistics? _currentStatistics;
  BillStatistics? get currentStatistics => _currentStatistics;

  // 当前的账单列表
  List<BillItem> _billItems = [];
  List<BillItem> get billItems => _billItems;

  // 当前的分类列表
  List<BillCategory> _categories = [];
  List<BillCategory> get categories => _categories;

  // 支出分类
  List<BillCategory> _expenseCategories = [];
  List<BillCategory> get expenseCategories => _expenseCategories;

  // 收入分类
  List<BillCategory> _incomeCategories = [];
  List<BillCategory> get incomeCategories => _incomeCategories;

  // 当前的统计类型（周、月、年）
  String _currentStatisticsType = 'month';
  String get currentStatisticsType => _currentStatisticsType;

  /// 初始化
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _loadCategories();
      await loadMonthlyData(_selectedYear, _selectedMonth, null, null);
    } catch (e) {
      _setError('初始化失败', e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// 加载分类数据
  Future<void> _loadCategories() async {
    try {
      _categories = await _repository.getAllCategories();
      _expenseCategories = await _repository.getExpenseCategories();
      _incomeCategories = await _repository.getIncomeCategories();
      notifyListeners();
    } catch (e) {
      _setError('加载分类失败', e.toString());
    }
  }

  /// 统一的去重方法：合并新旧账单数据，确保不重复
  List<BillItem> _mergeBillItemsWithoutDuplicates(
    List<BillItem> oldItems,
    List<BillItem> newItems, {
    bool newItemsFirst = false,
  }) {
    // 创建一个Map用于快速查找和去重
    final Map<int?, BillItem> uniqueBills = {};

    // 根据newItemsFirst参数决定处理顺序，确保保留的是需要优先的项
    final firstList = newItemsFirst ? newItems : oldItems;
    final secondList = newItemsFirst ? oldItems : newItems;

    // 先处理第一个列表
    for (var bill in firstList) {
      if (bill.billItemId != null) {
        uniqueBills[bill.billItemId] = bill;
      }
    }

    // 再处理第二个列表，只添加不存在的项
    for (var bill in secondList) {
      if (bill.billItemId != null &&
          !uniqueBills.containsKey(bill.billItemId)) {
        uniqueBills[bill.billItemId] = bill;
      }
    }

    // 返回去重后的列表
    return uniqueBills.values.toList();
  }

  /// 加载月度数据
  Future<void> loadMonthlyData(
    int year,
    int month,
    int? itemType,
    String? category, {
    double? minAmount,
    double? maxAmount,
  }) async {
    _setLoading(true);
    try {
      _selectedYear = year;
      _selectedMonth = month;
      _currentStatisticsType = 'month';

      _billItems = await _repository.getBillItemsByMonth(
        year,
        month,
        itemType: itemType,
        category: category,
      );

      // 如果有金额范围筛选，在内存中过滤
      if (minAmount != null || maxAmount != null) {
        _billItems =
            _billItems.where((bill) {
              if (minAmount != null && bill.value < minAmount) {
                return false;
              }
              if (maxAmount != null && bill.value > maxAmount) {
                return false;
              }
              return true;
            }).toList();
      }

      _currentStatistics = await _repository.getMonthlyStatistics(
        year,
        month,
        itemType: itemType,
        category: category,
      );

      // 如果有金额范围筛选，重新计算统计数据
      if (minAmount != null || maxAmount != null) {
        _currentStatistics = _calculateFilteredStatistics(_billItems);
      }

      notifyListeners();
    } catch (e) {
      _setError('加载月度数据失败', e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// 刷新当前月份数据
  Future<void> refreshCurrentMonthData(
    int? itemType,
    String? category, {
    double? minAmount,
    double? maxAmount,
  }) async {
    _setLoading(true);
    try {
      final freshItems = await _repository.getBillItemsByMonth(
        _selectedYear,
        _selectedMonth,
        itemType: itemType,
        category: category,
      );

      // 使用新数据替换旧数据
      _billItems = freshItems;

      // 如果有金额范围筛选，在内存中过滤
      if (minAmount != null || maxAmount != null) {
        _billItems =
            _billItems.where((bill) {
              if (minAmount != null && bill.value < minAmount) {
                return false;
              }
              if (maxAmount != null && bill.value > maxAmount) {
                return false;
              }
              return true;
            }).toList();
      }

      _currentStatistics = await _repository.getMonthlyStatistics(
        _selectedYear,
        _selectedMonth,
        itemType: itemType,
        category: category,
      );

      // 如果有金额范围筛选，重新计算统计数据
      if (minAmount != null || maxAmount != null) {
        _currentStatistics = _calculateFilteredStatistics(_billItems);
      }

      notifyListeners();
    } catch (e) {
      _setError('刷新数据失败', e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// 加载上一个月的数据（滚动加载更早数据）
  Future<void> loadPreviousMaxSixMonthData(
    int? itemType,
    String? category, {
    double? minAmount,
    double? maxAmount,
  }) async {
    try {
      // 计算上一个月
      int prevYear = _selectedYear;
      int prevMonth = _selectedMonth;
      List<BillItem> previousMonthItems = [];

      // 最多查找12个月的数据
      // ？？？这里有个小问题，如果中间超过12个月没有数据，在之前有数据也滚动无法加载了。
      // 比如第一条时2025.01.01,第二条是2023.12.31,超过12个月，滚动加载不出来
      // 理论上应该是遍历直到找到数据或在全部遍历完为止
      for (int i = 0; i < 12; i++) {
        prevMonth--;
        if (prevMonth <= 0) {
          prevYear--;
          prevMonth = 12;
        }

        previousMonthItems = await _repository.getBillItemsByMonth(
          prevYear,
          prevMonth,
          itemType: itemType,
          category: category,
        );

        // 如果有金额范围筛选，在内存中过滤
        if (minAmount != null || maxAmount != null) {
          previousMonthItems =
              previousMonthItems.where((bill) {
                if (minAmount != null && bill.value < minAmount) {
                  return false;
                }
                if (maxAmount != null && bill.value > maxAmount) {
                  return false;
                }
                return true;
              }).toList();
        }

        if (previousMonthItems.isNotEmpty) {
          // 找到数据，更新状态并退出循环
          // 合并数据，确保不重复，旧数据优先（添加到末尾）
          _billItems = _mergeBillItemsWithoutDuplicates(
            previousMonthItems,
            _billItems,
            newItemsFirst: false,
          );

          _selectedYear = prevYear;
          _selectedMonth = prevMonth;
          _currentStatistics = await _repository.getMonthlyStatistics(
            _selectedYear,
            _selectedMonth,
            itemType: itemType,
            category: category,
          );

          // 如果有金额范围筛选，重新计算统计数据
          if (minAmount != null || maxAmount != null) {
            _currentStatistics = _calculateFilteredStatistics(
              previousMonthItems,
            );
          }
          break;
        }
      }

      notifyListeners();
    } catch (e) {
      _setError('加载更多数据失败', e.toString());
    }
  }

  /// 加载上一个月的数据（滚动加载更早数据）
  /// 最多查找36个月的数据
  Future<void> loadPreviousMonthData(
    int? itemType,
    String? category, {
    double? minAmount,
    double? maxAmount,
  }) async {
    try {
      // 计算3年前的年份和月份
      int targetYear = _selectedYear - 3;
      int targetMonth = _selectedMonth;

      // 当前要查询的年份和月份
      int currentYear = _selectedYear;
      int currentMonth = _selectedMonth;

      List<BillItem> previousMonthItems = [];

      // 从当前月份开始，向前遍历直到3年前
      while (currentYear > targetYear ||
          (currentYear == targetYear && currentMonth > targetMonth)) {
        // 先减月份
        currentMonth--;
        if (currentMonth <= 0) {
          currentYear--;
          currentMonth = 12;
        }

        previousMonthItems = await _repository.getBillItemsByMonth(
          currentYear,
          currentMonth,
          itemType: itemType,
          category: category,
        );

        // 金额范围筛选
        if (minAmount != null || maxAmount != null) {
          previousMonthItems =
              previousMonthItems.where((bill) {
                if (minAmount != null && bill.value < minAmount) return false;
                if (maxAmount != null && bill.value > maxAmount) return false;
                return true;
              }).toList();
        }

        if (previousMonthItems.isNotEmpty) {
          _billItems = _mergeBillItemsWithoutDuplicates(
            previousMonthItems,
            _billItems,
            newItemsFirst: false,
          );

          _selectedYear = currentYear;
          _selectedMonth = currentMonth;
          _currentStatistics = await _repository.getMonthlyStatistics(
            _selectedYear,
            _selectedMonth,
            itemType: itemType,
            category: category,
          );

          if (minAmount != null || maxAmount != null) {
            _currentStatistics = _calculateFilteredStatistics(
              previousMonthItems,
            );
          }
          break;
        }
      }

      notifyListeners();
    } catch (e) {
      _setError('加载更多数据失败', e.toString());
    }
  }

  /// 加载下一个月的数据（滚动加载更新数据）
  Future<void> loadNextMonthData(
    int? itemType,
    String? category, {
    double? minAmount,
    double? maxAmount,
  }) async {
    try {
      // 计算下一个月
      int nextYear = _selectedYear;
      int nextMonth = _selectedMonth;
      List<BillItem> nextMonthItems = [];

      // 最多查找36个月的数据
      for (int i = 0; i < 36; i++) {
        nextMonth++;
        if (nextMonth > 12) {
          nextYear++;
          nextMonth = 1;
        }

        nextMonthItems = await _repository.getBillItemsByMonth(
          nextYear,
          nextMonth,
          itemType: itemType,
          category: category,
        );

        // 如果有金额范围筛选，在内存中过滤
        if (minAmount != null || maxAmount != null) {
          nextMonthItems =
              nextMonthItems.where((bill) {
                if (minAmount != null && bill.value < minAmount) {
                  return false;
                }
                if (maxAmount != null && bill.value > maxAmount) {
                  return false;
                }
                return true;
              }).toList();
        }

        if (nextMonthItems.isNotEmpty) {
          // 找到数据，更新状态并退出循环
          // 合并数据，确保不重复，新数据优先（添加到开头）
          _billItems = _mergeBillItemsWithoutDuplicates(
            _billItems,
            nextMonthItems,
            newItemsFirst: true,
          );

          _selectedYear = nextYear;
          _selectedMonth = nextMonth;
          _currentStatistics = await _repository.getMonthlyStatistics(
            _selectedYear,
            _selectedMonth,
            itemType: itemType,
            category: category,
          );

          // 如果有金额范围筛选，重新计算统计数据
          if (minAmount != null || maxAmount != null) {
            _currentStatistics = _calculateFilteredStatistics(nextMonthItems);
          }
          break;
        }
      }

      notifyListeners();
    } catch (e) {
      _setError('加载更新数据失败', e.toString());
    }
  }

  /// 加载周数据
  Future<void> loadWeeklyData(DateTime startDate, DateTime endDate) async {
    // 如果日期范围和统计类型都没有变化，且已经有数据，则不需要重新加载
    if (_currentStatisticsType == 'week' &&
        _weekStartDate == startDate &&
        _weekEndDate == endDate &&
        _currentStatistics != null) {
      return;
    }

    _setLoading(true);
    try {
      // 保存日期范围
      _weekStartDate = startDate;
      _weekEndDate = endDate;

      // 先设置统计类型，确保其他地方可以正确识别当前是周统计
      _currentStatisticsType = 'week';

      // 并行获取周数据和统计数据，提高效率
      final billItemsFuture = _repository.getBillItemsByWeek(
        startDate,
        endDate,
      );
      final statsFuture = _repository.getWeeklyStatistics(startDate, endDate);

      // 等待所有数据加载完成
      final results = await Future.wait([billItemsFuture, statsFuture]);

      // 更新数据模型
      _billItems = results[0] as List<BillItem>;
      _currentStatistics = results[1] as BillStatistics;

      // 所有数据更新完成后，一次性通知监听者
      notifyListeners();
    } catch (e) {
      _setError('加载周数据失败', e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// 加载年度数据
  Future<void> loadYearlyData(
    int year, {
    int? itemType,
    String? category,
  }) async {
    _setLoading(true);
    try {
      _selectedYear = year;
      _currentStatisticsType = 'year';

      _billItems = await _repository.getBillItemsByYear(
        year,
        itemType: itemType,
        category: category,
      );
      _currentStatistics = await _repository.getYearlyStatistics(year);

      notifyListeners();
    } catch (e) {
      _setError('加载年度数据失败', e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// 加载账单的日期范围
  Future<List<DateTime>> loadBillDateRange() async {
    final startDate = await _repository.getMinDate();
    final endDate = await _repository.getMaxDate();
    return [startDate, endDate];
  }

  /// 加载筛选后的数据
  Future<void> loadFilteredData(
    int? itemType,
    String? category, {
    double? minAmount,
    double? maxAmount,
  }) async {
    _setLoading(true);
    try {
      // 获取当前月份的数据
      _billItems = await _repository.getBillItemsByMonth(
        _selectedYear,
        _selectedMonth,
        itemType: itemType,
        category: category,
      );

      // 如果有金额范围筛选，在内存中过滤
      if (minAmount != null || maxAmount != null) {
        _billItems =
            _billItems.where((bill) {
              if (minAmount != null && bill.value < minAmount) {
                return false;
              }
              if (maxAmount != null && bill.value > maxAmount) {
                return false;
              }
              return true;
            }).toList();
      }

      _currentStatistics = await _repository.getMonthlyStatistics(
        _selectedYear,
        _selectedMonth,
        itemType: itemType,
        category: category,
      );

      // 如果有金额范围筛选，重新计算统计数据
      if (minAmount != null || maxAmount != null) {
        _currentStatistics = _calculateFilteredStatistics(_billItems);
      }

      // 如果是分类过滤模式且当前月份数据不足，自动加载前后月份的数据
      if ((itemType != null ||
              category != null ||
              minAmount != null ||
              maxAmount != null) &&
          _billItems.isEmpty) {
        await _autoLoadMoreData(
          itemType,
          category,
          minAmount: minAmount,
          maxAmount: maxAmount,
        );
      }

      notifyListeners();
    } catch (e) {
      _setError('加载筛选数据失败', e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// 自动加载更多数据（用于分类过滤模式）
  Future<void> _autoLoadMoreData(
    int? itemType,
    String? category, {
    double? minAmount,
    double? maxAmount,
  }) async {
    try {
      // 向前查找3个月
      int prevYear = _selectedYear;
      int prevMonth = _selectedMonth;
      List<BillItem> allPreviousItems = [];

      for (int i = 0; i < 3; i++) {
        prevMonth--;
        if (prevMonth <= 0) {
          prevYear--;
          prevMonth = 12;
        }

        final previousMonthItems = await _repository.getBillItemsByMonth(
          prevYear,
          prevMonth,
          itemType: itemType,
          category: category,
        );

        // 如果有金额范围筛选，在内存中过滤
        List<BillItem> filteredItems = previousMonthItems;
        if (minAmount != null || maxAmount != null) {
          filteredItems =
              previousMonthItems.where((bill) {
                if (minAmount != null && bill.value < minAmount) {
                  return false;
                }
                if (maxAmount != null && bill.value > maxAmount) {
                  return false;
                }
                return true;
              }).toList();
        }

        if (filteredItems.isNotEmpty) {
          allPreviousItems = _mergeBillItemsWithoutDuplicates(
            allPreviousItems,
            filteredItems,
            newItemsFirst: false,
          );
        }
      }

      // 添加前几个月的数据到当前数据
      _billItems = _mergeBillItemsWithoutDuplicates(
        _billItems,
        allPreviousItems,
        newItemsFirst: false,
      );

      // 向后查找3个月
      int nextYear = _selectedYear;
      int nextMonth = _selectedMonth;
      List<BillItem> allNextItems = [];

      for (int i = 0; i < 3; i++) {
        nextMonth++;
        if (nextMonth > 12) {
          nextYear++;
          nextMonth = 1;
        }

        final nextMonthItems = await _repository.getBillItemsByMonth(
          nextYear,
          nextMonth,
          itemType: itemType,
          category: category,
        );

        // 如果有金额范围筛选，在内存中过滤
        List<BillItem> filteredItems = nextMonthItems;
        if (minAmount != null || maxAmount != null) {
          filteredItems =
              nextMonthItems.where((bill) {
                if (minAmount != null && bill.value < minAmount) {
                  return false;
                }
                if (maxAmount != null && bill.value > maxAmount) {
                  return false;
                }
                return true;
              }).toList();
        }

        if (filteredItems.isNotEmpty) {
          allNextItems = _mergeBillItemsWithoutDuplicates(
            allNextItems,
            filteredItems,
            newItemsFirst: true,
          );
        }
      }

      // 将后几个月的数据添加到当前数据前面
      _billItems = _mergeBillItemsWithoutDuplicates(
        _billItems,
        allNextItems,
        newItemsFirst: true,
      );
    } catch (e) {
      _setError('自动加载更多数据失败', e.toString());
    }
  }

  /// 搜索账单
  Future<List<BillItem>> searchBills(
    String keyword, {
    int? type,
    String? category,
    double? minAmount,
    double? maxAmount,
  }) async {
    try {
      List<BillItem> results = await _repository.searchBillItems(keyword);

      // 应用类型筛选
      if (type != null) {
        results = results.where((bill) => bill.itemType == type).toList();
      }

      // 应用分类筛选
      if (category != null) {
        results = results.where((bill) => bill.category == category).toList();
      }

      // 应用金额范围筛选
      if (minAmount != null || maxAmount != null) {
        results =
            results.where((bill) {
              if (minAmount != null && bill.value < minAmount) {
                return false;
              }
              if (maxAmount != null && bill.value > maxAmount) {
                return false;
              }
              return true;
            }).toList();
      }

      return results;
    } catch (e) {
      _setError('搜索账单失败', e.toString());
      return [];
    }
  }

  /// 添加账单
  Future<bool> addBill(BillItem billItem) async {
    try {
      await _repository.insertBillItem(billItem);

      // 刷新当前数据
      if (_currentStatisticsType == 'month') {
        await refreshCurrentMonthData(null, null);
      } else if (_currentStatisticsType == 'week') {
        await loadWeeklyData(_weekStartDate, _weekEndDate);
      } else {
        await loadYearlyData(_selectedYear);
      }

      return true;
    } catch (e) {
      _setError('添加账单失败', e.toString());
      return false;
    }
  }

  /// 更新账单
  Future<bool> updateBill(BillItem billItem) async {
    try {
      await _repository.updateBillItem(billItem);

      // 刷新当前数据
      if (_currentStatisticsType == 'month') {
        await refreshCurrentMonthData(null, null);
      } else if (_currentStatisticsType == 'week') {
        await loadWeeklyData(_weekStartDate, _weekEndDate);
      } else {
        await loadYearlyData(_selectedYear);
      }

      return true;
    } catch (e) {
      _setError('更新账单失败', e.toString());
      return false;
    }
  }

  /// 删除账单
  Future<bool> deleteBill(int id) async {
    try {
      await _repository.deleteBillItem(id);

      // 刷新当前数据
      if (_currentStatisticsType == 'month') {
        await refreshCurrentMonthData(null, null);
      } else if (_currentStatisticsType == 'week') {
        await loadWeeklyData(_weekStartDate, _weekEndDate);
      } else {
        await loadYearlyData(_selectedYear);
      }

      return true;
    } catch (e) {
      _setError('删除账单失败', e.toString());
      return false;
    }
  }

  /// 获取账单详情
  Future<BillItem?> getBillDetail(int id) async {
    try {
      return await _repository.getBillItem(id);
    } catch (e) {
      _setError('获取账单详情失败', e.toString());
      return null;
    }
  }

  /// 从JSON导入账单数据
  Future<int> importFromJson(String jsonString) async {
    try {
      final count = await _repository.importFromJson(jsonString);

      // 刷新当前数据
      if (_currentStatisticsType == 'month') {
        await refreshCurrentMonthData(null, null);
      } else if (_currentStatisticsType == 'week') {
        await loadWeeklyData(_weekStartDate, _weekEndDate);
      } else {
        await loadYearlyData(_selectedYear);
      }

      return count;
    } catch (e) {
      _setError('导入数据失败', e.toString());
      return 0;
    }
  }

  /// 导出账单数据为JSON
  Future<String> exportToJson() async {
    try {
      return await _repository.exportToJson();
    } catch (e) {
      _setError('导出数据失败', e.toString());
      return '';
    }
  }

  /// 更新选中的月份（不重新加载数据）
  void updateSelectedMonth(int year, int month) {
    _selectedYear = year;
    _selectedMonth = month;
    notifyListeners();
  }

  /// 更新月度统计数据（不重新加载账单列表）
  Future<void> updateMonthlyStatistics(
    int year,
    int month,
    int? itemType,
    String? category, {
    double? minAmount,
    double? maxAmount,
  }) async {
    try {
      // 只更新统计数据，不重新加载账单列表
      _currentStatistics = await _repository.getMonthlyStatistics(
        year,
        month,
        itemType: itemType,
        category: category,
      );

      // 如果有金额范围筛选，需要在内存中过滤并重新计算统计数据
      if (minAmount != null || maxAmount != null) {
        // 获取当前显示的账单中属于指定月份的数据
        final monthKey = '$year-${month.toString().padLeft(2, '0')}';
        final monthlyBills =
            _billItems.where((bill) => bill.date.startsWith(monthKey)).toList();

        // 应用金额筛选
        final filteredBills =
            monthlyBills.where((bill) {
              if (minAmount != null && bill.value < minAmount) {
                return false;
              }
              if (maxAmount != null && bill.value > maxAmount) {
                return false;
              }
              return true;
            }).toList();

        // 重新计算统计数据
        _currentStatistics = _calculateFilteredStatistics(filteredBills);
      }

      notifyListeners();
    } catch (e) {
      _setError('更新月度统计数据失败', e.toString());
    }
  }

  /// 格式化日期
  String getFormattedDate(DateTime date) {
    return DateFormat(formatToYMDzh).format(date);
  }

  /// 格式化月份
  String getFormattedMonth(int year, int month) {
    return '$year年${month.toString().padLeft(2, '0')}月';
  }

  /// 格式化周
  String getFormattedWeek(DateTime startDate, DateTime endDate) {
    return '${DateFormat(formatToMDzh).format(startDate)}-${DateFormat(formatToMDzh).format(endDate)}';
  }

  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 设置错误信息
  void _setError(String context, String error) {
    _errorContext = context;
    _error = error;
    notifyListeners();
  }

  /// 清除错误信息
  void clearError() {
    _errorContext = null;
    _error = null;
    notifyListeners();
  }

  /// 根据分类名称和类型获取分类对象
  BillCategory? getCategoryByName(String name, int type) {
    final categories = type == 0 ? incomeCategories : expenseCategories;
    return categories.firstWhere(
      (category) => category.name == name,
      orElse:
          () => BillCategory(
            name: name,
            icon: type == 0 ? 'arrow_downward' : 'arrow_upward',
            color: type == 0 ? '#4CAF50' : '#F44336',
            type: type,
          ),
    );
  }

  /// 获取近6个月的统计数据
  Future<Map<String, BillStatistics>> getLast6MonthsStatistics() async {
    final Map<String, BillStatistics> result = {};

    // 使用选中的年月作为基准，而不是当前日期
    int baseYear = _selectedYear;
    int baseMonth = _selectedMonth;

    // 获取当前月份和前5个月的数据
    for (int i = 0; i < 6; i++) {
      // 计算月份
      int year = baseYear;
      int month = baseMonth - i;

      // 处理跨年的情况
      while (month <= 0) {
        year--;
        month += 12;
      }

      // 获取该月的统计数据
      final stats = await _repository.getMonthlyStatistics(
        year,
        month,
        itemType: null,
        category: null,
      );

      // 使用格式化的月份作为键
      final key = '$year-${month.toString().padLeft(2, '0')}';
      result[key] = stats;
    }

    return result;
  }

  /// 获取近6年的统计数据
  Future<Map<String, BillStatistics>> getLast6YearsStatistics() async {
    final Map<String, BillStatistics> result = {};

    // 使用选中的年份作为基准，而不是当前年份
    final baseYear = _selectedYear;

    // 获取当前年和前5年的数据
    for (int i = 0; i < 6; i++) {
      final year = baseYear - i;
      final stats = await _repository.getYearlyStatistics(year);

      // 使用年份作为键
      result[year.toString()] = stats;
    }

    return result;
  }

  /// 获取当前年度每月的统计数据
  Future<Map<String, BillStatistics>> getYearlyMonthlyStatistics(
    int year,
  ) async {
    final Map<String, BillStatistics> result = {};

    // 获取每个月的统计数据
    for (int month = 1; month <= 12; month++) {
      final stats = await _repository.getMonthlyStatistics(
        year,
        month,
        itemType: null,
        category: null,
      );

      // 使用月份作为键
      final key = month.toString().padLeft(2, '0');
      result[key] = stats;
    }

    return result;
  }

  /// 获取账单排行榜
  Future<List<BillItem>> getBillRanking({
    required DateTime startDate,
    required DateTime endDate,
    int? itemType,
    int maxItems = 10,
  }) async {
    try {
      // 格式化日期
      final startDateStr = DateFormat(formatToYMD).format(startDate);
      final endDateStr = DateFormat(formatToYMD).format(endDate);

      // 获取时间范围内的账单
      final bills = await _repository.getBillItemsByDateRange(
        startDateStr,
        endDateStr,
        itemType: itemType,
      );

      // 按金额排序
      bills.sort((a, b) => b.value.compareTo(a.value));

      // 如果maxItems小于等于0，则返回所有账单
      if (maxItems <= 0) {
        return bills;
      }
      // 返回前N项
      return bills.take(maxItems).toList();
    } catch (e) {
      _setError('获取账单排行失败', e.toString());
      return [];
    }
  }

  /// 获取指定周的统计数据（不加载账单列表）
  Future<BillStatistics> getWeeklyStatistics(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _repository.getWeeklyStatistics(startDate, endDate);
    } catch (e) {
      _setError('获取周统计数据失败', e.toString());
      return BillStatistics.empty();
    }
  }

  /// 获取月度统计数据（不加载账单列表）
  Future<BillStatistics> getMonthlyStatistics(int year, int month) async {
    try {
      return await _repository.getMonthlyStatistics(
        year,
        month,
        itemType: null,
        category: null,
      );
    } catch (e) {
      _setError('获取月度统计数据失败', e.toString());
      return BillStatistics.empty();
    }
  }

  /// 获取年度统计数据（不加载账单列表）
  Future<BillStatistics> getYearlyStatistics(int year) async {
    try {
      return await _repository.getYearlyStatistics(year);
    } catch (e) {
      _setError('获取年度统计数据失败', e.toString());
      return BillStatistics.empty();
    }
  }

  /// 根据过滤后的账单重新计算统计数据
  BillStatistics _calculateFilteredStatistics(List<BillItem> billItems) {
    double totalIncome = 0;
    double totalExpense = 0;
    Map<String, double> expenseByCategory = {};
    Map<String, double> incomeByCategory = {};
    Map<String, double> expenseByDate = {};
    Map<String, double> incomeByDate = {};

    for (var item in billItems) {
      if (item.itemType == 0) {
        // 收入
        totalIncome += item.value;

        // 按分类统计
        if (incomeByCategory.containsKey(item.category)) {
          incomeByCategory[item.category] =
              incomeByCategory[item.category]! + item.value;
        } else {
          incomeByCategory[item.category] = item.value;
        }

        // 按日期统计
        if (incomeByDate.containsKey(item.date)) {
          incomeByDate[item.date] = incomeByDate[item.date]! + item.value;
        } else {
          incomeByDate[item.date] = item.value;
        }
      } else {
        // 支出
        totalExpense += item.value;

        // 按分类统计
        if (expenseByCategory.containsKey(item.category)) {
          expenseByCategory[item.category] =
              expenseByCategory[item.category]! + item.value;
        } else {
          expenseByCategory[item.category] = item.value;
        }

        // 按日期统计
        if (expenseByDate.containsKey(item.date)) {
          expenseByDate[item.date] = expenseByDate[item.date]! + item.value;
        } else {
          expenseByDate[item.date] = item.value;
        }
      }
    }

    return BillStatistics(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netIncome: totalIncome - totalExpense,
      expenseByCategory: expenseByCategory,
      incomeByCategory: incomeByCategory,
      expenseByDate: expenseByDate,
      incomeByDate: incomeByDate,
    );
  }
}
