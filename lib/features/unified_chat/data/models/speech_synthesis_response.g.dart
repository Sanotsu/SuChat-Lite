// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'speech_synthesis_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpeechSynthesisResponse _$SpeechSynthesisResponseFromJson(
  Map<String, dynamic> json,
) => SpeechSynthesisResponse(
  audioUrl: json['audioUrl'] as String?,
  audioBase64: json['audioBase64'] as String?,
  format: json['format'] as String?,
  duration: (json['duration'] as num?)?.toInt(),
  taskId: json['taskId'] as String?,
  requestId: json['requestId'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$SpeechSynthesisResponseToJson(
  SpeechSynthesisResponse instance,
) => <String, dynamic>{
  'audioUrl': instance.audioUrl,
  'audioBase64': instance.audioBase64,
  'format': instance.format,
  'duration': instance.duration,
  'taskId': instance.taskId,
  'requestId': instance.requestId,
  'metadata': instance.metadata,
};
