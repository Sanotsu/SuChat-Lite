// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unified_conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnifiedConversation _$UnifiedConversationFromJson(Map<String, dynamic> json) =>
    UnifiedConversation(
      id: json['id'] as String,
      title: json['title'] as String,
      modelId: json['model_id'] as String,
      platformId: json['platform_id'] as String,
      partnerId: json['partner_id'] as String?,
      systemPrompt: json['system_prompt'] as String?,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      maxTokens: (json['max_tokens'] as num?)?.toInt() ?? 4096,
      topP: (json['top_p'] as num?)?.toDouble() ?? 1.0,
      frequencyPenalty: (json['frequency_penalty'] as num?)?.toDouble() ?? 0.0,
      presencePenalty: (json['presence_penalty'] as num?)?.toDouble() ?? 0.0,
      contextMessageLength:
          (json['context_message_length'] as num?)?.toInt() ?? 6,
      isStream: json['is_stream'] as bool? ?? true,
      extraParams: json['extra_params'] as Map<String, dynamic>?,
      messageCount: (json['message_count'] as num?)?.toInt() ?? 0,
      totalTokens: (json['total_tokens'] as num?)?.toInt() ?? 0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0.0,
      isPinned: json['is_pinned'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$UnifiedConversationToJson(
  UnifiedConversation instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'model_id': instance.modelId,
  'platform_id': instance.platformId,
  'partner_id': instance.partnerId,
  'system_prompt': instance.systemPrompt,
  'temperature': instance.temperature,
  'max_tokens': instance.maxTokens,
  'top_p': instance.topP,
  'frequency_penalty': instance.frequencyPenalty,
  'presence_penalty': instance.presencePenalty,
  'context_message_length': instance.contextMessageLength,
  'is_stream': instance.isStream,
  'extra_params': instance.extraParams,
  'message_count': instance.messageCount,
  'total_tokens': instance.totalTokens,
  'total_cost': instance.totalCost,
  'is_pinned': instance.isPinned,
  'is_archived': instance.isArchived,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
