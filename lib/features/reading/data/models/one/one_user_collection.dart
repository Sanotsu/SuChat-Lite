import 'package:json_annotation/json_annotation.dart';

import 'one_base_models.dart';

part 'one_user_collection.g.dart';

// 用户收藏查询，不同的分类结果栏位差异很大，和其他查询的接口栏位也不一样。就单独出来

// 用户收藏文章列表
/// https://apis.netstart.cn/one/othercollection/:userId/more/:category/:page
/// userId	用户id	string	√
/// category	分类id	string	√	图文0、阅读1、问答2、音乐4 、影视5、连载6、电台8、歌单9
/// page	分页页码	number	√	0为第一页，1、2、3等序号
/// 收藏文章栏位和之前的 OneContent 不太一样

///
/// 收藏的图文
/// https://apis.netstart.cn/one/othercollection/8878093/more/0/0
///
/// 删除了 share_list 栏位
///
@JsonSerializable(explicitToJson: true)
class OneUserHpCollection {
  @JsonKey(name: 'hpcontent_id')
  String? hpcontentId;

  @JsonKey(name: 'hp_title')
  String? hpTitle;

  @JsonKey(name: 'author_id')
  String? authorId;

  @JsonKey(name: 'hp_img_url')
  String? hpImgUrl;

  @JsonKey(name: 'hp_img_original_url')
  String? hpImgOriginalUrl;

  @JsonKey(name: 'hp_author')
  String? hpAuthor;

  @JsonKey(name: 'ipad_url')
  String? ipadUrl;

  @JsonKey(name: 'hp_content')
  String? hpContent;

  @JsonKey(name: 'hp_makettime')
  String? hpMakettime;

  @JsonKey(name: 'last_update_date')
  String? lastUpdateDate;

  @JsonKey(name: 'web_url')
  String? webUrl;

  @JsonKey(name: 'wb_img_url')
  String? wbImgUrl;

  @JsonKey(name: 'image_authors')
  String? imageAuthors;

  @JsonKey(name: 'text_authors')
  String? textAuthors;

  @JsonKey(name: 'image_from')
  String? imageFrom;

  @JsonKey(name: 'text_from')
  String? textFrom;

  @JsonKey(name: 'content_bgcolor')
  String? contentBgcolor;

  @JsonKey(name: 'template_category')
  String? templateCategory;

  @JsonKey(name: 'text_author_name')
  String? textAuthorName;

  @JsonKey(name: 'text_author_work')
  String? textAuthorWork;

  @JsonKey(name: 'text_author_desc')
  String? textAuthorDesc;

  @JsonKey(name: 'maketime')
  String? maketime;

  @JsonKey(name: 'praisenum')
  int? praisenum;

  @JsonKey(name: 'sharenum')
  int? sharenum;

  @JsonKey(name: 'commentnum')
  int? commentnum;

  OneUserHpCollection({
    this.hpcontentId,
    this.hpTitle,
    this.authorId,
    this.hpImgUrl,
    this.hpImgOriginalUrl,
    this.hpAuthor,
    this.ipadUrl,
    this.hpContent,
    this.hpMakettime,
    this.lastUpdateDate,
    this.webUrl,
    this.wbImgUrl,
    this.imageAuthors,
    this.textAuthors,
    this.imageFrom,
    this.textFrom,
    this.contentBgcolor,
    this.templateCategory,
    this.textAuthorName,
    this.textAuthorWork,
    this.textAuthorDesc,
    this.maketime,
    this.praisenum,
    this.sharenum,
    this.commentnum,
  });

  factory OneUserHpCollection.fromJson(Map<String, dynamic> srcJson) =>
      _$OneUserHpCollectionFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneUserHpCollectionToJson(this);
}

///
/// 收藏的阅读
/// https://apis.netstart.cn/one/othercollection/8878093/more/1/0
///
///
@JsonSerializable(explicitToJson: true)
class OneUserReadingCollection {
  @JsonKey(name: 'content_id')
  String? contentId;

  @JsonKey(name: 'hp_title')
  String? hpTitle;

  @JsonKey(name: 'hp_makettime')
  String? hpMakettime;

  @JsonKey(name: 'guide_word')
  String? guideWord;

  @JsonKey(name: 'start_video')
  String? startVideo;

  @JsonKey(name: 'author')
  List<OneAuthor>? author;

  @JsonKey(name: 'has_audio')
  bool? hasAudio;

  @JsonKey(name: 'author_list')
  List<OneAuthor>? authorList;

  OneUserReadingCollection({
    this.contentId,
    this.hpTitle,
    this.hpMakettime,
    this.guideWord,
    this.startVideo,
    this.author,
    this.hasAudio,
    this.authorList,
  });

  factory OneUserReadingCollection.fromJson(Map<String, dynamic> srcJson) =>
      _$OneUserReadingCollectionFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneUserReadingCollectionToJson(this);
}

///
/// 收藏的问题
/// https://apis.netstart.cn/one/othercollection/8878093/more/2/0
///
@JsonSerializable()
class OneUserQuestionCollection {
  @JsonKey(name: 'question_id')
  String? questionId;

  @JsonKey(name: 'question_title')
  String? questionTitle;

  @JsonKey(name: 'answer_title')
  String? answerTitle;

  @JsonKey(name: 'answer_content')
  String? answerContent;

  @JsonKey(name: 'question_makettime')
  String? questionMakettime;

  @JsonKey(name: 'start_video')
  String? startVideo;

  @JsonKey(name: 'author_list')
  List<OneAuthor>? authorList;

  @JsonKey(name: 'asker_list')
  List<OneAuthor>? askerList;

  OneUserQuestionCollection({
    this.questionId,
    this.questionTitle,
    this.answerTitle,
    this.answerContent,
    this.questionMakettime,
    this.startVideo,
    this.authorList,
    this.askerList,
  });

  factory OneUserQuestionCollection.fromJson(Map<String, dynamic> srcJson) =>
      _$OneUserQuestionCollectionFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneUserQuestionCollectionToJson(this);
}

// 收藏的音乐
// https://apis.netstart.cn/one/othercollection/8878093/more/4/0
@JsonSerializable(explicitToJson: true)
class OneUserMusicCollection {
  @JsonKey(name: 'id')
  String? id;

  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'cover')
  String? cover;

  @JsonKey(name: 'story_title')
  String? storyTitle;

  @JsonKey(name: 'platform')
  String? platform;

  @JsonKey(name: 'music_id')
  String? musicId;

  @JsonKey(name: 'album')
  String? album;

  @JsonKey(name: 'start_video')
  String? startVideo;

  @JsonKey(name: 'author')
  OneAuthor? author;

  @JsonKey(name: 'author_list')
  List<OneAuthor>? authorList;

  OneUserMusicCollection({
    this.id,
    this.title,
    this.cover,
    this.storyTitle,
    this.platform,
    this.musicId,
    this.album,
    this.startVideo,
    this.author,
    this.authorList,
  });

  factory OneUserMusicCollection.fromJson(Map<String, dynamic> srcJson) =>
      _$OneUserMusicCollectionFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneUserMusicCollectionToJson(this);
}

/// 收藏的影视
/// https://apis.netstart.cn/one/othercollection/8878093/more/5/0
@JsonSerializable(explicitToJson: true)
class OneUserMovieCollection {
  @JsonKey(name: 'id')
  String? id;

  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'verse')
  String? verse;

  @JsonKey(name: 'verse_en')
  String? verseEn;

  @JsonKey(name: 'revisedscore')
  String? revisedscore;

  @JsonKey(name: 'releasetime')
  String? releasetime;

  @JsonKey(name: 'scoretime')
  String? scoretime;

  @JsonKey(name: 'start_video')
  String? startVideo;

  @JsonKey(name: 'cover')
  String? cover;

  @JsonKey(name: 'author_list')
  List<OneAuthor>? authorList;

  @JsonKey(name: 'subtitle')
  String? subtitle;

  @JsonKey(name: 'servertime')
  int? servertime;

  OneUserMovieCollection({
    this.id,
    this.title,
    this.verse,
    this.verseEn,
    this.revisedscore,
    this.releasetime,
    this.scoretime,
    this.startVideo,
    this.cover,
    this.authorList,
    this.subtitle,
    this.servertime,
  });

  factory OneUserMovieCollection.fromJson(Map<String, dynamic> srcJson) =>
      _$OneUserMovieCollectionFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneUserMovieCollectionToJson(this);
}

/// 收藏的电台
/// https://apis.netstart.cn/one/othercollection/8878093/more/8/0
@JsonSerializable()
class OneUserRadioCollection {
  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'cover')
  String? cover;

  @JsonKey(name: 'category')
  int? category;

  @JsonKey(name: 'content_id')
  String? contentId;

  @JsonKey(name: 'author_list')
  List<OneAuthor>? authorList;

  OneUserRadioCollection({
    this.title,
    this.cover,
    this.category,
    this.contentId,
    this.authorList,
  });

  factory OneUserRadioCollection.fromJson(Map<String, dynamic> srcJson) =>
      _$OneUserRadioCollectionFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneUserRadioCollectionToJson(this);
}

/// 收藏的歌单
/// https://apis.netstart.cn/one/othercollection/8878093/more/9/0
@JsonSerializable()
class OneUserPlaylistCollection {
  @JsonKey(name: 'collection_type')
  String? collectionType;

  @JsonKey(name: 'collection_id')
  String? collectionId;

  @JsonKey(name: 'id')
  String? id;

  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'subtitle')
  String? subtitle;

  @JsonKey(name: 'cover')
  String? cover;

  @JsonKey(name: 'platform')
  String? platform;

  @JsonKey(name: 'platform_icon')
  String? platformIcon;

  @JsonKey(name: 'platform_name')
  String? platformName;

  @JsonKey(name: 'music_id')
  String? musicId;

  @JsonKey(name: 'category')
  int? category;

  @JsonKey(name: 'content_id')
  String? contentId;

  @JsonKey(name: 'music_exception')
  String? musicException;

  OneUserPlaylistCollection({
    this.collectionType,
    this.collectionId,
    this.id,
    this.title,
    this.subtitle,
    this.cover,
    this.platform,
    this.platformIcon,
    this.platformName,
    this.musicId,
    this.category,
    this.contentId,
    this.musicException,
  });

  factory OneUserPlaylistCollection.fromJson(Map<String, dynamic> srcJson) =>
      _$OneUserPlaylistCollectionFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneUserPlaylistCollectionToJson(this);
}
