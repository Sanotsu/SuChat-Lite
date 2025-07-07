import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/screen_helper.dart';
import '../../../../shared/constants/constants.dart';
import '../../domain/entities/bill_statistics.dart';
import '../viewmodels/bill_viewmodel.dart';
import '../widgets/bill_summary_card.dart';
import '../widgets/bar_chart_widget.dart';
import '../widgets/bill_ranking_widget.dart';
import '../widgets/custom_date_pickers.dart';
import '../widgets/summary_action_buttons.dart';
import '../widgets/summary_multi_bar_chart.dart';
import '../utils/statistics_utils.dart';

/// 更多统计页面组件
class FreeStatisticsPage extends StatefulWidget {
  const FreeStatisticsPage({super.key});

  @override
  State<FreeStatisticsPage> createState() => FreeStatisticsPageState();
}

class FreeStatisticsPageState extends State<FreeStatisticsPage>
    with AutomaticKeepAliveClientMixin {
  // 当前选中的类型：0-收入，1-支出
  int _selectedType = 1;

  // 统计开始日期和结束日期
  late DateTime _startDate;
  late DateTime _endDate;

  // 统计单位类型: day, week, month, year
  String _unitType = 'month';

  // 缓存加载过的数据
  Future<BillStatistics>? _cachedStatistics;
  Future<List<BarChartData>>? _cachedChartData;
  Future<List<BillRankingItem>>? _cachedRankingData;

  // 汇总数据缓存
  Future<Map<String, BillStatistics>>? _cachedMonthlySummary;
  Future<Map<String, BillStatistics>>? _cachedYearlySummary;

  // 当前选中的汇总类型：null-未选择，monthly-按月汇总，yearly-按年汇总
  String? _selectedSummaryType;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // 默认统计范围为最近3个月
    _endDate = DateTime.now();
    _startDate = DateTime(_endDate.year, _endDate.month - 3, _endDate.day);

    // 初始化数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getDateRange();
    });
  }

  // 公开的刷新数据方法，供父组件调用
  void refreshData() {
    // 清除汇总数据缓存(其他缓存在加载数据中有清除)
    setState(() {
      _cachedMonthlySummary = null;
      _cachedYearlySummary = null;
    });

    // 重新加载数据
    _loadStatisticsData();
  }

  // 初始化进入页面时查询账单最大日期范围内数据
  Future<void> _getDateRange() async {
    final viewModel = Provider.of<BillViewModel>(context, listen: false);

    var dates = await viewModel.loadBillDateRange();

    setState(() {
      _startDate = dates.first;
      _endDate = dates.last;
      _selectedSummaryType = 'yearly';
    });

    _loadStatisticsData();
  }

  // 加载统计数据
  Future<void> _loadStatisticsData() async {
    // 根据日期范围计算适合的统计单位
    _determineUnitType();

    // 清除缓存数据，强制重新加载
    setState(() {
      _cachedStatistics = null;
      _cachedChartData = null;
      _cachedRankingData = null;
    });
  }

  // 根据日期范围确定统计单位
  void _determineUnitType() {
    final difference = _endDate.difference(_startDate).inDays;

    if (difference <= 7) {
      _unitType = 'day'; // 不足一周，按天统计
    } else if (difference <= 31) {
      _unitType = 'week'; // 不足一个月，按周统计
    } else if (difference <= 365) {
      _unitType = 'month'; // 不足一年，按月统计
    } else {
      _unitType = 'year'; // 超过一年，按年统计
    }

    setState(() {});
  }

  // 处理按月汇总点击
  Future<void> _handleMonthlySummary() async {
    final viewModel = Provider.of<BillViewModel>(context, listen: false);

    // 获取账单日期范围
    final dateRange = await viewModel.loadBillDateRange();

    // 更新日期范围为所有数据
    setState(() {
      _startDate = dateRange[0];
      _endDate = dateRange[1];
      _selectedSummaryType = 'monthly';

      // 清除其他缓存数据，强制重新加载
      _cachedStatistics = null;
      _cachedChartData = null;
      _cachedRankingData = null;
    });

    // 重新确定统计单位
    _determineUnitType();
  }

  // 处理按年汇总点击
  Future<void> _handleYearlySummary() async {
    final viewModel = Provider.of<BillViewModel>(context, listen: false);

    // 获取账单日期范围
    final dateRange = await viewModel.loadBillDateRange();

    // 更新日期范围为所有数据
    setState(() {
      _startDate = dateRange[0];
      _endDate = dateRange[1];
      _selectedSummaryType = 'yearly';

      // 清除其他缓存数据，强制重新加载
      _cachedStatistics = null;
      _cachedChartData = null;
      _cachedRankingData = null;
    });

    // 重新确定统计单位
    _determineUnitType();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 日期范围选择器和收支类型切换
          _buildDateRangeSelector(),
          const SizedBox(height: 16),

          /// 摘要
          _buildSummaryCard(),
          const SizedBox(height: 16),

          /// 统计柱状图
          _buildTrendChart(),
          const SizedBox(height: 16),

          /// 分类统计饼图
          _buildCategoryPieChart(),
          const SizedBox(height: 16),

          /// 账单排行
          _buildBillRanking(),
          const SizedBox(height: 16),

          /// 汇总按钮(统计账单中全部数据)
          ..._buildSummaryChart(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // 构建日期范围选择器和收支类型切换
  Widget _buildDateRangeSelector() {
    return Row(
      children: [
        // 日期范围选择器
        Expanded(
          child: GestureDetector(
            onTap: () => _selectDateRange(),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.date_range,
                    color: Theme.of(context).colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _getFormattedDateRange(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // 收支类型切换
        StatisticsUtils.buildTypeSelector(_selectedType, (type) {
          setState(() {
            _selectedType = type;
            // 清除缓存数据，强制重新加载
            _cachedStatistics = null;
            _cachedChartData = null;
            _cachedRankingData = null;
          });
        }),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return FutureBuilder<BillStatistics>(
      future: _getStatistics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 109, // inspector 看到的
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final stats = snapshot.data ?? BillStatistics.empty();

        return BillSummaryCard(
          title: '${_getDateRangeTitle()}收支',
          income: stats.totalIncome,
          expense: stats.totalExpense,
          balance: stats.netIncome,
        );
      },
    );
  }

  Widget _buildTrendChart() {
    return FutureBuilder<List<BarChartData>>(
      future: _getStatisticsChartData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // 这个高度没法和条状图高度设置一样高
          return const SizedBox(
            height: 250,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox(
            height: 250,
            child: Center(child: Text('无法加载统计数据')),
          );
        }

        var list = snapshot.data!;
        return BarChartWidget(
          data: list,
          title: '${_getDateRangeTitle()}${_selectedType == 0 ? '收入' : '支出'}统计',
          // 每个柱子36大概可以完整显示每个柱子上方的文本
          height: list.length < 3 ? 100 : list.length * 36,
          horizontal: true,
          showLegend: false,
          seriesName: _selectedType == 0 ? '收入' : '支出',
          showYAxis: true,
          showValue: true,
        );
      },
    );
  }

  Widget _buildCategoryPieChart() {
    return FutureBuilder<BillStatistics>(
      future: _getStatistics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: ScreenHelper.isDesktop() ? 350 : 250,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return SizedBox(
            height: ScreenHelper.isDesktop() ? 350 : 250,
            child: Center(child: Text('无法加载分类统计数据')),
          );
        }

        return StatisticsUtils.buildCategoryPieChart(
          snapshot.data!,
          _selectedType,
          ScreenHelper.isDesktop() ? 350 : 250,
        );
      },
    );
  }

  Widget _buildBillRanking() {
    return FutureBuilder<List<BillRankingItem>>(
      future: _getRankingData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: 100,
            child: Center(child: Text('暂无账单排行数据')),
          );
        }

        return BillRankingWidget(
          items: snapshot.data!,
          title: _selectedType == 0 ? '收入排行Top20' : '支出排行Top20',
          maxItems: 20,
          rankMaxHeight: 300,
          onItemTap: (item) {
            if (item.id != null) {
              StatisticsUtils.navigateToBillDetail(context, item.id!);
            }
          },
        );
      },
    );
  }

  List<Widget> _buildSummaryChart() {
    return [
      SummaryActionButtons(
        onMonthlySummary: _handleMonthlySummary,
        onYearlySummary: _handleYearlySummary,
        selectedSummaryType: _selectedSummaryType,
      ),

      /// 按月汇总图表
      if (_selectedSummaryType == 'monthly')
        FutureBuilder<Map<String, BillStatistics>>(
          future: _getMonthlySummaryData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox(
                height: 100,
                child: Center(child: Text('暂无月度汇总数据')),
              );
            }

            return SummaryMultiBarChart(
              statisticsMap: snapshot.data!,
              title: '历史月度汇总',
              isMonthly: true,
              height: ScreenHelper.isDesktop() ? 400 : 300,
            );
          },
        ),

      // 按年汇总图表
      if (_selectedSummaryType == 'yearly')
        FutureBuilder<Map<String, BillStatistics>>(
          future: _getYearlySummaryData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox(
                height: 100,
                child: Center(child: Text('暂无年度汇总数据')),
              );
            }

            return SummaryMultiBarChart(
              statisticsMap: snapshot.data!,
              title: '历史年度汇总',
              isMonthly: false,
              height: ScreenHelper.isDesktop() ? 400 : 300,
            );
          },
        ),
    ];
  }

  // 选择日期范围
  Future<void> _selectDateRange() async {
    final result = await showCustomDateRangePicker(
      context: context,
      startDate: _startDate,
      endDate: _endDate,
      onChanged: (dateRange) {
        // 实时更新不需要处理
      },
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (result != null) {
      setState(() {
        _startDate = result.startDate;
        _endDate = result.endDate;
        // 清除选中的汇总类型
        _selectedSummaryType = null;
      });

      // 重新确定统计单位
      _determineUnitType();

      // 清除缓存数据，强制重新加载
      setState(() {
        _cachedStatistics = null;
        _cachedChartData = null;
        _cachedRankingData = null;
      });
    }
  }

  // 获取格式化的日期范围字符串
  String _getFormattedDateRange() {
    final dateFormat = DateFormat(formatToYMDzh);
    return '${dateFormat.format(_startDate)} -${ScreenHelper.isMobile() ? "\n" : " "}${dateFormat.format(_endDate)}';
  }

  // 获取日期范围标题
  String _getDateRangeTitle() {
    final difference = _endDate.difference(_startDate).inDays;

    if (difference <= 7) {
      return '选中${difference + 1}天';
    } else if (difference <= 31) {
      return '选中${(difference / 7).ceil()}周';
    } else if (difference <= 365) {
      return '选中${(difference / 30).ceil()}个月';
    } else {
      return '选中${(difference / 365).ceil()}年';
    }
  }

  // 获取统计数据（使用缓存）
  Future<BillStatistics> _getStatistics() {
    _cachedStatistics ??= _fetchStatistics();
    return _cachedStatistics!;
  }

  // 获取统计图表数据（使用缓存）
  Future<List<BarChartData>> _getStatisticsChartData() {
    _cachedChartData ??= _fetchStatisticsChartData();
    return _cachedChartData!;
  }

  // 获取排行数据（使用缓存）
  Future<List<BillRankingItem>> _getRankingData() {
    _cachedRankingData ??= StatisticsUtils.getRankingData(
      viewModel: Provider.of<BillViewModel>(context, listen: false),
      startDate: _startDate,
      endDate: _endDate,
      selectedType: _selectedType,
      maxItems: 20,
    );
    return _cachedRankingData!;
  }

  // 获取按月汇总数据（使用缓存）
  Future<Map<String, BillStatistics>> _getMonthlySummaryData() {
    _cachedMonthlySummary ??= StatisticsUtils.getMonthlySummaryData(
      Provider.of<BillViewModel>(context, listen: false),
    );
    return _cachedMonthlySummary!;
  }

  // 获取按年汇总数据（使用缓存）
  Future<Map<String, BillStatistics>> _getYearlySummaryData() {
    _cachedYearlySummary ??= StatisticsUtils.getYearlySummaryData(
      Provider.of<BillViewModel>(context, listen: false),
    );
    return _cachedYearlySummary!;
  }

  // 获取统计数据
  Future<BillStatistics> _fetchStatistics() async {
    try {
      final viewModel = Provider.of<BillViewModel>(context, listen: false);

      // 获取日期范围内的账单
      final bills = await viewModel.getBillRanking(
        startDate: _startDate,
        endDate: _endDate,
        maxItems: 0, // 获取足够多的账单项，0表示获取所有账单
      );

      // 手动计算统计数据
      double totalIncome = 0;
      double totalExpense = 0;
      Map<String, double> incomeByDate = {};
      Map<String, double> expenseByDate = {};
      Map<String, double> incomeByCategory = {};
      Map<String, double> expenseByCategory = {};

      for (var bill in bills) {
        final date = bill.date;
        final category = bill.category;
        final value = bill.value;

        if (bill.itemType == 0) {
          // 收入
          totalIncome += value;

          // 按日期统计
          if (incomeByDate.containsKey(date)) {
            incomeByDate[date] = incomeByDate[date]! + value;
          } else {
            incomeByDate[date] = value;
          }

          // 按分类统计
          if (incomeByCategory.containsKey(category)) {
            incomeByCategory[category] = incomeByCategory[category]! + value;
          } else {
            incomeByCategory[category] = value;
          }
        } else {
          // 支出
          totalExpense += value;

          // 按日期统计
          if (expenseByDate.containsKey(date)) {
            expenseByDate[date] = expenseByDate[date]! + value;
          } else {
            expenseByDate[date] = value;
          }

          // 按分类统计
          if (expenseByCategory.containsKey(category)) {
            expenseByCategory[category] = expenseByCategory[category]! + value;
          } else {
            expenseByCategory[category] = value;
          }
        }
      }

      // 创建统计对象
      return BillStatistics(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        netIncome: totalIncome - totalExpense,
        incomeByDate: incomeByDate,
        expenseByDate: expenseByDate,
        incomeByCategory: incomeByCategory,
        expenseByCategory: expenseByCategory,
      );
    } catch (e) {
      StatisticsUtils.log('获取统计数据失败: $e');
      return BillStatistics.empty();
    }
  }

  // 获取统计图表数据
  Future<List<BarChartData>> _fetchStatisticsChartData() async {
    try {
      final stats = await _getStatistics();
      final List<BarChartData> result = [];

      // 根据统计单位生成不同的数据
      switch (_unitType) {
        case 'day':
          result.addAll(_getDailyChartData(stats));
          break;
        case 'week':
          result.addAll(_getWeeklyChartData(stats));
          break;
        case 'month':
          result.addAll(_getMonthlyChartData(stats));
          break;
        case 'year':
          result.addAll(_getYearlyChartData(stats));
          break;
      }

      return result;
    } catch (e) {
      StatisticsUtils.log('获取统计图表数据失败: $e');
      return [];
    }
  }

  // 获取按天的统计数据
  List<BarChartData> _getDailyChartData(BillStatistics stats) {
    final List<BarChartData> result = [];
    final Map<String, double> dateData =
        _selectedType == 0 ? stats.incomeByDate : stats.expenseByDate;

    if (dateData.isEmpty) return [];

    // 获取日期范围内的所有日期
    final List<DateTime> allDates = [];
    for (var i = 0; i <= _endDate.difference(_startDate).inDays; i++) {
      allDates.add(_startDate.add(Duration(days: i)));
    }

    // 按日期排序（从早到晚）
    allDates.sort((a, b) => a.compareTo(b));

    // 生成每天的数据
    for (var date in allDates) {
      final dateStr = DateFormat(formatToYMD).format(date);
      final value = dateData[dateStr] ?? 0;

      result.add(
        BarChartData(
          category: DateFormat(formatToMD).format(date),
          value: value,
          // 支出为绿色，收入为红色
          color: _selectedType == 0 ? Colors.red : Colors.green,
          // 所有都是选中状态
          isSelected: true,
        ),
      );
    }

    return result;
  }

  // 获取按周的统计数据
  List<BarChartData> _getWeeklyChartData(BillStatistics stats) {
    final List<BarChartData> result = [];
    final Map<String, double> dateData =
        _selectedType == 0 ? stats.incomeByDate : stats.expenseByDate;

    if (dateData.isEmpty) return [];

    // 按周分组数据
    final Map<String, double> weeklyData = {};

    // 获取日期范围内的所有日期
    final List<DateTime> allDates = [];
    for (var i = 0; i <= _endDate.difference(_startDate).inDays; i++) {
      allDates.add(_startDate.add(Duration(days: i)));
    }

    // 按周分组
    for (var date in allDates) {
      final dateStr = DateFormat(formatToYMD).format(date);
      final weekStart = date.subtract(Duration(days: date.weekday - 1));
      final weekKey = DateFormat(formatToYMD).format(weekStart);

      if (!weeklyData.containsKey(weekKey)) {
        weeklyData[weekKey] = 0;
      }

      weeklyData[weekKey] = weeklyData[weekKey]! + (dateData[dateStr] ?? 0);
    }

    // 按日期排序
    final sortedKeys = weeklyData.keys.toList()..sort();

    // 生成每周的数据
    for (var weekKey in sortedKeys) {
      final weekStart = DateTime.parse(weekKey);
      final weekEnd = weekStart.add(const Duration(days: 6));
      final weekLabel =
          '${DateFormat('MM.dd').format(weekStart)}-${DateFormat('MM.dd').format(weekEnd)}';

      result.add(
        BarChartData(
          category: weekLabel,
          value: weeklyData[weekKey]!,
          // 支出为绿色，收入为红色
          color: _selectedType == 0 ? Colors.red : Colors.green,
          isSelected: true,
        ),
      );
    }

    return result;
  }

  // 获取按月的统计数据
  List<BarChartData> _getMonthlyChartData(BillStatistics stats) {
    final List<BarChartData> result = [];
    final Map<String, double> dateData =
        _selectedType == 0 ? stats.incomeByDate : stats.expenseByDate;

    if (dateData.isEmpty) return [];

    // 按月分组数据
    final Map<String, double> monthlyData = {};

    // 遍历所有日期数据
    for (var entry in dateData.entries) {
      final date = DateTime.parse(entry.key);
      final monthKey = DateFormat(formatToYM).format(date);

      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = 0;
      }

      monthlyData[monthKey] = monthlyData[monthKey]! + entry.value;
    }

    // 确保包含所有月份，即使没有数据
    DateTime current = DateTime(_startDate.year, _startDate.month);
    while (current.isBefore(
      DateTime(_endDate.year, _endDate.month).add(const Duration(days: 1)),
    )) {
      final monthKey = DateFormat(formatToYM).format(current);

      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = 0;
      }

      // 移到下个月
      if (current.month == 12) {
        current = DateTime(current.year + 1, 1);
      } else {
        current = DateTime(current.year, current.month + 1);
      }
    }

    // 按日期排序
    final sortedKeys = monthlyData.keys.toList()..sort();

    // 生成每月的数据
    for (var monthKey in sortedKeys) {
      final parts = monthKey.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final monthLabel = '$year年${month.toString().padLeft(2, '0')}月';

      result.add(
        BarChartData(
          category: monthLabel,
          value: monthlyData[monthKey]!,
          // 支出为绿色，收入为红色
          color: _selectedType == 0 ? Colors.red : Colors.green,
          isSelected: true,
        ),
      );
    }

    return result;
  }

  // 获取按年的统计数据
  List<BarChartData> _getYearlyChartData(BillStatistics stats) {
    final List<BarChartData> result = [];
    final Map<String, double> dateData =
        _selectedType == 0 ? stats.incomeByDate : stats.expenseByDate;

    if (dateData.isEmpty) return [];

    // 按年分组数据
    final Map<int, double> yearlyData = {};

    // 遍历所有日期数据
    for (var entry in dateData.entries) {
      final date = DateTime.parse(entry.key);
      final year = date.year;

      if (!yearlyData.containsKey(year)) {
        yearlyData[year] = 0;
      }

      yearlyData[year] = yearlyData[year]! + entry.value;
    }

    // 确保包含所有年份，即使没有数据
    for (var year = _startDate.year; year <= _endDate.year; year++) {
      if (!yearlyData.containsKey(year)) {
        yearlyData[year] = 0;
      }
    }

    // 按年份排序
    final sortedYears = yearlyData.keys.toList()..sort();

    // 生成每年的数据
    for (var year in sortedYears) {
      result.add(
        BarChartData(
          category: '$year年',
          value: yearlyData[year]!,
          // 支出为绿色，收入为红色
          color: _selectedType == 0 ? Colors.red : Colors.green,
          isSelected: true,
        ),
      );
    }

    return result;
  }
}
