import 'package:flutter/material.dart';

/// 2026-09-04 桌面端适配：内容限宽容器
/// 宽屏时内容居中限宽，避免列表/卡片/正文在桌面全宽拉伸难读；
/// 窄屏(移动端)宽度不足时原样铺满，无副作用
class CusContentWidth extends StatelessWidget {
  final Widget child;

  /// 标准：列表 880 / 正文 680 / 详情骨架 900
  final double maxWidth;

  const CusContentWidth({super.key, required this.child, this.maxWidth = 880});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
