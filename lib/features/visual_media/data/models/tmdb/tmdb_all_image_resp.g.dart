// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tmdb_all_image_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TmdbAllImageResp _$TmdbAllImageRespFromJson(Map<String, dynamic> json) =>
    TmdbAllImageResp(
      backdrops: (json['backdrops'] as List<dynamic>?)
          ?.map((e) => TmdbImageItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      id: (json['id'] as num?)?.toInt(),
      logos: (json['logos'] as List<dynamic>?)
          ?.map((e) => TmdbImageItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      posters: (json['posters'] as List<dynamic>?)
          ?.map((e) => TmdbImageItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      profiles: (json['profiles'] as List<dynamic>?)
          ?.map((e) => TmdbImageItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TmdbAllImageRespToJson(TmdbAllImageResp instance) =>
    <String, dynamic>{
      'id': instance.id,
      'backdrops': instance.backdrops?.map((e) => e.toJson()).toList(),
      'logos': instance.logos?.map((e) => e.toJson()).toList(),
      'posters': instance.posters?.map((e) => e.toJson()).toList(),
      'profiles': instance.profiles?.map((e) => e.toJson()).toList(),
    };
