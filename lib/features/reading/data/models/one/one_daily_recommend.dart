import 'package:json_annotation/json_annotation.dart';

import 'one_base_models.dart';

part 'one_daily_recommend.g.dart';

/// 首页的每日推荐
/// https://apis.netstart.cn/one/channel/one/2022-05-05
///

// 每日推荐的具体数据(部分栏位有删除，比如分享share_list 广告ad 等)
//  OneDailyRecommend => OneDR
@JsonSerializable(explicitToJson: true)
class OneRecommend {
  @JsonKey(name: 'id')
  String? id;

  @JsonKey(name: 'weather')
  OneWeather? weather;

  @JsonKey(name: 'date')
  String? date;

  // 每日推荐的内容，一般是:一个图文(小记)、一个阅读(文章)、一个问答、一个电台
  @JsonKey(name: 'content_list')
  List<OneRecommendContent>? contentList;

  @JsonKey(name: 'menu')
  OneRecommendMenu? menu;

  OneRecommend({this.id, this.weather, this.date, this.contentList, this.menu});

  factory OneRecommend.fromJson(Map<String, dynamic> srcJson) =>
      _$OneRecommendFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneRecommendToJson(this);
}

// 删除了ad_ share_ 开头的栏位
@JsonSerializable(explicitToJson: true)
class OneRecommendContent {
  @JsonKey(name: 'id')
  String? id;

  @JsonKey(name: 'category')
  String? category;

  @JsonKey(name: 'display_category')
  int? displayCategory;

  @JsonKey(name: 'item_id')
  String? itemId;

  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'forward')
  String? forward;

  @JsonKey(name: 'img_url')
  String? imgUrl;

  @JsonKey(name: 'pic_ipX')
  String? picIpX;

  @JsonKey(name: 'like_count')
  int? likeCount;

  @JsonKey(name: 'post_date')
  String? postDate;

  @JsonKey(name: 'last_update_date')
  String? lastUpdateDate;

  @JsonKey(name: 'author')
  OneAuthor? author;

  @JsonKey(name: 'video_url')
  String? videoUrl;

  @JsonKey(name: 'audio_url')
  String? audioUrl;

  @JsonKey(name: 'audio_platform')
  int? audioPlatform;

  @JsonKey(name: 'start_video')
  String? startVideo;

  @JsonKey(name: 'has_reading')
  int? hasReading;

  // 可能是数字也可能是字符串
  @JsonKey(name: 'volume')
  dynamic volume;

  @JsonKey(name: 'pic_info')
  String? picInfo;

  @JsonKey(name: 'words_info')
  String? wordsInfo;

  @JsonKey(name: 'text_author_info')
  OneTextAuthorInfo? textAuthorInfo;

  @JsonKey(name: 'subtitle')
  String? subtitle;

  // 可能是数字，可能是字符串
  @JsonKey(name: 'number')
  dynamic number;

  // 可能是数字，可能是字符串
  @JsonKey(name: 'serial_id')
  dynamic serialId;

  @JsonKey(name: 'serial_list')
  List<dynamic>? serialList;

  @JsonKey(name: 'movie_story_id')
  int? movieStoryId;

  @JsonKey(name: 'content_id')
  String? contentId;

  @JsonKey(name: 'content_type')
  String? contentType;

  @JsonKey(name: 'content_bgcolor')
  String? contentBgcolor;

  @JsonKey(name: 'tag_list')
  List<OneTag>? tagList;

  @JsonKey(name: 'orientation')
  String? orientation;

  OneRecommendContent({
    this.id,
    this.category,
    this.displayCategory,
    this.itemId,
    this.title,
    this.forward,
    this.imgUrl,
    this.picIpX,
    this.likeCount,
    this.postDate,
    this.lastUpdateDate,
    this.author,
    this.videoUrl,
    this.audioUrl,
    this.audioPlatform,
    this.startVideo,
    this.hasReading,
    this.volume,
    this.picInfo,
    this.wordsInfo,
    this.textAuthorInfo,
    this.subtitle,
    this.number,
    this.serialId,
    this.serialList,
    this.movieStoryId,
    this.contentId,
    this.contentType,
    this.contentBgcolor,
    this.tagList,
    this.orientation,
  });

  factory OneRecommendContent.fromJson(Map<String, dynamic> srcJson) =>
      _$OneRecommendContentFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneRecommendContentToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OneTextAuthorInfo {
  @JsonKey(name: 'text_author_name')
  String? textAuthorName;

  @JsonKey(name: 'text_author_work')
  String? textAuthorWork;

  @JsonKey(name: 'text_author_desc')
  String? textAuthorDesc;

  OneTextAuthorInfo({
    this.textAuthorName,
    this.textAuthorWork,
    this.textAuthorDesc,
  });

  factory OneTextAuthorInfo.fromJson(Map<String, dynamic> srcJson) =>
      _$OneTextAuthorInfoFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneTextAuthorInfoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OneRecommendMenu {
  // 每日推荐都有期数，这里显示当日的推荐是第几期
  @JsonKey(name: 'vol')
  String? vol;

  // 这里是当体推荐的目录简介内容
  @JsonKey(name: 'list')
  List<OneRecommendMenuContent>? list;

  OneRecommendMenu({this.vol, this.list});

  factory OneRecommendMenu.fromJson(Map<String, dynamic> srcJson) =>
      _$OneRecommendMenuFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneRecommendMenuToJson(this);
}

// 每日推荐的标题列表
@JsonSerializable(explicitToJson: true)
class OneRecommendMenuContent {
  @JsonKey(name: 'content_type')
  String? contentType;

  @JsonKey(name: 'content_id')
  String? contentId;

  @JsonKey(name: 'title')
  String? title;

  OneRecommendMenuContent({this.contentType, this.contentId, this.title});

  factory OneRecommendMenuContent.fromJson(Map<String, dynamic> srcJson) =>
      _$OneRecommendMenuContentFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneRecommendMenuContentToJson(this);
}

/// 按照月份获取所有推荐内容
/// https://apis.netstart.cn/one/feeds/list/2025-08

@JsonSerializable(explicitToJson: true)
class OneMonthRecommend {
  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'date')
  String? date;

  @JsonKey(name: 'cover')
  String? cover;

  OneMonthRecommend({this.id, this.date, this.cover});

  factory OneMonthRecommend.fromJson(Map<String, dynamic> srcJson) =>
      _$OneMonthRecommendFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneMonthRecommendToJson(this);
}
