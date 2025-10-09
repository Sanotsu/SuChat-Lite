// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unified_platform_spec.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnifiedPlatformSpec _$UnifiedPlatformSpecFromJson(Map<String, dynamic> json) =>
    UnifiedPlatformSpec(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      hostUrl: json['host_url'] as String,
      apiPrefix: json['api_prefix'] as String? ?? '/v1/chat/completions',
      imageGenerationPrefix: json['image_generation_prefix'] as String?,
      textToSpeechPrefix: json['text_to_speech_prefix'] as String?,
      speechToTextPrefix: json['speech_to_text_prefix'] as String?,
      isBuiltIn: json['is_built_in'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? false,
      description: json['description'] as String?,
      extraParams: json['extra_params'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$UnifiedPlatformSpecToJson(
  UnifiedPlatformSpec instance,
) => <String, dynamic>{
  'id': instance.id,
  'display_name': instance.displayName,
  'host_url': instance.hostUrl,
  'api_prefix': instance.apiPrefix,
  'image_generation_prefix': instance.imageGenerationPrefix,
  'text_to_speech_prefix': instance.textToSpeechPrefix,
  'speech_to_text_prefix': instance.speechToTextPrefix,
  'is_built_in': instance.isBuiltIn,
  'is_active': instance.isActive,
  'description': instance.description,
  'extra_params': instance.extraParams,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
