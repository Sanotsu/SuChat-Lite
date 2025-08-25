import 'package:flutter/material.dart';

import '../../../../../core/entities/cus_llm_model.dart';
import '../../../../../core/theme/style/app_colors.dart';
import '../../../../../shared/constants/constant_llm_enum.dart';
import '../../../../../shared/services/model_manager_service.dart';
import '../../../../../shared/widgets/cus_dropdown_button.dart';
import '../../../data/models/translator_supported_languages.dart';

/// 翻译配置区域组件
class TranslationConfigSection extends StatefulWidget {
  final LanguageOption sourceLanguage;
  final LanguageOption targetLanguage;
  final Function(LanguageOption) onSourceLanguageChanged;
  final Function(LanguageOption) onTargetLanguageChanged;
  final Function() onSwapLanguages;
  final Function(CusLLMSpec?) onTranslate;
  final bool isTranslating;
  final bool isEnabled;

  const TranslationConfigSection({
    super.key,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.onSourceLanguageChanged,
    required this.onTargetLanguageChanged,
    required this.onSwapLanguages,
    required this.onTranslate,
    this.isTranslating = false,
    this.isEnabled = true,
  });

  @override
  State<TranslationConfigSection> createState() =>
      _TranslationConfigSectionState();
}

class _TranslationConfigSectionState extends State<TranslationConfigSection> {
  // 模型列表
  List<CusLLMSpec> modelList = [];
  // 选中的模型
  CusLLMSpec? selectedModel;

  @override
  void initState() {
    super.initState();

    _loadModels();
  }

  Future<void> _loadModels() async {
    final models = await ModelManagerService.getAvailableModelByTypes([
      LLModelType.cc,
    ]);

    // 只使用qwen-mt模型
    // models.removeWhere((e) => !e.model.contains("qwen-mt"));

    if (!mounted) return;
    setState(() {
      modelList = models;
      selectedModel = models.isNotEmpty ? models.first : null;
    });
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
                Icon(Icons.translate, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '翻译设置',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              '模型选择',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: buildDropdownButton2<CusLLMSpec?>(
                    value: selectedModel,
                    items: modelList,
                    height: 48,
                    hintLabel: "选择模型",
                    itemsEmptyHint: "尚无可选翻译模型列表",
                    alignment: Alignment.centerLeft,
                    onChanged: widget.isTranslating
                        ? null
                        : (value) {
                            setState(() {
                              selectedModel = value!;
                            });
                          },
                    itemToString: (e) =>
                        "${CP_NAME_MAP[(e as CusLLMSpec).platform]} - ${e.name}",
                  ),
                ),
              ],
            ),
            // 语言选择区域
            Row(
              children: [
                // 源语言选择
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '源语言',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),

                      buildDropdownButton2<LanguageOption?>(
                        value: widget.sourceLanguage,
                        items: SupportedLanguages.languages,
                        height: 48,
                        itemMaxHeight: 200,
                        hintLabel: "选择源语言",
                        alignment: Alignment.centerLeft,
                        onChanged: widget.isEnabled
                            ? (LanguageOption? value) {
                                if (value != null) {
                                  widget.onSourceLanguageChanged(value);
                                }
                              }
                            : null,
                        itemToString: (e) => (e as LanguageOption).name,
                      ),
                    ],
                  ),
                ),

                // 交换按钮
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 0),
                  child: Column(
                    children: [
                      const SizedBox(height: 24), // 对齐下拉框
                      IconButton(
                        onPressed: widget.isEnabled
                            ? widget.onSwapLanguages
                            : null,
                        icon: Icon(
                          Icons.swap_horiz,
                          color: widget.isEnabled
                              ? AppColors.primary
                              : Colors.grey,
                        ),
                        tooltip: '交换语言',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 目标语言选择
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '目标语言',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),

                      buildDropdownButton2<LanguageOption?>(
                        value: widget.targetLanguage,
                        items: SupportedLanguages.languages,
                        height: 48,
                        itemMaxHeight: 200,
                        hintLabel: "选择目标语言",
                        alignment: Alignment.centerLeft,
                        onChanged: widget.isEnabled
                            ? (LanguageOption? value) {
                                if (value != null) {
                                  widget.onTargetLanguageChanged(value);
                                }
                              }
                            : null,
                        itemToString: (e) => (e as LanguageOption).name,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 翻译按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    widget.isEnabled &&
                        !widget.isTranslating &&
                        selectedModel != null
                    ? () => widget.onTranslate(selectedModel)
                    : null,
                icon: widget.isTranslating
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.translate),
                label: Text(widget.isTranslating ? '翻译中...' : '开始翻译'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            // 提示信息
            const SizedBox(height: 8),
            Text(
              '💡 支持${SupportedLanguages.languages.length}种语言互译',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
