import 'package:json_annotation/json_annotation.dart';

part 'speech_recognition_response.g.dart';

/// 语音识别响应模型
@JsonSerializable(explicitToJson: true)
class SpeechRecognitionResponse {
  /// 识别的文本内容
  final String text;

  /// 请求ID
  @JsonKey(name: 'request_id')
  final String? requestId;

  /// 任务ID
  @JsonKey(name: 'task_id')
  final String? taskId;

  /// 语言信息
  final String? language;

  /// 分段信息（智谱平台）
  final List<SpeechSegment>? segments;

  /// 创建时间（智谱平台）
  final int? created;

  /// 模型名称
  final String? model;

  /// 元数据
  final Map<String, dynamic>? metadata;

  const SpeechRecognitionResponse({
    required this.text,
    this.requestId,
    this.taskId,
    this.language,
    this.segments,
    this.created,
    this.model,
    this.metadata,
  });

  factory SpeechRecognitionResponse.fromJson(Map<String, dynamic> json) =>
      _$SpeechRecognitionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SpeechRecognitionResponseToJson(this);

  /// 从阿里百炼响应创建(从层层结构中获取text字段)
  factory SpeechRecognitionResponse.fromAliyunResponse(
    Map<String, dynamic> json,
  ) {
    final output = json['output'] as Map<String, dynamic>?;
    final choices = output?['choices'] as List<dynamic>?;
    final firstChoice = choices?.isNotEmpty == true
        ? choices!.first as Map<String, dynamic>
        : null;
    final message = firstChoice?['message'] as Map<String, dynamic>?;
    final content = message?['content'] as List<dynamic>?;
    final textContent = content?.isNotEmpty == true
        ? content!.first as Map<String, dynamic>
        : null;

    // 获取语言信息
    final annotations = message?['annotations'] as List<dynamic>?;
    final audioInfo =
        annotations?.firstWhere(
              (annotation) => annotation['type'] == 'audio_info',
              orElse: () => null,
            )
            as Map<String, dynamic>?;

    return SpeechRecognitionResponse(
      text: textContent?['text'] as String? ?? '',
      requestId: json['request_id'] as String?,
      language: audioInfo?['language'] as String?,
      metadata: {
        'usage': json['usage'],
        'finish_reason': firstChoice?['finish_reason'],
        'annotations': annotations,
      },
    );
  }

  /// 从硅基流动响应创建(只有text一个字段)
  factory SpeechRecognitionResponse.fromSiliconCloudResponse(
    Map<String, dynamic> json,
  ) {
    return SpeechRecognitionResponse(
      text: json['text'] as String? ?? '',
      metadata: json,
    );
  }

  /// 从智谱响应创建(包含分段信息，但也可以直接读取text字段)
  factory SpeechRecognitionResponse.fromZhipuResponse(
    Map<String, dynamic> json,
  ) {
    final segments = (json['segments'] as List<dynamic>?)
        ?.map(
          (segment) => SpeechSegment.fromJson(segment as Map<String, dynamic>),
        )
        .toList();

    return SpeechRecognitionResponse(
      text: json['text'] as String? ?? '',
      requestId: json['request_id'] as String?,
      taskId: json['id'] as String?,
      created: json['created'] as int?,
      model: json['model'] as String?,
      segments: segments,
      metadata: json,
    );
  }

  /// 复制并修改参数
  SpeechRecognitionResponse copyWith({
    String? text,
    String? requestId,
    String? taskId,
    String? language,
    List<SpeechSegment>? segments,
    int? created,
    String? model,
    Map<String, dynamic>? metadata,
  }) {
    return SpeechRecognitionResponse(
      text: text ?? this.text,
      requestId: requestId ?? this.requestId,
      taskId: taskId ?? this.taskId,
      language: language ?? this.language,
      segments: segments ?? this.segments,
      created: created ?? this.created,
      model: model ?? this.model,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// 语音分段信息（智谱平台）
@JsonSerializable(explicitToJson: true)
class SpeechSegment {
  /// 分段ID
  final int id;

  /// 开始时间（秒）
  final double start;

  /// 结束时间（秒）
  final double end;

  /// 分段文本
  final String text;

  const SpeechSegment({
    required this.id,
    required this.start,
    required this.end,
    required this.text,
  });

  factory SpeechSegment.fromJson(Map<String, dynamic> json) =>
      _$SpeechSegmentFromJson(json);

  Map<String, dynamic> toJson() => _$SpeechSegmentToJson(this);

  /// 复制并修改参数
  SpeechSegment copyWith({int? id, double? start, double? end, String? text}) {
    return SpeechSegment(
      id: id ?? this.id,
      start: start ?? this.start,
      end: end ?? this.end,
      text: text ?? this.text,
    );
  }
}
