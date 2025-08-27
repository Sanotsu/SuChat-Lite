// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daodu_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DaoduLesson _$DaoduLessonFromJson(Map<String, dynamic> json) => DaoduLesson(
  id: json['id'] as String?,
  article: json['article'] as String?,
  title: json['title'] as String?,
  provenance: json['provenance'] as String?,
  dateByDay: (json['date_by_day'] as num?)?.toInt(),
  author: json['author'] == null
      ? null
      : DaoduAuthor.fromJson(json['author'] as Map<String, dynamic>),
  updatedAt: (json['updated_at'] as num?)?.toInt(),
  createdAt: (json['created_at'] as num?)?.toInt(),
);

Map<String, dynamic> _$DaoduLessonToJson(DaoduLesson instance) =>
    <String, dynamic>{
      'id': instance.id,
      'article': instance.article,
      'title': instance.title,
      'provenance': instance.provenance,
      'date_by_day': instance.dateByDay,
      'author': instance.author?.toJson(),
      'updated_at': instance.updatedAt,
      'created_at': instance.createdAt,
    };

DaoduAuthor _$DaoduAuthorFromJson(Map<String, dynamic> json) =>
    DaoduAuthor(id: json['id'] as String?, name: json['name'] as String?);

Map<String, dynamic> _$DaoduAuthorToJson(DaoduAuthor instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

DaoduActivityStats _$DaoduActivityStatsFromJson(Map<String, dynamic> json) =>
    DaoduActivityStats(
      commentCount: (json['comment_count'] as num?)?.toInt(),
      favouriteCount: (json['favourite_count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$DaoduActivityStatsToJson(DaoduActivityStats instance) =>
    <String, dynamic>{
      'comment_count': instance.commentCount,
      'favourite_count': instance.favouriteCount,
    };

DaoduTodayRecommendsResp _$DaoduTodayRecommendsRespFromJson(
  Map<String, dynamic> json,
) => DaoduTodayRecommendsResp(
  (json['comments'] as List<dynamic>?)
      ?.map((e) => DaoduComment.fromJson(e as Map<String, dynamic>))
      .toList(),
  (json['lessons'] as List<dynamic>?)
      ?.map((e) => DaoduLesson.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DaoduTodayRecommendsRespToJson(
  DaoduTodayRecommendsResp instance,
) => <String, dynamic>{
  'comments': instance.comments?.map((e) => e.toJson()).toList(),
  'lessons': instance.lessons?.map((e) => e.toJson()).toList(),
};

DaoduComment _$DaoduCommentFromJson(Map<String, dynamic> json) => DaoduComment(
  id: json['id'] as String?,
  content: json['content'] as String?,
  contentTrZhHant: json['content_tr_zh_hant'] as String?,
  user: json['user'] == null
      ? null
      : DaoduUser.fromJson(json['user'] as Map<String, dynamic>),
  status: (json['status'] as num?)?.toInt(),
  likeCount: (json['like_count'] as num?)?.toInt(),
  subCommentCount: (json['sub_comment_count'] as num?)?.toInt(),
  replyTo: json['reply_to'] == null
      ? null
      : DaoduCommentReplyTo.fromJson(json['reply_to'] as Map<String, dynamic>),
  lessonId: json['lesson_id'] as String?,
  myLike: json['my_like'] as bool?,
  updatedAt: (json['updated_at'] as num?)?.toInt(),
  createdAt: (json['created_at'] as num?)?.toInt(),
);

Map<String, dynamic> _$DaoduCommentToJson(DaoduComment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'content_tr_zh_hant': instance.contentTrZhHant,
      'user': instance.user?.toJson(),
      'status': instance.status,
      'like_count': instance.likeCount,
      'sub_comment_count': instance.subCommentCount,
      'reply_to': instance.replyTo?.toJson(),
      'lesson_id': instance.lessonId,
      'my_like': instance.myLike,
      'updated_at': instance.updatedAt,
      'created_at': instance.createdAt,
    };

DaoduUser _$DaoduUserFromJson(Map<String, dynamic> json) => DaoduUser(
  id: json['id'] as String?,
  nickname: json['nickname'] as String?,
  avatar: json['avatar'] as String?,
);

Map<String, dynamic> _$DaoduUserToJson(DaoduUser instance) => <String, dynamic>{
  'id': instance.id,
  'nickname': instance.nickname,
  'avatar': instance.avatar,
};

DaoduCommentReplyTo _$DaoduCommentReplyToFromJson(Map<String, dynamic> json) =>
    DaoduCommentReplyTo(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      userNickname: json['user_nickname'] as String?,
      userAvatar: json['user_avatar'] as String?,
    );

Map<String, dynamic> _$DaoduCommentReplyToToJson(
  DaoduCommentReplyTo instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'user_nickname': instance.userNickname,
  'user_avatar': instance.userAvatar,
};

DaoduUserDetail _$DaoduUserDetailFromJson(Map<String, dynamic> json) =>
    DaoduUserDetail(
      id: json['id'] as String?,
      nickname: json['nickname'] as String?,
      sign: json['sign'] as String?,
      sex: (json['sex'] as num?)?.toInt(),
      birthday: (json['birthday'] as num?)?.toInt(),
      avatar: json['avatar'] as String?,
      wordsCount: (json['words_count'] as num?)?.toInt(),
      createdAt: (json['created_at'] as num?)?.toInt(),
      updatedAt: (json['updated_at'] as num?)?.toInt(),
      isPwdSet: json['is_pwd_set'] as bool?,
      commentLimit: json['comment_limit'] as bool?,
      whoSeeMyFavourite: (json['who_see_my_favourite'] as num?)?.toInt(),
      receivedLikes: (json['received_likes'] as num?)?.toInt(),
      lastCheckinTime: (json['last_checkin_time'] as num?)?.toInt(),
      sumCheckinTimes: (json['sum_checkin_times'] as num?)?.toInt(),
      currentContinuousCheckinTimes:
          (json['current_continuous_checkin_times'] as num?)?.toInt(),
      maxContinuousCheckinTimes: (json['max_continuous_checkin_times'] as num?)
          ?.toInt(),
      isAdmin: json['is_admin'] as bool?,
    );

Map<String, dynamic> _$DaoduUserDetailToJson(
  DaoduUserDetail instance,
) => <String, dynamic>{
  'id': instance.id,
  'nickname': instance.nickname,
  'sign': instance.sign,
  'sex': instance.sex,
  'birthday': instance.birthday,
  'avatar': instance.avatar,
  'words_count': instance.wordsCount,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'is_pwd_set': instance.isPwdSet,
  'comment_limit': instance.commentLimit,
  'who_see_my_favourite': instance.whoSeeMyFavourite,
  'received_likes': instance.receivedLikes,
  'last_checkin_time': instance.lastCheckinTime,
  'sum_checkin_times': instance.sumCheckinTimes,
  'current_continuous_checkin_times': instance.currentContinuousCheckinTimes,
  'max_continuous_checkin_times': instance.maxContinuousCheckinTimes,
  'is_admin': instance.isAdmin,
};

DaoduUserSnippetsCount _$DaoduUserSnippetsCountFromJson(
  Map<String, dynamic> json,
) => DaoduUserSnippetsCount(count: (json['count'] as num?)?.toInt());

Map<String, dynamic> _$DaoduUserSnippetsCountToJson(
  DaoduUserSnippetsCount instance,
) => <String, dynamic>{'count': instance.count};

DaoduUserSnippetsDetail _$DaoduUserSnippetsDetailFromJson(
  Map<String, dynamic> json,
) => DaoduUserSnippetsDetail(
  snippet: json['snippet'] == null
      ? null
      : DaoduSnippet.fromJson(json['snippet'] as Map<String, dynamic>),
  lesson: json['lesson'] == null
      ? null
      : DaoduLesson.fromJson(json['lesson'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DaoduUserSnippetsDetailToJson(
  DaoduUserSnippetsDetail instance,
) => <String, dynamic>{
  'snippet': instance.snippet?.toJson(),
  'lesson': instance.lesson?.toJson(),
};

DaoduSnippet _$DaoduSnippetFromJson(Map<String, dynamic> json) => DaoduSnippet(
  id: json['id'] as String?,
  content: json['content'] as String?,
  user: json['user'] == null
      ? null
      : DaoduUser.fromJson(json['user'] as Map<String, dynamic>),
  lessonId: json['lesson_id'] as String?,
  updatedAt: (json['updated_at'] as num?)?.toInt(),
  createdAt: (json['created_at'] as num?)?.toInt(),
);

Map<String, dynamic> _$DaoduSnippetToJson(DaoduSnippet instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'user': instance.user?.toJson(),
      'lesson_id': instance.lessonId,
      'updated_at': instance.updatedAt,
      'created_at': instance.createdAt,
    };

DaoduUserThoughtsProfile _$DaoduUserThoughtsProfileFromJson(
  Map<String, dynamic> json,
) => DaoduUserThoughtsProfile(
  json['thought'] == null
      ? null
      : DaoduComment.fromJson(json['thought'] as Map<String, dynamic>),
  json['lesson'] == null
      ? null
      : DaoduLesson.fromJson(json['lesson'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DaoduUserThoughtsProfileToJson(
  DaoduUserThoughtsProfile instance,
) => <String, dynamic>{
  'thought': instance.thought?.toJson(),
  'lesson': instance.lesson?.toJson(),
};
