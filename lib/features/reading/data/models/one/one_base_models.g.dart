// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'one_base_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OneBaseResp<T> _$OneBaseRespFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => OneBaseResp<T>(
  res: (json['res'] as num?)?.toInt(),
  data: _$nullableGenericFromJson(json['data'], fromJsonT),
);

Map<String, dynamic> _$OneBaseRespToJson<T>(
  OneBaseResp<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'res': instance.res,
  'data': _$nullableGenericToJson(instance.data, toJsonT),
};

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) => input == null ? null : fromJson(input);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) => input == null ? null : toJson(input);

OneUser _$OneUserFromJson(Map<String, dynamic> json) => OneUser(
  userId: json['user_id'] as String?,
  userName: json['user_name'] as String?,
  webUrl: json['web_url'] as String?,
  background: json['background'] as String?,
  score: json['score'] as String?,
  permission: json['permission'],
  isdisabled: (json['isdisabled'] as num?)?.toInt(),
  isauthor: (json['isauthor'] as num?)?.toInt(),
  regType: json['reg_type'] as String?,
  regAccount: json['reg_account'] as String?,
  payCount: (json['pay_count'] as num?)?.toInt(),
  desc: json['desc'] as String?,
);

Map<String, dynamic> _$OneUserToJson(OneUser instance) => <String, dynamic>{
  'user_id': instance.userId,
  'user_name': instance.userName,
  'web_url': instance.webUrl,
  'background': instance.background,
  'score': instance.score,
  'permission': instance.permission,
  'isdisabled': instance.isdisabled,
  'isauthor': instance.isauthor,
  'reg_type': instance.regType,
  'reg_account': instance.regAccount,
  'pay_count': instance.payCount,
  'desc': instance.desc,
};

OneAuthor _$OneAuthorFromJson(Map<String, dynamic> json) => OneAuthor(
  userId: json['user_id'] as String?,
  userName: json['user_name'] as String?,
  desc: json['desc'] as String?,
  wbName: json['wb_name'] as String?,
  isSettled: json['is_settled'] as String?,
  settledType: json['settled_type'] as String?,
  summary: json['summary'] as String?,
  fansTotal: json['fans_total'] as String?,
  webUrl: json['web_url'] as String?,
);

Map<String, dynamic> _$OneAuthorToJson(OneAuthor instance) => <String, dynamic>{
  'user_id': instance.userId,
  'user_name': instance.userName,
  'desc': instance.desc,
  'wb_name': instance.wbName,
  'is_settled': instance.isSettled,
  'settled_type': instance.settledType,
  'summary': instance.summary,
  'fans_total': instance.fansTotal,
  'web_url': instance.webUrl,
};

OneWeather _$OneWeatherFromJson(Map<String, dynamic> json) => OneWeather(
  cityName: json['city_name'] as String?,
  date: json['date'] as String?,
  temperature: json['temperature'] as String?,
  humidity: json['humidity'] as String?,
  climate: json['climate'] as String?,
  windDirection: json['wind_direction'] as String?,
  hurricane: json['hurricane'] as String?,
  icons: json['icons'] == null
      ? null
      : OneWeatherIcon.fromJson(json['icons'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OneWeatherToJson(OneWeather instance) =>
    <String, dynamic>{
      'city_name': instance.cityName,
      'date': instance.date,
      'temperature': instance.temperature,
      'humidity': instance.humidity,
      'climate': instance.climate,
      'wind_direction': instance.windDirection,
      'hurricane': instance.hurricane,
      'icons': instance.icons?.toJson(),
    };

OneWeatherIcon _$OneWeatherIconFromJson(Map<String, dynamic> json) =>
    OneWeatherIcon(
      day: json['day'] as String?,
      night: json['night'] as String?,
    );

Map<String, dynamic> _$OneWeatherIconToJson(OneWeatherIcon instance) =>
    <String, dynamic>{'day': instance.day, 'night': instance.night};

OneTag _$OneTagFromJson(Map<String, dynamic> json) =>
    OneTag(id: json['id'] as String?, title: json['title'] as String?);

Map<String, dynamic> _$OneTagToJson(OneTag instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
};
