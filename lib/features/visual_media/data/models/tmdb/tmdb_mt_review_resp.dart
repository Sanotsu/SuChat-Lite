import 'package:json_annotation/json_annotation.dart';

part 'tmdb_mt_review_resp.g.dart';

///
/// 指定电影的评论信息
/// https://developer.themoviedb.org/reference/movie-reviews
///
/// 剧集的评论结构类似，
/// https://developer.themoviedb.org/reference/tv-series-reviews
/// person就没有评论接口了
///
@JsonSerializable(explicitToJson: true)
class TmdbMTReviewResp {
  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'page')
  int? page;

  // 电影和剧集的评论结构是相同的
  @JsonKey(name: 'results')
  List<TmdbReviewItem>? results;

  @JsonKey(name: 'total_pages')
  int? totalPages;

  @JsonKey(name: 'total_results')
  int? totalResults;

  TmdbMTReviewResp({
    this.id,
    this.page,
    this.results,
    this.totalPages,
    this.totalResults,
  });

  factory TmdbMTReviewResp.fromJson(Map<String, dynamic> srcJson) =>
      _$TmdbMTReviewRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$TmdbMTReviewRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TmdbReviewItem {
  @JsonKey(name: 'author')
  String? author;

  @JsonKey(name: 'author_details')
  TmdbReviewAuthorDetail? authorDetails;

  @JsonKey(name: 'content')
  String? content;

  @JsonKey(name: 'created_at')
  String? createdAt;

  @JsonKey(name: 'id')
  String? id;

  @JsonKey(name: 'updated_at')
  String? updatedAt;

  @JsonKey(name: 'url')
  String? url;

  TmdbReviewItem({
    this.author,
    this.authorDetails,
    this.content,
    this.createdAt,
    this.id,
    this.updatedAt,
    this.url,
  });

  factory TmdbReviewItem.fromJson(Map<String, dynamic> srcJson) =>
      _$TmdbReviewItemFromJson(srcJson);

  Map<String, dynamic> toJson() => _$TmdbReviewItemToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TmdbReviewAuthorDetail {
  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'username')
  String? username;

  @JsonKey(name: 'avatar_path')
  String? avatarPath;

  @JsonKey(name: 'rating')
  int? rating;

  TmdbReviewAuthorDetail({
    this.name,
    this.username,
    this.avatarPath,
    this.rating,
  });

  factory TmdbReviewAuthorDetail.fromJson(Map<String, dynamic> srcJson) =>
      _$TmdbReviewAuthorDetailFromJson(srcJson);

  Map<String, dynamic> toJson() => _$TmdbReviewAuthorDetailToJson(this);
}
