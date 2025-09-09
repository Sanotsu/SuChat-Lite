// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_now_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NewsNowResp _$NewsNowRespFromJson(Map<String, dynamic> json) => NewsNowResp(
  json['status'] as String?,
  json['id'] as String?,
  (json['updatedTime'] as num?)?.toInt(),
  (json['items'] as List<dynamic>?)
      ?.map((e) => NewsNowItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$NewsNowRespToJson(NewsNowResp instance) =>
    <String, dynamic>{
      'status': instance.status,
      'id': instance.id,
      'updatedTime': instance.updatedTime,
      'items': instance.items?.map((e) => e.toJson()).toList(),
    };

NewsNowItem _$NewsNowItemFromJson(Map<String, dynamic> json) => NewsNowItem(
  json['id'],
  json['title'] as String?,
  json['extra'] == null
      ? null
      : NewsNowRExtra.fromJson(json['extra'] as Map<String, dynamic>),
  json['url'] as String?,
  json['mobileUrl'] as String?,
);

Map<String, dynamic> _$NewsNowItemToJson(NewsNowItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'extra': instance.extra?.toJson(),
      'url': instance.url,
      'mobileUrl': instance.mobileUrl,
    };

NewsNowRExtra _$NewsNowRExtraFromJson(Map<String, dynamic> json) =>
    NewsNowRExtra(json['info'] as String?, json['hover'] as String?);

Map<String, dynamic> _$NewsNowRExtraToJson(NewsNowRExtra instance) =>
    <String, dynamic>{'info': instance.info, 'hover': instance.hover};
