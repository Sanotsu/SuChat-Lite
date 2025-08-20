import 'package:json_annotation/json_annotation.dart';

part 'tmdb_common.g.dart';

///
/// tmdb 各种复用的类型
///
/// 有用到的，或者强行合并到一起的接口
/// trending 和 search 的 results 栏位
/// movie/tv 的 recommendations 和 similar 的 results 栏位
/// person 的 tv_credits movie_credits combined_credits 的cast和crew栏位
///
/// tv movie person 各自的栏位有稍微不同，但整合在一起
@JsonSerializable(explicitToJson: true)
class TmdbResultItem {
  // 这个时all时存在的栏位
  @JsonKey(name: 'adult')
  bool? adult;

  @JsonKey(name: 'backdrop_path')
  String? backdropPath;

  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'original_name')
  String? originalName;

  @JsonKey(name: 'overview')
  String? overview;

  @JsonKey(name: 'poster_path')
  String? posterPath;

  @JsonKey(name: 'media_type')
  String? mediaType;

  @JsonKey(name: 'original_language')
  String? originalLanguage;

  @JsonKey(name: 'genre_ids')
  List<int>? genreIds;

  @JsonKey(name: 'popularity')
  double? popularity;

  @JsonKey(name: 'first_air_date')
  String? firstAirDate;

  @JsonKey(name: 'vote_average')
  double? voteAverage;

  @JsonKey(name: 'vote_count')
  int? voteCount;

  @JsonKey(name: 'origin_country')
  List<String>? originCountry;

  // 这几个是单独 person movie tv 时其他的栏位
  @JsonKey(name: 'gender')
  int? gender;

  @JsonKey(name: 'known_for_department')
  String? knownForDepartment;

  @JsonKey(name: 'profile_path')
  String? profilePath;

  // tv person 是name ， movie 是title
  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'original_title')
  String? originalTitle;

  @JsonKey(name: 'release_date')
  String? releaseDate;

  @JsonKey(name: 'video')
  bool? video;

  // 在搜索时，针对person，会有一个known_for栏位，内容就是这个item部分属性
  @JsonKey(name: 'known_for')
  List<TmdbResultItem>? knownFor;

  // person 的 tv_credits 的 cast 还有的栏位:
  // character credit_id episode_count first_credit_air_date
  // person 的 movie_credits 的 cast 还有的栏位:
  // character credit_id order
  @JsonKey(name: 'character')
  String? character;

  @JsonKey(name: 'credit_id')
  String? creditId;

  @JsonKey(name: 'order')
  int? order;

  @JsonKey(name: 'episode_count')
  int? episodeCount;

  @JsonKey(name: 'first_credit_air_date')
  String? firstCreditAirDate;

  // person 的 movie_credits 和 tv_credits 的 crew 还有的栏位：
  // credit_id  department job
  @JsonKey(name: 'department')
  String? department;

  @JsonKey(name: 'job')
  String? job;

  TmdbResultItem({
    this.adult,
    this.backdropPath,
    this.id,
    this.name,
    this.originalName,
    this.overview,
    this.posterPath,
    this.mediaType,
    this.originalLanguage,
    this.genreIds,
    this.popularity,
    this.firstAirDate,
    this.voteAverage,
    this.voteCount,
    this.originCountry,
    this.gender,
    this.knownForDepartment,
    this.profilePath,
    this.title,
    this.originalTitle,
    this.releaseDate,
    this.video,
    this.knownFor,
    this.character,
    this.creditId,
    this.order,
    this.episodeCount,
    this.firstCreditAirDate,
    this.department,
    this.job,
  });

  factory TmdbResultItem.fromJson(Map<String, dynamic> srcJson) =>
      _$TmdbResultItemFromJson(srcJson);

  Map<String, dynamic> toJson() => _$TmdbResultItemToJson(this);
}

/// movie tv 详情都有这几个属性
/// 题材 发行公司 发行国家 语言
@JsonSerializable(explicitToJson: true)
class TmdbGenre {
  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'name')
  String? name;

  TmdbGenre({this.id, this.name});

  factory TmdbGenre.fromJson(Map<String, dynamic> srcJson) =>
      _$TmdbGenreFromJson(srcJson);

  Map<String, dynamic> toJson() => _$TmdbGenreToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TmdbProductionCompany {
  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'logo_path')
  String? logoPath;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'origin_country')
  String? originCountry;

  TmdbProductionCompany({
    this.id,
    this.logoPath,
    this.name,
    this.originCountry,
  });

  factory TmdbProductionCompany.fromJson(Map<String, dynamic> srcJson) =>
      _$TmdbProductionCompanyFromJson(srcJson);

  Map<String, dynamic> toJson() => _$TmdbProductionCompanyToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TmdbProductionCountry {
  @JsonKey(name: 'iso_3166_1')
  String? iso31661;

  @JsonKey(name: 'name')
  String? name;

  TmdbProductionCountry({this.iso31661, this.name});

  factory TmdbProductionCountry.fromJson(Map<String, dynamic> srcJson) =>
      _$TmdbProductionCountryFromJson(srcJson);

  Map<String, dynamic> toJson() => _$TmdbProductionCountryToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TmdbSpokenLanguage {
  @JsonKey(name: 'english_name')
  String? englishName;

  @JsonKey(name: 'iso_639_1')
  String? iso6391;

  @JsonKey(name: 'name')
  String? name;

  TmdbSpokenLanguage({this.englishName, this.iso6391, this.name});

  factory TmdbSpokenLanguage.fromJson(Map<String, dynamic> srcJson) =>
      _$TmdbSpokenLanguageFromJson(srcJson);

  Map<String, dynamic> toJson() => _$TmdbSpokenLanguageToJson(this);
}

// movie tv person 图片的结构都一样
@JsonSerializable(explicitToJson: true)
class TmdbImageItem {
  @JsonKey(name: 'aspect_ratio')
  double? aspectRatio;

  @JsonKey(name: 'height')
  int? height;

  @JsonKey(name: 'iso_639_1')
  String? iso6391;

  @JsonKey(name: 'file_path')
  String? filePath;

  @JsonKey(name: 'vote_average')
  double? voteAverage;

  @JsonKey(name: 'vote_count')
  int? voteCount;

  @JsonKey(name: 'width')
  int? width;

  TmdbImageItem({
    this.aspectRatio,
    this.height,
    this.iso6391,
    this.filePath,
    this.voteAverage,
    this.voteCount,
    this.width,
  });

  factory TmdbImageItem.fromJson(Map<String, dynamic> srcJson) =>
      _$TmdbImageItemFromJson(srcJson);

  Map<String, dynamic> toJson() => _$TmdbImageItemToJson(this);
}
