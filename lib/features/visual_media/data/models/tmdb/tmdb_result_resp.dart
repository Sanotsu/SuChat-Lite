import 'package:json_annotation/json_annotation.dart';

import 'tmdb_common.dart';

part 'tmdb_result_resp.g.dart';

///
/// 全部趋势 和 单个类型趋势结构类似
/// https://developer.themoviedb.org/reference/trending-all
/// https://developer.themoviedb.org/reference/trending-movie
/// https://developer.themoviedb.org/reference/trending-tv
/// https://developer.themoviedb.org/reference/trending-person
///
/// 全部类型的搜索 和 单个类型查询结构类似
/// https://developer.themoviedb.org/reference/search-multi
/// https://developer.themoviedb.org/reference/search-movie
/// https://developer.themoviedb.org/reference/search-tv
/// https://developer.themoviedb.org/reference/search-person
///
///
/// 推荐电影
/// https://developer.themoviedb.org/reference/movie-recommendations
/// 相似电影
/// https://developer.themoviedb.org/reference/movie-similar
/// 正在上映的电影（多个dates属性："dates": {"maximum": "2025-08-20","minimum": "2025-07-09"},）
/// https://developer.themoviedb.org/reference/movie-now-playing-list
/// 即将上映的电影（多个dates属性："dates": {"maximum": "2025-09-10","minimum": "2025-08-20"},）
/// https://developer.themoviedb.org/reference/movie-upcoming-list
/// 最受欢迎的电影
/// https://developer.themoviedb.org/reference/movie-popular-list
/// 评分最高的电影
/// https://developer.themoviedb.org/reference/movie-top-rated-list
///
/// 推荐剧集
/// https://developer.themoviedb.org/reference/tv-series-recommendations
/// 相似剧集
/// https://developer.themoviedb.org/reference/tv-series-similar
/// 正在播放的剧集
/// https://developer.themoviedb.org/reference/tv-series-airing-today-list
/// 即将播放的剧集
/// https://developer.themoviedb.org/reference/tv-series-on-the-air-list
/// 最受欢迎的剧集
/// https://developer.themoviedb.org/reference/tv-series-popular-list
/// 评分最高的剧集
/// https://developer.themoviedb.org/reference/tv-series-top-rated-list
///
/// 最受欢迎的人物
/// https://developer.themoviedb.org/reference/person-popular-list
///
/// 上面几个接口的响应结构完全一样，合并到一起 TmdbResultResp
/// 不是TmdbAllResultResp 是因为 person 没有推荐和相似接口
///
/// movie、tv、person 概要信息结构也相似，全部合并到一起 TmdbResultItem
///
@JsonSerializable(explicitToJson: true)
class TmdbResultResp {
  @JsonKey(name: 'page')
  int? page;

  @JsonKey(name: 'results')
  List<TmdbResultItem>? results;

  @JsonKey(name: 'total_pages')
  int? totalPages;

  @JsonKey(name: 'total_results')
  int? totalResults;

  // 正在上映和即将上映的电影多一个dates属性
  @JsonKey(name: 'dates')
  TmdbMovieDate? dates;

  TmdbResultResp({
    this.page,
    this.results,
    this.totalPages,
    this.totalResults,
    this.dates,
  });

  factory TmdbResultResp.fromJson(Map<String, dynamic> srcJson) =>
      _$TmdbResultRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$TmdbResultRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TmdbMovieDate {
  @JsonKey(name: 'maximum')
  String? maximum;

  @JsonKey(name: 'minimum')
  String? minimum;

  TmdbMovieDate({this.maximum, this.minimum});

  factory TmdbMovieDate.fromJson(Map<String, dynamic> srcJson) =>
      _$TmdbMovieDateFromJson(srcJson);

  Map<String, dynamic> toJson() => _$TmdbMovieDateToJson(this);
}
