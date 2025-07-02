import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/screen_helper.dart';
import '../viewmodels/bill_viewmodel.dart';
import '../widgets/bill_ranking_widget.dart';
import '../widgets/bill_summary_card.dart';
import '../widgets/bar_chart_widget.dart';
import '../widgets/custom_date_pickers.dart';
import '../utils/statistics_utils.dart';

/// 年统计页面
class YearlyStatisticsPage extends StatefulWidget {
  const YearlyStatisticsPage({super.key});
  @override
  State<YearlyStatisticsPage> createState() => YearlyStatisticsPageState();
}

class YearlyStatisticsPageState extends State<YearlyStatisticsPage>
    with AutomaticKeepAliveClientMixin {
  // 当前选中的类型：0-收入，1-支出
  int _selectedType = 1;

  // 缓存加载过的数据
  Future<List<BarChartData>>? _cachedLast6YearsData;
  Future<List<BarChartData>>? _cachedYearlyMonthsData;
  Future<List<BillRankingItem>>? _cachedYearlyRankingData;

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
    // 重新加载当前选中的年份数据
    viewModel.loadYearlyData(viewModel.selectedYear);

    // 清除缓存数据，强制重新加载
    setState(() {
      _cachedLast6YearsData = null;
      _cachedYearlyMonthsData = null;
      _cachedYearlyRankingData = null;
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
              /// 年份选择器和收支类型切换
              _buildYearSelector(context, viewModel),
              const SizedBox(height: 16),

              /// 年度摘要
              _buildSummaryCard(viewModel),
              const SizedBox(height: 16),

              /// 近6年柱状图
              _buildTrendChart(viewModel),
              const SizedBox(height: 16),

              /// 分类统计饼图
              _buildCategoryPieChart(),
              const SizedBox(height: 16),

              /// 年度月份柱状图
              _buildMonthBar(viewModel),
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

  // 构建年份选择器和收支类型切换
  Widget _buildYearSelector(BuildContext context, BillViewModel viewModel) {
    return Row(
      children: [
        // 年份选择器
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: GestureDetector(
            onTap: () => _selectYear(context, viewModel),
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
                    '${viewModel.selectedYear}年',
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
            _cachedLast6YearsData = null;
            _cachedYearlyMonthsData = null;
            _cachedYearlyRankingData = null;
          });
        }),
      ],
    );
  }

  // 构建摘要卡片
  Widget _buildSummaryCard(BillViewModel viewModel) {
    final stats = viewModel.currentStatistics;

    return BillSummaryCard(
      title: '年度收支',
      income: stats?.totalIncome ?? 0,
      expense: stats?.totalExpense ?? 0,
      balance: stats?.netIncome ?? 0,
    );
  }

  Widget _buildTrendChart(BillViewModel viewModel) {
    return FutureBuilder<List<BarChartData>>(
      future: _getLast6YearsData(viewModel),
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
            child: Center(child: Text('无法加载近6年数据')),
          );
        }

        return BarChartWidget(
          data: snapshot.data!,
          title: '6年趋势',
          height: 200,
          seriesName: _selectedType == 0 ? '收入' : '支出',
          showYAxis: ScreenHelper.isMobile() ? false : true,
          showAnnotations: ScreenHelper.isMobile() ? false : true,
        );
      },
    );
  }

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

  Widget _buildMonthBar(BillViewModel viewModel) {
    return FutureBuilder<List<BarChartData>>(
      future: _getYearlyMonthsData(viewModel),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 250 + 32 + 23, // 图表+标题
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox(
            height: 250 + 32 + 23, // 图表+标题
            child: Center(child: Text('无法加载年度月份数据')),
          );
        }

        return BarChartWidget(
          data: snapshot.data!,
          title:
              '${viewModel.selectedYear}年各月${_selectedType == 0 ? '收入' : '支出'}',

          seriesName: _selectedType == 0 ? '收入' : '支出',
          showValue: true,
          // 移动端空间可能不够12个月，所以横向显示
          horizontal: ScreenHelper.isDesktop() ? false : true,
          // 移动端高度为12个月，所以高度为12 * 36
          height: ScreenHelper.isDesktop() ? 250 : 12 * 36,
          showYAxis: true,
          showAnnotations: ScreenHelper.isMobile() ? false : true,
        );
      },
    );
  }

  Widget _buildBillRanking(BillViewModel viewModel) {
    return FutureBuilder<List<BillRankingItem>>(
      future: _getYearlyRankingData(viewModel),
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
          title: _selectedType == 0 ? '年度收入排行Top10' : '年度支出排行Top10',
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

  // 选择年份
  Future<void> _selectYear(
    BuildContext context,
    BillViewModel viewModel,
  ) async {
    final selectedDate = await showCustomYearPicker(
      context: context,
      selectedYear: viewModel.selectedYear,
      onChanged: (date) {
        // 在选择器内部实时更新UI（可选）
        // StatisticsUtils.log('选择了年份: $date');
      },
      firstYear: 2016,
      lastYear: DateTime.now().year + 1,
    );

    if (selectedDate != null && mounted) {
      viewModel.loadYearlyData(selectedDate.year);

      // 清除缓存数据，强制重新加载
      setState(() {
        _cachedLast6YearsData = null;
        _cachedYearlyMonthsData = null;
        _cachedYearlyRankingData = null;
      });
    }
  }

  // 获取近6年数据
  Future<List<BarChartData>> _getLast6YearsData(BillViewModel viewModel) {
    // 使用缓存
    _cachedLast6YearsData ??= _fetchLast6YearsData(viewModel);
    return _cachedLast6YearsData!;
  }

  // 获取年度月份数据
  Future<List<BarChartData>> _getYearlyMonthsData(BillViewModel viewModel) {
    // 使用缓存
    _cachedYearlyMonthsData ??= _fetchYearlyMonthsData(viewModel);
    return _cachedYearlyMonthsData!;
  }

  // 获取年度账单排行数据
  Future<List<BillRankingItem>> _getYearlyRankingData(BillViewModel viewModel) {
    // 使用缓存
    _cachedYearlyRankingData ??= _fetchYearlyRankingData(viewModel);
    return _cachedYearlyRankingData!;
  }

  // 实际获取年度排行数据的方法
  Future<List<BillRankingItem>> _fetchYearlyRankingData(
    BillViewModel viewModel,
  ) async {
    try {
      // 计算年份的开始和结束日期
      final firstDayOfYear = DateTime(viewModel.selectedYear, 1, 1);
      final lastDayOfYear = DateTime(viewModel.selectedYear, 12, 31);

      return StatisticsUtils.getRankingData(
        viewModel: viewModel,
        startDate: firstDayOfYear,
        endDate: lastDayOfYear,
        selectedType: _selectedType,
        maxItems: 10,
      );
    } catch (e) {
      StatisticsUtils.log('获取年度排行数据失败: $e');
      return [];
    }
  }

  // 实际获取近6年数据的方法
  Future<List<BarChartData>> _fetchLast6YearsData(
    BillViewModel viewModel,
  ) async {
    final List<BarChartData> result = [];

    try {
      // 获取近6年的统计数据
      final yearsData = await viewModel.getLast6YearsStatistics();

      // 按年份排序（从旧到新）
      final sortedKeys = yearsData.keys.toList()..sort();

      // 当前选中的年份
      final currentYearKey = viewModel.selectedYear.toString();

      // 生成柱状图数据
      for (var key in sortedKeys) {
        final stats = yearsData[key]!;

        // 根据选择的类型获取数据
        double value =
            _selectedType == 0 ? stats.totalIncome : stats.totalExpense;

        // 添加到结果中，并标记当前选中的年份
        result.add(
          BarChartData(
            category: key,
            value: value,
            // 收入红色，支出绿色
            color: _selectedType == 0 ? Colors.red : Colors.green,
            isSelected: key == currentYearKey, // 标记当前选中的年份
          ),
        );
      }

      return result;
    } catch (e) {
      StatisticsUtils.log('获取近6年数据失败: $e');
      return [];
    }
  }

  // 实际获取年度月份数据的方法
  Future<List<BarChartData>> _fetchYearlyMonthsData(
    BillViewModel viewModel,
  ) async {
    final List<BarChartData> result = [];

    try {
      // 获取当年每月的统计数据
      final monthsData = await viewModel.getYearlyMonthlyStatistics(
        viewModel.selectedYear,
      );

      // 按月份排序
      final sortedKeys = monthsData.keys.toList()..sort();

      // 生成柱状图数据
      for (var key in sortedKeys) {
        final stats = monthsData[key]!;

        // 根据选择的类型获取数据
        double value =
            _selectedType == 0 ? stats.totalIncome : stats.totalExpense;

        // 月份显示
        final month = int.parse(key);

        // 添加到结果中
        result.add(
          BarChartData(
            category: '$month月',
            value: value,
            // 收入红色，支出绿色
            color: _selectedType == 0 ? Colors.red : Colors.green,
            // 显示选中年统计的所有月份数据都是选中状态
            isSelected: true,
          ),
        );
      }

      return result;
    } catch (e) {
      StatisticsUtils.log('获取年度月份数据失败: $e');
      return [];
    }
  }
}
