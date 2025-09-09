// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'one_detail_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OneHpDetail _$OneHpDetailFromJson(Map<String, dynamic> json) => OneHpDetail(
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
  volume: json['volume'] as String?,
  picInfo: json['pic_info'] as String?,
  wordsInfo: json['words_info'] as String?,
  subtitle: json['subtitle'] as String?,
  number: (json['number'] as num?)?.toInt(),
  serialId: (json['serial_id'] as num?)?.toInt(),
  serialList: json['serial_list'] as List<dynamic>?,
  movieStoryId: (json['movie_story_id'] as num?)?.toInt(),
  contentId: json['content_id'] as String?,
  contentType: json['content_type'] as String?,
  contentBgcolor: json['content_bgcolor'] as String?,
  tagList: json['tag_list'] as List<dynamic>?,
  orientation: json['orientation'] as String?,
  weather: json['weather'] == null
      ? null
      : OneWeather.fromJson(json['weather'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OneHpDetailToJson(OneHpDetail instance) =>
    <String, dynamic>{
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
      'subtitle': instance.subtitle,
      'number': instance.number,
      'serial_id': instance.serialId,
      'serial_list': instance.serialList,
      'movie_story_id': instance.movieStoryId,
      'content_id': instance.contentId,
      'content_type': instance.contentType,
      'content_bgcolor': instance.contentBgcolor,
      'tag_list': instance.tagList,
      'orientation': instance.orientation,
      'weather': instance.weather?.toJson(),
    };

OneContentDetail _$OneContentDetailFromJson(Map<String, dynamic> json) =>
    OneContentDetail(
      serialTitle: json['serial_title'] as String?,
      serialId: json['serial_id'] as String?,
      audio: json['audio'] as String?,
      anchor: json['anchor'] as String?,
      category: (json['category'] as num?)?.toInt(),
      id: json['id'] as String?,
      title: json['title'] as String?,
      webUrl: json['web_url'] as String?,
      authorList: (json['author_list'] as List<dynamic>?)
          ?.map((e) => OneAuthor.fromJson(e as Map<String, dynamic>))
          .toList(),
      tagList: (json['tag_list'] as List<dynamic>?)
          ?.map((e) => OneTag.fromJson(e as Map<String, dynamic>))
          .toList(),
      enableComment: json['enable_comment'] as bool?,
      radio: json['radio'] as String?,
      platform: json['platform'] as String?,
      platformIcon: json['platform_icon'] as String?,
      platformName: json['platform_name'] as String?,
      musicId: json['music_id'] as String?,
      homeImage: json['home_image'] as String?,
      musicException: json['music_exception'] as String?,
      praisenum: (json['praisenum'] as num?)?.toInt(),
      commentnum: (json['commentnum'] as num?)?.toInt(),
      jsonContent: json['json_content'] == null
          ? null
          : OneContentDetailJson.fromJson(
              json['json_content'] as Map<String, dynamic>,
            ),
      bgColor: json['bg_color'] as String?,
      fontColor: json['font_color'] as String?,
    );

Map<String, dynamic> _$OneContentDetailToJson(OneContentDetail instance) =>
    <String, dynamic>{
      'audio': instance.audio,
      'anchor': instance.anchor,
      'category': instance.category,
      'id': instance.id,
      'title': instance.title,
      'web_url': instance.webUrl,
      'author_list': instance.authorList?.map((e) => e.toJson()).toList(),
      'tag_list': instance.tagList?.map((e) => e.toJson()).toList(),
      'enable_comment': instance.enableComment,
      'home_image': instance.homeImage,
      'praisenum': instance.praisenum,
      'commentnum': instance.commentnum,
      'json_content': instance.jsonContent?.toJson(),
      'platform': instance.platform,
      'platform_icon': instance.platformIcon,
      'platform_name': instance.platformName,
      'music_id': instance.musicId,
      'music_exception': instance.musicException,
      'radio': instance.radio,
      'bg_color': instance.bgColor,
      'font_color': instance.fontColor,
      'serial_title': instance.serialTitle,
      'serial_id': instance.serialId,
    };

OneContentDetailJson _$OneContentDetailJsonFromJson(
  Map<String, dynamic> json,
) =>
    OneContentDetailJson(
        json['type'] as String?,
        (json['id'] as num?)?.toInt(),
        json['title'] as String?,
        json['author'] == null
            ? null
            : OneContentJsonAuthor.fromJson(
                json['author'] as Map<String, dynamic>,
              ),
        json['audio_url'] as String?,
        (json['audio_platform'] as num?)?.toInt(),
        json['platform_name'] as String?,
        json['platform_icon'] as String?,
        json['music_header'] == null
            ? null
            : OneMusicHeader.fromJson(
                json['music_header'] as Map<String, dynamic>,
              ),
        json['oneDataArticle'] == null
            ? null
            : OneDataArticle.fromJson(
                json['oneDataArticle'] as Map<String, dynamic>,
              ),
        (json['simple_author'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
        json['content'] as String?,
        json['editor'] as String?,
        json['copyright'] as String?,
        json['question_brief'] as String?,
        json['simple_answerer'] as String?,
        json['radio_url'] as String?,
        json['cover'] as String?,
      )
      ..videoUrl = json['video_url'] as String?
      ..movieSwipe = json['movie_swipe']
      ..special = json['special'] == null
          ? null
          : OneDataArticle.fromJson(json['special'] as Map<String, dynamic>)
      ..oneDataArticles = (json['oneDataArticles'] as List<dynamic>?)
          ?.map((e) => OneRecommendContent.fromJson(e as Map<String, dynamic>))
          .toList()
      ..serialNav = json['serial_nav'] == null
          ? null
          : OneSerialNav.fromJson(json['serial_nav'] as Map<String, dynamic>);

Map<String, dynamic> _$OneContentDetailJsonToJson(
  OneContentDetailJson instance,
) => <String, dynamic>{
  'type': instance.type,
  'title': instance.title,
  'simple_author': instance.simpleAuthor,
  'content': instance.content,
  'editor': instance.editor,
  'copyright': instance.copyright,
  'author': instance.author?.toJson(),
  'question_brief': instance.questionBrief,
  'simple_answerer': instance.simpleAnswerer,
  'id': instance.id,
  'audio_url': instance.audioUrl,
  'audio_platform': instance.audioPlatform,
  'platform_name': instance.platformName,
  'platform_icon': instance.platformIcon,
  'music_header': instance.musicHeader?.toJson(),
  'oneDataArticle': instance.oneDataArticle?.toJson(),
  'video_url': instance.videoUrl,
  'movie_swipe': instance.movieSwipe,
  'radio_url': instance.radioUrl,
  'cover': instance.cover,
  'special': instance.special?.toJson(),
  'oneDataArticles': instance.oneDataArticles?.map((e) => e.toJson()).toList(),
  'serial_nav': instance.serialNav?.toJson(),
};

OneContentJsonAuthor _$OneContentJsonAuthorFromJson(
  Map<String, dynamic> json,
) => OneContentJsonAuthor(
  role: json['role'] as String?,
  authors: (json['authors'] as List<dynamic>?)
      ?.map((e) => OneContentBriefAuthor.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$OneContentJsonAuthorToJson(
  OneContentJsonAuthor instance,
) => <String, dynamic>{
  'role': instance.role,
  'authors': instance.authors?.map((e) => e.toJson()).toList(),
};

OneContentBriefAuthor _$OneContentBriefAuthorFromJson(
  Map<String, dynamic> json,
) => OneContentBriefAuthor(
  id: (json['id'] as num?)?.toInt(),
  avatar: json['avatar'] as String?,
  name: json['name'] as String?,
  brief: json['brief'] as String?,
);

Map<String, dynamic> _$OneContentBriefAuthorToJson(
  OneContentBriefAuthor instance,
) => <String, dynamic>{
  'id': instance.id,
  'avatar': instance.avatar,
  'name': instance.name,
  'brief': instance.brief,
};

OneMusicHeader _$OneMusicHeaderFromJson(Map<String, dynamic> json) =>
    OneMusicHeader(
      bg: json['bg'] as String?,
      disk: json['disk'] as String?,
      cover: json['cover'] as String?,
      copyrightImg: json['copyright_img'] as String?,
      info: json['info'] as String?,
    );

Map<String, dynamic> _$OneMusicHeaderToJson(OneMusicHeader instance) =>
    <String, dynamic>{
      'bg': instance.bg,
      'disk': instance.disk,
      'cover': instance.cover,
      'copyright_img': instance.copyrightImg,
      'info': instance.info,
    };

OneDataArticle _$OneDataArticleFromJson(Map<String, dynamic> json) =>
    OneDataArticle(
      cover: json['cover'] as String?,
      lyric: json['lyric'] as String?,
      info: json['info'] as String?,
      title: json['title'] as String?,
      poster: json['poster'] as String?,
      officialstory: json['officialstory'] as String?,
      releasetime: json['releasetime'] as String?,
      sumarry: json['sumarry'] as String?,
      content: json['content'] as String?,
    );

Map<String, dynamic> _$OneDataArticleToJson(OneDataArticle instance) =>
    <String, dynamic>{
      'cover': instance.cover,
      'lyric': instance.lyric,
      'info': instance.info,
      'title': instance.title,
      'poster': instance.poster,
      'officialstory': instance.officialstory,
      'releasetime': instance.releasetime,
      'sumarry': instance.sumarry,
      'content': instance.content,
    };

OneSerialNav _$OneSerialNavFromJson(Map<String, dynamic> json) => OneSerialNav(
  prev: (json['prev'] as num?)?.toInt(),
  next: (json['next'] as num?)?.toInt(),
);

Map<String, dynamic> _$OneSerialNavToJson(OneSerialNav instance) =>
    <String, dynamic>{'prev': instance.prev, 'next': instance.next};

OneCommentList _$OneCommentListFromJson(Map<String, dynamic> json) =>
    OneCommentList(
      count: (json['count'] as num?)?.toInt(),
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => OneComment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OneCommentListToJson(OneCommentList instance) =>
    <String, dynamic>{
      'count': instance.count,
      'data': instance.data?.map((e) => e.toJson()).toList(),
    };

OneComment _$OneCommentFromJson(Map<String, dynamic> json) => OneComment(
  id: json['id'] as String?,
  quote: json['quote'] as String?,
  content: json['content'] as String?,
  praisenum: (json['praisenum'] as num?)?.toInt(),
  deviceToken: json['device_token'] as String?,
  delFlag: json['del_flag'] as String?,
  reviewed: json['reviewed'] as String?,
  userInfoId: json['user_info_id'] as String?,
  inputDate: json['input_date'] as String?,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
  user: json['user'] == null
      ? null
      : OneUser.fromJson(json['user'] as Map<String, dynamic>),
  touser: json['touser'] == null
      ? null
      : OneUser.fromJson(json['touser'] as Map<String, dynamic>),
  type: (json['type'] as num?)?.toInt(),
);

Map<String, dynamic> _$OneCommentToJson(OneComment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'quote': instance.quote,
      'content': instance.content,
      'praisenum': instance.praisenum,
      'device_token': instance.deviceToken,
      'del_flag': instance.delFlag,
      'reviewed': instance.reviewed,
      'user_info_id': instance.userInfoId,
      'input_date': instance.inputDate,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'user': instance.user?.toJson(),
      'touser': instance.touser?.toJson(),
      'type': instance.type,
    };

OneSearchList _$OneSearchListFromJson(Map<String, dynamic> json) =>
    OneSearchList(
      list: (json['list'] as List<dynamic>?)
          ?.map((e) => OneContent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OneSearchListToJson(OneSearchList instance) =>
    <String, dynamic>{'list': instance.list?.map((e) => e.toJson()).toList()};
