import 'package:flutter/material.dart';
import '../utils/screen_helper.dart';

/// 高级参数配置面板
class AdvancedOptionsPanel extends StatefulWidget {
  // 当前选中的参数配置
  final Map<String, dynamic> currentOptions;
  // 可配置的参数列表
  final List<AdvancedOption> options;
  // 参数变化回调
  final Function(Map<String, dynamic>) onOptionsChanged;

  /// 如果直接使用面板，需要可调整是否启动高级选项；
  /// 但如果是把这个面板放在了弹窗等其他地方，可能打开弹窗点击确认就是启用高级选项了，
  /// 就不需要单独的启用开关了
  final bool isShowEnabledSwitch;
  // 添加是否启用高级参数的回调
  // 如果不显示启用开关，那这两个参数就不是必须的了
  final bool enabled;
  final Function(bool)? onEnabledChanged;

  const AdvancedOptionsPanel({
    super.key,
    required this.currentOptions,
    required this.options,
    required this.onOptionsChanged,
    this.isShowEnabledSwitch = true,
    this.enabled = true,
    this.onEnabledChanged,
  });

  @override
  State<AdvancedOptionsPanel> createState() => _AdvancedOptionsPanelState();
}

class _AdvancedOptionsPanelState extends State<AdvancedOptionsPanel> {
  // 当前选中的参数配置
  late Map<String, dynamic> _options;
  // 高级选项默认展开
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _options = Map.from(widget.currentOptions);

    // 如果当前值为空，使用默认值初始化
    for (var option in widget.options) {
      if (!_options.containsKey(option.key)) {
        _options[option.key] = option.defaultValue;
      }
    }

    _options.forEach((key, value) {
      debugPrint('高级选项panel中的初始值 > key: $key, value: $value');
    });
  }

  @override
  void didUpdateWidget(covariant AdvancedOptionsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果当前选中的参数配置发生变化，更新当前选中的参数配置
    if (widget.currentOptions != oldWidget.currentOptions) {
      setState(() {
        _options = Map.from(widget.currentOptions);
      });
    }
  }

  // 更新参数配置
  void _updateOption(String key, dynamic value) {
    setState(() {
      _options[key] = value;
      widget.onOptionsChanged(_options);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ScreenHelper.isDesktop();

    return isDesktop
        ? _buildDesktopLayout(context)
        : _buildMobileLayout(context);
  }

  // 移动端布局
  Widget _buildMobileLayout(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Column(
        children: [
          /// 如果需要显示启用开关
          if (widget.isShowEnabledSwitch) ...[
            // 启用开关
            SwitchListTile(
              title: const Text('启用高级参数'),
              value: widget.enabled,
              onChanged: widget.onEnabledChanged,
            ),
            // 展开/收起按钮
            ListTile(
              title: Text('高级选项', style: TextStyle(fontSize: 14)),
              trailing: Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
              ),
              onTap: () => setState(() => _isExpanded = !_isExpanded),
            ),
          ],

          // 高级选项列表(启用了高级选项并且展开了)
          if (widget.enabled && _isExpanded)
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                children:
                    widget.options.map((option) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        child: _buildOptionWidget(option, isMobile: true),
                      );
                    }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // 桌面端布局
  Widget _buildDesktopLayout(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          /// 如果需要显示启用开关
          if (widget.isShowEnabledSwitch) ...[
            // 启用开关
            SwitchListTile(
              title: const Text(
                '启用高级参数',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              value: widget.enabled,
              onChanged: widget.onEnabledChanged,
              secondary: Icon(Icons.settings, color: Colors.blue),
            ),
            // 展开/收起按钮
            ListTile(
              title: Text(
                '参数配置',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              trailing: Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
              ),
              onTap: () => setState(() => _isExpanded = !_isExpanded),
            ),
            Divider(height: 1),
          ],

          // 高级选项列表(启用了高级选项并且展开了)
          if (widget.enabled && _isExpanded)
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildDesktopOptionWidgets(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 为桌面布局构建选项组件列表
  List<Widget> _buildDesktopOptionWidgets() {
    List<Widget> result = [];

    // 按类型对选项进行分组
    Map<String, List<AdvancedOption>> groupedOptions = {};

    for (var option in widget.options) {
      String groupKey = _getOptionGroup(option.type);
      if (!groupedOptions.containsKey(groupKey)) {
        groupedOptions[groupKey] = [];
      }
      groupedOptions[groupKey]!.add(option);
    }

    // 按组构建选项
    groupedOptions.forEach((group, options) {
      if (options.isNotEmpty) {
        // 添加组标题
        result.add(
          Padding(
            padding: EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              group,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
          ),
        );

        // 添加组内的选项
        for (var option in options) {
          result.add(
            Container(
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              padding: EdgeInsets.all(12),
              child: _buildOptionWidget(option, isMobile: false),
            ),
          );
        }
      }
    });

    return result;
  }

  // 根据参数类型获取分组名称
  String _getOptionGroup(OptionType type) {
    switch (type) {
      case OptionType.slider:
        return "数值参数";
      case OptionType.toggle:
        return "开关参数";
      case OptionType.select:
        return "选择参数";
      case OptionType.number:
        return "数值参数";
      case OptionType.text:
        return "文本参数";
    }
  }

  // 根据参数类型构建对应的组件
  Widget _buildOptionWidget(AdvancedOption option, {required bool isMobile}) {
    switch (option.type) {
      case OptionType.slider:
        return _buildSlider(option, isMobile: isMobile);
      case OptionType.toggle:
        return _buildToggle(option, isMobile: isMobile);
      case OptionType.select:
        return _buildSelect(option, isMobile: isMobile);
      case OptionType.number:
        return _buildNumberInput(option, isMobile: isMobile);
      case OptionType.text:
        return _buildTextInput(option, isMobile: isMobile);
    }
  }

  // 构建滑块组件
  Widget _buildSlider(AdvancedOption option, {required bool isMobile}) {
    // 能进入滑块组件的，都是number,int或者double
    var tempValue = _options[option.key] ?? option.defaultValue;
    double value = double.tryParse(tempValue.toString()) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOptionLabel(option, isMobile: isMobile),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value.toDouble(),
                min: option.min ?? 0,
                max: option.max ?? 1,
                divisions: option.divisions,
                activeColor: isMobile ? null : Colors.blue[600],
                onChanged:
                    (value) => _updateOption(
                      option.key,
                      option.isNeedInt == true
                          ? value.toInt()
                          : double.tryParse(value.toStringAsFixed(2)) ?? 0,
                    ),
              ),
            ),
            Container(
              width: 50,
              alignment: Alignment.center,
              child: Text(
                option.isNeedInt == true
                    ? value.toInt().toString()
                    : value.toStringAsFixed(2),
                style: TextStyle(fontSize: isMobile ? 12 : 14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 构建开关组件
  Widget _buildToggle(AdvancedOption option, {required bool isMobile}) {
    final isEnabled = _options[option.key] ?? option.defaultValue;

    return isMobile
        ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 使用统一的标签组件
            _buildOptionLabel(option, isMobile: isMobile),
            // 自定义开关组件布局
            Row(
              children: [
                // 开关左边留点间距
                SizedBox(width: 16),
                // 缩小滑块组件点击区域
                Transform.scale(
                  // 缩放比例
                  scale: 0.9,
                  child: Switch(
                    value: isEnabled,
                    onChanged: (value) => _updateOption(option.key, value),
                    // 缩小点击区域
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                // 可选：在开关旁边显示当前状态文本
                Text(
                  isEnabled ? '已启用' : '已禁用',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ],
        )
        : Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildOptionLabel(option, isMobile: false)),
            Switch(
              value: isEnabled,
              activeColor: Colors.blue[600],
              onChanged: (value) => _updateOption(option.key, value),
            ),
          ],
        );
  }

  // 构建下拉选择组件
  Widget _buildSelect(AdvancedOption option, {required bool isMobile}) {
    final currentValue = _options[option.key] ?? option.defaultValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOptionLabel(option, isMobile: isMobile),
        isMobile
            ? DropdownButton<dynamic>(
              isExpanded: true,
              value: currentValue,
              items:
                  option.items?.map((item) {
                    return DropdownMenuItem(
                      value: item.value,
                      child: Text(item.label),
                    );
                  }).toList(),
              onChanged: (value) => _updateOption(option.key, value),
            )
            : Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<dynamic>(
                  isExpanded: true,
                  value: currentValue,
                  icon: Icon(Icons.arrow_drop_down, color: Colors.blue[700]),
                  items:
                      option.items?.map((item) {
                        return DropdownMenuItem(
                          value: item.value,
                          child: Text(
                            item.label,
                            style: TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                  onChanged: (value) => _updateOption(option.key, value),
                ),
              ),
            ),
      ],
    );
  }

  // 构建数字输入组件
  Widget _buildNumberInput(AdvancedOption option, {required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOptionLabel(option, isMobile: isMobile),
        Padding(
          padding: EdgeInsets.only(left: isMobile ? 20 : 0),
          child: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: option.hint,
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue[600]!),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            controller: TextEditingController(
              text: (_options[option.key] ?? option.defaultValue)?.toString(),
            ),
            onChanged: (value) {
              final number = int.tryParse(value);
              if (number != null) {
                _updateOption(option.key, number);
              }
            },
          ),
        ),
      ],
    );
  }

  // 构建文本输入组件
  Widget _buildTextInput(AdvancedOption option, {required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOptionLabel(option, isMobile: isMobile),
        Padding(
          padding: EdgeInsets.only(left: isMobile ? 20 : 0),
          child: TextField(
            decoration: InputDecoration(
              hintText: option.hint,
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue[600]!),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            controller: TextEditingController(
              text: (_options[option.key] ?? option.defaultValue)?.toString(),
            ),
            onChanged: (value) => _updateOption(option.key, value),
          ),
        ),
      ],
    );
  }

  // 构建参数标签组件
  Widget _buildOptionLabel(AdvancedOption option, {required bool isMobile}) {
    return Tooltip(
      message: option.description ?? '',
      // textStyle: TextStyle(fontSize: 12),
      triggerMode: TooltipTriggerMode.tap,
      child: Row(
        children: [
          Text(
            option.label,
            style: TextStyle(
              fontSize: isMobile ? 14 : 15,
              fontWeight: isMobile ? FontWeight.normal : FontWeight.w500,
            ),
          ),
          if (option.description != null)
            Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(
                Icons.info_outline,
                size: isMobile ? 16 : 18,
                color: isMobile ? null : Colors.blue[400],
              ),
            ),
        ],
      ),
    );
  }
}

/// 参数选项类型
enum OptionType {
  slider, // 滑块
  toggle, // 开关
  select, // 下拉选择
  number, // 数字输入
  text, // 文本输入
}

/// 选择项
class OptionItem {
  final String label;
  final dynamic value;

  const OptionItem(this.label, this.value);
}

/// 参数配置项
class AdvancedOption {
  final String key; // 参数键名
  final String label; // 显示标签
  final String? description; // 参数描述
  final String? hint; // 输入提示
  final OptionType type; // 参数类型
  final dynamic defaultValue; // 默认值
  final double? min; // 最小值(用于slider)
  final double? max; // 最大值(用于slider)
  final int? divisions; // 分段数(用于slider)
  final bool? isNeedInt; // 是否要取整(用于slider)
  final List<OptionItem>? items; // 选项列表(用于select)

  const AdvancedOption({
    required this.key,
    required this.label,
    required this.type,
    this.description,
    this.hint,
    this.defaultValue,
    this.min,
    this.max,
    this.divisions,
    this.isNeedInt,
    this.items,
  });
}
