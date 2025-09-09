// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'douguo_recommended_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DouguoRecommendedResp _$DouguoRecommendedRespFromJson(
  Map<String, dynamic> json,
) => DouguoRecommendedResp(
  state: json['state'] as String?,
  result: json['result'] == null
      ? null
      : DGRecommendedResult.fromJson(json['result'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DouguoRecommendedRespToJson(
  DouguoRecommendedResp instance,
) => <String, dynamic>{
  'state': instance.state,
  'result': instance.result?.toJson(),
};

DGRecommendedResult _$DGRecommendedResultFromJson(Map<String, dynamic> json) =>
    DGRecommendedResult(
      list: (json['list'] as List<dynamic>?)
          ?.map((e) => DGRecommendedList.fromJson(e as Map<String, dynamic>))
          .toList(),
      showHealthInformation: (json['show_health_information'] as num?)?.toInt(),
    );

Map<String, dynamic> _$DGRecommendedResultToJson(
  DGRecommendedResult instance,
) => <String, dynamic>{
  'list': instance.list?.map((e) => e.toJson()).toList(),
  'show_health_information': instance.showHealthInformation,
};

DGRecommendedList _$DGRecommendedListFromJson(Map<String, dynamic> json) =>
    DGRecommendedList(
      type: (json['type'] as num?)?.toInt(),
      r: json['r'] == null
          ? null
          : DGRoughItem.fromJson(json['r'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DGRecommendedListToJson(DGRecommendedList instance) =>
    <String, dynamic>{'type': instance.type, 'r': instance.r?.toJson()};

DGRoughItem _$DGRoughItemFromJson(Map<String, dynamic> json) => DGRoughItem(
  id: (json['id'] as num?)?.toInt(),
  n: json['n'] as String?,
  trimTitle: json['trim_title'] as String?,
  img: json['img'] as String?,
  pw: (json['pw'] as num?)?.toInt(),
  ph: (json['ph'] as num?)?.toInt(),
  vu: json['vu'] as String?,
  vfurl: json['vfurl'] as String?,
  a: json['a'] == null
      ? null
      : DGRoughAuthor.fromJson(json['a'] as Map<String, dynamic>),
  stdname: json['stdname'] as String?,
  gif: json['gif'] as String?,
  p: json['p'] as String?,
  vc: json['vc'] as String?,
  fc: (json['fc'] as num?)?.toInt(),
  collectCountText: json['collect_count_text'] as String?,
  cookDifficulty: json['cook_difficulty'] as String?,
  cookTime: json['cook_time'] as String?,
  major: (json['major'] as List<dynamic>?)
      ?.map((e) => DGRoughMajor.fromJson(e as Map<String, dynamic>))
      .toList(),
  tags: (json['tags'] as List<dynamic>?)
      ?.map((e) => DGRoughTag.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DGRoughItemToJson(DGRoughItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'n': instance.n,
      'trim_title': instance.trimTitle,
      'img': instance.img,
      'pw': instance.pw,
      'ph': instance.ph,
      'vu': instance.vu,
      'vfurl': instance.vfurl,
      'a': instance.a?.toJson(),
      'stdname': instance.stdname,
      'gif': instance.gif,
      'p': instance.p,
      'vc': instance.vc,
      'fc': instance.fc,
      'collect_count_text': instance.collectCountText,
      'cook_difficulty': instance.cookDifficulty,
      'cook_time': instance.cookTime,
      'major': instance.major?.map((e) => e.toJson()).toList(),
      'tags': instance.tags?.map((e) => e.toJson()).toList(),
    };

DGRoughMajor _$DGRoughMajorFromJson(Map<String, dynamic> json) => DGRoughMajor(
  note: json['note'] as String?,
  title: json['title'] as String?,
);

Map<String, dynamic> _$DGRoughMajorToJson(DGRoughMajor instance) =>
    <String, dynamic>{'note': instance.note, 'title': instance.title};

DGRoughTag _$DGRoughTagFromJson(Map<String, dynamic> json) =>
    DGRoughTag(t: json['t'] as String?);

Map<String, dynamic> _$DGRoughTagToJson(DGRoughTag instance) =>
    <String, dynamic>{'t': instance.t};

DGRoughAuthor _$DGRoughAuthorFromJson(Map<String, dynamic> json) =>
    DGRoughAuthor(
      id: json['id'],
      n: json['n'] as String?,
      v: (json['v'] as num?)?.toInt(),
      p: json['p'] as String?,
      lvl: (json['lvl'] as num?)?.toInt(),
      isPrime: json['is_prime'] as bool?,
      verifiedImage: json['verified_image'] as String?,
      progressImage: json['progress_image'] as String?,
      verifiedUrl: json['verified_url'] as String?,
    );

Map<String, dynamic> _$DGRoughAuthorToJson(DGRoughAuthor instance) =>
    <String, dynamic>{
      'id': instance.id,
      'n': instance.n,
      'v': instance.v,
      'p': instance.p,
      'lvl': instance.lvl,
      'is_prime': instance.isPrime,
      'verified_image': instance.verifiedImage,
      'progress_image': instance.progressImage,
      'verified_url': instance.verifiedUrl,
    };
