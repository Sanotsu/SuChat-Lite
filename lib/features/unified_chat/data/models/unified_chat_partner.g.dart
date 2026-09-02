// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unified_chat_partner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnifiedChatPartner _$UnifiedChatPartnerFromJson(Map<String, dynamic> json) =>
    UnifiedChatPartner(
      id: json['id'] as String,
      name: json['name'] as String,
      prompt: json['prompt'] as String,
      avatarUrl: json['avatar_url'] as String?,
      isBuiltIn: json['is_built_in'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      isFavorite: json['is_favorite'] as bool? ?? false,
      contextMessageLength:
          (json['context_message_length'] as num?)?.toInt() ?? 6,
      temperature: (json['temperature'] as num?)?.toDouble(),
      topP: (json['top_p'] as num?)?.toDouble(),
      maxTokens: (json['max_tokens'] as num?)?.toInt(),
      isStream: json['is_stream'] as bool? ?? true,
      description: json['description'] as String?,
      personality: json['personality'] as String?,
      scenario: json['scenario'] as String?,
      firstMessage: json['first_message'] as String?,
      exampleDialogue: json['example_dialogue'] as String?,
      tags: json['tags'] as String?,
      preferredModelId: json['preferred_model_id'] as String?,
      background: json['background'] as String?,
      backgroundOpacity: (json['background_opacity'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$UnifiedChatPartnerToJson(UnifiedChatPartner instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'prompt': instance.prompt,
      'avatar_url': instance.avatarUrl,
      'is_built_in': instance.isBuiltIn,
      'is_active': instance.isActive,
      'is_favorite': instance.isFavorite,
      'context_message_length': instance.contextMessageLength,
      'temperature': instance.temperature,
      'top_p': instance.topP,
      'max_tokens': instance.maxTokens,
      'is_stream': instance.isStream,
      'description': instance.description,
      'personality': instance.personality,
      'scenario': instance.scenario,
      'first_message': instance.firstMessage,
      'example_dialogue': instance.exampleDialogue,
      'tags': instance.tags,
      'preferred_model_id': instance.preferredModelId,
      'background': instance.background,
      'background_opacity': instance.backgroundOpacity,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
