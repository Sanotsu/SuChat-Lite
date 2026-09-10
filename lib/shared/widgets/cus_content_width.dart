import 'package:flutter/material.dart';

/// 2026-09-04 桌面端适配：内容限宽容器
/// 宽屏时内容居中限宽，避免列表/卡片/正文在桌面全宽拉伸难读；
/// 窄屏(移动端)宽度不足时原样铺满，无副作用。
/// 2026-09-09 档位具名化：全项目事实规范只有两档——内容/功能页 1000、
/// 设置/表单页 720。用 [CusContentWidth.form] 表达表单档，
/// 避免魔法数字散落与档位漂移(此前注释的"880/680/900"从未落地，已废)
class CusContentWidth extends StatelessWidget {
  final Widget child;

  /// 限宽上限(由所选构造的档位决定，特殊场景可显式覆盖)
  final double maxWidth;

  /// 内容/功能页标准限宽：列表、正文、详情等宽内容页
  static const double contentWidth = 1000;

  /// 设置/表单页标准限宽：表单控件全宽拉伸难看，收窄一档
  static const double formWidth = 720;

  /// 内容/功能页档位(默认1000)
  const CusContentWidth({
    super.key,
    required this.child,
    this.maxWidth = contentWidth,
  });

  /// 设置/表单类页面档位(720)
  const CusContentWidth.form({super.key, required this.child})
    : maxWidth = formWidth;

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
