import 'package:json_annotation/json_annotation.dart';

import '../../../../core/utils/simple_tools.dart';
import 'unified_model_spec.dart';

part 'image_generation_request.g.dart';

/// 图片生成请求模型
@JsonSerializable(explicitToJson: true)
class ImageGenerationRequest {
  final String model;
  final String prompt;
  final String? negativePrompt;
  final String? size;
  final int? n;
  final int? seed;
  final int? steps;
  final double? guidanceScale;
  final double? cfg;
  final String? quality;
  final String? style;
  final String? image; // base64 or url for image-to-image
  final String? maskImage; // for image editing
  final bool? watermark;
  final String? userId;

  /// 火山方舟的 doubao-seedream-4.0 支持
  // 是否关闭组图功能 auto(自动判断) disabled(默认)
  final String? sequentialImageGeneration;
  final dynamic sequentialImageGenerationOptions;
  // 返回图片格式:url(默认)、b64_json
  final String? responseFormat;

  const ImageGenerationRequest({
    required this.model,
    required this.prompt,
    this.negativePrompt,
    this.size,
    this.n,
    this.seed,
    this.steps,
    this.guidanceScale,
    this.cfg,
    this.quality,
    this.style,
    this.image,
    this.maskImage,
    this.watermark = false,
    this.userId,
    this.sequentialImageGeneration,
    this.sequentialImageGenerationOptions,
    this.responseFormat,
  });

  factory ImageGenerationRequest.fromJson(Map<String, dynamic> json) =>
      _$ImageGenerationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ImageGenerationRequestToJson(this);

  /// 转换为阿里百炼API格式(同步，结果在响应中)
  Map<String, dynamic> _toAliyunSyncFormat() {
    // input 是必填的
    final Map<String, dynamic> input = {
      // 目前仅支持单轮对话，即传入一组role、content参数
      'messages': [
        {
          // 消息的角色。此参数必须设置为user。
          "role": "user",
          // 消息的内容，包括图像与提示词。注意：content只能包含一个text。
          "content": [
            // 正向提示词，仅支持传入一个text，不超过800字符(自动截断)。
            {'text': prompt},
            // 需要编辑的图片或参考图，需要公网在线url或base64
            if (image != null) {'image': convertToBase64(image!)},
          ],
        },
      ],
    };

    // parameters 是可选的
    final Map<String, dynamic> parameters = {};

    if (negativePrompt != null) {
      parameters['negative_prompt'] = negativePrompt;
    }

    if (size != null) {
      parameters['size'] = '1328*1328';
    }

    // 2025-10-08 qwen-image 暂时只支持1张，其他参数会报错
    if (n != null) {
      parameters['n'] = 1;
    }

    if (seed != null) {
      parameters['seed'] = seed;
    }

    // 两个qwen-image独有的
    // 是否开启prompt智能改写。
    parameters['prompt_extend '] = false;

    // 是否添加水印标识，水印位于图片右下角，文案为“Qwen-Image生成”。
    if (watermark != null) {
      parameters['watermark'] = watermark;
    }

    return {'model': model, 'input': input, 'parameters': parameters};
  }

  /// 转换为阿里百炼API格式(异步，需要轮询得到结果)
  Map<String, dynamic> _toAliyunAsyncFormat() {
    // input 是必填的
    final Map<String, dynamic> input = {'prompt': prompt};

    // 文生图V2有的
    if (negativePrompt != null) {
      input['negative_prompt'] = negativePrompt;
    }

    // 通用图像编辑2.5还有的(图像编辑2.1不考虑了)
    if (image != null) {
      // 暂时只处理单张图片的编辑或参考图
      input['images'] = [convertToBase64(image!)];
    }
    if (maskImage != null) {
      // 暂时只处理单张图片的编辑或参考图
      input['images'] = [convertToBase64(maskImage!)];
    }

    /// parameters 是可选的
    final Map<String, dynamic> parameters = {};

    // 都有的
    if (size != null) {
      parameters['size'] = size;
    }

    if (seed != null) {
      parameters['seed'] = seed;
    }

    // 这几个flux有的
    if (steps != null) {
      parameters['steps'] = steps;
    }

    if (guidanceScale != null) {
      parameters['guidance'] = guidanceScale;
    }

    // 这几个文生图V2有的
    // 1~4,默认4张
    if (n != null) {
      parameters['n'] = n;
    }

    // 是否开启prompt智能改写。
    parameters['prompt_extend '] = false;

    // 是否添加水印标识，水印位于图片右下角，文案为“AI生成”。
    if (watermark != null) {
      parameters['watermark'] = watermark;
    }

    return {'model': model, 'input': input, 'parameters': parameters};
  }

  /// 转换为阿里百炼API格式
  Map<String, dynamic> toAliyunFormat(UnifiedModelSpec model) {
    if (model.modelName.contains('qwen-image')) {
      return _toAliyunSyncFormat();
    } else {
      return _toAliyunAsyncFormat();
    }
  }

  /// 转换为硅基流动API格式
  Map<String, dynamic> toSiliconCloudFormat() {
    final Map<String, dynamic> data = {'model': model, 'prompt': prompt};

    if (negativePrompt != null) {
      data['negative_prompt'] = negativePrompt;
    }

    // 尺寸参数稍微不一样(Qwen-Image-Edit不支持此栏位)
    if (size != null) {
      data['image_size'] = size;
    }

    if (n != null) {
      data['batch_size'] = n;
    }

    if (seed != null) {
      data['seed'] = seed;
    }

    if (steps != null) {
      data['num_inference_steps'] = steps;
    }

    if (guidanceScale != null) {
      data['guidance_scale'] = guidanceScale;
    }

    if (cfg != null) {
      data['cfg'] = cfg;
    }

    if (image != null) {
      data['image'] = convertToBase64(image!);
    }

    // 用于上传原始视频的图片可以是base64格式或URL
    // 此字段仅适用于Qwen/Qwen-Image-Edit-2509
    if (maskImage != null) {
      data['image2'] = convertToBase64(maskImage!);
    }

    return data;
  }

  /// 转换为智谱API格式
  Map<String, dynamic> toZhipuFormat() {
    final Map<String, dynamic> data = {'model': model, 'prompt': prompt};

    if (size != null) {
      data['size'] = size;
    }

    if (quality != null) {
      data['quality'] = quality;
    }

    if (watermark != null) {
      // true: 默认启用AI生成的显式水印及隐式数字水印，符合政策要求。
      // false: 关闭所有水印，仅允许已签署免责声明的客户使用，签署路径：个人中心-安全管理-去水印管理
      data['watermark_enabled'] = watermark;
    }

    if (userId != null) {
      data['user_id'] = userId;
    }

    return data;
  }

  /// 转换为火山方舟API格式(组图的不开启)
  Map<String, dynamic> toVolcengineFormat() {
    final Map<String, dynamic> data = {'model': model, 'prompt': prompt};

    if (image != null) {
      data['image'] = convertToBase64(image!);
    }

    if (size != null) {
      data['size'] = size;
    }

    // doubao-seedream-3.0-t2i 默认值 2.5doubao-seededit-3.0-i2i 默认值 5.5doubao-seedream-4.0 不支持
    if (guidanceScale != null) {
      data['guidance_scale'] = guidanceScale;
    }

    if (watermark != null) {
      data['watermark'] = watermark;
    }

    // 默认就是24小时有效的url，不需要改变
    if (responseFormat != null) {
      data['response_format'] = responseFormat;
    }

    return data;
  }

  ImageGenerationRequest copyWith({
    String? model,
    String? prompt,
    String? negativePrompt,
    String? size,
    int? n,
    int? seed,
    int? steps,
    double? guidanceScale,
    double? cfg,
    String? quality,
    String? style,
    String? image,
    String? maskImage,
    bool? watermark,
    String? userId,
  }) {
    return ImageGenerationRequest(
      model: model ?? this.model,
      prompt: prompt ?? this.prompt,
      negativePrompt: negativePrompt ?? this.negativePrompt,
      size: size ?? this.size,
      n: n ?? this.n,
      seed: seed ?? this.seed,
      steps: steps ?? this.steps,
      guidanceScale: guidanceScale ?? this.guidanceScale,
      cfg: cfg ?? this.cfg,
      quality: quality ?? this.quality,
      style: style ?? this.style,
      image: image ?? this.image,
      maskImage: maskImage ?? this.maskImage,
      watermark: watermark ?? this.watermark,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() {
    return 'ImageGenerationRequest(model: $model, prompt: $prompt)';
  }
}
