import 'package:json_annotation/json_annotation.dart';

part 'duomoyu_resp.g.dart';

///
/// 多摸鱼（https://duomoyu.com/）响应模型
/// 2026-09-04 API 改版后的新结构：
/// - 新闻源列表: GET https://duomoyu.com/api/news/sources
/// - 指定源热榜: GET https://duomoyu.com/api/news/rankings/{slug}
///

/// 新闻源列表响应
@JsonSerializable(explicitToJson: true)
class DuomoyuSourcesResp {
  @JsonKey(name: 'success')
  bool? success;

  @JsonKey(name: 'data')
  DuomoyuSourcesData? data;

  DuomoyuSourcesResp(this.success, this.data);

  factory DuomoyuSourcesResp.fromJson(Map<String, dynamic> srcJson) =>
      _$DuomoyuSourcesRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DuomoyuSourcesRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DuomoyuSourcesData {
  @JsonKey(name: 'sources')
  List<DuomoyuSource>? sources;

  DuomoyuSourcesData(this.sources);

  factory DuomoyuSourcesData.fromJson(Map<String, dynamic> srcJson) =>
      _$DuomoyuSourcesDataFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DuomoyuSourcesDataToJson(this);
}

/// 单个新闻源(热榜分类)
@JsonSerializable(explicitToJson: true)
class DuomoyuSource implements Comparable<DuomoyuSource> {
  /// 源标识，热榜接口的 {slug} 参数
  @JsonKey(name: 'slug')
  String? slug;

  /// 源中文名(分类标签显示名)
  @JsonKey(name: 'label')
  String? label;

  /// 源分类: technology/news/entertainment/community/market
  @JsonKey(name: 'category')
  String? category;

  @JsonKey(name: 'imageKey')
  String? imageKey;

  /// 展示排序(越小越靠前)
  @JsonKey(name: 'displayOrder')
  int? displayOrder;

  /// 访问级别: PUBLIC 等，非公开源不可直接查询
  @JsonKey(name: 'accessLevel')
  String? accessLevel;

  /// 该源数据最近更新时间(ISO8601)
  @JsonKey(name: 'updatedAt')
  String? updatedAt;

  /// 数据是否已过期
  @JsonKey(name: 'stale')
  bool? stale;

  DuomoyuSource(
    this.slug,
    this.label,
    this.category,
    this.imageKey,
    this.displayOrder,
    this.accessLevel,
    this.updatedAt,
    this.stale,
  );

  factory DuomoyuSource.fromJson(Map<String, dynamic> srcJson) =>
      _$DuomoyuSourceFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DuomoyuSourceToJson(this);

  /// 分类中文标签(展示用，未知分类归入其他)
  String get categoryCn => switch (category) {
    'technology' => '科技',
    'news' => '新闻',
    'entertainment' => '娱乐',
    'community' => '社区',
    'market' => '行情',
    _ => '其他',
  };

  /// 是否公开可查且数据未过期
  bool get isUsable => accessLevel == 'PUBLIC' && stale != true && slug != null;

  @override
  int compareTo(DuomoyuSource other) =>
      (displayOrder ?? 999999).compareTo(other.displayOrder ?? 999999);
}

/// 指定源热榜响应
@JsonSerializable(explicitToJson: true)
class DuomoyuRankingResp {
  @JsonKey(name: 'success')
  bool? success;

  @JsonKey(name: 'data')
  DuomoyuRankingData? data;

  DuomoyuRankingResp(this.success, this.data);

  factory DuomoyuRankingResp.fromJson(Map<String, dynamic> srcJson) =>
      _$DuomoyuRankingRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DuomoyuRankingRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DuomoyuRankingData {
  /// 当前源元数据
  @JsonKey(name: 'source')
  DuomoyuSource? source;

  /// 热榜条目
  @JsonKey(name: 'items')
  List<DuomoyuItem>? items;

  DuomoyuRankingData(this.source, this.items);

  factory DuomoyuRankingData.fromJson(Map<String, dynamic> srcJson) =>
      _$DuomoyuRankingDataFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DuomoyuRankingDataToJson(this);
}

/// 热榜条目
@JsonSerializable(explicitToJson: true)
class DuomoyuItem {
  /// 排名(从 1 开始)
  @JsonKey(name: 'rank')
  int? rank;

  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'url')
  String? url;

  /// 热度值，各源格式不一(数字/带单位字符串)，常为 null
  @JsonKey(name: 'hotValue')
  dynamic hotValue;

  /// 发布时间(ISO8601，常为 null)
  @JsonKey(name: 'publishedAt')
  String? publishedAt;

  DuomoyuItem(this.rank, this.title, this.url, this.hotValue, this.publishedAt);

  factory DuomoyuItem.fromJson(Map<String, dynamic> srcJson) =>
      _$DuomoyuItemFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DuomoyuItemToJson(this);

  /// 热度展示文本(无热度返回空串)
  String get hotDisplay {
    final v = hotValue?.toString();
    return (v == null || v.isEmpty) ? '' : '热度 $v';
  }
}
