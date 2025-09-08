// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'one_user_collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OneUserHpCollection _$OneUserHpCollectionFromJson(Map<String, dynamic> json) =>
    OneUserHpCollection(
      hpcontentId: json['hpcontent_id'] as String?,
      hpTitle: json['hp_title'] as String?,
      authorId: json['author_id'] as String?,
      hpImgUrl: json['hp_img_url'] as String?,
      hpImgOriginalUrl: json['hp_img_original_url'] as String?,
      hpAuthor: json['hp_author'] as String?,
      ipadUrl: json['ipad_url'] as String?,
      hpContent: json['hp_content'] as String?,
      hpMakettime: json['hp_makettime'] as String?,
      lastUpdateDate: json['last_update_date'] as String?,
      webUrl: json['web_url'] as String?,
      wbImgUrl: json['wb_img_url'] as String?,
      imageAuthors: json['image_authors'] as String?,
      textAuthors: json['text_authors'] as String?,
      imageFrom: json['image_from'] as String?,
      textFrom: json['text_from'] as String?,
      contentBgcolor: json['content_bgcolor'] as String?,
      templateCategory: json['template_category'] as String?,
      textAuthorName: json['text_author_name'] as String?,
      textAuthorWork: json['text_author_work'] as String?,
      textAuthorDesc: json['text_author_desc'] as String?,
      maketime: json['maketime'] as String?,
      praisenum: (json['praisenum'] as num?)?.toInt(),
      sharenum: (json['sharenum'] as num?)?.toInt(),
      commentnum: (json['commentnum'] as num?)?.toInt(),
    );

Map<String, dynamic> _$OneUserHpCollectionToJson(
  OneUserHpCollection instance,
) => <String, dynamic>{
  'hpcontent_id': instance.hpcontentId,
  'hp_title': instance.hpTitle,
  'author_id': instance.authorId,
  'hp_img_url': instance.hpImgUrl,
  'hp_img_original_url': instance.hpImgOriginalUrl,
  'hp_author': instance.hpAuthor,
  'ipad_url': instance.ipadUrl,
  'hp_content': instance.hpContent,
  'hp_makettime': instance.hpMakettime,
  'last_update_date': instance.lastUpdateDate,
  'web_url': instance.webUrl,
  'wb_img_url': instance.wbImgUrl,
  'image_authors': instance.imageAuthors,
  'text_authors': instance.textAuthors,
  'image_from': instance.imageFrom,
  'text_from': instance.textFrom,
  'content_bgcolor': instance.contentBgcolor,
  'template_category': instance.templateCategory,
  'text_author_name': instance.textAuthorName,
  'text_author_work': instance.textAuthorWork,
  'text_author_desc': instance.textAuthorDesc,
  'maketime': instance.maketime,
  'praisenum': instance.praisenum,
  'sharenum': instance.sharenum,
  'commentnum': instance.commentnum,
};

OneUserReadingCollection _$OneUserReadingCollectionFromJson(
  Map<String, dynamic> json,
) => OneUserReadingCollection(
  contentId: json['content_id'] as String?,
  hpTitle: json['hp_title'] as String?,
  hpMakettime: json['hp_makettime'] as String?,
  guideWord: json['guide_word'] as String?,
  startVideo: json['start_video'] as String?,
  author: (json['author'] as List<dynamic>?)
      ?.map((e) => OneAuthor.fromJson(e as Map<String, dynamic>))
      .toList(),
  hasAudio: json['has_audio'] as bool?,
  authorList: (json['author_list'] as List<dynamic>?)
      ?.map((e) => OneAuthor.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$OneUserReadingCollectionToJson(
  OneUserReadingCollection instance,
) => <String, dynamic>{
  'content_id': instance.contentId,
  'hp_title': instance.hpTitle,
  'hp_makettime': instance.hpMakettime,
  'guide_word': instance.guideWord,
  'start_video': instance.startVideo,
  'author': instance.author?.map((e) => e.toJson()).toList(),
  'has_audio': instance.hasAudio,
  'author_list': instance.authorList?.map((e) => e.toJson()).toList(),
};

OneUserQuestionCollection _$OneUserQuestionCollectionFromJson(
  Map<String, dynamic> json,
) => OneUserQuestionCollection(
  questionId: json['question_id'] as String?,
  questionTitle: json['question_title'] as String?,
  answerTitle: json['answer_title'] as String?,
  answerContent: json['answer_content'] as String?,
  questionMakettime: json['question_makettime'] as String?,
  startVideo: json['start_video'] as String?,
  authorList: (json['author_list'] as List<dynamic>?)
      ?.map((e) => OneAuthor.fromJson(e as Map<String, dynamic>))
      .toList(),
  askerList: (json['asker_list'] as List<dynamic>?)
      ?.map((e) => OneAuthor.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$OneUserQuestionCollectionToJson(
  OneUserQuestionCollection instance,
) => <String, dynamic>{
  'question_id': instance.questionId,
  'question_title': instance.questionTitle,
  'answer_title': instance.answerTitle,
  'answer_content': instance.answerContent,
  'question_makettime': instance.questionMakettime,
  'start_video': instance.startVideo,
  'author_list': instance.authorList,
  'asker_list': instance.askerList,
};

OneUserMusicCollection _$OneUserMusicCollectionFromJson(
  Map<String, dynamic> json,
) => OneUserMusicCollection(
  id: json['id'] as String?,
  title: json['title'] as String?,
  cover: json['cover'] as String?,
  storyTitle: json['story_title'] as String?,
  platform: json['platform'] as String?,
  musicId: json['music_id'] as String?,
  album: json['album'] as String?,
  startVideo: json['start_video'] as String?,
  author: json['author'] == null
      ? null
      : OneAuthor.fromJson(json['author'] as Map<String, dynamic>),
  authorList: (json['author_list'] as List<dynamic>?)
      ?.map((e) => OneAuthor.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$OneUserMusicCollectionToJson(
  OneUserMusicCollection instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'cover': instance.cover,
  'story_title': instance.storyTitle,
  'platform': instance.platform,
  'music_id': instance.musicId,
  'album': instance.album,
  'start_video': instance.startVideo,
  'author': instance.author?.toJson(),
  'author_list': instance.authorList?.map((e) => e.toJson()).toList(),
};

OneUserMovieCollection _$OneUserMovieCollectionFromJson(
  Map<String, dynamic> json,
) => OneUserMovieCollection(
  id: json['id'] as String?,
  title: json['title'] as String?,
  verse: json['verse'] as String?,
  verseEn: json['verse_en'] as String?,
  revisedscore: json['revisedscore'] as String?,
  releasetime: json['releasetime'] as String?,
  scoretime: json['scoretime'] as String?,
  startVideo: json['start_video'] as String?,
  cover: json['cover'] as String?,
  authorList: (json['author_list'] as List<dynamic>?)
      ?.map((e) => OneAuthor.fromJson(e as Map<String, dynamic>))
      .toList(),
  subtitle: json['subtitle'] as String?,
  servertime: (json['servertime'] as num?)?.toInt(),
);

Map<String, dynamic> _$OneUserMovieCollectionToJson(
  OneUserMovieCollection instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'verse': instance.verse,
  'verse_en': instance.verseEn,
  'revisedscore': instance.revisedscore,
  'releasetime': instance.releasetime,
  'scoretime': instance.scoretime,
  'start_video': instance.startVideo,
  'cover': instance.cover,
  'author_list': instance.authorList?.map((e) => e.toJson()).toList(),
  'subtitle': instance.subtitle,
  'servertime': instance.servertime,
};

OneUserRadioCollection _$OneUserRadioCollectionFromJson(
  Map<String, dynamic> json,
) => OneUserRadioCollection(
  title: json['title'] as String?,
  cover: json['cover'] as String?,
  category: (json['category'] as num?)?.toInt(),
  contentId: json['content_id'] as String?,
  authorList: (json['author_list'] as List<dynamic>?)
      ?.map((e) => OneAuthor.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$OneUserRadioCollectionToJson(
  OneUserRadioCollection instance,
) => <String, dynamic>{
  'title': instance.title,
  'cover': instance.cover,
  'category': instance.category,
  'content_id': instance.contentId,
  'author_list': instance.authorList,
};

OneUserPlaylistCollection _$OneUserPlaylistCollectionFromJson(
  Map<String, dynamic> json,
) => OneUserPlaylistCollection(
  collectionType: json['collection_type'] as String?,
  collectionId: json['collection_id'] as String?,
  id: json['id'] as String?,
  title: json['title'] as String?,
  subtitle: json['subtitle'] as String?,
  cover: json['cover'] as String?,
  platform: json['platform'] as String?,
  platformIcon: json['platform_icon'] as String?,
  platformName: json['platform_name'] as String?,
  musicId: json['music_id'] as String?,
  category: (json['category'] as num?)?.toInt(),
  contentId: json['content_id'] as String?,
  musicException: json['music_exception'] as String?,
);

Map<String, dynamic> _$OneUserPlaylistCollectionToJson(
  OneUserPlaylistCollection instance,
) => <String, dynamic>{
  'collection_type': instance.collectionType,
  'collection_id': instance.collectionId,
  'id': instance.id,
  'title': instance.title,
  'subtitle': instance.subtitle,
  'cover': instance.cover,
  'platform': instance.platform,
  'platform_icon': instance.platformIcon,
  'platform_name': instance.platformName,
  'music_id': instance.musicId,
  'category': instance.category,
  'content_id': instance.contentId,
  'music_exception': instance.musicException,
};
