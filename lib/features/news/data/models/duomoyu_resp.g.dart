// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'duomoyu_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DuomoyuResp _$DuomoyuRespFromJson(Map<String, dynamic> json) => DuomoyuResp(
  (json['code'] as num?)?.toInt(),
  json['name'] as String?,
  json['description'] as String?,
  json['title'] as String?,
  json['type'] as String?,
  json['link'] as String?,
  (json['total'] as num?)?.toInt(),
  json['fromCache'] as bool?,
  json['updateTime'] as String?,
  (json['data'] as List<dynamic>?)
      ?.map((e) => DuomoyuData.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DuomoyuRespToJson(DuomoyuResp instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'description': instance.description,
      'title': instance.title,
      'type': instance.type,
      'link': instance.link,
      'total': instance.total,
      'fromCache': instance.fromCache,
      'updateTime': instance.updateTime,
      'data': instance.data?.map((e) => e.toJson()).toList(),
    };

DuomoyuData _$DuomoyuDataFromJson(Map<String, dynamic> json) => DuomoyuData(
  json['id'],
  json['title'] as String?,
  json['desc'] as String?,
  json['cover'] as String?,
  (json['hot'] as num?)?.toInt(),
  (json['timestamp'] as num?)?.toInt(),
  json['url'] as String?,
  json['mobileUrl'] as String?,
);

Map<String, dynamic> _$DuomoyuDataToJson(DuomoyuData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'desc': instance.desc,
      'cover': instance.cover,
      'hot': instance.hot,
      'timestamp': instance.timestamp,
      'url': instance.url,
      'mobileUrl': instance.mobileUrl,
    };
