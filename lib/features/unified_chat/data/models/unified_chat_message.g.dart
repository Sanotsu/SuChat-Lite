// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unified_chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnifiedContentItem _$UnifiedContentItemFromJson(Map<String, dynamic> json) =>
    UnifiedContentItem(
      type: json['type'] as String,
      text: json['text'] as String?,
      imageUrl: json['image_url'] == null
          ? null
          : UnifiedImageUrl.fromJson(json['image_url'] as Map<String, dynamic>),
      audioUrl: json['audio_url'] as String?,
      videoUrl: json['video_url'] as String?,
      fileUrl: json['file_url'] as String?,
      fileName: json['file_name'] as String?,
      fileSize: (json['file_size'] as num?)?.toInt(),
      mimeType: json['mime_type'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$UnifiedContentItemToJson(UnifiedContentItem instance) =>
    <String, dynamic>{
      'type': instance.type,
      'text': instance.text,
      'image_url': instance.imageUrl?.toJson(),
      'audio_url': instance.audioUrl,
      'video_url': instance.videoUrl,
      'file_url': instance.fileUrl,
      'file_name': instance.fileName,
      'file_size': instance.fileSize,
      'mime_type': instance.mimeType,
      'metadata': instance.metadata,
    };

UnifiedImageUrl _$UnifiedImageUrlFromJson(Map<String, dynamic> json) =>
    UnifiedImageUrl(
      url: json['url'] as String,
      detail: json['detail'] as String? ?? 'auto',
    );

Map<String, dynamic> _$UnifiedImageUrlToJson(UnifiedImageUrl instance) =>
    <String, dynamic>{'url': instance.url, 'detail': instance.detail};

UnifiedFunctionCall _$UnifiedFunctionCallFromJson(Map<String, dynamic> json) =>
    UnifiedFunctionCall(
      name: json['name'] as String,
      arguments: json['arguments'] as String,
    );

Map<String, dynamic> _$UnifiedFunctionCallToJson(
  UnifiedFunctionCall instance,
) => <String, dynamic>{'name': instance.name, 'arguments': instance.arguments};

UnifiedToolCall _$UnifiedToolCallFromJson(Map<String, dynamic> json) =>
    UnifiedToolCall(
      id: json['id'] as String,
      type: json['type'] as String,
      function: UnifiedFunctionCall.fromJson(
        json['function'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$UnifiedToolCallToJson(UnifiedToolCall instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'function': instance.function.toJson(),
    };

SearchReference _$SearchReferenceFromJson(Map<String, dynamic> json) =>
    SearchReference(
      title: json['title'] as String,
      url: json['url'] as String,
      description: json['description'] as String?,
      favicon: json['favicon'] as String?,
      publishedDate: json['publishedDate'] as String?,
      score: (json['score'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$SearchReferenceToJson(SearchReference instance) =>
    <String, dynamic>{
      'title': instance.title,
      'url': instance.url,
      'description': instance.description,
      'favicon': instance.favicon,
      'publishedDate': instance.publishedDate,
      'score': instance.score,
    };

UnifiedChatMessage _$UnifiedChatMessageFromJson(Map<String, dynamic> json) =>
    UnifiedChatMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      role: $enumDecode(_$UnifiedMessageRoleEnumMap, json['role']),
      thinkingContent: json['thinking_content'] as String?,
      thinkingTime: (json['thinking_time'] as num?)?.toInt(),
      content: json['content'] as String?,
      contentType:
          $enumDecodeNullable(
            _$UnifiedContentTypeEnumMap,
            json['content_type'],
          ) ??
          UnifiedContentType.text,
      multimodalContent: (json['multimodal_content'] as List<dynamic>?)
          ?.map((e) => UnifiedContentItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      functionCall: json['function_call'] == null
          ? null
          : UnifiedFunctionCall.fromJson(
              json['function_call'] as Map<String, dynamic>,
            ),
      toolCalls: (json['tool_calls'] as List<dynamic>?)
          ?.map((e) => UnifiedToolCall.fromJson(e as Map<String, dynamic>))
          .toList(),
      toolCallId: json['tool_call_id'] as String?,
      name: json['name'] as String?,
      finishReason: json['finish_reason'] as String?,
      tokenCount: (json['token_count'] as num?)?.toInt() ?? 0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      modelNameUsed: json['model_name_used'] as String?,
      platformIdUsed: json['platform_id_used'] as String?,
      responseTimeMs: (json['response_time_ms'] as num?)?.toInt(),
      isStreaming: json['is_streaming'] as bool? ?? false,
      isError: json['is_error'] as bool? ?? false,
      errorMessage: json['error_message'] as String?,
      searchReferences: (json['search_references'] as List<dynamic>?)
          ?.map((e) => SearchReference.fromJson(e as Map<String, dynamic>))
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$UnifiedChatMessageToJson(UnifiedChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conversation_id': instance.conversationId,
      'role': _$UnifiedMessageRoleEnumMap[instance.role]!,
      'thinking_content': instance.thinkingContent,
      'thinking_time': instance.thinkingTime,
      'content': instance.content,
      'content_type': _$UnifiedContentTypeEnumMap[instance.contentType]!,
      'multimodal_content': instance.multimodalContent
          ?.map((e) => e.toJson())
          .toList(),
      'function_call': instance.functionCall?.toJson(),
      'tool_calls': instance.toolCalls?.map((e) => e.toJson()).toList(),
      'tool_call_id': instance.toolCallId,
      'name': instance.name,
      'finish_reason': instance.finishReason,
      'token_count': instance.tokenCount,
      'cost': instance.cost,
      'model_name_used': instance.modelNameUsed,
      'platform_id_used': instance.platformIdUsed,
      'response_time_ms': instance.responseTimeMs,
      'is_streaming': instance.isStreaming,
      'is_error': instance.isError,
      'error_message': instance.errorMessage,
      'search_references': instance.searchReferences
          ?.map((e) => e.toJson())
          .toList(),
      'metadata': instance.metadata,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$UnifiedMessageRoleEnumMap = {
  UnifiedMessageRole.system: 'system',
  UnifiedMessageRole.user: 'user',
  UnifiedMessageRole.assistant: 'assistant',
  UnifiedMessageRole.function: 'function',
  UnifiedMessageRole.tool: 'tool',
};

const _$UnifiedContentTypeEnumMap = {
  UnifiedContentType.text: 'text',
  UnifiedContentType.image: 'image',
  UnifiedContentType.audio: 'audio',
  UnifiedContentType.video: 'video',
  UnifiedContentType.file: 'file',
  UnifiedContentType.multimodal: 'multimodal',
};
