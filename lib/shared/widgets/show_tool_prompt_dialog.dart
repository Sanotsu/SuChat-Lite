import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/screen_helper.dart';
import 'markdown_render/cus_markdown_renderer.dart';
import 'toast_utils.dart';

/// 显示提示词预览/编辑对话框
///
/// [context] - 上下文
/// [initialPrompt] - 初始提示词
/// [title] - 对话框标题，默认为"预览提示词"
/// [previewTitle] - 预览模式的标题，默认为"预览提示词"
/// [editTitle] - 编辑模式的标题，默认为"编辑提示词"
/// [confirmButtonText] - 确认按钮文本，默认为"用此提示词生成"
/// [cancelButtonText] - 取消按钮文本，默认为"取消"
/// [editButtonTooltip] - 编辑按钮提示文本，默认为"编辑"
/// [previewButtonTooltip] - 预览按钮提示文本，默认为"预览"
/// [copyTooltip] - 复制按钮提示文本，默认为"复制到剪贴板"
/// [copiedMessage] - 复制成功消息，默认为"提示词已复制到剪贴板"
/// [previewHint] - 预览模式提示文本
/// [editHint] - 编辑模式提示文本
///
/// 返回值：
/// PromptDialogResult? 包含以下字段：
/// - "useCustomPrompt": 布尔值，表示是否使用自定义提示词
/// - "customPrompt": 字符串，用户编辑后的提示词内容
/// 如果用户点击取消，则返回null
Future<PromptDialogResult?> showToolPromptDialog({
  required BuildContext context,
  required String initialPrompt,
  String? title,
  String previewTitle = '预览提示词',
  String editTitle = '编辑提示词',
  String confirmButtonText = '用此提示词生成',
  String cancelButtonText = '取消',
  String editButtonTooltip = '编辑',
  String previewButtonTooltip = '预览',
  String copyTooltip = '复制到剪贴板',
  String copiedMessage = '提示词已复制到剪贴板',
  String previewHint = '以下是根据您的选择生成的提示词，点击右上角编辑按钮可以修改。',
  String editHint = '您可以根据需要修改提示词，修改后将使用您的自定义提示词生成。',
}) async {
  final promptController = TextEditingController(text: initialPrompt);
  bool isEditMode = false;
  bool hasEdited = false;

  final result = await showDialog<PromptDialogResult>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          // 确定按钮点击处理
          void onConfirm() {
            // 检查是否有编辑过提示词
            final isCustomPrompt = hasEdited || isEditMode;
            final customPrompt = promptController.text.trim();

            Navigator.of(context).pop(
              PromptDialogResult(
                useCustomPrompt: isCustomPrompt,
                customPrompt: customPrompt,
              ),
            );
          }

          // 复制提示词到剪贴板
          void copyToClipboard() {
            Clipboard.setData(ClipboardData(text: promptController.text));
            ToastUtils.showToast(copiedMessage);
          }

          // 切换编辑/预览模式
          void toggleEditMode() {
            setState(() {
              isEditMode = !isEditMode;
            });
          }

          // 监听文本变化，标记是否有编辑
          void onTextChanged() {
            if (promptController.text != initialPrompt) {
              hasEdited = true;
            }
          }

          // 添加文本变化监听
          promptController.addListener(onTextChanged);

          return ScreenHelper.isMobile()
              ? _buildMobilePromptDialog(
                context,
                promptController,
                isEditMode,
                toggleEditMode,
                copyToClipboard,
                onConfirm,
                previewTitle: previewTitle,
                editTitle: editTitle,
                confirmButtonText: confirmButtonText,
                cancelButtonText: cancelButtonText,
                editButtonTooltip: editButtonTooltip,
                previewButtonTooltip: previewButtonTooltip,
                copyTooltip: copyTooltip,
              )
              : _buildDesktopPromptDialog(
                context,
                promptController,
                isEditMode,
                toggleEditMode,
                copyToClipboard,
                onConfirm,
                previewTitle: previewTitle,
                editTitle: editTitle,
                confirmButtonText: confirmButtonText,
                cancelButtonText: cancelButtonText,
                editButtonTooltip: editButtonTooltip,
                previewButtonTooltip: previewButtonTooltip,
                copyTooltip: copyTooltip,
                previewHint: previewHint,
                editHint: editHint,
              );
        },
      );
    },
  );

  return result;
}

// 移动端的全屏提示词对话框
Widget _buildMobilePromptDialog(
  BuildContext context,
  TextEditingController promptController,
  bool isEditMode,
  VoidCallback onModeChanged,
  VoidCallback onCopy,
  VoidCallback onConfirm, {
  required String previewTitle,
  required String editTitle,
  required String confirmButtonText,
  required String cancelButtonText,
  required String editButtonTooltip,
  required String previewButtonTooltip,
  required String copyTooltip,
}) {
  return Dialog.fullscreen(
    child: Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? editTitle : previewTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: copyTooltip,
            onPressed: onCopy,
          ),
          IconButton(
            icon: Icon(isEditMode ? Icons.visibility : Icons.edit),
            tooltip: isEditMode ? previewButtonTooltip : editButtonTooltip,
            onPressed: onModeChanged,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child:
                  isEditMode
                      ? TextField(
                        controller: promptController,
                        maxLines: null,
                        expands: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '请输入自定义提示词...',
                        ),
                      )
                      : RepaintBoundary(
                        child: SingleChildScrollView(
                          child: CusMarkdownRenderer.instance.render(
                            promptController.text,
                            textStyle: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(cancelButtonText),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: Text(confirmButtonText),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// 桌面端的提示词对话框
Widget _buildDesktopPromptDialog(
  BuildContext context,
  TextEditingController promptController,
  bool isEditMode,
  VoidCallback onModeChanged,
  VoidCallback onCopy,
  VoidCallback onConfirm, {
  required String previewTitle,
  required String editTitle,
  required String confirmButtonText,
  required String cancelButtonText,
  required String editButtonTooltip,
  required String previewButtonTooltip,
  required String copyTooltip,
  required String previewHint,
  required String editHint,
}) {
  return AlertDialog(
    title: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(isEditMode ? editTitle : previewTitle),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: copyTooltip,
              onPressed: onCopy,
            ),
            IconButton(
              icon: Icon(isEditMode ? Icons.visibility : Icons.edit),
              tooltip: isEditMode ? previewButtonTooltip : editButtonTooltip,
              onPressed: onModeChanged,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    ),
    content: SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        children: [
          Text(
            isEditMode ? editHint : previewHint,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Expanded(
            child:
                isEditMode
                    ? TextField(
                      controller: promptController,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '请输入自定义提示词...',
                      ),
                    )
                    : RepaintBoundary(
                      child: SingleChildScrollView(
                        child: CusMarkdownRenderer.instance.render(
                          promptController.text,
                          textStyle: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(cancelButtonText),
      ),
      ElevatedButton(
        onPressed: onConfirm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        child: Text(confirmButtonText),
      ),
    ],
  );
}

class PromptDialogResult {
  final bool useCustomPrompt;
  final String customPrompt;

  const PromptDialogResult({
    required this.useCustomPrompt,
    required this.customPrompt,
  });
}
