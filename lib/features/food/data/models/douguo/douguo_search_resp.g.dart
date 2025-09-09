// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'douguo_search_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DouguoSearchResp _$DouguoSearchRespFromJson(Map<String, dynamic> json) =>
    DouguoSearchResp(
      state: json['state'] as String?,
      result: json['result'] == null
          ? null
          : DGSearchResult.fromJson(json['result'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DouguoSearchRespToJson(DouguoSearchResp instance) =>
    <String, dynamic>{
      'state': instance.state,
      'result': instance.result?.toJson(),
    };

DGSearchResult _$DGSearchResultFromJson(Map<String, dynamic> json) =>
    DGSearchResult(
      primaryKeyword: json['primary_keyword'] as String?,
      anchoringKeyword: json['anchoring_keyword'] as String?,
      sts: (json['sts'] as List<dynamic>?)?.map((e) => e as String).toList(),
      hiddenSortingTags: (json['hidden_sorting_tags'] as num?)?.toInt(),
      list: (json['list'] as List<dynamic>?)
          ?.map((e) => DGSearchList.fromJson(e as Map<String, dynamic>))
          .toList(),
      secondaryKeywords: (json['secondary_keywords'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      end: (json['end'] as num?)?.toInt(),
      endText: json['end_text'] as String?,
      emptyText: json['empty_text'] as String?,
    );

Map<String, dynamic> _$DGSearchResultToJson(DGSearchResult instance) =>
    <String, dynamic>{
      'primary_keyword': instance.primaryKeyword,
      'anchoring_keyword': instance.anchoringKeyword,
      'sts': instance.sts,
      'hidden_sorting_tags': instance.hiddenSortingTags,
      'list': instance.list?.map((e) => e.toJson()).toList(),
      'secondary_keywords': instance.secondaryKeywords,
      'end': instance.end,
      'end_text': instance.endText,
      'empty_text': instance.emptyText,
    };

DGSearchList _$DGSearchListFromJson(Map<String, dynamic> json) => DGSearchList(
  ju: json['ju'] as String?,
  type: (json['type'] as num?)?.toInt(),
  r: json['r'] == null
      ? null
      : DGRoughItem.fromJson(json['r'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DGSearchListToJson(DGSearchList instance) =>
    <String, dynamic>{
      'ju': instance.ju,
      'type': instance.type,
      'r': instance.r?.toJson(),
    };
