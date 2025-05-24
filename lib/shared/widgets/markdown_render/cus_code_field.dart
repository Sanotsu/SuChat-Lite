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

  // 选择了一个flutter_highlight 中的主题，然后修改了root的背景颜色为透明
  // 这样可以同时保留了其他的代码高亮
  final modifiedTheme = Map<String, TextStyle>.from(
      themeMap['xcode'] ?? githubTheme,
    )
    ..['root'] = TextStyle(
      backgroundColor: Colors.transparent,
      color: Colors.black,
      fontFamily: 'FiraCode', // 使用等宽字体
      fontSize: 14,
    );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                  padding: const EdgeInsets.all(0),
                  child: Text(widget.name),
                ),
                const Spacer(),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
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
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.all(4),

            // 使用highlight 渲染有好的样式和高亮，自定义修改主题后也可以背景透明
            child: HighlightView(
              widget.codes,
              language: widget.name,
              theme: modifiedTheme,
            ),
          ),
        ],
      ),
    );
  }
}
