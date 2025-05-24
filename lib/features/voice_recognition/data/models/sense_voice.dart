// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'sense_voice.g.dart';

// sensevoice 查询任务结果和录音文件识别结果
// 提交任务的响应比较简单，是SenseVoiceJobResp的一部分属性

///
/// 阿里云sensevoice识别提交任务的结果
/// https://help.aliyun.com/zh/model-studio/developer-reference/sensevoice-recorded-speech-recognition-restful-api#c39d0f9988uc2
///
/// 提交任务和查询任务的响应
@JsonSerializable(explicitToJson: true)
class SenseVoiceJobResp {
  @JsonKey(name: 'request_id')
  String? requestId;

  @JsonKey(name: 'output')
  SenseVoiceJROutput? output;

  @JsonKey(name: 'usage')
  SenseVoiceJRUsage? usage;

  SenseVoiceJobResp(this.requestId, this.output, this.usage);

  // 从字符串转
  factory SenseVoiceJobResp.fromRawJson(String str) =>
      SenseVoiceJobResp.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory SenseVoiceJobResp.fromJson(Map<String, dynamic> srcJson) =>
      _$SenseVoiceJobRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$SenseVoiceJobRespToJson(this);
}

// 缩写 SenseVoiceJobResp => SenseVoiceJR
@JsonSerializable(explicitToJson: true)
class SenseVoiceJROutput {
  @JsonKey(name: 'task_id')
  String taskId;

  @JsonKey(name: 'task_status')
  String taskStatus;

  @JsonKey(name: 'submit_time')
  String? submitTime;

  @JsonKey(name: 'scheduled_time')
  String? scheduledTime;

  @JsonKey(name: 'end_time')
  String? endTime;

  @JsonKey(name: 'results')
  List<SenseVoiceJROutputResult>? results;

  @JsonKey(name: 'task_metrics')
  SenseVoiceJROutputTaskMetric? taskMetrics;

  // 失败了还有其他栏位
  @JsonKey(name: 'code')
  String? code;

  @JsonKey(name: 'message')
  String? message;

  SenseVoiceJROutput(
    this.taskId,
    this.taskStatus,
    this.submitTime,
    this.scheduledTime,
    this.endTime,
    this.results,
    this.taskMetrics,
    this.code,
    this.message,
  );

  // 从字符串转
  factory SenseVoiceJROutput.fromRawJson(String str) =>
      SenseVoiceJROutput.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory SenseVoiceJROutput.fromJson(Map<String, dynamic> srcJson) =>
      _$SenseVoiceJROutputFromJson(srcJson);

  Map<String, dynamic> toJson() => _$SenseVoiceJROutputToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SenseVoiceJROutputResult {
  @JsonKey(name: 'file_url')
  String fileUrl;

  @JsonKey(name: 'subtask_status')
  String subtaskStatus;

  // 识别成功了才有翻译url栏位
  @JsonKey(name: 'transcription_url')
  String? transcriptionUrl;

  // 失败了则是code和message
  @JsonKey(name: 'code')
  String? code;

  @JsonKey(name: 'message')
  String? message;

  SenseVoiceJROutputResult(
    this.fileUrl,
    this.transcriptionUrl,
    this.subtaskStatus,
    this.code,
    this.message,
  );

  // 从字符串转
  factory SenseVoiceJROutputResult.fromRawJson(String str) =>
      SenseVoiceJROutputResult.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory SenseVoiceJROutputResult.fromJson(Map<String, dynamic> srcJson) =>
      _$SenseVoiceJROutputResultFromJson(srcJson);

  Map<String, dynamic> toJson() => _$SenseVoiceJROutputResultToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SenseVoiceJROutputTaskMetric {
  @JsonKey(name: 'TOTAL')
  int TOTAL;

  @JsonKey(name: 'SUCCEEDED')
  int SUCCEEDED;

  @JsonKey(name: 'FAILED')
  int FAILED;

  SenseVoiceJROutputTaskMetric(this.TOTAL, this.SUCCEEDED, this.FAILED);

  // 从字符串转
  factory SenseVoiceJROutputTaskMetric.fromRawJson(String str) =>
      SenseVoiceJROutputTaskMetric.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory SenseVoiceJROutputTaskMetric.fromJson(Map<String, dynamic> srcJson) =>
      _$SenseVoiceJROutputTaskMetricFromJson(srcJson);

  Map<String, dynamic> toJson() => _$SenseVoiceJROutputTaskMetricToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SenseVoiceJRUsage {
  @JsonKey(name: 'duration')
  int duration;

  SenseVoiceJRUsage(this.duration);

  // 从字符串转
  factory SenseVoiceJRUsage.fromRawJson(String str) =>
      SenseVoiceJRUsage.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory SenseVoiceJRUsage.fromJson(Map<String, dynamic> srcJson) =>
      _$SenseVoiceJRUsageFromJson(srcJson);

  Map<String, dynamic> toJson() => _$SenseVoiceJRUsageToJson(this);
}

///
/// 阿里云sensevoice识别结果
/// https://help.aliyun.com/zh/model-studio/developer-reference/sensevoice-recorded-speech-recognition-restful-api#c750fdbe55t0f
/// 录音识别结果的json文件的格式
///
@JsonSerializable(explicitToJson: true)
class SenseVoiceRecogResp {
  @JsonKey(name: 'file_url')
  String? fileUrl;

  @JsonKey(name: 'properties')
  SenseVoiceRRProperty? properties;

  @JsonKey(name: 'transcripts')
  List<SenseVoiceRRTranscript>? transcripts;

  SenseVoiceRecogResp(this.fileUrl, this.properties, this.transcripts);

  // 从字符串转
  factory SenseVoiceRecogResp.fromRawJson(String str) =>
      SenseVoiceRecogResp.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory SenseVoiceRecogResp.fromJson(Map<String, dynamic> srcJson) =>
      _$SenseVoiceRecogRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$SenseVoiceRecogRespToJson(this);
}

// 简单缩写 SenseVoiceRecogResp => SenseVoiceRR
@JsonSerializable(explicitToJson: true)
class SenseVoiceRRProperty {
  // 实测
  // paraformer-8k-v1 模型返回没有 audio_format 栏位
  // sensevoice-v1 有此栏位
  @JsonKey(name: 'audio_format')
  String? audioFormat;

  @JsonKey(name: 'channels')
  List<int>? channels;

  @JsonKey(name: 'original_sampling_rate')
  int? originalSamplingRate;

  @JsonKey(name: 'original_duration_in_milliseconds')
  int? originalDurationInMilliseconds;

  SenseVoiceRRProperty(
    this.audioFormat,
    this.channels,
    this.originalSamplingRate,
    this.originalDurationInMilliseconds,
  );

  // 从字符串转
  factory SenseVoiceRRProperty.fromRawJson(String str) =>
      SenseVoiceRRProperty.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory SenseVoiceRRProperty.fromJson(Map<String, dynamic> srcJson) =>
      _$SenseVoiceRRPropertyFromJson(srcJson);

  Map<String, dynamic> toJson() => _$SenseVoiceRRPropertyToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SenseVoiceRRTranscript {
  @JsonKey(name: 'channel_id')
  int channelId;

  @JsonKey(name: 'content_duration_in_milliseconds')
  int contentDurationInMilliseconds;

  @JsonKey(name: 'text')
  String text;

  @JsonKey(name: 'sentences')
  List<SenseVoiceRRTranscriptSentence> sentences;

  SenseVoiceRRTranscript(
    this.channelId,
    this.contentDurationInMilliseconds,
    this.text,
    this.sentences,
  );

  // 从字符串转
  factory SenseVoiceRRTranscript.fromRawJson(String str) =>
      SenseVoiceRRTranscript.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory SenseVoiceRRTranscript.fromJson(Map<String, dynamic> srcJson) =>
      _$SenseVoiceRRTranscriptFromJson(srcJson);

  Map<String, dynamic> toJson() => _$SenseVoiceRRTranscriptToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SenseVoiceRRTranscriptSentence {
  @JsonKey(name: 'begin_time')
  int beginTime;

  @JsonKey(name: 'end_time')
  int endTime;

  @JsonKey(name: 'text')
  String text;

  // 实测 paraformer-8k-v1 模型还有 sentence_id 和 words 栏位
  @JsonKey(name: 'sentence_id')
  int? sentenceId;

  @JsonKey(name: 'words')
  List<SenseVoiceRRTranscriptSentenceWord>? words;

  // 当开启自动说话人分离功能时才会显示该字段
  @JsonKey(name: 'speaker_id')
  int? speakerId;

  SenseVoiceRRTranscriptSentence(
    this.beginTime,
    this.endTime,
    this.text,
    this.sentenceId,
    this.words,
    this.speakerId,
  );

  // 从字符串转
  factory SenseVoiceRRTranscriptSentence.fromRawJson(String str) =>
      SenseVoiceRRTranscriptSentence.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory SenseVoiceRRTranscriptSentence.fromJson(
    Map<String, dynamic> srcJson,
  ) => _$SenseVoiceRRTranscriptSentenceFromJson(srcJson);

  Map<String, dynamic> toJson() => _$SenseVoiceRRTranscriptSentenceToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SenseVoiceRRTranscriptSentenceWord {
  @JsonKey(name: 'begin_time')
  int beginTime;

  @JsonKey(name: 'end_time')
  int endTime;

  @JsonKey(name: 'text')
  String text;

  @JsonKey(name: 'punctuation')
  String punctuation;

  SenseVoiceRRTranscriptSentenceWord(
    this.beginTime,
    this.endTime,
    this.text,
    this.punctuation,
  );

  // 从字符串转
  factory SenseVoiceRRTranscriptSentenceWord.fromRawJson(String str) =>
      SenseVoiceRRTranscriptSentenceWord.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory SenseVoiceRRTranscriptSentenceWord.fromJson(
    Map<String, dynamic> srcJson,
  ) => _$SenseVoiceRRTranscriptSentenceWordFromJson(srcJson);

  Map<String, dynamic> toJson() =>
      _$SenseVoiceRRTranscriptSentenceWordToJson(this);
}
