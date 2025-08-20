import 'package:json_annotation/json_annotation.dart';

part 'baike_history_in_today_resp.g.dart';

/// 不知道那里的来源了
/// https://api.asilu.com/today
///
/// 还有一个60s的api
/// https://60s.viki.moe/v2/today_in_history
/// 外面还有一层，直接取data就和第一个基本一样了
/// url都是指向装百度百科的连接
///
///  BaikeHihItem -> Baike history in today item

@JsonSerializable(explicitToJson: true)
class BaikeHistoryInTodayResp {
  @JsonKey(name: 'code')
  int? code;

  @JsonKey(name: 'date')
  String? date;

  // 返回可能是字符串，可能是int
  @JsonKey(name: 'month')
  dynamic month;

  @JsonKey(name: 'day')
  dynamic day;

  // 使用 readValue 动态解析 "data" 或 "items" 字段
  @JsonKey(readValue: _readItems)
  List<BaikeHihItem>? items;

  BaikeHistoryInTodayResp(this.code, this.month, this.day, this.items);

  factory BaikeHistoryInTodayResp.fromJson(Map<String, dynamic> srcJson) =>
      _$BaikeHistoryInTodayRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$BaikeHistoryInTodayRespToJson(this);

  static Object? _readItems(Map<dynamic, dynamic> json, String key) {
    return json['data'] ?? json['items'];
  }
}

@JsonSerializable(explicitToJson: true)
class BaikeHihItem {
  // 一个返回int，一个返回string
  @JsonKey(name: 'year')
  dynamic year;

  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'link')
  String? link;

  // 使用 readValue 动态解析 "type" 或 "event_type" 字段
  @JsonKey(readValue: _readType)
  String? type;

  @JsonKey(name: 'description')
  String? description;

  BaikeHihItem(this.year, this.title, this.link, this.type);

  factory BaikeHihItem.fromJson(Map<String, dynamic> srcJson) =>
      _$BaikeHihItemFromJson(srcJson);

  Map<String, dynamic> toJson() => _$BaikeHihItemToJson(this);

  static Object? _readType(Map<dynamic, dynamic> json, String key) {
    return json['type'] ?? json['event_type'];
  }
}
