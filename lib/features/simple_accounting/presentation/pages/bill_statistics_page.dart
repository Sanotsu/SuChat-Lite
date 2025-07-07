import 'package:flutter/material.dart';

import '../pages/free_statistics_page.dart';
import '../pages/weekly_statistics_page.dart';
import '../pages/monthly_statistics_page.dart';
import '../pages/yearly_statistics_page.dart';

/// 账单统计页面
class BillStatisticsPage extends StatefulWidget {
  const BillStatisticsPage({super.key});

  @override
  State<BillStatisticsPage> createState() => _BillStatisticsPageState();
}

class _BillStatisticsPageState extends State<BillStatisticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 用于通知子页面刷新数据的key
  final GlobalKey<WeeklyStatisticsPageState> _weeklyKey =
      GlobalKey<WeeklyStatisticsPageState>();
  final GlobalKey<MonthlyStatisticsPageState> _monthlyKey =
      GlobalKey<MonthlyStatisticsPageState>();
  final GlobalKey<YearlyStatisticsPageState> _yearlyKey =
      GlobalKey<YearlyStatisticsPageState>();
  final GlobalKey<FreeStatisticsPageState> _freeKey =
      GlobalKey<FreeStatisticsPageState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // 添加tab切换监听
    _tabController.addListener(_handleTabChange);

    // 不在这里加载数据，让各个子页面自己负责数据加载
    // 这可以避免父页面状态变化导致的整体闪烁
  }

  // 处理tab切换事件
  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      // 当tab切换完成后，通知当前tab页面刷新数据
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        switch (_tabController.index) {
          case 0:
            _weeklyKey.currentState?.refreshData();
            break;
          case 1:
            _monthlyKey.currentState?.refreshData();
            break;
          case 2:
            _yearlyKey.currentState?.refreshData();
            break;
          case 3:
            _freeKey.currentState?.refreshData();
            break;
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('账单统计'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '周统计'),
            Tab(text: '月统计'),
            Tab(text: '年统计'),
            Tab(text: '更多统计'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        // 使用独立的统计页面组件
        children: [
          // 周统计
          WeeklyStatisticsPage(key: _weeklyKey),

          // 月统计
          MonthlyStatisticsPage(key: _monthlyKey),

          // 年统计
          YearlyStatisticsPage(key: _yearlyKey),

          // 更多统计
          FreeStatisticsPage(key: _freeKey),
        ],
      ),
    );
  }
}
