import 'package:json_annotation/json_annotation.dart';

part 'tmdb_mt_credit_resp.g.dart';

/// 指定电影的演职表
/// https://developer.themoviedb.org/reference/movie-credits
///
/// 指定剧集的演职表
/// https://developer.themoviedb.org/reference/tv-series-credits
///
/// 虽然在查询电影/剧集详情时，append_to_response 可以添加 credits images similar等最多20个
/// 但是这些都是一次性响应所有内容，比较多。所以后续在页面设计时最好分开引导式查询
///
/// 电影剧集的credits内部的结构是一样的，是演职表栏位
/// 但person的 movie_credits 和 tv_credits 或者一次性查询俩的 combined_credits，是通用的影片剧集栏位
@JsonSerializable(explicitToJson: true)
class TmdbMTCreditResp {
  // 电影/剧集编号
  @JsonKey(name: 'id')
  int? id;

  // 演员列表
  @JsonKey(name: 'cast')
  List<TmdbCredit>? cast;

  // 职员列表
  @JsonKey(name: 'crew')
  List<TmdbCredit>? crew;

  TmdbMTCreditResp({this.id, this.cast, this.crew});

  factory TmdbMTCreditResp.fromJson(Map<String, dynamic> srcJson) =>
      _$TmdbMTCreditRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$TmdbMTCreditRespToJson(this);
}

// 把movie/tv credits 的cast和crew合并为一个类了
@JsonSerializable(explicitToJson: true)
class TmdbCredit {
  @JsonKey(name: 'adult')
  bool? adult;

  @JsonKey(name: 'gender')
  int? gender;

  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'known_for_department')
  String? knownForDepartment;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'original_name')
  String? originalName;

  @JsonKey(name: 'popularity')
  double? popularity;

  @JsonKey(name: 'profile_path')
  String? profilePath;

  // movie credits cast 中独有的
  @JsonKey(name: 'cast_id')
  int? castId;

  // movie/tv credits  cast 中独有的
  @JsonKey(name: 'character')
  String? character;

  @JsonKey(name: 'credit_id')
  String? creditId;

  @JsonKey(name: 'order')
  int? order;

  // movie/tv credits  crew 中独有的
  @JsonKey(name: 'department')
  String? department;

  @JsonKey(name: 'job')
  String? job;

  TmdbCredit({
    this.adult,
    this.gender,
    this.id,
    this.knownForDepartment,
    this.name,
    this.originalName,
    this.popularity,
    this.profilePath,
    this.castId,
    this.character,
    this.creditId,
    this.order,
    this.department,
    this.job,
  });

  factory TmdbCredit.fromJson(Map<String, dynamic> srcJson) =>
      _$TmdbCreditFromJson(srcJson);

  Map<String, dynamic> toJson() => _$TmdbCreditToJson(this);
}
