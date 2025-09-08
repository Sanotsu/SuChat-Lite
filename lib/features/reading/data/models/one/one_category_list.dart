import 'package:json_annotation/json_annotation.dart';

import 'one_base_models.dart';

part 'one_category_list.g.dart';

// 查询各种榜单列表

/// 查询拥有的专题(topic)内容
/// https://apis.netstart.cn/one/banner/list/4
@JsonSerializable(explicitToJson: true)
class OneTopic {
  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'cover')
  String? cover;

  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'category')
  int? category;

  @JsonKey(name: 'content_id')
  String? contentId;

  @JsonKey(name: 'is_stick')
  bool? isStick;

  @JsonKey(name: 'serial_list')
  List<dynamic>? serialList;

  @JsonKey(name: 'link_url')
  String? linkUrl;

  OneTopic({
    this.id,
    this.cover,
    this.title,
    this.category,
    this.contentId,
    this.isStick,
    this.serialList,
    this.linkUrl,
  });

  factory OneTopic.fromJson(Map<String, dynamic> srcJson) =>
      _$OneTopicFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneTopicToJson(this);
}

/// 榜单(rank)分类和推荐
/// https://apis.netstart.cn/one/find/rank
/// 查询阅读的不同榜单信息，并显示榜单前3文章标题，查看完整榜单需要其他接口
/// 榜单分类的内容，一般是:春夏季阅读热榜、春夏季问答热榜、月度阅读热榜、月度问答热榜
@JsonSerializable(explicitToJson: true)
class OneRank {
  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'img_url')
  String? imgUrl;

  // 榜单内容和 OneContent 的基本一样，多个weight栏位
  @JsonKey(name: 'contents')
  List<OneContent>? contents;

  OneRank({this.id, this.title, this.imgUrl, this.contents});

  factory OneRank.fromJson(Map<String, dynamic> srcJson) =>
      _$OneRankFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneRankToJson(this);
}

// 完整榜单列表 List<OneContent>
/// https://apis.netstart.cn/one/find/rank/7

/// 小记(Diary)列表
/// https://apis.netstart.cn/one/diary/square/more/:diaryId
/// diaryId：0获取首页，类似2083895的小记id用来获取前面的小记，一般取上一个列表的最后一个
/// 数据放在响应data栏位的list栏位中
@JsonSerializable(explicitToJson: true)
class OneDiaryList {
  @JsonKey(name: 'list')
  List<OneDiary>? list;

  OneDiaryList({this.list});

  factory OneDiaryList.fromJson(Map<String, dynamic> srcJson) =>
      _$OneDiaryListFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneDiaryListToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OneDiary {
  @JsonKey(name: 'id')
  String? id;

  @JsonKey(name: 'user_id')
  String? userId;

  @JsonKey(name: 'weather')
  String? weather;

  @JsonKey(name: 'content')
  String? content;

  @JsonKey(name: 'picture')
  String? picture;

  @JsonKey(name: 'input_date')
  String? inputDate;

  @JsonKey(name: 'img_url')
  String? imgUrl;

  @JsonKey(name: 'addr')
  String? addr;

  @JsonKey(name: 'is_public')
  String? isPublic;

  @JsonKey(name: 'reviewed')
  String? reviewed;

  @JsonKey(name: 'remark')
  String? remark;

  @JsonKey(name: 'diary_id')
  String? diaryId;

  @JsonKey(name: 'img_url_thumb_h')
  int? imgUrlThumbH;

  // 小记是由用户编写的，所以这个user其实就是小记的作者
  // 单独的文章、连载等，则是由签约author编写，栏位不一样
  @JsonKey(name: 'user')
  OneUser? user;

  @JsonKey(name: 'img_url_thumb')
  String? imgUrlThumb;

  @JsonKey(name: 'praisenum')
  int? praisenum;

  @JsonKey(name: 'img_url_thumb_w')
  int? imgUrlThumbW;

  OneDiary({
    this.id,
    this.userId,
    this.weather,
    this.content,
    this.picture,
    this.inputDate,
    this.imgUrl,
    this.addr,
    this.isPublic,
    this.reviewed,
    this.remark,
    this.diaryId,
    this.imgUrlThumbH,
    this.user,
    this.imgUrlThumb,
    this.praisenum,
    this.imgUrlThumbW,
  });

  factory OneDiary.fromJson(Map<String, dynamic> srcJson) =>
      _$OneDiaryFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneDiaryToJson(this);
}

/// 文章列表 按月查询 (注意，和小记结构不一样)
/// https://apis.netstart.cn/one/find/bymonth/:category/:month
///  category	文章分类	string	√	图文0、阅读1、问答3、音乐4、影视5、电台8
///  month	月份	string	√	2022-05等类似的月份
/// 这里把所有分类的栏位合在一起了，查询指定文章详情就是 OneContentDetail
@JsonSerializable(explicitToJson: true)
class OneContent {
  // id 不一定是字符串或者数字
  @JsonKey(name: 'id')
  dynamic id;

  // 搜索结果中没有id，是content_id
  @JsonKey(name: 'content_id')
  dynamic contentId;

  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'subtitle')
  String? subtitle;

  @JsonKey(name: 'category')
  int? category;

  @JsonKey(name: 'cover')
  String? cover;

  @JsonKey(name: 'maketime')
  String? maketime;

  // 榜单内容和 essay 的基本一样，多个weight栏位
  @JsonKey(name: 'weight')
  int? weight;

  // 年度连载列表的 data 和 essay 栏位一样，但多出连载额外的栏位
  @JsonKey(name: 'serial_id')
  int? serialId;

  @JsonKey(name: 'serial_title')
  String? serialTitle;

  @JsonKey(name: 'forward')
  String? forward;

  @JsonKey(name: 'finished')
  bool? finished;

  // 连载章节目录列表 data 比 essay 多一个序列号列表栏位、编号栏位
  // 可能是数字，可能是字符串
  @JsonKey(name: 'serial_list')
  List<dynamic>? serialList;

  @JsonKey(name: 'number')
  int? number;

  // 搜索结果中多一个date栏位
  @JsonKey(name: 'date')
  String? date;

  // 电台分类还有作者、音频地址等内容 (share_list 不处理)
  @JsonKey(name: 'volume')
  String? volume;

  @JsonKey(name: 'audio_url')
  String? audioUrl;

  @JsonKey(name: 'share_url')
  String? shareUrl;

  @JsonKey(name: 'author')
  OneAuthor? author;

  @JsonKey(name: 'like_count')
  int? likeCount;

  OneContent({
    this.id,
    this.contentId,
    this.title,
    this.subtitle,
    this.category,
    this.cover,
    this.maketime,
    this.weight,
    this.serialId,
    this.serialTitle,
    this.forward,
    this.finished,
    this.serialList,
    this.number,
    this.date,
    this.volume,
    this.audioUrl,
    this.shareUrl,
    this.author,
    this.likeCount,
  });

  factory OneContent.fromJson(Map<String, dynamic> srcJson) =>
      _$OneContentFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneContentToJson(this);
}

// 按年获取连载(Serial)列表 List<OneContent>
/// https://apis.netstart.cn/one/find/serial/byyear/2022

// 指定连载的章节目录列表 List<OneContent>
/// https://apis.netstart.cn/one/find/serial/list/92
