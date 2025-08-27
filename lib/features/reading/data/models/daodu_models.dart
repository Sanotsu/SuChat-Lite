import 'package:json_annotation/json_annotation.dart';

part 'daodu_models.g.dart';

/// 岛读APP 文章请求
/// https://apis.netstart.cn/daodu/#/
///
/// 文章列表API： https://apis.netstart.cn/daodu/lessons?from=20220101&to=20230930&updated_at=1664527511
/// 每天更新一篇，可以根据时间范围查询，结果直接是一个列表
///
/// 文章详情API：https://apis.netstart.cn/daodu/lessons/6335baac8d555800061883d8
/// 直接返回该文章的数据
///
/// 文章状态API：https://apis.netstart.cn/daodu/lessons/6335baac8d555800061883d8/activity_stats
/// 返回文章的点赞数和评论数，查询评论时直接返回评论列表，评论总数需要在文章状态中得到

List<DaoduLesson> getDaoduLessonsRespList(List<dynamic> list) {
  List<DaoduLesson> result = [];
  for (var item in list) {
    result.add(DaoduLesson.fromJson(item));
  }
  return result;
}

@JsonSerializable(explicitToJson: true)
class DaoduLesson {
  @JsonKey(name: 'id')
  String? id;

  // 文章的内容详情
  @JsonKey(name: 'article')
  String? article;

  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'provenance')
  String? provenance;

  @JsonKey(name: 'date_by_day')
  int? dateByDay;

  @JsonKey(name: 'author')
  DaoduAuthor? author;

  @JsonKey(name: 'updated_at')
  int? updatedAt;

  @JsonKey(name: 'created_at')
  int? createdAt;

  DaoduLesson({
    this.id,
    this.article,
    this.title,
    this.provenance,
    this.dateByDay,
    this.author,
    this.updatedAt,
    this.createdAt,
  });

  factory DaoduLesson.fromJson(Map<String, dynamic> srcJson) =>
      _$DaoduLessonFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DaoduLessonToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DaoduAuthor {
  @JsonKey(name: 'id')
  String? id;

  @JsonKey(name: 'name')
  String? name;

  DaoduAuthor({this.id, this.name});

  factory DaoduAuthor.fromJson(Map<String, dynamic> srcJson) =>
      _$DaoduAuthorFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DaoduAuthorToJson(this);
}

/// 文章状态
@JsonSerializable(explicitToJson: true)
class DaoduActivityStats {
  @JsonKey(name: 'comment_count')
  int? commentCount;

  @JsonKey(name: 'favourite_count')
  int? favouriteCount;

  DaoduActivityStats({this.commentCount, this.favouriteCount});

  factory DaoduActivityStats.fromJson(Map<String, dynamic> srcJson) =>
      _$DaoduActivityStatsFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DaoduActivityStatsToJson(this);
}

///
/// 岛读今日推荐API：https://apis.netstart.cn/daodu/today_recommends
/// 有一些评论和几篇文章
///
/// 指定文章评论列表API：https://apis.netstart.cn/daodu/lessons/6335baac8d555800061883d8/comments?offset=0&limit=256
/// 直接返回评论列表
///
/// 对指定评论的回复列表API：https://apis.netstart.cn/daodu/comments/6336858e8d55580006188987/comments
/// 直接返回评论的回复列表,和文章评论列表结构一样的 （评论中sub_comment_count不为0,就需要继续调用评论的回复查询）
///
List<DaoduComment> getDaoduCommentsRespList(List<dynamic> list) {
  List<DaoduComment> result = [];
  for (var item in list) {
    result.add(DaoduComment.fromJson(item));
  }
  return result;
}

@JsonSerializable(explicitToJson: true)
class DaoduTodayRecommendsResp {
  @JsonKey(name: 'comments')
  List<DaoduComment>? comments;

  @JsonKey(name: 'lessons')
  List<DaoduLesson>? lessons;

  DaoduTodayRecommendsResp(this.comments, this.lessons);

  factory DaoduTodayRecommendsResp.fromJson(Map<String, dynamic> srcJson) =>
      _$DaoduTodayRecommendsRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DaoduTodayRecommendsRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DaoduComment {
  @JsonKey(name: 'id')
  String? id;

  // 评论的详情
  @JsonKey(name: 'content')
  String? content;

  // 评论的详情(繁体中文)
  @JsonKey(name: 'content_tr_zh_hant')
  String? contentTrZhHant;

  @JsonKey(name: 'user')
  DaoduUser? user;

  @JsonKey(name: 'status')
  int? status;

  @JsonKey(name: 'like_count')
  int? likeCount;

  @JsonKey(name: 'sub_comment_count')
  int? subCommentCount;

  @JsonKey(name: 'reply_to')
  DaoduCommentReplyTo? replyTo;

  @JsonKey(name: 'lesson_id')
  String? lessonId;

  @JsonKey(name: 'my_like')
  bool? myLike;

  @JsonKey(name: 'updated_at')
  int? updatedAt;

  @JsonKey(name: 'created_at')
  int? createdAt;

  DaoduComment({
    this.id,
    this.content,
    this.contentTrZhHant,
    this.user,
    this.status,
    this.likeCount,
    this.subCommentCount,
    this.replyTo,
    this.lessonId,
    this.myLike,
    this.updatedAt,
    this.createdAt,
  });

  factory DaoduComment.fromJson(Map<String, dynamic> srcJson) =>
      _$DaoduCommentFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DaoduCommentToJson(this);
}

// user 栏位 id nickname avatar
// author 栏位 id name
@JsonSerializable(explicitToJson: true)
class DaoduUser {
  @JsonKey(name: 'id')
  String? id;

  @JsonKey(name: 'nickname')
  String? nickname;

  @JsonKey(name: 'avatar')
  String? avatar;

  DaoduUser({this.id, this.nickname, this.avatar});

  factory DaoduUser.fromJson(Map<String, dynamic> srcJson) =>
      _$DaoduUserFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DaoduUserToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DaoduCommentReplyTo {
  @JsonKey(name: 'id')
  String? id;

  @JsonKey(name: 'user_id')
  String? userId;

  @JsonKey(name: 'user_nickname')
  String? userNickname;

  @JsonKey(name: 'user_avatar')
  String? userAvatar;

  DaoduCommentReplyTo({
    this.id,
    this.userId,
    this.userNickname,
    this.userAvatar,
  });

  factory DaoduCommentReplyTo.fromJson(Map<String, dynamic> srcJson) =>
      _$DaoduCommentReplyToFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DaoduCommentReplyToToJson(this);
}

///
/// 用户详情API：https://apis.netstart.cn/daodu/users/5f0ae18889f0fe0006d86b67
/// 直接返回用户详情，但这里对栏位有删减，比如对齐社交媒体相关栏位，被后台加密的栏位(邮箱、手机号等)
///
@JsonSerializable(explicitToJson: true)
class DaoduUserDetail {
  @JsonKey(name: 'id')
  String? id;

  @JsonKey(name: 'nickname')
  String? nickname;

  @JsonKey(name: 'sign')
  String? sign;

  @JsonKey(name: 'sex')
  int? sex;

  @JsonKey(name: 'birthday')
  int? birthday;

  @JsonKey(name: 'avatar')
  String? avatar;

  @JsonKey(name: 'words_count')
  int? wordsCount;

  @JsonKey(name: 'created_at')
  int? createdAt;

  @JsonKey(name: 'updated_at')
  int? updatedAt;

  @JsonKey(name: 'is_pwd_set')
  bool? isPwdSet;

  @JsonKey(name: 'comment_limit')
  bool? commentLimit;

  @JsonKey(name: 'who_see_my_favourite')
  int? whoSeeMyFavourite;

  @JsonKey(name: 'received_likes')
  int? receivedLikes;

  @JsonKey(name: 'last_checkin_time')
  int? lastCheckinTime;

  @JsonKey(name: 'sum_checkin_times')
  int? sumCheckinTimes;

  @JsonKey(name: 'current_continuous_checkin_times')
  int? currentContinuousCheckinTimes;

  @JsonKey(name: 'max_continuous_checkin_times')
  int? maxContinuousCheckinTimes;

  @JsonKey(name: 'is_admin')
  bool? isAdmin;

  DaoduUserDetail({
    this.id,
    this.nickname,
    this.sign,
    this.sex,
    this.birthday,
    this.avatar,
    this.wordsCount,
    this.createdAt,
    this.updatedAt,
    this.isPwdSet,
    this.commentLimit,
    this.whoSeeMyFavourite,
    this.receivedLikes,
    this.lastCheckinTime,
    this.sumCheckinTimes,
    this.currentContinuousCheckinTimes,
    this.maxContinuousCheckinTimes,
    this.isAdmin,
  });

  factory DaoduUserDetail.fromJson(Map<String, dynamic> srcJson) =>
      _$DaoduUserDetailFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DaoduUserDetailToJson(this);
}

/// 用户摘要统计
/// https://apis.netstart.cn/daodu/users/5f0ae18889f0fe0006d86b67/snippets/count
/// 指定用户摘要统计数量，在查询摘要列表时可能分页时需要
@JsonSerializable(explicitToJson: true)
class DaoduUserSnippetsCount {
  @JsonKey(name: 'count')
  int? count;

  DaoduUserSnippetsCount({this.count});

  factory DaoduUserSnippetsCount.fromJson(Map<String, dynamic> srcJson) =>
      _$DaoduUserSnippetsCountFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DaoduUserSnippetsCountToJson(this);
}

/// 用户摘要列表
/// https://apis.netstart.cn/daodu/users/5f0ae18889f0fe0006d86b67/snippets_detail?offset=0&limit=256
/// 指定用户的摘要列表
///
List<DaoduUserSnippetsDetail> getDaoduUserSnippetsDetailRespList(
  List<dynamic> list,
) {
  List<DaoduUserSnippetsDetail> result = [];
  for (var item in list) {
    result.add(DaoduUserSnippetsDetail.fromJson(item));
  }
  return result;
}

@JsonSerializable(explicitToJson: true)
class DaoduUserSnippetsDetail {
  @JsonKey(name: 'snippet')
  DaoduSnippet? snippet;

  // 摘要中的文章详情栏位不全，只有部分，需要通过ID查看文章详情
  @JsonKey(name: 'lesson')
  DaoduLesson? lesson;

  DaoduUserSnippetsDetail({this.snippet, this.lesson});

  factory DaoduUserSnippetsDetail.fromJson(Map<String, dynamic> srcJson) =>
      _$DaoduUserSnippetsDetailFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DaoduUserSnippetsDetailToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DaoduSnippet {
  @JsonKey(name: 'id')
  String? id;

  @JsonKey(name: 'content')
  String? content;

  @JsonKey(name: 'user')
  DaoduUser? user;

  @JsonKey(name: 'lesson_id')
  String? lessonId;

  @JsonKey(name: 'updated_at')
  int? updatedAt;

  @JsonKey(name: 'created_at')
  int? createdAt;

  DaoduSnippet({
    this.id,
    this.content,
    this.user,
    this.lessonId,
    this.updatedAt,
    this.createdAt,
  });

  factory DaoduSnippet.fromJson(Map<String, dynamic> srcJson) =>
      _$DaoduSnippetFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DaoduSnippetToJson(this);
}

/// 用户喜欢列表
/// https://apis.netstart.cn/daodu/users/5f0ae18889f0fe0006d86b67/favourite_lessons?offset=0&limit=256
// 直接返回的文章列表 List<DaoduLesson>
///

///
/// 用户想法列表
/// https://apis.netstart.cn/daodu/users/5f0ae18889f0fe0006d86b67/thoughts_profile?offset=0&limit=256
/// 直接返回针对文章的想法列表
///
List<DaoduUserThoughtsProfile> getDaoduUserThoughtsProfileRespList(
  List<dynamic> list,
) {
  List<DaoduUserThoughtsProfile> result = [];
  for (var item in list) {
    result.add(DaoduUserThoughtsProfile.fromJson(item));
  }
  return result;
}

@JsonSerializable(explicitToJson: true)
class DaoduUserThoughtsProfile {
  // 用户想法和评论的结构是一样的，这里只是外部栏位key不一样
  @JsonKey(name: 'thought')
  DaoduComment? thought;

  // 摘要中的文章详情栏位不全，只有部分，需要通过ID查看文章详情
  @JsonKey(name: 'lesson')
  DaoduLesson? lesson;

  DaoduUserThoughtsProfile(this.thought, this.lesson);

  factory DaoduUserThoughtsProfile.fromJson(Map<String, dynamic> srcJson) =>
      _$DaoduUserThoughtsProfileFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DaoduUserThoughtsProfileToJson(this);
}
