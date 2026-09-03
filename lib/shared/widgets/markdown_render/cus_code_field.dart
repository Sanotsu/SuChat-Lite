import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/theme_map.dart';
import 'package:flutter_highlight/themes/github.dart';

/// 改造原始代码做一些简单自定义
/// A widget that displays code with syntax highlighting and a copy button.
///
/// The [CusCodeField] widget takes a [name] parameter which is displayed as a label
/// above the code block, and a [codes] parameter containing the actual code text
/// to display.
///
/// Features:
/// - Displays code in a Material container with rounded corners
/// - Shows the code language/name as a label
/// - Provides a copy button to copy code to clipboard
/// - Visual feedback when code is copied
/// - Themed colors that adapt to light/dark mode
class CusCodeField extends StatefulWidget {
  const CusCodeField({super.key, required this.name, required this.codes});
  final String name;
  final String codes;

  @override
  State<CusCodeField> createState() => _CusCodeFieldState();
}

class _CusCodeFieldState extends State<CusCodeField> {
  bool _copied = false;

  // 横向滚动控制器，供Scrollbar联动显示滚动条
  final ScrollController _horizontalController = ScrollController();

  // 选择flutter_highlight主题并修改root背景为透明以融入容器：
  // 浅色用github，深色用atom-one-dark，字色随明暗模式切换
  Map<String, TextStyle> _buildHighlightTheme(bool isDark) {
    final base = Map<String, TextStyle>.from(
      themeMap[isDark ? 'atom-one-dark' : 'github'] ?? githubTheme,
    );
    base['root'] = TextStyle(
      backgroundColor: Colors.transparent,
      color: isDark ? const Color(0xFFABB2BF) : const Color(0xFF24292E),
      fontFamily: 'FiraCode', // 使用等宽字体
      fontSize: 13.5,
      height: 1.5,
    );
    return base;
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlightTheme = _buildHighlightTheme(isDark);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1)),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 2),
                  child: Text(
                    widget.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    textStyle: const TextStyle(fontWeight: FontWeight.normal),
                  ),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: widget.codes),
                    ).then((value) {
                      setState(() {
                        _copied = true;
                      });
                    });
                    await Future.delayed(const Duration(seconds: 2));
                    setState(() {
                      _copied = false;
                    });
                  },
                  icon: Icon(
                    (_copied) ? Icons.done : Icons.content_paste,
                    size: 15,
                  ),
                  label: Text((_copied) ? "Copied!" : "Copy"),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.15),
          ),
          // 横向滚动必须手动包Scrollbar(仅纵向走PrimaryScrollController才有默认滚动条)
          Scrollbar(
            controller: _horizontalController,
            thumbVisibility: true,
            thickness: 6,
            radius: const Radius.circular(3),
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              // 使用highlight渲染代码高亮，root背景透明融入容器
              child: HighlightView(
                widget.codes,
                language: widget.name,
                theme: highlightTheme,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
