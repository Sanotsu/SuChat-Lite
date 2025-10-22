import 'dart:convert';
import 'dart:io';

import 'package:json_annotation/json_annotation.dart';

import '../../../../core/utils/datetime_formatter.dart';
import '../../../../core/utils/get_dir.dart';

part 'speech_synthesis_response.g.dart';

/// 语音合成响应模型
@JsonSerializable(explicitToJson: true)
class SpeechSynthesisResponse {
  final String? audioUrl;
  final String? audioBase64;
  final String? format;
  final int? duration;
  final String? taskId;
  final String? requestId;
  final Map<String, dynamic>? metadata;

  const SpeechSynthesisResponse({
    this.audioUrl,
    this.audioBase64,
    this.format,
    this.duration,
    this.taskId,
    this.requestId,
    this.metadata,
  });

  factory SpeechSynthesisResponse.fromJson(Map<String, dynamic> json) =>
      _$SpeechSynthesisResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SpeechSynthesisResponseToJson(this);

  /// 从阿里百炼响应格式创建
  factory SpeechSynthesisResponse.fromAliyunResponse(
    Map<String, dynamic> json,
  ) {
    final output = json['output'] as Map<String, dynamic>?;
    final audio = output?['audio'] as Map<String, dynamic>?;

    return SpeechSynthesisResponse(
      audioUrl: audio?['url'] as String?,
      taskId: audio?['id'] as String?,
      requestId: json['request_id'] as String?,
      metadata: {
        'usage': json['usage'],
        'request_id': json['request_id'],
        'audio_id': audio?['id'],
        'expires_at': audio?['expires_at'],
      },
    );
  }

  /// 从二进制数据创建响应（用于直接返回音频数据的API, 保存二进制音频数据到文件并返回路径）
  static Future<SpeechSynthesisResponse> fromBinaryData(
    List<int> audioBytes, {
    String format = 'mp3',
    String source = 'siliconCloud',
  }) async {
    try {
      // 1. 保存文件到本地
      final filePath = await _saveAudioToFile(audioBytes, format);

      // 2. 可选：如果需要Base64，使用dart内置方法
      final audioBase64 = base64Encode(audioBytes);

      return SpeechSynthesisResponse(
        audioUrl: filePath, // 文件路径
        audioBase64: audioBase64, // 如果需要Base64
        format: format,
        metadata: {
          'source': source,
          'format': format,
          'fileSize': audioBytes.length,
          'savedPath': filePath,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 保存音频数据到文件
  static Future<String> _saveAudioToFile(
    List<int> audioBytes,
    String format, {
    String? source = 'siliconCloud',
  }) async {
    // 获取应用文档目录
    final directory = await getUnifiedChatMediaDir();
    final audioDir = Directory('${directory.path}/audio');

    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    // 生成唯一文件名
    final timestamp = fileTs(DateTime.now(), isS: true);
    final fileName = 'tts_${source}_$timestamp.$format';
    final filePath = '${audioDir.path}/$fileName';

    // 写入文件
    final file = File(filePath);
    await file.writeAsBytes(audioBytes, flush: true);

    return filePath;
  }

  /// 获取音频数据（优先返回URL，其次返回Base64）
  String? get audioData => audioUrl ?? audioBase64;

  /// 是否有音频数据
  bool get hasAudio => audioUrl != null || audioBase64 != null;

  @override
  String toString() {
    return 'SpeechSynthesisResponse(hasAudio: $hasAudio, format: $format)';
  }
}
