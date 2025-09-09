// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'baike_history_in_today_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BaikeHistoryInTodayResp _$BaikeHistoryInTodayRespFromJson(
  Map<String, dynamic> json,
) => BaikeHistoryInTodayResp(
  (json['code'] as num?)?.toInt(),
  json['month'],
  json['day'],
  (BaikeHistoryInTodayResp._readItems(json, 'items') as List<dynamic>?)
      ?.map((e) => BaikeHihItem.fromJson(e as Map<String, dynamic>))
      .toList(),
)..date = json['date'] as String?;

Map<String, dynamic> _$BaikeHistoryInTodayRespToJson(
  BaikeHistoryInTodayResp instance,
) => <String, dynamic>{
  'code': instance.code,
  'date': instance.date,
  'month': instance.month,
  'day': instance.day,
  'items': instance.items?.map((e) => e.toJson()).toList(),
};

BaikeHihItem _$BaikeHihItemFromJson(Map<String, dynamic> json) => BaikeHihItem(
  json['year'],
  json['title'] as String?,
  json['link'] as String?,
  BaikeHihItem._readType(json, 'type') as String?,
)..description = json['description'] as String?;

Map<String, dynamic> _$BaikeHihItemToJson(BaikeHihItem instance) =>
    <String, dynamic>{
      'year': instance.year,
      'title': instance.title,
      'link': instance.link,
      'type': instance.type,
      'description': instance.description,
    };
