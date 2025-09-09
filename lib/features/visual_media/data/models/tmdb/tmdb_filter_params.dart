import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:tmdb_api/tmdb_api.dart';

part 'tmdb_filter_params.g.dart';

/// 电影筛选参数
@JsonSerializable(explicitToJson: true)
class MovieFilterParams {
  // 基础参数
  String? language;
  SortMoviesBy sortBy;
  int page;
  bool includeAdult;
  bool includeVideo;
  String? region;

  // 分级参数
  String? certificationCountry;
  String? certification;
  String? certificationLessThan;
  String? certificationGreaterThan;

  // 日期参数
  int? primaryReleaseYear;
  DateTime? primaryReleaseDateGreaterThan;
  DateTime? primaryReleaseDateLessThan;
  DateTime? releaseDateGreaterThan;
  DateTime? releaseDateLessThan;
  String? withReleaseType;
  int? year;

  // 评分参数
  int? voteCountGreaterThan;
  int? voteCountLessThan;
  double? voteAverageGreaterThan;
  double? voteAverageLessThan;

  // 人员参数
  List<int>? withCast;
  List<int>? withCrew;
  List<int>? withPeople;

  // 公司和类型参数
  List<int>? withCompanies;
  List<int>? withoutCompanies;
  List<int>? withGenres;
  List<int>? withoutGenres;

  // 关键词参数
  List<int>? withKeywords;
  List<int>? withoutKeywords;

  // 时长参数
  int? withRunTimeGreaterThan;
  int? withRuntimeLessThan;

  // 语言参数
  String? withOriginCountry;
  String? withOriginalLanguage;

  // 观看提供商参数
  List<int>? withWatchProviders;
  List<int>? withoutWatchProviders;
  String? watchRegion;
  String? withWatchMonetizationTypes;

  MovieFilterParams({
    this.language = 'zh-CN',
    this.sortBy = SortMoviesBy.popularityDesc,
    this.page = 1,
    this.includeAdult = false,
    this.includeVideo = false,
    this.region,
    this.certificationCountry,
    this.certification,
    this.certificationLessThan,
    this.certificationGreaterThan,
    this.primaryReleaseYear,
    this.primaryReleaseDateGreaterThan,
    this.primaryReleaseDateLessThan,
    this.releaseDateGreaterThan,
    this.releaseDateLessThan,
    this.withReleaseType,
    this.year,
    this.voteCountGreaterThan,
    this.voteCountLessThan,
    this.voteAverageGreaterThan,
    this.voteAverageLessThan,
    this.withCast,
    this.withCrew,
    this.withPeople,
    this.withCompanies,
    this.withoutCompanies,
    this.withGenres,
    this.withoutGenres,
    this.withKeywords,
    this.withoutKeywords,
    this.withRunTimeGreaterThan,
    this.withRuntimeLessThan,
    this.withOriginalLanguage,
    this.withOriginCountry,
    this.withWatchProviders,
    this.withoutWatchProviders,
    this.watchRegion,
    this.withWatchMonetizationTypes,
  });

  // 从字符串转
  factory MovieFilterParams.fromRawJson(String str) =>
      MovieFilterParams.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory MovieFilterParams.fromJson(Map<String, dynamic> srcJson) =>
      _$MovieFilterParamsFromJson(srcJson);

  Map<String, dynamic> toJson() => _$MovieFilterParamsToJson(this);

  MovieFilterParams copyWith({
    String? language,
    SortMoviesBy? sortBy,
    int? page,
    bool? includeAdult,
    bool? includeVideo,
    String? region,
    String? certificationCountry,
    String? certification,
    String? certificationLessThan,
    String? certificationGreaterThan,
    int? primaryReleaseYear,
    DateTime? primaryReleaseDateGreaterThan,
    DateTime? primaryReleaseDateLessThan,
    DateTime? releaseDateGreaterThan,
    DateTime? releaseDateLessThan,
    String? withReleaseType,
    int? year,
    int? voteCountGreaterThan,
    int? voteCountLessThan,
    double? voteAverageGreaterThan,
    double? voteAverageLessThan,
    List<int>? withCast,
    List<int>? withCrew,
    List<int>? withPeople,
    List<int>? withCompanies,
    List<int>? withoutCompanies,
    List<int>? withGenres,
    List<int>? withoutGenres,
    List<int>? withKeywords,
    List<int>? withoutKeywords,
    int? withRunTimeGreaterThan,
    int? withRuntimeLessThan,
    String? withOriginalLanguage,
    String? withOriginCountry,
    List<int>? withWatchProviders,
    List<int>? withoutWatchProviders,
    String? watchRegion,
    String? withWatchMonetizationTypes,
  }) {
    return MovieFilterParams(
      language: language ?? this.language,
      sortBy: sortBy ?? this.sortBy,
      page: page ?? this.page,
      includeAdult: includeAdult ?? this.includeAdult,
      includeVideo: includeVideo ?? this.includeVideo,
      region: region ?? this.region,
      certificationCountry: certificationCountry ?? this.certificationCountry,
      certification: certification ?? this.certification,
      certificationLessThan:
          certificationLessThan ?? this.certificationLessThan,
      certificationGreaterThan:
          certificationGreaterThan ?? this.certificationGreaterThan,
      primaryReleaseYear: primaryReleaseYear ?? this.primaryReleaseYear,
      primaryReleaseDateGreaterThan:
          primaryReleaseDateGreaterThan ?? this.primaryReleaseDateGreaterThan,
      primaryReleaseDateLessThan:
          primaryReleaseDateLessThan ?? this.primaryReleaseDateLessThan,
      releaseDateGreaterThan:
          releaseDateGreaterThan ?? this.releaseDateGreaterThan,
      releaseDateLessThan: releaseDateLessThan ?? this.releaseDateLessThan,
      withReleaseType: withReleaseType ?? this.withReleaseType,
      year: year ?? this.year,
      voteCountGreaterThan: voteCountGreaterThan ?? this.voteCountGreaterThan,
      voteCountLessThan: voteCountLessThan ?? this.voteCountLessThan,
      voteAverageGreaterThan:
          voteAverageGreaterThan ?? this.voteAverageGreaterThan,
      voteAverageLessThan: voteAverageLessThan ?? this.voteAverageLessThan,
      withCast: withCast ?? this.withCast,
      withCrew: withCrew ?? this.withCrew,
      withPeople: withPeople ?? this.withPeople,
      withCompanies: withCompanies ?? this.withCompanies,
      withoutCompanies: withoutCompanies ?? this.withoutCompanies,
      withGenres: withGenres ?? this.withGenres,
      withoutGenres: withoutGenres ?? this.withoutGenres,
      withKeywords: withKeywords ?? this.withKeywords,
      withoutKeywords: withoutKeywords ?? this.withoutKeywords,
      withRunTimeGreaterThan:
          withRunTimeGreaterThan ?? this.withRunTimeGreaterThan,
      withRuntimeLessThan: withRuntimeLessThan ?? this.withRuntimeLessThan,
      withOriginalLanguage: withOriginalLanguage ?? this.withOriginalLanguage,
      withOriginCountry: withOriginCountry ?? this.withOriginCountry,
      withWatchProviders: withWatchProviders ?? this.withWatchProviders,
      withoutWatchProviders:
          withoutWatchProviders ?? this.withoutWatchProviders,
      watchRegion: watchRegion ?? this.watchRegion,
      withWatchMonetizationTypes:
          withWatchMonetizationTypes ?? this.withWatchMonetizationTypes,
    );
  }

  /// 转换为API调用参数
  Map<String, dynamic> toApiParams() {
    final params = <String, dynamic>{
      'language': language,
      'sortBy': sortBy,
      'page': page,
      'includeAdult': includeAdult,
      'includeVideo': includeVideo,
    };

    if (region != null) params['region'] = region;
    if (certificationCountry != null) {
      params['certificationCountry'] = certificationCountry;
    }
    if (certification != null) params['certification'] = certification;
    if (certificationLessThan != null) {
      params['certificationLessThan'] = certificationLessThan;
    }
    if (certificationGreaterThan != null) {
      params['certificationGreaterThan'] = certificationGreaterThan;
    }
    if (primaryReleaseYear != null) {
      params['primaryReleaseYear'] = primaryReleaseYear;
    }
    if (primaryReleaseDateGreaterThan != null) {
      params['primaryReleaseDateGreaterThan'] = _formatDate(
        primaryReleaseDateGreaterThan!,
      );
    }
    if (primaryReleaseDateLessThan != null) {
      params['primaryReleaseDateLessThan'] = _formatDate(
        primaryReleaseDateLessThan!,
      );
    }
    if (releaseDateGreaterThan != null) {
      params['releaseDateGreaterThan'] = _formatDate(releaseDateGreaterThan!);
    }
    if (releaseDateLessThan != null) {
      params['releaseDateLessThan'] = _formatDate(releaseDateLessThan!);
    }
    if (withReleaseType != null) params['withReleaseType'] = withReleaseType;
    if (year != null) params['year'] = year;
    if (voteCountGreaterThan != null) {
      params['voteCountGreaterThan'] = voteCountGreaterThan;
    }
    if (voteCountLessThan != null) {
      params['voteCountLessThan'] = voteCountLessThan;
    }
    if (voteAverageGreaterThan != null) {
      params['voteAverageGreaterThan'] = voteAverageGreaterThan!.toInt();
    }
    if (voteAverageLessThan != null) {
      params['voteAverageLessThan'] = voteAverageLessThan!.toInt();
    }
    if (withCast != null && withCast!.isNotEmpty) {
      params['withCast'] = withCast!.join(',');
    }
    if (withCrew != null && withCrew!.isNotEmpty) {
      params['withCrew'] = withCrew!.join(',');
    }
    if (withPeople != null && withPeople!.isNotEmpty) {
      params['withPeople'] = withPeople!.join(',');
    }
    if (withCompanies != null && withCompanies!.isNotEmpty) {
      params['withCompanies'] = withCompanies!.join(',');
    }
    if (withoutCompanies != null && withoutCompanies!.isNotEmpty) {
      params['withoutCompanies'] = withoutCompanies!.join(',');
    }
    if (withGenres != null && withGenres!.isNotEmpty) {
      // 逗号是且(And)，竖线是或(Or),默认多选为或
      params['withGenres'] = withGenres!.join('|');
    }
    if (withoutGenres != null && withoutGenres!.isNotEmpty) {
      params['withoutGenres'] = withoutGenres!.join(',');
    }
    if (withKeywords != null && withKeywords!.isNotEmpty) {
      params['withKeywords'] = withKeywords!.join(',');
    }
    if (withoutKeywords != null && withoutKeywords!.isNotEmpty) {
      params['withoutKeywords'] = withoutKeywords!.join(',');
    }
    if (withRunTimeGreaterThan != null) {
      params['withRunTimeGreaterThan'] = withRunTimeGreaterThan;
    }
    if (withRuntimeLessThan != null) {
      params['withRuntimeLessThan'] = withRuntimeLessThan;
    }
    if (withOriginalLanguage != null) {
      params['withOrginalLanguage'] = withOriginalLanguage;
    }
    if (withOriginCountry != null) {
      params['withOriginCountry'] = withOriginCountry;
    }
    if (withWatchProviders != null && withWatchProviders!.isNotEmpty) {
      params['withWatchProviders'] = withWatchProviders!.join(',');
    }
    if (withoutWatchProviders != null && withoutWatchProviders!.isNotEmpty) {
      params['withoutWatchProviders'] = withoutWatchProviders!.join(',');
    }
    if (watchRegion != null) params['watchRegion'] = watchRegion;
    if (withWatchMonetizationTypes != null) {
      params['withWatchMonetizationTypes'] = withWatchMonetizationTypes;
    }

    return params;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// 电视剧筛选参数
@JsonSerializable(explicitToJson: true)
class TvFilterParams {
  // 基础参数
  String? language;
  SortTvShowsBy sortBy;
  int page;
  bool includeAdult;
  bool includeNullFirstAirDates;

  // 日期参数
  DateTime? airDateGte;
  DateTime? airDateLte;
  DateTime? firstAirDateGte;
  DateTime? firstAirDateLte;
  int? firstAirDateYear;
  String? timezone;

  // 评分参数
  double? voteAverageGte;
  double? voteAverageLte;
  int? voteCountGte;
  int? voteCountLte;

  // 类型和网络参数
  List<int>? withGenres;
  List<int>? withoutGenres;
  List<int>? withNetworks;

  // 时长参数
  int? withRuntimeGte;
  int? withRuntimeLte;

  // 语言参数
  String? withOriginalLanguage;
  String? withOriginCountry;

  // 关键词参数
  List<int>? withKeywords;
  List<int>? withoutKeywords;

  // 其他参数
  bool? screenedTheatrically;
  List<int>? withCompanies;
  List<int>? withoutCompanies;
  List<int>? withWatchProviders;
  List<int>? withoutWatchProviders;
  String? watchRegion;
  String? withWatchMonetizationTypes;
  FilterTvShowsByStatus? withStatus;
  FilterTvShowsByType? withType;

  TvFilterParams({
    this.language = 'zh-CN',
    this.sortBy = SortTvShowsBy.popularityDesc,
    this.page = 1,
    this.includeAdult = false,
    this.includeNullFirstAirDates = false,
    this.airDateGte,
    this.airDateLte,
    this.firstAirDateGte,
    this.firstAirDateLte,
    this.firstAirDateYear,
    this.timezone,
    this.voteAverageGte,
    this.voteAverageLte,
    this.voteCountGte,
    this.voteCountLte,
    this.withGenres,
    this.withoutGenres,
    this.withNetworks,
    this.withRuntimeGte,
    this.withRuntimeLte,
    this.withOriginalLanguage,
    this.withOriginCountry,
    this.withKeywords,
    this.withoutKeywords,
    this.screenedTheatrically,
    this.withCompanies,
    this.withoutCompanies,
    this.withWatchProviders,
    this.withoutWatchProviders,
    this.watchRegion,
    this.withWatchMonetizationTypes,
    this.withStatus,
    this.withType,
  });

  // 从字符串转
  factory TvFilterParams.fromRawJson(String str) =>
      TvFilterParams.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory TvFilterParams.fromJson(Map<String, dynamic> srcJson) =>
      _$TvFilterParamsFromJson(srcJson);

  Map<String, dynamic> toJson() => _$TvFilterParamsToJson(this);

  TvFilterParams copyWith({
    String? language,
    SortTvShowsBy? sortBy,
    int? page,
    bool? includeNullFirstAirDates,
    DateTime? airDateGte,
    DateTime? airDateLte,
    DateTime? firstAirDateGte,
    DateTime? firstAirDateLte,
    int? firstAirDateYear,
    String? timezone,
    double? voteAverageGte,
    double? voteAverageLte,
    int? voteCountGte,
    int? voteCountLte,
    List<int>? withGenres,
    List<int>? withoutGenres,
    List<int>? withNetworks,
    int? withRuntimeGte,
    int? withRuntimeLte,
    String? withOriginalLanguage,
    String? withOriginCountry,
    List<int>? withKeywords,
    List<int>? withoutKeywords,
    bool? screenedTheatrically,
    List<int>? withCompanies,
    List<int>? withoutCompanies,
    List<int>? withWatchProviders,
    List<int>? withoutWatchProviders,
    String? watchRegion,
    String? withWatchMonetizationTypes,
    FilterTvShowsByStatus? withStatus,
    FilterTvShowsByType? withType,
  }) {
    return TvFilterParams(
      language: language ?? this.language,
      sortBy: sortBy ?? this.sortBy,
      page: page ?? this.page,
      includeNullFirstAirDates:
          includeNullFirstAirDates ?? this.includeNullFirstAirDates,
      airDateGte: airDateGte ?? this.airDateGte,
      airDateLte: airDateLte ?? this.airDateLte,
      firstAirDateGte: firstAirDateGte ?? this.firstAirDateGte,
      firstAirDateLte: firstAirDateLte ?? this.firstAirDateLte,
      firstAirDateYear: firstAirDateYear ?? this.firstAirDateYear,
      timezone: timezone ?? this.timezone,
      voteAverageGte: voteAverageGte ?? this.voteAverageGte,
      voteAverageLte: voteAverageLte ?? this.voteAverageLte,
      voteCountGte: voteCountGte ?? this.voteCountGte,
      voteCountLte: voteCountLte ?? this.voteCountLte,
      withGenres: withGenres ?? this.withGenres,
      withoutGenres: withoutGenres ?? this.withoutGenres,
      withNetworks: withNetworks ?? this.withNetworks,
      withRuntimeGte: withRuntimeGte ?? this.withRuntimeGte,
      withRuntimeLte: withRuntimeLte ?? this.withRuntimeLte,
      withOriginalLanguage: withOriginalLanguage ?? this.withOriginalLanguage,
      withOriginCountry: withOriginCountry ?? this.withOriginCountry,
      withKeywords: withKeywords ?? this.withKeywords,
      withoutKeywords: withoutKeywords ?? this.withoutKeywords,
      screenedTheatrically: screenedTheatrically ?? this.screenedTheatrically,
      withCompanies: withCompanies ?? this.withCompanies,
      withoutCompanies: withoutCompanies ?? this.withoutCompanies,
      withWatchProviders: withWatchProviders ?? this.withWatchProviders,
      withoutWatchProviders:
          withoutWatchProviders ?? this.withoutWatchProviders,
      watchRegion: watchRegion ?? this.watchRegion,
      withWatchMonetizationTypes:
          withWatchMonetizationTypes ?? this.withWatchMonetizationTypes,
      withStatus: withStatus ?? this.withStatus,
      withType: withType ?? this.withType,
    );
  }

  /// 转换为API调用参数
  Map<String, dynamic> toApiParams() {
    final params = <String, dynamic>{
      'language': language,
      'sortBy': sortBy,
      'page': page,
      'includeAdult': includeAdult,
      'includeNullFirstAirDates': includeNullFirstAirDates,
    };

    if (airDateGte != null) params['airDateGte'] = _formatDate(airDateGte!);
    if (airDateLte != null) params['airDateLte'] = _formatDate(airDateLte!);
    if (firstAirDateGte != null) {
      params['firstAirDateGte'] = _formatDate(firstAirDateGte!);
    }
    if (firstAirDateLte != null) {
      params['firstAirDateLte'] = _formatDate(firstAirDateLte!);
    }
    if (firstAirDateYear != null) params['firstAirDateYear'] = firstAirDateYear;
    if (timezone != null) params['timezone'] = timezone;
    if (voteAverageGte != null) params['voteAverageGte'] = voteAverageGte;
    if (voteAverageLte != null) params['voteAverageLte'] = voteAverageLte;
    if (voteCountGte != null) params['voteCountGte'] = voteCountGte;
    if (voteCountLte != null) params['voteCountLte'] = voteCountLte;
    if (withGenres != null && withGenres!.isNotEmpty) {
      // 逗号是且(And)，竖线是或(Or),默认多选为或
      params['withGenres'] = withGenres!.join('|');
    }
    if (withoutGenres != null && withoutGenres!.isNotEmpty) {
      params['withoutGenres'] = withoutGenres!.join(',');
    }
    if (withNetworks != null && withNetworks!.isNotEmpty) {
      params['withNetworks'] = withNetworks!.join(',');
    }
    if (withRuntimeGte != null) params['withRuntimeGte'] = withRuntimeGte;
    if (withRuntimeLte != null) params['withRuntimeLte'] = withRuntimeLte;
    if (withOriginalLanguage != null) {
      params['withOrginalLanguage'] = withOriginalLanguage;
    }
    if (withOriginCountry != null) {
      params['withOriginCountry'] = withOriginCountry;
    }
    if (withKeywords != null && withKeywords!.isNotEmpty) {
      params['withKeywords'] = withKeywords!.join(',');
    }
    if (withoutKeywords != null && withoutKeywords!.isNotEmpty) {
      params['withoutKeywords'] = withoutKeywords!.join(',');
    }
    if (screenedTheatrically != null) {
      params['screenedTheatrically'] = screenedTheatrically;
    }
    if (withCompanies != null && withCompanies!.isNotEmpty) {
      params['withCompanies'] = withCompanies!.join(',');
    }
    if (withoutCompanies != null && withoutCompanies!.isNotEmpty) {
      params['withoutCompanies'] = withoutCompanies!.join(',');
    }
    if (withWatchProviders != null && withWatchProviders!.isNotEmpty) {
      params['withWatchProviders'] = withWatchProviders!.join(',');
    }
    if (withoutWatchProviders != null && withoutWatchProviders!.isNotEmpty) {
      params['withoutWatchProviders'] = withoutWatchProviders!.join(',');
    }
    if (watchRegion != null) params['watchRegion'] = watchRegion;
    if (withWatchMonetizationTypes != null) {
      params['withWatchMonetizationTypes'] = withWatchMonetizationTypes;
    }
    if (withStatus != null) params['withStatus'] = withStatus;
    if (withType != null) params['withType'] = withType;

    return params;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
