import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../../../../../shared/constants/constant_llm_enum.dart';

part 'image_generation_request.g.dart';

@JsonSerializable(explicitToJson: true)
class ImageGenerationRequest {
  // 标准必填参数
  final String model;
  final String prompt;
  // 这两个是页面功能设计时传入的生成数量和尺寸，在实际构建请求参数时再赋值给特定参数
  // 比如硅基流动中，size是image_size，n 是 batch_size
  // 智谱AI中 size是size，没有n
  final int? n;
  final String? size;

  /// 2025-05-08 硅基流动中，现在只有 Kwai-Kolors/Kolors
  //  必填 model prompt image_size(即size) batch_size(即n) num_inference_steps guidance_scale
  //  可选 negative_prompt seed image(参考图)
  @JsonKey(name: 'num_inference_steps')
  final int? numInferenceSteps;
  @JsonKey(name: 'guidance_scale')
  final double? guidanceScale;
  @JsonKey(name: 'negative_prompt')
  final String? negativePrompt;
  @JsonKey(name: 'seed')
  final int? seed;
  // 参考图在非硅基流动中使用时也可能有，所以改为更通用的名称，在构建body时再赋值给特定参数
  @JsonKey(name: 'ref_image')
  final String? refImage;

  /// 阿里云特有参数
  // 通义万相-文生图V2版
  // 必填 model input
  // 选填 parameters
  final AliyunWanxV2Input? input;
  final AliyunWanxV2Parameter? parameters;

  // 阿里云上的Flux
  // 必填 model prompt
  // 可选 size seed steps guidance offload add_sampling_metadata
  @JsonKey(name: 'steps')
  final int? steps;
  @JsonKey(name: 'guidance')
  final int? guidance;
  @JsonKey(name: 'offload')
  final double? offload;
  @JsonKey(name: 'add_sampling_metadata')
  final String? addSamplingMetadata;

  // 智谱平台 cogview
  // 必填 model prompt
  // 可选 size user_id quality(此参数仅支持cogview-4-250304)
  @JsonKey(name: 'user_id')
  final String? userId;
  @JsonKey(name: 'quality')
  final String? quality;

  const ImageGenerationRequest({
    required this.model,
    required this.prompt,
    this.n,
    this.size,
    this.numInferenceSteps,
    this.guidanceScale,
    this.negativePrompt,
    this.seed,
    this.refImage,
    this.input,
    this.parameters,
    this.steps,
    this.guidance,
    this.offload,
    this.addSamplingMetadata,
    this.userId,
    this.quality,
  });

  // 从字符串转
  factory ImageGenerationRequest.fromRawJson(String str) =>
      ImageGenerationRequest.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory ImageGenerationRequest.fromJson(Map<String, dynamic> srcJson) =>
      _$ImageGenerationRequestFromJson(srcJson);

  Map<String, dynamic> toJson() => _$ImageGenerationRequestToJson(this);

  Map<String, dynamic> toRequestBody(ApiPlatform platform) {
    // 基础请求体
    final Map<String, dynamic> base = {'model': model, 'prompt': prompt};

    switch (platform) {
      case ApiPlatform.siliconCloud:
        return {
          ...base,
          if (size != null) 'image_size': size,
          if (n != null) 'batch_size': n,

          // if (numInferenceSteps != null)
          //   'num_inference_steps': numInferenceSteps,
          // if (guidanceScale != null) 'guidance_scale': guidanceScale,

          // 2025-05-14 暂时使用默认，不自定义
          'num_inference_steps': numInferenceSteps ?? 20,
          'guidance_scale': guidanceScale ?? 7.5,
          if (negativePrompt != null) 'negative_prompt': negativePrompt,
          if (seed != null) 'seed': seed,
          if (refImage != null) 'image': refImage,
        };

      case ApiPlatform.aliyun:
        return {
          // 阿里云的输入参数是单独的
          'model': model,
          "input": AliyunWanxV2Input(prompt: prompt).toJson(),
          "parameters":
              AliyunWanxV2Parameter(
                size: size,
                n: n,
                seed: seed,
                promptExtend: true,
                watermark: false,
              ).toJson(),

          if (input != null) 'input': input?.toJson(),
          if (parameters != null) 'parameters': parameters?.toJson(),
          // 但阿里云的flux还是这样一个个传入的
          if (size != null) 'size': size,
          if (seed != null) 'seed': seed,
          if (steps != null) 'steps': steps,
          if (guidance != null) 'guidance': guidance,
          if (offload != null) 'offload': offload,
          if (addSamplingMetadata != null)
            'add_sampling_metadata': addSamplingMetadata,
        };

      case ApiPlatform.zhipu:
        return {
          ...base,
          if (size != null) 'size': size,
          if (quality != null) 'quality': quality,
          if (userId != null) 'user_id': userId,
        };

      default:
        return base;
    }
  }
}

///
/// 2025-02-17 暂时只支持阿里云的通义万相-文生图及其部署的Flux模型
/// 其中通义万相-文生图模型的参数是额外的内容
/// 暂时使用问生图v2版本的输入和参数
/// https://help.aliyun.com/zh/model-studio/developer-reference/text-to-image-v2-api-reference
///
@JsonSerializable(explicitToJson: true)
class AliyunWanxV2Input {
  // 描述画面的提示词信息。支持中英文，长度不超过500个字符，超过部分会自动截断
  @JsonKey(name: 'prompt')
  String? prompt;

  // 画面中不想出现的内容描述词信息。支持中英文，长度不超过500个字符，超过部分会自动截断。
  @JsonKey(name: 'negative_prompt')
  String? negativePrompt;

  AliyunWanxV2Input({required this.prompt, this.negativePrompt});

  // 从字符串转
  factory AliyunWanxV2Input.fromRawJson(String str) =>
      AliyunWanxV2Input.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory AliyunWanxV2Input.fromJson(Map<String, dynamic> srcJson) =>
      _$AliyunWanxV2InputFromJson(srcJson);

  Map<String, dynamic> toFullJson() => _$AliyunWanxV2InputToJson(this);

  // 自定义tojson方法，参数为null的就不加到json中
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    if (prompt != null) json['prompt'] = prompt;
    if (negativePrompt != null) json['negative_prompt'] = negativePrompt;

    return json;
  }
}

@JsonSerializable(explicitToJson: true)
class AliyunWanxV2Parameter {
  // 输出图像的分辨率，默认值是1024*1024。图像宽高边长的像素范围为：[768, 1440]，单位像素。
  @JsonKey(name: 'size')
  String? size;

  // 本次请求生成的图片数量，目前支持1~4张，默认为1。
  @JsonKey(name: 'n')
  int? n;

  // 图片生成时候的种子值，取值范围为(0, 4294967290) 。如果不提供，则算法自动用一个随机生成的数字作为种子，
  //  如果给定了，则根据 batch 数量分别生成 seed，seed+1，seed+2，seed+3为参数的图片。
  @JsonKey(name: 'seed')
  int? seed;

  // 是否开启prompt智能改写。开启后会使用大模型对输入prompt进行智能改写，仅对正向提示词有效。
  // 对于较短的输入prompt生成效果提升明显，但会增加3-4秒耗时。
  @JsonKey(name: 'prompt_extend')
  bool? promptExtend;

  // 是否添加水印标识，水印位于图片右下角，文案为“AI生成”。
  @JsonKey(name: 'watermark')
  bool? watermark;

  AliyunWanxV2Parameter({
    this.size,
    this.n,
    this.seed,
    this.promptExtend,
    this.watermark = false,
  });

  // 从字符串转
  factory AliyunWanxV2Parameter.fromRawJson(String str) =>
      AliyunWanxV2Parameter.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory AliyunWanxV2Parameter.fromJson(Map<String, dynamic> srcJson) =>
      _$AliyunWanxV2ParameterFromJson(srcJson);

  Map<String, dynamic> toFullJson() => _$AliyunWanxV2ParameterToJson(this);

  // 自定义tojson方法，参数为null的就不加到json中
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    if (size != null) json['size'] = size;
    if (n != null) json['n'] = n;
    if (seed != null) json['seed'] = seed;
    if (promptExtend != null) json['prompt_extend'] = promptExtend;
    if (watermark != null) json['watermark'] = watermark;

    return json;
  }
}
