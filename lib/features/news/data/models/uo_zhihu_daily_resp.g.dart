// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'uo_zhihu_daily_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UoZhihuDailyResp _$UoZhihuDailyRespFromJson(Map<String, dynamic> json) =>
    UoZhihuDailyResp(
      json['date'] as String?,
      (json['stories'] as List<dynamic>?)
          ?.map((e) => UoZDSItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['top_stories'] as List<dynamic>?)
          ?.map((e) => UoZDSItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UoZhihuDailyRespToJson(UoZhihuDailyResp instance) =>
    <String, dynamic>{
      'date': instance.date,
      'stories': instance.stories?.map((e) => e.toJson()).toList(),
      'top_stories': instance.topStories?.map((e) => e.toJson()).toList(),
    };

UoZDSItem _$UoZDSItemFromJson(Map<String, dynamic> json) => UoZDSItem(
  json['image_hue'] as String?,
  json['title'] as String?,
  json['url'] as String?,
  json['hint'] as String?,
  json['ga_prefix'] as String?,
  (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
  json['image'] as String?,
  (json['type'] as num?)?.toInt(),
  (json['id'] as num?)?.toInt(),
);

Map<String, dynamic> _$UoZDSItemToJson(UoZDSItem instance) => <String, dynamic>{
  'image_hue': instance.imageHue,
  'title': instance.title,
  'url': instance.url,
  'hint': instance.hint,
  'ga_prefix': instance.gaPrefix,
  'images': instance.images,
  'image': instance.image,
  'type': instance.type,
  'id': instance.id,
};
