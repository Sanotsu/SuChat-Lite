import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

import '../../../../core/viewmodels/user_info_viewmodel.dart';
import '../../../../shared/constants/constants.dart';
import '../viewmodels/diet_diary_viewmodel.dart';
import '../widgets/scrollable_chart.dart';
import 'weight_trend_page.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late UserInfoViewModel _userViewModel;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _endDate = DateTime.now();

  List<Map<String, dynamic>> _nutritionData = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _userViewModel = Provider.of<UserInfoViewModel>(context, listen: false);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final viewModel = Provider.of<DietDiaryViewModel>(context, listen: false);
      _nutritionData = await viewModel.getNutritionDataByDateRange(
        _startDate,
        _endDate,
      );

      if (_nutritionData.isEmpty) {
        setState(() {
          _error = '所选时间段内没有数据';
          _isLoading = false;
        });
        return;
      }

      // 处理数据，确保每个日期都有数据
      _processNutritionData();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载数据失败: $e';
        _isLoading = false;
      });
    }
  }

  void _processNutritionData() {
    // 确保每一天都有数据，如果没有则填充零值
    final Map<String, Map<String, dynamic>> dateMap = {};

    // 先将已有数据放入 Map 中
    for (var data in _nutritionData) {
      final dateString = (data['date'] as String).split('T')[0];
      dateMap[dateString] = data;
    }

    // 清空原数据列表，准备重新填充
    _nutritionData = [];

    // 遍历日期范围内的每一天
    for (
      DateTime date = _startDate;
      !date.isAfter(_endDate);
      date = date.add(const Duration(days: 1))
    ) {
      final dateString = date.toIso8601String().split('T')[0];

      if (dateMap.containsKey(dateString)) {
        // 使用已有数据
        _nutritionData.add(dateMap[dateString]!);
      } else {
        // 填充零值数据
        _nutritionData.add({
          'date': dateString,
          'totalCalories': 0.0,
          'totalCarbs': 0.0,
          'totalProtein': 0.0,
          'totalFat': 0.0,
        });
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      saveText: '确定',
      cancelText: '取消',
      confirmText: '确定',
      locale: const Locale('zh', 'CN'),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('图表统计'),
        actions: [
          IconButton(
            icon: const Icon(Icons.monitor_weight_rounded),
            tooltip: '体重趋势',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WeightTrendPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 日期范围选择器
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
            child: Row(
              children: [
                const Icon(Icons.date_range),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${DateFormat(formatToYMD).format(_startDate)} 至 ${DateFormat(formatToYMD).format(_endDate)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: _selectDateRange,
                  child: const Text('选择日期'),
                ),
              ],
            ),
          ),

          // 图表内容
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error?.isNotEmpty == true
                    ? Center(child: Text(_error!))
                    : _nutritionData.isEmpty
                    ? const Center(child: Text('没有数据'))
                    : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildCaloriesChart(),
                            _buildCaloriesDeficitChart(),
                            _buildNutrientsChart(),
                            _buildCaloriesSummary(),
                            _buildNutrientsSummary(),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesChart() {
    // 获取用户目标热量
    final targetCalories =
        _userViewModel.dailyRecommendedIntake?.calories ?? 0.0;

    // 准备图表系列
    List<CartesianSeries> series = [
      // 实际热量摄入柱状图
      ColumnSeries<Map<String, dynamic>, String>(
        name: '实际摄入',
        dataSource: _nutritionData,
        xValueMapper:
            (Map<String, dynamic> data, _) => DateFormat(
              formatToMD,
            ).format(DateTime.parse(data['date'].toString())),
        yValueMapper:
            (Map<String, dynamic> data, _) =>
                (data['totalCalories'] as num?)?.toDouble() ?? 0.0,
        color: Colors.blue,
        dataLabelSettings: const DataLabelSettings(isVisible: true),
        width: 0.8, // 设置柱状图宽度
        spacing: 0.2, // 设置柱状图间距
      ),
    ];

    // 如果有目标热量，添加目标线
    if (targetCalories > 0) {
      series.add(
        LineSeries<Map<String, dynamic>, String>(
          name: '目标摄入',
          dataSource: _nutritionData,
          xValueMapper:
              (Map<String, dynamic> data, _) => DateFormat(
                formatToMD,
              ).format(DateTime.parse(data['date'].toString())),
          yValueMapper: (Map<String, dynamic> data, _) => targetCalories,
          color: Colors.red,
          markerSettings: const MarkerSettings(isVisible: true),
        ),
      );
    }

    return ScrollableChart(
      title: '热量摄入(千卡)',
      height: 300,
      series: series,
      xAxis: CategoryAxis(
        labelRotation: -45,
        labelStyle: const TextStyle(fontSize: 10),
      ),
      yAxis: NumericAxis(
        title: AxisTitle(text: '热量 (千卡)'),
        numberFormat: NumberFormat('###,###'),
        // 不显示y轴标签，让表格有更多空间
        isVisible: false,
      ),
    );
  }

  Widget _buildCaloriesDeficitChart() {
    // 获取用户目标热量
    final targetCalories =
        _userViewModel.dailyRecommendedIntake?.calories ?? 0.0;
    if (targetCalories <= 0) return const SizedBox.shrink();

    // 计算每日热量缺口
    List<Map<String, dynamic>> deficitData = [];
    for (var data in _nutritionData) {
      final calories = (data['totalCalories'] as num?)?.toDouble() ?? 0.0;
      final deficit = targetCalories - calories;
      deficitData.add({
        'date': data['date'],
        'deficit': deficit,
        'isPositive': deficit >= 0,
      });
    }

    return ScrollableChart(
      title: '热量缺口(千卡)',
      description: '正值表示热量不足（有助于减重），负值表示热量过剩（有助于增重）',
      height: 300,
      series: [
        ColumnSeries<Map<String, dynamic>, String>(
          name: '热量缺口',
          dataSource: deficitData,
          xValueMapper:
              (Map<String, dynamic> data, _) => DateFormat(
                formatToMD,
              ).format(DateTime.parse(data['date'].toString())),
          yValueMapper: (Map<String, dynamic> data, _) => data['deficit'],
          pointColorMapper:
              (Map<String, dynamic> data, _) =>
                  (data['isPositive'] as bool) ? Colors.green : Colors.red,
          dataLabelSettings: const DataLabelSettings(isVisible: true),
          width: 0.8, // 设置柱状图宽度
          spacing: 0.2, // 设置柱状图间距
        ),
      ],
      xAxis: CategoryAxis(
        labelRotation: -45,
        labelStyle: const TextStyle(fontSize: 10),
      ),
      yAxis: NumericAxis(
        title: AxisTitle(text: '热量缺口 (千卡)'),
        numberFormat: NumberFormat('###,###'),
        // 不显示y轴标签，让表格有更多空间
        isVisible: false,
      ),
    );
  }

  Widget _buildNutrientsChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '营养素平均比例(克)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: SfCircularChart(
                legend: Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                ),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <CircularSeries>[
                  DoughnutSeries<Map<String, dynamic>, String>(
                    radius: '70%',
                    innerRadius: '50%',
                    dataSource: _calculateAverageNutrients(),
                    xValueMapper:
                        (Map<String, dynamic> data, _) =>
                            data['name'] as String,
                    yValueMapper:
                        (Map<String, dynamic> data, _) =>
                            data['value'] as double,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                    ),
                    pointColorMapper:
                        (Map<String, dynamic> data, _) =>
                            data['color'] as Color,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _calculateAverageNutrients() {
    if (_nutritionData.isEmpty) {
      return [];
    }

    double totalCarbs = 0;
    double totalProtein = 0;
    double totalFat = 0;

    for (var data in _nutritionData) {
      totalCarbs += (data['totalCarbs'] as num?)?.toDouble() ?? 0;
      totalProtein += (data['totalProtein'] as num?)?.toDouble() ?? 0;
      totalFat += (data['totalFat'] as num?)?.toDouble() ?? 0;
    }

    final double avgCarbs = totalCarbs / _nutritionData.length;
    final double avgProtein = totalProtein / _nutritionData.length;
    final double avgFat = totalFat / _nutritionData.length;

    // 计算总克数
    final double totalGrams = avgCarbs + avgProtein + avgFat;

    // 避免除以零
    if (totalGrams <= 0) {
      return [
        {'name': '碳水化合物 (0%)', 'value': 1.0, 'color': Colors.amber},
        {'name': '蛋白质 (0%)', 'value': 1.0, 'color': Colors.blue},
        {'name': '脂肪 (0%)', 'value': 1.0, 'color': Colors.red},
      ];
    }

    // 计算百分比
    final double carbsPercent = (avgCarbs / totalGrams) * 100;
    final double proteinPercent = (avgProtein / totalGrams) * 100;
    final double fatPercent = (avgFat / totalGrams) * 100;

    return [
      {
        'name': '碳水化合物 (${carbsPercent.toStringAsFixed(0)}%)',
        'value': double.parse(avgCarbs.toStringAsFixed(1)),
        'color': Colors.amber,
      },
      {
        'name': '蛋白质 (${proteinPercent.toStringAsFixed(0)}%)',
        'value': double.parse(avgProtein.toStringAsFixed(1)),
        'color': Colors.blue,
      },
      {
        'name': '脂肪 (${fatPercent.toStringAsFixed(0)}%)',
        'value': double.parse(avgFat.toStringAsFixed(1)),
        'color': Colors.red,
      },
    ];
  }

  Widget _buildCaloriesSummary() {
    if (_nutritionData.isEmpty) {
      return const SizedBox.shrink();
    }

    double totalCalories = 0;
    double maxCalories = 0;
    double minCalories = double.infinity;
    DateTime? maxDate;
    DateTime? minDate;

    for (var data in _nutritionData) {
      final calories = (data['totalCalories'] as num?)?.toDouble() ?? 0;
      totalCalories += calories;

      if (calories > maxCalories) {
        maxCalories = calories;
        maxDate = DateTime.parse(data['date'].toString());
      }

      if (calories < minCalories && calories > 0) {
        minCalories = calories;
        minDate = DateTime.parse(data['date'].toString());
      }
    }

    // 如果没有找到最小值，设为0
    if (minCalories == double.infinity) {
      minCalories = 0;
    }

    final avgCalories = totalCalories / _nutritionData.length;

    // 计算平均热量缺口
    final targetCalories =
        _userViewModel.dailyRecommendedIntake?.calories ?? 0.0;
    final avgDeficit = targetCalories - avgCalories;
    final deficitText =
        avgDeficit >= 0
            ? '平均每日热量缺口: ${avgDeficit.toStringAsFixed(0)} 千卡'
            : '平均每日热量过剩: ${(-avgDeficit).toStringAsFixed(0)} 千卡';
    final deficitColor = avgDeficit >= 0 ? Colors.green : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '热量摄入摘要',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSummaryItem(
              '平均热量摄入',
              '${avgCalories.toStringAsFixed(0)} 千卡/天',
              Icons.calculate,
              Colors.purple,
            ),
            if (targetCalories > 0)
              _buildSummaryItem(
                '目标热量摄入',
                '${targetCalories.toStringAsFixed(0)} 千卡/天',
                Icons.flag,
                Colors.blue,
              ),
            if (targetCalories > 0)
              _buildSummaryItem(
                '平均热量缺口',
                deficitText,
                avgDeficit >= 0 ? Icons.trending_down : Icons.trending_up,
                deficitColor,
              ),
            _buildSummaryItem(
              '最高热量摄入',
              '${maxCalories.toStringAsFixed(0)} 千卡 (${maxDate != null ? DateFormat(formatToMD).format(maxDate) : "无"})',
              Icons.arrow_upward,
              Colors.red,
            ),
            _buildSummaryItem(
              '最低热量摄入',
              '${minCalories.toStringAsFixed(0)} 千卡 (${minDate != null ? DateFormat(formatToMD).format(minDate) : "无"})',
              Icons.arrow_downward,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientsSummary() {
    if (_nutritionData.isEmpty) {
      return const SizedBox.shrink();
    }

    double totalCarbs = 0;
    double totalProtein = 0;
    double totalFat = 0;

    for (var data in _nutritionData) {
      totalCarbs += (data['totalCarbs'] as num?)?.toDouble() ?? 0;
      totalProtein += (data['totalProtein'] as num?)?.toDouble() ?? 0;
      totalFat += (data['totalFat'] as num?)?.toDouble() ?? 0;
    }

    final double avgCarbs = totalCarbs / _nutritionData.length;
    final double avgProtein = totalProtein / _nutritionData.length;
    final double avgFat = totalFat / _nutritionData.length;

    // 获取用户推荐摄入量
    final recommendedIntake = _userViewModel.dailyRecommendedIntake;
    final targetCarbs = recommendedIntake?.carbs ?? 0.0;
    final targetProtein = recommendedIntake?.protein ?? 0.0;
    final targetFat = recommendedIntake?.fat ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '营养素摄入摘要',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSummaryItem(
              '平均碳水化合物',
              '${avgCarbs.toStringAsFixed(1)} 克/天 ${targetCarbs > 0 ? "(目标: ${targetCarbs.toStringAsFixed(0)} 克)" : ""}',
              Icons.grain,
              Colors.amber,
            ),
            _buildSummaryItem(
              '平均蛋白质',
              '${avgProtein.toStringAsFixed(1)} 克/天 ${targetProtein > 0 ? "(目标: ${targetProtein.toStringAsFixed(0)} 克)" : ""}',
              Icons.fitness_center,
              Colors.blue,
            ),
            _buildSummaryItem(
              '平均脂肪',
              '${avgFat.toStringAsFixed(1)} 克/天 ${targetFat > 0 ? "(目标: ${targetFat.toStringAsFixed(0)} 克)" : ""}',
              Icons.opacity,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
