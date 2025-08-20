import 'package:json_annotation/json_annotation.dart';

import 'tmdb_common.dart';

part 'tmdb_person_credit_resp.g.dart';

///
/// 人物出演或者参与的电影和剧集
/// 合并查询
/// https://developer.themoviedb.org/reference/person-combined-credits
/// 单独查询电影
/// https://developer.themoviedb.org/reference/person-movie-credits
/// 单独查询剧集
/// https://developer.themoviedb.org/reference/person-tv-credits
///
@JsonSerializable(explicitToJson: true)
class TmdbPersonCreditResp {
  // 人物编号
  @JsonKey(name: 'id')
  int? id;
  // 出演电影/剧集信息
  @JsonKey(name: 'cast')
  List<TmdbResultItem>? cast;

  // 担任电影/剧集信息
  @JsonKey(name: 'crew')
  List<TmdbResultItem>? crew;

  TmdbPersonCreditResp({this.cast, this.crew, this.id});

  factory TmdbPersonCreditResp.fromJson(Map<String, dynamic> srcJson) =>
      _$TmdbPersonCreditRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$TmdbPersonCreditRespToJson(this);
}
