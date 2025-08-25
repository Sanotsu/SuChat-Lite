import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/style/app_colors.dart';
import '../../../../../shared/widgets/toast_utils.dart';

/// 翻译结果显示区域组件
class TranslationResultSection extends StatelessWidget {
  final String? translatedText;
  final bool hasError;
  final String? errorMessage;
  final bool isLoading;

  const TranslationResultSection({
    super.key,
    this.translatedText,
    this.hasError = false,
    this.errorMessage,
    this.isLoading = false,
  });

  void _copyToClipboard() {
    if (translatedText != null && translatedText!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: translatedText!));
      ToastUtils.showToast('翻译结果已复制到剪贴板');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Icon(Icons.text_snippet, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '翻译结果',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (translatedText != null && translatedText!.isNotEmpty)
                  IconButton(
                    onPressed: _copyToClipboard,
                    icon: Icon(Icons.copy, size: 20),
                    tooltip: '复制翻译结果',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // 内容区域
            Container(
              width: double.infinity,
              constraints: BoxConstraints(minHeight: 120),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            '正在翻译中...',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      );
    }

    if (hasError) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 32),
          const SizedBox(height: 8),
          Text(
            '翻译失败',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              errorMessage!,
              style: TextStyle(color: Colors.red[700], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      );
    }

    if (translatedText != null && translatedText!.isNotEmpty) {
      return SelectableText(
        translatedText!,
        style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.translate, color: Colors.grey[400], size: 32),
        const SizedBox(height: 8),
        Text(
          '翻译结果将在这里显示',
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
      ],
    );
  }
}
