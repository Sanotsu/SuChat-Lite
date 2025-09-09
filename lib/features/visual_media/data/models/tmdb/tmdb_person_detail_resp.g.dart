// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tmdb_person_detail_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TmdbPersonDetailResp _$TmdbPersonDetailRespFromJson(
  Map<String, dynamic> json,
) => TmdbPersonDetailResp(
  adult: json['adult'] as bool?,
  alsoKnownAs: (json['also_known_as'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  biography: json['biography'] as String?,
  birthday: json['birthday'] as String?,
  gender: (json['gender'] as num?)?.toInt(),
  id: (json['id'] as num?)?.toInt(),
  imdbId: json['imdb_id'] as String?,
  knownForDepartment: json['known_for_department'] as String?,
  name: json['name'] as String?,
  placeOfBirth: json['place_of_birth'] as String?,
  popularity: (json['popularity'] as num?)?.toDouble(),
  profilePath: json['profile_path'] as String?,
);

Map<String, dynamic> _$TmdbPersonDetailRespToJson(
  TmdbPersonDetailResp instance,
) => <String, dynamic>{
  'adult': instance.adult,
  'also_known_as': instance.alsoKnownAs,
  'biography': instance.biography,
  'birthday': instance.birthday,
  'gender': instance.gender,
  'id': instance.id,
  'imdb_id': instance.imdbId,
  'known_for_department': instance.knownForDepartment,
  'name': instance.name,
  'place_of_birth': instance.placeOfBirth,
  'popularity': instance.popularity,
  'profile_path': instance.profilePath,
};
