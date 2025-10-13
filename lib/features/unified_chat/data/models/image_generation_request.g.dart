// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_generation_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImageGenerationRequest _$ImageGenerationRequestFromJson(
  Map<String, dynamic> json,
) => ImageGenerationRequest(
  model: json['model'] as String,
  prompt: json['prompt'] as String,
  negativePrompt: json['negativePrompt'] as String?,
  size: json['size'] as String?,
  n: (json['n'] as num?)?.toInt(),
  seed: (json['seed'] as num?)?.toInt(),
  steps: (json['steps'] as num?)?.toInt(),
  guidanceScale: (json['guidanceScale'] as num?)?.toDouble(),
  cfg: (json['cfg'] as num?)?.toDouble(),
  quality: json['quality'] as String?,
  style: json['style'] as String?,
  image: json['image'] as String?,
  maskImage: json['maskImage'] as String?,
  watermark: json['watermark'] as bool? ?? false,
  userId: json['userId'] as String?,
  sequentialImageGeneration: json['sequentialImageGeneration'] as String?,
  sequentialImageGenerationOptions: json['sequentialImageGenerationOptions'],
  responseFormat: json['responseFormat'] as String?,
);

Map<String, dynamic> _$ImageGenerationRequestToJson(
  ImageGenerationRequest instance,
) => <String, dynamic>{
  'model': instance.model,
  'prompt': instance.prompt,
  'negativePrompt': instance.negativePrompt,
  'size': instance.size,
  'n': instance.n,
  'seed': instance.seed,
  'steps': instance.steps,
  'guidanceScale': instance.guidanceScale,
  'cfg': instance.cfg,
  'quality': instance.quality,
  'style': instance.style,
  'image': instance.image,
  'maskImage': instance.maskImage,
  'watermark': instance.watermark,
  'userId': instance.userId,
  'sequentialImageGeneration': instance.sequentialImageGeneration,
  'sequentialImageGenerationOptions': instance.sequentialImageGenerationOptions,
  'responseFormat': instance.responseFormat,
};
