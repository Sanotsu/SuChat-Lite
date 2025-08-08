// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jiqizhixin_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JiqizhixinResp _$JiqizhixinRespFromJson(Map<String, dynamic> json) =>
    JiqizhixinResp(
      json['success'] as bool?,
      (json['articles'] as List<dynamic>?)
          ?.map((e) => JiqizhixinArticle.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      (json['totalCount'] as num?)?.toInt(),
      json['hasNextPage'] as bool?,
      (json['publishedArticlesCount'] as num?)?.toInt(),
      (json['elapsedDays'] as num?)?.toInt(),
    );

Map<String, dynamic> _$JiqizhixinRespToJson(JiqizhixinResp instance) =>
    <String, dynamic>{
      'success': instance.success,
      'articles': instance.articles?.map((e) => e.toJson()).toList(),
      'tags': instance.tags,
      'totalCount': instance.totalCount,
      'hasNextPage': instance.hasNextPage,
      'publishedArticlesCount': instance.publishedArticlesCount,
      'elapsedDays': instance.elapsedDays,
    };

JiqizhixinArticle _$JiqizhixinArticleFromJson(Map<String, dynamic> json) =>
    JiqizhixinArticle(
      json['id'] as String?,
      json['title'] as String?,
      json['coverImageUrl'] as String?,
      json['category'] as String?,
      json['slug'] as String?,
      (json['tagList'] as List<dynamic>?)?.map((e) => e as String).toList(),
      json['author'] as String?,
      json['publishedAt'] as String?,
      json['content'] as String?,
      json['source'] as String?,
    );

Map<String, dynamic> _$JiqizhixinArticleToJson(JiqizhixinArticle instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'coverImageUrl': instance.coverImageUrl,
      'category': instance.category,
      'slug': instance.slug,
      'tagList': instance.tagList,
      'author': instance.author,
      'publishedAt': instance.publishedAt,
      'content': instance.content,
      'source': instance.source,
    };
