import '../../../../core/api/base_api_manager.dart';
import '../models/one/one_base_models.dart';
import '../models/one/one_category_list.dart';
import '../models/one/one_daily_recommend.dart';
import '../models/one/one_detail_models.dart';
import '../models/one/one_user_collection.dart';
import 'one_config.dart';

/// 阅读API管理器
/// 统一管理所有阅读源的API调用，提供保护措施
class OneApiManager extends BaseApiManager<OneApiConfig> {
  static final OneApiManager _instance = OneApiManager._internal();
  factory OneApiManager() => _instance;
  OneApiManager._internal() : super(OneApiConfig());

  // 源基础URL
  static const String _oneBase = "https://apis.netstart.cn/one";

  /// 获取one每日推荐的内容
  Future<OneRecommend> getOneRecommend({
    // 日期参数需要为yyyy-MM-dd格式
    required String date,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'one_recommend_$date';

    var respData = await get(
      path: "$_oneBase/channel/one/$date",
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return OneBaseResp<OneRecommend>.fromJson(
      respData,
      (json) => OneRecommend.fromJson(json as Map<String, dynamic>),
    ).getDataOrThrow();
  }

  // 按照月份获取所有推荐内容
  Future<List<OneMonthRecommend>> getOneMonthRecommendList({
    // 日期参数需要为yyyy-MM格式
    required String month,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'one_recommend_list_$month';

    var respData = await get(
      path: "$_oneBase/feeds/list/$month",
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return OneBaseResp<List<OneMonthRecommend>>.fromJson(respData, (json) {
      if (json is List) {
        return json
            .whereType<Map<String, dynamic>>()
            .map((json) => OneMonthRecommend.fromJson(json))
            .toList();
      }
      return [];
    }).getDataOrThrow();
  }

  // 获取专题内容列表
  Future<List<OneTopic>> getOneTopicList({bool forceRefresh = false}) async {
    final cacheKey = 'one_topic_list';

    var respData = await get(
      path: "$_oneBase/banner/list/4",
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return OneBaseResp<List<OneTopic>>.fromJson(respData, (json) {
      if (json is List) {
        return json
            .whereType<Map<String, dynamic>>()
            .map((json) => OneTopic.fromJson(json))
            .toList();
      }
      return [];
    }).getDataOrThrow();
  }

  // 获取小记列表
  Future<List<OneDiary>> getOneDiaryList({
    // 小记编号，
    // 0获取首页，
    // 分页查询时，传入首页最后一个小记id，类似 2645963（即一般取上一个列表的最后一个）
    int? diaryId = 0,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'one_diary_list_$diaryId';

    var respData = await get(
      path: "$_oneBase/diary/square/more/$diaryId",
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return OneBaseResp<List<OneDiary>>.fromJson(respData, (json) {
      if (json is List) {
        return json
            .whereType<Map<String, dynamic>>()
            .map((json) => OneDiary.fromJson(json))
            .toList();
      }
      // 结果是放在data.list中
      if (json is Map<String, dynamic>) {
        return (json['list'] as List)
            .whereType<Map<String, dynamic>>()
            .map((json) => OneDiary.fromJson(json))
            .toList();
      }
      return [];
    }).getDataOrThrow();
  }

  // 按月获取分类文章列表
  Future<List<OneContent>> getOneContentListByMonth({
    // 文章分类:图文0、阅读1、问答3、音乐4、影视5、电台8
    required int category,
    // 月份，格式为yyyy-MM
    required String month,

    bool forceRefresh = false,
  }) async {
    final cacheKey = 'one_content_list_by_month_${category}_$month';

    var respData = await get(
      path: "$_oneBase/find/bymonth/$category/$month",
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return OneBaseResp<List<OneContent>>.fromJson(respData, (json) {
      if (json is List) {
        return json
            .whereType<Map<String, dynamic>>()
            .map((json) => OneContent.fromJson(json))
            .toList();
      }
      return [];
    }).getDataOrThrow();
  }

  // 获取榜单列表
  Future<List<OneRank>> getOneRankList({bool forceRefresh = false}) async {
    final cacheKey = 'one_rank_list';

    var respData = await get(
      path: "$_oneBase/find/rank",
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return OneBaseResp<List<OneRank>>.fromJson(respData, (json) {
      if (json is List) {
        return json
            .whereType<Map<String, dynamic>>()
            .map((json) => OneRank.fromJson(json))
            .toList();
      }
      return [];
    }).getDataOrThrow();
  }

  // 获取指定榜单详情列表
  Future<List<OneContent>> getOneRankContentList({
    // 榜单id
    required int id,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'one_rank_content_list_$id';

    var respData = await get(
      path: "$_oneBase/find/rank/$id",
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return OneBaseResp<List<OneContent>>.fromJson(respData, (json) {
      if (json is List) {
        return json
            .whereType<Map<String, dynamic>>()
            .map((json) => OneContent.fromJson(json))
            .toList();
      }
      return [];
    }).getDataOrThrow();
  }

  // 获取年度连载列表
  Future<List<OneContent>> getOneSerialListByYear({
    // 年份 yyyy
    required int year,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'one_serial_list_by_year_$year';

    var respData = await get(
      path: "$_oneBase/find/serial/byyear/$year",
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return OneBaseResp<List<OneContent>>.fromJson(respData, (json) {
      if (json is List) {
        return json
            .whereType<Map<String, dynamic>>()
            .map((json) => OneContent.fromJson(json))
            .toList();
      }
      return [];
    }).getDataOrThrow();
  }

  // 获取指定连载的章节目录列表
  Future<List<OneContent>> getOneSerialListBySerialId({
    // 连载id
    required int serialId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'one_serial_list_by_serial_id_$serialId';

    var respData = await get(
      path: "$_oneBase/find/serial/list/$serialId",
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return OneBaseResp<List<OneContent>>.fromJson(respData, (json) {
      if (json is List) {
        return json
            .whereType<Map<String, dynamic>>()
            .map((json) => OneContent.fromJson(json))
            .toList();
      }
      return [];
    }).getDataOrThrow();
  }

  // 获取图文详情
  // 图文是一日一篇，所以用日期查询
  Future<OneHpDetail> getOneHpDetail({
    // 日期：yyyy-MM-dd
    required String date,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'one_hp_detail_$date';

    var respData = await get(
      path: "$_oneBase/hp/bydate/$date",
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return OneBaseResp<OneHpDetail>.fromJson(
      respData,
      (json) => OneHpDetail.fromJson(json as Map<String, dynamic>),
    ).getDataOrThrow();
  }

  // 获取文章详情
  Future<OneContentDetail> getOneContentDetail({
    // 文章分类:阅读essay 、问答question、 音乐music、 影视movie 、电台radio 、专题topic、连载serialcontent
    required String category,
    // 文章id/内容id
    required int contentId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'one_content_detail_${category}_$contentId';

    var respData = await get(
      path: "$_oneBase/$category/htmlcontent/$contentId",
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return OneBaseResp<OneContentDetail>.fromJson(
      respData,
      (json) => OneContentDetail.fromJson(json as Map<String, dynamic>),
    ).getDataOrThrow();
  }

  // 获取文章评论列表
  Future<OneCommentList> getOneCommentList({
    // 文章分类:阅读essay 、问答question、 音乐music、 影视movie 、电台radio 、连载serial
    required String categoryName,
    // 文章id/内容id
    required int contentId,
    // 评论id
    // 如果是0 这查询首页
    // 分页查询时，传入首页最后一个评论id，类似137385 （即一般取上页列表的最后一个）
    required int commentId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'one_comment_list_${categoryName}_${contentId}_$commentId';

    var respData = await get(
      path:
          "$_oneBase/comment/praiseandtime/$categoryName/$contentId/$commentId",
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return OneBaseResp<OneCommentList>.fromJson(
      respData,
      (json) => OneCommentList.fromJson(json as Map<String, dynamic>),
    ).getDataOrThrow();

    // return OneBaseResp<List<OneComment>>.fromJson(respData, (json) {
    //   if (json is List) {
    //     return json
    //         .whereType<Map<String, dynamic>>()
    //         .map((json) => OneComment.fromJson(json))
    //         .toList();
    //   }
    //   return [];
    // }).getDataOrThrow();
  }

  // 获取搜索结果
  Future<List<OneContent>> getOneSearchList({
    // 文章分类: 图文hp、阅读reading、音乐 music、影视 movie、ONE电台 radio、作者/音乐人 author
    required String categoryName,
    // 搜索关键词
    required String keyword,
    // 分页页码
    required int page,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'one_search_list_${categoryName}_${keyword}_$page';

    var respData = await get(
      path: "$_oneBase/search/$categoryName/$keyword/$page",
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    var data = OneBaseResp<OneSearchList>.fromJson(
      respData,
      (json) => OneSearchList.fromJson(json as Map<String, dynamic>),
    ).getDataOrThrow();

    return data.list ?? [];
  }

  // 获取热门作者
  Future<List<OneAuthor>> getOneHotAuthorList({
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'one_hot_author_list';

    var respData = await get(
      path: "$_oneBase/author/hot",
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return OneBaseResp<List<OneAuthor>>.fromJson(respData, (json) {
      if (json is List) {
        return json
            .whereType<Map<String, dynamic>>()
            .map((json) => OneAuthor.fromJson(json))
            .toList();
      }
      return [];
    }).getDataOrThrow();
  }

  // 获取指定作者作品列表
  Future<List<OneRecommendContent>> getOneAuthorContentList({
    // 作者id
    required int authorId,
    // 页码
    int pageNum = 0,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'one_author_content_list_${authorId}_$pageNum';

    var respData = await get(
      path: "$_oneBase/author/works",
      queryParameters: {'author_id': authorId, 'page_num': pageNum},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return OneBaseResp<List<OneRecommendContent>>.fromJson(respData, (json) {
      if (json is List) {
        return json
            .whereType<Map<String, dynamic>>()
            .map((json) => OneRecommendContent.fromJson(json))
            .toList();
      }
      return [];
    }).getDataOrThrow();
  }

  // 获取用户详情
  Future<OneUser> getOneUserDetail({
    // 用户id
    required String userId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'one_user_detail_$userId';

    var respData = await get(
      path: "$_oneBase/user/info/$userId",
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return OneBaseResp<OneUser>.fromJson(
      respData,
      (json) => OneUser.fromJson(json as Map<String, dynamic>),
    ).getDataOrThrow();
  }

  // 获取用户关注作者列表
  Future<List<OneAuthor>> getOneUserFollowAuthorList({
    // 用户id
    required String userId,
    // 0为获取第一页，获取关注列表分页时取当前页列表的最后一个
    required String lastId,
    // 0获取作者详情 1只获取作者id
    required String type,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'one_user_follow_author_list_${userId}_${lastId}_$type';

    var respData = await get(
      path: "$_oneBase/user/follow_list",
      queryParameters: {'uid': userId, 'last_id': lastId, 'type': type},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return OneBaseResp<List<OneAuthor>>.fromJson(respData, (json) {
      if (json is List) {
        return json
            .whereType<Map<String, dynamic>>()
            .map((json) => OneAuthor.fromJson(json))
            .toList();
      }
      return [];
    }).getDataOrThrow();
  }

  // 获取用户公开小记列表
  Future<List<OneDiary>> getOneUserDiaryList({
    // 用户id
    required String userId,
    // 0为获取第一页，获取小记分页时取当前页列表的最后一个
    required String diaryId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'one_user_diary_list_${userId}_$diaryId';

    var respData = await get(
      path: "$_oneBase/other/diary/public/$userId/$diaryId",
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    // return OneBaseResp<List<OneDiary>>.fromJson(respData, (json) {
    //   if (json is List) {
    //     return json
    //         .whereType<Map<String, dynamic>>()
    //         .map((json) => OneDiary.fromJson(json))
    //         .toList();
    //   }
    //   return [];
    // }).getDataOrThrow();

    var data = OneBaseResp<OneDiaryList>.fromJson(
      respData,
      (json) => OneDiaryList.fromJson(json as Map<String, dynamic>),
    ).getDataOrThrow();

    return data.list ?? [];
  }

  // 获取用户收藏文章列表
  // 根据不同分类返回不同类型的收藏内容
  Future<OneBaseResp<List<T>>> getOneUserCollectionList<T>({
    // 用户id
    required String userId,
    // 分类id: 图文0、阅读1、问答2、音乐4 、影视5、连载6、电台8、歌单9
    required String category,
    // 0为获取第一页，获取小记分页时取当前页列表的最后一个
    required int contentId,
    bool forceRefresh = false,
  }) async {
    final cacheKey =
        'one_user_collection_list_${userId}_${category}_$contentId';

    var respData = await get(
      path: "$_oneBase/othercollection/$userId/more/$category/$contentId",
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return OneBaseResp.fromJson(respData, (json) {
      if (json is List) {
        return json.whereType<Map<String, dynamic>>().map((item) {
          // 根据分类返回不同类型的对象
          switch (category) {
            case '0': // 图文
              return OneUserHpCollection.fromJson(item) as T;
            case '1': // 阅读
              return OneUserReadingCollection.fromJson(item) as T;
            case '2': // 问答
              return OneUserQuestionCollection.fromJson(item) as T;
            case '4': // 音乐
              return OneUserMusicCollection.fromJson(item) as T;
            case '5': // 影视
              return OneUserMovieCollection.fromJson(item) as T;
            case '8': // 电台
              return OneUserRadioCollection.fromJson(item) as T;
            case '9': // 歌单
              return OneUserPlaylistCollection.fromJson(item) as T;
            default:
              throw Exception('不支持的收藏分类: $category');
          }
        }).toList();
      }
      return <T>[];
    });
  }

  // 继承自BaseApiManager的clearAllCache()和getCacheStats()方法
}

/// 便捷的全局访问方法
OneApiManager get readingApiManager => OneApiManager();
