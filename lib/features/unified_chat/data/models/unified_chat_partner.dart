import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'unified_chat_partner.g.dart';

// 一个预设的默认的系统角色
final defaultPartner = UnifiedChatPartner(
  id: 'default',
  name: '默认助手',
  prompt: '你是一个非常有用的智能助手，能够回答各种问题并提供帮助。',
  isBuiltIn: true,
  isStream: true,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

/// 聊天搭档/角色模型
/// 2026-08-31 合并旧版角色卡系统：
/// 搭档可以是"轻量人格"(仅prompt)，也可以是"角色卡"(结构化人设+开场白+专属背景+偏好模型)。
/// 结构化字段均可空：为空时行为与旧版搭档完全一致；
/// 非空时编辑保存会调用 [generateSystemPrompt] 生成最终prompt(与旧版CharacterCard一致)。
@JsonSerializable(explicitToJson: true)
class UnifiedChatPartner {
  final String id;
  final String name;
  final String prompt;

  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  @JsonKey(name: 'is_built_in')
  final bool isBuiltIn;

  @JsonKey(name: 'is_active')
  final bool isActive;

  @JsonKey(name: 'is_favorite')
  final bool isFavorite;

  // ============ 对话参数 ============
  @JsonKey(name: 'context_message_length')
  final int contextMessageLength;

  @JsonKey(name: 'temperature')
  final double? temperature;

  @JsonKey(name: 'top_p')
  final double? topP;

  @JsonKey(name: 'max_tokens')
  final int? maxTokens;

  @JsonKey(name: 'is_stream')
  final bool? isStream;

  // ============ 角色卡字段(2026-08-31 从旧版CharacterCard合并，均可空) ============

  /// 角色背景描述(结构化人设)
  @JsonKey(name: 'description')
  final String? description;

  /// 性格特点
  @JsonKey(name: 'personality')
  final String? personality;

  /// 场景设定
  @JsonKey(name: 'scenario')
  final String? scenario;

  /// 开场白：选择该搭档开始新对话时，自动以assistant身份发送(不调用模型)
  @JsonKey(name: 'first_message')
  final String? firstMessage;

  /// 对话示例
  @JsonKey(name: 'example_dialogue')
  final String? exampleDialogue;

  /// 标签(JSON数组字符串存储，对齐旧版tagsJson)
  @JsonKey(name: 'tags')
  final String? tags;

  /// 偏好模型id(选择该搭档时自动切换；模型不存在时忽略)
  @JsonKey(name: 'preferred_model_id')
  final String? preferredModelId;

  /// 搭档专属背景图路径(优先级：搭档背景 > 全局聊天背景)
  @JsonKey(name: 'background')
  final String? background;

  /// 搭档专属背景不透明度(默认0.35，对齐旧版角色背景默认值)
  @JsonKey(name: 'background_opacity')
  final double? backgroundOpacity;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const UnifiedChatPartner({
    required this.id,
    required this.name,
    required this.prompt,
    this.avatarUrl,
    this.isBuiltIn = false,
    this.isActive = true,
    this.isFavorite = false,
    this.contextMessageLength = 6,
    this.temperature,
    this.topP,
    this.maxTokens,
    this.isStream = true,
    this.description,
    this.personality,
    this.scenario,
    this.firstMessage,
    this.exampleDialogue,
    this.tags,
    this.preferredModelId,
    this.background,
    this.backgroundOpacity,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UnifiedChatPartner.fromJson(Map<String, dynamic> json) =>
      _$UnifiedChatPartnerFromJson(json);

  Map<String, dynamic> toJson() => _$UnifiedChatPartnerToJson(this);

  /// 解析标签列表(tags为JSON数组字符串)
  List<String> get tagList {
    final raw = tags;
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.cast<String>();
    } catch (_) {
      return const [];
    }
  }

  /// 是否配置了结构化人设(决定prompt是否由结构化字段生成)
  bool get hasStructuredProfile {
    return (description ?? '').trim().isNotEmpty ||
        (personality ?? '').trim().isNotEmpty ||
        (scenario ?? '').trim().isNotEmpty ||
        (exampleDialogue ?? '').trim().isNotEmpty;
  }

  /// 是否有开场白
  bool get hasFirstMessage => (firstMessage ?? '').trim().isNotEmpty;

  /// 是否配置了专属背景
  bool get hasBackground => background != null && background!.trim().isNotEmpty;

  /// 从结构化人设字段生成系统提示词(移植自旧版CharacterCard.generateSystemPrompt)
  /// 有结构化字段时编辑保存会自动生成prompt；仅填prompt的轻量搭档不走此逻辑
  String generateSystemPrompt() {
    final buffer = StringBuffer();

    buffer.writeln('# 角色定义');
    buffer.writeln('你现在将扮演: $name');
    buffer.writeln('');

    buffer.writeln('## 角色背景');
    buffer.writeln(description ?? '');
    buffer.writeln('');

    if ((personality ?? '').trim().isNotEmpty) {
      buffer.writeln('## 性格特点');
      buffer.writeln(personality);
      buffer.writeln('');
    }

    if ((scenario ?? '').trim().isNotEmpty) {
      buffer.writeln('## 场景设定');
      buffer.writeln(scenario);
      buffer.writeln('');
    }

    if ((exampleDialogue ?? '').trim().isNotEmpty) {
      buffer.writeln('## 对话示例');
      buffer.writeln(exampleDialogue);
      buffer.writeln('');
    }

    buffer.writeln('## 行为指南');
    buffer.writeln('1. 始终保持角色一致性，不要破坏角色设定');
    buffer.writeln('2. 使用第一人称回应用户，展现出你的专业知识和个性');
    buffer.writeln('3. 不要提及你是AI、语言模型或程序，完全沉浸在角色中');
    buffer.writeln('4. 根据用户的问题和需求提供相关、有帮助的回应');
    buffer.writeln('5. 如果用户的请求超出你的角色能力范围，可以礼貌地引导话题回到你的专业领域');
    buffer.writeln('6. 保持你的性格特点和说话风格，使回应符合角色形象');
    buffer.writeln('7. 在适当的情况下使用表情、动作描述等增强角色的真实感');

    // 根据标签添加角色扮演指导(对齐旧版)
    if (tagList.contains('虚拟') || tagList.contains('角色扮演')) {
      buffer.writeln('\n## 角色扮演指导');
      buffer.writeln('- 完全沉浸在角色中，保持一致的语气、用词和行为模式');
      buffer.writeln('- 使用角色特有的表达方式、习惯用语或口头禅');
      buffer.writeln('- 通过描述动作、表情和语气增强互动的沉浸感');
      buffer.writeln('- 根据角色背景做出符合逻辑的反应和决定');
      buffer.writeln('- 在角色知识范围内回应，对未知信息可以创造性地处理');
    }

    return buffer.toString();
  }

  UnifiedChatPartner copyWith({
    String? id,
    String? name,
    String? prompt,
    String? avatarUrl,
    bool? isBuiltIn,
    bool? isActive,
    bool? isFavorite,
    int? contextMessageLength,
    double? temperature,
    double? topP,
    int? maxTokens,
    bool? isStream,
    String? description,
    String? personality,
    String? scenario,
    String? firstMessage,
    String? exampleDialogue,
    String? tags,
    String? preferredModelId,
    String? background,
    double? backgroundOpacity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UnifiedChatPartner(
      id: id ?? this.id,
      name: name ?? this.name,
      prompt: prompt ?? this.prompt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      isActive: isActive ?? this.isActive,
      isFavorite: isFavorite ?? this.isFavorite,
      contextMessageLength: contextMessageLength ?? this.contextMessageLength,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      maxTokens: maxTokens ?? this.maxTokens,
      isStream: isStream ?? this.isStream,
      description: description ?? this.description,
      personality: personality ?? this.personality,
      scenario: scenario ?? this.scenario,
      firstMessage: firstMessage ?? this.firstMessage,
      exampleDialogue: exampleDialogue ?? this.exampleDialogue,
      tags: tags ?? this.tags,
      preferredModelId: preferredModelId ?? this.preferredModelId,
      background: background ?? this.background,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 转换为数据库格式
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'prompt': prompt,
      'avatar_url': avatarUrl,
      'is_built_in': isBuiltIn ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'is_favorite': isFavorite ? 1 : 0,
      'context_message_length': contextMessageLength,
      'temperature': temperature,
      'top_p': topP,
      'max_tokens': maxTokens,
      'is_stream': isStream == true ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'description': description,
      'personality': personality,
      'scenario': scenario,
      'first_message': firstMessage,
      'example_dialogue': exampleDialogue,
      'tags': tags,
      'preferred_model_id': preferredModelId,
      'background': background,
      'background_opacity': backgroundOpacity,
    };
  }

  /// 从数据库格式创建
  factory UnifiedChatPartner.fromMap(Map<String, dynamic> map) {
    return UnifiedChatPartner(
      id: map['id'] as String,
      name: map['name'] as String,
      prompt: map['prompt'] as String,
      avatarUrl: map['avatar_url'] as String?,
      isBuiltIn: (map['is_built_in'] as int) == 1,
      isActive: (map['is_active'] as int) == 1,
      isFavorite: (map['is_favorite'] as int) == 1,
      contextMessageLength: map['context_message_length'] as int? ?? 6,
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.7,
      topP: (map['top_p'] as num?)?.toDouble() ?? 1.0,
      maxTokens: map['max_tokens'] as int? ?? 4096,
      isStream: (map['is_stream'] as int) == 1,
      description: map['description'] as String?,
      personality: map['personality'] as String?,
      scenario: map['scenario'] as String?,
      firstMessage: map['first_message'] as String?,
      exampleDialogue: map['example_dialogue'] as String?,
      tags: map['tags'] as String?,
      preferredModelId: map['preferred_model_id'] as String?,
      background: map['background'] as String?,
      backgroundOpacity: (map['background_opacity'] as num?)?.toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  @override
  String toString() {
    return 'ChatPartner(id: $id, name: $name, isBuiltIn: $isBuiltIn)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnifiedChatPartner && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
