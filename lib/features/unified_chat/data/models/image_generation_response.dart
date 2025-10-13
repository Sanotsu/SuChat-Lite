import 'package:json_annotation/json_annotation.dart';

part 'image_generation_response.g.dart';

/// 图片生成响应模型
@JsonSerializable(explicitToJson: true)
class ImageGenerationResponse {
  final int? created;
  final List<GeneratedImage> data;
  final Map<String, dynamic>? timings;
  final int? seed;
  final List<ContentFilter>? contentFilter;
  final String? requestId;

  /// 元数据
  final Map<String, dynamic>? metadata;

  const ImageGenerationResponse({
    this.created,
    required this.data,
    this.timings,
    this.seed,
    this.contentFilter,
    this.requestId,
    this.metadata,
  });

  factory ImageGenerationResponse.fromJson(Map<String, dynamic> json) =>
      _$ImageGenerationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ImageGenerationResponseToJson(this);

  /// 从阿里百炼响应格式创建(同步响应)
  /// https://bailian.console.aliyun.com/?switchAgent=10147514&productCode=p_efm&switchUserType=3&tab=api#/api/?type=model&url=2975126
  factory ImageGenerationResponse.fromAliyunSyncResponse(
    Map<String, dynamic> json,
  ) {
    final output = json['output'] as Map<String, dynamic>?;
    final choices = output?['choices'] as List<dynamic>? ?? [];

    final images = choices.map((choice) {
      final choiceMap = choice as Map<String, dynamic>;

      String? url = choiceMap['message']?['content']?[0]['image'];

      return GeneratedImage(url: url, b64Json: null);
    }).toList();

    return ImageGenerationResponse(
      data: images,
      requestId: json['request_id'] as String?,
      metadata: json,
    );
  }

  /// 从阿里百炼响应格式创建(异步响应)
  factory ImageGenerationResponse.fromAliyunAsyncResponse(
    Map<String, dynamic> json,
  ) {
    final output = json['output'] as Map<String, dynamic>?;
    final results = output?['results'] as List<dynamic>? ?? [];

    final images = results.map((result) {
      final resultMap = result as Map<String, dynamic>;

      String? url = resultMap['url'];

      return GeneratedImage(url: url, b64Json: null);
    }).toList();

    return ImageGenerationResponse(
      data: images,
      requestId: json['request_id'] as String?,
      metadata: json,
    );
  }

  /// 从硅基流动响应格式创建
  /// https://docs.siliconflow.cn/cn/api-reference/images/images-generations
  factory ImageGenerationResponse.fromSiliconCloudResponse(
    Map<String, dynamic> json,
  ) {
    final images = json['images'] as List<dynamic>? ?? [];

    final generatedImages = images.map((image) {
      final imageMap = image as Map<String, dynamic>;
      return GeneratedImage(url: imageMap['url'] as String, b64Json: null);
    }).toList();

    return ImageGenerationResponse(
      data: generatedImages,
      timings: json['timings'] as Map<String, dynamic>?,
      seed: json['seed'] as int?,
      metadata: json,
    );
  }

  /// 从智谱响应格式创建
  /// https://docs.bigmodel.cn/api-reference/%E6%A8%A1%E5%9E%8B-api/%E5%9B%BE%E5%83%8F%E7%94%9F%E6%88%90
  factory ImageGenerationResponse.fromZhipuResponse(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? [];

    final images = data.map((item) {
      final itemMap = item as Map<String, dynamic>;
      return GeneratedImage(url: itemMap['url'] as String, b64Json: null);
    }).toList();

    final contentFilterList = json['content_filter'] as List<dynamic>?;
    List<ContentFilter>? filters;
    if (contentFilterList != null) {
      filters = contentFilterList.map((filter) {
        final filterMap = filter as Map<String, dynamic>;
        return ContentFilter(
          role: filterMap['role'] as String,
          level: filterMap['level'] as int,
        );
      }).toList();
    }

    return ImageGenerationResponse(
      created: json['created'] as int?,
      data: images,
      contentFilter: filters,
      metadata: json,
    );
  }

  /// 从火山方舟响应格式创建
  /// https://www.volcengine.com/docs/82379/1541523
  factory ImageGenerationResponse.fromVolcengineResponse(
    Map<String, dynamic> json,
  ) {
    final images = json['data'] as List<dynamic>? ?? [];

    final generatedImages = images.map((image) {
      final imageMap = image as Map<String, dynamic>;
      return GeneratedImage(url: imageMap['url'] as String, b64Json: null);
    }).toList();

    return ImageGenerationResponse(
      created: json['created'] as int?,
      data: generatedImages,
      metadata: {'usage': json['usage'], 'model': json['model']},
    );
  }

  @override
  String toString() {
    return 'ImageGenerationResponse(data: ${data.length} images)';
  }
}

/// 生成的图片模型
@JsonSerializable(explicitToJson: true)
class GeneratedImage {
  final String? url;
  @JsonKey(name: 'b64_json')
  final String? b64Json;

  const GeneratedImage({this.url, this.b64Json});

  factory GeneratedImage.fromJson(Map<String, dynamic> json) =>
      _$GeneratedImageFromJson(json);

  Map<String, dynamic> toJson() => _$GeneratedImageToJson(this);

  @override
  String toString() {
    return 'GeneratedImage(url: $url, hasB64: ${b64Json != null})';
  }
}

/// 内容过滤器模型
@JsonSerializable(explicitToJson: true)
class ContentFilter {
  final String role;
  final int level;

  const ContentFilter({required this.role, required this.level});

  factory ContentFilter.fromJson(Map<String, dynamic> json) =>
      _$ContentFilterFromJson(json);

  Map<String, dynamic> toJson() => _$ContentFilterToJson(this);

  @override
  String toString() {
    return 'ContentFilter(role: $role, level: $level)';
  }
}
