import 'package:flutter/material.dart';

// 颜色配置类来管理所有颜色设置
class MessageFontColor {
  final Color userTextColor; // 用户输入文本颜色
  final Color aiNormalTextColor; // AI正常响应文本颜色
  final Color aiThinkingTextColor; // AI深度思考文本颜色

  MessageFontColor({
    required this.userTextColor,
    required this.aiNormalTextColor,
    required this.aiThinkingTextColor,
  });

  // 默认配置
  factory MessageFontColor.defaultConfig() {
    return MessageFontColor(
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
  factory MessageFontColor.fromMap(Map<String, dynamic> map) {
    return MessageFontColor(
      userTextColor: Color(map['userTextColor']),
      aiNormalTextColor: Color(map['aiNormalTextColor']),
      aiThinkingTextColor: Color(map['aiThinkingTextColor']),
    );
  }

  // 实现相等比较
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MessageFontColor &&
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
