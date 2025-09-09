import 'package:json_annotation/json_annotation.dart';

part 'uo_zhihu_daily_resp.g.dart';

///
/// 知乎日报
/// https://apis.netstart.cn/zhihudaily/#/
///
///
/// Unofficial -> uo
/// UoZhihuDailyStoreItem -> UoZDSItem
/// UoZhihuDailyStoreDetail -> UoZDSDetail
///
@JsonSerializable(explicitToJson: true)
class UoZhihuDailyResp {
  @JsonKey(name: 'date')
  String? date;

  @JsonKey(name: 'stories')
  List<UoZDSItem>? stories;

  @JsonKey(name: 'top_stories')
  List<UoZDSItem>? topStories;

  UoZhihuDailyResp(this.date, this.stories, this.topStories);

  factory UoZhihuDailyResp.fromJson(Map<String, dynamic> srcJson) =>
      _$UoZhihuDailyRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$UoZhihuDailyRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class UoZDSItem {
  @JsonKey(name: 'image_hue')
  String? imageHue;

  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'url')
  String? url;

  @JsonKey(name: 'hint')
  String? hint;

  @JsonKey(name: 'ga_prefix')
  String? gaPrefix;

  // stories 返回的是列表
  @JsonKey(name: 'images')
  List<String>? images;

  // top_stories 返回的是单个
  @JsonKey(name: 'image')
  String? image;

  @JsonKey(name: 'type')
  int? type;

  @JsonKey(name: 'id')
  int? id;

  UoZDSItem(
    this.imageHue,
    this.title,
    this.url,
    this.hint,
    this.gaPrefix,
    this.images,
    this.image,
    this.type,
    this.id,
  );

  factory UoZDSItem.fromJson(Map<String, dynamic> srcJson) =>
      _$UoZDSItemFromJson(srcJson);

  Map<String, dynamic> toJson() => _$UoZDSItemToJson(this);
}
