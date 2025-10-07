// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

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

  @JsonKey(name: 'api_prefix')
  final String apiPrefix;

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
    this.apiPrefix = '/v1/chat/completions',
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
      apiPrefix: map['api_prefix'] as String? ?? '/v1/chat/completions',
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
      'api_prefix': apiPrefix,
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
    String? apiPrefix,
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
      apiPrefix: apiPrefix ?? this.apiPrefix,
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
  String getApiUrl() {
    final cleanBaseUrl = hostUrl.endsWith('/')
        ? hostUrl.substring(0, hostUrl.length - 1)
        : hostUrl;
    final cleanEndpoint = apiPrefix.startsWith('/') ? apiPrefix : '/$apiPrefix';
    return '$cleanBaseUrl$cleanEndpoint';
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
