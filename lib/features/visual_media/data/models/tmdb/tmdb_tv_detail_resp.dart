import 'package:json_annotation/json_annotation.dart';

import 'tmdb_common.dart';

part 'tmdb_tv_detail_resp.g.dart';

/// tmdb 剧集详情栏位
/// https://developer.themoviedb.org/reference/tv-series-details
///
@JsonSerializable(explicitToJson: true)
class TmdbTvDetailResp {
  @JsonKey(name: 'adult')
  bool? adult;

  @JsonKey(name: 'backdrop_path')
  String? backdropPath;

  @JsonKey(name: 'created_by')
  List<TmdbCreatedBy>? createdBy;

  @JsonKey(name: 'episode_run_time')
  List<int>? episodeRunTime;

  @JsonKey(name: 'first_air_date')
  String? firstAirDate;

  //tv 的体裁类型
  @JsonKey(name: 'genres')
  List<TmdbGenre>? genres;

  @JsonKey(name: 'homepage')
  String? homepage;

  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'in_production')
  bool? inProduction;

  @JsonKey(name: 'languages')
  List<String>? languages;

  @JsonKey(name: 'last_air_date')
  String? lastAirDate;

  // 最新播放的一集
  @JsonKey(name: 'last_episode_to_air')
  TmdbLastEpisodeToAir? lastEpisodeToAir;

  @JsonKey(name: 'name')
  String? name;

  // 下一集播放信息
  @JsonKey(name: 'next_episode_to_air')
  TmdbLastEpisodeToAir? nextEpisodeToAir;

  // 网络平台的一些信息
  @JsonKey(name: 'networks')
  List<TmdbNetwork>? networks;

  @JsonKey(name: 'number_of_episodes')
  int? numberOfEpisodes;

  @JsonKey(name: 'number_of_seasons')
  int? numberOfSeasons;

  @JsonKey(name: 'origin_country')
  List<String>? originCountry;

  @JsonKey(name: 'original_language')
  String? originalLanguage;

  @JsonKey(name: 'original_name')
  String? originalName;

  @JsonKey(name: 'overview')
  String? overview;

  @JsonKey(name: 'popularity')
  double? popularity;

  @JsonKey(name: 'poster_path')
  String? posterPath;

  @JsonKey(name: 'production_companies')
  List<TmdbProductionCompany>? productionCompanies;

  @JsonKey(name: 'production_countries')
  List<TmdbProductionCountry>? productionCountries;

  // 剧集每季的信息
  @JsonKey(name: 'seasons')
  List<TmdbSeason>? seasons;

  // 剧集语言
  @JsonKey(name: 'spoken_languages')
  List<TmdbSpokenLanguage>? spokenLanguages;

  // 剧集状态
  @JsonKey(name: 'status')
  String? status;

  // 剧集标语
  @JsonKey(name: 'tagline')
  String? tagline;

  @JsonKey(name: 'type')
  String? type;

  @JsonKey(name: 'vote_average')
  double? voteAverage;

  @JsonKey(name: 'vote_count')
  int? voteCount;

  TmdbTvDetailResp({
    this.adult,
    this.backdropPath,
    this.createdBy,
    this.episodeRunTime,
    this.firstAirDate,
    this.genres,
    this.homepage,
    this.id,
    this.inProduction,
    this.languages,
    this.lastAirDate,
    this.lastEpisodeToAir,
    this.name,
    this.networks,
    this.numberOfEpisodes,
    this.numberOfSeasons,
    this.originCountry,
    this.originalLanguage,
    this.originalName,
    this.overview,
    this.popularity,
    this.posterPath,
    this.productionCompanies,
    this.productionCountries,
    this.seasons,
    this.spokenLanguages,
    this.status,
    this.tagline,
    this.type,
    this.voteAverage,
    this.voteCount,
  });

  factory TmdbTvDetailResp.fromJson(Map<String, dynamic> srcJson) =>
      _$TmdbTvDetailRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$TmdbTvDetailRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TmdbCreatedBy {
  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'credit_id')
  String? creditId;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'original_name')
  String? originalName;

  @JsonKey(name: 'gender')
  int? gender;

  @JsonKey(name: 'profile_path')
  String? profilePath;

  TmdbCreatedBy({
    this.id,
    this.creditId,
    this.name,
    this.originalName,
    this.gender,
    this.profilePath,
  });

  factory TmdbCreatedBy.fromJson(Map<String, dynamic> srcJson) =>
      _$TmdbCreatedByFromJson(srcJson);

  Map<String, dynamic> toJson() => _$TmdbCreatedByToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TmdbLastEpisodeToAir {
  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'overview')
  String? overview;

  @JsonKey(name: 'vote_average')
  double? voteAverage;

  @JsonKey(name: 'vote_count')
  int? voteCount;

  @JsonKey(name: 'air_date')
  String? airDate;

  @JsonKey(name: 'episode_number')
  int? episodeNumber;

  @JsonKey(name: 'episode_type')
  String? episodeType;

  @JsonKey(name: 'production_code')
  String? productionCode;

  @JsonKey(name: 'runtime')
  int? runtime;

  @JsonKey(name: 'season_number')
  int? seasonNumber;

  @JsonKey(name: 'show_id')
  int? showId;

  @JsonKey(name: 'still_path')
  String? stillPath;

  TmdbLastEpisodeToAir({
    this.id,
    this.name,
    this.overview,
    this.voteAverage,
    this.voteCount,
    this.airDate,
    this.episodeNumber,
    this.episodeType,
    this.productionCode,
    this.runtime,
    this.seasonNumber,
    this.showId,
    this.stillPath,
  });

  factory TmdbLastEpisodeToAir.fromJson(Map<String, dynamic> srcJson) =>
      _$TmdbLastEpisodeToAirFromJson(srcJson);

  Map<String, dynamic> toJson() => _$TmdbLastEpisodeToAirToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TmdbNetwork {
  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'logo_path')
  String? logoPath;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'origin_country')
  String? originCountry;

  TmdbNetwork({this.id, this.logoPath, this.name, this.originCountry});

  factory TmdbNetwork.fromJson(Map<String, dynamic> srcJson) =>
      _$TmdbNetworkFromJson(srcJson);

  Map<String, dynamic> toJson() => _$TmdbNetworkToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TmdbSeason {
  @JsonKey(name: 'air_date')
  String? airDate;

  @JsonKey(name: 'episode_count')
  int? episodeCount;

  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'overview')
  String? overview;

  @JsonKey(name: 'poster_path')
  String? posterPath;

  @JsonKey(name: 'season_number')
  int? seasonNumber;

  @JsonKey(name: 'vote_average')
  double? voteAverage;

  TmdbSeason({
    this.airDate,
    this.episodeCount,
    this.id,
    this.name,
    this.overview,
    this.posterPath,
    this.seasonNumber,
    this.voteAverage,
  });

  factory TmdbSeason.fromJson(Map<String, dynamic> srcJson) =>
      _$TmdbSeasonFromJson(srcJson);

  Map<String, dynamic> toJson() => _$TmdbSeasonToJson(this);
}
