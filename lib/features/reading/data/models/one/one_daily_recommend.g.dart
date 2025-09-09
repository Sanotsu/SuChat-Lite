// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'one_daily_recommend.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OneRecommend _$OneRecommendFromJson(Map<String, dynamic> json) => OneRecommend(
  id: json['id'] as String?,
  weather: json['weather'] == null
      ? null
      : OneWeather.fromJson(json['weather'] as Map<String, dynamic>),
  date: json['date'] as String?,
  contentList: (json['content_list'] as List<dynamic>?)
      ?.map((e) => OneRecommendContent.fromJson(e as Map<String, dynamic>))
      .toList(),
  menu: json['menu'] == null
      ? null
      : OneRecommendMenu.fromJson(json['menu'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OneRecommendToJson(OneRecommend instance) =>
    <String, dynamic>{
      'id': instance.id,
      'weather': instance.weather?.toJson(),
      'date': instance.date,
      'content_list': instance.contentList?.map((e) => e.toJson()).toList(),
      'menu': instance.menu?.toJson(),
    };

OneRecommendContent _$OneRecommendContentFromJson(Map<String, dynamic> json) =>
    OneRecommendContent(
      id: json['id'] as String?,
      category: json['category'] as String?,
      displayCategory: (json['display_category'] as num?)?.toInt(),
      itemId: json['item_id'] as String?,
      title: json['title'] as String?,
      forward: json['forward'] as String?,
      imgUrl: json['img_url'] as String?,
      picIpX: json['pic_ipX'] as String?,
      likeCount: (json['like_count'] as num?)?.toInt(),
      postDate: json['post_date'] as String?,
      lastUpdateDate: json['last_update_date'] as String?,
      author: json['author'] == null
          ? null
          : OneAuthor.fromJson(json['author'] as Map<String, dynamic>),
      videoUrl: json['video_url'] as String?,
      audioUrl: json['audio_url'] as String?,
      audioPlatform: (json['audio_platform'] as num?)?.toInt(),
      startVideo: json['start_video'] as String?,
      hasReading: (json['has_reading'] as num?)?.toInt(),
      volume: json['volume'],
      picInfo: json['pic_info'] as String?,
      wordsInfo: json['words_info'] as String?,
      textAuthorInfo: json['text_author_info'] == null
          ? null
          : OneTextAuthorInfo.fromJson(
              json['text_author_info'] as Map<String, dynamic>,
            ),
      subtitle: json['subtitle'] as String?,
      number: json['number'],
      serialId: json['serial_id'],
      serialList: json['serial_list'] as List<dynamic>?,
      movieStoryId: (json['movie_story_id'] as num?)?.toInt(),
      contentId: json['content_id'] as String?,
      contentType: json['content_type'] as String?,
      contentBgcolor: json['content_bgcolor'] as String?,
      tagList: (json['tag_list'] as List<dynamic>?)
          ?.map((e) => OneTag.fromJson(e as Map<String, dynamic>))
          .toList(),
      orientation: json['orientation'] as String?,
    );

Map<String, dynamic> _$OneRecommendContentToJson(
  OneRecommendContent instance,
) => <String, dynamic>{
  'id': instance.id,
  'category': instance.category,
  'display_category': instance.displayCategory,
  'item_id': instance.itemId,
  'title': instance.title,
  'forward': instance.forward,
  'img_url': instance.imgUrl,
  'pic_ipX': instance.picIpX,
  'like_count': instance.likeCount,
  'post_date': instance.postDate,
  'last_update_date': instance.lastUpdateDate,
  'author': instance.author?.toJson(),
  'video_url': instance.videoUrl,
  'audio_url': instance.audioUrl,
  'audio_platform': instance.audioPlatform,
  'start_video': instance.startVideo,
  'has_reading': instance.hasReading,
  'volume': instance.volume,
  'pic_info': instance.picInfo,
  'words_info': instance.wordsInfo,
  'text_author_info': instance.textAuthorInfo?.toJson(),
  'subtitle': instance.subtitle,
  'number': instance.number,
  'serial_id': instance.serialId,
  'serial_list': instance.serialList,
  'movie_story_id': instance.movieStoryId,
  'content_id': instance.contentId,
  'content_type': instance.contentType,
  'content_bgcolor': instance.contentBgcolor,
  'tag_list': instance.tagList?.map((e) => e.toJson()).toList(),
  'orientation': instance.orientation,
};

OneTextAuthorInfo _$OneTextAuthorInfoFromJson(Map<String, dynamic> json) =>
    OneTextAuthorInfo(
      textAuthorName: json['text_author_name'] as String?,
      textAuthorWork: json['text_author_work'] as String?,
      textAuthorDesc: json['text_author_desc'] as String?,
    );

Map<String, dynamic> _$OneTextAuthorInfoToJson(OneTextAuthorInfo instance) =>
    <String, dynamic>{
      'text_author_name': instance.textAuthorName,
      'text_author_work': instance.textAuthorWork,
      'text_author_desc': instance.textAuthorDesc,
    };

OneRecommendMenu _$OneRecommendMenuFromJson(Map<String, dynamic> json) =>
    OneRecommendMenu(
      vol: json['vol'] as String?,
      list: (json['list'] as List<dynamic>?)
          ?.map(
            (e) => OneRecommendMenuContent.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$OneRecommendMenuToJson(OneRecommendMenu instance) =>
    <String, dynamic>{
      'vol': instance.vol,
      'list': instance.list?.map((e) => e.toJson()).toList(),
    };

OneRecommendMenuContent _$OneRecommendMenuContentFromJson(
  Map<String, dynamic> json,
) => OneRecommendMenuContent(
  contentType: json['content_type'] as String?,
  contentId: json['content_id'] as String?,
  title: json['title'] as String?,
);

Map<String, dynamic> _$OneRecommendMenuContentToJson(
  OneRecommendMenuContent instance,
) => <String, dynamic>{
  'content_type': instance.contentType,
  'content_id': instance.contentId,
  'title': instance.title,
};

OneMonthRecommend _$OneMonthRecommendFromJson(Map<String, dynamic> json) =>
    OneMonthRecommend(
      id: (json['id'] as num?)?.toInt(),
      date: json['date'] as String?,
      cover: json['cover'] as String?,
    );

Map<String, dynamic> _$OneMonthRecommendToJson(OneMonthRecommend instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'cover': instance.cover,
    };
