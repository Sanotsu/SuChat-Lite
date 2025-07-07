import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/screen_helper.dart';
import '../../../../shared/constants/constants.dart';
import '../viewmodels/bill_viewmodel.dart';
import '../widgets/bill_ranking_widget.dart';
import '../widgets/bill_summary_card.dart';
import '../widgets/bar_chart_widget.dart';
import '../widgets/month_calendar_widget.dart';
import '../widgets/custom_date_pickers.dart';
import '../utils/statistics_utils.dart';

/// 月统计页面
class MonthlyStatisticsPage extends StatefulWidget {
  const MonthlyStatisticsPage({super.key});
  @override
  State<MonthlyStatisticsPage> createState() => MonthlyStatisticsPageState();
}

class MonthlyStatisticsPageState extends State<MonthlyStatisticsPage>
    with AutomaticKeepAliveClientMixin {
  // 当前选中的类型：0-收入，1-支出
  int _selectedType = 1;

  // 缓存加载过的数据
  Future<List<BarChartData>>? _cachedLast6MonthsData;
  Future<List<BillRankingItem>>? _cachedMonthlyRankingData;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // 初始化时加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshData();
    });
  }

  // 公开的刷新数据方法，供父组件调用
  void refreshData() {
    final viewModel = Provider.of<BillViewModel>(context, listen: false);
    // 重新加载当前选中的月份数据
    viewModel.loadMonthlyData(
      viewModel.selectedYear,
      viewModel.selectedMonth,
      null,
      null,
    );

    // 清除缓存数据，强制重新加载(要放在最后面)
    setState(() {
      _cachedLast6MonthsData = null;
      _cachedMonthlyRankingData = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<BillViewModel>(
      builder: (context, viewModel, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 月份选择器和收支类型切换
              _buildMonthSelector(context, viewModel),
              const SizedBox(height: 16),

              /// 月度摘要
              _buildSummaryCard(viewModel),
              const SizedBox(height: 16),

              /// 近6个月柱状图
              _buildTrendChart(viewModel),
              const SizedBox(height: 16),

              /// 分类统计饼图
              _buildCategoryPieChart(),
              const SizedBox(height: 16),

              /// 月历
              _buildMonthCalendar(),
              const SizedBox(height: 16),

              /// 账单排行
              _buildBillRanking(viewModel),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // 构建月份选择器和收支类型切换
  Widget _buildMonthSelector(BuildContext context, BillViewModel viewModel) {
    return Row(
      children: [
        // 月份选择器
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: GestureDetector(
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    viewModel.getFormattedMonth(
                      viewModel.selectedYear,
                      viewModel.selectedMonth,
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ),

        const Spacer(),

        // 收支类型切换
        StatisticsUtils.buildTypeSelector(_selectedType, (type) {
          setState(() {
            _selectedType = type;

            // 清除缓存数据，强制重新加载
            _cachedLast6MonthsData = null;
            _cachedMonthlyRankingData = null;
          });
        }),
      ],
    );
  }

  // 选择月份
  Future<void> _selectMonth(
    BuildContext context,
    BillViewModel viewModel,
  ) async {
    final selectedDate = await showCustomMonthPicker(
      context: context,
      selectedYear: viewModel.selectedYear,
      selectedMonth: viewModel.selectedMonth,
      onChanged: (date) {
        // 在选择器内部实时更新UI（可选）
        // StatisticsUtils.log('选择了月份: $date');
      },
      firstDate: DateTime(2016),
      lastDate: DateTime(DateTime.now().year + 1),
    );

    if (selectedDate != null && mounted) {
      viewModel.loadMonthlyData(
        selectedDate.year,
        selectedDate.month,
        null,
        null,
      );

      // 清除缓存数据，强制重新加载
      setState(() {
        _cachedLast6MonthsData = null;
        _cachedMonthlyRankingData = null;
      });
    }
  }

  // 构建摘要卡片
  Widget _buildSummaryCard(BillViewModel viewModel) {
    final stats = viewModel.currentStatistics;

    return BillSummaryCard(
      title: '本月收支',
      income: stats?.totalIncome ?? 0,
      expense: stats?.totalExpense ?? 0,
      balance: stats?.netIncome ?? 0,
    );
  }

  // 构建趋势图
  Widget _buildTrendChart(BillViewModel viewModel) {
    return FutureBuilder<List<BarChartData>>(
      future: _getLast6MonthsData(viewModel),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200 + 32 + 23, // 图表+标题
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox(
            height: 200 + 32 + 23, // 图表+标题
            child: Center(child: Text('无法加载近6个月数据')),
          );
        }

        return BarChartWidget(
          data: snapshot.data!,
          title: '6个月趋势',
          height: 200,
          showLegend: true,
          seriesName: _selectedType == 0 ? '收入' : '支出',
          showYAxis: ScreenHelper.isMobile() ? false : true,
          showAnnotations: ScreenHelper.isMobile() ? false : true,
        );
      },
    );
  }

  // 构建分类统计饼图
  Widget _buildCategoryPieChart() {
    return Consumer<BillViewModel>(
      builder: (context, viewModel, _) {
        final stats = viewModel.currentStatistics;
        if (stats != null) {
          return Column(
            children: [
              StatisticsUtils.buildCategoryPieChart(
                stats,
                _selectedType,
                ScreenHelper.isDesktop() ? 350 : 250,
              ),
              const SizedBox(height: 16),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // 构建月历
  Widget _buildMonthCalendar() {
    return Consumer<BillViewModel>(
      builder: (context, viewModel, _) {
        final stats = viewModel.currentStatistics;
        if (stats == null) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            // 上一个月和下一个月切换
            Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 8),
                  child: Text(
                    '${DateFormat(formatToYMzh).format(DateTime(viewModel.selectedYear, viewModel.selectedMonth))}每日数据',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    // 如果当前月是1月，则年份减1，月份为12
                    int currentYear = viewModel.selectedYear;
                    int currentMonth = viewModel.selectedMonth;
                    if (currentMonth == 1) {
                      currentYear--;
                      currentMonth = 12;
                    } else {
                      currentMonth--;
                    }
                    viewModel.loadMonthlyData(
                      currentYear,
                      currentMonth,
                      null,
                      null,
                    );
                    // 清除缓存数据，强制重新加载
                    setState(() {
                      _cachedLast6MonthsData = null;
                      _cachedMonthlyRankingData = null;
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                ),

                IconButton(
                  onPressed: () {
                    // 如果当前月是12月，则年份加1，月份为1
                    int currentYear = viewModel.selectedYear;
                    int currentMonth = viewModel.selectedMonth;
                    if (currentMonth == 12) {
                      currentYear++;
                      currentMonth = 1;
                    } else {
                      currentMonth++;
                    }

                    viewModel.loadMonthlyData(
                      currentYear,
                      currentMonth,
                      null,
                      null,
                    );
                    // 清除缓存数据，强制重新加载
                    setState(() {
                      _cachedLast6MonthsData = null;
                      _cachedMonthlyRankingData = null;
                    });
                  },
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
            MonthCalendarWidget(
              year: viewModel.selectedYear,
              month: viewModel.selectedMonth,
              expenseData: stats.expenseByDate,
              incomeData: stats.incomeByDate,
              selectedType: _selectedType,
              // 因为添加了月历切换，所以不显示标题了
              showTitle: false,
              onDateTap: (date) {
                // 点击日期，弹窗显示当日的账单列表
                StatisticsUtils.navigateToDateBillDialog(
                  context,
                  date,
                  viewModel,
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  // 构建月度排行
  Widget _buildBillRanking(BillViewModel viewModel) {
    return FutureBuilder<List<BillRankingItem>>(
      future: _getMonthlyRankingData(viewModel),
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
          title: _selectedType == 0 ? '月度收入排行Top10' : '月度支出排行Top10',
          maxItems: 10,
          showBorder: false,
          onItemTap: (item) {
            if (item.id != null) {
              StatisticsUtils.navigateToBillDetail(context, item.id!);
            }
          },
        );
      },
    );
  }

  // 获取近6个月数据
  Future<List<BarChartData>> _getLast6MonthsData(BillViewModel viewModel) {
    // 使用缓存
    _cachedLast6MonthsData ??= _fetchLast6MonthsData(viewModel);
    return _cachedLast6MonthsData!;
  }

  // 获取月度账单排行数据
  Future<List<BillRankingItem>> _getMonthlyRankingData(
    BillViewModel viewModel,
  ) {
    // 使用缓存
    _cachedMonthlyRankingData ??= _fetchMonthlyRankingData(viewModel);
    return _cachedMonthlyRankingData!;
  }

  // 实际获取月度排行数据的方法
  Future<List<BillRankingItem>> _fetchMonthlyRankingData(
    BillViewModel viewModel,
  ) async {
    try {
      // 计算月份的开始和结束日期
      final firstDayOfMonth = DateTime(
        viewModel.selectedYear,
        viewModel.selectedMonth,
        1,
      );
      final lastDayOfMonth = DateTime(
        viewModel.selectedYear,
        viewModel.selectedMonth + 1,
        0,
      );

      return StatisticsUtils.getRankingData(
        viewModel: viewModel,
        startDate: firstDayOfMonth,
        endDate: lastDayOfMonth,
        selectedType: _selectedType,
        maxItems: 10,
      );
    } catch (e) {
      StatisticsUtils.log('获取月度排行数据失败: $e');
      return [];
    }
  }

  // 实际获取近6个月数据的方法
  Future<List<BarChartData>> _fetchLast6MonthsData(
    BillViewModel viewModel,
  ) async {
    final List<BarChartData> result = [];

    try {
      // 获取近6个月的统计数据
      final monthsData = await viewModel.getLast6MonthsStatistics();

      // 按日期排序（从旧到新）
      final sortedKeys = monthsData.keys.toList()..sort();

      // 当前选中的月份格式化为键
      final currentMonthKey =
          '${viewModel.selectedYear}-${viewModel.selectedMonth.toString().padLeft(2, '0')}';

      // 生成柱状图数据
      for (var key in sortedKeys) {
        final stats = monthsData[key]!;

        // 根据选择的类型获取数据
        double value =
            _selectedType == 0 ? stats.totalIncome : stats.totalExpense;

        // 提取月份显示
        String monthDisplay;
        String yearPart = '';
        try {
          final parts = key.split('-');
          final year = parts[0];
          final month = int.parse(parts[1]);
          // 如果不是当前年份，显示年份
          if (year != viewModel.selectedYear.toString()) {
            yearPart = '$year年';
          }
          monthDisplay = '$yearPart$month月';
        } catch (e) {
          monthDisplay = key;
        }

        // 添加到结果中，并标记当前选中的月份
        result.add(
          BarChartData(
            category: monthDisplay,
            value: value,
            // 收入红色，支出绿色
            color: _selectedType == 0 ? Colors.red : Colors.green,
            isSelected: key == currentMonthKey, // 标记当前选中的月份
          ),
        );
      }

      return result;
    } catch (e) {
      StatisticsUtils.log('获取近6个月数据失败: $e');
      return [];
    }
  }
}
