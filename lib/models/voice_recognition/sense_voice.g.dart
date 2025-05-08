// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sense_voice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SenseVoiceJobResp _$SenseVoiceJobRespFromJson(Map<String, dynamic> json) =>
    SenseVoiceJobResp(
      json['request_id'] as String?,
      json['output'] == null
          ? null
          : SenseVoiceJROutput.fromJson(json['output'] as Map<String, dynamic>),
      json['usage'] == null
          ? null
          : SenseVoiceJRUsage.fromJson(json['usage'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SenseVoiceJobRespToJson(SenseVoiceJobResp instance) =>
    <String, dynamic>{
      'request_id': instance.requestId,
      'output': instance.output?.toJson(),
      'usage': instance.usage?.toJson(),
    };

SenseVoiceJROutput _$SenseVoiceJROutputFromJson(Map<String, dynamic> json) =>
    SenseVoiceJROutput(
      json['task_id'] as String,
      json['task_status'] as String,
      json['submit_time'] as String?,
      json['scheduled_time'] as String?,
      json['end_time'] as String?,
      (json['results'] as List<dynamic>?)
          ?.map((e) =>
              SenseVoiceJROutputResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      json['task_metrics'] == null
          ? null
          : SenseVoiceJROutputTaskMetric.fromJson(
              json['task_metrics'] as Map<String, dynamic>),
      json['code'] as String?,
      json['message'] as String?,
    );

Map<String, dynamic> _$SenseVoiceJROutputToJson(SenseVoiceJROutput instance) =>
    <String, dynamic>{
      'task_id': instance.taskId,
      'task_status': instance.taskStatus,
      'submit_time': instance.submitTime,
      'scheduled_time': instance.scheduledTime,
      'end_time': instance.endTime,
      'results': instance.results?.map((e) => e.toJson()).toList(),
      'task_metrics': instance.taskMetrics?.toJson(),
      'code': instance.code,
      'message': instance.message,
    };

SenseVoiceJROutputResult _$SenseVoiceJROutputResultFromJson(
        Map<String, dynamic> json) =>
    SenseVoiceJROutputResult(
      json['file_url'] as String,
      json['transcription_url'] as String?,
      json['subtask_status'] as String,
      json['code'] as String?,
      json['message'] as String?,
    );

Map<String, dynamic> _$SenseVoiceJROutputResultToJson(
        SenseVoiceJROutputResult instance) =>
    <String, dynamic>{
      'file_url': instance.fileUrl,
      'subtask_status': instance.subtaskStatus,
      'transcription_url': instance.transcriptionUrl,
      'code': instance.code,
      'message': instance.message,
    };

SenseVoiceJROutputTaskMetric _$SenseVoiceJROutputTaskMetricFromJson(
        Map<String, dynamic> json) =>
    SenseVoiceJROutputTaskMetric(
      (json['TOTAL'] as num).toInt(),
      (json['SUCCEEDED'] as num).toInt(),
      (json['FAILED'] as num).toInt(),
    );

Map<String, dynamic> _$SenseVoiceJROutputTaskMetricToJson(
        SenseVoiceJROutputTaskMetric instance) =>
    <String, dynamic>{
      'TOTAL': instance.TOTAL,
      'SUCCEEDED': instance.SUCCEEDED,
      'FAILED': instance.FAILED,
    };

SenseVoiceJRUsage _$SenseVoiceJRUsageFromJson(Map<String, dynamic> json) =>
    SenseVoiceJRUsage(
      (json['duration'] as num).toInt(),
    );

Map<String, dynamic> _$SenseVoiceJRUsageToJson(SenseVoiceJRUsage instance) =>
    <String, dynamic>{
      'duration': instance.duration,
    };

SenseVoiceRecogResp _$SenseVoiceRecogRespFromJson(Map<String, dynamic> json) =>
    SenseVoiceRecogResp(
      json['file_url'] as String?,
      json['properties'] == null
          ? null
          : SenseVoiceRRProperty.fromJson(
              json['properties'] as Map<String, dynamic>),
      (json['transcripts'] as List<dynamic>?)
          ?.map(
              (e) => SenseVoiceRRTranscript.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SenseVoiceRecogRespToJson(
        SenseVoiceRecogResp instance) =>
    <String, dynamic>{
      'file_url': instance.fileUrl,
      'properties': instance.properties?.toJson(),
      'transcripts': instance.transcripts?.map((e) => e.toJson()).toList(),
    };

SenseVoiceRRProperty _$SenseVoiceRRPropertyFromJson(
        Map<String, dynamic> json) =>
    SenseVoiceRRProperty(
      json['audio_format'] as String?,
      (json['channels'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      (json['original_sampling_rate'] as num?)?.toInt(),
      (json['original_duration_in_milliseconds'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SenseVoiceRRPropertyToJson(
        SenseVoiceRRProperty instance) =>
    <String, dynamic>{
      'audio_format': instance.audioFormat,
      'channels': instance.channels,
      'original_sampling_rate': instance.originalSamplingRate,
      'original_duration_in_milliseconds':
          instance.originalDurationInMilliseconds,
    };

SenseVoiceRRTranscript _$SenseVoiceRRTranscriptFromJson(
        Map<String, dynamic> json) =>
    SenseVoiceRRTranscript(
      (json['channel_id'] as num).toInt(),
      (json['content_duration_in_milliseconds'] as num).toInt(),
      json['text'] as String,
      (json['sentences'] as List<dynamic>)
          .map((e) => SenseVoiceRRTranscriptSentence.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SenseVoiceRRTranscriptToJson(
        SenseVoiceRRTranscript instance) =>
    <String, dynamic>{
      'channel_id': instance.channelId,
      'content_duration_in_milliseconds':
          instance.contentDurationInMilliseconds,
      'text': instance.text,
      'sentences': instance.sentences.map((e) => e.toJson()).toList(),
    };

SenseVoiceRRTranscriptSentence _$SenseVoiceRRTranscriptSentenceFromJson(
        Map<String, dynamic> json) =>
    SenseVoiceRRTranscriptSentence(
      (json['begin_time'] as num).toInt(),
      (json['end_time'] as num).toInt(),
      json['text'] as String,
      (json['sentence_id'] as num?)?.toInt(),
      (json['words'] as List<dynamic>?)
          ?.map((e) => SenseVoiceRRTranscriptSentenceWord.fromJson(
              e as Map<String, dynamic>))
          .toList(),
      (json['speaker_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SenseVoiceRRTranscriptSentenceToJson(
        SenseVoiceRRTranscriptSentence instance) =>
    <String, dynamic>{
      'begin_time': instance.beginTime,
      'end_time': instance.endTime,
      'text': instance.text,
      'sentence_id': instance.sentenceId,
      'words': instance.words?.map((e) => e.toJson()).toList(),
      'speaker_id': instance.speakerId,
    };

SenseVoiceRRTranscriptSentenceWord _$SenseVoiceRRTranscriptSentenceWordFromJson(
        Map<String, dynamic> json) =>
    SenseVoiceRRTranscriptSentenceWord(
      (json['begin_time'] as num).toInt(),
      (json['end_time'] as num).toInt(),
      json['text'] as String,
      json['punctuation'] as String,
    );

Map<String, dynamic> _$SenseVoiceRRTranscriptSentenceWordToJson(
        SenseVoiceRRTranscriptSentenceWord instance) =>
    <String, dynamic>{
      'begin_time': instance.beginTime,
      'end_time': instance.endTime,
      'text': instance.text,
      'punctuation': instance.punctuation,
    };
