import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/screen_helper.dart';
import '../../../../shared/widgets/toast_utils.dart';

class TextSelectionDialog extends StatelessWidget {
  final String text;
  final String title;

  const TextSelectionDialog({
    super.key,
    required this.text,
    this.title = "选择文本",
  });

  @override
  Widget build(BuildContext context) {
    final content = Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              ToastUtils.showToast('已复制到剪贴板');
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: SelectableText(text, style: TextStyle(fontSize: 16)),
      ),
    );

    // 桌面用固定尺寸窗口弹窗，移动端保持全屏
    if (ScreenHelper.isDesktop()) {
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 560),
          child: content,
        ),
      );
    }
    return Dialog.fullscreen(child: content);
  }
}
