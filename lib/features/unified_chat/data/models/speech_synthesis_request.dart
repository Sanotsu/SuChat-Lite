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
  /// 2026-10-14 FIX：Qwen-Audio-TTS系列(qwen-audio-*-tts*)与Qwen-TTS
  /// 协议不同(官方文档 https://help.aliyun.com/zh/model-studio/qwen-audio-tts-http-api)：
  ///   1. 端点为 /api/v1/services/audio/tts/SpeechSynthesizer(平台规格已更新)
  ///   2. input为 {text, voice(必选), format, sample_rate}，无language_type
  ///   3. 音色体系不同：系统音色如longanhuan_v3.6(Cherry是Qwen-TTS音色)
  /// Qwen-TTS(qwen-tts系列)仍走multimodal-generation，input为
  /// {text, voice, language_type}
  Map<String, dynamic> toAliyunFormat() {
    final Map<String, dynamic> data = {'model': model};

    if (model.startsWith('qwen-audio-')) {
      data['input'] = {
        'text': input,
        // 音色必须属于当前模型的音色列表，不能跨模型混用——混用报
        // InvalidParameter [cosyvoice:]Engine error [411]
        // (音色列表: help.aliyun.com/zh/model-studio/qwen-audio-tts-voice-list)
        'voice': voice ?? _defaultAliyunAudioTtsVoice(),
        // 默认22050/mp3，显式指定24kHz wav与本地落盘格式一致
        'format': 'wav',
        'sample_rate': 24000,
      };
    } else {
      data['input'] = {
        'text': input,
        'voice': voice ?? 'Cherry',
        'language_type': languageType ?? 'Auto',
      };
    }

    if (stream != null) {
      data['stream'] = stream;
    }

    return data;
  }

  /// Qwen-Audio-TTS各模型的默认音色(音色列表各模型独立，不可混用)：
  /// 3.1系为_v3.1后缀；3.0-plus为无后缀音色；3.0-flash为_v3.6后缀
  String _defaultAliyunAudioTtsVoice() {
    if (model.contains('3.1')) return 'longanhuan_v3.1';
    if (model.contains('plus')) return 'longanlingxin';
    return 'longanhuan_v3.6';
  }

  /// 转换为硅基流动API格式
  Map<String, dynamic> toSiliconCloudFormat() {
    final Map<String, dynamic> data = {'model': model, 'input': input};

    if (voice != null) {
      // data['voice'] = voice;
      // 2025-10-14  IndexTeam/IndexTTS-2 模型没有文档，从体验中心看到的几个参数
      // 音色不是model+人名
      if (model == 'IndexTeam/IndexTTS-2') {
        data['voice'] = 'fishaudio/fish-speech-1.4:$voice';
      } else {
        data['voice'] = '$model:$voice';
      }
    } else {
      // 2025-10-14  IndexTeam/IndexTTS-2 模型没有文档，从体验中心看到的几个参数
      // 音色不是model+人名
      if (model == 'IndexTeam/IndexTTS-2') {
        data['voice'] = 'fishaudio/fish-speech-1.4:diana';
      } else {
        data['voice'] = '$model:diana';
      }
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

  /// 转换为小米MiMo API格式(2026-09-10 chat completions风格，不走audio端点)
  /// 要合成的文本放在assistant消息中，音色/格式放在audio对象；
  /// 仅mimo-v2.5-tts-voicedesign需要user消息(音色描述)，内置tts模型不需要
  Map<String, dynamic> toMimoFormat() {
    return {
      'model': model,
      'messages': [
        {'role': 'assistant', 'content': input},
      ],
      'audio': {
        // 内置音色，默认mimo_default；支持：冰糖/茉莉/苏打/白桦/Mia/Chloe/Milo/Dean
        'voice': voice ?? 'mimo_default',
        // 仅支持wav/mp3/pcm/pcm16，默认wav
        'format': responseFormat ?? 'wav',
      },
      'stream': stream ?? false,
    };
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
