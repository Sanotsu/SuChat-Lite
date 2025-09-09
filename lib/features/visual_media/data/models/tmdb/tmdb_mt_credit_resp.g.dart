// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tmdb_mt_credit_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TmdbMTCreditResp _$TmdbMTCreditRespFromJson(Map<String, dynamic> json) =>
    TmdbMTCreditResp(
      id: (json['id'] as num?)?.toInt(),
      cast: (json['cast'] as List<dynamic>?)
          ?.map((e) => TmdbCredit.fromJson(e as Map<String, dynamic>))
          .toList(),
      crew: (json['crew'] as List<dynamic>?)
          ?.map((e) => TmdbCredit.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TmdbMTCreditRespToJson(TmdbMTCreditResp instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cast': instance.cast?.map((e) => e.toJson()).toList(),
      'crew': instance.crew?.map((e) => e.toJson()).toList(),
    };

TmdbCredit _$TmdbCreditFromJson(Map<String, dynamic> json) => TmdbCredit(
  adult: json['adult'] as bool?,
  gender: (json['gender'] as num?)?.toInt(),
  id: (json['id'] as num?)?.toInt(),
  knownForDepartment: json['known_for_department'] as String?,
  name: json['name'] as String?,
  originalName: json['original_name'] as String?,
  popularity: (json['popularity'] as num?)?.toDouble(),
  profilePath: json['profile_path'] as String?,
  castId: (json['cast_id'] as num?)?.toInt(),
  character: json['character'] as String?,
  creditId: json['credit_id'] as String?,
  order: (json['order'] as num?)?.toInt(),
  department: json['department'] as String?,
  job: json['job'] as String?,
);

Map<String, dynamic> _$TmdbCreditToJson(TmdbCredit instance) =>
    <String, dynamic>{
      'adult': instance.adult,
      'gender': instance.gender,
      'id': instance.id,
      'known_for_department': instance.knownForDepartment,
      'name': instance.name,
      'original_name': instance.originalName,
      'popularity': instance.popularity,
      'profile_path': instance.profilePath,
      'cast_id': instance.castId,
      'character': instance.character,
      'credit_id': instance.creditId,
      'order': instance.order,
      'department': instance.department,
      'job': instance.job,
    };
