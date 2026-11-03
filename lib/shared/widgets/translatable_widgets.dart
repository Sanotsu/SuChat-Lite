import 'package:flutter/material.dart';

import '../../core/utils/simple_tools.dart';
import '../../features/unified_chat/data/models/openai_response.dart';
import '../services/translation_service.dart';
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
  // 2026-10-13 翻译进行中标志：防重复点击(思考模型响应慢)
  bool _translating = false;

  Future<void> _translateText() async {
    if (_translating) return;
    setState(() {
      _translating = true;
    });
    try {
      String translation = await TranslationService.translateToChinese(
        widget.title,
      );
      if (!mounted) return;
      setState(() {
        translatedText = translation;
      });
    } finally {
      if (mounted) {
        setState(() {
          _translating = false;
        });
      }
    }
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
                    // 翻译中显示加载圈并禁点，避免重复请求
                    onPressed: _translating ? null : _translateText,
                    icon: _translating
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(Icons.translate, size: 16),
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
  // 2026-10-13 翻译进行中标志：防重复点击(思考模型首字延迟可能很久)
  bool _translating = false;
  // 流式模式下是否已收到正文(用于区分"思考中"与"翻译中")
  bool _receivedContent = false;

  Future<void> _translateText() async {
    if (_translating) return;
    setState(() {
      _translating = true;
      _receivedContent = false;
    });
    try {
      if (widget.stream == true) {
        final (stream, cancelFunc) =
            await TranslationService.translateStreamToChinese(widget.text);

        await for (final chunk in stream) {
          if (!mounted) {
            cancelFunc();
            break;
          }
          // 2026-10-13 FIX：chunk.cusText 是旧协议残留(该getter不存在，
          // 运行时NoSuchMethodError)——流式契约正文在delta.content
          if (chunk is OpenAIChatCompletionResponse &&
              chunk.choices.isNotEmpty) {
            final content = chunk.choices.first.delta?.content;
            if (content != null && content.isNotEmpty) {
              setState(() {
                translatedText += content;
                _receivedContent = true;
              });
            }
          }
        }
      } else {
        String translation = await TranslationService.translateToChinese(
          widget.text,
        );

        if (mounted) {
          setState(() {
            translatedText = translation;
          });
        }
      }
    } catch (e) {
      ToastUtils.showError("翻译出错：${e.toString()}");

      if (mounted) {
        setState(() {
          translatedText = widget.text;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _translating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // 翻译中显示状态提示：未收到正文时思考模型可能在长时间思考
            if (_translating && widget.stream == true)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  _receivedContent ? '翻译中...' : '思考中...',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            // 2026-10-13 FIX：已有译文时只显示清除按钮——此前翻译按钮
            // 仍可点击，流式追加模式再点会重复追加译文
            if (translatedText.isNotEmpty)
              IconButton(
                onPressed: () => setState(() => translatedText = ""),
                icon: Icon(Icons.clear, size: 20),
              )
            else
              IconButton(
                // 翻译中禁点，避免重复请求；图标变加载圈
                onPressed: _translating ? null : _translateText,
                icon: _translating
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.translate, size: 20),
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
