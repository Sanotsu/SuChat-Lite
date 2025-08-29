// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'haokan_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HaokanBaseResp<T> _$HaokanBaseRespFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => HaokanBaseResp<T>(
  code: (json['code'] as num?)?.toInt(),
  msg: json['msg'] as String?,
  time: (json['time'] as num?)?.toInt(),
  data: _$nullableGenericFromJson(json['data'], fromJsonT),
);

Map<String, dynamic> _$HaokanBaseRespToJson<T>(
  HaokanBaseResp<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'code': instance.code,
  'msg': instance.msg,
  'time': instance.time,
  'data': _$nullableGenericToJson(instance.data, toJsonT),
};

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) => input == null ? null : fromJson(input);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) => input == null ? null : toJson(input);

HaokanIndex _$HaokanIndexFromJson(Map<String, dynamic> json) => HaokanIndex(
  recommend: (json['recommend'] as List<dynamic>?)
      ?.map((e) => HaokanRecommend.fromJson(e as Map<String, dynamic>))
      .toList(),
  recommendHeng: json['recommend_heng'],
  recommendPiao: json['recommend_piao'],
  tab: (json['tab'] as List<dynamic>?)
      ?.map((e) => HaokanTab.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$HaokanIndexToJson(HaokanIndex instance) =>
    <String, dynamic>{
      'recommend': instance.recommend?.map((e) => e.toJson()).toList(),
      'recommend_heng': instance.recommendHeng,
      'recommend_piao': instance.recommendPiao,
      'tab': instance.tab?.map((e) => e.toJson()).toList(),
    };

HaokanRecommend _$HaokanRecommendFromJson(Map<String, dynamic> json) =>
    HaokanRecommend(
      type: (json['type'] as num?)?.toInt(),
      did: (json['did'] as num?)?.toInt(),
      chapterid: (json['chapterid'] as num?)?.toInt(),
      pic: json['pic'] as String?,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      url: json['url'] as String?,
      title: json['title'] as String?,
      desc: json['desc'] as String?,
    );

Map<String, dynamic> _$HaokanRecommendToJson(HaokanRecommend instance) =>
    <String, dynamic>{
      'type': instance.type,
      'did': instance.did,
      'chapterid': instance.chapterid,
      'pic': instance.pic,
      'width': instance.width,
      'height': instance.height,
      'url': instance.url,
      'title': instance.title,
      'desc': instance.desc,
    };

HaokanTab _$HaokanTabFromJson(Map<String, dynamic> json) => HaokanTab(
  id: json['id'],
  name: json['name'] as String?,
  pictype: json['pictype'] as String?,
  list: (json['list'] as List<dynamic>?)
      ?.map((e) => HaokanComic.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$HaokanTabToJson(HaokanTab instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'pictype': instance.pictype,
  'list': instance.list?.map((e) => e.toJson()).toList(),
};

HaokanComic _$HaokanComicFromJson(Map<String, dynamic> json) => HaokanComic(
  id: (json['id'] as num?)?.toInt(),
  cateid: json['cateid'] as String?,
  userid: (json['userid'] as num?)?.toInt(),
  author: json['author'] as String?,
  title: json['title'] as String?,
  tag: json['tag'] as String?,
  info: json['info'] as String?,
  pic: json['pic'] as String?,
  bigpic: json['bigpic'] as String?,
  newpic: json['newpic'] as String?,
  indexpic: json['indexpic'] as String?,
  updatepic: json['updatepic'] as String?,
  firstchapterid: (json['firstchapterid'] as num?)?.toInt(),
  lastchapter: json['lastchapter'] as String?,
  lastNumChapter: json['lastNumChapter'] as String?,
  ifend: (json['ifend'] as num?)?.toInt(),
  vip: (json['vip'] as num?)?.toInt(),
  coupon: (json['coupon'] as num?)?.toInt(),
  look: (json['look'] as num?)?.toInt(),
  createtime: (json['createtime'] as num?)?.toInt(),
  updatetime: (json['updatetime'] as num?)?.toInt(),
  onlinetime: json['onlinetime'] as String?,
  cpid: (json['cpid'] as num?)?.toInt(),
  status: (json['status'] as num?)?.toInt(),
  lastReadChapter: json['lastReadChapter'] == null
      ? null
      : HaokanChapter.fromJson(json['lastReadChapter'] as Map<String, dynamic>),
  inBookcase: (json['inBookcase'] as num?)?.toInt(),
  chapterlist1: json['chapterlist1'] as List<dynamic>?,
  chapterlist2: (json['chapterlist2'] as List<dynamic>?)
      ?.map((e) => HaokanChapter.fromJson(e as Map<String, dynamic>))
      .toList(),
  ifurge: (json['ifurge'] as num?)?.toInt(),
  urgeNum: (json['urge_num'] as num?)?.toInt(),
  numComment: (json['num_comment'] as num?)?.toInt(),
  numLove: (json['num_love'] as num?)?.toInt(),
  numLook: (json['num_look'] as num?)?.toInt(),
  numFav: (json['num_fav'] as num?)?.toInt(),
  ifFav: (json['if_fav'] as num?)?.toInt(),
  ifLove: (json['if_love'] as num?)?.toInt(),
  ifUpdate: (json['if_update'] as num?)?.toInt(),
)..indexsort = (json['indexsort'] as num?)?.toInt();

Map<String, dynamic> _$HaokanComicToJson(HaokanComic instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cateid': instance.cateid,
      'userid': instance.userid,
      'author': instance.author,
      'title': instance.title,
      'tag': instance.tag,
      'info': instance.info,
      'pic': instance.pic,
      'bigpic': instance.bigpic,
      'newpic': instance.newpic,
      'indexpic': instance.indexpic,
      'updatepic': instance.updatepic,
      'firstchapterid': instance.firstchapterid,
      'lastchapter': instance.lastchapter,
      'lastNumChapter': instance.lastNumChapter,
      'ifend': instance.ifend,
      'vip': instance.vip,
      'coupon': instance.coupon,
      'look': instance.look,
      'createtime': instance.createtime,
      'updatetime': instance.updatetime,
      'onlinetime': instance.onlinetime,
      'cpid': instance.cpid,
      'status': instance.status,
      'num_comment': instance.numComment,
      'num_love': instance.numLove,
      'num_look': instance.numLook,
      'num_fav': instance.numFav,
      'if_fav': instance.ifFav,
      'if_love': instance.ifLove,
      'if_update': instance.ifUpdate,
      'lastReadChapter': instance.lastReadChapter?.toJson(),
      'indexsort': instance.indexsort,
      'inBookcase': instance.inBookcase,
      'chapterlist1': instance.chapterlist1,
      'chapterlist2': instance.chapterlist2?.map((e) => e.toJson()).toList(),
      'ifurge': instance.ifurge,
      'urge_num': instance.urgeNum,
    };

HaokanChapter _$HaokanChapterFromJson(Map<String, dynamic> json) =>
    HaokanChapter(
      id: (json['id'] as num?)?.toInt(),
      comicid: (json['comicid'] as num?)?.toInt(),
      chapter: json['chapter'] as String?,
      name: json['name'] as String?,
      sort: (json['sort'] as num?)?.toInt(),
      piclist: (json['piclist'] as List<dynamic>?)
          ?.map((e) => HaokanChapterPicture.fromJson(e as Map<String, dynamic>))
          .toList(),
      createtime: (json['createtime'] as num?)?.toInt(),
      updatetime: (json['updatetime'] as num?)?.toInt(),
      vip: (json['vip'] as num?)?.toInt(),
      status: (json['status'] as num?)?.toInt(),
      onlinetime: json['onlinetime'] as String?,
      outsite: json['outsite'] as String?,
      outid: json['outid'] as String?,
      idLast: (json['id_last'] as num?)?.toInt(),
      idNext: (json['id_next'] as num?)?.toInt(),
      numComment: (json['num_comment'] as num?)?.toInt(),
      numLove: (json['num_love'] as num?)?.toInt(),
      numFav: (json['num_fav'] as num?)?.toInt(),
      ifLove: (json['if_love'] as num?)?.toInt(),
      ifFav: (json['if_fav'] as num?)?.toInt(),
      ifBuy: (json['if_buy'] as num?)?.toInt(),
      limitfree: (json['limitfree'] as num?)?.toInt(),
      ifvipuser: (json['ifvipuser'] as num?)?.toInt(),
      ad: json['ad'],
      ifCloseAuto: (json['if_close_auto'] as num?)?.toInt(),
      ifshowad: (json['ifshowad'] as num?)?.toInt(),
      noadtime: (json['noadtime'] as num?)?.toInt(),
      coupon: (json['coupon'] as num?)?.toInt(),
      couponPutnum: (json['coupon_putnum'] as num?)?.toInt(),
      couponNum: (json['coupon_num'] as num?)?.toInt(),
      lookCount: (json['look_count'] as num?)?.toInt(),
      cover: json['cover'] as String?,
      reading: (json['reading'] as num?)?.toInt(),
    );

Map<String, dynamic> _$HaokanChapterToJson(HaokanChapter instance) =>
    <String, dynamic>{
      'id': instance.id,
      'comicid': instance.comicid,
      'chapter': instance.chapter,
      'name': instance.name,
      'sort': instance.sort,
      'createtime': instance.createtime,
      'updatetime': instance.updatetime,
      'status': instance.status,
      'vip': instance.vip,
      'cover': instance.cover,
      'reading': instance.reading,
      'if_buy': instance.ifBuy,
      'limitfree': instance.limitfree,
      'num_comment': instance.numComment,
      'num_love': instance.numLove,
      'num_fav': instance.numFav,
      'if_love': instance.ifLove,
      'if_fav': instance.ifFav,
      'piclist': instance.piclist?.map((e) => e.toJson()).toList(),
      'onlinetime': instance.onlinetime,
      'outsite': instance.outsite,
      'outid': instance.outid,
      'id_last': instance.idLast,
      'id_next': instance.idNext,
      'ifvipuser': instance.ifvipuser,
      'ad': instance.ad,
      'if_close_auto': instance.ifCloseAuto,
      'ifshowad': instance.ifshowad,
      'noadtime': instance.noadtime,
      'coupon': instance.coupon,
      'coupon_putnum': instance.couponPutnum,
      'coupon_num': instance.couponNum,
      'look_count': instance.lookCount,
    };

HaokanChapterPicture _$HaokanChapterPictureFromJson(
  Map<String, dynamic> json,
) => HaokanChapterPicture(
  url: json['url'] as String?,
  width: (json['width'] as num?)?.toInt(),
  height: (json['height'] as num?)?.toInt(),
  size: (json['size'] as num?)?.toInt(),
);

Map<String, dynamic> _$HaokanChapterPictureToJson(
  HaokanChapterPicture instance,
) => <String, dynamic>{
  'url': instance.url,
  'width': instance.width,
  'height': instance.height,
  'size': instance.size,
};

HaokanComment _$HaokanCommentFromJson(Map<String, dynamic> json) =>
    HaokanComment(
      id: (json['id'] as num?)?.toInt(),
      did: (json['did'] as num?)?.toInt(),
      did2: (json['did2'] as num?)?.toInt(),
      did3: json['did3'] as String?,
      rid: (json['rid'] as num?)?.toInt(),
      rrid: (json['rrid'] as num?)?.toInt(),
      uid: (json['uid'] as num?)?.toInt(),
      content: json['content'] as String?,
      ctime: (json['ctime'] as num?)?.toInt(),
      lastmodified: (json['lastmodified'] as num?)?.toInt(),
      status: (json['status'] as num?)?.toInt(),
      uname: json['uname'] as String?,
      uhead: json['uhead'] as String?,
      ulevel: (json['ulevel'] as num?)?.toInt(),
      likeCount: (json['like_count'] as num?)?.toInt(),
      replyCount: (json['reply_count'] as num?)?.toInt(),
      hasLike: (json['has_like'] as num?)?.toInt(),
      from: json['from'] as String?,
    );

Map<String, dynamic> _$HaokanCommentToJson(HaokanComment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'did': instance.did,
      'did2': instance.did2,
      'did3': instance.did3,
      'rid': instance.rid,
      'rrid': instance.rrid,
      'uid': instance.uid,
      'content': instance.content,
      'ctime': instance.ctime,
      'lastmodified': instance.lastmodified,
      'status': instance.status,
      'uname': instance.uname,
      'uhead': instance.uhead,
      'ulevel': instance.ulevel,
      'like_count': instance.likeCount,
      'reply_count': instance.replyCount,
      'has_like': instance.hasLike,
      'from': instance.from,
    };

HaokanTop _$HaokanTopFromJson(Map<String, dynamic> json) =>
    HaokanTop(id: json['id'] as String?, name: json['name'] as String?);

Map<String, dynamic> _$HaokanTopToJson(HaokanTop instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
};

HaokanCategoryData _$HaokanCategoryDataFromJson(Map<String, dynamic> json) =>
    HaokanCategoryData(
      (json['category'] as List<dynamic>?)
          ?.map((e) => HaokanCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['end'] as List<dynamic>?)
          ?.map((e) => HaokanCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['free'] as List<dynamic>?)
          ?.map((e) => HaokanCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['sort'] as List<dynamic>?)
          ?.map((e) => HaokanCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$HaokanCategoryDataToJson(HaokanCategoryData instance) =>
    <String, dynamic>{
      'category': instance.category?.map((e) => e.toJson()).toList(),
      'end': instance.end?.map((e) => e.toJson()).toList(),
      'free': instance.free?.map((e) => e.toJson()).toList(),
      'sort': instance.sort?.map((e) => e.toJson()).toList(),
    };

HaokanCategory _$HaokanCategoryFromJson(Map<String, dynamic> json) =>
    HaokanCategory((json['id'] as num?)?.toInt(), json['title'] as String?);

Map<String, dynamic> _$HaokanCategoryToJson(HaokanCategory instance) =>
    <String, dynamic>{'id': instance.id, 'title': instance.title};

HaokanQueryResult _$HaokanQueryResultFromJson(Map<String, dynamic> json) =>
    HaokanQueryResult(
      type: (json['type'] as num?)?.toInt(),
      name: json['name'] as String?,
      list: (json['list'] as List<dynamic>?)
          ?.map((e) => HaokanComic.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$HaokanQueryResultToJson(HaokanQueryResult instance) =>
    <String, dynamic>{
      'type': instance.type,
      'name': instance.name,
      'list': instance.list?.map((e) => e.toJson()).toList(),
    };
