// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'speech_recognition_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpeechRecognitionRequest _$SpeechRecognitionRequestFromJson(
  Map<String, dynamic> json,
) => SpeechRecognitionRequest(
  model: json['model'] as String,
  audioPath: json['audioPath'] as String?,
  audioUrl: json['audioUrl'] as String?,
  language: json['language'] as String?,
  temperature: (json['temperature'] as num?)?.toDouble(),
  stream: json['stream'] as bool?,
  enableLid: json['enable_lid'] as bool?,
  enableItn: json['enable_itn'] as bool?,
  context: json['context'] as String?,
  requestId: json['request_id'] as String?,
  userId: json['user_id'] as String?,
);

Map<String, dynamic> _$SpeechRecognitionRequestToJson(
  SpeechRecognitionRequest instance,
) => <String, dynamic>{
  'audioPath': instance.audioPath,
  'audioUrl': instance.audioUrl,
  'model': instance.model,
  'language': instance.language,
  'temperature': instance.temperature,
  'stream': instance.stream,
  'enable_lid': instance.enableLid,
  'enable_itn': instance.enableItn,
  'context': instance.context,
  'request_id': instance.requestId,
  'user_id': instance.userId,
};
