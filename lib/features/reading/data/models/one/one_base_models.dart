import 'package:json_annotation/json_annotation.dart';

part 'one_base_models.g.dart';

/// “one一个” app 请求响应的基类
/// 所有的API返回结果都是这样的
@JsonSerializable(genericArgumentFactories: true, explicitToJson: true)
class OneBaseResp<T> {
  @JsonKey(name: 'res')
  final int? res;

  @JsonKey(name: 'data')
  final T? data;

  OneBaseResp({this.res, this.data});

  // 检查请求是否成功
  bool get isSuccess => res.toString() == "0";

  factory OneBaseResp.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return _$OneBaseRespFromJson(json, fromJsonT);
  }

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) {
    return _$OneBaseRespToJson(this, toJsonT);
  }
}

// 添加扩展方法，从积累中获取数据
extension OneBaseRespExtensions<T> on OneBaseResp<T> {
  /// 如果响应成功且数据不为空，返回数据；否则抛出异常
  T getDataOrThrow() {
    if (res == 0 && data != null) {
      return data!;
    }
    throw Exception("请求出错:\nres:$res\ndata:$data");
  }

  /// 如果响应成功且数据不为空，返回数据；否则返回null
  T? getDataOrNull() {
    return res == 0 ? data : null;
  }
}

// one的用户概要信息
@JsonSerializable(explicitToJson: true)
class OneUser {
  @JsonKey(name: 'user_id')
  String? userId;

  @JsonKey(name: 'user_name')
  String? userName;

  @JsonKey(name: 'web_url')
  String? webUrl;

  /// 如果是通过userId获取的用户信息，还有很多额外内容(有删除 permission 栏位)
  @JsonKey(name: 'background')
  String? background;

  @JsonKey(name: 'score')
  String? score;

  @JsonKey(name: 'permission')
  dynamic permission;

  @JsonKey(name: 'isdisabled')
  int? isdisabled;

  @JsonKey(name: 'isauthor')
  int? isauthor;

  @JsonKey(name: 'reg_type')
  String? regType;

  @JsonKey(name: 'reg_account')
  String? regAccount;

  @JsonKey(name: 'pay_count')
  int? payCount;

  @JsonKey(name: 'desc')
  String? desc;

  OneUser({
    this.userId,
    this.userName,
    this.webUrl,
    this.background,
    this.score,
    this.permission,
    this.isdisabled,
    this.isauthor,
    this.regType,
    this.regAccount,
    this.payCount,
    this.desc,
  });

  factory OneUser.fromJson(Map<String, dynamic> srcJson) =>
      _$OneUserFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneUserToJson(this);
}

// 不同地方作者信息可能有不同栏位，但都放在一起
@JsonSerializable(explicitToJson: true)
class OneAuthor {
  @JsonKey(name: 'user_id')
  String? userId;

  @JsonKey(name: 'user_name')
  String? userName;

  @JsonKey(name: 'desc')
  String? desc;

  @JsonKey(name: 'wb_name')
  String? wbName;

  @JsonKey(name: 'is_settled')
  String? isSettled;

  @JsonKey(name: 'settled_type')
  String? settledType;

  @JsonKey(name: 'summary')
  String? summary;

  @JsonKey(name: 'fans_total')
  String? fansTotal;

  @JsonKey(name: 'web_url')
  String? webUrl;

  OneAuthor({
    this.userId,
    this.userName,
    this.desc,
    this.wbName,
    this.isSettled,
    this.settledType,
    this.summary,
    this.fansTotal,
    this.webUrl,
  });

  factory OneAuthor.fromJson(Map<String, dynamic> srcJson) =>
      _$OneAuthorFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneAuthorToJson(this);
}

/// 每日推荐和图文(小记)详情接口会有这个天气栏位
@JsonSerializable(explicitToJson: true)
class OneWeather {
  @JsonKey(name: 'city_name')
  String? cityName;

  @JsonKey(name: 'date')
  String? date;

  @JsonKey(name: 'temperature')
  String? temperature;

  @JsonKey(name: 'humidity')
  String? humidity;

  @JsonKey(name: 'climate')
  String? climate;

  @JsonKey(name: 'wind_direction')
  String? windDirection;

  @JsonKey(name: 'hurricane')
  String? hurricane;

  @JsonKey(name: 'icons')
  OneWeatherIcon? icons;

  OneWeather({
    this.cityName,
    this.date,
    this.temperature,
    this.humidity,
    this.climate,
    this.windDirection,
    this.hurricane,
    this.icons,
  });

  factory OneWeather.fromJson(Map<String, dynamic> srcJson) =>
      _$OneWeatherFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneWeatherToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OneWeatherIcon {
  @JsonKey(name: 'day')
  String? day;

  @JsonKey(name: 'night')
  String? night;

  OneWeatherIcon({this.day, this.night});

  factory OneWeatherIcon.fromJson(Map<String, dynamic> srcJson) =>
      _$OneWeatherIconFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneWeatherIconToJson(this);
}

/// 文章详情等地方会用到tagList
@JsonSerializable(explicitToJson: true)
class OneTag {
  @JsonKey(name: 'id')
  String? id;

  @JsonKey(name: 'title')
  String? title;

  OneTag({this.id, this.title});

  factory OneTag.fromJson(Map<String, dynamic> srcJson) =>
      _$OneTagFromJson(srcJson);

  Map<String, dynamic> toJson() => _$OneTagToJson(this);
}
