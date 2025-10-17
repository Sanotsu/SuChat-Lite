import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../data/models/unified_platform_spec.dart';
import '../../data/models/unified_model_spec.dart';

/// 图片生成设置对话框
class ImageGenerationSettingsDialog extends StatefulWidget {
  final UnifiedPlatformSpec? currentPlatform;
  final UnifiedModelSpec? currentModel;
  final Map<String, dynamic> currentSettings;
  final Function(Map<String, dynamic>) onSave;

  const ImageGenerationSettingsDialog({
    super.key,
    this.currentPlatform,
    this.currentModel,
    required this.currentSettings,
    required this.onSave,
  });

  @override
  State<ImageGenerationSettingsDialog> createState() =>
      _ImageGenerationSettingsDialogState();
}

class _ImageGenerationSettingsDialogState
    extends State<ImageGenerationSettingsDialog> {
  final _formKey = GlobalKey<FormBuilderState>();

  late Map<String, dynamic> _initialValues;

  // 添加状态变量来跟踪当前选择的值
  String? _currentSourceLanguage;
  String? _currentTargetLanguage;

  // 简化一些判断的逻辑
  bool get isQwenMtImage =>
      widget.currentModel?.modelName.contains('qwen-mt-image') ?? false;

  bool get isAliyunPlatform =>
      widget.currentPlatform?.id == UnifiedPlatformId.aliyun.name;

  bool get isSiliconCloudPlatform =>
      widget.currentPlatform?.id == UnifiedPlatformId.siliconCloud.name;

  bool get isZhipuPlatform =>
      widget.currentPlatform?.id == UnifiedPlatformId.zhipu.name;

  @override
  void initState() {
    super.initState();

    // 默认设置
    final defaultSettings = {
      'size': '1024x1024',
      'quality': 'standard',
      'n': 1.0, // 滑块需要double类型
      'seed': null,
      'steps': 20,
      'guidanceScale': 7.5,
      'watermark': true,
      'negativePrompt': '',
      'sourceLanguage': 'auto',
      'targetLanguage': 'zh',
    };

    _initialValues = {...defaultSettings, ...widget.currentSettings};

    final supportedSizes = _getSupportedSizes();
    // 传入的配置中尺寸可能与平台模型支持的尺寸不一致，需要进行调整
    _initialValues['size'] =
        (supportedSizes.isNotEmpty &&
            supportedSizes.contains(_initialValues['size']))
        ? _initialValues['size']
        : supportedSizes.isNotEmpty
        ? supportedSizes.first
        : '1024x1024';

    // 初始化状态变量
    _currentSourceLanguage = _initialValues['sourceLanguage'] as String?;
    _currentTargetLanguage = _initialValues['targetLanguage'] as String?;
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
            '图片生成设置',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                // 尺寸选择
                const SizedBox(height: 10),

                if (!isQwenMtImage) _buildSizeSelector(),

                // 数量选择
                const SizedBox(height: 10),
                _buildImageCountSlider(),
                const SizedBox(height: 10),

                // 质量选择
                if (isZhipuPlatform) _buildQualitySelector(),
                // 智谱、火山方舟的没有负面提示词栏位
                if ((isAliyunPlatform || isSiliconCloudPlatform) &&
                    !isQwenMtImage)
                  _buildNegativePromptField(),
                // 硅基流动的没有水印栏位
                if (!isSiliconCloudPlatform && !isQwenMtImage)
                  _buildWatermarkField(),

                // 只有阿里云的qwen-mt-image有语言选择
                if (isAliyunPlatform && isQwenMtImage) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildSourceLanguageSelector()),
                      const SizedBox(width: 8),
                      Expanded(child: _buildTargetLanguageSelector()),
                    ],
                  ),
                ],

                // 高级设置
                // TEST 暂时只有硅基流动的
                if (isSiliconCloudPlatform) _buildAdvancedSettings(),
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
        TextButton(onPressed: _resetToDefaults, child: const Text('重置')),
        ElevatedButton(onPressed: _saveSettings, child: const Text('保存')),
      ],
    );
  }

  Widget _buildSizeSelector() {
    final supportedSizes = _getSupportedSizes();
    final currentSize = _initialValues['size']?.toString();
    final validInitialSize = supportedSizes.contains(currentSize)
        ? currentSize
        : (supportedSizes.isNotEmpty ? supportedSizes.first : '1024x1024');

    return FormBuilderDropdown<String>(
      name: 'size',
      // initialValue: _initialValues['size']?.toString(),
      initialValue: validInitialSize,
      decoration: const InputDecoration(
        labelText: '图片尺寸',
        border: OutlineInputBorder(),
      ),
      items: supportedSizes
          .map((size) => DropdownMenuItem(value: size, child: Text(size)))
          .toList(),
    );
  }

  Widget _buildImageCountSlider() {
    final maxCount = _getMaxImageCount();
    if (maxCount <= 1) return const SizedBox.shrink();

    return FormBuilderField<double>(
      name: 'n',
      initialValue:
          double.tryParse(_initialValues['n']?.toString() ?? '1') ?? 1.0,
      builder: (FormFieldState<double> field) {
        return Row(
          children: [
            // 左侧标签
            const Text('数量', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 12),
            // 滑块
            Expanded(
              child: Slider(
                value: field.value ?? 1.0,
                min: 1,
                max: maxCount.toDouble(),
                divisions: maxCount - 1,
                onChanged: (value) {
                  field.didChange(value);
                },
              ),
            ),
            const SizedBox(width: 12),
            // 右侧数值显示
            Container(
              width: 30,
              alignment: Alignment.center,
              child: Text(
                '${field.value?.toInt() ?? 1}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQualitySelector() {
    final supportedQualities = _getSupportedQualities();
    if (supportedQualities.length <= 1) return const SizedBox.shrink();

    return FormBuilderDropdown<String>(
      name: 'quality',
      initialValue: _initialValues['quality']?.toString(),
      decoration: const InputDecoration(
        labelText: '图片质量',
        border: OutlineInputBorder(),
      ),
      items: supportedQualities
          .map(
            (quality) => DropdownMenuItem(
              value: quality,
              child: Text(quality == 'standard' ? '标准' : '高清'),
            ),
          )
          .toList(),
    );
  }

  Widget _buildNegativePromptField() {
    return FormBuilderTextField(
      name: 'negativePrompt',
      initialValue: _initialValues['negativePrompt'] as String?,
      decoration: const InputDecoration(
        labelText: '负面提示词（可选）',
        hintText: '描述不想要的元素...',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }

  Widget _buildWatermarkField() {
    return FormBuilderSwitch(
      name: 'watermark',
      initialValue: _initialValues['watermark']?.toString() == 'true',
      title: const Text('添加AI水印'),
      subtitle: const Text('是否在生成的图片上添加AI水印'),
    );
  }

  // 源语言选择器
  Widget _buildSourceLanguageSelector() {
    final supportedLanguages = _getSupportedSourceLanguages(
      _currentTargetLanguage,
    );
    return FormBuilderDropdown<String>(
      name: 'sourceLanguage',
      // initialValue: _currentSourceLanguage,
      // 使用 value 而不是 initialValue，确保值在选项中
      initialValue: supportedLanguages.contains(_currentSourceLanguage)
          ? _currentSourceLanguage
          : supportedLanguages.first,
      decoration: const InputDecoration(
        labelText: '源语言',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _currentSourceLanguage = value;

            // 如果新的源语言不是auto/zh/en，且当前目标语言不是zh/en，则重置目标语言
            if (value != 'auto' && value != 'zh' && value != 'en') {
              if (_currentTargetLanguage != 'zh' &&
                  _currentTargetLanguage != 'en') {
                _currentTargetLanguage = 'zh';
                // 更新表单字段的值
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _formKey.currentState?.fields['targetLanguage']?.didChange(
                    'zh',
                  );
                });
              }
            }
          });
        }
      },
      items: _getSupportedSourceLanguages(_currentTargetLanguage)
          .map(
            (language) => DropdownMenuItem(
              value: language,
              child: Text(_getLanguageDisplayName(language)),
            ),
          )
          .toList(),
    );
  }

  // 目标语言选择器
  Widget _buildTargetLanguageSelector() {
    final supportedLanguages = _getSupportedTargetLanguages(
      _currentSourceLanguage,
    );

    return FormBuilderDropdown<String>(
      name: 'targetLanguage',
      // initialValue: _currentTargetLanguage,
      // 使用 value 而不是 initialValue，确保值在选项中
      initialValue: supportedLanguages.contains(_currentTargetLanguage)
          ? _currentTargetLanguage
          : supportedLanguages.first,
      decoration: const InputDecoration(
        labelText: '目标语言',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _currentTargetLanguage = value;

            // 如果新的目标语言不是zh/en，且当前源语言不是auto/zh/en，则重置源语言
            if (value != 'zh' && value != 'en') {
              if (_currentSourceLanguage != 'auto' &&
                  _currentSourceLanguage != 'zh' &&
                  _currentSourceLanguage != 'en') {
                _currentSourceLanguage = 'auto';
                // 更新表单字段的值
                // 使用 addPostFrameCallback 确保在下一帧更新表单
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _formKey.currentState?.fields['sourceLanguage']?.didChange(
                    'auto',
                  );
                });
              }
            }
          });
        }
      },
      items: _getSupportedTargetLanguages(_currentSourceLanguage)
          .map(
            (language) => DropdownMenuItem(
              value: language,
              child: Text(_getLanguageDisplayName(language)),
            ),
          )
          .toList(),
    );
  }

  Widget _buildAdvancedSettings() {
    return ExpansionTile(
      title: const Text('高级设置'),
      children: [
        const SizedBox(height: 10),
        if (isSiliconCloudPlatform) ...[
          FormBuilderTextField(
            name: 'seed',
            initialValue: _initialValues['seed']?.toString(),
            decoration: const InputDecoration(
              labelText: '随机种子',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          FormBuilderTextField(
            name: 'steps',
            initialValue: _initialValues['steps']?.toString(),
            decoration: const InputDecoration(
              labelText: '推理步数',
              hintText: '默认20步',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.integer(),
              FormBuilderValidators.min(1),
              FormBuilderValidators.max(100),
            ]),
          ),
          const SizedBox(height: 10),
          FormBuilderTextField(
            name: 'guidanceScale',
            initialValue: _initialValues['guidanceScale']?.toString(),
            decoration: const InputDecoration(
              labelText: '引导强度',
              hintText: '默认7.5',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.numeric(),
              FormBuilderValidators.min(1.0),
              FormBuilderValidators.max(20.0),
            ]),
          ),
        ],
      ],
    );
  }

  List<String> _getSupportedSizes() {
    // 模型名称才是请求时作为model参数的那个值
    final modelName = widget.currentModel?.modelName.toLowerCase();

    switch (widget.currentPlatform?.id) {
      case 'aliyun':
        // qwen-image 系列
        if (modelName?.startsWith('qwen-image') ?? false) {
          return [
            '1328*1328',
            '1664*928',
            '1472*1140',
            '1140*1472',
            '928*1664',
          ];
        }

        // 文生图V2系列
        if ((modelName?.startsWith('wanx2') ?? false) ||
            (modelName?.startsWith('wan2') ?? false)) {
          return [
            '1024*1024',
            '800*1200',
            '1200*800',
            '960*1280',
            '1280*960',
            '720*1280',
            '1280*720',
            '1344*576',
          ];
        }

        // 如果是flux系列模型
        if (modelName?.startsWith('flux-') ?? false) {
          return [
            '1024*1024',
            '512*1024',
            '768*512',
            '768*1024',
            '1024*576',
            '576*1024',
          ];
        }

        return [];
      case 'siliconCloud':

        // 如果是kolor模型
        if (modelName?.startsWith('kolor') ?? false) {
          return ['1024x1024', '960x1280', '768x1024', '720x1440', '720x1280'];
        }
        // 如果是qwen-image模型
        if (modelName?.startsWith('qwen-image') ?? false) {
          return [
            '1328x1328',
            '1664x928',
            '928x1664',
            '1472x1140',
            '1140x1472',
            '1584x1056',
            '1056x1584',
          ];
        }

        return [];
      case 'zhipu':
        return [
          '1024x1024',
          '768x1344',
          '864x1152',
          '1344x768',
          '1152x864',
          '1440x720',
          '720x1440',
        ];
      case 'volcengine':
        // doubao-seedream-4.0 系列
        if (modelName?.startsWith('doubao-seedream-4-0') ?? false) {
          return ['1K', '2K', '4K'];
        }
        // doubao-seedream-3.0-t2i 系列
        if (modelName?.startsWith('doubao-seedream-3-0-t2i') ?? false) {
          return [
            '1024x1024',
            '1152x864',
            '864x1152',
            '1280x720',
            '720x1280',
            '1248x832',
            '832x1248',
            '1512x648',
          ];
        }
        if (modelName?.startsWith('doubao-seededit-3-0-i2i') ?? false) {
          return ['adaptive'];
        }
        return [];

      default:
        return ['1024x1024'];
    }
  }

  // 获取支持的源语言（根据当前目标语言动态计算）
  List<String> _getSupportedSourceLanguages(String? currentTargetLanguage) {
    final allLanguages = [
      // 所有支持的语言
      'auto', 'zh', 'en', 'ko', 'ja', 'ru', 'es', 'fr', 'pt', 'it', 'de', 'vi',
    ];

    // 如果目标语言是zh或en，源语言可以是所有语言
    if (currentTargetLanguage == 'zh' || currentTargetLanguage == 'en') {
      return allLanguages;
    }
    // 如果目标语言不是zh或en，源语言只能是auto、zh、en
    else {
      return ['auto', 'zh', 'en'];
    }
  }

  // (只有阿里云的qwen-mt-image支持)
  // 获取支持的目标语言（根据当前源语言动态计算）
  List<String> _getSupportedTargetLanguages(String? currentSourceLanguage) {
    final allLanguages = [
      // 所有支持的语言（比源语言多几个）
      // 中文翻译中文不知道行不行？？？？
      'zh', 'en', 'ko', 'ja', 'ru', 'es', 'fr', 'pt', 'it', 'de', 'vi',
      'ms', 'th', 'id', 'ar',
    ];

    // 如果源语言是auto、zh或en，目标语言可以是所有语言
    if (currentSourceLanguage == 'auto' ||
        currentSourceLanguage == 'zh' ||
        currentSourceLanguage == 'en') {
      return allLanguages;
    }
    // 如果源语言不是auto、zh、en，目标语言只能是zh、en
    else {
      return ['zh', 'en'];
    }
  }

  // 获取语言的显示名称
  String _getLanguageDisplayName(String languageCode) {
    final languageNames = {
      'auto': '自动检测',
      'zh': '中文',
      'en': '英文',
      'ko': '韩文',
      'ja': '日文',
      'ru': '俄文',
      'es': '西班牙文',
      'fr': '法文',
      'pt': '葡萄牙文',
      'it': '意大利文',
      'de': '德文',
      'vi': '越南文',
      'ms': '马来文',
      'th': '泰文',
      'id': '印尼文',
      'ar': '阿拉伯文',
    };
    return languageNames[languageCode] ?? languageCode;
  }

  List<String> _getSupportedQualities() {
    switch (widget.currentPlatform?.id) {
      case 'zhipu':
        return ['standard', 'hd'];
      // 阿里百炼、硅基流动没有此栏位
      default:
        return [];
    }
  }

  int _getMaxImageCount() {
    final modelName = widget.currentModel?.modelName.toLowerCase();
    switch (widget.currentPlatform?.id) {
      case 'siliconCloud':
        return 4;
      case 'aliyun':
        // 文生图V2系列
        if ((modelName?.startsWith('wanx2') ?? false) ||
            (modelName?.startsWith('wan2') ?? false)) {
          return 4;
        }
        // qwen-image 、flux 都为1
        return 1;
      case 'zhipu':
        return 1;
      default:
        return 1;
    }
  }

  void _resetToDefaults() {
    final supportedSizes = _getSupportedSizes();
    final defaultSettings = {
      'size': supportedSizes.isNotEmpty ? supportedSizes.first : '1024x1024',
      'quality': 'standard',
      'n': 1.0, // 滑块需要double类型
      'seed': null,
      'steps': 20,
      'guidanceScale': 7.5,
      'watermark': true,
      'negativePrompt': '',
      'sourceLanguage': 'auto',
      'targetLanguage': 'zh',
    };

    setState(() {
      _currentSourceLanguage = 'auto';
      _currentTargetLanguage = 'zh';
    });

    _formKey.currentState?.reset();
    _formKey.currentState?.patchValue(defaultSettings);
  }

  void _saveSettings() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formValues = _formKey.currentState!.value;

      // 清理空值
      final cleanedValues = <String, dynamic>{};
      formValues.forEach((key, value) {
        if (value != null && value != '') {
          if (key == 'seed' || key == 'steps') {
            cleanedValues[key] = double.tryParse(value.toString())?.toInt();
          } else if (key == 'guidanceScale') {
            cleanedValues[key] = double.tryParse(value.toString());
          } else {
            cleanedValues[key] = value;
          }
        }
      });

      widget.onSave(cleanedValues);
      Navigator.of(context).pop();
    }
  }
}
