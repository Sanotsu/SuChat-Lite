import 'dart:convert';

import '../../models/douguo/douguo_recipe_comment_resp.dart';
import '../../models/douguo/douguo_recipe_resp.dart';
import '../../models/douguo/douguo_recommended_resp.dart';
import '../../models/douguo/douguo_search_resp.dart';
import 'douguo_api_wrapper.dart';

/// 豆果API管理器
/// 统一管理所有豆果源的API调用，提供保护措施
class DouguoApiManager {
  static final DouguoApiManager _instance = DouguoApiManager._internal();
  factory DouguoApiManager() => _instance;
  DouguoApiManager._internal();

  // 豆果源基础URL
  static const String _douguoApiBase = "https://apis.netstart.cn/douguo";

  /// 豆果推荐
  Future<DouguoRecommendedResp> getDouguoRecommendedList({
    // 默认0
    required int offset,
    // 默认10
    required int limit,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'douguo_recommended_${offset}_$limit';

    var respData = await newsGet(
      path: "$_douguoApiBase/home/recommended/$offset/$limit",
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 2),
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    return DouguoRecommendedResp.fromJson(respData);
  }

  // 获取豆果搜索列表
  Future<DouguoSearchResp> getDouguoSearchList({
    required String keyword,
    // 排序： <0>综合排序、<2>收藏最多、<3>学做最多
    int order = 0,
    // 搜索类型：<0>文章、<1>视频
    int type = 0,
    // 次级关键词
    String secondaryKeyword = "",
    // 分页偏移
    int offset = 0,
    // 每页大小
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    final cacheKey =
        'douguo_search_${keyword}_${order}_${type}_${secondaryKeyword}_${offset}_$limit';

    var respData = await newsGet(
      path: "$_douguoApiBase/recipe/search",
      queryParameters: {
        "keyword": keyword,
        "order": order,
        "type": type,
        "secondary_keyword": secondaryKeyword,
        "offset": offset,
        "limit": limit,
      },
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 2),
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    return DouguoSearchResp.fromJson(respData);
  }

  /// 获取菜谱详情
  Future<DouguoRecipeResp> getRecipeDetail({
    required String recipeId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'douguo_recipe_detail_$recipeId';

    var respData = await newsGet(
      path: "$_douguoApiBase/recipe/detail/$recipeId",
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    return DouguoRecipeResp.fromJson(respData);
  }

  // 获取菜谱的评论列表
  Future<DouguoRecipeCommentResp> getRecipeCommentList({
    required String recipeId,
    // 分页偏移
    int offset = 0,
    // 每页大小
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'douguo_recipe_comment_${recipeId}_${offset}_$limit';

    var respData = await newsGet(
      path: "$_douguoApiBase/recipe/flatcomments/$recipeId/$offset/$limit",
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    return DouguoRecipeCommentResp.fromJson(respData);
  }

  /// 清理所有缓存
  void clearAllCache() {
    DouguoApiWrapper().clearCache();
    DouguoApiWrapper().clearRequestLog();
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    return DouguoApiWrapper().getCacheStats();
  }
}

/// 便捷的全局访问方法
DouguoApiManager get newsApiManager => DouguoApiManager();
