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

  // 对话参数
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
    required this.createdAt,
    required this.updatedAt,
  });

  factory UnifiedChatPartner.fromJson(Map<String, dynamic> json) =>
      _$UnifiedChatPartnerFromJson(json);

  Map<String, dynamic> toJson() => _$UnifiedChatPartnerToJson(this);

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
