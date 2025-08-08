import 'package:json_annotation/json_annotation.dart';

part 'uo_toutiao_news_resp.g.dart';

///
/// 今日头条新闻
///
/// https://github.com/Meowv/ToutiaoNews
///
/// 返回的json中图片等无法使用，就使用简单几个关键栏位即可
///
/// Unofficial -> uo
///
@JsonSerializable(explicitToJson: true)
class UoToutiaoNewsResp {
  @JsonKey(name: 'has_more')
  bool? hasMore;

  @JsonKey(name: 'message')
  String? message;

  @JsonKey(name: 'data')
  List<UoToutiaoNews>? data;

  @JsonKey(name: 'next')
  UoToutiaoNewsNext? next;

  UoToutiaoNewsResp(this.hasMore, this.message, this.data, this.next);

  factory UoToutiaoNewsResp.fromJson(Map<String, dynamic> srcJson) =>
      _$UoToutiaoNewsRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$UoToutiaoNewsRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class UoToutiaoNews {
  @JsonKey(name: 'media_avatar_url')
  String? mediaAvatarUrl;

  @JsonKey(name: 'is_feed_ad')
  bool? isFeedAd;

  @JsonKey(name: 'tag_url')
  String? tagUrl;

  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'single_mode')
  bool? singleMode;

  @JsonKey(name: 'abstract')
  String? abstract;

  @JsonKey(name: 'middle_mode')
  bool? middleMode;

  @JsonKey(name: 'behot_time')
  int? behotTime;

  @JsonKey(name: 'source_url')
  String? sourceUrl;

  @JsonKey(name: 'source')
  String? source;

  @JsonKey(name: 'more_mode')
  bool? moreMode;

  @JsonKey(name: 'article_genre')
  String? articleGenre;

  @JsonKey(name: 'comments_count')
  int? commentsCount;

  @JsonKey(name: 'is_stick')
  bool? isStick;

  @JsonKey(name: 'group_source')
  int? groupSource;

  @JsonKey(name: 'item_id')
  String? itemId;

  @JsonKey(name: 'has_gallery')
  bool? hasGallery;

  @JsonKey(name: 'group_id')
  String? groupId;

  @JsonKey(name: 'media_url')
  String? mediaUrl;

  UoToutiaoNews(
    this.mediaAvatarUrl,
    this.isFeedAd,
    this.tagUrl,
    this.title,
    this.singleMode,
    this.abstract,
    this.middleMode,
    this.behotTime,
    this.sourceUrl,
    this.source,
    this.moreMode,
    this.articleGenre,
    this.commentsCount,
    this.isStick,
    this.groupSource,
    this.itemId,
    this.hasGallery,
    this.groupId,
    this.mediaUrl,
  );

  factory UoToutiaoNews.fromJson(Map<String, dynamic> srcJson) =>
      _$UoToutiaoNewsFromJson(srcJson);

  Map<String, dynamic> toJson() => _$UoToutiaoNewsToJson(this);
}

@JsonSerializable(explicitToJson: true)
class UoToutiaoNewsNext {
  @JsonKey(name: 'max_behot_time')
  int? maxBehotTime;

  UoToutiaoNewsNext(this.maxBehotTime);

  factory UoToutiaoNewsNext.fromJson(Map<String, dynamic> srcJson) =>
      _$UoToutiaoNewsNextFromJson(srcJson);

  Map<String, dynamic> toJson() => _$UoToutiaoNewsNextToJson(this);
}
