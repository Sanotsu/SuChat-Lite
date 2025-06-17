import 'package:flutter/material.dart';

/// BMI指示器组件
/// 用于显示BMI值在不同健康范围区间的位置
class BmiIndicator extends StatelessWidget {
  /// 当前BMI值
  final double bmi;

  /// 组件高度
  final double height;

  /// 是否显示标签
  final bool showLabels;

  /// 自定义颜色
  final List<Color>? colors;

  /// BMI范围的最小值
  static const double minBmi = 15.0;

  /// BMI范围的最大值
  static const double maxBmi = 35.0;

  /// BMI范围的关键点
  static const List<double> keyPoints = [15.0, 18.5, 24.0, 28.0, 35.0];

  /// BMI范围的标签
  static const List<String> labels = ['15', '18.5', '24', '28', '35'];

  /// BMI范围的颜色
  static const List<Color> defaultColors = [
    Colors.blue, // 偏瘦
    Colors.green, // 正常
    Colors.orange, // 超重
    Colors.red, // 肥胖
  ];

  const BmiIndicator({
    super.key,
    required this.bmi,
    this.height = 24.0,
    this.showLabels = true,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // BMI指示条
        SizedBox(
          height: height,
          child: CustomPaint(
            painter: BmiIndicatorPainter(
              bmi: bmi,
              colors: colors ?? defaultColors,
            ),
            size: Size.fromHeight(height),
          ),
        ),

        // BMI标签
        if (showLabels)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: SizedBox(
                height: 20, // 给标签区域一个固定高度
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      // 允许溢出绘制(避免最左和最右的标签被裁剪)
                      clipBehavior: Clip.none,
                      children: List.generate(labels.length, (index) {
                        // 计算每个标签的位置比例
                        final position =
                            (keyPoints[index] - minBmi) / (maxBmi - minBmi);

                        // 计算标签的实际位置
                        final labelPosition = position * constraints.maxWidth;

                        return Positioned(
                          left: labelPosition - 15, // 调整居中位置
                          child: SizedBox(
                            width: 30, // 给标签一个固定宽度
                            child: Text(
                              labels[index],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// BMI指示器绘制器
class BmiIndicatorPainter extends CustomPainter {
  /// 当前BMI值
  final double bmi;

  /// 自定义颜色
  final List<Color> colors;

  /// BMI范围的最小值
  static const double minBmi = 15.0;

  /// BMI范围的最大值
  static const double maxBmi = 35.0;

  /// BMI范围的关键点
  static const List<double> keyPoints = [15.0, 18.5, 24.0, 28.0, 35.0];

  BmiIndicatorPainter({required this.bmi, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // 绘制背景渐变
    _drawGradientBackground(canvas, size);

    // 计算BMI在范围内的位置比例 (0.0 - 1.0)
    final position = ((bmi - minBmi) / (maxBmi - minBmi)).clamp(0.0, 1.0);

    // 计算指示器位置
    final indicatorX = position * width;

    // 绘制指示器
    final paint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    // 绘制指示器线条
    canvas.drawRect(Rect.fromLTWH(indicatorX - 1, 0, 2, height), paint);

    // 绘制三角形指示器
    final path = Path();
    path.moveTo(indicatorX, height);
    path.lineTo(indicatorX - 6, height - 6);
    path.lineTo(indicatorX + 6, height - 6);
    path.close();

    canvas.drawPath(path, paint);

    // 可选：绘制关键点的垂直线（调试用）
    // drawKeyPointLines(canvas, size);
  }

  // 绘制关键点的垂直线（调试用）
  void drawKeyPointLines(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final paint =
        Paint()
          ..color = Colors.grey.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;

    for (final point in keyPoints) {
      final position = (point - minBmi) / (maxBmi - minBmi);
      final x = position * width;
      canvas.drawLine(Offset(x, 0), Offset(x, height), paint);
    }
  }

  /// 绘制背景渐变
  void _drawGradientBackground(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // 计算每个区间的宽度比例
    final rect = Rect.fromLTWH(0, 0, width, height);

    // 计算精确的停止点位置
    final List<double> stops = [];

    // 第一个区间: 15.0 - 18.5 (偏瘦)
    stops.add(0.0); // 起始点

    // 第二个区间: 18.5 - 24.0 (正常)
    stops.add((18.5 - minBmi) / (maxBmi - minBmi));

    // 第三个区间: 24.0 - 28.0 (超重)
    stops.add((24.0 - minBmi) / (maxBmi - minBmi));

    // 第四个区间: 28.0 - 35.0 (肥胖)
    stops.add((28.0 - minBmi) / (maxBmi - minBmi));
    stops.add(1.0); // 结束点

    final gradient = LinearGradient(
      colors: [
        colors[0],
        colors[0],
        colors[1],
        colors[1],
        colors[2],
        colors[2],
        colors[3],
        colors[3],
      ],
      stops: [
        0.0,
        stops[1] - 0.001,
        stops[1],
        stops[2] - 0.001,
        stops[2],
        stops[3] - 0.001,
        stops[3],
        1.0,
      ],
    );

    final paint =
        Paint()
          ..shader = gradient.createShader(rect)
          ..style = PaintingStyle.fill;

    // 绘制圆角矩形背景
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(height / 2));

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(BmiIndicatorPainter oldDelegate) {
    return oldDelegate.bmi != bmi || oldDelegate.colors != colors;
  }
}
