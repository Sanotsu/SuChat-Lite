// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'speech_synthesis_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpeechSynthesisRequest _$SpeechSynthesisRequestFromJson(
  Map<String, dynamic> json,
) => SpeechSynthesisRequest(
  model: json['model'] as String,
  input: json['input'] as String,
  voice: json['voice'] as String?,
  responseFormat: json['response_format'] as String?,
  speed: (json['speed'] as num?)?.toDouble(),
  volume: (json['volume'] as num?)?.toDouble(),
  languageType: json['language_type'] as String?,
  stream: json['stream'] as bool?,
  watermark: json['watermark'] as bool?,
  encodeFormat: json['encode_format'] as String?,
  gain: (json['gain'] as num?)?.toDouble(),
);

Map<String, dynamic> _$SpeechSynthesisRequestToJson(
  SpeechSynthesisRequest instance,
) => <String, dynamic>{
  'model': instance.model,
  'input': instance.input,
  'voice': instance.voice,
  'stream': instance.stream,
  'response_format': instance.responseFormat,
  'speed': instance.speed,
  'language_type': instance.languageType,
  'volume': instance.volume,
  'encode_format': instance.encodeFormat,
  'watermark': instance.watermark,
  'gain': instance.gain,
};
