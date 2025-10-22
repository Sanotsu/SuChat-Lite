import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mime/mime.dart';

import 'unified_platform_spec.dart';

part 'unified_chat_message.g.dart';

/// 消息角色枚举
enum UnifiedMessageRole {
  @JsonValue('system')
  system,
  @JsonValue('user')
  user,
  @JsonValue('assistant')
  assistant,
  @JsonValue('function')
  function,
  @JsonValue('tool')
  tool,
}

/// 消息角色扩展
extension UnifiedMessageRoleExtension on UnifiedMessageRole {
  String get displayName {
    switch (this) {
      case UnifiedMessageRole.system:
        return '系统';
      case UnifiedMessageRole.user:
        return '用户';
      case UnifiedMessageRole.assistant:
        return '助手';
      case UnifiedMessageRole.function:
        return '函数';
      case UnifiedMessageRole.tool:
        return '工具';
    }
  }
}

/// 内容类型枚举
enum UnifiedContentType {
  @JsonValue('text')
  text,
  @JsonValue('image')
  image,
  @JsonValue('audio')
  audio,
  @JsonValue('video')
  video,
  @JsonValue('file')
  file,
  @JsonValue('multimodal')
  multimodal,
}

/// 多模态内容项
@JsonSerializable(explicitToJson: true)
class UnifiedContentItem {
  final String type;
  final String? text;
  @JsonKey(name: 'image_url')
  final UnifiedImageUrl? imageUrl;
  @JsonKey(name: 'audio_url')
  final String? audioUrl;
  @JsonKey(name: 'video_url')
  final String? videoUrl;
  @JsonKey(name: 'file_url')
  final String? fileUrl;
  @JsonKey(name: 'file_name')
  final String? fileName;
  @JsonKey(name: 'file_size')
  final int? fileSize;
  @JsonKey(name: 'mime_type')
  final String? mimeType;
  final Map<String, dynamic>? metadata;

  const UnifiedContentItem({
    required this.type,
    this.text,
    this.imageUrl,
    this.audioUrl,
    this.videoUrl,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.metadata,
  });

  // 从字符串转
  factory UnifiedContentItem.fromRawJson(String str) =>
      UnifiedContentItem.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory UnifiedContentItem.fromJson(Map<String, dynamic> json) =>
      _$UnifiedContentItemFromJson(json);

  Map<String, dynamic> toJson() => _$UnifiedContentItemToJson(this);

  factory UnifiedContentItem.text(String text) {
    return UnifiedContentItem(type: 'text', text: text);
  }

  factory UnifiedContentItem.image(String url, {String? detail}) {
    return UnifiedContentItem(
      type: 'image_url',
      imageUrl: UnifiedImageUrl(url: url, detail: detail ?? 'auto'),
    );
  }

  factory UnifiedContentItem.audio(
    String url, {
    String? fileName,
    int? fileSize,
  }) {
    return UnifiedContentItem(
      type: 'audio',
      audioUrl: url,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: 'audio/mpeg',
    );
  }

  factory UnifiedContentItem.video(
    String url, {
    String? fileName,
    int? fileSize,
  }) {
    return UnifiedContentItem(
      type: 'video',
      videoUrl: url,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: 'video/mp4',
    );
  }

  factory UnifiedContentItem.file(
    String url,
    String fileName, {
    int? fileSize,
    String? mimeType,
  }) {
    return UnifiedContentItem(
      type: 'file',
      fileUrl: url,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
    );
  }

  // 从item中获取指定类型的文件
  File? getFileByType(String type) {
    // 如果存在指定类型的多模态文件，才返回；否则返回null
    if (type == 'image_url' && imageUrl != null) {
      return File(imageUrl!.url);
    } else if (type == 'audio' && audioUrl != null) {
      return File(audioUrl!);
    } else if (type == 'video' && videoUrl != null) {
      return File(videoUrl!);
    } else if (type == 'file' && fileUrl != null) {
      return File(fileUrl!);
    }
    return null;
  }
}

/// 图片URL配置
@JsonSerializable(explicitToJson: true)
class UnifiedImageUrl {
  final String url;
  final String detail; // auto, low, high

  const UnifiedImageUrl({required this.url, this.detail = 'auto'});

  factory UnifiedImageUrl.fromJson(Map<String, dynamic> json) =>
      _$UnifiedImageUrlFromJson(json);

  Map<String, dynamic> toJson() => _$UnifiedImageUrlToJson(this);
}

/// 函数调用
@JsonSerializable(explicitToJson: true)
class UnifiedFunctionCall {
  final String name;
  final String arguments;

  const UnifiedFunctionCall({required this.name, required this.arguments});

  factory UnifiedFunctionCall.fromJson(Map<String, dynamic> json) =>
      _$UnifiedFunctionCallFromJson(json);

  Map<String, dynamic> toJson() => _$UnifiedFunctionCallToJson(this);
}

/// 工具调用
@JsonSerializable(explicitToJson: true)
class UnifiedToolCall {
  final String id;
  final String type;
  final UnifiedFunctionCall function;

  const UnifiedToolCall({
    required this.id,
    required this.type,
    required this.function,
  });

  factory UnifiedToolCall.fromJson(Map<String, dynamic> json) =>
      _$UnifiedToolCallFromJson(json);

  Map<String, dynamic> toJson() => _$UnifiedToolCallToJson(this);
}

/// 搜索结果参考链接
@JsonSerializable(explicitToJson: true)
class SearchReference {
  final String title;
  final String url;
  final String? description;
  final String? favicon;
  final String? publishedDate;
  final double? score;

  const SearchReference({
    required this.title,
    required this.url,
    this.description,
    this.favicon,
    this.publishedDate,
    this.score,
  });

  factory SearchReference.fromJson(Map<String, dynamic> json) =>
      _$SearchReferenceFromJson(json);

  Map<String, dynamic> toJson() => _$SearchReferenceToJson(this);

  factory SearchReference.fromSearchResultItem(dynamic item) {
    if (item is Map<String, dynamic>) {
      return SearchReference(
        title: item['title'] ?? '',
        url: item['url'] ?? '',
        description: item['content'] ?? item['description'],
        favicon: item['favicon'],
        publishedDate: item['publishedDate'] ?? item['published_date'],
        score: double.parse(item['score']?.toString() ?? '0'),
      );
    }
    return SearchReference(title: '', url: '');
  }
}

/// 统一聊天消息模型
@JsonSerializable(explicitToJson: true)
class UnifiedChatMessage {
  final String id;

  @JsonKey(name: 'conversation_id')
  final String conversationId;

  final UnifiedMessageRole role;

  @JsonKey(name: 'thinking_content')
  final String? thinkingContent;

  // 思考的时间
  @JsonKey(name: 'thinking_time')
  final int? thinkingTime;

  final String? content;

  @JsonKey(name: 'content_type')
  final UnifiedContentType contentType;

  @JsonKey(name: 'multimodal_content')
  final List<UnifiedContentItem>? multimodalContent;

  @JsonKey(name: 'function_call')
  final UnifiedFunctionCall? functionCall;

  @JsonKey(name: 'tool_calls')
  final List<UnifiedToolCall>? toolCalls;

  @JsonKey(name: 'tool_call_id')
  final String? toolCallId;

  final String? name;

  @JsonKey(name: 'finish_reason')
  final String? finishReason;

  @JsonKey(name: 'token_count')
  final int tokenCount;

  final double cost;

  @JsonKey(name: 'model_name_used')
  final String? modelNameUsed;

  @JsonKey(name: 'platform_id_used')
  final String? platformIdUsed;

  @JsonKey(name: 'response_time_ms')
  final int? responseTimeMs;

  @JsonKey(name: 'is_streaming')
  final bool isStreaming;

  @JsonKey(name: 'is_error')
  final bool isError;

  @JsonKey(name: 'error_message')
  final String? errorMessage;

  // 搜索结果链接（用于联网搜索功能）
  @JsonKey(name: 'search_references')
  final List<SearchReference>? searchReferences;

  // 元数据可以存放平台和模型信息？
  final Map<String, dynamic>? metadata;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  // 兼容性字段
  DateTime get timestamp => createdAt;
  int get tokens => tokenCount;

  const UnifiedChatMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    this.thinkingContent,
    this.thinkingTime,
    this.content,
    this.contentType = UnifiedContentType.text,
    this.multimodalContent,
    this.functionCall,
    this.toolCalls,
    this.toolCallId,
    this.name,
    this.finishReason,
    this.tokenCount = 0,
    this.cost = 0.0,
    this.modelNameUsed,
    this.platformIdUsed,
    this.responseTimeMs,
    this.isStreaming = false,
    this.isError = false,
    this.errorMessage,
    this.searchReferences,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  // 从字符串转
  factory UnifiedChatMessage.fromRawJson(String str) =>
      UnifiedChatMessage.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory UnifiedChatMessage.fromJson(Map<String, dynamic> json) =>
      _$UnifiedChatMessageFromJson(json);

  Map<String, dynamic> toJson() => _$UnifiedChatMessageToJson(this);

  factory UnifiedChatMessage.fromMap(Map<String, dynamic> map) {
    return UnifiedChatMessage(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      role: UnifiedMessageRole.values.firstWhere(
        (e) => e.toString().split('.').last == map['role'],
      ),
      thinkingContent: map['thinking_content'] as String?,
      thinkingTime: map['thinking_time'] as int?,
      content: map['content'] as String?,
      contentType: UnifiedContentType.values.firstWhere(
        (e) => e.toString().split('.').last == map['content_type'],
        orElse: () => UnifiedContentType.text,
      ),
      multimodalContent: map['multimodal_content'] != null
          ? (json.decode(map['multimodal_content']) as List)
                .map(
                  (e) => UnifiedContentItem.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : null,
      functionCall: map['function_call'] != null
          ? UnifiedFunctionCall.fromJson(
              map['function_call'] as Map<String, dynamic>,
            )
          : null,
      toolCalls: map['tool_calls'] != null
          ? (json.decode(map['tool_calls']) as List)
                .map((e) => UnifiedToolCall.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      toolCallId: map['tool_call_id'] as String?,
      name: map['name'] as String?,
      finishReason: map['finish_reason'] as String?,
      tokenCount: map['token_count'] as int? ?? 0,
      cost: (map['cost'] as num?)?.toDouble() ?? 0.0,
      modelNameUsed: map['model_name_used'] as String?,
      platformIdUsed: map['platform_id_used'] as String?,
      responseTimeMs: map['response_time_ms'] as int?,
      isStreaming: (map['is_streaming'] as int? ?? 0) == 1,
      isError: (map['is_error'] as int? ?? 0) == 1,
      errorMessage: map['error_message'] as String?,
      searchReferences: map['search_references'] != null
          ? (json.decode(map['search_references']) as List)
                .map((e) => SearchReference.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(json.decode(map['metadata']))
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'role': role.toString().split('.').last,
      'thinking_content': thinkingContent,
      'thinking_time': thinkingTime,
      'content': content,
      'content_type': contentType.toString().split('.').last,
      'multimodal_content': multimodalContent != null
          ? json.encode(multimodalContent?.map((e) => e.toJson()).toList())
          : null,
      'function_call': functionCall?.toJson(),
      'tool_calls': toolCalls != null
          ? json.encode(toolCalls?.map((e) => e.toJson()).toList())
          : null,
      'tool_call_id': toolCallId,
      'name': name,
      'finish_reason': finishReason,
      'token_count': tokenCount,
      'cost': cost,
      'model_name_used': modelNameUsed,
      'platform_id_used': platformIdUsed,
      'response_time_ms': responseTimeMs,
      'is_streaming': isStreaming ? 1 : 0,
      'is_error': isError ? 1 : 0,
      'error_message': errorMessage,
      'search_references': searchReferences != null
          ? json.encode(searchReferences?.map((e) => e.toJson()).toList())
          : null,
      'metadata': metadata != null ? json.encode(metadata) : null,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  UnifiedChatMessage copyWith({
    String? id,
    String? conversationId,
    UnifiedMessageRole? role,
    String? thinkingContent,
    int? thinkingTime,
    String? content,
    UnifiedContentType? contentType,
    List<UnifiedContentItem>? multimodalContent,
    UnifiedFunctionCall? functionCall,
    List<UnifiedToolCall>? toolCalls,
    String? toolCallId,
    String? name,
    String? finishReason,
    int? tokenCount,
    double? cost,
    String? modelNameUsed,
    String? platformIdUsed,
    int? responseTimeMs,
    bool? isStreaming,
    bool? isError,
    String? errorMessage,
    List<SearchReference>? searchReferences,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UnifiedChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      thinkingContent: thinkingContent ?? this.thinkingContent,
      thinkingTime: thinkingTime ?? this.thinkingTime,
      content: content ?? this.content,
      contentType: contentType ?? this.contentType,
      multimodalContent: multimodalContent ?? this.multimodalContent,
      functionCall: functionCall ?? this.functionCall,
      toolCalls: toolCalls ?? this.toolCalls,
      toolCallId: toolCallId ?? this.toolCallId,
      name: name ?? this.name,
      finishReason: finishReason ?? this.finishReason,
      tokenCount: tokenCount ?? this.tokenCount,
      cost: cost ?? this.cost,
      modelNameUsed: modelNameUsed ?? this.modelNameUsed,
      platformIdUsed: platformIdUsed ?? this.platformIdUsed,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
      isStreaming: isStreaming ?? this.isStreaming,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
      searchReferences: searchReferences ?? this.searchReferences,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnifiedChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UnifiedChatMessage(id: $id, role: $role, contentType: $contentType)';
  }

  /// 是否为用户消息
  bool get isUser => role == UnifiedMessageRole.user;

  /// 是否为助手消息
  bool get isAssistant => role == UnifiedMessageRole.assistant;

  /// 是否为系统消息
  bool get isSystem => role == UnifiedMessageRole.system;

  /// 是否包含多模态内容
  bool get hasMultimodalContent =>
      multimodalContent != null && multimodalContent!.isNotEmpty;

  /// 是否包含图片
  bool get hasImages =>
      hasMultimodalContent &&
      multimodalContent!.any((item) => item.type == 'image_url');

  /// 是否包含音频
  bool get hasAudio =>
      hasMultimodalContent &&
      multimodalContent!.any((item) => item.type == 'audio');

  /// 是否包含视频
  bool get hasVideo =>
      hasMultimodalContent &&
      multimodalContent!.any((item) => item.type == 'video');

  /// 是否包含文件
  bool get hasFiles =>
      hasMultimodalContent &&
      multimodalContent!.any((item) => item.type == 'file');

  /// 是否包含函数调用
  bool get hasFunctionCall =>
      functionCall != null || (toolCalls != null && toolCalls!.isNotEmpty);

  /// 获取显示内容
  String get displayContent {
    if (content != null && content!.isNotEmpty) {
      return content!;
    }

    if (hasMultimodalContent) {
      final textItems = multimodalContent!.where((item) => item.type == 'text');
      if (textItems.isNotEmpty) {
        return textItems.map((item) => item.text ?? '').join('\n');
      }

      // 如果没有文本，返回媒体类型描述
      final mediaTypes = multimodalContent!.map((item) => item.type).toSet();
      return '[${mediaTypes.join(', ')}]';
    }

    if (hasFunctionCall) {
      return '[函数调用: ${functionCall?.name ?? toolCalls?.first.function.name}]';
    }

    return '';
  }

  /// 获取消息摘要
  String get summary {
    final displayText = displayContent;
    if (displayText.length <= 50) {
      return displayText;
    }
    return '${displayText.substring(0, 50)}...';
  }

  /// 获取响应时间描述
  String get responseTimeDescription {
    if (responseTimeMs == null) return '';

    if (responseTimeMs! < 1000) {
      return '${responseTimeMs}ms';
    } else {
      return '${(responseTimeMs! / 1000).toStringAsFixed(1)}s';
    }
  }

  /// 获取成本格式化字符串
  String get formattedCost {
    if (cost < 0.001) {
      return '< ¥0.001';
    } else if (cost < 0.01) {
      return '¥${cost.toStringAsFixed(4)}';
    } else {
      return '¥${cost.toStringAsFixed(3)}';
    }
  }

  /// 转换为OpenAI API格式
  Map<String, dynamic> toOpenAIFormat() {
    final result = <String, dynamic>{'role': role.toString().split('.').last};

    if (hasMultimodalContent) {
      result['content'] = _convertMultimodalContentToOpenAI();
    } else if (content != null) {
      result['content'] = content;
    }

    if (functionCall != null) {
      result['function_call'] = functionCall!.toJson();
    }

    if (toolCalls != null && toolCalls!.isNotEmpty) {
      result['tool_calls'] = toolCalls!.map((call) => call.toJson()).toList();
    }

    if (toolCallId != null) {
      result['tool_call_id'] = toolCallId;
    }

    if (name != null) {
      result['name'] = name;
    }

    return result;
  }

  /// 将多模态内容转换为OpenAI API格式
  List<Map<String, dynamic>> _convertMultimodalContentToOpenAI() {
    final result = <Map<String, dynamic>>[];

    // 首先添加文本内容（如果存在）
    if (content != null && content!.isNotEmpty) {
      result.add({'type': 'text', 'text': content});
    }

    // 先获得消息使用的平台，在不同平台模型中可以有细微差异
    // 比如如果是智谱的，图片参数不能带detail
    String platformId = '';
    if (metadata != null && metadata!['platform'] != null) {
      if (metadata!['platform'] is UnifiedPlatformSpec) {
        platformId = (metadata!['platform'] as UnifiedPlatformSpec).id;
      } else if (metadata!['platform'] is Map<String, dynamic>) {
        platformId = (metadata!['platform'] as Map<String, dynamic>)['id'];
      }
    }

    // 处理多模态内容项
    for (final item in multimodalContent!) {
      switch (item.type) {
        // 如果有其他媒体资源同时有文本，就很上面那首先添加文本重复了？？？
        case 'text':
          // if (item.text != null && item.text!.isNotEmpty) {
          //   result.add({'type': 'text', 'text': item.text});
          // }
          break;
        case 'image_url':
          if (item.imageUrl != null) {
            result.add({
              'type': 'image_url',
              'image_url': {
                'url': _convertToBase64(item.imageUrl!.url),
                if (platformId != UnifiedPlatformId.zhipu.name)
                  'detail': item.imageUrl!.detail,
              },
            });
          }
          break;
        case 'video':
          if (item.videoUrl != null &&
              platformId == UnifiedPlatformId.aliyun.name) {
            // 这个是直接传入视频文件；如果是图片列表形式的视频:
            // {"type": "video","video": ["https://img.1.jpg","https://img.2.jpg","……"]},
            result.add({
              'type': 'video_url',
              'video_url': {
                'url': _convertToBase64(item.videoUrl!, fileType: 'video'),
              },
            });
          }
        // 2025-10-15 这里暂时是cc模型发送音频和文件，语音识别传入的音频文件有单独其他地方处理
        case 'audio':
          // 2025-10-15 暂时只有阿里百炼的qwen-omni系列模型可以传入音频文件
          if (item.audioUrl != null &&
              platformId == UnifiedPlatformId.aliyun.name &&
              // omni可以合成音频，但添加到 messages 数组中的 Assistant Message 只可以包含文本数据。
              // https://bailian.console.aliyun.com/?switchAgent=10147514&productCode=p_efm&switchUserType=3&tab=doc#/doc/?type=model&url=2867839
              role == UnifiedMessageRole.user) {
            result.add({
              'type': 'input_audio',
              'input_audio': {
                'data': _convertToBase64(item.audioUrl!, fileType: 'audio'),
                'format': item.audioUrl!.split('.').last,
              },
            });
          }

        case 'file':
          // TODO 这里应该是留着上传文档文件，解析出文档内容，喂给大模型处理(暂时转换为文本描述)
          final fileName = item.fileName ?? '未知文件';
          final fileType = item.type;
          result.add({'type': 'text', 'text': '[附件: $fileName ($fileType)]'});
          break;
        default:
          // 未知类型，转换为文本描述
          result.add({'type': 'text', 'text': '[未知内容类型: ${item.type}]'});
      }
    }

    return result;
  }

  /// 将图片或视频转换为base64格式
  String _convertToBase64(String fileUrl, {String fileType = 'image'}) {
    // 如果已经是base64格式的图片/视频/音频，直接返回
    if (fileType == 'image' && fileUrl.startsWith('data:image/')) {
      return fileUrl;
    }
    if (fileType == 'video' && fileUrl.startsWith('data:video/')) {
      return fileUrl;
    }
    if (fileType == 'audio' && fileUrl.startsWith('data:audio/')) {
      return fileUrl;
    }

    // 如果是网络图片/视频，直接返回URL
    if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
      return fileUrl;
    }

    // 如果是本地文件，转换为base64
    try {
      final file = File(fileUrl);
      if (file.existsSync()) {
        final bytes = file.readAsBytesSync();
        final base64String = base64Encode(bytes);

        // 获取文件类型
        final mimeType = lookupMimeType(file.path);

        // 返回base64字符串
        return 'data:$mimeType;base64,$base64String';
      }
    } catch (e) {
      if (kDebugMode) {
        print('转换文件到base64失败: $e');
      }
    }

    // 如果转换失败，返回原始URL
    return fileUrl;
  }

  /// 获取多模态内容项列表
  List<UnifiedContentItem> getMultimodalContentItems() {
    return multimodalContent ?? [];
  }
}
