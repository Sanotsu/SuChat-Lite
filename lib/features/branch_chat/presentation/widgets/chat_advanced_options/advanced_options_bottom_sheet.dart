import 'package:flutter/material.dart';

import '../../../../../shared/widgets/simple_tool_widget.dart';
import '../../../domain/advanced_options_utils.dart';
import 'advanced_options_panel.dart';

class AdvancedOptionsBottomSheet extends StatefulWidget {
  final bool enabled;
  final Map<String, dynamic> currentOptions;
  final List<AdvancedOption> options;

  const AdvancedOptionsBottomSheet({
    super.key,
    required this.enabled,
    required this.currentOptions,
    required this.options,
  });

  @override
  State<AdvancedOptionsBottomSheet> createState() =>
      _AdvancedOptionsBottomSheetState();
}

class _AdvancedOptionsBottomSheetState
    extends State<AdvancedOptionsBottomSheet> {
  late Map<String, dynamic> _options;
  late bool _enabled;

  final _hintDialog = '''
**若这些参数不太了解，建议不要启用“更多参数”**。

“更多参数”只针对了不同平台中、同样类型的模型分类进行了简单处理。举例：
- 同样为文本对话(cc)分类的模型，混元lite 和 deepseek-v3 的参数并不统一。
- 同样是deepseek-v3模型，在阿里云支持的参数和在无问芯穹支持的参数也不统一。
- **因此，并不是所有展示可调整的参数都会生效。**

若对某个模型启用“更多参数”后导致响应异常，请放弃使用“更多参数”。
''';

  @override
  void initState() {
    super.initState();
    _enabled = widget.enabled;
    _options =
        widget.enabled ? Map.from(widget.currentOptions) : _getDefaultOptions();
  }

  // 获取所有选项的默认值
  Map<String, dynamic> _getDefaultOptions() {
    final defaults = <String, dynamic>{};
    for (var option in widget.options) {
      // 使用选项定义中的 key（蛇形命名）
      defaults[option.key] = option.defaultValue;
    }
    return defaults;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Tooltip(
                    message: '说明',
                    triggerMode: TooltipTriggerMode.tap,
                    onTriggered: () {
                      commonMarkdwonHintDialog(
                        context,
                        '说明',
                        _hintDialog,
                        msgFontSize: 14,
                      );
                    },
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 24),
                        Text(
                          '更多参数',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _enabled,
                    onChanged: (value) {
                      setState(() => _enabled = value);
                    },
                  ),
                  Text(
                    (_enabled) ? '已启用' : '已禁用',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  // SizedBox(width: 8),
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
        ),
        Divider(height: 1),
        _enabled
            ? Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: AdvancedOptionsPanel(
                  currentOptions: _options,
                  options: widget.options,
                  onOptionsChanged: (newOptions) {
                    setState(() => _options = newOptions);
                  },
                  isShowEnabledSwitch: false,
                ),
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
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '启用开关后可配置更多参数选项',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
