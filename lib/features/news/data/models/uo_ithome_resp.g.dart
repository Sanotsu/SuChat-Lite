// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'uo_ithome_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UoItHomeResp _$UoItHomeRespFromJson(Map<String, dynamic> json) => UoItHomeResp(
  (json['toplist'] as List<dynamic>?)
      ?.map((e) => UoItHomeTop.fromJson(e as Map<String, dynamic>))
      .toList(),
  (json['newslist'] as List<dynamic>?)
      ?.map((e) => UoItHomeNews.fromJson(e as Map<String, dynamic>))
      .toList(),
  (json['array'] as List<dynamic>?)?.map((e) => e as String).toList(),
  json['lapin'] as bool?,
);

Map<String, dynamic> _$UoItHomeRespToJson(UoItHomeResp instance) =>
    <String, dynamic>{
      'toplist': instance.toplist?.map((e) => e.toJson()).toList(),
      'newslist': instance.newslist?.map((e) => e.toJson()).toList(),
      'array': instance.array,
      'lapin': instance.lapin,
    };

UoItHomeTop _$UoItHomeTopFromJson(Map<String, dynamic> json) => UoItHomeTop(
  json['client'] as String?,
  json['device'] as String?,
  json['topplat'] as String?,
  (json['newsid'] as num?)?.toInt(),
  json['title'] as String?,
  json['postdate'] as String?,
  json['orderdate'] as String?,
  json['description'] as String?,
  json['image'] as String?,
  (json['hitcount'] as num?)?.toInt(),
  (json['commentcount'] as num?)?.toInt(),
  json['hidecount'] as bool?,
  (json['cid'] as num?)?.toInt(),
  (json['nd'] as num?)?.toInt(),
  (json['sid'] as num?)?.toInt(),
  json['url'] as String?,
);

Map<String, dynamic> _$UoItHomeTopToJson(UoItHomeTop instance) =>
    <String, dynamic>{
      'client': instance.client,
      'device': instance.device,
      'topplat': instance.topplat,
      'newsid': instance.newsid,
      'title': instance.title,
      'postdate': instance.postdate,
      'orderdate': instance.orderdate,
      'description': instance.description,
      'image': instance.image,
      'hitcount': instance.hitcount,
      'commentcount': instance.commentcount,
      'hidecount': instance.hidecount,
      'cid': instance.cid,
      'nd': instance.nd,
      'sid': instance.sid,
      'url': instance.url,
    };

UoItHomeNews _$UoItHomeNewsFromJson(Map<String, dynamic> json) => UoItHomeNews(
  json['forbidcomment'] as bool?,
  (json['kwdlist'] as List<dynamic>?)?.map((e) => e as String).toList(),
  (json['newsid'] as num?)?.toInt(),
  json['title'] as String?,
  json['postdate'] as String?,
  json['orderdate'] as String?,
  json['description'] as String?,
  json['image'] as String?,
  (json['hitcount'] as num?)?.toInt(),
  (json['commentcount'] as num?)?.toInt(),
  json['hidecount'] as bool?,
  (json['cid'] as num?)?.toInt(),
  (json['nd'] as num?)?.toInt(),
  (json['sid'] as num?)?.toInt(),
  json['url'] as String?,
);

Map<String, dynamic> _$UoItHomeNewsToJson(UoItHomeNews instance) =>
    <String, dynamic>{
      'forbidcomment': instance.forbidcomment,
      'kwdlist': instance.kwdlist,
      'newsid': instance.newsid,
      'title': instance.title,
      'postdate': instance.postdate,
      'orderdate': instance.orderdate,
      'description': instance.description,
      'image': instance.image,
      'hitcount': instance.hitcount,
      'commentcount': instance.commentcount,
      'hidecount': instance.hidecount,
      'cid': instance.cid,
      'nd': instance.nd,
      'sid': instance.sid,
      'url': instance.url,
    };
