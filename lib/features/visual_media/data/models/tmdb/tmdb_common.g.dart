// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tmdb_common.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TmdbResultItem _$TmdbResultItemFromJson(Map<String, dynamic> json) =>
    TmdbResultItem(
      adult: json['adult'] as bool?,
      backdropPath: json['backdrop_path'] as String?,
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      originalName: json['original_name'] as String?,
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      mediaType: json['media_type'] as String?,
      originalLanguage: json['original_language'] as String?,
      genreIds: (json['genre_ids'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      popularity: (json['popularity'] as num?)?.toDouble(),
      firstAirDate: json['first_air_date'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      voteCount: (json['vote_count'] as num?)?.toInt(),
      originCountry: (json['origin_country'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      gender: (json['gender'] as num?)?.toInt(),
      knownForDepartment: json['known_for_department'] as String?,
      profilePath: json['profile_path'] as String?,
      title: json['title'] as String?,
      originalTitle: json['original_title'] as String?,
      releaseDate: json['release_date'] as String?,
      video: json['video'] as bool?,
      knownFor: (json['known_for'] as List<dynamic>?)
          ?.map((e) => TmdbResultItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      character: json['character'] as String?,
      creditId: json['credit_id'] as String?,
      order: (json['order'] as num?)?.toInt(),
      episodeCount: (json['episode_count'] as num?)?.toInt(),
      firstCreditAirDate: json['first_credit_air_date'] as String?,
      department: json['department'] as String?,
      job: json['job'] as String?,
    );

Map<String, dynamic> _$TmdbResultItemToJson(TmdbResultItem instance) =>
    <String, dynamic>{
      'adult': instance.adult,
      'backdrop_path': instance.backdropPath,
      'id': instance.id,
      'name': instance.name,
      'original_name': instance.originalName,
      'overview': instance.overview,
      'poster_path': instance.posterPath,
      'media_type': instance.mediaType,
      'original_language': instance.originalLanguage,
      'genre_ids': instance.genreIds,
      'popularity': instance.popularity,
      'first_air_date': instance.firstAirDate,
      'vote_average': instance.voteAverage,
      'vote_count': instance.voteCount,
      'origin_country': instance.originCountry,
      'gender': instance.gender,
      'known_for_department': instance.knownForDepartment,
      'profile_path': instance.profilePath,
      'title': instance.title,
      'original_title': instance.originalTitle,
      'release_date': instance.releaseDate,
      'video': instance.video,
      'known_for': instance.knownFor?.map((e) => e.toJson()).toList(),
      'character': instance.character,
      'credit_id': instance.creditId,
      'order': instance.order,
      'episode_count': instance.episodeCount,
      'first_credit_air_date': instance.firstCreditAirDate,
      'department': instance.department,
      'job': instance.job,
    };

TmdbGenre _$TmdbGenreFromJson(Map<String, dynamic> json) =>
    TmdbGenre(id: (json['id'] as num?)?.toInt(), name: json['name'] as String?);

Map<String, dynamic> _$TmdbGenreToJson(TmdbGenre instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
};

TmdbProductionCompany _$TmdbProductionCompanyFromJson(
  Map<String, dynamic> json,
) => TmdbProductionCompany(
  id: (json['id'] as num?)?.toInt(),
  logoPath: json['logo_path'] as String?,
  name: json['name'] as String?,
  originCountry: json['origin_country'] as String?,
);

Map<String, dynamic> _$TmdbProductionCompanyToJson(
  TmdbProductionCompany instance,
) => <String, dynamic>{
  'id': instance.id,
  'logo_path': instance.logoPath,
  'name': instance.name,
  'origin_country': instance.originCountry,
};

TmdbProductionCountry _$TmdbProductionCountryFromJson(
  Map<String, dynamic> json,
) => TmdbProductionCountry(
  iso31661: json['iso_3166_1'] as String?,
  name: json['name'] as String?,
);

Map<String, dynamic> _$TmdbProductionCountryToJson(
  TmdbProductionCountry instance,
) => <String, dynamic>{'iso_3166_1': instance.iso31661, 'name': instance.name};

TmdbSpokenLanguage _$TmdbSpokenLanguageFromJson(Map<String, dynamic> json) =>
    TmdbSpokenLanguage(
      englishName: json['english_name'] as String?,
      iso6391: json['iso_639_1'] as String?,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$TmdbSpokenLanguageToJson(TmdbSpokenLanguage instance) =>
    <String, dynamic>{
      'english_name': instance.englishName,
      'iso_639_1': instance.iso6391,
      'name': instance.name,
    };

TmdbImageItem _$TmdbImageItemFromJson(Map<String, dynamic> json) =>
    TmdbImageItem(
      aspectRatio: (json['aspect_ratio'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toInt(),
      iso6391: json['iso_639_1'] as String?,
      filePath: json['file_path'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      voteCount: (json['vote_count'] as num?)?.toInt(),
      width: (json['width'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TmdbImageItemToJson(TmdbImageItem instance) =>
    <String, dynamic>{
      'aspect_ratio': instance.aspectRatio,
      'height': instance.height,
      'iso_639_1': instance.iso6391,
      'file_path': instance.filePath,
      'vote_average': instance.voteAverage,
      'vote_count': instance.voteCount,
      'width': instance.width,
    };
