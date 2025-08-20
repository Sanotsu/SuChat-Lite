// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tmdb_result_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TmdbResultResp _$TmdbResultRespFromJson(Map<String, dynamic> json) =>
    TmdbResultResp(
      page: (json['page'] as num?)?.toInt(),
      results: (json['results'] as List<dynamic>?)
          ?.map((e) => TmdbResultItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPages: (json['total_pages'] as num?)?.toInt(),
      totalResults: (json['total_results'] as num?)?.toInt(),
      dates: json['dates'] == null
          ? null
          : TmdbMovieDate.fromJson(json['dates'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TmdbResultRespToJson(TmdbResultResp instance) =>
    <String, dynamic>{
      'page': instance.page,
      'results': instance.results?.map((e) => e.toJson()).toList(),
      'total_pages': instance.totalPages,
      'total_results': instance.totalResults,
      'dates': instance.dates?.toJson(),
    };

TmdbMovieDate _$TmdbMovieDateFromJson(Map<String, dynamic> json) =>
    TmdbMovieDate(
      maximum: json['maximum'] as String?,
      minimum: json['minimum'] as String?,
    );

Map<String, dynamic> _$TmdbMovieDateToJson(TmdbMovieDate instance) =>
    <String, dynamic>{'maximum': instance.maximum, 'minimum': instance.minimum};
