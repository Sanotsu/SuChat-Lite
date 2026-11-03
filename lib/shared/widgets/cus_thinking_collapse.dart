import 'package:flutter/material.dart';

import '../../core/utils/screen_helper.dart';
import 'markdown_render/cus_markdown_renderer.dart';

/// 2026-09-04 思考模型思考过程折叠组件
/// 样式复刻聊天模块multimodal_content_widget的_buildThinkingContent，
/// 供扩展功能流式生成(定制食谱/饮食分析)复用：
/// 思考中默认展开并显示"思考中"，正文开始输出后显示"已深度思考(用时X秒)"
class CusThinkingCollapse extends StatelessWidget {
  /// 思考内容(reasoning_content累积)
  final String thinkingText;

  /// 是否仍在思考中(正文尚未开始输出)
  final bool isThinking;

  /// 思考用时(秒，正文首块到达时定格)
  final int? thinkingSeconds;

  /// 标题颜色(思考内容用主题色)
  final Color? color;

  const CusThinkingCollapse({
    super.key,
    required this.thinkingText,
    required this.isThinking,
    this.thinkingSeconds,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          isThinking ? '思考中' : '已深度思考(用时${thinkingSeconds ?? 0}秒)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color ?? Colors.black54,
          ),
        ),
        initiallyExpanded: isThinking,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: RepaintBoundary(
                // 使用高性能MarkdownRenderer渲染思考内容，利用缓存机制
                child: CusMarkdownRenderer.instance.render(
                  thinkingText,
                  textStyle: TextStyle(
                    color: color ?? Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  selectable: ScreenHelper.isDesktop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
