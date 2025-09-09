import 'package:json_annotation/json_annotation.dart';

import 'douguo_recommended_resp.dart';

part 'douguo_search_resp.g.dart';

///
/// 豆果 菜谱搜索结果列表
///
/// API数据来源：
/// https://apis.netstart.cn/douguo/#/
///
/// DouGuoSearch -> DGSearch
///
/// 栏位很多，有删减，棋子dsp、mdsp应该是广告种草等相关的，直接全丢了
///
@JsonSerializable(explicitToJson: true)
class DouguoSearchResp {
  @JsonKey(name: 'state')
  String? state;

  @JsonKey(name: 'result')
  DGSearchResult? result;

  DouguoSearchResp({this.state, this.result});

  factory DouguoSearchResp.fromJson(Map<String, dynamic> srcJson) =>
      _$DouguoSearchRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DouguoSearchRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DGSearchResult {
  // 搜索关键字
  @JsonKey(name: 'primary_keyword')
  String? primaryKeyword;

  // 搜索二级关键字
  @JsonKey(name: 'anchoring_keyword')
  String? anchoringKeyword;

  @JsonKey(name: 'sts')
  List<String>? sts;

  // 可能是隐藏的排序标签
  @JsonKey(name: 'hidden_sorting_tags')
  int? hiddenSortingTags;

  // 搜索结果中菜谱列表
  @JsonKey(name: 'list')
  List<DGSearchList>? list;

  @JsonKey(name: 'secondary_keywords')
  List<String>? secondaryKeywords;

  // 可能是搜索结果是否结束
  @JsonKey(name: 'end')
  int? end;

  // 可能是搜索结果是否结束的文本
  @JsonKey(name: 'end_text')
  String? endText;

  // 可能是搜索结果为空的文本
  @JsonKey(name: 'empty_text')
  String? emptyText;

  DGSearchResult({
    this.primaryKeyword,
    this.anchoringKeyword,
    this.sts,
    this.hiddenSortingTags,
    this.list,
    this.secondaryKeywords,
    this.end,
    this.endText,
    this.emptyText,
  });

  factory DGSearchResult.fromJson(Map<String, dynamic> srcJson) =>
      _$DGSearchResultFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DGSearchResultToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DGSearchList {
  @JsonKey(name: 'ju')
  String? ju;

  @JsonKey(name: 'type')
  int? type;

  // 搜索结果中的这个菜谱概况，和推荐列表中的有大量相同的栏位，但多了不少栏位，
  // 可以简单把需要的栏位揉在一起
  @JsonKey(name: 'r')
  DGRoughItem? r;

  DGSearchList({this.ju, this.type, this.r});

  factory DGSearchList.fromJson(Map<String, dynamic> srcJson) =>
      _$DGSearchListFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DGSearchListToJson(this);
}
