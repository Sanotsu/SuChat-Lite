import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// 可滚动和缩放的图表组件
/// 支持双指缩放和滚动查看
class ScrollableChart extends StatefulWidget {
  /// 图表标题
  final String title;

  /// 图表描述（可选）
  final String? description;

  /// 图表高度
  final double height;

  /// 图表系列
  final List<CartesianSeries> series;

  /// X轴类型
  final ChartAxis xAxis;

  /// Y轴类型
  final ChartAxis yAxis;

  /// 是否显示图例
  final bool showLegend;

  /// 图例位置
  final LegendPosition legendPosition;

  /// 是否启用缩放
  final bool enableZoom;

  /// 是否启用平移
  final bool enablePanning;

  /// 缩放模式
  final ZoomMode zoomMode;

  const ScrollableChart({
    super.key,
    required this.title,
    this.description,
    this.height = 300,
    required this.series,
    required this.xAxis,
    required this.yAxis,
    this.showLegend = true,
    this.legendPosition = LegendPosition.bottom,
    this.enableZoom = true,
    this.enablePanning = true,
    this.zoomMode = ZoomMode.x,
  });

  @override
  State<ScrollableChart> createState() => _ScrollableChartState();
}

class _ScrollableChartState extends State<ScrollableChart> {
  late ZoomPanBehavior _zoomPanBehavior;

  @override
  void initState() {
    super.initState();
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: widget.enableZoom,
      enablePanning: widget.enablePanning,
      zoomMode: widget.zoomMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (widget.description != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.description!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: widget.height,
              child: SfCartesianChart(
                primaryXAxis: widget.xAxis,
                // 暂时不使用自定义Y轴，让表格有更多空间
                primaryYAxis: widget.yAxis,
                // y轴的一些配置
                // primaryYAxis: NumericAxis(
                //   // 隐藏y轴网格线(宽度设为0)
                //   // majorGridLines: MajorGridLines(width: 1),
                //   // 标签文字旋转角度
                //   // labelRotation: -60,
                //   // 标签文字大小
                //   // labelStyle: TextStyle(fontSize: 10),
                //   // 不显示y轴标签
                //   // isVisible: false,
                // ),
                legend: Legend(
                  isVisible: widget.showLegend,
                  position: widget.legendPosition,
                ),
                tooltipBehavior: TooltipBehavior(enable: true),
                zoomPanBehavior: _zoomPanBehavior,
                series: widget.series,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
