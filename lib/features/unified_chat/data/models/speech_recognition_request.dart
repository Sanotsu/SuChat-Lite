import 'dart:io';
import 'package:json_annotation/json_annotation.dart';

part 'speech_recognition_request.g.dart';

/// 语音识别请求模型
@JsonSerializable(explicitToJson: true)
class SpeechRecognitionRequest {
  /// 音频文件路径（本地文件）
  final String? audioPath;

  /// 音频文件URL（在线文件）
  final String? audioUrl;

  /// 模型名称
  final String model;

  /// 语言代码（可选）
  final String? language;

  /// 采样温度（智谱平台）
  final double? temperature;

  /// 是否启用流式输出
  final bool? stream;

  /// 是否启用语言识别（阿里百炼）
  @JsonKey(name: 'enable_lid')
  final bool? enableLid;

  /// 是否启用逆文本规范化（阿里百炼）
  @JsonKey(name: 'enable_itn')
  final bool? enableItn;

  /// 上下文文本（阿里百炼）
  final String? context;

  /// 请求ID（智谱平台）
  @JsonKey(name: 'request_id')
  final String? requestId;

  /// 用户ID（智谱平台）
  @JsonKey(name: 'user_id')
  final String? userId;

  /// 阿里百炼的 Qwen3-ASR 需要的参数
  /// 2025-10-10 (具体没找到文档，就看到示例的代码有少量，那就只用这些必要的参数)
  // model  input parameters

  /// 硅基流动需要的参数
  // file model

  /// 智谱的 glm-asr 需要的参数
  //  file (wav mp3格式，小于25M，短于60秒) model temperature([0,1]) stream request_id user_id

  const SpeechRecognitionRequest({
    required this.model,
    this.audioPath,
    this.audioUrl,
    this.language,
    this.temperature,
    this.stream,
    this.enableLid,
    this.enableItn,
    this.context,
    this.requestId,
    this.userId,
  });

  factory SpeechRecognitionRequest.fromJson(Map<String, dynamic> json) =>
      _$SpeechRecognitionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SpeechRecognitionRequestToJson(this);

  /// 转换为阿里百炼API格式（DashScope 方式，不是openAI API兼容的接口）
  Map<String, dynamic> toAliyunFormat({String? audioUrl}) {
    // qwen3-asr 请求参数可参考通用文档 https://help.aliyun.com/zh/model-studio/use-qwen-by-calling-api
    // messages 要放在input 对象中
    final messages = [
      {
        "role": "system",
        "content": [
          {"text": context ?? ""},
        ],
      },
      {
        "role": "user",
        "content": [
          // 这个只能是可公开访问的网络地址，而不是本地文件路径或base64
          {"audio": audioUrl ?? audioPath},
        ],
      },
    ];

    // asr_options 要放在 parameters 对象中
    final asrOptions = <String, dynamic>{};
    if (language != null) asrOptions['language'] = language;
    if (enableLid != null) asrOptions['enable_lid'] = enableLid;
    if (enableItn != null) asrOptions['enable_itn'] = enableItn;

    return {
      'model': model,
      'input': {'messages': messages},
      // 2025-10-11 构建参数方式是对的，但暂时不启用，就全部默认不自定
      'parameters': {if (asrOptions.isNotEmpty) 'asr_options': asrOptions},
    };
  }

  /// 转换为硅基流动API格式（FormData，文件在外面处理）
  Map<String, dynamic> toSiliconCloudFormData() {
    return {'model': model};
  }

  /// 转换为智谱API格式（FormData，文件在外面处理）
  Map<String, dynamic> toZhipuFormData() {
    return {
      'model': model,
      if (temperature != null) 'temperature': temperature,
      if (stream != null) 'stream': stream,
      if (requestId != null) 'request_id': requestId,
      if (userId != null) 'user_id': userId,
    };
  }

  /// 获取音频文件
  File? getAudioFile() {
    if (audioPath != null) {
      return File(audioPath!);
    }
    return null;
  }

  /// 复制并修改参数
  SpeechRecognitionRequest copyWith({
    String? audioPath,
    String? audioUrl,
    String? model,
    String? language,
    double? temperature,
    bool? stream,
    bool? enableLid,
    bool? enableItn,
    String? context,
    String? requestId,
    String? userId,
  }) {
    return SpeechRecognitionRequest(
      audioPath: audioPath ?? this.audioPath,
      audioUrl: audioUrl ?? this.audioUrl,
      model: model ?? this.model,
      language: language ?? this.language,
      temperature: temperature ?? this.temperature,
      stream: stream ?? this.stream,
      enableLid: enableLid ?? this.enableLid,
      enableItn: enableItn ?? this.enableItn,
      context: context ?? this.context,
      requestId: requestId ?? this.requestId,
      userId: userId ?? this.userId,
    );
  }
}
