import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/screen_helper.dart';

/// 柱状图数据项
class BarChartData {
  final String category;
  final double value;
  final Color color;
  final bool isSelected; // 是否为当前选中项

  BarChartData({
    required this.category,
    required this.value,
    required this.color,
    this.isSelected = false, // 默认为非选中
  });
}

/// 柱状图组件
class BarChartWidget extends StatelessWidget {
  final List<BarChartData> data;
  final String title;
  final String? seriesName;
  final double height;
  final bool showTitle;
  final bool showValue;
  final bool horizontal;
  final bool centerTitle;
  final bool showLegend;
  final String? yAxisTitle;
  final String? xAxisTitle;
  // 是否显示y轴（移动端宽度太小可不显示）
  final bool showYAxis;
  final bool showAnnotations;

  const BarChartWidget({
    super.key,
    required this.data,
    this.title = '',
    this.seriesName = '系列',
    this.height = 300,
    this.showTitle = true,
    this.showValue = true,
    this.horizontal = false,
    this.centerTitle = false,
    this.showLegend = false,
    this.yAxisTitle,
    this.xAxisTitle,
    this.showYAxis = false,
    this.showAnnotations = false,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(height: height, child: const Center(child: Text('暂无柱状图数据')));
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
          child: horizontal ? _buildHorizontalChart() : _buildVerticalChart(),
        ),
      ],
    );
  }

  /// 构建垂直柱状图
  Widget _buildVerticalChart() {
    return SfCartesianChart(
      margin: EdgeInsets.zero,
      primaryXAxis: CategoryAxis(
        // labelRotation: data.length > 5 ? 45 : 0,
        labelRotation: 0,
        labelStyle: const TextStyle(fontSize: 10),
      ),
      // Y轴刻度移动端不显示，增加柱状图可显示宽度
      primaryYAxis: NumericAxis(
        isVisible: showYAxis,
        numberFormat: NumberFormat.currency(
          locale: 'zh_CN',
          symbol: '¥',
          decimalDigits: 0,
        ),
        labelStyle: const TextStyle(fontSize: 10),
      ),
      legend: Legend(isVisible: showLegend, position: LegendPosition.bottom),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        format: 'point.x: point.y',
        duration: 1500,
      ),
      series: <CartesianSeries>[
        ColumnSeries<BarChartData, String>(
          name: seriesName,
          dataSource: data,
          xValueMapper: (BarChartData data, _) => data.category,
          yValueMapper: (BarChartData data, _) => data.value,
          //  pointColorMapper: (BarChartData data, _) => data.color,
          pointColorMapper:
              (BarChartData data, _) =>
                  data.isSelected
                      ? data.color
                      : data.color.withValues(alpha: 0.5),
          dataLabelSettings: DataLabelSettings(
            isVisible: showValue,
            labelAlignment: ChartDataLabelAlignment.outer,
            textStyle: TextStyle(
              fontSize: ScreenHelper.isDesktop() ? 12 : 10,
              fontWeight: FontWeight.bold,
            ),
            // 为选中项添加不同的标签样式
            builder: (
              dynamic data,
              dynamic point,
              dynamic series,
              int pointIndex,
              int seriesIndex,
            ) {
              final item = data as BarChartData;
              final formatter = NumberFormat.currency(
                locale: 'zh_CN',
                symbol: '¥',
                decimalDigits: 0,
              );
              return Container(
                // padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration:
                    item.isSelected
                        ? BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(4),
                        )
                        : null,
                child: Text(
                  formatter.format(item.value),
                  style: TextStyle(
                    color:
                        item.isSelected
                            ? Colors.black
                            : Colors.black.withValues(alpha: 0.7),
                    fontSize: ScreenHelper.isDesktop() ? 12 : 10,
                    fontWeight:
                        item.isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
          width: 0.8,
          spacing: 0.2,
          borderRadius: BorderRadius.circular(4),
          animationDuration: 1000,
          // // 为选中项添加边框
          // borderColor: Colors.black26,
          // borderWidth: 1,
          // // 被选中项的样式
          // selectionBehavior: SelectionBehavior(
          //   enable: true,
          //   selectedColor: Colors.amber,
          // ),
        ),
      ],
      // 添加选中项的注释
      annotations: showAnnotations ? _buildSelectedAnnotations() : [],
    );
  }

  /// 构建选中项的注释
  List<CartesianChartAnnotation> _buildSelectedAnnotations() {
    List<CartesianChartAnnotation> annotations = [];

    for (int i = 0; i < data.length; i++) {
      if (data[i].isSelected && data[i].value > 0) {
        annotations.add(
          CartesianChartAnnotation(
            widget: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_drop_down,
                color: Colors.amber,
                size: 16,
              ),
            ),
            coordinateUnit: CoordinateUnit.point,
            x: data[i].category,
            y: data[i].value,
            verticalAlignment: ChartAlignment.near,
          ),
        );
      }
    }

    return annotations;
  }

  /// 构建水平柱状图
  Widget _buildHorizontalChart() {
    return SfCartesianChart(
      margin: EdgeInsets.zero,
      // 使用isTransposed属性将垂直柱状图转换为水平柱状图
      isTransposed: true,
      primaryXAxis: CategoryAxis(labelStyle: const TextStyle(fontSize: 10)),
      primaryYAxis: NumericAxis(
        isVisible: showYAxis,
        numberFormat: NumberFormat.currency(
          locale: 'zh_CN',
          symbol: '¥',
          decimalDigits: 0,
        ),
        labelStyle: const TextStyle(fontSize: 10),
      ),
      legend: Legend(isVisible: showLegend, position: LegendPosition.bottom),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        format: 'point.x: point.y',
        duration: 1500,
      ),
      series: <CartesianSeries>[
        // 使用ColumnSeries配合isTransposed实现横向条状图
        ColumnSeries<BarChartData, String>(
          name: seriesName,
          dataSource: data,
          xValueMapper: (BarChartData data, _) => data.category,
          yValueMapper: (BarChartData data, _) => data.value,
          pointColorMapper:
              (BarChartData data, _) =>
                  data.isSelected
                      ? data.color
                      : data.color.withValues(alpha: 0.3),
          dataLabelSettings: DataLabelSettings(
            isVisible: showValue,
            labelAlignment: ChartDataLabelAlignment.outer,
            // y轴偏移字体大小的一半才正好和柱状图对齐
            // x轴负数减少outer的空隙
            offset: const Offset(-10, 5),
            textStyle: const TextStyle(fontSize: 10),
            overflowMode: OverflowMode.shift,
            // 为选中项添加不同的标签样式
            builder: (
              dynamic data,
              dynamic point,
              dynamic series,
              int pointIndex,
              int seriesIndex,
            ) {
              final item = data as BarChartData;
              final formatter = NumberFormat.currency(
                locale: 'zh_CN',
                symbol: '¥',
                decimalDigits: 0,
              );
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration:
                    item.isSelected
                        ? BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(4),
                        )
                        : null,
                child: Text(
                  formatter.format(item.value),
                  style: TextStyle(
                    color:
                        item.isSelected
                            ? Colors.black
                            : Colors.black.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight:
                        item.isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
          width: 0.8,
          spacing: 0.2,
          borderRadius: BorderRadius.circular(4),
          animationDuration: 1000,
          // 为选中项添加边框
          borderColor: Colors.black26,
          borderWidth: 1,
        ),
      ],
    );
  }
}
