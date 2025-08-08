import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'readhub_resp.g.dart';

///
/// readhub 部分新闻
/// 热点话题(大体结构一样，但item多个相关新闻和时间线)
/// https://api.readhub.cn/topic/list?page=1&size=5
///
/// 分类新闻
/// https://api.readhub.cn/news/list?size=10&type=1&page=1
///
/// 这个API正常请求是最外面有个data，这里就忽略了，http请求时response取data属性就好
///
@JsonSerializable(explicitToJson: true)
class ReadhubResp {
  @JsonKey(name: 'totalItems')
  int? totalItems;

  @JsonKey(name: 'startIndex')
  int? startIndex;

  @JsonKey(name: 'pageIndex')
  int? pageIndex;

  @JsonKey(name: 'itemsPerPage')
  int? itemsPerPage;

  @JsonKey(name: 'currentItemCount')
  int? currentItemCount;

  @JsonKey(name: 'totalPages')
  int? totalPages;

  @JsonKey(name: 'items')
  List<ReadhubItem>? items;

  ReadhubResp({
    this.totalItems,
    this.startIndex,
    this.pageIndex,
    this.itemsPerPage,
    this.currentItemCount,
    this.totalPages,
    this.items,
  });

  factory ReadhubResp.fromRawJson(String str) =>
      ReadhubResp.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ReadhubResp.fromJson(Map<String, dynamic> srcJson) =>
      _$ReadhubRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$ReadhubRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ReadhubItem {
  // 都有的栏位
  @JsonKey(name: 'uid')
  String uid;

  @JsonKey(name: 'title')
  String title;

  @JsonKey(name: 'summary')
  String summary;

  @JsonKey(name: 'createdAt')
  String? createdAt;

  @JsonKey(name: 'publishDate')
  String? publishDate;

  @JsonKey(name: 'siteNameDisplay')
  String? siteNameDisplay;

  // 分类新闻有
  @JsonKey(name: 'url')
  String? url;

  // 热点新闻没有url，但有这一堆
  @JsonKey(name: 'siteCount')
  int? siteCount;

  @JsonKey(name: 'newsAggList')
  List<ReadhubNewsAggList>? newsAggList;

  @JsonKey(name: 'timeline')
  ReadhubTimeline? timeline;

  @JsonKey(name: 'entityList')
  List<dynamic>? entityList;

  @JsonKey(name: 'tagList')
  List<dynamic>? tagList;

  @JsonKey(name: 'itemId')
  String? itemId;

  @JsonKey(name: 'useful')
  ReadhubUseful? useful;

  ReadhubItem({
    required this.uid,
    required this.title,
    required this.summary,
    required this.createdAt,
    required this.publishDate,
    required this.siteNameDisplay,
    this.url,
    this.siteCount,
    this.newsAggList,
    this.timeline,
    this.entityList,
    this.tagList,
    this.itemId,
    this.useful,
  });

  factory ReadhubItem.fromRawJson(String str) =>
      ReadhubItem.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ReadhubItem.fromJson(Map<String, dynamic> srcJson) =>
      _$ReadhubItemFromJson(srcJson);

  Map<String, dynamic> toJson() => _$ReadhubItemToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ReadhubNewsAggList {
  @JsonKey(name: 'uid')
  String? uid;

  @JsonKey(name: 'url')
  String? url;

  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'siteNameDisplay')
  String? siteNameDisplay;

  ReadhubNewsAggList(this.uid, this.url, this.title, this.siteNameDisplay);

  factory ReadhubNewsAggList.fromRawJson(String str) =>
      ReadhubNewsAggList.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ReadhubNewsAggList.fromJson(Map<String, dynamic> srcJson) =>
      _$ReadhubNewsAggListFromJson(srcJson);

  Map<String, dynamic> toJson() => _$ReadhubNewsAggListToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ReadhubTimeline {
  @JsonKey(name: 'topics')
  List<ReadhubTimelineTopic>? topics;

  @JsonKey(name: 'commonEntityList')
  List<dynamic>? commonEntityList;

  ReadhubTimeline(this.topics, this.commonEntityList);

  factory ReadhubTimeline.fromRawJson(String str) =>
      ReadhubTimeline.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ReadhubTimeline.fromJson(Map<String, dynamic> srcJson) =>
      _$ReadhubTimelineFromJson(srcJson);

  Map<String, dynamic> toJson() => _$ReadhubTimelineToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ReadhubTimelineTopic {
  @JsonKey(name: 'uid')
  String? uid;

  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'createdAt')
  String? createdAt;

  @JsonKey(name: 'publishDate')
  String? publishDate;

  ReadhubTimelineTopic(this.uid, this.title, this.createdAt, this.publishDate);

  factory ReadhubTimelineTopic.fromRawJson(String str) =>
      ReadhubTimelineTopic.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ReadhubTimelineTopic.fromJson(Map<String, dynamic> srcJson) =>
      _$ReadhubTimelineTopicFromJson(srcJson);

  Map<String, dynamic> toJson() => _$ReadhubTimelineTopicToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ReadhubUseful {
  @JsonKey(name: 'count')
  int? count;

  @JsonKey(name: 'topicId')
  String? topicId;

  ReadhubUseful(this.count, this.topicId);

  factory ReadhubUseful.fromRawJson(String str) =>
      ReadhubUseful.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ReadhubUseful.fromJson(Map<String, dynamic> srcJson) =>
      _$ReadhubUsefulFromJson(srcJson);

  Map<String, dynamic> toJson() => _$ReadhubUsefulToJson(this);
}
