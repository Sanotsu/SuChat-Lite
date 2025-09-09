import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'haokan_models.g.dart';

/// 好看漫画的model合并在一起去，几个比较重要的类合并成一个，减少重复
///

/// 好看漫画请求响应的基类
/// 所有的API返回结果都是这样的
@JsonSerializable(genericArgumentFactories: true, explicitToJson: true)
class HaokanBaseResp<T> {
  @JsonKey(name: 'code')
  final int? code;

  @JsonKey(name: 'msg')
  final String? msg;

  @JsonKey(name: 'time')
  final int? time;

  @JsonKey(name: 'data')
  final T? data;

  HaokanBaseResp({this.code, this.msg, this.time, this.data});

  // 检查请求是否成功
  bool get isSuccess => code == 200;

  factory HaokanBaseResp.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return _$HaokanBaseRespFromJson(json, fromJsonT);
  }

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) {
    return _$HaokanBaseRespToJson(this, toJsonT);
  }
}

// 添加扩展方法，从积累中获取数据
extension HaokanBaseRespExtensions<T> on HaokanBaseResp<T> {
  /// 如果响应成功且数据不为空，返回数据；否则抛出异常
  T getDataOrThrow() {
    if (code == 200 && data != null) {
      return data!;
    }
    throw Exception("请求出错:\ntime:$time\ncode:$code\nmsg:$msg");
  }

  /// 如果响应成功且数据不为空，返回数据；否则返回null
  T? getDataOrNull() {
    return code == 200 ? data : null;
  }
}

///
/// 【首页部分】
/// 好看漫画首页响应数据
/// https://apis.netstart.cn/haokan/index/index
///
/// 首页某个tab下方点击换一环(参数id为对应tab中id)
/// https://apis.netstart.cn/haokan/index/exchange?id=13
///
/// HaokanIndex => HKI 好看漫画首页
///
// 响应结果： HaokanBaseResp<HaokanIndex>
@JsonSerializable(explicitToJson: true)
class HaokanIndex {
  @JsonKey(name: 'recommend')
  List<HaokanRecommend>? recommend;

  // 20250827 目前返回的是个{} 空对象，不知道具体栏位
  @JsonKey(name: 'recommend_heng')
  dynamic recommendHeng;

  // 20250827 目前返回的是个{} 空对象，不知道具体栏位
  @JsonKey(name: 'recommend_piao')
  dynamic recommendPiao;

  @JsonKey(name: 'tab')
  List<HaokanTab>? tab;

  HaokanIndex({
    this.recommend,
    this.recommendHeng,
    this.recommendPiao,
    this.tab,
  });

  // 从字符串转
  factory HaokanIndex.fromRawJson(String str) =>
      HaokanIndex.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory HaokanIndex.fromJson(Map<String, dynamic> srcJson) =>
      _$HaokanIndexFromJson(srcJson);

  Map<String, dynamic> toJson() => _$HaokanIndexToJson(this);
}

@JsonSerializable(explicitToJson: true)
class HaokanRecommend {
  @JsonKey(name: 'type')
  int? type;

  @JsonKey(name: 'did')
  int? did;

  @JsonKey(name: 'chapterid')
  int? chapterid;

  @JsonKey(name: 'pic')
  String? pic;

  @JsonKey(name: 'width')
  int? width;

  @JsonKey(name: 'height')
  int? height;

  @JsonKey(name: 'url')
  String? url;

  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'desc')
  String? desc;

  HaokanRecommend({
    this.type,
    this.did,
    this.chapterid,
    this.pic,
    this.width,
    this.height,
    this.url,
    this.title,
    this.desc,
  });

  // 从字符串转
  factory HaokanRecommend.fromRawJson(String str) =>
      HaokanRecommend.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory HaokanRecommend.fromJson(Map<String, dynamic> srcJson) =>
      _$HaokanRecommendFromJson(srcJson);

  Map<String, dynamic> toJson() => _$HaokanRecommendToJson(this);
}

@JsonSerializable(explicitToJson: true)
class HaokanTab {
  // 首页查询时时string类型，但换一换时时int类型，所以用dynamic（其他id也可能有这种问题）
  @JsonKey(name: 'id')
  dynamic id;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'pictype')
  String? pictype;

  @JsonKey(name: 'list')
  List<HaokanComic>? list;

  HaokanTab({this.id, this.name, this.pictype, this.list});

  // 从字符串转
  factory HaokanTab.fromRawJson(String str) =>
      HaokanTab.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory HaokanTab.fromJson(Map<String, dynamic> srcJson) =>
      _$HaokanTabFromJson(srcJson);

  Map<String, dynamic> toJson() => _$HaokanTabToJson(this);
}

///
/// 漫画信息
/// 概要的和详细的栏位放在一起
///
@JsonSerializable(explicitToJson: true)
class HaokanComic {
  @JsonKey(name: 'id')
  int? id;

  // 分类编号可能拥有多个分类，所以值为“用逗号分割的数字字符串”
  @JsonKey(name: 'cateid')
  String? cateid;

  @JsonKey(name: 'userid')
  int? userid;

  @JsonKey(name: 'author')
  String? author;

  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'tag')
  String? tag;

  @JsonKey(name: 'info')
  String? info;

  @JsonKey(name: 'pic')
  String? pic;

  @JsonKey(name: 'bigpic')
  String? bigpic;

  @JsonKey(name: 'newpic')
  String? newpic;

  @JsonKey(name: 'indexpic')
  String? indexpic;

  @JsonKey(name: 'updatepic')
  String? updatepic;

  @JsonKey(name: 'firstchapterid')
  int? firstchapterid;

  @JsonKey(name: 'lastchapter')
  String? lastchapter;

  @JsonKey(name: 'lastNumChapter')
  String? lastNumChapter;

  @JsonKey(name: 'ifend')
  int? ifend;

  @JsonKey(name: 'vip')
  int? vip;

  @JsonKey(name: 'coupon')
  int? coupon;

  @JsonKey(name: 'look')
  int? look;

  @JsonKey(name: 'createtime')
  int? createtime;

  @JsonKey(name: 'updatetime')
  int? updatetime;

  @JsonKey(name: 'onlinetime')
  String? onlinetime;

  @JsonKey(name: 'cpid')
  int? cpid;

  @JsonKey(name: 'status')
  int? status;

  @JsonKey(name: 'num_comment')
  int? numComment;

  @JsonKey(name: 'num_love')
  int? numLove;

  @JsonKey(name: 'num_look')
  int? numLook;

  @JsonKey(name: 'num_fav')
  int? numFav;

  @JsonKey(name: 'if_fav')
  int? ifFav;

  @JsonKey(name: 'if_love')
  int? ifLove;

  @JsonKey(name: 'if_update')
  int? ifUpdate;

  // 这个直接使用章节信息类，即便属性比章节信息少很多
  @JsonKey(name: 'lastReadChapter')
  HaokanChapter? lastReadChapter;

  // 漫画详情没这个
  @JsonKey(name: 'indexsort')
  int? indexsort;

  // 这几个是漫画详情多出来的
  @JsonKey(name: 'inBookcase')
  int? inBookcase;

  @JsonKey(name: 'chapterlist1')
  List<dynamic>? chapterlist1;

  // 这个直接使用章节信息类，即便属性比章节信息少很多
  @JsonKey(name: 'chapterlist2')
  List<HaokanChapter>? chapterlist2;

  @JsonKey(name: 'ifurge')
  int? ifurge;

  @JsonKey(name: 'urge_num')
  int? urgeNum;

  HaokanComic({
    this.id,
    this.cateid,
    this.userid,
    this.author,
    this.title,
    this.tag,
    this.info,
    this.pic,
    this.bigpic,
    this.newpic,
    this.indexpic,
    this.updatepic,
    this.firstchapterid,
    this.lastchapter,
    this.lastNumChapter,
    this.ifend,
    this.vip,
    this.coupon,
    this.look,
    this.createtime,
    this.updatetime,
    this.onlinetime,
    this.cpid,
    this.status,
    this.lastReadChapter,
    this.inBookcase,
    this.chapterlist1,
    this.chapterlist2,
    this.ifurge,
    this.urgeNum,
    this.numComment,
    this.numLove,
    this.numLook,
    this.numFav,
    this.ifFav,
    this.ifLove,
    this.ifUpdate,
  });

  // 从字符串转
  factory HaokanComic.fromRawJson(String str) =>
      HaokanComic.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory HaokanComic.fromJson(Map<String, dynamic> srcJson) =>
      _$HaokanComicFromJson(srcJson);

  Map<String, dynamic> toJson() => _$HaokanComicToJson(this);
}

/// 漫画章节信息
///
/// 栏位从少到多，都放在一起(这里删除了 ad 等广告相关的栏位):
///
/// LastReadChapter < Chapterlist2 < HaokanChapterData < HaokanComicChapterDetail
///
@JsonSerializable(explicitToJson: true)
class HaokanChapter {
  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'comicid')
  int? comicid;

  @JsonKey(name: 'chapter')
  String? chapter;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'sort')
  int? sort;

  @JsonKey(name: 'createtime')
  int? createtime;

  @JsonKey(name: 'updatetime')
  int? updatetime;

  @JsonKey(name: 'status')
  int? status;

  // 比 LastReadChapter 多出的栏位
  @JsonKey(name: 'vip')
  int? vip;

  @JsonKey(name: 'cover')
  String? cover;

  @JsonKey(name: 'reading')
  int? reading;

  @JsonKey(name: 'if_buy')
  int? ifBuy;

  @JsonKey(name: 'limitfree')
  int? limitfree;

  // 比 Chapterlist2 多出的栏位(少了一个reading栏位)
  @JsonKey(name: 'num_comment')
  int? numComment;

  @JsonKey(name: 'num_love')
  int? numLove;

  @JsonKey(name: 'num_fav')
  int? numFav;

  @JsonKey(name: 'if_love')
  int? ifLove;

  @JsonKey(name: 'if_fav')
  int? ifFav;

  // 下面是相较于 HaokanChapterData 多出的栏位
  @JsonKey(name: 'piclist')
  List<HaokanChapterPicture>? piclist;

  @JsonKey(name: 'onlinetime')
  String? onlinetime;

  @JsonKey(name: 'outsite')
  String? outsite;

  @JsonKey(name: 'outid')
  String? outid;

  @JsonKey(name: 'id_last')
  int? idLast;

  @JsonKey(name: 'id_next')
  int? idNext;

  @JsonKey(name: 'ifvipuser')
  int? ifvipuser;

  // 这个应该是广告，不会去显示，所以直接动态类型
  @JsonKey(name: 'ad')
  dynamic ad;

  @JsonKey(name: 'if_close_auto')
  int? ifCloseAuto;

  @JsonKey(name: 'ifshowad')
  int? ifshowad;

  @JsonKey(name: 'noadtime')
  int? noadtime;

  @JsonKey(name: 'coupon')
  int? coupon;

  @JsonKey(name: 'coupon_putnum')
  int? couponPutnum;

  @JsonKey(name: 'coupon_num')
  int? couponNum;

  @JsonKey(name: 'look_count')
  int? lookCount;

  HaokanChapter({
    this.id,
    this.comicid,
    this.chapter,
    this.name,
    this.sort,
    this.piclist,
    this.createtime,
    this.updatetime,
    this.vip,
    this.status,
    this.onlinetime,
    this.outsite,
    this.outid,
    this.idLast,
    this.idNext,
    this.numComment,
    this.numLove,
    this.numFav,
    this.ifLove,
    this.ifFav,
    this.ifBuy,
    this.limitfree,
    this.ifvipuser,
    this.ad,
    this.ifCloseAuto,
    this.ifshowad,
    this.noadtime,
    this.coupon,
    this.couponPutnum,
    this.couponNum,
    this.lookCount,
    this.cover,
    this.reading,
  });

  // 从字符串转
  factory HaokanChapter.fromRawJson(String str) =>
      HaokanChapter.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory HaokanChapter.fromJson(Map<String, dynamic> srcJson) =>
      _$HaokanChapterFromJson(srcJson);

  Map<String, dynamic> toJson() => _$HaokanChapterToJson(this);
}

// 看漫画的话，最主要就是这个图片的url了
@JsonSerializable(explicitToJson: true)
class HaokanChapterPicture {
  // 这里是http，可能不好用。直接改为https虽然可用，但是不安全的连接
  @JsonKey(name: 'url')
  String? url;

  @JsonKey(name: 'width')
  int? width;

  @JsonKey(name: 'height')
  int? height;

  @JsonKey(name: 'size')
  int? size;

  HaokanChapterPicture({this.url, this.width, this.height, this.size});

  // 从字符串转
  factory HaokanChapterPicture.fromRawJson(String str) =>
      HaokanChapterPicture.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory HaokanChapterPicture.fromJson(Map<String, dynamic> srcJson) =>
      _$HaokanChapterPictureFromJson(srcJson);

  Map<String, dynamic> toJson() => _$HaokanChapterPictureToJson(this);
}

///
/// 漫画评论信息
///
@JsonSerializable(explicitToJson: true)
class HaokanComment {
  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'did')
  int? did;

  @JsonKey(name: 'did2')
  int? did2;

  @JsonKey(name: 'did3')
  String? did3;

  @JsonKey(name: 'rid')
  int? rid;

  @JsonKey(name: 'rrid')
  int? rrid;

  @JsonKey(name: 'uid')
  int? uid;

  @JsonKey(name: 'content')
  String? content;

  @JsonKey(name: 'ctime')
  int? ctime;

  @JsonKey(name: 'lastmodified')
  int? lastmodified;

  @JsonKey(name: 'status')
  int? status;

  @JsonKey(name: 'uname')
  String? uname;

  @JsonKey(name: 'uhead')
  String? uhead;

  @JsonKey(name: 'ulevel')
  int? ulevel;

  @JsonKey(name: 'like_count')
  int? likeCount;

  @JsonKey(name: 'reply_count')
  int? replyCount;

  @JsonKey(name: 'has_like')
  int? hasLike;

  @JsonKey(name: 'from')
  String? from;

  HaokanComment({
    this.id,
    this.did,
    this.did2,
    this.did3,
    this.rid,
    this.rrid,
    this.uid,
    this.content,
    this.ctime,
    this.lastmodified,
    this.status,
    this.uname,
    this.uhead,
    this.ulevel,
    this.likeCount,
    this.replyCount,
    this.hasLike,
    this.from,
  });

  // 从字符串转
  factory HaokanComment.fromRawJson(String str) =>
      HaokanComment.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory HaokanComment.fromJson(Map<String, dynamic> srcJson) =>
      _$HaokanCommentFromJson(srcJson);

  Map<String, dynamic> toJson() => _$HaokanCommentToJson(this);
}

/// 漫画的榜单数据
/// 这个请求结果，可以写死为枚举
/* 
[{"id": "1","name": "人气榜"},
{"id": "4","name": "男生榜"},
{"id": "5","name": "女生榜"},
{"id": "2","name": "新作榜"},
{"id": "6","name": "催更榜"}]
*/
@JsonSerializable()
class HaokanTop {
  @JsonKey(name: 'id')
  String? id;

  @JsonKey(name: 'name')
  String? name;

  HaokanTop({this.id, this.name});

  // 从字符串转
  factory HaokanTop.fromRawJson(String str) =>
      HaokanTop.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory HaokanTop.fromJson(Map<String, dynamic> srcJson) =>
      _$HaokanTopFromJson(srcJson);

  Map<String, dynamic> toJson() => _$HaokanTopToJson(this);
}

///
/// 漫画的分类数据
/// 这个结果也可以写死
///
@JsonSerializable(explicitToJson: true)
class HaokanCategoryData {
  @JsonKey(name: 'category')
  List<HaokanCategory>? category;

  @JsonKey(name: 'end')
  List<HaokanCategory>? end;

  @JsonKey(name: 'free')
  List<HaokanCategory>? free;

  @JsonKey(name: 'sort')
  List<HaokanCategory>? sort;

  HaokanCategoryData(this.category, this.end, this.free, this.sort);

  // 从字符串转
  factory HaokanCategoryData.fromRawJson(String str) =>
      HaokanCategoryData.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory HaokanCategoryData.fromJson(Map<String, dynamic> srcJson) =>
      _$HaokanCategoryDataFromJson(srcJson);

  Map<String, dynamic> toJson() => _$HaokanCategoryDataToJson(this);
}

@JsonSerializable(explicitToJson: true)
class HaokanCategory {
  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'title')
  String? title;

  HaokanCategory(this.id, this.title);

  // 从字符串转
  factory HaokanCategory.fromRawJson(String str) =>
      HaokanCategory.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory HaokanCategory.fromJson(Map<String, dynamic> srcJson) =>
      _$HaokanCategoryFromJson(srcJson);

  Map<String, dynamic> toJson() => _$HaokanCategoryToJson(this);
}

///
/// 漫画的关键字搜索结果
///
@JsonSerializable(explicitToJson: true)
class HaokanQueryResult {
  @JsonKey(name: 'type')
  int? type;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'list')
  List<HaokanComic>? list;

  HaokanQueryResult({this.type, this.name, this.list});

  // 从字符串转
  factory HaokanQueryResult.fromRawJson(String str) =>
      HaokanQueryResult.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory HaokanQueryResult.fromJson(Map<String, dynamic> srcJson) =>
      _$HaokanQueryResultFromJson(srcJson);

  Map<String, dynamic> toJson() => _$HaokanQueryResultToJson(this);
}
