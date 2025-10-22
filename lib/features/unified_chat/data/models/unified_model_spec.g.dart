// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unified_model_spec.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnifiedModelSpec _$UnifiedModelSpecFromJson(Map<String, dynamic> json) =>
    UnifiedModelSpec(
      id: json['id'] as String,
      platformId: json['platform_id'] as String,
      modelName: json['model_name'] as String,
      displayName: json['display_name'] as String,
      modelType: json['model_type'] as String? ?? 'cc',
      supportsThinking: json['supports_thinking'] as bool? ?? false,
      supportsVision: json['supports_vision'] as bool? ?? false,
      supportsToolCalling: json['supports_tool_calling'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      isBuiltIn: json['is_built_in'] as bool? ?? false,
      isFavorite: json['is_favorite'] as bool? ?? false,
      description: json['description'] as String?,
      extraConfig: json['extra_config'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$UnifiedModelSpecToJson(UnifiedModelSpec instance) =>
    <String, dynamic>{
      'id': instance.id,
      'platform_id': instance.platformId,
      'model_name': instance.modelName,
      'display_name': instance.displayName,
      'model_type': instance.modelType,
      'supports_thinking': instance.supportsThinking,
      'supports_vision': instance.supportsVision,
      'supports_tool_calling': instance.supportsToolCalling,
      'is_active': instance.isActive,
      'is_built_in': instance.isBuiltIn,
      'is_favorite': instance.isFavorite,
      'description': instance.description,
      'extra_config': instance.extraConfig,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
