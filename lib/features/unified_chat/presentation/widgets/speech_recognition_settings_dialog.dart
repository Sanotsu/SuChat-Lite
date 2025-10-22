import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../data/models/unified_platform_spec.dart';
import '../../data/models/unified_model_spec.dart';

/// 语音识别设置对话框
class SpeechRecognitionSettingsDialog extends StatefulWidget {
  final UnifiedPlatformSpec? currentPlatform;
  final UnifiedModelSpec? currentModel;
  final Map<String, dynamic> currentSettings;
  final Function(Map<String, dynamic>) onSave;

  const SpeechRecognitionSettingsDialog({
    super.key,
    this.currentPlatform,
    this.currentModel,
    required this.currentSettings,
    required this.onSave,
  });

  @override
  State<SpeechRecognitionSettingsDialog> createState() =>
      _SpeechRecognitionSettingsDialogState();
}

class _SpeechRecognitionSettingsDialogState
    extends State<SpeechRecognitionSettingsDialog> {
  final _formKey = GlobalKey<FormBuilderState>();

  late Map<String, dynamic> _initialValues;

  @override
  void initState() {
    super.initState();

    // 默认设置(虽然有这些，但是暂时没让都生效)
    final defaultSettings = {
      'language': 'zh',
      'temperature': 0.95,
      'stream': false,
      'enableLid': false,
      'enableItn': false,
      'context': '',
      'requestId': null,
      'userId': null,
    };

    // 合并当前设置和默认设置
    _initialValues = {...defaultSettings, ...widget.currentSettings};

    // 传入的配置时对话中的配置，有可能切换了平台和模型，那么语言也会变化，需要获取默认的语言
    _initialValues['language'] = 'zh';
  }

  bool _shouldShowLanguageSettings() {
    // 所有平台都支持语言设置
    return widget.currentPlatform?.id == 'aliyun';
  }

  List<Map<String, String>> _getLanguageOptions() {
    if (widget.currentPlatform?.id == 'aliyun') {
      return [
        {'value': 'zh', 'label': '中文'},
        {'value': 'en', 'label': '英语'},
        {'value': 'ja', 'label': '日语'},
        {'value': 'de', 'label': '德语'},
        {'value': 'ko', 'label': '韩语'},
        {'value': 'ru', 'label': '俄语'},
        {'value': 'fr', 'label': '法语'},
        {'value': 'pt', 'label': '葡萄牙语'},
        {'value': 'ar', 'label': '阿拉伯语'},
        {'value': 'it', 'label': '意大利语'},
        {'value': 'es', 'label': '西班牙语'},
      ];
    }
    return [
      {'value': 'zh', 'label': '中文'},
      {'value': 'en', 'label': '英语'},
    ];
  }

  void _resetSettings() {
    _formKey.currentState?.reset();
  }

  void _saveSettings() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formValues = _formKey.currentState!.value;

      // 清理空值
      final cleanedValues = <String, dynamic>{};
      formValues.forEach((key, value) {
        if (value != null && value != '') {
          cleanedValues[key] = value;
        }
      });

      widget.onSave(cleanedValues);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.image, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            '语音识别设置',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Tooltip(
            message: '注意: 因模型不同，部分设置可能不会生效。',
            triggerMode: TooltipTriggerMode.tap,
            showDuration: Duration(seconds: 20),
            margin: EdgeInsets.all(24),
            child: Icon(Icons.info_outline, size: 24, color: Colors.grey),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: FormBuilder(
          key: _formKey,
          initialValue: _initialValues,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 语言设置
                if (_shouldShowLanguageSettings())
                  FormBuilderDropdown<String>(
                    name: 'language',
                    decoration: const InputDecoration(
                      labelText: '识别语言',
                      hintText: '选择要识别的语言',
                    ),
                    initialValue: _initialValues['language'] as String?,
                    items: _getLanguageOptions()
                        .map(
                          (lang) => DropdownMenuItem(
                            value: lang['value']!,
                            child: Text(lang['label']!),
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 16),

                // 流式输出（阿里云、智谱平台）
                if (widget.currentPlatform?.id == 'zhipu' ||
                    widget.currentPlatform?.id == 'aliyun')
                  FormBuilderSwitch(
                    name: 'stream',
                    title: const Text('流式输出'),
                    subtitle: const Text('是否启用流式输出'),
                  ),
                const SizedBox(height: 16),

                // 阿里百炼特有设置
                if (widget.currentPlatform?.id == 'aliyun') ...[
                  FormBuilderSwitch(
                    name: 'enableLid',
                    title: const Text('语种识别'),
                    subtitle: const Text('是否在识别结果中显示语种信息'),
                  ),
                  const SizedBox(height: 16),
                  FormBuilderSwitch(
                    name: 'enableItn',
                    title: const Text('逆文本规范化'),
                    subtitle: const Text('将数字等转换为标准格式（仅支持中英文）'),
                  ),
                  const SizedBox(height: 16),
                  FormBuilderTextField(
                    name: 'context',
                    decoration: const InputDecoration(
                      labelText: '上下文',
                      hintText: '输入上下文信息以提高识别准确率',
                    ),
                    maxLines: 3,
                  ),
                ],

                // 智谱平台特有设置
                if (widget.currentPlatform?.id == 'zhipu') ...[
                  // 采样温度
                  FormBuilderSlider(
                    name: 'temperature',
                    decoration: const InputDecoration(
                      labelText: '采样温度',
                      helperText: '控制输出的随机性，值越大越随机',
                    ),
                    initialValue:
                        (_initialValues['temperature'] as double?) ?? 0.95,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    valueTransformer: (value) => value?.toDouble(),
                  ),
                  const SizedBox(height: 16),
                  FormBuilderTextField(
                    name: 'requestId',
                    decoration: const InputDecoration(
                      labelText: '请求ID',
                      hintText: '可选的唯一请求标识符',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FormBuilderTextField(
                    name: 'userId',
                    decoration: const InputDecoration(
                      labelText: '用户ID',
                      hintText: '终端用户的唯一ID（6-128字符）',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(onPressed: _resetSettings, child: const Text('重置')),
        ElevatedButton(onPressed: _saveSettings, child: const Text('保存')),
      ],
    );
  }
}
