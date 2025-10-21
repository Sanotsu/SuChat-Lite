import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../data/models/unified_platform_spec.dart';
import '../../data/models/unified_model_spec.dart';
import '../../data/services/speech_synthesis_service.dart';

/// 语音合成设置对话框
class SpeechSynthesisSettingsDialog extends StatefulWidget {
  final UnifiedPlatformSpec? currentPlatform;
  final UnifiedModelSpec? currentModel;
  final Map<String, dynamic> currentSettings;
  final Function(Map<String, dynamic>) onSave;

  const SpeechSynthesisSettingsDialog({
    super.key,
    this.currentPlatform,
    this.currentModel,
    required this.currentSettings,
    required this.onSave,
  });

  @override
  State<SpeechSynthesisSettingsDialog> createState() =>
      _SpeechSynthesisSettingsDialogState();
}

class _SpeechSynthesisSettingsDialogState
    extends State<SpeechSynthesisSettingsDialog> {
  final _formKey = GlobalKey<FormBuilderState>();

  final speechService = SpeechSynthesisService();

  late Map<String, dynamic> _initialValues;

  @override
  void initState() {
    super.initState();

    // 默认设置
    final defaultSettings = {
      'voice': _getDefaultVoice(),
      'responseFormat': 'wav',
      'speed': 1.0,
      'volume': 1.0,
      // 下面这几个暂时不处理了
      // stream(默认为false，先不处理流式的)
      // languageType encodeFormat watermark gain
    };

    _initialValues = {...defaultSettings, ...widget.currentSettings};

    // 传入的配置时对话中的配置，有可能切换了平台和模型，那么音色也会变化，需要获取默认的音色
    // _initialValues['voice'] = _getDefaultVoice();
    _initialValues['voice'] =
        _getVoiceOptions().contains(widget.currentSettings['voice'])
        ? widget.currentSettings['voice']
        : _getVoiceOptions().first;

    _initialValues['responseFormat'] =
        _getFormatOptions().contains(widget.currentSettings['responseFormat'])
        ? widget.currentSettings['responseFormat']
        : 'wav';

    // 同样的语速在不同平台可能不同，超过范围的需要进行调整
    if (_initialValues['speed'] > _getSpeedRange()['max']!) {
      _initialValues['speed'] = _getSpeedRange()['max']!;
    }
    if (_initialValues['speed'] < _getSpeedRange()['min']!) {
      _initialValues['speed'] = _getSpeedRange()['min']!;
    }
  }

  String _getDefaultVoice() {
    if (widget.currentPlatform?.id == 'aliyun') {
      return 'Cherry';
    } else if (widget.currentPlatform?.id == 'siliconCloud') {
      return 'alex';
    } else if (widget.currentPlatform?.id == 'zhipu') {
      return 'tongtong';
    }
    return 'Cherry';
  }

  /// 获取平台支持的语音列表
  List<String> _getVoiceOptions() {
    String? platformId = widget.currentPlatform?.id;
    final modelName = widget.currentModel?.modelName.toLowerCase();
    switch (platformId) {
      case 'aliyun':
        if (['qwen-tts-latest', 'qwen-tts-2025-05-22'].contains(modelName)) {
          return [
            'Cherry',
            'Serena',
            'Ethan',
            'Chelsie',
            'Sunny', // 四川-晴儿
            'Jada', // 上海-阿珍
            'Dylan', // 北京-晓东
          ];
        }
        if ([
          'qwen-tts',
          'qwen-tts-2025-05-22',
          'qwen-tts-2025-04-10',
        ].contains(modelName)) {
          return ['Cherry', 'Serena', 'Ethan', 'Chelsie'];
        }
        if (modelName?.contains('qwen3-tts') ?? false) {
          return [
            'Cherry',
            'Ethan',
            'Nofish',
            'Jennifer',
            'Ryan',
            'Katerina',
            'Elias',
            'Jada', // 上海-阿珍
            'Dylan', // 北京-晓东
            'Sunny', // 四川-晴儿
            'Li', // 南京-老李
            'Marcus', // 陕西-秦川
            'Roy', // 闽南-阿杰
            'Peter', // 天津-李彼得
            'Rocky', // 粤语-阿强
            'Kiki', // 粤语-阿清
            'Eric', // 四川-程川
          ];
        }

        // 没指定的显示默认的
        return ['Cherry', 'Ethan'];
      case 'siliconCloud':
        return [
          'alex',
          'anna',
          'bella',
          'benjamin',
          'charles',
          'claire',
          'david',
          'diana',
        ];
      case 'zhipu':
        return [
          'tongtong',
          'chuichui',
          'xiaochen',
          'jam',
          'kazi',
          'douji',
          'luodo',
        ];
      default:
        return [];
    }
  }

  /// 获取平台支持的音频格式
  List<String> _getFormatOptions() {
    String? platformId = widget.currentPlatform?.id;
    switch (platformId) {
      case 'aliyun':
        return ['wav'];
      case 'siliconCloud':
        return ['mp3', 'opus', 'wav', 'pcm'];
      case 'zhipu':
        return ['pcm', 'wav'];
      default:
        return ['wav'];
    }
  }

  Map<String, double> _getSpeedRange() {
    if (widget.currentPlatform?.id == UnifiedPlatformId.siliconCloud.name) {
      return {'min': 0.25, 'max': 4.0};
    } else if (widget.currentPlatform?.id == UnifiedPlatformId.zhipu.name) {
      return {'min': 0.5, 'max': 2.0};
    }
    return {'min': 0.5, 'max': 2.0};
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
            '语音合成设置',
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
                // 语音选择
                const SizedBox(height: 10),
                FormBuilderDropdown<String>(
                  name: 'voice',
                  decoration: const InputDecoration(
                    labelText: '语音',
                    border: OutlineInputBorder(),
                  ),
                  items: _getVoiceOptions()
                      .map(
                        (voice) =>
                            DropdownMenuItem(value: voice, child: Text(voice)),
                      )
                      .toList(),
                ),

                // 音频格式
                const SizedBox(height: 10),
                FormBuilderDropdown<String>(
                  name: 'responseFormat',
                  decoration: const InputDecoration(
                    labelText: '音频格式',
                    border: OutlineInputBorder(),
                  ),
                  items: _getFormatOptions()
                      .map(
                        (format) => DropdownMenuItem(
                          value: format,
                          child: Text(format.toUpperCase()),
                        ),
                      )
                      .toList(),
                ),

                // 语速(智谱和硅基流动)
                if (widget.currentPlatform?.id !=
                    UnifiedPlatformId.aliyun.name) ...[
                  const SizedBox(height: 10),
                  FormBuilderSlider(
                    name: 'speed',
                    initialValue:
                        double.tryParse(
                          _initialValues['speed']?.toString() ?? '1',
                        ) ??
                        1.0,
                    decoration: const InputDecoration(labelText: '语速'),
                    min: _getSpeedRange()['min']!,
                    max: _getSpeedRange()['max']!,
                    divisions: 20,
                    displayValues: DisplayValues.current,
                  ),
                ],

                // 音量（仅智谱支持）
                if (widget.currentPlatform?.id ==
                    UnifiedPlatformId.zhipu.name) ...[
                  const SizedBox(height: 10),
                  FormBuilderSlider(
                    name: 'volume',
                    initialValue:
                        double.tryParse(
                          _initialValues['volume']?.toString() ?? '1',
                        ) ??
                        1.0,
                    decoration: const InputDecoration(labelText: '音量'),
                    min: 0.1,
                    max: 10.0,
                    divisions: 19,
                    displayValues: DisplayValues.current,
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
        TextButton(
          onPressed: () {
            if (_formKey.currentState?.saveAndValidate() ?? false) {
              final settings = _formKey.currentState!.value;
              widget.onSave(settings);
              Navigator.of(context).pop();
            }
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
