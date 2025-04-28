import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../../../services/cus_get_storage.dart';

class MessageColorSettingsPage extends StatefulWidget {
  const MessageColorSettingsPage({super.key});

  @override
  State<MessageColorSettingsPage> createState() =>
      _MessageColorSettingsPageState();
}

class _MessageColorSettingsPageState extends State<MessageColorSettingsPage> {
  MessageColorConfig _config = MessageColorConfig.defaultConfig();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await MyGetStorage().loadMessageColorConfig();

    setState(() {
      _config = config;
    });
  }

  Future<void> _saveConfig() async {
    await MyGetStorage().saveMessageColorConfig(_config);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('颜色设置已保存')));
  }

  Future<void> _selectColor(BuildContext context, String colorType) async {
    Color currentColor;
    switch (colorType) {
      case 'user':
        currentColor = _config.userTextColor;
        break;
      case 'aiNormal':
        currentColor = _config.aiNormalTextColor;
        break;
      case 'aiThinking':
        currentColor = _config.aiThinkingTextColor;
        break;
      default:
        currentColor = Colors.black;
    }

    Color? newColor = await showDialog<Color>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('选择颜色'),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: currentColor,
                onColorChanged: (color) {
                  // 实时预览颜色变化
                  setState(() {
                    currentColor = color;
                  });
                },
                // labelTypes: [],
                pickerAreaHeightPercent: 0.8,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, currentColor),
                child: const Text('确定'),
              ),
            ],
          ),
    );

    if (newColor != null) {
      setState(() {
        switch (colorType) {
          case 'user':
            _config = MessageColorConfig(
              userTextColor: newColor,
              aiNormalTextColor: _config.aiNormalTextColor,
              aiThinkingTextColor: _config.aiThinkingTextColor,
            );
            break;
          case 'aiNormal':
            _config = MessageColorConfig(
              userTextColor: _config.userTextColor,
              aiNormalTextColor: newColor,
              aiThinkingTextColor: _config.aiThinkingTextColor,
            );
            break;
          case 'aiThinking':
            _config = MessageColorConfig(
              userTextColor: _config.userTextColor,
              aiNormalTextColor: _config.aiNormalTextColor,
              aiThinkingTextColor: newColor,
            );
            break;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('消息颜色设置'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveConfig),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildColorSettingItem(
            '用户消息颜色',
            _config.userTextColor,
            () => _selectColor(context, 'user'),
          ),
          _buildColorSettingItem(
            'AI正常响应颜色',
            _config.aiNormalTextColor,
            () => _selectColor(context, 'aiNormal'),
          ),
          _buildColorSettingItem(
            'AI深度思考颜色',
            _config.aiThinkingTextColor,
            () => _selectColor(context, 'aiThinking'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _config = MessageColorConfig.defaultConfig();
              });
            },
            child: const Text('恢复默认设置'),
          ),
          Text(
            _config.userTextColor.toString(),
            style: TextStyle(color: _config.userTextColor),
          ),
          Text(
            _config.aiNormalTextColor.toString(),
            style: TextStyle(color: _config.aiNormalTextColor),
          ),
          Text(
            _config.aiThinkingTextColor.toString(),
            style: TextStyle(color: _config.aiThinkingTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSettingItem(
    String title,
    Color currentColor,
    VoidCallback onTap,
  ) {
    return ListTile(
      title: Text(title),
      trailing: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: currentColor,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.grey),
        ),
      ),
      onTap: onTap,
    );
  }
}

// 颜色配置类来管理所有颜色设置
class MessageColorConfig {
  final Color userTextColor; // 用户输入文本颜色
  final Color aiNormalTextColor; // AI正常响应文本颜色
  final Color aiThinkingTextColor; // AI深度思考文本颜色

  MessageColorConfig({
    required this.userTextColor,
    required this.aiNormalTextColor,
    required this.aiThinkingTextColor,
  });

  // 默认配置
  factory MessageColorConfig.defaultConfig() {
    return MessageColorConfig(
      userTextColor: Colors.blue,
      aiNormalTextColor: Colors.black,
      aiThinkingTextColor: Colors.grey,
    );
  }

  // 转换为Map以便存储
  Map<String, dynamic> toMap() {
    return {
      'userTextColor': userTextColor.toARGB32(),
      'aiNormalTextColor': aiNormalTextColor.toARGB32(),
      'aiThinkingTextColor': aiThinkingTextColor.toARGB32(),
    };
  }

  // 从Map恢复
  factory MessageColorConfig.fromMap(Map<String, dynamic> map) {
    return MessageColorConfig(
      userTextColor: Color(map['userTextColor']),
      aiNormalTextColor: Color(map['aiNormalTextColor']),
      aiThinkingTextColor: Color(map['aiThinkingTextColor']),
    );
  }

  // 实现相等比较
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MessageColorConfig &&
        other.userTextColor == userTextColor &&
        other.aiNormalTextColor == aiNormalTextColor &&
        other.aiThinkingTextColor == aiThinkingTextColor;
  }

  // 实现hashCode
  @override
  int get hashCode =>
      userTextColor.hashCode ^
      aiNormalTextColor.hashCode ^
      aiThinkingTextColor.hashCode;
}
