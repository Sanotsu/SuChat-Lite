// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_generation_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoGenerationRequest _$VideoGenerationRequestFromJson(
  Map<String, dynamic> json,
) => VideoGenerationRequest(
  model: json['model'] as String,
  prompt: json['prompt'] as String,
  size: json['size'] as String?,
  refImage: json['ref_image'] as String?,
  input: json['input'] == null
      ? null
      : AliyunVideoInput.fromJson(json['input'] as Map<String, dynamic>),
  parameters: json['parameters'] == null
      ? null
      : AliyunVideoParameter.fromJson(
          json['parameters'] as Map<String, dynamic>,
        ),
  resolution: json['resolution'] as String?,
  duration: (json['duration'] as num?)?.toInt(),
  negativePrompt: json['negative_prompt'] as String?,
  quality: json['quality'] as String?,
  withAudio: json['with_audio'] as bool?,
  fps: (json['fps'] as num?)?.toInt(),
  requestId: json['request_id'] as String?,
  userId: json['user_id'] as String?,
  seed: (json['seed'] as num?)?.toInt(),
);

Map<String, dynamic> _$VideoGenerationRequestToJson(
  VideoGenerationRequest instance,
) => <String, dynamic>{
  'model': instance.model,
  'prompt': instance.prompt,
  'size': instance.size,
  'ref_image': instance.refImage,
  'input': instance.input?.toJson(),
  'parameters': instance.parameters?.toJson(),
  'resolution': instance.resolution,
  'duration': instance.duration,
  'quality': instance.quality,
  'with_audio': instance.withAudio,
  'fps': instance.fps,
  'request_id': instance.requestId,
  'user_id': instance.userId,
  'negative_prompt': instance.negativePrompt,
  'seed': instance.seed,
};

AliyunVideoInput _$AliyunVideoInputFromJson(Map<String, dynamic> json) =>
    AliyunVideoInput(
      prompt: json['prompt'] as String?,
      imgUrl: json['img_url'] as String?,
    );

Map<String, dynamic> _$AliyunVideoInputToJson(AliyunVideoInput instance) =>
    <String, dynamic>{'prompt': instance.prompt, 'img_url': instance.imgUrl};

AliyunVideoParameter _$AliyunVideoParameterFromJson(
  Map<String, dynamic> json,
) => AliyunVideoParameter(
  size: json['size'] as String?,
  resolution: json['resolution'] as String?,
  seed: (json['seed'] as num?)?.toInt(),
  duration: (json['duration'] as num?)?.toInt() ?? 5,
  promptExtend: json['prompt_extend'] as bool? ?? true,
);

Map<String, dynamic> _$AliyunVideoParameterToJson(
  AliyunVideoParameter instance,
) => <String, dynamic>{
  'size': instance.size,
  'resolution': instance.resolution,
  'duration': instance.duration,
  'prompt_extend': instance.promptExtend,
  'seed': instance.seed,
};
