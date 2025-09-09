import '../../../../../core/api/base_api_manager.dart';
import '../../models/douguo/douguo_recipe_comment_resp.dart';
import '../../models/douguo/douguo_recipe_resp.dart';
import '../../models/douguo/douguo_recommended_resp.dart';
import '../../models/douguo/douguo_search_resp.dart';
import 'douguo_config.dart';

/// 豆果API管理器
/// 统一管理所有豆果源的API调用，提供保护措施
class DouguoApiManager extends BaseApiManager<DouguoApiConfig> {
  static final DouguoApiManager _instance = DouguoApiManager._internal();
  factory DouguoApiManager() => _instance;
  DouguoApiManager._internal() : super(DouguoApiConfig());

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

    var respData = await get(
      path: "$_douguoApiBase/home/recommended/$offset/$limit",
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 2),
    );

    respData = processResponse(respData);

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

    var respData = await get(
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

    respData = processResponse(respData);

    return DouguoSearchResp.fromJson(respData);
  }

  /// 获取菜谱详情
  Future<DouguoRecipeResp> getRecipeDetail({
    required String recipeId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'douguo_recipe_detail_$recipeId';

    var respData = await get(
      path: "$_douguoApiBase/recipe/detail/$recipeId",
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

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

    var respData = await get(
      path: "$_douguoApiBase/recipe/flatcomments/$recipeId/$offset/$limit",
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return DouguoRecipeCommentResp.fromJson(respData);
  }

  // 继承自BaseApiManager的clearAllCache()和getCacheStats()方法
}

/// 便捷的全局访问方法
DouguoApiManager get douguoApiManager => DouguoApiManager();
