// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tmdb_filter_params.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MovieFilterParams _$MovieFilterParamsFromJson(
  Map<String, dynamic> json,
) => MovieFilterParams(
  language: json['language'] as String? ?? 'zh-CN',
  sortBy:
      $enumDecodeNullable(_$SortMoviesByEnumMap, json['sortBy']) ??
      SortMoviesBy.popularityDesc,
  page: (json['page'] as num?)?.toInt() ?? 1,
  includeAdult: json['includeAdult'] as bool? ?? false,
  includeVideo: json['includeVideo'] as bool? ?? false,
  region: json['region'] as String?,
  certificationCountry: json['certificationCountry'] as String?,
  certification: json['certification'] as String?,
  certificationLessThan: json['certificationLessThan'] as String?,
  certificationGreaterThan: json['certificationGreaterThan'] as String?,
  primaryReleaseYear: (json['primaryReleaseYear'] as num?)?.toInt(),
  primaryReleaseDateGreaterThan: json['primaryReleaseDateGreaterThan'] == null
      ? null
      : DateTime.parse(json['primaryReleaseDateGreaterThan'] as String),
  primaryReleaseDateLessThan: json['primaryReleaseDateLessThan'] == null
      ? null
      : DateTime.parse(json['primaryReleaseDateLessThan'] as String),
  releaseDateGreaterThan: json['releaseDateGreaterThan'] == null
      ? null
      : DateTime.parse(json['releaseDateGreaterThan'] as String),
  releaseDateLessThan: json['releaseDateLessThan'] == null
      ? null
      : DateTime.parse(json['releaseDateLessThan'] as String),
  withReleaseType: json['withReleaseType'] as String?,
  year: (json['year'] as num?)?.toInt(),
  voteCountGreaterThan: (json['voteCountGreaterThan'] as num?)?.toInt(),
  voteCountLessThan: (json['voteCountLessThan'] as num?)?.toInt(),
  voteAverageGreaterThan: (json['voteAverageGreaterThan'] as num?)?.toDouble(),
  voteAverageLessThan: (json['voteAverageLessThan'] as num?)?.toDouble(),
  withCast: (json['withCast'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  withCrew: (json['withCrew'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  withPeople: (json['withPeople'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  withCompanies: (json['withCompanies'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  withoutCompanies: (json['withoutCompanies'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  withGenres: (json['withGenres'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  withoutGenres: (json['withoutGenres'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  withKeywords: (json['withKeywords'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  withoutKeywords: (json['withoutKeywords'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  withRunTimeGreaterThan: (json['withRunTimeGreaterThan'] as num?)?.toInt(),
  withRuntimeLessThan: (json['withRuntimeLessThan'] as num?)?.toInt(),
  withOriginalLanguage: json['withOriginalLanguage'] as String?,
  withOriginCountry: json['withOriginCountry'] as String?,
  withWatchProviders: (json['withWatchProviders'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  withoutWatchProviders: (json['withoutWatchProviders'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  watchRegion: json['watchRegion'] as String?,
  withWatchMonetizationTypes: json['withWatchMonetizationTypes'] as String?,
);

Map<String, dynamic> _$MovieFilterParamsToJson(
  MovieFilterParams instance,
) => <String, dynamic>{
  'language': instance.language,
  'sortBy': _$SortMoviesByEnumMap[instance.sortBy]!,
  'page': instance.page,
  'includeAdult': instance.includeAdult,
  'includeVideo': instance.includeVideo,
  'region': instance.region,
  'certificationCountry': instance.certificationCountry,
  'certification': instance.certification,
  'certificationLessThan': instance.certificationLessThan,
  'certificationGreaterThan': instance.certificationGreaterThan,
  'primaryReleaseYear': instance.primaryReleaseYear,
  'primaryReleaseDateGreaterThan': instance.primaryReleaseDateGreaterThan
      ?.toIso8601String(),
  'primaryReleaseDateLessThan': instance.primaryReleaseDateLessThan
      ?.toIso8601String(),
  'releaseDateGreaterThan': instance.releaseDateGreaterThan?.toIso8601String(),
  'releaseDateLessThan': instance.releaseDateLessThan?.toIso8601String(),
  'withReleaseType': instance.withReleaseType,
  'year': instance.year,
  'voteCountGreaterThan': instance.voteCountGreaterThan,
  'voteCountLessThan': instance.voteCountLessThan,
  'voteAverageGreaterThan': instance.voteAverageGreaterThan,
  'voteAverageLessThan': instance.voteAverageLessThan,
  'withCast': instance.withCast,
  'withCrew': instance.withCrew,
  'withPeople': instance.withPeople,
  'withCompanies': instance.withCompanies,
  'withoutCompanies': instance.withoutCompanies,
  'withGenres': instance.withGenres,
  'withoutGenres': instance.withoutGenres,
  'withKeywords': instance.withKeywords,
  'withoutKeywords': instance.withoutKeywords,
  'withRunTimeGreaterThan': instance.withRunTimeGreaterThan,
  'withRuntimeLessThan': instance.withRuntimeLessThan,
  'withOriginCountry': instance.withOriginCountry,
  'withOriginalLanguage': instance.withOriginalLanguage,
  'withWatchProviders': instance.withWatchProviders,
  'withoutWatchProviders': instance.withoutWatchProviders,
  'watchRegion': instance.watchRegion,
  'withWatchMonetizationTypes': instance.withWatchMonetizationTypes,
};

const _$SortMoviesByEnumMap = {
  SortMoviesBy.popularityAsc: 'popularityAsc',
  SortMoviesBy.popularityDesc: 'popularityDesc',
  SortMoviesBy.releaseDateAsc: 'releaseDateAsc',
  SortMoviesBy.releaseDateDesc: 'releaseDateDesc',
  SortMoviesBy.revenueAsc: 'revenueAsc',
  SortMoviesBy.revenueDesc: 'revenueDesc',
  SortMoviesBy.primaryReleaseDateAsc: 'primaryReleaseDateAsc',
  SortMoviesBy.primaryReleaseDateDesc: 'primaryReleaseDateDesc',
  SortMoviesBy.orginalTitleAsc: 'orginalTitleAsc',
  SortMoviesBy.orginalTitleDesc: 'orginalTitleDesc',
  SortMoviesBy.voteAverageAsc: 'voteAverageAsc',
  SortMoviesBy.voteAverageDesc: 'voteAverageDesc',
  SortMoviesBy.voteCountAsc: 'voteCountAsc',
  SortMoviesBy.voteCountDesc: 'voteCountDesc',
};

TvFilterParams _$TvFilterParamsFromJson(
  Map<String, dynamic> json,
) => TvFilterParams(
  language: json['language'] as String? ?? 'zh-CN',
  sortBy:
      $enumDecodeNullable(_$SortTvShowsByEnumMap, json['sortBy']) ??
      SortTvShowsBy.popularityDesc,
  page: (json['page'] as num?)?.toInt() ?? 1,
  includeAdult: json['includeAdult'] as bool? ?? false,
  includeNullFirstAirDates: json['includeNullFirstAirDates'] as bool? ?? false,
  airDateGte: json['airDateGte'] == null
      ? null
      : DateTime.parse(json['airDateGte'] as String),
  airDateLte: json['airDateLte'] == null
      ? null
      : DateTime.parse(json['airDateLte'] as String),
  firstAirDateGte: json['firstAirDateGte'] == null
      ? null
      : DateTime.parse(json['firstAirDateGte'] as String),
  firstAirDateLte: json['firstAirDateLte'] == null
      ? null
      : DateTime.parse(json['firstAirDateLte'] as String),
  firstAirDateYear: (json['firstAirDateYear'] as num?)?.toInt(),
  timezone: json['timezone'] as String?,
  voteAverageGte: (json['voteAverageGte'] as num?)?.toDouble(),
  voteAverageLte: (json['voteAverageLte'] as num?)?.toDouble(),
  voteCountGte: (json['voteCountGte'] as num?)?.toInt(),
  voteCountLte: (json['voteCountLte'] as num?)?.toInt(),
  withGenres: (json['withGenres'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  withoutGenres: (json['withoutGenres'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  withNetworks: (json['withNetworks'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  withRuntimeGte: (json['withRuntimeGte'] as num?)?.toInt(),
  withRuntimeLte: (json['withRuntimeLte'] as num?)?.toInt(),
  withOriginalLanguage: json['withOriginalLanguage'] as String?,
  withOriginCountry: json['withOriginCountry'] as String?,
  withKeywords: (json['withKeywords'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  withoutKeywords: (json['withoutKeywords'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  screenedTheatrically: json['screenedTheatrically'] as bool?,
  withCompanies: (json['withCompanies'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  withoutCompanies: (json['withoutCompanies'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  withWatchProviders: (json['withWatchProviders'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  withoutWatchProviders: (json['withoutWatchProviders'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  watchRegion: json['watchRegion'] as String?,
  withWatchMonetizationTypes: json['withWatchMonetizationTypes'] as String?,
  withStatus: $enumDecodeNullable(
    _$FilterTvShowsByStatusEnumMap,
    json['withStatus'],
  ),
  withType: $enumDecodeNullable(_$FilterTvShowsByTypeEnumMap, json['withType']),
);

Map<String, dynamic> _$TvFilterParamsToJson(TvFilterParams instance) =>
    <String, dynamic>{
      'language': instance.language,
      'sortBy': _$SortTvShowsByEnumMap[instance.sortBy]!,
      'page': instance.page,
      'includeAdult': instance.includeAdult,
      'includeNullFirstAirDates': instance.includeNullFirstAirDates,
      'airDateGte': instance.airDateGte?.toIso8601String(),
      'airDateLte': instance.airDateLte?.toIso8601String(),
      'firstAirDateGte': instance.firstAirDateGte?.toIso8601String(),
      'firstAirDateLte': instance.firstAirDateLte?.toIso8601String(),
      'firstAirDateYear': instance.firstAirDateYear,
      'timezone': instance.timezone,
      'voteAverageGte': instance.voteAverageGte,
      'voteAverageLte': instance.voteAverageLte,
      'voteCountGte': instance.voteCountGte,
      'voteCountLte': instance.voteCountLte,
      'withGenres': instance.withGenres,
      'withoutGenres': instance.withoutGenres,
      'withNetworks': instance.withNetworks,
      'withRuntimeGte': instance.withRuntimeGte,
      'withRuntimeLte': instance.withRuntimeLte,
      'withOriginalLanguage': instance.withOriginalLanguage,
      'withOriginCountry': instance.withOriginCountry,
      'withKeywords': instance.withKeywords,
      'withoutKeywords': instance.withoutKeywords,
      'screenedTheatrically': instance.screenedTheatrically,
      'withCompanies': instance.withCompanies,
      'withoutCompanies': instance.withoutCompanies,
      'withWatchProviders': instance.withWatchProviders,
      'withoutWatchProviders': instance.withoutWatchProviders,
      'watchRegion': instance.watchRegion,
      'withWatchMonetizationTypes': instance.withWatchMonetizationTypes,
      'withStatus': _$FilterTvShowsByStatusEnumMap[instance.withStatus],
      'withType': _$FilterTvShowsByTypeEnumMap[instance.withType],
    };

const _$SortTvShowsByEnumMap = {
  SortTvShowsBy.voteAverageAsc: 'voteAverageAsc',
  SortTvShowsBy.voteAverageDesc: 'voteAverageDesc',
  SortTvShowsBy.popularityAsc: 'popularityAsc',
  SortTvShowsBy.popularityDesc: 'popularityDesc',
  SortTvShowsBy.firstAirDateAsc: 'firstAirDateAsc',
  SortTvShowsBy.firstAirDateDesc: 'firstAirDateDesc',
};

const _$FilterTvShowsByStatusEnumMap = {
  FilterTvShowsByStatus.returningSeries: 'returningSeries',
  FilterTvShowsByStatus.planned: 'planned',
  FilterTvShowsByStatus.inProduction: 'inProduction',
  FilterTvShowsByStatus.ended: 'ended',
  FilterTvShowsByStatus.cancelled: 'cancelled',
  FilterTvShowsByStatus.pilot: 'pilot',
};

const _$FilterTvShowsByTypeEnumMap = {
  FilterTvShowsByType.documentary: 'documentary',
  FilterTvShowsByType.news: 'news',
  FilterTvShowsByType.miniseries: 'miniseries',
  FilterTvShowsByType.reality: 'reality',
  FilterTvShowsByType.scripted: 'scripted',
  FilterTvShowsByType.talkShow: 'talkShow',
  FilterTvShowsByType.video: 'video',
};
