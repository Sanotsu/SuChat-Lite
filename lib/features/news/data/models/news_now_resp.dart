import 'package:json_annotation/json_annotation.dart';

part 'news_now_resp.g.dart';

///
/// NewsNow站点，也属于热点榜
/// https://newsnow.busiyi.world/
/// github上可以自行部署：https://github.com/ourongxing/newsnow
///
/// 从控制台得到的API
/// https://newsnow.busiyi.world/api/s?id=<分类>
///
@JsonSerializable(explicitToJson: true)
class NewsNowResp {
  @JsonKey(name: 'status')
  String? status;

  @JsonKey(name: 'id')
  String? id;

  @JsonKey(name: 'updatedTime')
  int? updatedTime;

  @JsonKey(name: 'items')
  List<NewsNowItem>? items;

  NewsNowResp(this.status, this.id, this.updatedTime, this.items);

  factory NewsNowResp.fromJson(Map<String, dynamic> srcJson) =>
      _$NewsNowRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$NewsNowRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class NewsNowItem {
  // 可能是字符串，可能是数字
  @JsonKey(name: 'id')
  dynamic id;

  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'extra')
  NewsNowRExtra? extra;

  @JsonKey(name: 'url')
  String? url;

  @JsonKey(name: 'mobileUrl')
  String? mobileUrl;

  NewsNowItem(this.id, this.title, this.extra, this.url, this.mobileUrl);

  factory NewsNowItem.fromJson(Map<String, dynamic> srcJson) =>
      _$NewsNowItemFromJson(srcJson);

  Map<String, dynamic> toJson() => _$NewsNowItemToJson(this);
}

@JsonSerializable(explicitToJson: true)
class NewsNowRExtra {
  @JsonKey(name: 'info')
  String? info;

  @JsonKey(name: 'hover')
  String? hover;

  NewsNowRExtra(this.info, this.hover);

  factory NewsNowRExtra.fromJson(Map<String, dynamic> srcJson) =>
      _$NewsNowRExtraFromJson(srcJson);

  Map<String, dynamic> toJson() => _$NewsNowRExtraToJson(this);
}
