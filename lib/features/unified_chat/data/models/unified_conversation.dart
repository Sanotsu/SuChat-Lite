import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../../../../core/utils/datetime_formatter.dart';

part 'unified_conversation.g.dart';

/// 统一对话记录模型
@JsonSerializable(explicitToJson: true)
class UnifiedConversation {
  final String id;

  final String title;

  @JsonKey(name: 'model_id')
  final String modelId;

  @JsonKey(name: 'platform_id')
  final String platformId;

  @JsonKey(name: 'partner_id')
  final String? partnerId;

  @JsonKey(name: 'system_prompt')
  final String? systemPrompt;

  final double temperature;

  @JsonKey(name: 'max_tokens')
  final int maxTokens;

  @JsonKey(name: 'top_p')
  final double topP;

  @JsonKey(name: 'frequency_penalty')
  final double frequencyPenalty;

  @JsonKey(name: 'presence_penalty')
  final double presencePenalty;

  @JsonKey(name: 'context_message_length')
  final int contextMessageLength;

  @JsonKey(name: 'is_stream')
  final bool isStream;

  @JsonKey(name: 'extra_params')
  final Map<String, dynamic>? extraParams;

  @JsonKey(name: 'message_count')
  final int messageCount;

  @JsonKey(name: 'total_tokens')
  final int totalTokens;

  @JsonKey(name: 'total_cost')
  final double totalCost;

  @JsonKey(name: 'is_pinned')
  final bool isPinned;

  @JsonKey(name: 'is_archived')
  final bool isArchived;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const UnifiedConversation({
    required this.id,
    required this.title,
    required this.modelId,
    required this.platformId,
    this.partnerId,
    this.systemPrompt,
    this.temperature = 0.7,
    this.maxTokens = 4096,
    this.topP = 1.0,
    this.frequencyPenalty = 0.0,
    this.presencePenalty = 0.0,
    this.contextMessageLength = 6,
    this.isStream = true,
    this.extraParams,
    this.messageCount = 0,
    this.totalTokens = 0,
    this.totalCost = 0.0,
    this.isPinned = false,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UnifiedConversation.fromJson(Map<String, dynamic> json) =>
      _$UnifiedConversationFromJson(json);

  Map<String, dynamic> toJson() => _$UnifiedConversationToJson(this);

  factory UnifiedConversation.fromMap(Map<String, dynamic> map) {
    return UnifiedConversation(
      id: map['id'] as String,
      title: map['title'] as String,
      modelId: map['model_id'] as String,
      platformId: map['platform_id'] as String,
      partnerId: map['partner_id'] as String?,
      systemPrompt: map['system_prompt'] as String?,
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.7,
      maxTokens: map['max_tokens'] as int? ?? 4096,
      topP: (map['top_p'] as num?)?.toDouble() ?? 1.0,
      frequencyPenalty: (map['frequency_penalty'] as num?)?.toDouble() ?? 0.0,
      presencePenalty: (map['presence_penalty'] as num?)?.toDouble() ?? 0.0,
      contextMessageLength: map['context_message_length'] as int? ?? 6,
      isStream: (map['is_stream'] as int? ?? 1) == 1,
      extraParams: map['extra_params'] != null
          ? Map<String, dynamic>.from(json.decode(map['extra_params']))
          : null,
      messageCount: map['message_count'] as int? ?? 0,
      totalTokens: map['total_tokens'] as int? ?? 0,
      totalCost: (map['total_cost'] as num?)?.toDouble() ?? 0.0,
      isPinned: (map['is_pinned'] as int? ?? 0) == 1,
      isArchived: (map['is_archived'] as int? ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'model_id': modelId,
      'platform_id': platformId,
      'partner_id': partnerId,
      'system_prompt': systemPrompt,
      'temperature': temperature,
      'max_tokens': maxTokens,
      'top_p': topP,
      'frequency_penalty': frequencyPenalty,
      'presence_penalty': presencePenalty,
      'context_message_length': contextMessageLength,
      'is_stream': isStream ? 1 : 0,
      'extra_params': extraParams != null ? json.encode(extraParams) : null,
      'message_count': messageCount,
      'total_tokens': totalTokens,
      'total_cost': totalCost,
      'is_pinned': isPinned ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  UnifiedConversation copyWith({
    String? id,
    String? title,
    String? modelId,
    String? platformId,
    String? partnerId,
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
    double? topP,
    double? frequencyPenalty,
    double? presencePenalty,
    int? contextMessageLength,
    bool? isStream,
    Map<String, dynamic>? extraParams,
    int? messageCount,
    int? totalTokens,
    double? totalCost,
    bool? isPinned,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UnifiedConversation(
      id: id ?? this.id,
      title: title ?? this.title,
      modelId: modelId ?? this.modelId,
      platformId: platformId ?? this.platformId,
      partnerId: partnerId ?? this.partnerId,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      topP: topP ?? this.topP,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      presencePenalty: presencePenalty ?? this.presencePenalty,
      contextMessageLength: contextMessageLength ?? this.contextMessageLength,
      isStream: isStream ?? this.isStream,
      extraParams: extraParams ?? this.extraParams,
      messageCount: messageCount ?? this.messageCount,
      totalTokens: totalTokens ?? this.totalTokens,
      totalCost: totalCost ?? this.totalCost,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnifiedConversation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UnifiedConversation(id: $id, title: $title, messageCount: $messageCount)';
  }

  /// 获取对话状态
  String get status {
    if (isArchived) return 'archived';
    if (isPinned) return 'pinned';
    if (messageCount == 0) return 'empty';
    return 'active';
  }

  /// 获取平均每条消息的成本
  double get averageCostPerMessage {
    return messageCount > 0 ? totalCost / messageCount : 0.0;
  }

  /// 获取平均每个token的成本
  double get averageCostPerToken {
    return totalTokens > 0 ? totalCost / totalTokens : 0.0;
  }

  /// 是否为新对话
  bool get isNew => messageCount == 0;

  /// 是否为活跃对话
  bool get isActive => !isArchived && messageCount > 0;

  /// 获取对话时长（分钟）
  int get durationInMinutes {
    return updatedAt.difference(createdAt).inMinutes;
  }

  /// 获取最后活动时间描述
  String get lastActivityDescription => formatRelativeDate(updatedAt);

  /// 获取成本格式化字符串
  String get formattedCost {
    if (totalCost < 0.01) {
      return '< ¥0.01';
    } else if (totalCost < 1.0) {
      return '¥${totalCost.toStringAsFixed(3)}';
    } else {
      return '¥${totalCost.toStringAsFixed(2)}';
    }
  }

  /// 获取token数格式化字符串
  String get formattedTokens {
    if (totalTokens < 1000) {
      return '$totalTokens';
    } else if (totalTokens < 1000000) {
      return '${(totalTokens / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(totalTokens / 1000000).toStringAsFixed(1)}M';
    }
  }

  /// 验证对话参数
  bool get isValidConfiguration {
    return temperature >= 0.0 &&
        temperature <= 2.0 &&
        topP >= 0.0 &&
        topP <= 1.0 &&
        frequencyPenalty >= -2.0 &&
        frequencyPenalty <= 2.0 &&
        presencePenalty >= -2.0 &&
        presencePenalty <= 2.0 &&
        maxTokens > 0;
  }

  /// 获取对话配置摘要
  Map<String, dynamic> get configurationSummary {
    return {
      'partner_id': partnerId,
      'system_prompt': systemPrompt,
      'temperature': temperature,
      'max_tokens': maxTokens,
      'top_p': topP,
      'frequency_penalty': frequencyPenalty,
      'presence_penalty': presencePenalty,
      'context_message_length': contextMessageLength,
      'is_stream': isStream,
      'has_system_prompt': systemPrompt != null && systemPrompt!.isNotEmpty,
      'has_extra_params': extraParams != null && extraParams!.isNotEmpty,
    };
  }
}
