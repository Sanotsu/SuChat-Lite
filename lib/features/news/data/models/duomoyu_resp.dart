import 'package:json_annotation/json_annotation.dart';

part 'duomoyu_resp.g.dart';

///
/// 多摸鱼（https://duomoyu.com/hot-list/）主页响应
/// https://duomoyu.com/api/{分类}
///
@JsonSerializable(explicitToJson: true)
class DuomoyuResp {
  @JsonKey(name: 'code')
  int? code;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'description')
  String? description;

  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'type')
  String? type;

  @JsonKey(name: 'link')
  String? link;

  @JsonKey(name: 'total')
  int? total;

  @JsonKey(name: 'fromCache')
  bool? fromCache;

  @JsonKey(name: 'updateTime')
  String? updateTime;

  @JsonKey(name: 'data')
  List<DuomoyuData>? data;

  DuomoyuResp(
    this.code,
    this.name,
    this.description,
    this.title,
    this.type,
    this.link,
    this.total,
    this.fromCache,
    this.updateTime,
    this.data,
  );

  factory DuomoyuResp.fromJson(Map<String, dynamic> srcJson) =>
      _$DuomoyuRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DuomoyuRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DuomoyuData {
  @JsonKey(name: 'id')
  // 有的是字符串，有的又是数字
  dynamic id;

  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'desc')
  String? desc;

  @JsonKey(name: 'cover')
  String? cover;

  @JsonKey(name: 'hot')
  int? hot;

  @JsonKey(name: 'timestamp')
  int? timestamp;

  @JsonKey(name: 'url')
  String? url;

  @JsonKey(name: 'mobileUrl')
  String? mobileUrl;

  DuomoyuData(
    this.id,
    this.title,
    this.desc,
    this.cover,
    this.hot,
    this.timestamp,
    this.url,
    this.mobileUrl,
  );

  factory DuomoyuData.fromJson(Map<String, dynamic> srcJson) =>
      _$DuomoyuDataFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DuomoyuDataToJson(this);
}
