// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'one_category_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OneTopic _$OneTopicFromJson(Map<String, dynamic> json) => OneTopic(
  id: (json['id'] as num?)?.toInt(),
  cover: json['cover'] as String?,
  title: json['title'] as String?,
  category: (json['category'] as num?)?.toInt(),
  contentId: json['content_id'] as String?,
  isStick: json['is_stick'] as bool?,
  serialList: json['serial_list'] as List<dynamic>?,
  linkUrl: json['link_url'] as String?,
);

Map<String, dynamic> _$OneTopicToJson(OneTopic instance) => <String, dynamic>{
  'id': instance.id,
  'cover': instance.cover,
  'title': instance.title,
  'category': instance.category,
  'content_id': instance.contentId,
  'is_stick': instance.isStick,
  'serial_list': instance.serialList,
  'link_url': instance.linkUrl,
};

OneRank _$OneRankFromJson(Map<String, dynamic> json) => OneRank(
  id: (json['id'] as num?)?.toInt(),
  title: json['title'] as String?,
  imgUrl: json['img_url'] as String?,
  contents: (json['contents'] as List<dynamic>?)
      ?.map((e) => OneContent.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$OneRankToJson(OneRank instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'img_url': instance.imgUrl,
  'contents': instance.contents?.map((e) => e.toJson()).toList(),
};

OneDiaryList _$OneDiaryListFromJson(Map<String, dynamic> json) => OneDiaryList(
  list: (json['list'] as List<dynamic>?)
      ?.map((e) => OneDiary.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$OneDiaryListToJson(OneDiaryList instance) =>
    <String, dynamic>{'list': instance.list?.map((e) => e.toJson()).toList()};

OneDiary _$OneDiaryFromJson(Map<String, dynamic> json) => OneDiary(
  id: json['id'] as String?,
  userId: json['user_id'] as String?,
  weather: json['weather'] as String?,
  content: json['content'] as String?,
  picture: json['picture'] as String?,
  inputDate: json['input_date'] as String?,
  imgUrl: json['img_url'] as String?,
  addr: json['addr'] as String?,
  isPublic: json['is_public'] as String?,
  reviewed: json['reviewed'] as String?,
  remark: json['remark'] as String?,
  diaryId: json['diary_id'] as String?,
  imgUrlThumbH: (json['img_url_thumb_h'] as num?)?.toInt(),
  user: json['user'] == null
      ? null
      : OneUser.fromJson(json['user'] as Map<String, dynamic>),
  imgUrlThumb: json['img_url_thumb'] as String?,
  praisenum: (json['praisenum'] as num?)?.toInt(),
  imgUrlThumbW: (json['img_url_thumb_w'] as num?)?.toInt(),
);

Map<String, dynamic> _$OneDiaryToJson(OneDiary instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'weather': instance.weather,
  'content': instance.content,
  'picture': instance.picture,
  'input_date': instance.inputDate,
  'img_url': instance.imgUrl,
  'addr': instance.addr,
  'is_public': instance.isPublic,
  'reviewed': instance.reviewed,
  'remark': instance.remark,
  'diary_id': instance.diaryId,
  'img_url_thumb_h': instance.imgUrlThumbH,
  'user': instance.user?.toJson(),
  'img_url_thumb': instance.imgUrlThumb,
  'praisenum': instance.praisenum,
  'img_url_thumb_w': instance.imgUrlThumbW,
};

OneContent _$OneContentFromJson(Map<String, dynamic> json) => OneContent(
  id: json['id'],
  contentId: json['content_id'],
  title: json['title'] as String?,
  subtitle: json['subtitle'] as String?,
  category: (json['category'] as num?)?.toInt(),
  cover: json['cover'] as String?,
  maketime: json['maketime'] as String?,
  weight: (json['weight'] as num?)?.toInt(),
  serialId: (json['serial_id'] as num?)?.toInt(),
  serialTitle: json['serial_title'] as String?,
  forward: json['forward'] as String?,
  finished: json['finished'] as bool?,
  serialList: json['serial_list'] as List<dynamic>?,
  number: (json['number'] as num?)?.toInt(),
  date: json['date'] as String?,
  volume: json['volume'] as String?,
  audioUrl: json['audio_url'] as String?,
  shareUrl: json['share_url'] as String?,
  author: json['author'] == null
      ? null
      : OneAuthor.fromJson(json['author'] as Map<String, dynamic>),
  likeCount: (json['like_count'] as num?)?.toInt(),
);

Map<String, dynamic> _$OneContentToJson(OneContent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content_id': instance.contentId,
      'title': instance.title,
      'subtitle': instance.subtitle,
      'category': instance.category,
      'cover': instance.cover,
      'maketime': instance.maketime,
      'weight': instance.weight,
      'serial_id': instance.serialId,
      'serial_title': instance.serialTitle,
      'forward': instance.forward,
      'finished': instance.finished,
      'serial_list': instance.serialList,
      'number': instance.number,
      'date': instance.date,
      'volume': instance.volume,
      'audio_url': instance.audioUrl,
      'share_url': instance.shareUrl,
      'author': instance.author?.toJson(),
      'like_count': instance.likeCount,
    };
