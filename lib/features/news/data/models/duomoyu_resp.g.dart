// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'duomoyu_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DuomoyuSourcesResp _$DuomoyuSourcesRespFromJson(Map<String, dynamic> json) =>
    DuomoyuSourcesResp(
      json['success'] as bool?,
      json['data'] == null
          ? null
          : DuomoyuSourcesData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DuomoyuSourcesRespToJson(DuomoyuSourcesResp instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data?.toJson(),
    };

DuomoyuSourcesData _$DuomoyuSourcesDataFromJson(Map<String, dynamic> json) =>
    DuomoyuSourcesData(
      (json['sources'] as List<dynamic>?)
          ?.map((e) => DuomoyuSource.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DuomoyuSourcesDataToJson(DuomoyuSourcesData instance) =>
    <String, dynamic>{
      'sources': instance.sources?.map((e) => e.toJson()).toList(),
    };

DuomoyuSource _$DuomoyuSourceFromJson(Map<String, dynamic> json) =>
    DuomoyuSource(
      json['slug'] as String?,
      json['label'] as String?,
      json['category'] as String?,
      json['imageKey'] as String?,
      (json['displayOrder'] as num?)?.toInt(),
      json['accessLevel'] as String?,
      json['updatedAt'] as String?,
      json['stale'] as bool?,
    );

Map<String, dynamic> _$DuomoyuSourceToJson(DuomoyuSource instance) =>
    <String, dynamic>{
      'slug': instance.slug,
      'label': instance.label,
      'category': instance.category,
      'imageKey': instance.imageKey,
      'displayOrder': instance.displayOrder,
      'accessLevel': instance.accessLevel,
      'updatedAt': instance.updatedAt,
      'stale': instance.stale,
    };

DuomoyuRankingResp _$DuomoyuRankingRespFromJson(Map<String, dynamic> json) =>
    DuomoyuRankingResp(
      json['success'] as bool?,
      json['data'] == null
          ? null
          : DuomoyuRankingData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DuomoyuRankingRespToJson(DuomoyuRankingResp instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data?.toJson(),
    };

DuomoyuRankingData _$DuomoyuRankingDataFromJson(Map<String, dynamic> json) =>
    DuomoyuRankingData(
      json['source'] == null
          ? null
          : DuomoyuSource.fromJson(json['source'] as Map<String, dynamic>),
      (json['items'] as List<dynamic>?)
          ?.map((e) => DuomoyuItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DuomoyuRankingDataToJson(DuomoyuRankingData instance) =>
    <String, dynamic>{
      'source': instance.source?.toJson(),
      'items': instance.items?.map((e) => e.toJson()).toList(),
    };

DuomoyuItem _$DuomoyuItemFromJson(Map<String, dynamic> json) => DuomoyuItem(
  (json['rank'] as num?)?.toInt(),
  json['title'] as String?,
  json['url'] as String?,
  json['hotValue'],
  json['publishedAt'] as String?,
);

Map<String, dynamic> _$DuomoyuItemToJson(DuomoyuItem instance) =>
    <String, dynamic>{
      'rank': instance.rank,
      'title': instance.title,
      'url': instance.url,
      'hotValue': instance.hotValue,
      'publishedAt': instance.publishedAt,
    };
