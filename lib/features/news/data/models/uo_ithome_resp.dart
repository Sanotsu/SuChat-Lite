import 'package:json_annotation/json_annotation.dart';

part 'uo_ithome_resp.g.dart';

///
/// 忘了从那里看到的，地址返回最新25条数据，没有分页
/// https://api.ithome.com/json/newslist/news
///
/// Unofficial -> uo
///
@JsonSerializable(explicitToJson: true)
class UoItHomeResp {
  @JsonKey(name: 'toplist')
  List<UoItHomeTop>? toplist;

  @JsonKey(name: 'newslist')
  List<UoItHomeNews>? newslist;

  @JsonKey(name: 'array')
  List<String>? array;

  @JsonKey(name: 'lapin')
  bool? lapin;

  UoItHomeResp(this.toplist, this.newslist, this.array, this.lapin);

  factory UoItHomeResp.fromJson(Map<String, dynamic> srcJson) =>
      _$UoItHomeRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$UoItHomeRespToJson(this);
}

// 置顶数据
@JsonSerializable(explicitToJson: true)
class UoItHomeTop {
  @JsonKey(name: 'client')
  String? client;

  @JsonKey(name: 'device')
  String? device;

  @JsonKey(name: 'topplat')
  String? topplat;

  @JsonKey(name: 'newsid')
  int? newsid;

  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'postdate')
  String? postdate;

  @JsonKey(name: 'orderdate')
  String? orderdate;

  @JsonKey(name: 'description')
  String? description;

  @JsonKey(name: 'image')
  String? image;

  @JsonKey(name: 'hitcount')
  int? hitcount;

  @JsonKey(name: 'commentcount')
  int? commentcount;

  @JsonKey(name: 'hidecount')
  bool? hidecount;

  @JsonKey(name: 'cid')
  int? cid;

  @JsonKey(name: 'nd')
  int? nd;

  @JsonKey(name: 'sid')
  int? sid;

  @JsonKey(name: 'url')
  String? url;

  UoItHomeTop(
    this.client,
    this.device,
    this.topplat,
    this.newsid,
    this.title,
    this.postdate,
    this.orderdate,
    this.description,
    this.image,
    this.hitcount,
    this.commentcount,
    this.hidecount,
    this.cid,
    this.nd,
    this.sid,
    this.url,
  );

  factory UoItHomeTop.fromJson(Map<String, dynamic> srcJson) =>
      _$UoItHomeTopFromJson(srcJson);

  Map<String, dynamic> toJson() => _$UoItHomeTopToJson(this);
}

@JsonSerializable(explicitToJson: true)
class UoItHomeNews {
  @JsonKey(name: 'forbidcomment')
  bool? forbidcomment;

  @JsonKey(name: 'kwdlist')
  List<String>? kwdlist;

  @JsonKey(name: 'newsid')
  int? newsid;

  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'postdate')
  String? postdate;

  @JsonKey(name: 'orderdate')
  String? orderdate;

  @JsonKey(name: 'description')
  String? description;

  @JsonKey(name: 'image')
  String? image;

  @JsonKey(name: 'hitcount')
  int? hitcount;

  @JsonKey(name: 'commentcount')
  int? commentcount;

  @JsonKey(name: 'hidecount')
  bool? hidecount;

  @JsonKey(name: 'cid')
  int? cid;

  @JsonKey(name: 'nd')
  int? nd;

  @JsonKey(name: 'sid')
  int? sid;

  @JsonKey(name: 'url')
  String? url;

  UoItHomeNews(
    this.forbidcomment,
    this.kwdlist,
    this.newsid,
    this.title,
    this.postdate,
    this.orderdate,
    this.description,
    this.image,
    this.hitcount,
    this.commentcount,
    this.hidecount,
    this.cid,
    this.nd,
    this.sid,
    this.url,
  );

  factory UoItHomeNews.fromJson(Map<String, dynamic> srcJson) =>
      _$UoItHomeNewsFromJson(srcJson);

  Map<String, dynamic> toJson() => _$UoItHomeNewsToJson(this);
}
