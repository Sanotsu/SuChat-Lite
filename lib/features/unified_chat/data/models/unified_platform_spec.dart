// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'unified_model_spec.dart';

part 'unified_platform_spec.g.dart';

/// 内置的平台
enum UnifiedPlatformId {
  aliyun,
  siliconCloud,
  deepseek,
  zhipu,
  infini,
  lingyiwanwu,
  volcengine,
}

// 内置的平台对应的中文名
final Map<UnifiedPlatformId, String> UPI_NAME_MAP = {
  UnifiedPlatformId.aliyun: '阿里百炼',
  UnifiedPlatformId.siliconCloud: '硅基流动',
  UnifiedPlatformId.deepseek: 'DeepSeek',
  UnifiedPlatformId.zhipu: '智谱',
  UnifiedPlatformId.infini: '无问芯穹',
  UnifiedPlatformId.lingyiwanwu: '零一万物',
  UnifiedPlatformId.volcengine: '火山方舟',
};

/// 统一平台规格模型
@JsonSerializable(explicitToJson: true)
class UnifiedPlatformSpec {
  // 如果是内置的平台，id必须是预定好的id字符串，因为在某些地方会作为逻辑判断
  final String id;

  @JsonKey(name: 'display_name')
  final String displayName;

  @JsonKey(name: 'host_url')
  final String hostUrl;

  @JsonKey(name: 'cc_prefix')
  final String ccPrefix;

  // 图片生成API端点
  @JsonKey(name: 'img_gen_prefix')
  final String? imgGenPrefix;

  // 语音合成API端点
  @JsonKey(name: 'tts_prefix')
  final String? ttsPrefix;

  // 语音识别API端点
  @JsonKey(name: 'asr_prefix')
  final String? asrPrefix;

  // 是否是内置的
  @JsonKey(name: 'is_built_in')
  final bool isBuiltIn;

  // 是否已激活（有测试过AK可以使用的平台，在平台列表页面可以展示已激活状态）
  @JsonKey(name: 'is_active')
  final bool isActive;

  final String? description;

  @JsonKey(name: 'extra_params')
  final Map<String, dynamic>? extraParams;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const UnifiedPlatformSpec({
    required this.id,
    required this.displayName,
    required this.hostUrl,
    this.ccPrefix = '/v1/chat/completions',
    this.imgGenPrefix,
    this.ttsPrefix,
    this.asrPrefix,
    this.isBuiltIn = false,
    this.isActive = false,
    this.description,
    this.extraParams,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UnifiedPlatformSpec.fromJson(Map<String, dynamic> json) =>
      _$UnifiedPlatformSpecFromJson(json);

  Map<String, dynamic> toJson() => _$UnifiedPlatformSpecToJson(this);

  factory UnifiedPlatformSpec.fromMap(Map<String, dynamic> map) {
    return UnifiedPlatformSpec(
      id: map['id'] as String,
      displayName: map['display_name'] as String,
      hostUrl: map['host_url'] as String,
      ccPrefix: map['cc_prefix'] as String? ?? '/v1/chat/completions',
      imgGenPrefix: map['img_gen_prefix'] as String?,
      ttsPrefix: map['tts_prefix'] as String?,
      asrPrefix: map['asr_prefix'] as String?,
      isBuiltIn: (map['is_built_in'] as int? ?? 0) == 1,
      isActive: (map['is_active'] as int? ?? 0) == 1,
      description: map['description'] as String?,
      extraParams: map['extra_params'] != null
          ? Map<String, dynamic>.from(json.decode(map['extra_params']))
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'display_name': displayName,
      'host_url': hostUrl,
      'cc_prefix': ccPrefix,
      'img_gen_prefix': imgGenPrefix,
      'tts_prefix': ttsPrefix,
      'asr_prefix': asrPrefix,
      'is_built_in': isBuiltIn ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'description': description,
      'extra_params': extraParams != null ? json.encode(extraParams) : null,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  UnifiedPlatformSpec copyWith({
    String? id,
    String? displayName,
    String? hostUrl,
    String? ccPrefix,
    String? imgGenPrefix,
    String? ttsPrefix,
    String? asrPrefix,
    bool? isBuiltIn,
    bool? isActive,
    String? description,
    Map<String, dynamic>? extraParams,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UnifiedPlatformSpec(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      hostUrl: hostUrl ?? this.hostUrl,
      ccPrefix: ccPrefix ?? this.ccPrefix,
      imgGenPrefix: imgGenPrefix ?? this.imgGenPrefix,
      ttsPrefix: ttsPrefix ?? this.ttsPrefix,
      asrPrefix: asrPrefix ?? this.asrPrefix,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      extraParams: extraParams ?? this.extraParams,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnifiedPlatformSpec && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UnifiedPlatformSpec(id: $id, displayName: $displayName)';
  }

  /// 获取完整的API URL
  String getChatCompletionsUrl() {
    final cleanBaseUrl = hostUrl.endsWith('/')
        ? hostUrl.substring(0, hostUrl.length - 1)
        : hostUrl;
    final cleanEndpoint = ccPrefix.startsWith('/') ? ccPrefix : '/$ccPrefix';
    return '$cleanBaseUrl$cleanEndpoint';
  }

  /// 获取图片生成API URL
  String? getImageGenerationUrl() {
    if (imgGenPrefix == null) return null;
    final cleanBaseUrl = hostUrl.endsWith('/')
        ? hostUrl.substring(0, hostUrl.length - 1)
        : hostUrl;
    final cleanEndpoint = imgGenPrefix!.startsWith('/')
        ? imgGenPrefix!
        : '/$imgGenPrefix!';
    return '$cleanBaseUrl$cleanEndpoint';
  }

  /// 获取语音合成API URL
  String? getTextToSpeechUrl() {
    if (ttsPrefix == null) return null;
    final cleanBaseUrl = hostUrl.endsWith('/')
        ? hostUrl.substring(0, hostUrl.length - 1)
        : hostUrl;
    final cleanEndpoint = ttsPrefix!.startsWith('/')
        ? ttsPrefix!
        : '/$ttsPrefix!';
    return '$cleanBaseUrl$cleanEndpoint';
  }

  /// 获取语音识别API URL
  String? getSpeechToTextUrl() {
    if (asrPrefix == null) return null;
    final cleanBaseUrl = hostUrl.endsWith('/')
        ? hostUrl.substring(0, hostUrl.length - 1)
        : hostUrl;
    final cleanEndpoint = asrPrefix!.startsWith('/')
        ? asrPrefix!
        : '/$asrPrefix!';
    return '$cleanBaseUrl$cleanEndpoint';
  }

  /// 根据模型类型获取对应的API端点
  String? getApiUrlForModelType(UnifiedModelType modelType) {
    switch (modelType) {
      case UnifiedModelType.cc:
        return getChatCompletionsUrl();
      case UnifiedModelType.tti:
      case UnifiedModelType.iti:
        return getImageGenerationUrl();
      case UnifiedModelType.tts:
        return getTextToSpeechUrl();
      case UnifiedModelType.asr:
        return getSpeechToTextUrl();
      case UnifiedModelType.embedding:
      case UnifiedModelType.reranker:
        return getChatCompletionsUrl(); // 暂时使用聊天端点
      // case UnifiedModelType.ttv:
      // case UnifiedModelType.itv:
      // return null; // 暂未支持
    }
  }

  /// 检查是否支持指定的模型类型
  bool supportsModelType(UnifiedModelType modelType) {
    return getApiUrlForModelType(modelType) != null;
  }

  /// 获取认证头
  Map<String, String> getAuthHeaders(String apiKey) {
    final headers = <String, String>{};

    // 验证都是统一的请求头中添加: "Authorization: Bearer <API Key>"
    headers['Authorization'] = 'Bearer $apiKey';

    // 如果谷歌等验证有其他验证内容，这里再扩展

    return headers;
  }
}
