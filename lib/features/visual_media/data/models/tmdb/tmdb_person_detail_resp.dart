import 'package:json_annotation/json_annotation.dart';

part 'tmdb_person_detail_resp.g.dart';

/// tmdb 人员详情栏位
/// https://developer.themoviedb.org/reference/person-details
///
/// 单独的人物详情比较单调，如果是显示人物详情的页面，可能还需要查询image、credits等其他内容
///
@JsonSerializable(explicitToJson: true)
class TmdbPersonDetailResp {
  @JsonKey(name: 'adult')
  bool? adult;

  @JsonKey(name: 'also_known_as')
  List<String>? alsoKnownAs;

  @JsonKey(name: 'biography')
  String? biography;

  @JsonKey(name: 'birthday')
  String? birthday;

  @JsonKey(name: 'gender')
  int? gender;

  @JsonKey(name: 'id')
  int? id;

  @JsonKey(name: 'imdb_id')
  String? imdbId;

  @JsonKey(name: 'known_for_department')
  String? knownForDepartment;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'place_of_birth')
  String? placeOfBirth;

  @JsonKey(name: 'popularity')
  double? popularity;

  @JsonKey(name: 'profile_path')
  String? profilePath;

  TmdbPersonDetailResp({
    this.adult,
    this.alsoKnownAs,
    this.biography,
    this.birthday,
    this.gender,
    this.id,
    this.imdbId,
    this.knownForDepartment,
    this.name,
    this.placeOfBirth,
    this.popularity,
    this.profilePath,
  });

  factory TmdbPersonDetailResp.fromJson(Map<String, dynamic> srcJson) =>
      _$TmdbPersonDetailRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$TmdbPersonDetailRespToJson(this);
}
