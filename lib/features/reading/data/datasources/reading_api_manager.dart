import '../../../../core/api/base_api_manager.dart';
import '../models/daodu_models.dart';
import 'reading_config.dart';

/// 阅读API管理器
/// 统一管理所有阅读源的API调用，提供保护措施
class ReadingApiManager extends BaseApiManager<ReadingApiConfig> {
  static final ReadingApiManager _instance = ReadingApiManager._internal();
  factory ReadingApiManager() => _instance;
  ReadingApiManager._internal() : super(ReadingApiConfig());

  // 源基础URL
  static const String _daoduBase = "https://apis.netstart.cn/daodu/";

  /// 获取岛读首页列表
  Future<List<DaoduLesson>> getDaoduLessonList({
    // 开始日期 格式 20250101 补全0
    required int from,
    // 结束日期 格式 20250101 补全0
    required int to,
    // 更新时间 格式 1664527511 不带毫秒的时间戳
    int? updatedAt,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'daodu_lesson_list_${from}_${to}_$updatedAt';

    var respData = await get(
      path: "$_daoduBase/lessons",
      queryParameters: {"from": from, "to": to, "updated_at": updatedAt},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return getDaoduLessonsRespList(respData);
  }

  /// 获取岛读今日推荐的探索列表
  Future<DaoduTodayRecommendsResp> getDaoduTodayRecommendList({
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'daodu_today_recommend_list';

    var respData = await get(
      path: "$_daoduBase/today_recommends",
      queryParameters: {},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return DaoduTodayRecommendsResp.fromJson(respData);
  }

  /// 获取文章详情
  Future<DaoduLesson> getDaoduLessonDetail({
    required String id,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'daodu_lesson_detail_$id';

    var respData = await get(
      path: "$_daoduBase/lessons/$id",
      queryParameters: {},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return DaoduLesson.fromJson(respData);
  }

  /// 获取文章状态
  Future<DaoduActivityStats> getDaoduLessonActivityStats({
    required String id,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'daodu_lesson_activity_stats_$id';

    var respData = await get(
      path: "$_daoduBase/lessons/$id/activity_stats",
      queryParameters: {},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return DaoduActivityStats.fromJson(respData);
  }

  /// 获取文章评论列表
  Future<List<DaoduComment>> getDaoduLessonCommentList({
    required String id,
    int offset = 0,
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'daodu_lesson_comment_list_${id}_${offset}_$limit';

    var respData = await get(
      path: "$_daoduBase/lessons/$id/comments",
      queryParameters: {"offset": offset, "limit": limit},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return getDaoduCommentsRespList(respData);
  }

  /// 获取评论的回复(只有一条数据的列表)
  Future<List<DaoduComment>> getDaoduCommentReplyList({
    required String id,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'daodu_comment_reply_list_$id';

    var respData = await get(
      path: "$_daoduBase/comments/$id/comments",
      queryParameters: {},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return getDaoduCommentsRespList(respData);
  }

  /// 获取用户详情
  Future<DaoduUserDetail> getDaoduUserDetail({
    required String id,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'daodu_user_detail_$id';

    var respData = await get(
      path: "$_daoduBase/users/$id",
      queryParameters: {},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return DaoduUserDetail.fromJson(respData);
  }

  /// 获取用户摘要统计
  Future<DaoduUserSnippetsCount> getDaoduUserSnippetsCount({
    required String id,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'daodu_user_snippets_count_$id';

    var respData = await get(
      path: "$_daoduBase/users/$id/snippets/count",
      queryParameters: {},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return DaoduUserSnippetsCount.fromJson(respData);
  }

  /// 获取用户摘要列表
  Future<List<DaoduUserSnippetsDetail>> getDaoduUserSnippetList({
    required String id,
    int offset = 0,
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'daodu_user_snippet_list_${id}_${offset}_$limit';

    var respData = await get(
      path: "$_daoduBase/users/$id/snippets_detail",
      queryParameters: {"offset": offset, "limit": limit},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return getDaoduUserSnippetsDetailRespList(respData);
  }

  /// 获取用户喜欢文章列表
  Future<List<DaoduLesson>> getDaoduUserFavouriteLessonList({
    required String id,
    int offset = 0,
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'daodu_user_favourite_lessons_${id}_${offset}_$limit';

    var respData = await get(
      path: "$_daoduBase/users/$id/favourite_lessons",
      queryParameters: {"offset": offset, "limit": limit},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return getDaoduLessonsRespList(respData);
  }

  /// 获取用户想法列表
  Future<List<DaoduUserThoughtsProfile>> getDaoduUserThoughtsProfileList({
    required String id,
    int offset = 0,
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'daodu_user_thoughts_profile_${id}_${offset}_$limit';

    var respData = await get(
      path: "$_daoduBase/users/$id/thoughts_profile",
      queryParameters: {"offset": offset, "limit": limit},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return getDaoduUserThoughtsProfileRespList(respData);
  }

  // 继承自BaseApiManager的clearAllCache()和getCacheStats()方法
}

/// 便捷的全局访问方法
ReadingApiManager get readingApiManager => ReadingApiManager();
