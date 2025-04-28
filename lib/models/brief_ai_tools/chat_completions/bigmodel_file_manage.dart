import 'package:json_annotation/json_annotation.dart';

part 'bigmodel_file_manage.g.dart';

/// 上传文件
@JsonSerializable(explicitToJson: true)
class BigmodelFileUploadResult {
  @JsonKey(name: 'id')
  String id;

  @JsonKey(name: 'object')
  String object;

  @JsonKey(name: 'bytes')
  int bytes;

  @JsonKey(name: 'filename')
  String filename;

  @JsonKey(name: 'purpose')
  String purpose;

  @JsonKey(name: 'created_at')
  int createdAt;

  BigmodelFileUploadResult(
    this.id,
    this.object,
    this.bytes,
    this.filename,
    this.purpose,
    this.createdAt,
  );

  factory BigmodelFileUploadResult.fromJson(Map<String, dynamic> srcJson) =>
      _$BigmodelFileUploadResultFromJson(srcJson);

  Map<String, dynamic> toJson() => _$BigmodelFileUploadResultToJson(this);
}

/// 获取文件列表
@JsonSerializable(explicitToJson: true)
class BigmodelGetFilesResultResp {
  @JsonKey(name: 'object')
  String object;

  @JsonKey(name: 'data')
  List<BigmodelGetFilesResult> data;

  BigmodelGetFilesResultResp(this.object, this.data);

  factory BigmodelGetFilesResultResp.fromJson(Map<String, dynamic> srcJson) =>
      _$BigmodelGetFilesResultRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$BigmodelGetFilesResultRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BigmodelGetFilesResult {
  @JsonKey(name: 'bytes')
  int bytes;

  @JsonKey(name: 'created_at')
  int createdAt;

  @JsonKey(name: 'filename')
  String filename;

  @JsonKey(name: 'id')
  String id;

  @JsonKey(name: 'object')
  String object;

  @JsonKey(name: 'purpose')
  String purpose;

  @JsonKey(name: 'samples')
  String? samples;

  @JsonKey(name: 'text_stats')
  String? textStats;

  @JsonKey(name: 'tokensEstimate')
  String? tokensEstimate;

  @JsonKey(name: 'totalRecords')
  String? totalRecords;

  BigmodelGetFilesResult(
    this.bytes,
    this.createdAt,
    this.filename,
    this.id,
    this.object,
    this.purpose, {
    this.samples,
    this.textStats,
    this.tokensEstimate,
    this.totalRecords,
  });

  factory BigmodelGetFilesResult.fromJson(Map<String, dynamic> srcJson) =>
      _$BigmodelGetFilesResultFromJson(srcJson);

  Map<String, dynamic> toJson() => _$BigmodelGetFilesResultToJson(this);
}

/// 删除返回结果
@JsonSerializable(explicitToJson: true)
class BigmodelDeleteFilesResult {
  @JsonKey(name: 'id')
  String id;

  @JsonKey(name: 'object')
  String object;

  @JsonKey(name: 'deleted')
  bool deleted;

  BigmodelDeleteFilesResult(this.id, this.object, this.deleted);

  factory BigmodelDeleteFilesResult.fromJson(Map<String, dynamic> srcJson) =>
      _$BigmodelDeleteFilesResultFromJson(srcJson);

  Map<String, dynamic> toJson() => _$BigmodelDeleteFilesResultToJson(this);
}

/// 获取指定文件提取的结果
@JsonSerializable(explicitToJson: true)
class BigmodelExtractFileResult {
  @JsonKey(name: 'content')
  String content;

  @JsonKey(name: 'file_type')
  String fileType;

  @JsonKey(name: 'filename')
  String filename;

  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'type')
  String type;

  BigmodelExtractFileResult(
    this.content,
    this.fileType,
    this.filename,
    this.type, {
    this.title,
  });

  factory BigmodelExtractFileResult.fromJson(Map<String, dynamic> srcJson) =>
      _$BigmodelExtractFileResultFromJson(srcJson);

  Map<String, dynamic> toJson() => _$BigmodelExtractFileResultToJson(this);
}
