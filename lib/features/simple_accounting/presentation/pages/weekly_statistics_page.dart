import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/datetime_formatter.dart';
import '../../../../core/utils/screen_helper.dart';
import '../../../../shared/constants/constants.dart';
import '../../domain/entities/bill_statistics.dart';
import '../viewmodels/bill_viewmodel.dart';
import '../widgets/bill_ranking_widget.dart';
import '../widgets/bill_summary_card.dart';
import '../widgets/multi_bar_chart_widget.dart';
import '../widgets/week_calendar_widget.dart';
import '../widgets/custom_date_pickers.dart';
import '../utils/statistics_utils.dart';

/// 周统计页面
class WeeklyStatisticsPage extends StatefulWidget {
  const WeeklyStatisticsPage({super.key});

  @override
  State<WeeklyStatisticsPage> createState() => WeeklyStatisticsPageState();
}

class WeeklyStatisticsPageState extends State<WeeklyStatisticsPage>
    with AutomaticKeepAliveClientMixin {
  // 当前选中的类型：0-收入，1-支出
  int _selectedType = 1;

  // 缓存加载过的数据
  Future<List<MultiBarChartData>>? _cachedWeeklyComparisonData;
  Future<List<BillRankingItem>>? _cachedWeeklyRankingData;

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
  Future<void> refreshData() async {
    // 判断当前统计类型是否为周统计，如果不是，则需要重新计算当前周期
    final viewModel = Provider.of<BillViewModel>(context, listen: false);

    // 如果当前不是周统计或没有数据，需要加载当前周数据
    if (viewModel.currentStatisticsType != 'week' ||
        viewModel.currentStatistics == null) {
      // 计算本周的开始和结束日期(周日到周六)
      final now = DateTime.now();
      // 计算本周的周日
      final weekStart = now.subtract(Duration(days: now.weekday % 7));
      final weekEnd = weekStart.add(const Duration(days: 6)); // 周六

      await viewModel.loadWeeklyData(weekStart, weekEnd);
    }

    // 首先清除缓存数据，强制重新加载
    // 要放在最后面，否则周对比柱状图数据本周的可以就不对
    setState(() {
      _cachedWeeklyComparisonData = null;
      _cachedWeeklyRankingData = null;
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
              /// 周选择器和收支类型切换
              _buildWeekSelector(context, viewModel),
              const SizedBox(height: 16),

              /// 周摘要
              _buildSummaryCard(viewModel),
              const SizedBox(height: 16),

              /// 本周和上周对比柱状图
              _buildWeeklyComparisonChart(viewModel),
              const SizedBox(height: 16),

              /// 周历
              _buildWeekCalendar(viewModel),
              const SizedBox(height: 16),

              /// 分类统计饼图
              _buildCategoryPieChart(viewModel),
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

  // 构建周选择器和收支类型切换
  Widget _buildWeekSelector(BuildContext context, BillViewModel viewModel) {
    return Row(
      children: [
        // 周选择器
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: GestureDetector(
            onTap: () => _selectWeek(context, viewModel),
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
                    viewModel.getFormattedWeek(
                      viewModel.weekStartDate,
                      viewModel.weekEndDate,
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
            _cachedWeeklyComparisonData = null;
            _cachedWeeklyRankingData = null;
          });
        }),
      ],
    );
  }

  // 构建摘要卡片
  Widget _buildSummaryCard(BillViewModel viewModel) {
    final stats = viewModel.currentStatistics;

    return BillSummaryCard(
      title: '本周收支',
      income: stats?.totalIncome ?? 0,
      expense: stats?.totalExpense ?? 0,
      balance: stats?.netIncome ?? 0,
    );
  }

  Widget _buildWeeklyComparisonChart(BillViewModel viewModel) {
    return FutureBuilder<List<MultiBarChartData>>(
      future: _getWeeklyComparisonData(viewModel),
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
            child: Center(child: Text('无法加载对比数据')),
          );
        }

        return MultiBarChartWidget(
          data: snapshot.data!,
          title: '本周与上周对比',
          series1Name: '上周',
          series2Name: '本周',
          series1Color: Colors.grey,
          series2Color: Colors.blue,
          height: 200,

          // showValue: ScreenHelper.isMobile() ? false : true,
        );
      },
    );
  }

  Widget _buildWeekCalendar(BillViewModel viewModel) {
    return Consumer<BillViewModel>(
      builder: (context, viewModel, _) {
        final stats = viewModel.currentStatistics;

        if (stats == null) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            // 上一周和下一周切换
            Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 8),
                  child: Text(
                    '${formatToYearWeek(viewModel.weekStartDate)}账单列表',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () async {
                    // 获取上一周的开始和结束日期
                    final lastWeekStart = viewModel.weekStartDate.subtract(
                      const Duration(days: 7),
                    );
                    final lastWeekEnd = viewModel.weekEndDate.subtract(
                      const Duration(days: 7),
                    );

                    // 注意，这里不使用await可能没有立刻得到本周的数据，导致对比柱状图数据不全
                    await viewModel.loadWeeklyData(lastWeekStart, lastWeekEnd);
                    // 清除缓存数据，强制重新加载
                    if (mounted) {
                      setState(() {
                        _cachedWeeklyComparisonData = null;
                        _cachedWeeklyRankingData = null;
                      });
                    }
                  },
                  icon: const Icon(Icons.arrow_back),
                ),

                IconButton(
                  onPressed: () async {
                    // 获取下一周的开始和结束日期
                    final nextWeekStart = viewModel.weekStartDate.add(
                      const Duration(days: 7),
                    );
                    final nextWeekEnd = viewModel.weekEndDate.add(
                      const Duration(days: 7),
                    );

                    await viewModel.loadWeeklyData(nextWeekStart, nextWeekEnd);
                    // 清除缓存数据，强制重新加载
                    if (mounted) {
                      setState(() {
                        _cachedWeeklyComparisonData = null;
                        _cachedWeeklyRankingData = null;
                      });
                    }
                  },
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
            ),

            WeekCalendarWidget(
              startDate: viewModel.weekStartDate,
              expenseData: stats.expenseByDate,
              incomeData: stats.incomeByDate,
              selectedType: _selectedType,
              // 因为添加了周历切换，所以不显示标题了
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

  Widget _buildCategoryPieChart(BillViewModel viewModel) {
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

  Widget _buildBillRanking(BillViewModel viewModel) {
    return FutureBuilder<List<BillRankingItem>>(
      future: _getWeeklyRankingData(viewModel),
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
          title: _selectedType == 0 ? '周度收入排行Top10' : '周度支出排行Top10',
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

  // 选择周
  Future<void> _selectWeek(
    BuildContext context,
    BillViewModel viewModel,
  ) async {
    final result = await showCustomWeekPicker(
      context: context,
      selectedDate: viewModel.weekStartDate,
      onChanged: (period) {
        // StatisticsUtils.log('选择了周: ${period.start} ~ ${period.end}');
      },
      firstDate: DateTime(2016),
      lastDate: DateTime(DateTime.now().year + 1),
      dateFormat: DateFormat(formatToYMDzh),
    );

    if (result != null && mounted) {
      // 确保设置currentStatisticsType为'week'
      await viewModel.loadWeeklyData(result.start, result.end);

      // 清除缓存数据，强制重新加载
      setState(() {
        _cachedWeeklyComparisonData = null;
        _cachedWeeklyRankingData = null;
      });
    }
  }

  // 获取周对比数据
  Future<List<MultiBarChartData>> _getWeeklyComparisonData(
    BillViewModel viewModel,
  ) {
    _cachedWeeklyComparisonData ??= _fetchWeeklyComparisonData(viewModel);
    return _cachedWeeklyComparisonData!;
  }

  // 获取周账单排行数据
  Future<List<BillRankingItem>> _getWeeklyRankingData(BillViewModel viewModel) {
    // 使用缓存
    _cachedWeeklyRankingData ??= StatisticsUtils.getRankingData(
      viewModel: viewModel,
      startDate: viewModel.weekStartDate,
      endDate: viewModel.weekEndDate,
      selectedType: _selectedType,
      maxItems: 10,
    );
    return _cachedWeeklyRankingData!;
  }

  // 实际获取周对比数据的方法
  Future<List<MultiBarChartData>> _fetchWeeklyComparisonData(
    BillViewModel viewModel,
  ) async {
    final List<MultiBarChartData> result = [];

    // 当前周的日期范围
    final currentWeekStart = viewModel.weekStartDate;
    final currentWeekEnd = viewModel.weekEndDate;

    // 上一周的日期范围
    final lastWeekStart = currentWeekStart.subtract(const Duration(days: 7));
    final lastWeekEnd = currentWeekEnd.subtract(const Duration(days: 7));

    try {
      // 1. 获取当前周的统计数据
      final currentStats =
          viewModel.currentStatistics ?? BillStatistics.empty();

      // 2. 获取上周的统计数据
      final lastWeekStats = await viewModel.getWeeklyStatistics(
        lastWeekStart,
        lastWeekEnd,
      );

      // 生成每天的对比数据
      for (int i = 0; i < 7; i++) {
        final currentDate = currentWeekStart.add(Duration(days: i));
        final lastWeekDate = lastWeekStart.add(Duration(days: i));

        final currentDateStr = DateFormat(formatToYMD).format(currentDate);
        final lastWeekDateStr = DateFormat(formatToYMD).format(lastWeekDate);

        // 根据选择的类型获取数据
        double currentValue = 0;
        double lastWeekValue = 0;

        if (_selectedType == 0) {
          // 收入
          currentValue = currentStats.incomeByDate[currentDateStr] ?? 0;
          lastWeekValue = lastWeekStats.incomeByDate[lastWeekDateStr] ?? 0;
        } else {
          // 支出
          currentValue = currentStats.expenseByDate[currentDateStr] ?? 0;
          lastWeekValue = lastWeekStats.expenseByDate[lastWeekDateStr] ?? 0;
        }

        // 添加到结果中
        result.add(
          MultiBarChartData(
            category: DateFormat('E', 'zh_CN').format(currentDate),
            value1: lastWeekValue,
            value2: currentValue,
          ),
        );
      }

      return result;
    } catch (e) {
      StatisticsUtils.log('获取周对比数据失败: $e');
      return [];
    }
  }
}
