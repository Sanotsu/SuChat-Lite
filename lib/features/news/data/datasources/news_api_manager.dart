import '../../../../core/api/base_api_manager.dart';
import '../../../../core/utils/get_app_key_helper.dart';
import '../../../../shared/constants/default_models.dart';
import '../models/baike_history_in_today_resp.dart';
import '../models/duomoyu_resp.dart';
import '../models/uo_ithome_resp.dart';
import '../models/momoyu_resp.dart';
import '../models/news_api_resp.dart';
import '../models/news_now_resp.dart';
import '../models/readhub_resp.dart';
import '../models/sina_roll_news_resp.dart';
import '../models/sut_bbc_news_resp.dart';
import '../models/uo_toutiao_news_resp.dart';
import '../models/uo_zhihu_daily_resp.dart';
import 'news_config.dart';

/// 新闻API管理器
/// 统一管理所有新闻源的API调用，提供保护措施
class NewsApiManager extends BaseApiManager<NewsApiConfig> {
  static final NewsApiManager _instance = NewsApiManager._internal();
  factory NewsApiManager() => _instance;
  NewsApiManager._internal() : super(NewsApiConfig());

  // 新闻源基础URL

  // 热点聚合
  // 摸摸鱼
  static const String _momoyuBase = "https://momoyu.cc/api";
  // 多模鱼
  static const String _duomoyuBase = "https://duomoyu.com/api";
  // 这个和上面的类似，暂时不单独显示了
  static const String _newsnowBase = "https://newsnow.busiyi.world/api";

  // 来源官网
  static const String _readhubBase = "https://api.readhub.cn";
  static const String _sinaRollNewsBase =
      "https://feed.mix.sina.com.cn/api/roll/get";

  // 外网新闻源
  static const String _newsapiBase = "https://newsapi.org/v2";
  static const String _sutBbcNewsBase = "https://bbc-news-api.vercel.app/news";

  // 野源数据（随时不可用）
  // 头条新闻
  static const String _toutiaoBase = "https://www.toutiao.com/api/pc/feed/";
  // it之家
  static const String _ithomeNewsBase =
      "https://api.ithome.com/json/newslist/news";
  // 知乎日报
  static const String _uoZhihudailyBase = "https://apis.netstart.cn/zhihudaily";
  // 历史上的今天
  // static const String _baikeHistoryInTodayBase = "https://api.asilu.com/today";
  static const String _baikeHistoryInTodayBase =
      "https://60s.viki.moe/v2/today_in_history";

  /// 获取NewsAPI新闻列表
  Future<NewsApiResp> getNewsapiList({
    int page = 1,
    int pageSize = 100,
    // 热点 top-headlines | 所有 everything
    String type = "top-headlines",
    String? query,
    String? category,
    bool forceRefresh = false,
  }) async {
    final params = {
      "apiKey": getStoredUserKey(
        "USER_NEWSAPI_API_KEY",
        DefaultApiKeys.newsApiKey,
      ),
      // 新闻来源，可以在 https://newsapi.org/v2/top-headlines/sources 查到相关信息(结构体的id栏位)

      /// 不能和 country 或 category 一起用
      // "sources": '',
      "page": page,
      // 默认100。为了减少请求次数，可以保留个大数字
      "pageSize": pageSize,
    };

    // 2024-11-06 就只给两个选项，热榜和所有的查询
    if (type == "top-headlines") {
      /// 热榜时，这几个栏位不可都为空: sources, q, country, category
      params.addAll({
        // 查询热榜暂时不用关键字查询，默认分类显示所有
        // "q": query ?? "",

        // ISO 3166-1编码的两个字母的国家编号【目前免费的看起来只能用 us 才有值】
        // 不能和 sources 参数一起用
        // https://www.iso.org/obp/ui/#search
        // "country": 'us',

        // 新闻的分类： business entertainment general health science sports technology
        // 不能和 sources 参数一起用
        "category": category ?? 'general',
      });
    } else {
      // 所有搜索时，后面栏位不可全为空： q, qInTitle, sources, domains.
      params.addAll({
        // 搜索的关键字(带双引号可以强制匹配)
        // 2024-11-07 查询热榜时只有分类就不带上查询了，查询就从所有新闻来
        "q": "$query",

        // 搜索限制到的字段,可以用逗号添加多个
        // title | description | content
        "searchIn": "title,description",

        // 新闻的网域,多个用逗号连接，例如 bbc.co.uk,techcrunch.com,engadget.com
        // "domains": "",

        // 排除的域,多个用逗号连接，例如 bbc.co.uk,techcrunch.com,engadget.com
        // "excludeDomains": "",

        // 搜索的时间范围，ISO 8601 格式字符串
        // "from": '',
        // "to": '',

        // 标题的语言,可选性
        // ar de en es fr he it nl no pt ru sv ud zh
        // "language": "zh",

        // 排序方式
        // relevancy: 与q关系更密切的文章排在前面
        // popularity: 来自流行来源和出版商的文章优先
        // publishedAt(默认): 最新文章排在第一位
        "sortBy": "publishedAt",
      });
    }

    final cacheKey =
        'newsapi_${type}_${category ?? 'general'}_${page}_$pageSize';

    var respData = await get(
      path: "$_newsapiBase/$type",
      queryParameters: params,
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 15),
    );

    respData = processResponse(respData);

    return NewsApiResp.fromJson(respData);
  }

  /// 获取摸摸鱼指定分类
  Future<MomoyuResp<MMYIdData>> getMomoyuList({
    // type为item时，需要指定类别
    int id = 1,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'momoyu_item_$id';

    var respData = await get(
      path: "$_momoyuBase/hot/item",
      queryParameters: {"id": id},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 5),
    );

    respData = processResponse(respData);

    if (respData["status"] != 100000) {
      throw Exception("查询数据失败，请稍候重试");
    }

    return MomoyuResp.fromJson(
      respData,
      (i) => MMYIdData.fromJson(i as Map<String, dynamic>),
    );
  }

  /// 获取摸摸鱼在线人数
  Future<MomoyuResp<int>> getMomoyuUserCount({
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'momoyu_user_count';

    var respData = await get(
      path: "$_momoyuBase/user/count",
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 1),
    );

    respData = processResponse(respData);

    return MomoyuResp.fromJson(
      respData,
      (i) => int.tryParse(i.toString()) ?? 0,
    );
  }

  /// 获取ReadHub新闻列表
  Future<ReadhubResp> getReadhubList({
    int page = 1,
    int size = 10,
    int type = 999,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'readhub_${type}_${page}_$size';

    // 热点新闻自定义 type
    final path = type == 999
        ? "$_readhubBase/topic/list"
        : "$_readhubBase/news/list";

    var respData = await get(
      path: path,
      queryParameters: type == 999
          ? {"page": page, "size": size}
          : {"type": type, "page": page, "size": size},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 2),
    );

    respData = processResponse(respData);

    if (respData["data"] == null) {
      throw Exception("返回结果不正确: $respData");
    }

    return ReadhubResp.fromJson(respData["data"]);
  }

  /// 获取新浪滚动新闻
  Future<SinaRollNewsResp> getSinaRollNewsList({
    int page = 1,
    int size = 10,
    int lid = 2509,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'sina_roll_news_${lid}_${page}_$size';

    var respData = await get(
      path: _sinaRollNewsBase,
      queryParameters: {"pageid": 153, "lid": lid, "page": page, "num": size},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 5),
    );

    respData = processResponse(respData);

    if (respData["result"] == null) {
      throw Exception("返回结果不正确: $respData");
    }

    return SinaRollNewsResp.fromJson(respData["result"]);
  }

  /// 获取今日头条新闻
  Future<UoToutiaoNewsResp> getUoToutiaoNewsList({
    String? category = "__all__",
    // 请求时，客户端带上 ?max_behot_time=xxx，以获取更早的热门内容（类似分页）
    int? maxBehotTime,
    bool forceRefresh = false,
  }) async {
    final cacheKey =
        'uo_toutiao_news_${category ?? "__all__"}_${maxBehotTime ?? 0}';

    var respData = await get(
      path: _toutiaoBase,
      queryParameters: maxBehotTime != null
          ? {"category": category, "max_behot_time": maxBehotTime}
          : {"category": category},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 5),
    );

    respData = processResponse(respData);

    return UoToutiaoNewsResp.fromJson(respData);
  }

  /// 获取IT之家新闻
  Future<UoItHomeResp> getUoItHomeList({bool forceRefresh = false}) async {
    final cacheKey = 'uo_ithome';

    var respData = await get(
      path: _ithomeNewsBase,
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return UoItHomeResp.fromJson(respData);
  }

  /// 获取第三方BBC新闻
  Future<SutBbcNewsResp> getSutBbcNewsList({
    String lang = 'chinese',
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'sut_bbc_news_$lang';

    var respData = await get(
      path: _sutBbcNewsBase,
      queryParameters: {"lang": lang},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return SutBbcNewsResp.fromJson(respData);
  }

  /// 获取多摸鱼新闻源列表(动态分类)
  /// 2026-09-04 API 改版：/api/{分类} 改为 /api/news/sources + /api/news/rankings/{slug}
  Future<List<DuomoyuSource>> getDuomoyuSources({
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'duomoyu_news_sources';

    var respData = await get(
      path: "$_duomoyuBase/news/sources",
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      // 源列表变动低频，缓存放宽
      cacheDuration: const Duration(minutes: 30),
    );

    respData = processResponse(respData);

    final resp = DuomoyuSourcesResp.fromJson(respData);
    if (resp.success != true || resp.data?.sources == null) {
      throw Exception("查询新闻源失败，请稍候重试");
    }

    final sources = resp.data!.sources!;
    sources.sort();
    return sources;
  }

  /// 获取多摸鱼指定源热榜
  Future<DuomoyuRankingResp> getDuomoyuRanking({
    required String slug,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'duomoyu_rankings_$slug';

    var respData = await get(
      path: "$_duomoyuBase/news/rankings/$slug",
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 5),
    );

    respData = processResponse(respData);

    final resp = DuomoyuRankingResp.fromJson(respData);
    if (resp.success != true || resp.data == null) {
      throw Exception("查询热榜失败，请稍候重试");
    }

    return resp;
  }

  /// 获取newsnow指定分类
  Future<NewsNowResp> getNewsNowList({
    // type为item时，需要指定类别
    String id = "baidu",
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'newsnow_item_$id';

    var respData = await get(
      path: "$_newsnowBase/s",
      queryParameters: {"id": id},
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 3),
    );

    respData = processResponse(respData);

    return NewsNowResp.fromJson(respData);
  }

  /// 获取第三方知乎日报数据
  Future<UoZhihuDailyResp> getUoZhihuDailyList({
    // date需要是yyyyMMDD格式，不传则默认最新的
    String? date,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'uo_zhihu_daily_$date';
    String path = "";
    if (date == null || date == "latest") {
      path = "$_uoZhihudailyBase/stories/latest";
    } else {
      // 注意：如果before/20250812，其实是查询20250811的数据
      path = "$_uoZhihudailyBase/stories/before/$date";
    }

    var respData = await get(
      path: path,
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    return UoZhihuDailyResp.fromJson(respData);
  }

  /// 获取百度百科历史上的今天
  Future<BaikeHistoryInTodayResp> getBaikeHistoryInTodayList({
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'baike_history_in_today';

    var respData = await get(
      path: _baikeHistoryInTodayBase,
      forceRefresh: forceRefresh,
      customCacheKey: cacheKey,
      cacheDuration: const Duration(minutes: 10),
    );

    respData = processResponse(respData);

    if (respData["data"] == null) {
      throw Exception("返回结果不正确: $respData");
    }

    return BaikeHistoryInTodayResp.fromJson(respData["data"]);
  }

  // 继承自BaseApiManager的clearAllCache()和getCacheStats()方法
}

/// 便捷的全局访问方法
NewsApiManager get newsApiManager => NewsApiManager();
