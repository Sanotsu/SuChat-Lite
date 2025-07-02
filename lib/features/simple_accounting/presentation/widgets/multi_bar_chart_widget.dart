import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/screen_helper.dart';

/// 多柱状图数据项
class MultiBarChartData {
  final String category;
  final double value1;
  final double value2;
  final String? label1;
  final String? label2;

  MultiBarChartData({
    required this.category,
    required this.value1,
    required this.value2,
    this.label1,
    this.label2,
  });

  @override
  String toString() {
    return 'MultiBarChartData(category: $category, value1: $value1, value2: $value2, label1: $label1, label2: $label2)';
  }
}

/// 多柱状图组件，用于显示两组数据的对比
class MultiBarChartWidget extends StatelessWidget {
  final List<MultiBarChartData> data;
  final String title;
  final double height;
  final bool showTitle;
  final String? series1Name;
  final String? series2Name;
  final Color series1Color;
  final Color series2Color;
  final bool showLegend;
  final String? yAxisTitle;
  final bool showValue;

  /// 是否外部启用横向滚动模式（这里不会控制滚动与否，只是根据是否滚动模式修改一些配置）
  final bool enableScrollMode;

  const MultiBarChartWidget({
    super.key,
    required this.data,
    this.title = '',
    this.height = 300,
    this.showTitle = true,
    this.series1Name = '系列1',
    this.series2Name = '系列2',
    this.series1Color = Colors.blue,
    this.series2Color = Colors.orange,
    this.showLegend = true,
    this.yAxisTitle,
    this.showValue = true,
    this.enableScrollMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(height: height, child: const Center(child: Text('暂无数据')));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle && title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        SizedBox(
          height: height,
          child: SfCartesianChart(
            margin: const EdgeInsets.all(1),
            primaryXAxis: CategoryAxis(
              // labelRotation:
              //     ScreenHelper.isDesktop()
              //         ? 0
              //         : data.length > 5
              //         ? 45
              //         : 0,
              // X轴数据大于7个时，标签旋转45度
              // 启用横向滚动模式时，不旋转标签
              labelRotation: enableScrollMode ? 0 : (data.length > 7 ? 45 : 0),
              labelStyle: const TextStyle(fontSize: 10),
              // 横向滚动模式下，设置固定的间距
              plotOffset: enableScrollMode ? 0 : null,
              // 确保每个类别只显示一个标签
              // labelPlacement: LabelPlacement.betweenTicks,
              // // 设置标签位置为柱子中间
              // labelAlignment: LabelAlignment.center,
              // // 确保每个类别只显示一个标签
              // interval: 1,
              // // 设置为true，确保柱子按索引排列，解决标签重复问题
              // arrangeByIndex: true,
            ),
            primaryYAxis: NumericAxis(
              // 为了和父组件下方的周历大致对起，所以隐藏y轴
              isVisible: false,
              numberFormat: NumberFormat.currency(
                locale: 'zh_CN',
                // symbol: '¥',
                symbol: '',
                decimalDigits: ScreenHelper.isMobile() ? 0 : 1,
              ),
              labelStyle: TextStyle(fontSize: ScreenHelper.isMobile() ? 8 : 10),
              title:
                  yAxisTitle != null
                      ? AxisTitle(text: yAxisTitle!)
                      : const AxisTitle(text: ''),
            ),
            legend: Legend(
              isVisible: showLegend,
              position: LegendPosition.bottom,
              overflowMode: LegendItemOverflowMode.wrap,
            ),
            tooltipBehavior: TooltipBehavior(
              enable: true,
              format: 'point.x: point.y',
              duration: 1500,
            ),
            series: <CartesianSeries>[
              // 第一组数据
              ColumnSeries<MultiBarChartData, String>(
                name: series1Name,
                dataSource: data,
                xValueMapper: (MultiBarChartData data, _) => data.category,
                yValueMapper: (MultiBarChartData data, _) => data.value1,
                color: series1Color,
                dataLabelSettings: DataLabelSettings(
                  isVisible: showValue,
                  labelAlignment: ChartDataLabelAlignment.outer,
                  textStyle: TextStyle(fontSize: 10),
                ),
                // 横向滚动模式下，使用更宽的柱子宽度
                width: enableScrollMode ? 0.9 : 0.7,
                spacing: enableScrollMode ? 0.0 : 0.2,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
                animationDuration: 1000,
              ),

              // 第二组数据
              ColumnSeries<MultiBarChartData, String>(
                name: series2Name,
                dataSource: data,
                xValueMapper: (MultiBarChartData data, _) => data.category,
                yValueMapper: (MultiBarChartData data, _) => data.value2,
                color: series2Color,
                dataLabelSettings: DataLabelSettings(
                  // isVisible: showValue,
                  // 因为父组件下方周历有本周的数值，所以只显示上周的即可
                  isVisible: ScreenHelper.isMobile() ? false : showValue,
                  labelAlignment: ChartDataLabelAlignment.outer,
                  textStyle: TextStyle(fontSize: 10),
                ),
                // 横向滚动模式下，使用更宽的柱子宽度
                width: enableScrollMode ? 0.9 : 0.7,
                spacing: enableScrollMode ? 0.0 : 0.2,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
                animationDuration: 1000,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
