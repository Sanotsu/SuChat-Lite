//api with out console logs
import 'package:tmdb_api/tmdb_api.dart';

import '../../../../../core/utils/get_app_key_helper.dart';
import '../../../../../shared/constants/default_models.dart';
import '../../models/tmdb/tmdb_all_image_resp.dart';
import '../../models/tmdb/tmdb_movie_detail_resp.dart';
import '../../models/tmdb/tmdb_mt_credit_resp.dart';
import '../../models/tmdb/tmdb_mt_review_resp.dart';
import '../../models/tmdb/tmdb_person_credit_resp.dart';
import '../../models/tmdb/tmdb_person_detail_resp.dart';
import '../../models/tmdb/tmdb_result_resp.dart';
import '../../models/tmdb/tmdb_tv_detail_resp.dart';
import 'custom_discover.dart';

// 转换方法
// 手动将 Map<dynamic, dynamic> 转为 Map<String, dynamic>
Map<String, dynamic> convertMap(Map<dynamic, dynamic> map) {
  return Map<String, dynamic>.fromEntries(
    map.entries.map(
      (e) => MapEntry(
        e.key.toString(),
        e.value is Map
            ? convertMap(e.value)
            : e.value is List
            ? e.value
                  .map((item) => item is Map ? convertMap(item) : item)
                  .toList()
            : e.value,
      ),
    ),
  );
}

class TmdbApiManager {
  static final TmdbApiManager _instance = TmdbApiManager._internal();
  factory TmdbApiManager() => _instance;
  TmdbApiManager._internal();

  final _ak = getStoredUserKey("USER_TMDB_API_KEY", DefaultApiKeys.tmdbApiKey);
  final _token = getStoredUserKey(
    "USER_TMDB_ACCESS_TOKEN",
    DefaultApiKeys.tmdbAccessToken,
  );

  String get apiKey => _ak;
  String get accessToken => _token;

  TMDB get tmdb => configTMDB();

  TMDB configTMDB() {
    //api with showing all console logs
    final tmdb = TMDB(
      ApiKeys(_ak, _token),
      logConfig: const ConfigLogger.showAll(),
      // logConfig: const ConfigLogger(
      //   //must be true than only all other logs will be shown
      //   showLogs: true,
      //   showErrorLogs: true,
      // ),
      defaultLanguage: 'zh-CN',
    );

    return tmdb;
  }

  // 获取所有类型的当前趋势(movie tv person，可手动指定类型和时间段)
  Future<TmdbResultResp> getTrending({
    MediaType mediaType = MediaType.all,
    TimeWindow timeWindow = TimeWindow.day,
    int page = 1,
    String? language,
  }) async {
    var map = await tmdb.v3.trending.getTrending(
      mediaType: mediaType,
      timeWindow: timeWindow,
      page: page,
      language: language,
    );

    return TmdbResultResp.fromJson(convertMap(map));
  }

  // 关键字搜索(movie tv person，可手动指定类型和时间段)
  // 把所有栏位都放在这里，但实际调用时只传入支持的那部分参数
  Future<TmdbResultResp> search(
    String query, {
    MediaType mediaType = MediaType.all,
    bool includeAdult = false,
    String region = 'CN',
    int? year,
    int? primaryReleaseYear,
    String language = 'zh-CN',
    int page = 1,
    String? firstAirDateYear,
  }) async {
    Map<dynamic, dynamic> map;
    // 如果是查询电影
    if (mediaType == MediaType.movie) {
      map = await tmdb.v3.search.queryMovies(
        query,
        includeAdult: includeAdult,
        region: region,
        year: year,
        primaryReleaseYear: primaryReleaseYear,
        language: language,
        page: page,
      );
    } else if (mediaType == MediaType.tv) {
      // 如果是查询电视剧
      map = await tmdb.v3.search.queryTvShows(
        query,
        firstAirDateYear: firstAirDateYear,
        language: language,
        page: page,
      );
    } else if (mediaType == MediaType.person) {
      // 如果是查询人物
      map = await tmdb.v3.search.queryPeople(
        query,
        includeAdult: includeAdult,
        region: region,
        language: language,
        page: page,
      );
    } else {
      // 如果是查询所有类型
      // 注意，只有这个的结果有media_type，其他的在逻辑中需要处理筛选值
      map = await tmdb.v3.search.queryMulti(
        query,
        includeAdult: includeAdult,
        region: region,
        language: language,
        page: page,
      );
    }
    return TmdbResultResp.fromJson(convertMap(map));
  }

  /// 2025-08-18 此时最新的 tmdb_api: ^2.2.3 版本，getMovies() 、 getTvShows()参数内部构建不对、不完整
  /// 所以使用自己构建的请求方法
  // 发现电影（更多自由筛选）
  Future<TmdbResultResp> getDiscoverMovie({
    String? language = 'en-US',
    SortMoviesBy sortBy = SortMoviesBy.popularityDesc,
    int page = 1,
    bool includeAdult = false,
    bool includeVideo = false,
    String? certification,
    String? certificationGreaterThan,
    String? certificationLessThan,
    String? certificationCountry,
    int? primaryReleaseYear,
    String? primaryReleaseDateGreaterThan,
    String? primaryReleaseDateLessThan,
    String? region,
    String? releaseDateGreaterThan,
    String? releaseDateLessThan,
    int? voteAverageGreaterThan,
    int? voteAverageLessThan,
    int? voteCountGreaterThan,
    int? voteCountLessThan,
    String? watchRegion,
    String? withCast,
    String? withCompanies,
    String? withCrew,
    String? withGenres,
    String? withKeywords,
    String? withOriginCountry,
    String? withOrginalLanguage,
    String? withPeople,
    String? withReleaseType,
    int? withRunTimeGreaterThan,
    int? withRuntimeLessThan,
    String? withWatchMonetizationTypes,
    String? withWatchProviders,
    String? withoutCompanies,
    String? withoutGenres,
    String? withoutKeywords,
    String? withoutWatchProviders,
    int? year,
  }) async {
    var customDiscover = CustomDiscover(accessToken);

    // var map = await tmdb.v3.discover.getMovies(
    var map = await customDiscover.getMovies(
      language: language,
      sortBy: sortBy.toCustomSortMoviesBy(),
      page: page,
      includeAdult: includeAdult,
      includeVideo: includeVideo,
      certification: certification,
      certificationGreaterThan: certificationGreaterThan,
      certificationLessThan: certificationLessThan,
      certificationCountry: certificationCountry,
      primaryReleaseYear: primaryReleaseYear,
      primaryReleaseDateGreaterThan: primaryReleaseDateGreaterThan,
      primaryReleaseDateLessThan: primaryReleaseDateLessThan,
      region: region,
      releaseDateGreaterThan: releaseDateGreaterThan,
      releaseDateLessThan: releaseDateLessThan,
      voteAverageGreaterThan: voteAverageGreaterThan,
      voteAverageLessThan: voteAverageLessThan,
      voteCountGreaterThan: voteCountGreaterThan,
      voteCountLessThan: voteCountLessThan,
      watchRegion: watchRegion,
      withCast: withCast,
      withCompanies: withCompanies,
      withCrew: withCrew,
      withGenres: withGenres,
      withKeywords: withKeywords,
      withOriginCountry: withOriginCountry,
      withOrginalLanguage: withOrginalLanguage,
      withPeople: withPeople,
      withReleaseType: withReleaseType,
      withRunTimeGreaterThan: withRunTimeGreaterThan,
      withRuntimeLessThan: withRuntimeLessThan,
      withWatchMonetizationTypes: withWatchMonetizationTypes,
      withWatchProviders: withWatchProviders,
      withoutCompanies: withoutCompanies,
      withoutGenres: withoutGenres,
      withoutKeywords: withoutKeywords,
      withoutWatchProviders: withoutWatchProviders,
      year: year,
    );
    return TmdbResultResp.fromJson(convertMap(map));
  }

  // 发现剧集（更多自由筛选）
  Future<TmdbResultResp> getDiscoverTv({
    String? language = 'en-US',
    SortTvShowsBy sortBy = SortTvShowsBy.popularityDesc,
    int page = 1,
    bool includeAdult = false,
    bool includeNullFirstAirDates = false,
    String? airDateGte,
    String? airDateLte,
    int? firstAirDateYear,
    String? firstAirDateGte,
    String? firstAirDateLte,
    bool? screenedTheatrically,
    String? timezone,
    double? voteAverageGte,
    double? voteAverageLte,
    int? voteCountGte,
    int? voteCountLte,
    String? watchRegion,
    String? withCompanies,
    String? withGenres,
    String? withKeywords,
    String? withNetworks,
    String? withOriginCountry,
    String? withOrginalLanguage,
    int? withRuntimeGte,
    int? withRuntimeLte,
    FilterTvShowsByStatus? withStatus,
    String? withWatchMonetizationTypes,
    String? withWatchProviders,
    String? withoutCompanies,
    String? withoutGenres,
    String? withoutKeywords,
    String? withoutWatchProviders,
    FilterTvShowsByType? withType,
  }) async {
    var customDiscover = CustomDiscover(accessToken);

    // var map = await tmdb.v3.discover.getTvShows(
    var map = await customDiscover.getTvShows(
      language: language,
      sortBy: sortBy,
      page: page,
      includeAdult: includeAdult,
      includeNullFirstAirDates: includeNullFirstAirDates,
      airDateGte: airDateGte,
      airDateLte: airDateLte,
      firstAirDateYear: firstAirDateYear,
      firstAirDateGte: firstAirDateGte,
      firstAirDateLte: firstAirDateLte,
      timezone: timezone,
      voteAverageGte: voteAverageGte,
      voteAverageLte: voteAverageLte,
      voteCountGte: voteCountGte,
      voteCountLte: voteCountLte,
      watchRegion: watchRegion,
      withCompanies: withCompanies,
      withGenres: withGenres,
      withKeywords: withKeywords,
      withNetworks: withNetworks,
      withOriginCountry: withOriginCountry,
      withOrginalLanguage: withOrginalLanguage,
      withRuntimeGte: withRuntimeGte,
      withRuntimeLte: withRuntimeLte,
      withStatus: withStatus,
      withWatchMonetizationTypes: withWatchMonetizationTypes,
      withWatchProviders: withWatchProviders,
      withoutCompanies: withoutCompanies,
      withoutGenres: withoutGenres,
      withoutKeywords: withoutKeywords,
      withoutWatchProviders: withoutWatchProviders,
      withType: withType,
    );
    return TmdbResultResp.fromJson(convertMap(map));
  }

  /// ============================
  /// 电影相关接口
  /// ============================

  // 关键字查询电影
  Future<TmdbResultResp> searchMovie(
    String query, {
    bool includeAdult = false,
    String region = 'CN',
    int? year,
    int? primaryReleaseYear,
    String language = 'zh-CN',
    int page = 1,
  }) async {
    var map = await tmdb.v3.search.queryMovies(
      query,
      includeAdult: includeAdult,
      region: region,
      language: language,
      page: page,
      year: year,
      primaryReleaseYear: primaryReleaseYear,
    );

    return TmdbResultResp.fromJson(convertMap(map));
  }

  // 获取电影详情
  Future<TmdbMovieDetailResp> getMovieDetail(int id) async {
    var map = await tmdb.v3.movies.getDetails(
      id,
      appendToResponse: "images,reviews,similar",
      includeImageLanguage: "zh-CN,en,cn,null",
    );

    return TmdbMovieDetailResp.fromJson(convertMap(map));
  }

  // 获取电影演职表
  Future<TmdbMTCreditResp> getMovieCredit(int id) async {
    var map = await tmdb.v3.movies.getCredits(id);
    return TmdbMTCreditResp.fromJson(convertMap(map));
  }

  // 获取电影图片
  Future<TmdbAllImageResp> getMovieImages(int id) async {
    var map = await tmdb.v3.movies.getImages(
      id,
      includeImageLanguage: "zh-CN,en,cn,null",
    );

    return TmdbAllImageResp.fromJson(convertMap(map));
  }

  // 获取电影评论
  Future<TmdbMTReviewResp> getMovieReviews(int id) async {
    var map = await tmdb.v3.movies.getReviews(id);
    return TmdbMTReviewResp.fromJson(convertMap(map));
  }

  ///
  /// 电影列表
  ///

  // 获取电影相似
  Future<TmdbResultResp> getMovieSimilar(int id) async {
    var map = await tmdb.v3.movies.getSimilar(id);
    return TmdbResultResp.fromJson(convertMap(map));
  }

  // 获取电影推荐
  Future<TmdbResultResp> getMovieRecommendations(int id) async {
    var map = await tmdb.v3.movies.getRecommended(id);
    return TmdbResultResp.fromJson(convertMap(map));
  }

  // 获取正在上映的电影
  Future<TmdbResultResp> getMovieNowPlaying({
    String? language,
    int page = 1,
    String? region,
  }) async {
    var map = await tmdb.v3.movies.getNowPlaying(
      language: language,
      page: page,
      region: region,
    );
    return TmdbResultResp.fromJson(convertMap(map));
  }

  // 获取即将上映的电影
  Future<TmdbResultResp> getMovieUpcoming({
    String? language,
    int page = 1,
    String? region,
  }) async {
    var map = await tmdb.v3.movies.getUpcoming(
      language: language,
      page: page,
      region: region,
    );
    return TmdbResultResp.fromJson(convertMap(map));
  }

  // 获取最受欢迎的电影
  Future<TmdbResultResp> getMoviePopular({
    String? language,
    int page = 1,
    String? region,
  }) async {
    var map = await tmdb.v3.movies.getPopular(
      language: language,
      page: page,
      region: region,
    );
    return TmdbResultResp.fromJson(convertMap(map));
  }

  // 获取评分最高的电影
  Future<TmdbResultResp> getMovieTopRated({
    String? language,
    int page = 1,
    String? region,
  }) async {
    var map = await tmdb.v3.movies.getTopRated(
      language: language,
      page: page,
      region: region,
    );
    return TmdbResultResp.fromJson(convertMap(map));
  }

  /// ============================
  /// 剧集相关接口
  /// ============================

  // 关键字查询剧集
  Future<TmdbResultResp> searchTvShows(
    String query, {
    String? firstAirDateYear,
    String? language,
    int page = 1,
  }) async {
    var map = await tmdb.v3.search.queryTvShows(
      query,
      firstAirDateYear: firstAirDateYear,
      language: language,
      page: page,
    );

    return TmdbResultResp.fromJson(convertMap(map));
  }

  // 获取电视剧详情
  Future<TmdbTvDetailResp> getTvDetail(int id) async {
    var map = await tmdb.v3.tv.getDetails(
      id,
      appendToResponse: "images,reviews,similar",
      includeImageLanguage: "zh-CN,en,cn,null",
    );

    return TmdbTvDetailResp.fromJson(convertMap(map));
  }

  // 获取电视剧演职表
  Future<TmdbMTCreditResp> getTvCredit(int id) async {
    var map = await tmdb.v3.tv.getCredits(id);
    return TmdbMTCreditResp.fromJson(convertMap(map));
  }

  // 获取电视剧图片
  Future<TmdbAllImageResp> getTvImages(int id) async {
    var map = await tmdb.v3.tv.getImages(
      id,
      includeImageLanguage: "zh-CN,en,cn,null",
    );

    return TmdbAllImageResp.fromJson(convertMap(map));
  }

  // 获取电视剧评论
  Future<TmdbMTReviewResp> getTvReviews(int id) async {
    var map = await tmdb.v3.tv.getReviews(id);
    return TmdbMTReviewResp.fromJson(convertMap(map));
  }

  ///
  /// 剧集列表
  ///

  // 获取电视剧相似
  Future<TmdbResultResp> getTvSimilar(int id) async {
    var map = await tmdb.v3.tv.getSimilar(id);
    return TmdbResultResp.fromJson(convertMap(map));
  }

  // 获取电视剧推荐
  Future<TmdbResultResp> getTvRecommendations(int id) async {
    var map = await tmdb.v3.tv.getRecommendations(id);
    return TmdbResultResp.fromJson(convertMap(map));
  }

  // 获取正在播放的电视剧
  Future<TmdbResultResp> getTvAiringToday({
    String? language,
    int page = 1,
  }) async {
    var map = await tmdb.v3.tv.getAiringToday(language: language, page: page);
    return TmdbResultResp.fromJson(convertMap(map));
  }

  // 获取即将播放的电视剧
  Future<TmdbResultResp> getTvOnTheAir({String? language, int page = 1}) async {
    var map = await tmdb.v3.tv.getOnTheAir(language: language, page: page);
    return TmdbResultResp.fromJson(convertMap(map));
  }

  // 获取最受欢迎的电视剧
  Future<TmdbResultResp> getTvPopular({String? language, int page = 1}) async {
    var map = await tmdb.v3.tv.getPopular(language: language, page: page);
    return TmdbResultResp.fromJson(convertMap(map));
  }

  // 获取评分最高的电视剧
  Future<TmdbResultResp> getTvTopRated({String? language, int page = 1}) async {
    var map = await tmdb.v3.tv.getTopRated(language: language, page: page);
    return TmdbResultResp.fromJson(convertMap(map));
  }

  /// ============================
  /// 人物相关接口
  /// ============================

  // 关键字查询人物
  Future<TmdbResultResp> searchPerson(
    String query, {
    bool includeAdult = false,
    String? region,
    String? language,
    int page = 1,
  }) async {
    var map = await tmdb.v3.search.queryPeople(
      query,
      includeAdult: includeAdult,
      region: region,
      language: language,
      page: page,
    );

    return TmdbResultResp.fromJson(convertMap(map));
  }

  // 获取人物详情
  Future<TmdbPersonDetailResp> getPersonDetail(int id) async {
    var map = await tmdb.v3.people.getDetails(
      id,
      appendToResponse: "images,tv_credits,movie_credits",
    );

    return TmdbPersonDetailResp.fromJson(convertMap(map));
  }

  // 获取人物图片
  Future<TmdbAllImageResp> getPersonImages(int id) async {
    var map = await tmdb.v3.people.getImages(id);
    return TmdbAllImageResp.fromJson(convertMap(map));
  }

  // 获取人物出演或参与的电影和剧集
  Future<TmdbPersonCreditResp> getPersonCredit(int id) async {
    var map = await tmdb.v3.people.getCombinedCredits(id);
    return TmdbPersonCreditResp.fromJson(convertMap(map));
  }

  // 获取最受欢迎的人物
  Future<TmdbResultResp> getPersonPopular({
    String? language,
    int page = 1,
  }) async {
    var map = await tmdb.v3.people.getPopular(language: language, page: page);
    return TmdbResultResp.fromJson(convertMap(map));
  }
}
