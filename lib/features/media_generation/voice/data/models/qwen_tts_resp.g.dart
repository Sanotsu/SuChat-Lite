// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qwen_tts_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QwenTTSResp _$QwenTTSRespFromJson(Map<String, dynamic> json) => QwenTTSResp(
  QwenTTSOutput.fromJson(json['output'] as Map<String, dynamic>),
  QwenTTSUsage.fromJson(json['usage'] as Map<String, dynamic>),
  json['request_id'] as String,
);

Map<String, dynamic> _$QwenTTSRespToJson(QwenTTSResp instance) =>
    <String, dynamic>{
      'output': instance.output.toJson(),
      'usage': instance.usage.toJson(),
      'request_id': instance.requestId,
    };

QwenTTSOutput _$QwenTTSOutputFromJson(Map<String, dynamic> json) =>
    QwenTTSOutput(
      json['finish_reason'] as String,
      QwenTTSAudio.fromJson(json['audio'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$QwenTTSOutputToJson(QwenTTSOutput instance) =>
    <String, dynamic>{
      'finish_reason': instance.finishReason,
      'audio': instance.audio.toJson(),
    };

QwenTTSAudio _$QwenTTSAudioFromJson(Map<String, dynamic> json) => QwenTTSAudio(
  (json['expires_at'] as num).toInt(),
  json['data'] as String,
  json['id'] as String,
  json['url'] as String,
);

Map<String, dynamic> _$QwenTTSAudioToJson(QwenTTSAudio instance) =>
    <String, dynamic>{
      'expires_at': instance.expiresAt,
      'data': instance.data,
      'id': instance.id,
      'url': instance.url,
    };

QwenTTSUsage _$QwenTTSUsageFromJson(Map<String, dynamic> json) => QwenTTSUsage(
  QwenTTSInputTokensDetails.fromJson(
    json['input_tokens_details'] as Map<String, dynamic>,
  ),
  (json['total_tokens'] as num).toInt(),
  (json['output_tokens'] as num).toInt(),
  (json['input_tokens'] as num).toInt(),
  QwenTTSOutputTokensDetails.fromJson(
    json['output_tokens_details'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$QwenTTSUsageToJson(QwenTTSUsage instance) =>
    <String, dynamic>{
      'input_tokens_details': instance.inputTokensDetails.toJson(),
      'total_tokens': instance.totalTokens,
      'output_tokens': instance.outputTokens,
      'input_tokens': instance.inputTokens,
      'output_tokens_details': instance.outputTokensDetails.toJson(),
    };

QwenTTSInputTokensDetails _$QwenTTSInputTokensDetailsFromJson(
  Map<String, dynamic> json,
) => QwenTTSInputTokensDetails((json['text_tokens'] as num).toInt());

Map<String, dynamic> _$QwenTTSInputTokensDetailsToJson(
  QwenTTSInputTokensDetails instance,
) => <String, dynamic>{'text_tokens': instance.textTokens};

QwenTTSOutputTokensDetails _$QwenTTSOutputTokensDetailsFromJson(
  Map<String, dynamic> json,
) => QwenTTSOutputTokensDetails(
  (json['audio_tokens'] as num).toInt(),
  (json['text_tokens'] as num).toInt(),
);

Map<String, dynamic> _$QwenTTSOutputTokensDetailsToJson(
  QwenTTSOutputTokensDetails instance,
) => <String, dynamic>{
  'audio_tokens': instance.audioTokens,
  'text_tokens': instance.textTokens,
};
