// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'unified_model_spec.g.dart';

/// 模型类型枚举
enum UnifiedModelType { cc, embedding, reranker, tti, iti, tts, asr, ttv, itv }

// 模型类型对应的中文名
final Map<UnifiedModelType, String> UMT_NAME_MAP = {
  UnifiedModelType.cc: '对话',
  UnifiedModelType.embedding: '嵌入',
  UnifiedModelType.reranker: '重排',
  UnifiedModelType.tti: '文生图',
  UnifiedModelType.iti: '图生图',
  UnifiedModelType.tts: '语音合成',
  UnifiedModelType.asr: '语音识别',
  UnifiedModelType.ttv: '文生视频',
  UnifiedModelType.itv: '图生视频',
};

/// 统一模型规格模型
@JsonSerializable(explicitToJson: true)
class UnifiedModelSpec {
  final String id;

  @JsonKey(name: 'platform_id')
  final String platformId;

  // 作为请求参数的那个代码
  @JsonKey(name: 'model_name')
  final String modelName;

  // 用于显示用户理解的名称
  @JsonKey(name: 'display_name')
  final String displayName;

  // 模型类型：cc对话模型、embedder嵌入模型、reranker重排模型
  @JsonKey(name: 'model_type')
  final String modelType;

  @JsonKey(name: 'supports_thinking')
  final bool supportsThinking;

  @JsonKey(name: 'supports_vision')
  final bool supportsVision;

  @JsonKey(name: 'supports_tool_calling')
  final bool supportsToolCalling;

  // 列表展示时,未激活的可以不展示
  @JsonKey(name: 'is_active')
  final bool isActive;

  // 是否是内置的
  @JsonKey(name: 'is_built_in')
  final bool isBuiltIn;

  // 是否收藏
  @JsonKey(name: 'is_favorite')
  final bool isFavorite;

  final String? description;

  @JsonKey(name: 'extra_config')
  final Map<String, dynamic>? extraConfig;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const UnifiedModelSpec({
    required this.id,
    required this.platformId,
    required this.modelName,
    required this.displayName,
    this.modelType = 'cc',
    this.supportsThinking = false,
    this.supportsVision = false,
    this.supportsToolCalling = false,
    this.isActive = true,
    this.isBuiltIn = false,
    this.isFavorite = false,
    this.description,
    this.extraConfig,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UnifiedModelSpec.fromJson(Map<String, dynamic> json) =>
      _$UnifiedModelSpecFromJson(json);

  Map<String, dynamic> toJson() => _$UnifiedModelSpecToJson(this);

  factory UnifiedModelSpec.fromMap(Map<String, dynamic> map) {
    return UnifiedModelSpec(
      id: map['id'] as String,
      platformId: map['platform_id'] as String,
      modelName: map['model_name'] as String,
      displayName: map['display_name'] as String,
      modelType: map['model_type'] as String,
      supportsThinking: (map['supports_thinking'] as int? ?? 0) == 1,
      supportsVision: (map['supports_vision'] as int? ?? 0) == 1,
      supportsToolCalling: (map['supports_tool_calling'] as int? ?? 0) == 1,
      isActive: (map['is_active'] as int? ?? 0) == 1,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      isBuiltIn: (map['is_built_in'] as int? ?? 0) == 1,
      description: map['description'] as String?,
      extraConfig: map['extra_config'] != null
          ? Map<String, dynamic>.from(json.decode(map['extra_config']))
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'platform_id': platformId,
      'model_name': modelName,
      'display_name': displayName,
      'model_type': modelType,
      'supports_thinking': supportsThinking ? 1 : 0,
      'supports_vision': supportsVision ? 1 : 0,
      'supports_tool_calling': supportsToolCalling ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'is_favorite': isFavorite ? 1 : 0,
      'is_built_in': isBuiltIn ? 1 : 0,
      'description': description,
      'extra_config': extraConfig != null ? json.encode(extraConfig) : null,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  UnifiedModelSpec copyWith({
    String? id,
    String? platformId,
    String? modelName,
    String? displayName,
    String? modelType,
    bool? supportsThinking,
    bool? supportsVision,
    bool? supportsToolCalling,
    bool? isActive,
    bool? isBuiltIn,
    bool? isFavorite,
    String? description,
    Map<String, dynamic>? extraConfig,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UnifiedModelSpec(
      id: id ?? this.id,
      platformId: platformId ?? this.platformId,
      modelName: modelName ?? this.modelName,
      displayName: displayName ?? this.displayName,
      modelType: modelType ?? this.modelType,
      supportsThinking: supportsThinking ?? this.supportsThinking,
      supportsVision: supportsVision ?? this.supportsVision,
      supportsToolCalling: supportsToolCalling ?? this.supportsToolCalling,
      isActive: isActive ?? this.isActive,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      isFavorite: isFavorite ?? this.isFavorite,
      description: description ?? this.description,
      extraConfig: extraConfig ?? this.extraConfig,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnifiedModelSpec && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UnifiedModelSpec(id: $id, modelName: $modelName, displayName: $displayName)';
  }

  /// 获取模型类型枚举
  UnifiedModelType get type {
    switch (modelType) {
      case 'cc':
        return UnifiedModelType.cc;
      case 'embedding':
        return UnifiedModelType.embedding;
      case 'reranker':
        return UnifiedModelType.reranker;
      case 'tti':
        return UnifiedModelType.tti;
      case 'iti':
        return UnifiedModelType.iti;
      case 'tts':
        return UnifiedModelType.tts;
      case 'asr':
        return UnifiedModelType.asr;
      case 'ttv':
        return UnifiedModelType.ttv;
      case 'itv':
        return UnifiedModelType.itv;
      default:
        return UnifiedModelType.cc;
    }
  }

  /// 是否支持指定功能
  bool supportsFeature(String feature) {
    switch (feature.toLowerCase()) {
      case 'thinking':
        return supportsThinking;
      case 'vision':
        return supportsVision;
      case 'function_calling':
        return supportsToolCalling;
      default:
        return false;
    }
  }
}
