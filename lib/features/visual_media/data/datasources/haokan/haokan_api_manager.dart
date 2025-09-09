import '../../../../../core/api/base_api_manager.dart';

import '../../models/haokan/haokan_models.dart';
import 'haokan_config.dart';

/// 好看漫画API管理器
/// 统一管理所有好看漫画源的API调用，提供保护措施
class HaokanApiManager extends BaseApiManager<HaokanApiConfig> {
  static final HaokanApiManager _instance = HaokanApiManager._internal();
  factory HaokanApiManager() => _instance;
  HaokanApiManager._internal() : super(HaokanApiConfig());

  // 源基础URL
  static const String _haokanBase = "https://apis.netstart.cn/haokan";

  /// 获取好看漫画首页列表
  Future<HaokanIndex> getHaokanIndex({bool forceRefresh = false}) async {
    final cacheKey = 'haokan_index';

    var respData = await get(
      path: "$_haokanBase/index/index",
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return HaokanBaseResp<HaokanIndex>.fromJson(
      respData,
      (json) => HaokanIndex.fromJson(json as Map<String, dynamic>),
    ).getDataOrThrow();
  }

  // 获取首页换一换的推荐
  Future<HaokanTab> getHaokanTabExchange({
    required int tabId,
    bool forceRefresh = false,
  }) async {
    // 换一换可能一直在点击
    final cacheKey =
        'haokan_tab_exchange_${tabId}_${DateTime.now().millisecondsSinceEpoch}';

    var respData = await get(
      path: "$_haokanBase/index/exchange",
      queryParameters: {"id": tabId},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return HaokanBaseResp<HaokanTab>.fromJson(
      respData,
      (json) => HaokanTab.fromJson(json as Map<String, dynamic>),
    ).getDataOrThrow();
  }

  // 获取首页某个分类更多数据
  Future<List<HaokanComic>> getHaokanTabMore({
    required int tabId,
    int page = 1,
    int size = 20,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'haokan_tab_more_${tabId}_${page}_$size';

    var respData = await get(
      path: "$_haokanBase/index/more",
      queryParameters: {"id": tabId, "p": page, "n": size},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return HaokanBaseResp<List<HaokanComic>>.fromJson(respData, (json) {
      if (json is List) {
        return json
            .whereType<Map<String, dynamic>>()
            .map((json) => HaokanComic.fromJson(json))
            .toList();
      }
      return [];
    }).getDataOrThrow();
  }

  // 获取榜单漫画列表数据
  Future<List<HaokanComic>> getHaokanComicTopList({
    // 1 人气榜; 2 新作榜; 4 男生榜; 5 女生榜; 6 催更榜
    required int topId,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'haokan_comic_top_list_$topId';

    var respData = await get(
      path: "$_haokanBase/top/list",
      queryParameters: {"id": topId, "p": page},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return HaokanBaseResp<List<HaokanComic>>.fromJson(respData, (json) {
      if (json is List) {
        return json
            .whereType<Map<String, dynamic>>()
            .map((json) => HaokanComic.fromJson(json))
            .toList();
      }
      return [];
    }).getDataOrThrow();
  }

  // 通过分类获取漫画列表
  Future<List<HaokanComic>> getHaokanComicListByCategory({
    required int categoryId,
    // 完结状态
    int comicEndStatus = 0,
    // 0 免费 1 付费
    int comicFreeStatus = 0,
    // 排序方式
    int comicSortType = 0,
    int page = 1,
    int size = 20,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'haokan_comic_list_by_category_$categoryId';

    // 手动设置全部分类为99,如果传入99,则不添加到参数中
    var params = {
      "end": comicEndStatus,
      "free": comicFreeStatus,
      "sort": comicSortType,
      "p": page,
      "n": size,
    };
    if (categoryId != 99) {
      params["cateid"] = categoryId;
    }

    var respData = await get(
      path: "$_haokanBase/book/list",
      queryParameters: params,
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return HaokanBaseResp<List<HaokanComic>>.fromJson(respData, (json) {
      if (json is List) {
        return json
            .whereType<Map<String, dynamic>>()
            .map((json) => HaokanComic.fromJson(json))
            .toList();
      }
      return [];
    }).getDataOrThrow();
  }

  // 获取热门搜索漫画列表
  Future<List<HaokanComic>> getHaokanComicListByHotSearch({
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'haokan_comic_list_by_hot_search';

    var respData = await get(
      path: "$_haokanBase/so/hot",
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return HaokanBaseResp<List<HaokanComic>>.fromJson(respData, (json) {
      if (json is List) {
        return json
            .whereType<Map<String, dynamic>>()
            .map((json) => HaokanComic.fromJson(json))
            .toList();
      }

      // 热门搜索结果的data中结构是 data:{list:[<动画列表>],ad:{}}
      if (json is Map<String, dynamic>) {
        return (json['list'] as List)
            .whereType<Map<String, dynamic>>()
            .map((json) => HaokanComic.fromJson(json))
            .toList();
      }
      return [];
    }).getDataOrThrow();
  }

  // 通过关键字搜索漫画列表
  Future<List<HaokanComic>> getHaokanComicListByKeyword({
    required String keyword,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'haokan_comic_list_by_keyword_$keyword';
    var respData = await get(
      path: "$_haokanBase/so/comic",
      // 搜索结果只有1页，没有更多分页，所以写死在这里
      queryParameters: {"keyword": keyword, "p": 1},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    var result = HaokanBaseResp<HaokanQueryResult>.fromJson(
      respData,
      (json) => HaokanQueryResult.fromJson(json as Map<String, dynamic>),
    ).getDataOrThrow();

    return result.list ?? [];
  }

  // 获取每日更新漫画列表
  Future<List<HaokanComic>> getHaokanComicListByDaily({
    // 今天0、昨天1、前天2,依此类推，这里需要自己确定前几天是星期几。
    int dailyId = 0,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'haokan_comic_list_by_daily_$dailyId';
    var respData = await get(
      path: "$_haokanBase/day/list",
      // 同样只有第一页，没有更多分页，所以写死在这里
      queryParameters: {"id": dailyId, "p": 1},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return HaokanBaseResp<List<HaokanComic>>.fromJson(respData, (json) {
      if (json is List) {
        return json
            .whereType<Map<String, dynamic>>()
            .map((json) => HaokanComic.fromJson(json))
            .toList();
      }
      return [];
    }).getDataOrThrow();
  }

  // 获取指定漫画的漫画详情数据
  Future<HaokanComic> getHaokanComicDetail({
    required int comicId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'haokan_comic_detail_$comicId';
    var respData = await get(
      path: "$_haokanBase/book/show",
      queryParameters: {"id": comicId},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return HaokanBaseResp<HaokanComic>.fromJson(
      respData,
      (json) => HaokanComic.fromJson(json as Map<String, dynamic>),
    ).getDataOrThrow();
  }

  // 获取相关漫画推荐列表
  Future<List<HaokanComic>> getHaokanComicRecommendList({
    required int comicId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'haokan_comic_recommend_list_$comicId';
    var respData = await get(
      path: "$_haokanBase/book/recommend",
      queryParameters: {"id": comicId},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return HaokanBaseResp<List<HaokanComic>>.fromJson(respData, (json) {
      if (json is List) {
        return json
            .whereType<Map<String, dynamic>>()
            .map((json) => HaokanComic.fromJson(json))
            .toList();
      }
      return [];
    }).getDataOrThrow();
  }

  // 获取漫画章节列表
  Future<List<HaokanChapter>> getHaokanComicChapterList({
    required int comicId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'haokan_comic_chapter_list_$comicId';
    var respData = await get(
      path: "$_haokanBase/book/listChapter",
      queryParameters: {"id": comicId},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return HaokanBaseResp<List<HaokanChapter>>.fromJson(respData, (json) {
      if (json is List) {
        return json
            .whereType<Map<String, dynamic>>()
            .map((json) => HaokanChapter.fromJson(json))
            .toList();
      }
      return [];
    }).getDataOrThrow();
  }

  // 获取漫画章节列表详情
  // 同样返回 HaokanChapter，但会多一个 piclist 字段，就是章节图片地址
  Future<HaokanChapter> getHaokanComicChapterDetail({
    required int chapterId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'haokan_comic_chapter_detail_$chapterId';
    var respData = await get(
      path: "$_haokanBase/book/showChapter",
      queryParameters: {"id": chapterId},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return HaokanBaseResp<HaokanChapter>.fromJson(
      respData,
      (json) => HaokanChapter.fromJson(json as Map<String, dynamic>),
    ).getDataOrThrow();
  }

  // 获取指定漫画的热门评论列表
  Future<List<HaokanComment>> getHaokanComicHotCommentList({
    required int comicId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'haokan_comic_hot_comment_list_$comicId';
    var respData = await get(
      path: "$_haokanBase/comment/listHot",
      queryParameters: {"did": comicId},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return HaokanBaseResp<List<HaokanComment>>.fromJson(respData, (json) {
      if (json is List) {
        return json
            .whereType<Map<String, dynamic>>()
            .map((json) => HaokanComment.fromJson(json))
            .toList();
      }
      return [];
    }).getDataOrThrow();
  }

  // 获取指定漫画的评论数量
  Future<int> getHaokanComicCommentCount({
    required int comicId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'haokan_comic_comment_count_$comicId';
    var respData = await get(
      path: "$_haokanBase/comment/count",
      queryParameters: {"did": comicId},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    // 这个漫画评论数量的响应结果的data结构类似: data:[{"128": 1598}]
    // 其中"128"是漫画id，1598是评论数量
    return HaokanBaseResp<int>.fromJson(respData, (json) {
      if (json is List && json.isNotEmpty) {
        return int.tryParse((json.first as Map).values.first.toString()) ?? 0;
      }
      return 0;
    }).getDataOrThrow();
  }

  // 获取指定漫画的全部评论列表
  Future<List<HaokanComment>> getHaokanComicCommentList({
    required int comicId,
    int page = 1,
    int size = 20,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'haokan_comic_comment_list_$comicId';
    var respData = await get(
      path: "$_haokanBase/comment/list",
      queryParameters: {"did": comicId, "pn": page, "ps": size},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return HaokanBaseResp<List<HaokanComment>>.fromJson(respData, (json) {
      if (json is List) {
        return json
            .whereType<Map<String, dynamic>>()
            .map((json) => HaokanComment.fromJson(json))
            .toList();
      }
      return [];
    }).getDataOrThrow();
  }

  // 继承自BaseApiManager的clearAllCache()和getCacheStats()方法
}

/// 便捷的全局访问方法
HaokanApiManager get haokanApiManager => HaokanApiManager();
