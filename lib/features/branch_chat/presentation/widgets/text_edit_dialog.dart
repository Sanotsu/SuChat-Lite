import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/widgets/toast_utils.dart';

class TextEditDialog extends StatefulWidget {
  final String text;
  final String title;
  final Function(String) onSaved;

  const TextEditDialog({
    super.key,
    required this.text,
    required this.onSaved,
    this.title = "编辑文本",
  });

  @override
  State<TextEditDialog> createState() => _TextEditDialogState();
}

class _TextEditDialogState extends State<TextEditDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(widget.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _controller.text));
                ToastUtils.showToast('已复制到剪贴板');
              },
            ),
            TextButton(
              onPressed: () {
                widget.onSaved(_controller.text);
                Navigator.pop(context);
                ToastUtils.showToast('保存成功');
              },
              child: const Text('保存'),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _controller,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '编辑文本内容...',
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
