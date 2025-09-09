import 'package:json_annotation/json_annotation.dart';

import 'one_base_models.dart';
import 'one_category_list.dart';
import 'one_daily_recommend.dart';

part 'one_detail_models.g.dart';

// 各个分类的详情栏位

/// 图文的详情栏位  (和其他分类的文章详情栏位不一样)
/// https://apis.netstart.cn/one/hp/bydate/2025-09-05
/// 会删除掉ad_ 、 share_ 等广告、分享的内容栏位
@JsonSerializable(explicitToJson: true)
class OneHpDetail {
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

  // 实测小记的author栏位是空的对象
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

  @JsonKey(name: 'volume')
  String? volume;

  @JsonKey(name: 'pic_info')
  String? picInfo;

  @JsonKey(name: 'words_info')
  String? wordsInfo;

  @JsonKey(name: 'subtitle')
  String? subtitle;

  @JsonKey(name: 'number')
  int? number;

  @JsonKey(name: 'serial_id')
  int? serialId;

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
  List<dynamic>? tagList;

  @JsonKey(name: 'orientation')
  String? orientation;

  @JsonKey(name: 'weather')
  OneWeather? weather;

  OneHpDetail({
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
    this.weather,
  });

  factory OneHpDetail.fromJson(Map<String, dynamic> srcJson) =>
      _$OneHpDetailFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneHpDetailToJson(this);
}

/// 文章详情
/// 阅读essay 、问答question、 音乐music、 影视movie 、电台radio 、专题topic、连载serialcontent 等不同类型的文章详情
/// 都使用同一个请求，但响应的栏位根据分类有一些不同，但都整理到一起来
/// https://apis.netstart.cn/one/:categoryName/htmlcontent/:articleId
///
/// 阅读: https://apis.netstart.cn/one/essay/htmlcontent/5243
/// 问答: https://apis.netstart.cn/one/question/htmlcontent/3353
/// 影视: https://apis.netstart.cn/one/movie/htmlcontent/2166
/// 电台: https://apis.netstart.cn/one/radio/htmlcontent/3861
/// 连载: https://apis.netstart.cn/one/serialcontent/htmlcontent/1354
/// 专题: https://apis.netstart.cn/one/topic/htmlcontent/129
@JsonSerializable(explicitToJson: true)
class OneContentDetail {
  @JsonKey(name: 'audio')
  String? audio;

  @JsonKey(name: 'anchor')
  String? anchor;

  @JsonKey(name: 'category')
  int? category;

  @JsonKey(name: 'id')
  String? id;

  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'web_url')
  String? webUrl;

  @JsonKey(name: 'author_list')
  List<OneAuthor>? authorList;

  @JsonKey(name: 'tag_list')
  List<OneTag>? tagList;

  @JsonKey(name: 'enable_comment')
  bool? enableComment;

  @JsonKey(name: 'home_image')
  String? homeImage;

  // 点赞数
  @JsonKey(name: 'praisenum')
  int? praisenum;

  // 评论数
  @JsonKey(name: 'commentnum')
  int? commentnum;

  @JsonKey(name: 'json_content')
  OneContentDetailJson? jsonContent;

  /// 音乐多一些栏位
  @JsonKey(name: 'platform')
  String? platform;

  @JsonKey(name: 'platform_icon')
  String? platformIcon;

  @JsonKey(name: 'platform_name')
  String? platformName;

  @JsonKey(name: 'music_id')
  String? musicId;

  @JsonKey(name: 'music_exception')
  String? musicException;

  /// 电台多的栏位
  @JsonKey(name: 'radio')
  String? radio;

  /// 专题多的栏位
  @JsonKey(name: 'bg_color')
  String? bgColor;

  @JsonKey(name: 'font_color')
  String? fontColor;

  /// 连载多的栏位
  @JsonKey(name: 'serial_title')
  String? serialTitle;

  @JsonKey(name: 'serial_id')
  String? serialId;

  OneContentDetail({
    this.serialTitle,
    this.serialId,
    this.audio,
    this.anchor,
    this.category,
    this.id,
    this.title,
    this.webUrl,
    this.authorList,
    this.tagList,
    this.enableComment,
    this.radio,
    this.platform,
    this.platformIcon,
    this.platformName,
    this.musicId,
    this.homeImage,
    this.musicException,
    this.praisenum,
    this.commentnum,
    this.jsonContent,
    this.bgColor,
    this.fontColor,
  });

  factory OneContentDetail.fromJson(Map<String, dynamic> srcJson) =>
      _$OneContentDetailFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneContentDetailToJson(this);
}

// 不同的分类json内容也有稍微不一样
@JsonSerializable(explicitToJson: true)
class OneContentDetailJson {
  // 阅读的最少，就这些栏位
  @JsonKey(name: 'type')
  String? type;

  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'simple_author')
  List<String>? simpleAuthor;

  @JsonKey(name: 'content')
  String? content;

  @JsonKey(name: 'editor')
  String? editor;

  @JsonKey(name: 'copyright')
  String? copyright;

  // 详情数据的作者栏位和外面的结构不太一样
  @JsonKey(name: 'author')
  OneContentJsonAuthor? author;

  /// 问答额外还有这两个
  @JsonKey(name: 'question_brief')
  String? questionBrief;

  @JsonKey(name: 'simple_answerer')
  String? simpleAnswerer;

  /// 音乐额外还有的栏位
  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'audio_url')
  String? audioUrl;

  @JsonKey(name: 'audio_platform')
  int? audioPlatform;

  @JsonKey(name: 'platform_name')
  String? platformName;

  @JsonKey(name: 'platform_icon')
  String? platformIcon;

  // 音乐的封面信息
  @JsonKey(name: 'music_header')
  OneMusicHeader? musicHeader;

  // 音乐的作者信息
  @JsonKey(name: 'oneDataArticle')
  OneDataArticle? oneDataArticle;

  /// 电影额外还有的栏位
  /// id video_url movie_swipe oneDataArticle
  @JsonKey(name: 'video_url')
  String? videoUrl;

  // 应该不会用到吧，结构类似:  "movie_swipe": {"slides": [],"title": "0/0"},
  @JsonKey(name: 'movie_swipe')
  dynamic movieSwipe;

  /// 电台额外还有的栏位
  /// id radio_url cover
  @JsonKey(name: 'radio_url')
  String? radioUrl;

  @JsonKey(name: 'cover')
  String? cover;

  /// 专题栏位非常少就只有: type special oneDataArticles
  /// 主要就是看 oneDataArticles 栏位中的内容，
  /// 实测：专题的special栏位为 cover\title\content，类似其他分类中的 OneDataArticle

  @JsonKey(name: 'special')
  OneDataArticle? special;

  /// 实测， oneDataArticles 和推荐的内容栏位一致
  @JsonKey(name: 'oneDataArticles')
  List<OneRecommendContent>? oneDataArticles;

  /// 连载额外的栏位(上一篇的id和下一篇的id)
  @JsonKey(name: 'serial_nav')
  OneSerialNav? serialNav;

  OneContentDetailJson(
    this.type,
    this.id,
    this.title,
    this.author,
    this.audioUrl,
    this.audioPlatform,
    this.platformName,
    this.platformIcon,
    this.musicHeader,
    this.oneDataArticle,
    this.simpleAuthor,
    this.content,
    this.editor,
    this.copyright,
    this.questionBrief,
    this.simpleAnswerer,
    this.radioUrl,
    this.cover,
  );

  factory OneContentDetailJson.fromJson(Map<String, dynamic> srcJson) =>
      _$OneContentDetailJsonFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneContentDetailJsonToJson(this);
}

// 详情数据的作者栏位和外面的结构不太一样
@JsonSerializable(explicitToJson: true)
class OneContentJsonAuthor {
  @JsonKey(name: 'role')
  String? role;

  @JsonKey(name: 'authors')
  List<OneContentBriefAuthor>? authors;

  OneContentJsonAuthor({this.role, this.authors});

  factory OneContentJsonAuthor.fromJson(Map<String, dynamic> srcJson) =>
      _$OneContentJsonAuthorFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneContentJsonAuthorToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OneContentBriefAuthor {
  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'avatar')
  String? avatar;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'brief')
  String? brief;

  OneContentBriefAuthor({this.id, this.avatar, this.name, this.brief});

  factory OneContentBriefAuthor.fromJson(Map<String, dynamic> srcJson) =>
      _$OneContentBriefAuthorFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneContentBriefAuthorToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OneMusicHeader {
  @JsonKey(name: 'bg')
  String? bg;

  @JsonKey(name: 'disk')
  String? disk;

  @JsonKey(name: 'cover')
  String? cover;

  @JsonKey(name: 'copyright_img')
  String? copyrightImg;

  @JsonKey(name: 'info')
  String? info;

  OneMusicHeader({
    this.bg,
    this.disk,
    this.cover,
    this.copyrightImg,
    this.info,
  });

  factory OneMusicHeader.fromJson(Map<String, dynamic> srcJson) =>
      _$OneMusicHeaderFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneMusicHeaderToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OneDataArticle {
  // 音乐的栏位
  @JsonKey(name: 'cover')
  String? cover;

  @JsonKey(name: 'lyric')
  String? lyric;

  @JsonKey(name: 'info')
  String? info;

  // 电影的栏位(加上info)
  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'poster')
  String? poster;

  @JsonKey(name: 'officialstory')
  String? officialstory;

  @JsonKey(name: 'releasetime')
  String? releasetime;

  @JsonKey(name: 'sumarry')
  String? sumarry;

  // 专题的special栏位其实就是这个OneDataArticle，但栏位为 cover\title\content
  @JsonKey(name: 'content')
  String? content;

  OneDataArticle({
    this.cover,
    this.lyric,
    this.info,
    this.title,
    this.poster,
    this.officialstory,
    this.releasetime,
    this.sumarry,
    this.content,
  });

  factory OneDataArticle.fromJson(Map<String, dynamic> srcJson) =>
      _$OneDataArticleFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneDataArticleToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OneSerialNav {
  @JsonKey(name: 'prev')
  int? prev;

  @JsonKey(name: 'next')
  int? next;

  OneSerialNav({this.prev, this.next});

  factory OneSerialNav.fromJson(Map<String, dynamic> srcJson) =>
      _$OneSerialNavFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneSerialNavToJson(this);
}

/// 对指定分类内容详情的评论列表
/// https://apis.netstart.cn/one/comment/praiseandtime/:categoryName/:contentId/:commentId
/// commentId	评论id	string	√	0为获取第一页，获取评论分页时取当前页评论的最后一个
/// 评论列表响应的data栏位包含总计和评论列表
@JsonSerializable(explicitToJson: true)
class OneCommentList {
  @JsonKey(name: 'count')
  int? count;

  @JsonKey(name: 'data')
  List<OneComment>? data;

  OneCommentList({this.count, this.data});

  factory OneCommentList.fromJson(Map<String, dynamic> srcJson) =>
      _$OneCommentListFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneCommentListToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OneComment {
  @JsonKey(name: 'id')
  String? id;

  @JsonKey(name: 'quote')
  String? quote;

  @JsonKey(name: 'content')
  String? content;

  @JsonKey(name: 'praisenum')
  int? praisenum;

  @JsonKey(name: 'device_token')
  String? deviceToken;

  @JsonKey(name: 'del_flag')
  String? delFlag;

  @JsonKey(name: 'reviewed')
  String? reviewed;

  @JsonKey(name: 'user_info_id')
  String? userInfoId;

  @JsonKey(name: 'input_date')
  String? inputDate;

  @JsonKey(name: 'created_at')
  String? createdAt;

  @JsonKey(name: 'updated_at')
  String? updatedAt;

  @JsonKey(name: 'user')
  OneUser? user;

  @JsonKey(name: 'touser')
  OneUser? touser;

  @JsonKey(name: 'type')
  int? type;

  OneComment({
    this.id,
    this.quote,
    this.content,
    this.praisenum,
    this.deviceToken,
    this.delFlag,
    this.reviewed,
    this.userInfoId,
    this.inputDate,
    this.createdAt,
    this.updatedAt,
    this.user,
    this.touser,
    this.type,
  });

  factory OneComment.fromJson(Map<String, dynamic> srcJson) =>
      _$OneCommentFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneCommentToJson(this);
}

// 搜索结果 list里面包裹 List<OneContent>
/// search/:categoryName/:keyword/:page
/// categoryName	分类名	string	√	图文hp、阅读reading、音乐 music、影视 movie、ONE电台 radio、作者/音乐人 author
/// keyword	搜索关键词	string	√
/// page	分页页码	number	√	0为第一页，1、2、3等序号
///
/// 比如: https://apis.netstart.cn/one/search/hp/爱/0
///
/// 和分类中 OneContent 比较类似，没有id，但有content_id，所以放在一起
/// 数据放在响应data栏位的list栏位中
@JsonSerializable(explicitToJson: true)
class OneSearchList {
  @JsonKey(name: 'list')
  List<OneContent>? list;

  OneSearchList({this.list});

  factory OneSearchList.fromJson(Map<String, dynamic> srcJson) =>
      _$OneSearchListFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneSearchListToJson(this);
}

// 热门作者 List<OneAuthor>
/// https://apis.netstart.cn/one/author/hot
///

// 作者作品列表 List<OneRecommendContent>
/// https://apis.netstart.cn/one/author/works?author_id=7682938&page_num=0

/// 用户详情 OneUser
/// https://apis.netstart.cn/one/user/info/8878093

// 用户关注作者列表 List<OneAuthor>
/// https://apis.netstart.cn/one/user/follow_list?uid=8878093&last_id=0&type=0

// 用户公开小记列表 List<OneDiary>
// https://apis.netstart.cn/one/other/diary/public/8878093/2035866
