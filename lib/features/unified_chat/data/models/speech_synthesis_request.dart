import 'package:json_annotation/json_annotation.dart';

part 'speech_synthesis_request.g.dart';

/// 语音合成请求模型
@JsonSerializable(explicitToJson: true)
class SpeechSynthesisRequest {
  // 都有的
  final String model;
  final String input;
  final String? voice;

  // 阿里和硅基流动
  final bool? stream;

  // 智谱和硅基流动
  @JsonKey(name: 'response_format')
  final String? responseFormat;
  final double? speed;

  // 阿里百炼用
  @JsonKey(name: 'language_type')
  final String? languageType;

  // 智谱
  final double? volume;
  @JsonKey(name: 'encode_format')
  final String? encodeFormat;
  final bool? watermark;

  // 硅基流动
  // 音频增益，单位dB，可以控制音频声音大小，float类型，默认值是0.0，可选范围是[-10,10]；
  final double? gain;

  /// 阿里百炼qwen-tts的请求参数
  // model input(text voice language_type) stream

  /// 智谱tts的请求参数
  // model input voice speed volume encode_format response_format watermark_enabled

  /// 硅基流动tts的请求参数(只使用几个通用的)
  /// 【暂未使用的 [max_tokens(MOSS-TTSD-v0.5独有，暂不用)] references sample_rate(不同格式不同，默认就好)】
  // model input voice response_format stream speed gain

  const SpeechSynthesisRequest({
    required this.model,
    required this.input,
    this.voice,
    this.responseFormat,
    this.speed,
    this.volume,
    this.languageType,
    this.stream,
    this.watermark,
    this.encodeFormat,
    this.gain,
  });

  factory SpeechSynthesisRequest.fromJson(Map<String, dynamic> json) =>
      _$SpeechSynthesisRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SpeechSynthesisRequestToJson(this);

  /// 转换为阿里百炼API格式
  Map<String, dynamic> toAliyunFormat() {
    final Map<String, dynamic> inputData = {
      'text': input,
      'voice': voice ?? 'Cherry',
      'language_type': languageType ?? 'Auto',
    };

    final Map<String, dynamic> data = {'model': model, 'input': inputData};

    if (stream != null) {
      data['stream'] = stream;
    }

    return data;
  }

  /// 转换为硅基流动API格式
  Map<String, dynamic> toSiliconCloudFormat() {
    final Map<String, dynamic> data = {'model': model, 'input': input};

    if (voice != null) {
      data['voice'] = voice;
    } else {
      // 没传需要手动指定一个默认的
      data['voice'] = '$model:diana';
    }

    if (responseFormat != null) {
      data['response_format'] = responseFormat;
    } else {
      data['response_format'] = 'mp3';
    }

    if (speed != null) {
      data['speed'] = speed;
    }

    if (gain != null) {
      data['gain'] = gain;
    }

    if (stream != null) {
      data['stream'] = stream;
    }

    return data;
  }

  /// 转换为智谱API格式
  Map<String, dynamic> toZhipuFormat() {
    final Map<String, dynamic> data = {
      'model': model,
      'input': input,
      'voice': voice ?? 'tongtong',
      'response_format': responseFormat ?? 'pcm',
    };

    if (speed != null) {
      data['speed'] = speed;
    }

    if (volume != null) {
      data['volume'] = volume;
    }

    if (watermark != null) {
      data['watermark_enabled'] = watermark;
    }

    if (encodeFormat != null) {
      data['encode_format'] = encodeFormat;
    }

    return data;
  }

  SpeechSynthesisRequest copyWith({
    String? model,
    String? input,
    String? voice,
    String? responseFormat,
    double? speed,
    double? volume,
    String? languageType,
    bool? stream,
    bool? watermark,
    String? encodeFormat,
    double? gain,
  }) {
    return SpeechSynthesisRequest(
      model: model ?? this.model,
      input: input ?? this.input,
      voice: voice ?? this.voice,
      responseFormat: responseFormat ?? this.responseFormat,
      speed: speed ?? this.speed,
      volume: volume ?? this.volume,
      languageType: languageType ?? this.languageType,
      stream: stream ?? this.stream,
      watermark: watermark ?? this.watermark,
      encodeFormat: encodeFormat ?? this.encodeFormat,
      gain: gain ?? this.gain,
    );
  }

  @override
  String toString() {
    return 'SpeechSynthesisRequest(model: $model, input: $input)';
  }
}
