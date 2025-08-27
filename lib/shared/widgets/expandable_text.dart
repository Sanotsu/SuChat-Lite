import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle? style;
  final TextStyle? buttonStyle;
  final List<TextMenuAction>? menuActions;

  const ExpandableText({
    super.key,
    required this.text,
    this.maxLines = 5,
    this.style,
    this.buttonStyle,
    this.menuActions = const [TextMenuAction.copy],
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded = false;
  final GlobalKey _textKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 创建文本样式
        final textStyle =
            widget.style ?? const TextStyle(fontSize: 15, height: 1.5);

        // 创建文本布局
        final textSpan = TextSpan(text: widget.text, style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          maxLines: widget.maxLines,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout(maxWidth: constraints.maxWidth);

        // 判断文本是否超过指定行数
        final isOverflowed = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 文本内容 - 添加长按复制功能
            GestureDetector(
              key: _textKey,
              onLongPressStart: (details) {
                // 保存长按位置
                _showTextMenuAtPosition(context, details.globalPosition);
              },
              child: Text(
                widget.text,
                style: textStyle,
                maxLines: _isExpanded ? null : widget.maxLines,
                overflow: _isExpanded ? null : TextOverflow.ellipsis,
                textAlign: TextAlign.justify,
              ),
            ),

            // 展开/收起按钮（只有在文本溢出时才显示）
            if (isOverflowed || _isExpanded)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    _isExpanded ? '收起' : '全文',
                    style:
                        widget.buttonStyle ??
                        TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // 在指定位置显示文本菜单
  void _showTextMenuAtPosition(BuildContext context, Offset globalPosition) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // 计算弹窗位置，确保不会超出屏幕
    double left = globalPosition.dx;
    double top = globalPosition.dy;

    // 水平方向调整
    if (left > screenWidth - 200) {
      left = screenWidth - 200;
    }
    if (left < 0) {
      left = 8;
    }

    // 垂直方向调整
    if (top > screenHeight - 200) {
      top = screenHeight - 200;
    }
    if (top < 0) {
      top = 8;
    }

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        left,
        top,
        screenWidth - left,
        screenHeight - top,
      ),
      items: widget.menuActions!.map((action) {
        return PopupMenuItem(
          value: action,
          height: 48,
          child: Row(
            children: [
              Icon(action.icon, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 12),
              Text(action.label, style: const TextStyle(fontSize: 16)),
            ],
          ),
        );
      }).toList(),
    ).then((value) {
      if (value != null) {
        _handleMenuAction(value, widget.text);
      }
    });
  }

  // 处理菜单操作
  void _handleMenuAction(TextMenuAction action, String text) {
    switch (action.type) {
      case TextMenuActionType.copy:
        _copyToClipboard(text);
        break;
      case TextMenuActionType.share:
        _shareText(text);
        break;
      case TextMenuActionType.reply:
        _replyToText(text);
        break;
      case TextMenuActionType.translate:
        _translateText(text);
        break;
      case TextMenuActionType.selectAll:
        _selectAllText(text);
        break;
    }
  }

  // 复制到剪贴板（除了这个其他都是预留的）
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSuccessSnackBar('已复制到剪贴板');
  }

  // 分享文本
  void _shareText(String text) {
    _showSuccessSnackBar('分享功能准备中');
  }

  // 回复文本
  void _replyToText(String text) {
    _showSuccessSnackBar('回复: ${_truncateText(text, 20)}');
  }

  // 翻译文本
  void _translateText(String text) {
    _showSuccessSnackBar('翻译功能准备中');
  }

  // 全选文本
  void _selectAllText(String text) {
    _showSuccessSnackBar('已全选文本');
  }

  // 显示成功提示
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 截断文本
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}

// 菜单操作类型
enum TextMenuActionType { copy, share, reply, translate, selectAll }

// 菜单操作类
class TextMenuAction {
  final TextMenuActionType type;
  final String label;
  final IconData icon;

  const TextMenuAction({
    required this.type,
    required this.label,
    required this.icon,
  });

  // 预定义的操作
  static const TextMenuAction copy = TextMenuAction(
    type: TextMenuActionType.copy,
    label: '复制',
    icon: Icons.content_copy,
  );

  static const TextMenuAction share = TextMenuAction(
    type: TextMenuActionType.share,
    label: '分享',
    icon: Icons.share,
  );

  static const TextMenuAction reply = TextMenuAction(
    type: TextMenuActionType.reply,
    label: '回复',
    icon: Icons.reply,
  );

  static const TextMenuAction translate = TextMenuAction(
    type: TextMenuActionType.translate,
    label: '翻译',
    icon: Icons.translate,
  );

  static const TextMenuAction selectAll = TextMenuAction(
    type: TextMenuActionType.selectAll,
    label: '全选',
    icon: Icons.select_all,
  );
}
