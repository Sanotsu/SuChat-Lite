// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tmdb_person_credit_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TmdbPersonCreditResp _$TmdbPersonCreditRespFromJson(
  Map<String, dynamic> json,
) => TmdbPersonCreditResp(
  cast: (json['cast'] as List<dynamic>?)
      ?.map((e) => TmdbResultItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  crew: (json['crew'] as List<dynamic>?)
      ?.map((e) => TmdbResultItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  id: (json['id'] as num?)?.toInt(),
);

Map<String, dynamic> _$TmdbPersonCreditRespToJson(
  TmdbPersonCreditResp instance,
) => <String, dynamic>{
  'id': instance.id,
  'cast': instance.cast?.map((e) => e.toJson()).toList(),
  'crew': instance.crew?.map((e) => e.toJson()).toList(),
};
