// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tmdb_mt_review_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TmdbMTReviewResp _$TmdbMTReviewRespFromJson(Map<String, dynamic> json) =>
    TmdbMTReviewResp(
      id: (json['id'] as num?)?.toInt(),
      page: (json['page'] as num?)?.toInt(),
      results: (json['results'] as List<dynamic>?)
          ?.map((e) => TmdbReviewItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPages: (json['total_pages'] as num?)?.toInt(),
      totalResults: (json['total_results'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TmdbMTReviewRespToJson(TmdbMTReviewResp instance) =>
    <String, dynamic>{
      'id': instance.id,
      'page': instance.page,
      'results': instance.results?.map((e) => e.toJson()).toList(),
      'total_pages': instance.totalPages,
      'total_results': instance.totalResults,
    };

TmdbReviewItem _$TmdbReviewItemFromJson(Map<String, dynamic> json) =>
    TmdbReviewItem(
      author: json['author'] as String?,
      authorDetails: json['author_details'] == null
          ? null
          : TmdbReviewAuthorDetail.fromJson(
              json['author_details'] as Map<String, dynamic>,
            ),
      content: json['content'] as String?,
      createdAt: json['created_at'] as String?,
      id: json['id'] as String?,
      updatedAt: json['updated_at'] as String?,
      url: json['url'] as String?,
    );

Map<String, dynamic> _$TmdbReviewItemToJson(TmdbReviewItem instance) =>
    <String, dynamic>{
      'author': instance.author,
      'author_details': instance.authorDetails?.toJson(),
      'content': instance.content,
      'created_at': instance.createdAt,
      'id': instance.id,
      'updated_at': instance.updatedAt,
      'url': instance.url,
    };

TmdbReviewAuthorDetail _$TmdbReviewAuthorDetailFromJson(
  Map<String, dynamic> json,
) => TmdbReviewAuthorDetail(
  name: json['name'] as String?,
  username: json['username'] as String?,
  avatarPath: json['avatar_path'] as String?,
  rating: (json['rating'] as num?)?.toInt(),
);

Map<String, dynamic> _$TmdbReviewAuthorDetailToJson(
  TmdbReviewAuthorDetail instance,
) => <String, dynamic>{
  'name': instance.name,
  'username': instance.username,
  'avatar_path': instance.avatarPath,
  'rating': instance.rating,
};
