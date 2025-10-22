// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_generation_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImageGenerationResponse _$ImageGenerationResponseFromJson(
  Map<String, dynamic> json,
) => ImageGenerationResponse(
  created: (json['created'] as num?)?.toInt(),
  data: (json['data'] as List<dynamic>)
      .map((e) => GeneratedImage.fromJson(e as Map<String, dynamic>))
      .toList(),
  timings: json['timings'] as Map<String, dynamic>?,
  seed: (json['seed'] as num?)?.toInt(),
  contentFilter: (json['contentFilter'] as List<dynamic>?)
      ?.map((e) => ContentFilter.fromJson(e as Map<String, dynamic>))
      .toList(),
  requestId: json['requestId'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ImageGenerationResponseToJson(
  ImageGenerationResponse instance,
) => <String, dynamic>{
  'created': instance.created,
  'data': instance.data.map((e) => e.toJson()).toList(),
  'timings': instance.timings,
  'seed': instance.seed,
  'contentFilter': instance.contentFilter?.map((e) => e.toJson()).toList(),
  'requestId': instance.requestId,
  'metadata': instance.metadata,
};

GeneratedImage _$GeneratedImageFromJson(Map<String, dynamic> json) =>
    GeneratedImage(
      url: json['url'] as String?,
      b64Json: json['b64_json'] as String?,
    );

Map<String, dynamic> _$GeneratedImageToJson(GeneratedImage instance) =>
    <String, dynamic>{'url': instance.url, 'b64_json': instance.b64Json};

ContentFilter _$ContentFilterFromJson(Map<String, dynamic> json) =>
    ContentFilter(
      role: json['role'] as String,
      level: (json['level'] as num).toInt(),
    );

Map<String, dynamic> _$ContentFilterToJson(ContentFilter instance) =>
    <String, dynamic>{'role': instance.role, 'level': instance.level};
