import 'dart:convert';

import '../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../voice_recognition/sense_voice.dart';

/// 本地存储的任务模型，包含阿里云任务信息和本地信息
class VoiceRecognitionTaskInfo {
  final String taskId;
  final String? localAudioPath; // 本地音频文件路径
  final String? githubAudioUrl; // GitHub上的音频URL
  final String? languageHint; // 语言类型
  final String? taskStatus; // 任务状态
  final DateTime? gmtCreate; // 创建时间
  final CusBriefLLMSpec? llmSpec; // 任务模型
  final SenseVoiceJobResp? jobResponse; // 阿里云任务响应
  final SenseVoiceRecogResp? recognitionResponse; // 阿里云识别结果

  VoiceRecognitionTaskInfo({
    required this.taskId,
    this.localAudioPath,
    this.githubAudioUrl,
    this.languageHint,
    this.taskStatus,
    this.gmtCreate,
    this.llmSpec,
    this.jobResponse,
    this.recognitionResponse,
  });

  // 从JSON创建任务
  factory VoiceRecognitionTaskInfo.fromJson(Map<String, dynamic> json) {
    return VoiceRecognitionTaskInfo(
      taskId: json['taskId'],
      localAudioPath: json['localAudioPath'],
      githubAudioUrl: json['githubAudioUrl'],
      languageHint: json['languageHint'],
      taskStatus: json['taskStatus'],
      gmtCreate:
          json['gmtCreate'] != null ? DateTime.parse(json['gmtCreate']) : null,
      llmSpec:
          json['llmSpec'] != null
              ? CusBriefLLMSpec.fromJson(jsonDecode(json['llmSpec']))
              : null,
      jobResponse:
          json['jobResponse'] != null
              ? SenseVoiceJobResp.fromJson(jsonDecode(json['jobResponse']))
              : null,
      recognitionResponse:
          json['recognitionResponse'] != null
              ? SenseVoiceRecogResp.fromJson(
                jsonDecode(json['recognitionResponse']),
              )
              : null,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'localAudioPath': localAudioPath,
      'githubAudioUrl': githubAudioUrl,
      'languageHint': languageHint,
      'taskStatus': taskStatus,
      'gmtCreate': gmtCreate?.toIso8601String(),
      'llmSpec': llmSpec != null ? jsonEncode(llmSpec!.toJson()) : null,
      'jobResponse':
          jobResponse != null ? jsonEncode(jobResponse!.toJson()) : null,
      'recognitionResponse':
          recognitionResponse != null
              ? jsonEncode(recognitionResponse!.toJson())
              : null,
    };
  }

  // 数据库栏位已改为驼峰命名方式,toMap 和 fromMap 主要是数据库操作有用到
  factory VoiceRecognitionTaskInfo.fromMap(Map<String, dynamic> map) {
    return VoiceRecognitionTaskInfo(
      taskId: map['taskId'],
      localAudioPath: map['localAudioPath'],
      githubAudioUrl: map['githubAudioUrl'],
      languageHint: map['languageHint'],
      taskStatus: map['taskStatus'],
      gmtCreate:
          map['gmtCreate'] != null ? DateTime.parse(map['gmtCreate']) : null,
      jobResponse:
          map['jobResponse'] != null
              ? SenseVoiceJobResp.fromJson(jsonDecode(map['jobResponse']))
              : null,
      llmSpec:
          map['llmSpec'] != null
              ? CusBriefLLMSpec.fromJson(jsonDecode(map['llmSpec']))
              : null,
      recognitionResponse:
          map['recognitionResponse'] != null
              ? SenseVoiceRecogResp.fromJson(
                jsonDecode(map['recognitionResponse']),
              )
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'localAudioPath': localAudioPath,
      'githubAudioUrl': githubAudioUrl,
      'languageHint': languageHint,
      'taskStatus': taskStatus,
      'gmtCreate': gmtCreate?.toIso8601String(),
      'llmSpec': llmSpec?.toRawJson(),
      'jobResponse': jobResponse?.toRawJson(),
      'recognitionResponse': recognitionResponse?.toRawJson(),
    };
  }

  // 复制对象并更新部分属性
  VoiceRecognitionTaskInfo copyWith({
    String? taskId,
    String? localAudioPath,
    String? githubAudioUrl,
    String? languageHint,
    String? taskStatus,
    DateTime? gmtCreate,
    CusBriefLLMSpec? llmSpec,
    SenseVoiceJobResp? jobResponse,
    SenseVoiceRecogResp? recognitionResponse,
  }) {
    return VoiceRecognitionTaskInfo(
      taskId: taskId ?? this.taskId,
      localAudioPath: localAudioPath ?? this.localAudioPath,
      githubAudioUrl: githubAudioUrl ?? this.githubAudioUrl,
      languageHint: languageHint ?? this.languageHint,
      taskStatus: taskStatus ?? this.taskStatus,
      gmtCreate: gmtCreate ?? this.gmtCreate,
      llmSpec: llmSpec ?? this.llmSpec,
      jobResponse: jobResponse ?? this.jobResponse,
      recognitionResponse: recognitionResponse ?? this.recognitionResponse,
    );
  }

  // 获取识别文本
  String? get recognizedText {
    if (recognitionResponse?.transcripts != null &&
        recognitionResponse!.transcripts!.isNotEmpty) {
      return recognitionResponse!.transcripts!.first.text;
    }
    return null;
  }

  // 获取错误信息
  String? get errorMessage {
    // 从jobResponse中提取错误信息，如果有的话
    if (jobResponse?.output?.code != null &&
        jobResponse!.output!.code!.isNotEmpty) {
      return '${jobResponse!.output!.code} - ${jobResponse?.output?.message}';
    }
    return null;
  }

  // 获取分段句子列表
  List<SenseVoiceRRTranscriptSentence>? get sentences {
    if (recognitionResponse?.transcripts != null &&
        recognitionResponse!.transcripts!.isNotEmpty) {
      return recognitionResponse!.transcripts!.first.sentences;
    }
    return null;
  }

  // 获取音频文件URL
  String? get audioFileUrl {
    // 优先使用本地路径
    return localAudioPath ?? githubAudioUrl;
  }

  // 获取音频时长（毫秒）
  int? get audioDurationMs {
    if (recognitionResponse?.properties?.originalDurationInMilliseconds !=
        null) {
      return recognitionResponse!.properties!.originalDurationInMilliseconds;
    }
    return null;
  }

  // 获取识别结果URL
  String? get transcriptionUrl {
    if (jobResponse?.output?.results != null &&
        jobResponse!.output!.results!.isNotEmpty) {
      return jobResponse!.output!.results!.first.transcriptionUrl;
    }
    return null;
  }
}
