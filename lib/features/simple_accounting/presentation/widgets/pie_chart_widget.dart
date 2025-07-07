import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// 饼图数据项
class PieChartData {
  final String category;
  final double value;
  final double percentage;
  final Color color;

  PieChartData({
    required this.category,
    required this.value,
    required this.percentage,
    required this.color,
  });
}

/// 饼图组件
class PieChartWidget extends StatelessWidget {
  final List<PieChartData> data;
  final String title;
  final double height;
  final bool showLegend;
  final bool showPercentage;
  final bool showValue;
  final bool showTitle;
  final bool centerTitle;

  const PieChartWidget({
    super.key,
    required this.data,
    this.title = '',
    this.height = 300,
    this.showLegend = true,
    this.showPercentage = true,
    this.showValue = true,
    this.showTitle = true,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(height: height, child: const Center(child: Text('暂无数据')));
    }

    return Column(
      crossAxisAlignment:
          centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
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
          child: SfCircularChart(
            margin: EdgeInsets.zero,
            legend: Legend(
              isVisible: showLegend,
              overflowMode: LegendItemOverflowMode.wrap,
              position: LegendPosition.bottom,
            ),
            series: <CircularSeries>[
              DoughnutSeries<PieChartData, String>(
                dataSource: data,
                xValueMapper: (PieChartData data, _) => data.category,
                yValueMapper: (PieChartData data, _) => data.value,
                pointColorMapper: (PieChartData data, _) => data.color,
                dataLabelMapper: (PieChartData data, _) {
                  String label = data.category;
                  if (showPercentage) {
                    label += '${data.percentage.toStringAsFixed(1)}%';
                  }
                  if (showValue) {
                    if (label.isNotEmpty) label += '\n';
                    label += '¥${data.value.toStringAsFixed(2)}';
                  }
                  return label;
                },
                // 饼图数据标签，颜色（默认的黑色）不和甜甜圈一样，因为会很麻烦
                dataLabelSettings: DataLabelSettings(
                  isVisible: showPercentage || showValue,
                  labelPosition: ChartDataLabelPosition.outside,
                  textStyle: const TextStyle(fontSize: 10),
                  connectorLineSettings: const ConnectorLineSettings(
                    type: ConnectorType.curve,
                    length: '15%',
                  ),
                ),
                enableTooltip: true,
                animationDuration: 1000,
                explode: true,
                explodeIndex: 0,
                explodeOffset: '5%',
                radius: '75%',
                innerRadius: '50%',
              ),
            ],
            tooltipBehavior: TooltipBehavior(
              enable: true,
              format: 'point.x: ¥point.y',
              duration: 1500,
            ),
          ),
        ),
      ],
    );
  }
}
