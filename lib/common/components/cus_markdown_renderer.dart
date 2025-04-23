import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:gpt_markdown/custom_widgets/selectable_adapter.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import 'cus_code_field.dart';
import 'optimized_custom_markdown_renderer.dart';
import 'safe_markdown_wrapper.dart';
import 'tool_widget.dart';

/// 优化的Markdown渲染工具类
///
/// 提供缓存机制和智能组件加载，优化性能
class CusMarkdownRenderer {
  // 私有构造函数，防止直接实例化
  CusMarkdownRenderer._();

  // 单例实例
  static final CusMarkdownRenderer _instance = CusMarkdownRenderer._();

  // 获取单例
  static CusMarkdownRenderer get instance => _instance;

  // Markdown缓存 - 使用LRU缓存策略
  final Map<String, Widget> _markdownCache = {};

  // 缓存大小限制
  static const int _maxCacheSize = 200;

  // 预定义的所有组件列表
  static final List<MarkdownComponent> _allComponents = [
    CodeBlockMd(),
    NewLines(),
    BlockQuote(),
    ImageMd(),
    ATagMd(),
    TableMd(),
    HTag(),
    UnOrderedList(),
    OrderedList(),
    RadioButtonMd(),
    CheckBoxMd(),
    HrLine(),
    StrikeMd(),
    BoldMd(),
    ItalicMd(),
    LatexMath(),
    LatexMathMultiLine(),
    HighlightedText(),
    SourceTag(),
    IndentMd(),
  ];

  // 预定义的所有内联组件
  static final List<MarkdownComponent> _allInlineComponents = [
    ImageMd(),
    ATagMd(),
    TableMd(),
    StrikeMd(),
    BoldMd(),
    ItalicMd(),
    LatexMath(),
    LatexMathMultiLine(),
    HighlightedText(),
    SourceTag(),
  ];

  /// 渲染Markdown内容
  ///
  /// [text] 要渲染的Markdown文本
  /// [selectable] 是否可选择文本(默认不可选)
  /// [textColor] 文本颜色
  Widget render(String text, {Color? textColor, bool selectable = false}) {
    if (text.isEmpty) return const SizedBox.shrink();

    // 检查缓存中是否存在
    final cacheKey = '${selectable}_$text';
    final cachedWidget = _markdownCache[cacheKey];
    if (cachedWidget != null) return cachedWidget;

    return _buildMarkdownWidget(text, textColor, selectable, cacheKey);
  }

  // 构建Markdown小部件
  Widget _buildMarkdownWidget(
    String text,
    Color? textColor,
    bool selectable,
    String cacheKey,
  ) {
    try {
      final widget = _buildGptMarkdown(text, textColor, selectable);
      _addToCache(cacheKey, widget);
      return widget;
    } catch (e) {
      debugPrint('Markdown渲染错误: $e');
      return _buildFallbackMarkdown(text, textColor, selectable, cacheKey);
    }
  }

  // 主要的 GPT Markdown渲染器
  Widget _buildGptMarkdown(String text, Color? textColor, bool selectable) {
    return Builder(
      builder: (context) {
        // 2025-04-22 经过测试，gpt_markdown 无法正常渲染表格中的LaTeX，所以需要先处理文本
        // 具体来说，表格中使用$$...$$、$...$、\[...\]包裹的LaTeX，gpt_markdown 无法正常渲染
        // 所以需要先处理文本，检测到表格中有$$...$$、$...$、\[...\]包裹的内容替换为使用\(...\)

        /// 其实还有一点，非表格中、其他地方单独显示的使用$...$包裹的LaTeX公式也无法正确显示，其他3种则正常。
        // text = normalizeLatexInMarkdownTable(text);

        // // 2025-04-22
        // // 目前实测，gpt_markdown 能正常渲染大部分使用\(...\)包裹的LaTeX内容，无论是表格中、列表中、还是文本中。
        // // 所有暂时把所有使用到LaTeX语法的地方，统一替换使用单行\(...\)来包裹
        // text = normalizeAllLatex(text);

        // 2025-04-23 我在21日提出issue (https://github.com/Infinitix-LLC/gpt_markdown/issues/56)，23日作者就修复了.
        // 表格中使用$$...$$、\[...\]包裹的LaTeX可以正常显示不抛错了，但是所有(不管是否表格内)使用 $...$ 还是无法正常显示
        // 所以需要再处理一次，检测到$...$包裹的LaTeX公式，替换为使用单行$...$来包裹
        text = convertDollarToParenthesesLatex(text);

        // print("处理后的text:\n $text");

        final child = GptMarkdown(
          text,
          style: TextStyle(
            color: textColor ?? Theme.of(context).textTheme.bodyMedium?.color,
          ),
          onLinkTab: (url, title) {
            debugPrint('链接点击: $url, 标题: $title');
            launchStringUrl(url);
          },
          highlightBuilder: _buildHighlight,
          latexWorkaround: _processLatexText,
          imageBuilder: _buildImage,
          latexBuilder:
              (context, tex, textStyle, inline) =>
                  _buildLatex(context, tex, textStyle, inline),
          sourceTagBuilder: _buildSourceTag,
          linkBuilder: _buildLink,
          codeBuilder: _buildCode,
          components: _allComponents,
          inlineComponents: _allInlineComponents,
        );

        return selectable ? SelectionArea(child: child) : child;
      },
    );
  }

  // 备用渲染器
  Widget _buildFallbackMarkdown(
    String text,
    Color? textColor,
    bool selectable,
    String cacheKey,
  ) {
    try {
      final widget = OptimizedCustomMarkdownRenderer(
        text: text,
        textStyle: TextStyle(color: textColor),
      );
      _addToCache(cacheKey, widget);
      return widget;
    } catch (e) {
      debugPrint('备用渲染器错误: $e');
      final widget = MarkdownBody(
        data: text,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(color: textColor),
          tableColumnWidth: const IntrinsicColumnWidth(),
        ),
      );
      _addToCache(cacheKey, widget);
      return widget;
    }
  }

  // 高亮文本构建器
  Widget _buildHighlight(BuildContext context, String text, TextStyle style) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: theme.colorScheme.onSecondaryContainer,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          fontSize: style.fontSize != null ? style.fontSize! * 0.9 : 13.5,
          height: style.height,
        ),
      ),
    );
  }

  // LaTeX文本处理
  String _processLatexText(String tex) {
    final stack = <String>[];
    tex = tex.splitMapJoin(
      RegExp(r"\\text\{|\{|\}|\_"),
      onMatch: (p) {
        final input = p[0] ?? "";
        if (input == r"\text{") {
          stack.add(input);
        }
        if (stack.isNotEmpty) {
          if (input == r"{") {
            stack.add(input);
          }
          if (input == r"}") {
            stack.removeLast();
          }
          if (input == r"_") {
            return r"\_";
          }
        }
        return input;
      },
    );
    return tex.replaceAllMapped(RegExp(r"align\*"), (match) => "aligned");
  }

  // 图片构建器
  Widget _buildImage(BuildContext context, String url) {
    return Image.network(
      url,
      width: 100,
      height: 100,
      errorBuilder:
          (context, error, stackTrace) => Icon(
            Icons.error,
            size: 24,
            color: Theme.of(context).colorScheme.error,
          ),
    );
  }

  // LaTeX构建器
  Widget _buildLatex(
    BuildContext context,
    String tex,
    TextStyle? textStyle,
    bool inline,
  ) {
    if (tex.contains(r"\begin{tabular}")) {
      return _buildLatexTable(tex);
    }

    final controller = ScrollController();

    final child =
        inline
            ? Math.tex(tex, textStyle: textStyle)
            : Padding(
              padding: EdgeInsets.all(8),
              child: Scrollbar(
                controller: controller,
                child: SingleChildScrollView(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  child: Math.tex(tex, textStyle: textStyle),
                ),
              ),
            );

    return InkWell(
      onTap: () => debugPrint("LaTeX content: $tex"),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableAdapter(selectedText: tex, child: child),
      ),
    );
  }

  Widget _buildLatexTable(String tex) {
    final tableString =
        "|${(RegExp(r"^\\begin\{tabular\}\{.*?\}(.*?)\\end\{tabular\}$", multiLine: true, dotAll: true).firstMatch(tex)?[1] ?? "").trim()}|";

    final processedString = tableString
        .replaceAll(r"\\", "|\n|")
        .replaceAll(r"\hline", "")
        .replaceAll(RegExp(r"(?<!\\)&"), "|");

    final tableStringList = processedString.split("\n")..insert(1, "|---|");
    return GptMarkdown(tableStringList.join("\n"));
  }

  // 源标签构建器
  Widget _buildSourceTag(
    BuildContext context,
    String string,
    TextStyle textStyle,
  ) {
    final value = (int.tryParse(string) ?? -1) + 1;
    return SizedBox(
      height: 20,
      width: 20,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            "$value",
            style: textStyle.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  // 链接构建器
  Widget _buildLink(
    BuildContext context,
    String label,
    String path,
    TextStyle style,
  ) {
    return Text(
      label,
      style: style.copyWith(
        color: Theme.of(context).colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
    );
  }

  // 代码块构建器
  Widget _buildCode(
    BuildContext context,
    String name,
    String code,
    bool closed,
  ) {
    return CusCodeField(name: name, codes: code);
  }

  /// 添加到缓存
  void _addToCache(String key, Widget widget) {
    if (_markdownCache.length >= _maxCacheSize) {
      _markdownCache.remove(_markdownCache.keys.first);
    }
    _markdownCache[key] = widget;
  }

  /// 清除全部缓存
  void clearCache() {
    _markdownCache.clear();
  }

  /// 从缓存中移除特定项
  void removeFromCache(String text) {
    _markdownCache.remove(text);
    _markdownCache.remove('true_$text');
    _markdownCache.remove('false_$text');
  }

  /// 获取当前缓存大小
  int get cacheSize => _markdownCache.length;
}

/// 向后兼容的API，调用单例的render方法
Widget buildCusMarkdown(String text, {Color? textColor}) =>
    CusMarkdownRenderer.instance.render(text, textColor: textColor);
