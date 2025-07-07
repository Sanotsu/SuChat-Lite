import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widgets/multi_bar_chart_widget.dart';
import '../../domain/entities/bill_statistics.dart';
import '../../../../core/utils/screen_helper.dart';

/// 汇总多柱状图组件
/// 用于显示按月或按年的收入、支出、结余对比
class SummaryMultiBarChart extends StatefulWidget {
  /// 统计数据映射，键为月份或年份，值为对应的统计数据
  final Map<String, BillStatistics> statisticsMap;

  /// 图表标题
  final String title;

  /// 图表高度
  final double height;

  /// 是否为月度汇总，false表示年度汇总
  final bool isMonthly;

  /// 是否显示图表标题
  final bool showTitle;

  /// 每个柱子的固定宽度
  final double barWidth;

  const SummaryMultiBarChart({
    super.key,
    required this.statisticsMap,
    required this.title,
    this.height = 350,
    this.isMonthly = true,
    this.showTitle = true,
    this.barWidth = 60, // 默认每个柱子宽度为60
  });

  @override
  State<SummaryMultiBarChart> createState() => _SummaryMultiBarChartState();
}

class _SummaryMultiBarChartState extends State<SummaryMultiBarChart> {
  /// 当前缩放比例
  double _scale = 1.0;

  /// 最小缩放比例
  double _minScale = 0.5;

  /// 最大缩放比例
  final double _maxScale = 1.0;

  /// 水平滚动控制器
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 计算最小缩放比例，使所有柱子都能在屏幕上显示
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.statisticsMap.isEmpty) return;

      final chartData = _prepareChartData();
      if (chartData.isEmpty) return;

      // 获取屏幕宽度
      final screenWidth = MediaQuery.of(context).size.width;
      // 计算所有柱子总宽度
      final totalWidth = chartData.length * widget.barWidth;

      // 如果总宽度大于屏幕宽度，计算最小缩放比例
      if (totalWidth > screenWidth) {
        setState(() {
          _minScale = screenWidth / totalWidth;
          // 初始缩放比例设为最小值，以便用户可以看到全部数据
          _scale = _minScale;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.statisticsMap.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: Text('暂无汇总数据')),
      );
    }

    // 转换数据为MultiBarChartData格式
    final chartData = _prepareChartData();

    // 计算当前图表宽度
    final totalWidth = chartData.length * widget.barWidth;
    final scaledWidth = totalWidth * _scale;

    // 判断是否需要显示滚动条
    final bool needScrollbar = scaledWidth > MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              widget.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

        // 显示累计数据
        _buildTotalSummary(),

        // 添加滑块控制缩放
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.zoom_out, size: 16),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4.0,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8.0,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14.0,
                        ),
                      ),
                      child: Slider(
                        value: _scale,
                        min: _minScale,
                        max: _maxScale,
                        divisions: 20,
                        label: '缩放: ${(_scale * 100).toStringAsFixed(0)}%',
                        onChanged: (value) {
                          setState(() {
                            _scale = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const Icon(Icons.zoom_in, size: 16),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '拖动滑块可缩放图表',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (needScrollbar)
                    const Text(
                      '← 左右滚动查看更多 →',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // 使用Scrollbar包装SingleChildScrollView，显示滚动条
        Scrollbar(
          controller: _scrollController,
          // 在桌面端总是显示滚动条，在移动端根据需要显示
          thumbVisibility: ScreenHelper.isDesktop() && needScrollbar,
          thickness: ScreenHelper.isDesktop() ? 8.0 : 4.0,
          radius: const Radius.circular(4.0),
          interactive: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              // 使用缩放后的宽度
              width: scaledWidth,
              child: MultiBarChartWidget(
                data: chartData,
                height: widget.height,
                showTitle: false,
                series1Name: '支出',
                series2Name: '收入',
                // 支出为绿色，收入为红色
                series1Color: Colors.green,
                series2Color: Colors.red,
                showLegend: true,
                showValue: true,
                enableScrollMode: true, // 启用横向滚动模式
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 准备图表数据
  List<MultiBarChartData> _prepareChartData() {
    final List<MultiBarChartData> result = [];

    // 获取所有键并排序
    final keys = widget.statisticsMap.keys.toList();
    keys.sort();

    for (var key in keys) {
      final stats = widget.statisticsMap[key]!;

      // 格式化标签
      String displayLabel;
      if (widget.isMonthly) {
        // 月度标签格式：2023-01 -> 2023年01月
        final parts = key.split('-');
        if (parts.length == 2) {
          displayLabel = '${parts[0]}年${parts[1]}月';
        } else {
          displayLabel = key;
        }
      } else {
        // 年度标签格式：2023 -> 2023年
        displayLabel = '$key年';
      }

      result.add(
        MultiBarChartData(
          category: displayLabel,
          value1: stats.totalExpense, // 支出
          value2: stats.totalIncome, // 收入
        ),
      );
    }

    return result;
  }

  /// 构建累计汇总数据
  Widget _buildTotalSummary() {
    double totalIncome = 0;
    double totalExpense = 0;

    // 计算累计数据
    for (var stats in widget.statisticsMap.values) {
      totalIncome += stats.totalIncome;
      totalExpense += stats.totalExpense;
    }

    final netIncome = totalIncome - totalExpense;

    // 格式化金额
    final formatter = NumberFormat.currency(
      locale: 'zh_CN',
      symbol: '¥',
      decimalDigits: ScreenHelper.isDesktop() ? 2 : 0,
    );

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '累计汇总',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                '累计支出',
                formatter.format(totalExpense),
                Colors.green,
              ),
              _buildSummaryItem(
                '累计收入',
                formatter.format(totalIncome),
                Colors.red,
              ),
              _buildSummaryItem(
                '累计结余',
                formatter.format(netIncome),
                netIncome >= 0 ? Colors.blue : Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建汇总项
  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
