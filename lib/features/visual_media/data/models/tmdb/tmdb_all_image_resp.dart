import 'package:json_annotation/json_annotation.dart';

import 'tmdb_common.dart';

part 'tmdb_all_image_resp.g.dart';

/// 指定电视剧的图片
/// https://developer.themoviedb.org/reference/tv-series-images
/// 指定电影的图片
/// https://developer.themoviedb.org/reference/movie-images
/// 指定人的图片
/// https://developer.themoviedb.org/reference/person-images
///
/// 虽然在查询电视剧详情时，append_to_response 可以添加 credits images similar等最多20个
/// 但是这些都是一次性响应所有内容，比较多。所以后续在页面设计时最好分开引导式查询
///
/// 注意，和电影图片响应结构是一样的，可以考虑合并。
/// person 没有backdrops logos posters，使用的是profiles ，但结构一样
///
/// 注意：以TmdbAll开头的，就包含了 movie tv person 的响应
/// 以TmdbMT开头的，就包含了movie tv的响应
/// 否则就是单独 TmdbMovie_ TmdbTv_ TmdbPerson_
@JsonSerializable(explicitToJson: true)
class TmdbAllImageResp {
  // movie tv person 的编号
  @JsonKey(name: 'id')
  int? id;

  // 背景图（估计这几个图片类型在剧集等分类中也是一样的），但像logo又怕有歧义，所以不带movie分类，但加上image特指
  // 电影和剧集的图片都有 backdrop、logo、poster，内部属性结构一样，所以使用同一个item作为其类型
  @JsonKey(name: 'backdrops')
  List<TmdbImageItem>? backdrops;

  @JsonKey(name: 'logos')
  List<TmdbImageItem>? logos;

  @JsonKey(name: 'posters')
  List<TmdbImageItem>? posters;

  /// person 没有backdrops logos posters，使用的是profiles ，但结构一样
  @JsonKey(name: 'profiles')
  List<TmdbImageItem>? profiles;

  TmdbAllImageResp({
    this.backdrops,
    this.id,
    this.logos,
    this.posters,
    this.profiles,
  });

  factory TmdbAllImageResp.fromJson(Map<String, dynamic> srcJson) =>
      _$TmdbAllImageRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$TmdbAllImageRespToJson(this);
}
