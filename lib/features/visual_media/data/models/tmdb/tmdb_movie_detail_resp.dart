import 'package:json_annotation/json_annotation.dart';

import 'tmdb_common.dart';

part 'tmdb_movie_detail_resp.g.dart';

/// tmdb 电影详情栏位
/// https://developer.themoviedb.org/reference/movie-details
///
@JsonSerializable(explicitToJson: true)
class TmdbMovieDetailResp {
  @JsonKey(name: 'adult')
  bool? adult;

  @JsonKey(name: 'backdrop_path')
  String? backdropPath;

  // 归属某个系列
  @JsonKey(name: 'belongs_to_collection')
  TmdbBelongsToCollection? belongsToCollection;

  @JsonKey(name: 'budget')
  int? budget;

  @JsonKey(name: 'genres')
  List<TmdbGenre>? genres;

  @JsonKey(name: 'homepage')
  String? homepage;

  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'imdb_id')
  String? imdbId;

  @JsonKey(name: 'origin_country')
  List<String>? originCountry;

  @JsonKey(name: 'original_language')
  String? originalLanguage;

  @JsonKey(name: 'original_title')
  String? originalTitle;

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

  @JsonKey(name: 'release_date')
  String? releaseDate;

  @JsonKey(name: 'revenue')
  int? revenue;

  @JsonKey(name: 'runtime')
  int? runtime;

  @JsonKey(name: 'spoken_languages')
  List<TmdbSpokenLanguage>? spokenLanguages;

  @JsonKey(name: 'status')
  String? status;

  @JsonKey(name: 'tagline')
  String? tagline;

  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'video')
  bool? video;

  @JsonKey(name: 'vote_average')
  double? voteAverage;

  @JsonKey(name: 'vote_count')
  int? voteCount;

  TmdbMovieDetailResp({
    this.adult,
    this.backdropPath,
    this.belongsToCollection,
    this.budget,
    this.genres,
    this.homepage,
    this.id,
    this.imdbId,
    this.originCountry,
    this.originalLanguage,
    this.originalTitle,
    this.overview,
    this.popularity,
    this.posterPath,
    this.productionCompanies,
    this.productionCountries,
    this.releaseDate,
    this.revenue,
    this.runtime,
    this.spokenLanguages,
    this.status,
    this.tagline,
    this.title,
    this.video,
    this.voteAverage,
    this.voteCount,
  });

  factory TmdbMovieDetailResp.fromJson(Map<String, dynamic> srcJson) =>
      _$TmdbMovieDetailRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$TmdbMovieDetailRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TmdbBelongsToCollection {
  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'poster_path')
  String? posterPath;

  @JsonKey(name: 'backdrop_path')
  String? backdropPath;

  TmdbBelongsToCollection({
    this.id,
    this.name,
    this.posterPath,
    this.backdropPath,
  });

  factory TmdbBelongsToCollection.fromJson(Map<String, dynamic> srcJson) =>
      _$TmdbBelongsToCollectionFromJson(srcJson);

  Map<String, dynamic> toJson() => _$TmdbBelongsToCollectionToJson(this);
}
