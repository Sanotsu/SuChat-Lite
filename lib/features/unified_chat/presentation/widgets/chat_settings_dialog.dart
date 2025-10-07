import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/models/unified_chat_partner.dart';

/// 对话设置弹窗
class ChatSettingsDialog extends StatefulWidget {
  final String? title;
  final String? systemPrompt;
  final int? contextMessageLength;
  final double? temperature;
  final double? topP;
  final int? maxTokens;
  final bool? isStream;
  final bool? enableThinking;
  final UnifiedChatPartner? selectedPartner;
  final Function(Map<String, dynamic>) onSave;

  const ChatSettingsDialog({
    super.key,
    this.title,
    this.systemPrompt,
    this.contextMessageLength,
    this.temperature,
    this.topP,
    this.maxTokens,
    this.isStream = true,
    this.enableThinking = false,
    this.selectedPartner,
    required this.onSave,
  });

  @override
  State<ChatSettingsDialog> createState() => _ChatSettingsDialogState();
}

class _ChatSettingsDialogState extends State<ChatSettingsDialog> {
  late TextEditingController _titleController;
  late TextEditingController _systemPromptController;
  late TextEditingController _maxTokensController;

  late double _contextMessageLength;
  late double _temperature;
  late double _topP;
  bool _isStream = true;
  // 比如Qwen3 、GLM4.5等，可以配置是否启用思考模式
  bool _enableThinking = false;

  bool showAdvancedSettings = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title ?? 'Untitled');
    _systemPromptController = TextEditingController(
      text: widget.systemPrompt ?? 'You are a helpful assistant.',
    );
    _maxTokensController = TextEditingController(
      text: (widget.maxTokens ?? 4096).toString(),
    );

    _contextMessageLength = (widget.contextMessageLength ?? 6).toDouble();
    _temperature = widget.temperature ?? 0.7;
    _topP = widget.topP ?? 1.0;
    _isStream = widget.isStream ?? true;
    _enableThinking = widget.enableThinking ?? false;

    // 如果有选择搭档,则默认显示高级设置
    showAdvancedSettings = widget.selectedPartner != null;
  }

  @override
  void didUpdateWidget(ChatSettingsDialog oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 当widget参数更新时，更新控制器的值
    if (oldWidget.title != widget.title) {
      _titleController.text = widget.title ?? 'Untitled';
    }
    if (oldWidget.systemPrompt != widget.systemPrompt) {
      _systemPromptController.text =
          widget.systemPrompt ?? 'You are a helpful assistant.';
    }
    if (oldWidget.maxTokens != widget.maxTokens) {
      _maxTokensController.text = (widget.maxTokens ?? 4096).toString();
    }
    if (oldWidget.contextMessageLength != widget.contextMessageLength) {
      _contextMessageLength = (widget.contextMessageLength ?? 6).toDouble();
    }
    if (oldWidget.temperature != widget.temperature) {
      _temperature = widget.temperature ?? 0.7;
    }
    if (oldWidget.topP != widget.topP) {
      _topP = widget.topP ?? 1.0;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _systemPromptController.dispose();
    _maxTokensController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final settings = {
      'title': _titleController.text,
      'systemPrompt': _systemPromptController.text,
      'contextMessageLength': _contextMessageLength.round(),
      'temperature': _temperature,
      'topP': _topP,
      'maxTokens': int.tryParse(_maxTokensController.text) ?? 4096,
      'isStream': _isStream,
      'enableThinking': _enableThinking,
    };

    widget.onSave(settings);
    Navigator.of(context).pop();
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
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            '对话设置',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: double.maxFinite,
          maxHeight: 0.6.sh,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 搭档信息显示(搭档的标题和提示词都放在输入框里了,这里不必再显示)
              // if (widget.selectedPartner != null) buildPartnerInfo(),

              // 名称
              const Text('名称', style: TextStyle(color: Colors.grey)),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(8),
                ),
              ),
              const SizedBox(height: 8),

              // 系统提示
              const Text('系统提示（角色设定）', style: TextStyle(color: Colors.grey)),
              TextField(
                controller: _systemPromptController,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 8),

              _buildCollapsibleSection(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(onPressed: _handleSave, child: const Text('保存')),
      ],
    );
  }

  /// 构建搭档信息显示
  Widget buildPartnerInfo() {
    final partner = widget.selectedPartner!;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          // 搭档头像
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blue,
            child: partner.avatarUrl != null && partner.avatarUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      partner.avatarUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.person, color: Colors.white);
                      },
                    ),
                  )
                : const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),

          // 搭档信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '当前搭档: ${partner.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  partner.prompt.length > 60
                      ? '${partner.prompt.substring(0, 60)}...'
                      : partner.prompt,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 构建折叠栏，用于显示特定模型设置
  Widget _buildCollapsibleSection() {
    return ExpansionTile(
      title: const Text('特定模型设置'),
      initiallyExpanded: showAdvancedSettings,
      leading: showAdvancedSettings
          ? const Icon(Icons.keyboard_arrow_up)
          : const Icon(Icons.keyboard_arrow_down),
      trailing: TextButton(
        onPressed: () {
          // 重置当前对话使用的模型设置为预设的
          setState(() {
            _contextMessageLength = 6;
            _temperature = 0.7;
            _topP = 1.0;
            _maxTokensController.text = '4096';
            _isStream = true;
            _enableThinking = false;
          });
        },
        child: Text('重置'),
      ),
      onExpansionChanged: (value) {
        setState(() {
          showAdvancedSettings = value;
        });
      },
      children: [
        const SizedBox(height: 8),

        // 上下文的消息数量上限
        Row(
          children: [
            const Text('上下文的消息数量上限'),
            const SizedBox(width: 8),
            Tooltip(
              message: '发送给模型的历史消息数量。在对话过长时，更便于在理解深度和响应效率之间找到和谐的平衡。',
              triggerMode: TooltipTriggerMode.tap,
              showDuration: Duration(seconds: 20),
              margin: EdgeInsets.symmetric(horizontal: 24),
              child: Icon(Icons.info_outline, size: 16, color: Colors.grey),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _contextMessageLength,
                min: 1,
                max: 20,
                divisions: 19,
                onChanged: (value) {
                  setState(() {
                    _contextMessageLength = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 50,
              height: 32,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  _contextMessageLength.round().toString(),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 温度
        Row(
          children: [
            const Text('温度'),
            const SizedBox(width: 8),
            Tooltip(
              message: '温度参数修改AI回复的创造力: 值越大，回复变得越随机和有趣；而较低的值则确保更大的稳定性和可靠性。',
              // message:
              //     'Temperature 通过调整概率分布的平滑度来控制生成的随机性：'
              //     '温度越低输出越确定保守，温度越高输出越随机多样。',
              triggerMode: TooltipTriggerMode.tap,
              showDuration: Duration(seconds: 20),
              margin: EdgeInsets.symmetric(horizontal: 24),
              child: Icon(Icons.info_outline, size: 16, color: Colors.grey),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _temperature,
                min: 0.0,
                max: 2.0,
                divisions: 20,
                onChanged: (value) {
                  setState(() {
                    _temperature = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 80,
              height: 32,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  _temperature == 0.0 ? '未设置' : _temperature.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Top P
        Row(
          children: [
            const Text('Top P'),
            const SizedBox(width: 8),
            Tooltip(
              message: 'topP参数控制AI响应的多样性: 较低的值使输出更集中和可预测；而较高的值则允许更多样化和富有创意的回复。',
              // message:
              //     'Top-p 通过从累积概率超过p值的最小词集中进行采样，来动态平衡生成的确凿性和多样性。'
              //     '较低的值使输出更集中和可预测，而较高的值则允许更多样化和富有创意的回复。',
              triggerMode: TooltipTriggerMode.tap,
              showDuration: Duration(seconds: 20),
              margin: EdgeInsets.symmetric(horizontal: 24),
              child: Icon(Icons.info_outline, size: 16, color: Colors.grey),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _topP,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                onChanged: (value) {
                  setState(() {
                    _topP = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 80,
              height: 32,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  _topP == 0.0 ? '未设置' : _topP.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 最大输出Token数
        Row(
          children: [
            const Text('最大输出Token数'),
            const SizedBox(width: 8),
            Tooltip(
              message: '最大输出Token数。请设置在模型可接受范围内，否则可能会发生错误。',
              triggerMode: TooltipTriggerMode.tap,
              showDuration: Duration(seconds: 20),
              margin: EdgeInsets.symmetric(horizontal: 24),
              child: Icon(Icons.info_outline, size: 16, color: Colors.grey),
            ),
          ],
        ),
        TextField(
          controller: _maxTokensController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            hintText: '未设置',
            hintStyle: TextStyle(color: Colors.grey.shade500),
          ),
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            const Text('流式输出'),
            const SizedBox(width: 12),
            Switch(
              value: _isStream,
              onChanged: (value) => setState(() {
                _isStream = value;
              }),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            const Text('启用思考'),
            const SizedBox(width: 12),
            Switch(
              value: _enableThinking,
              onChanged: (value) => setState(() {
                _enableThinking = value;
              }),
            ),
            const Spacer(),
            Tooltip(
              message:
                  '1 类似Qwen3、DeepSeek3.1、GLM4.5等模型可以参数设置是否开启思考模式。\n'
                  '2 思考模式和调用工具的联网搜索最好不要同时开启，否则部分平台模型在构建tools会出错。\n'
                  '3 是否启用思考摸索、是否联网搜索设置仅对当前对话生效。',
              triggerMode: TooltipTriggerMode.tap,
              showDuration: Duration(seconds: 20),
              margin: EdgeInsets.all(24),
              child: Icon(Icons.info_outline, size: 16, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}
