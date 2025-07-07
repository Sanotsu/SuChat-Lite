import 'package:flutter/material.dart';
import 'dart:math' as math;

class NutritionGauge extends StatelessWidget {
  final double current;
  final double target;
  final String label;

  const NutritionGauge({
    super.key,
    required this.current,
    required this.target,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final caloriesLeft = target - current;
    final isOverTarget = current > target;

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 仪表盘背景
              CustomPaint(
                size: const Size(200, 200),
                painter: GaugePainter(
                  percentage: percentage,
                  backgroundColor: Colors.grey[200]!,
                  progressColor: isOverTarget ? Colors.red : Colors.green,
                ),
              ),

              // 中间文本
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isOverTarget ? '超出目标' : label,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isOverTarget
                        ? '+${current.toInt() - target.toInt()}'
                        : '${caloriesLeft.toInt()}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isOverTarget ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '千卡',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class GaugePainter extends CustomPainter {
  final double percentage;
  final Color backgroundColor;
  final Color progressColor;

  GaugePainter({
    required this.percentage,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2) * 0.8;

    // 绘制背景弧
    final backgroundPaint =
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.8, // 开始角度
      math.pi * 1.4, // 扫描角度
      false,
      backgroundPaint,
    );

    // 绘制进度弧
    final progressPaint =
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.8, // 开始角度
      math.pi * 1.4 * percentage, // 扫描角度
      false,
      progressPaint,
    );

    // 绘制刻度
    final tickPaint =
        Paint()
          ..color = Colors.grey[400]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    for (int i = 0; i <= 10; i++) {
      final angle = math.pi * 0.8 + math.pi * 1.4 * (i / 10);
      final outerPoint = Offset(
        center.dx + (radius + 10) * math.cos(angle),
        center.dy + (radius + 10) * math.sin(angle),
      );
      final innerPoint = Offset(
        center.dx + (radius - 5) * math.cos(angle),
        center.dy + (radius - 5) * math.sin(angle),
      );

      canvas.drawLine(innerPoint, outerPoint, tickPaint);

      // 绘制刻度值
      if (i == 0 || i == 5 || i == 10) {
        final textPainter = TextPainter(
          text: TextSpan(
            text:
                i == 0
                    ? '0'
                    : i == 5
                    ? '50%'
                    : '100%',
            style: TextStyle(color: Colors.grey[600], fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        final textPoint = Offset(
          center.dx + (radius + 25) * math.cos(angle) - textPainter.width / 2,
          center.dy + (radius + 25) * math.sin(angle) - textPainter.height / 2,
        );

        textPainter.paint(canvas, textPoint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor;
  }
}
