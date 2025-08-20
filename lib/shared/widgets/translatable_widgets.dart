import 'package:flutter/material.dart';

import '../../core/utils/simple_tools.dart';
import '../../core/utils/simple_traslate_tool.dart';
import 'toast_utils.dart';

/// 带有可翻译按钮的标题组件
/// 用于mal详情页英文标题翻译成中文等地方
class TranslatableTitleButton extends StatefulWidget {
  final String title;
  final String? url;

  const TranslatableTitleButton({super.key, required this.title, this.url});

  @override
  State<TranslatableTitleButton> createState() =>
      _TranslatableTitleButtonState();
}

class _TranslatableTitleButtonState extends State<TranslatableTitleButton> {
  String? translatedText;

  Future<void> _translateText() async {
    String translation = await getAITranslation(widget.title);
    setState(() {
      translatedText = translation;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: widget.url != null
                    ? () => launchStringUrl(widget.url!)
                    : null,
                child: Text(
                  "${widget.title}${translatedText != null ? '($translatedText)' : ''}",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // 两个按钮都显示占太宽了，如果翻译结果不满意，关闭后再点击
            (translatedText != null && translatedText!.isNotEmpty)
                ? IconButton(
                    onPressed: () => setState(() => translatedText = null),
                    icon: Icon(Icons.clear, size: 16),
                  )
                : IconButton(
                    onPressed: _translateText,
                    icon: Icon(Icons.translate, size: 16),
                  ),
          ],
        ),
      ],
    );
  }
}

/// 带有可翻译按钮的正文组件
/// 用于mal详情页简介翻译成中文等地方
class TranslatableText extends StatefulWidget {
  final String text;
  // 是否是追加模式，不是就直接替换
  final bool? isAppend;

  // 是否流式响应
  final bool? stream;

  const TranslatableText({
    super.key,
    required this.text,
    this.isAppend = true,
    this.stream = false,
  });

  @override
  State<TranslatableText> createState() => _TranslatableTextState();
}

class _TranslatableTextState extends State<TranslatableText> {
  String translatedText = "";

  Future<void> _translateText() async {
    try {
      if (widget.stream == true) {
        final (stream, cancelFunc) = await getStreamAITranslation(widget.text);
        await for (final chunk in stream) {
          setState(() {
            translatedText += chunk.cusText;
          });
        }
      } else {
        String translation = await getAITranslation(widget.text);
        setState(() {
          translatedText = translation;
        });
      }
    } catch (e) {
      ToastUtils.showError("翻译出错：${e.toString()}");

      setState(() {
        translatedText = widget.text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              onPressed: _translateText,
              icon: Icon(Icons.translate, size: 20),
            ),
            if (translatedText.isNotEmpty)
              IconButton(
                onPressed: () => setState(() => translatedText = ""),
                icon: Icon(Icons.clear, size: 20),
              ),
          ],
        ),
        if (widget.isAppend == false)
          Padding(
            padding: EdgeInsets.all(5),
            child: Text(
              translatedText.isNotEmpty ? translatedText : widget.text,
            ),
          ),
        if (widget.isAppend == true) ...[
          Padding(padding: EdgeInsets.all(5), child: Text(widget.text)),
          if (translatedText.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(5),
              child: Text("【AI翻译】\n$translatedText"),
            ),
        ],
      ],
    );
  }
}
