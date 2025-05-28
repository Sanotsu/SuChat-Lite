import 'package:flutter/material.dart';

import '../../../../../shared/widgets/simple_tool_widget.dart';
import '../../../domain/advanced_options_utils.dart';
import 'advanced_options_panel.dart';

/// 桌面端专用的高级参数配置对话框
class AdvancedOptionsDialog extends StatefulWidget {
  final bool enabled;
  final Map<String, dynamic> currentOptions;
  final List<AdvancedOption> options;

  const AdvancedOptionsDialog({
    super.key,
    required this.enabled,
    required this.currentOptions,
    required this.options,
  });

  @override
  State<AdvancedOptionsDialog> createState() => _AdvancedOptionsDialogState();
}

class _AdvancedOptionsDialogState extends State<AdvancedOptionsDialog> {
  late bool _enabled;
  late Map<String, dynamic> _options;

  final String _hintText = '''
**若这些参数不太了解，建议不要启用"更多参数"**。

"更多参数"只针对了不同平台中、同样类型的模型分类进行了简单处理。举例：
- 同样为文本对话(cc)分类的模型，混元lite 和 deepseek-v3 的参数并不统一。
- 同样是deepseek-v3模型，在阿里云支持的参数和在无问芯穹支持的参数也不统一。
- **因此，并不是所有展示可调整的参数都会生效。**

若对某个模型启用"更多参数"后导致响应异常，请放弃使用"更多参数"。
''';

  @override
  void initState() {
    super.initState();
    _enabled = widget.enabled;
    _options =
        _enabled ? Map.from(widget.currentOptions) : _getDefaultOptions();
  }

  // 获取所有选项的默认值
  Map<String, dynamic> _getDefaultOptions() {
    final defaults = <String, dynamic>{};
    for (var option in widget.options) {
      defaults[option.key] = option.defaultValue;
    }
    return defaults;
  }

  @override
  Widget build(BuildContext context) {
    // 计算对话框的尺寸
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width * 0.7; // 对话框宽度为屏幕宽度的70%
    final dialogHeight = size.height * 0.8; // 对话框高度为屏幕高度的80%

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24.0,
        vertical: 24.0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题和按钮区域
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        commonMarkdwonHintDialog(context, '说明', _hintText);
                      },
                      child: const Icon(Icons.info_outline, size: 24),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '高级参数配置',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _enabled,
                      onChanged: (value) {
                        setState(() {
                          _enabled = value;
                          if (!_enabled) {
                            // 禁用时重置为默认值
                            _options = _getDefaultOptions();
                          }
                        });
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed:
                          () => Navigator.pop(
                            context,
                            AdvancedOptionsResult(
                              enabled: _enabled,
                              options: _options,
                            ),
                          ),
                      child: const Text('确定'),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            // 参数配置区域
            (_enabled)
                ? Expanded(
                  child: AdvancedOptionsPanel(
                    currentOptions: _options,
                    options: widget.options,
                    onOptionsChanged: (newOptions) {
                      setState(() {
                        _options = newOptions;
                      });
                    },
                    enabled: _enabled,
                    onEnabledChanged: (value) {
                      setState(() {
                        _enabled = value;
                      });
                    },
                    isShowEnabledSwitch: false,
                  ),
                )
                : Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.settings_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '该模型未启用更多参数',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '启用开关后可配置更多参数选项',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
