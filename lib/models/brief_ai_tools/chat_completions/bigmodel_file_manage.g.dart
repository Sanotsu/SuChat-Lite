// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bigmodel_file_manage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BigmodelFileUploadResult _$BigmodelFileUploadResultFromJson(
        Map<String, dynamic> json) =>
    BigmodelFileUploadResult(
      json['id'] as String,
      json['object'] as String,
      (json['bytes'] as num).toInt(),
      json['filename'] as String,
      json['purpose'] as String,
      (json['created_at'] as num).toInt(),
    );

Map<String, dynamic> _$BigmodelFileUploadResultToJson(
        BigmodelFileUploadResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'object': instance.object,
      'bytes': instance.bytes,
      'filename': instance.filename,
      'purpose': instance.purpose,
      'created_at': instance.createdAt,
    };

BigmodelGetFilesResultResp _$BigmodelGetFilesResultRespFromJson(
        Map<String, dynamic> json) =>
    BigmodelGetFilesResultResp(
      json['object'] as String,
      (json['data'] as List<dynamic>)
          .map(
              (e) => BigmodelGetFilesResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BigmodelGetFilesResultRespToJson(
        BigmodelGetFilesResultResp instance) =>
    <String, dynamic>{
      'object': instance.object,
      'data': instance.data.map((e) => e.toJson()).toList(),
    };

BigmodelGetFilesResult _$BigmodelGetFilesResultFromJson(
        Map<String, dynamic> json) =>
    BigmodelGetFilesResult(
      (json['bytes'] as num).toInt(),
      (json['created_at'] as num).toInt(),
      json['filename'] as String,
      json['id'] as String,
      json['object'] as String,
      json['purpose'] as String,
      samples: json['samples'] as String?,
      textStats: json['text_stats'] as String?,
      tokensEstimate: json['tokensEstimate'] as String?,
      totalRecords: json['totalRecords'] as String?,
    );

Map<String, dynamic> _$BigmodelGetFilesResultToJson(
        BigmodelGetFilesResult instance) =>
    <String, dynamic>{
      'bytes': instance.bytes,
      'created_at': instance.createdAt,
      'filename': instance.filename,
      'id': instance.id,
      'object': instance.object,
      'purpose': instance.purpose,
      'samples': instance.samples,
      'text_stats': instance.textStats,
      'tokensEstimate': instance.tokensEstimate,
      'totalRecords': instance.totalRecords,
    };

BigmodelDeleteFilesResult _$BigmodelDeleteFilesResultFromJson(
        Map<String, dynamic> json) =>
    BigmodelDeleteFilesResult(
      json['id'] as String,
      json['object'] as String,
      json['deleted'] as bool,
    );

Map<String, dynamic> _$BigmodelDeleteFilesResultToJson(
        BigmodelDeleteFilesResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'object': instance.object,
      'deleted': instance.deleted,
    };

BigmodelExtractFileResult _$BigmodelExtractFileResultFromJson(
        Map<String, dynamic> json) =>
    BigmodelExtractFileResult(
      json['content'] as String,
      json['file_type'] as String,
      json['filename'] as String,
      json['type'] as String,
      title: json['title'] as String?,
    );

Map<String, dynamic> _$BigmodelExtractFileResultToJson(
        BigmodelExtractFileResult instance) =>
    <String, dynamic>{
      'content': instance.content,
      'file_type': instance.fileType,
      'filename': instance.filename,
      'title': instance.title,
      'type': instance.type,
    };
