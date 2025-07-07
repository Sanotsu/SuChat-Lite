import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/screen_helper.dart';
import '../../../../shared/constants/constants.dart';
import '../../domain/entities/bill_statistics.dart';
import '../widgets/bill_ranking_widget.dart';
import '../widgets/pie_chart_widget.dart';
import '../viewmodels/bill_viewmodel.dart';
import '../pages/bill_detail_page.dart';

/// 统计工具类，提供各种统计页面通用的方法
class StatisticsUtils {
  /// 添加日志方法
  static void log(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  /// 构建分类饼图
  static Widget buildCategoryPieChart(
    BillStatistics stats,
    int selectedType,
    double height,
  ) {
    // 根据选择的类型获取分类数据
    final Map<String, double> categoryData =
        selectedType == 0 ? stats.incomeByCategory : stats.expenseByCategory;

    if (categoryData.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(child: Text('暂无${selectedType == 0 ? "收入" : "支出"}分类数据')),
      );
    }

    // 计算总金额
    final total = selectedType == 0 ? stats.totalIncome : stats.totalExpense;

    // 构建饼图数据
    final List<PieChartData> pieData =
        categoryData.entries.map((entry) {
          final percentage = total > 0 ? (entry.value / total) * 100 : 0;

          // 生成随机颜色（实际应用中可以使用预定义的颜色列表）
          final color = Color.fromARGB(
            255,
            100 + (entry.key.hashCode % 155),
            100 + ((entry.key.hashCode * 2) % 155),
            100 + ((entry.key.hashCode * 3) % 155),
          );

          return PieChartData(
            category: entry.key,
            value: entry.value,
            percentage: percentage.toDouble(),
            color: color,
          );
        }).toList();

    // 按金额排序
    pieData.sort((a, b) => b.value.compareTo(a.value));

    return PieChartWidget(
      data: pieData,
      title: selectedType == 0 ? '收入分类统计' : '支出分类统计',
      height: height,
    );
  }

  /// 获取账单排行数据
  static Future<List<BillRankingItem>> getRankingData({
    required BillViewModel viewModel,
    required DateTime startDate,
    required DateTime endDate,
    int? selectedType,
    int maxItems = 10,
  }) async {
    try {
      // 获取日期范围内的账单排行
      final bills = await viewModel.getBillRanking(
        startDate: startDate,
        endDate: endDate,
        itemType: selectedType,
        maxItems: maxItems,
      );

      // 转换为排行项
      return bills.map((bill) {
        return BillRankingItem(
          name: bill.item,
          category: bill.category,
          amount: bill.value,
          date: DateTime.parse(bill.date),
          type: bill.itemType,
          id: bill.billItemId,
        );
      }).toList();
    } catch (e) {
      log('获取排行数据失败: $e');
      return [];
    }
  }

  /// 跳转到账单详情页面
  static void navigateToBillDetail(BuildContext context, int billItemId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillDetailPage(billItemId: billItemId),
      ),
    );
  }

  /// 跳转到指定日期的账单列表弹窗
  static void navigateToDateBillDialog(
    BuildContext context,
    DateTime date,
    BillViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => Center(
            // 使用Center包裹使弹窗居中
            child: Container(
              // 设置宽度为屏幕宽度的80%
              width:
                  MediaQuery.of(context).size.width *
                  (ScreenHelper.isDesktop() ? 0.5 : 0.9),
              height: MediaQuery.of(context).size.height * 0.5,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12), // 圆角
              ),
              child: FutureBuilder<List<BillRankingItem>>(
                future: StatisticsUtils.getRankingData(
                  viewModel: viewModel,
                  startDate: date,
                  endDate: date,
                  maxItems: 0,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('暂无排行数据'));
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min, // 使Column尽可能小
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '${DateFormat(formatToYMDzh).format(date)}账单列表',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Expanded(
                        // 使用Expanded使列表可滚动
                        child: SingleChildScrollView(
                          // 添加滚动
                          child: Material(
                            child: BillRankingWidget(
                              items: snapshot.data!,
                              maxItems: 10,
                              showTitle: false,
                              showBorder: false,
                              // 因为弹窗包含了整个账单列表，所以要显示+/-符号
                              showSymbol: true,
                              // onItemTap: (item) {
                              //   if (item.id != null) {
                              //     StatisticsUtils.navigateToBillDetail(
                              //       context,
                              //       item.id!,
                              //     );
                              //   }
                              // },
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextButton(
                          child: const Text('确定'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
    );
  }

  /// 构建收支类型切换按钮
  static Widget buildTypeSelector(
    int selectedType,
    Function(int) onTypeChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // 支出按钮，绿色
          InkWell(
            onTap: () {
              if (selectedType != 1) {
                onTypeChanged(1);
              }
            },
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selectedType == 1 ? Colors.green : null,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(20),
                ),
              ),
              child: Text(
                '支出',
                style: TextStyle(
                  color: selectedType == 1 ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 收入按钮，红色
          InkWell(
            onTap: () {
              if (selectedType != 0) {
                onTypeChanged(0);
              }
            },
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selectedType == 0 ? Colors.red : null,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(20),
                ),
              ),
              child: Text(
                '收入',
                style: TextStyle(
                  color: selectedType == 0 ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 获取按月汇总数据
  static Future<Map<String, BillStatistics>> getMonthlySummaryData(
    BillViewModel viewModel, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final Map<String, BillStatistics> result = {};

    try {
      // 获取账单日期范围
      if (startDate == null || endDate == null) {
        final dateRange = await viewModel.loadBillDateRange();
        startDate = dateRange[0];
        endDate = dateRange[1];
      }

      // 计算月份范围
      DateTime current = DateTime(startDate.year, startDate.month);
      final lastMonth = DateTime(endDate.year, endDate.month);

      // 遍历每个月份
      while (!current.isAfter(lastMonth)) {
        final year = current.year;
        final month = current.month;

        // 获取月度统计数据
        final stats = await viewModel.getMonthlyStatistics(year, month);

        // 使用格式化的月份作为键 (YYYY-MM)
        final key = '$year-${month.toString().padLeft(2, '0')}';

        // 只添加有数据的月份
        if (stats.totalIncome > 0 || stats.totalExpense > 0) {
          result[key] = stats;
        }

        // 移到下一个月
        if (month == 12) {
          current = DateTime(year + 1, 1);
        } else {
          current = DateTime(year, month + 1);
        }
      }

      return result;
    } catch (e) {
      log('获取月度汇总数据失败: $e');
      return {};
    }
  }

  /// 获取按年汇总数据
  static Future<Map<String, BillStatistics>> getYearlySummaryData(
    BillViewModel viewModel, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final Map<String, BillStatistics> result = {};

    try {
      // 获取账单日期范围
      if (startDate == null || endDate == null) {
        final dateRange = await viewModel.loadBillDateRange();
        startDate = dateRange[0];
        endDate = dateRange[1];
      }

      final startYear = startDate.year;
      final endYear = endDate.year;

      // 遍历每一年
      for (int year = startYear; year <= endYear; year++) {
        // 获取年度统计数据
        final stats = await viewModel.getYearlyStatistics(year);

        // 使用年份作为键
        final key = year.toString();

        // 只添加有数据的年份
        if (stats.totalIncome > 0 || stats.totalExpense > 0) {
          result[key] = stats;
        }
      }

      return result;
    } catch (e) {
      log('获取年度汇总数据失败: $e');
      return {};
    }
  }
}
