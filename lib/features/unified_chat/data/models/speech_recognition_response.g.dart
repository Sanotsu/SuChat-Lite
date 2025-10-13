// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'speech_recognition_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpeechRecognitionResponse _$SpeechRecognitionResponseFromJson(
  Map<String, dynamic> json,
) => SpeechRecognitionResponse(
  text: json['text'] as String,
  requestId: json['request_id'] as String?,
  taskId: json['task_id'] as String?,
  language: json['language'] as String?,
  segments: (json['segments'] as List<dynamic>?)
      ?.map((e) => SpeechSegment.fromJson(e as Map<String, dynamic>))
      .toList(),
  created: (json['created'] as num?)?.toInt(),
  model: json['model'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$SpeechRecognitionResponseToJson(
  SpeechRecognitionResponse instance,
) => <String, dynamic>{
  'text': instance.text,
  'request_id': instance.requestId,
  'task_id': instance.taskId,
  'language': instance.language,
  'segments': instance.segments?.map((e) => e.toJson()).toList(),
  'created': instance.created,
  'model': instance.model,
  'metadata': instance.metadata,
};

SpeechSegment _$SpeechSegmentFromJson(Map<String, dynamic> json) =>
    SpeechSegment(
      id: (json['id'] as num).toInt(),
      start: (json['start'] as num).toDouble(),
      end: (json['end'] as num).toDouble(),
      text: json['text'] as String,
    );

Map<String, dynamic> _$SpeechSegmentToJson(SpeechSegment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'start': instance.start,
      'end': instance.end,
      'text': instance.text,
    };
