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
    };

    _initialValues = {...defaultSettings, ...widget.currentSettings};

    final supportedSizes = _getSupportedSizes();
    // 传入的配置中尺寸可能与平台模型支持的尺寸不一致，需要进行调整
    _initialValues['size'] = supportedSizes.isNotEmpty
        ? supportedSizes.first
        : '1024x1024';
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
                _buildSizeSelector(),

                // 数量选择
                const SizedBox(height: 10),
                _buildImageCountSlider(),
                const SizedBox(height: 10),

                // 质量选择
                if (widget.currentPlatform?.id == UnifiedPlatformId.zhipu.name)
                  _buildQualitySelector(),
                // 智谱的没有负面提示词栏位
                if (widget.currentPlatform?.id != UnifiedPlatformId.zhipu.name)
                  _buildNegativePromptField(),
                // 硅基流动的没有水印栏位
                if (widget.currentPlatform?.id !=
                    UnifiedPlatformId.siliconCloud.name)
                  _buildWatermarkField(),
                // 高级设置
                // TEST 暂时只有硅基流动的
                if (widget.currentPlatform?.id ==
                    UnifiedPlatformId.siliconCloud.name)
                  _buildAdvancedSettings(),
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

    return FormBuilderDropdown<String>(
      name: 'size',
      initialValue: _initialValues['size']?.toString(),
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

  Widget _buildAdvancedSettings() {
    return ExpansionTile(
      title: const Text('高级设置'),
      children: [
        const SizedBox(height: 10),
        if (widget.currentPlatform?.id ==
            UnifiedPlatformId.siliconCloud.name) ...[
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
    final modelId = widget.currentModel?.id.toLowerCase();

    switch (widget.currentPlatform?.id) {
      case 'aliyun':
        // qwen-image 系列
        if (modelId?.startsWith('qwen-image') ?? false) {
          return [
            '1328*1328',
            '1664*928',
            '1472*1140',
            '1140*1472',
            '928*1664',
          ];
        }

        // 文生图V2系列
        if ((modelId?.startsWith('wanx2') ?? false) ||
            (modelId?.startsWith('wan2') ?? false)) {
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
        if (modelId?.startsWith('flux-') ?? false) {
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
        if (modelId?.startsWith('kolor') ?? false) {
          return ['1024x1024', '960x1280', '768x1024', '720x1440', '720x1280'];
        }
        // 如果是qwen-image模型
        if (modelId?.startsWith('qwen-image') ?? false) {
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
      default:
        return ['1024x1024'];
    }
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
    final modelId = widget.currentModel?.id.toLowerCase();
    switch (widget.currentPlatform?.id) {
      case 'siliconCloud':
        return 4;
      case 'aliyun':
        // 文生图V2系列
        if ((modelId?.startsWith('wanx2') ?? false) ||
            (modelId?.startsWith('wan2') ?? false)) {
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
    };

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
