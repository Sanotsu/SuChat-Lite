// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'uo_toutiao_news_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UoToutiaoNewsResp _$UoToutiaoNewsRespFromJson(Map<String, dynamic> json) =>
    UoToutiaoNewsResp(
      json['has_more'] as bool?,
      json['message'] as String?,
      (json['data'] as List<dynamic>?)
          ?.map((e) => UoToutiaoNews.fromJson(e as Map<String, dynamic>))
          .toList(),
      json['next'] == null
          ? null
          : UoToutiaoNewsNext.fromJson(json['next'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UoToutiaoNewsRespToJson(UoToutiaoNewsResp instance) =>
    <String, dynamic>{
      'has_more': instance.hasMore,
      'message': instance.message,
      'data': instance.data?.map((e) => e.toJson()).toList(),
      'next': instance.next?.toJson(),
    };

UoToutiaoNews _$UoToutiaoNewsFromJson(Map<String, dynamic> json) =>
    UoToutiaoNews(
      json['media_avatar_url'] as String?,
      json['is_feed_ad'] as bool?,
      json['tag_url'] as String?,
      json['title'] as String?,
      json['single_mode'] as bool?,
      json['abstract'] as String?,
      json['middle_mode'] as bool?,
      (json['behot_time'] as num?)?.toInt(),
      json['source_url'] as String?,
      json['source'] as String?,
      json['more_mode'] as bool?,
      json['article_genre'] as String?,
      (json['comments_count'] as num?)?.toInt(),
      json['is_stick'] as bool?,
      (json['group_source'] as num?)?.toInt(),
      json['item_id'] as String?,
      json['has_gallery'] as bool?,
      json['group_id'] as String?,
      json['media_url'] as String?,
    );

Map<String, dynamic> _$UoToutiaoNewsToJson(UoToutiaoNews instance) =>
    <String, dynamic>{
      'media_avatar_url': instance.mediaAvatarUrl,
      'is_feed_ad': instance.isFeedAd,
      'tag_url': instance.tagUrl,
      'title': instance.title,
      'single_mode': instance.singleMode,
      'abstract': instance.abstract,
      'middle_mode': instance.middleMode,
      'behot_time': instance.behotTime,
      'source_url': instance.sourceUrl,
      'source': instance.source,
      'more_mode': instance.moreMode,
      'article_genre': instance.articleGenre,
      'comments_count': instance.commentsCount,
      'is_stick': instance.isStick,
      'group_source': instance.groupSource,
      'item_id': instance.itemId,
      'has_gallery': instance.hasGallery,
      'group_id': instance.groupId,
      'media_url': instance.mediaUrl,
    };

UoToutiaoNewsNext _$UoToutiaoNewsNextFromJson(Map<String, dynamic> json) =>
    UoToutiaoNewsNext((json['max_behot_time'] as num?)?.toInt());

Map<String, dynamic> _$UoToutiaoNewsNextToJson(UoToutiaoNewsNext instance) =>
    <String, dynamic>{'max_behot_time': instance.maxBehotTime};
