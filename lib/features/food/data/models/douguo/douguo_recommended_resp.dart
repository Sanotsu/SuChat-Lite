import 'package:json_annotation/json_annotation.dart';

part 'douguo_recommended_resp.g.dart';

///
/// 豆果 菜谱推荐列表
///
/// API数据来源：
/// https://apis.netstart.cn/douguo/#/
///
/// DouGuoRecommended -> DGRecommended
///
/// 栏位很多，有删减
///
@JsonSerializable(explicitToJson: true)
class DouguoRecommendedResp {
  @JsonKey(name: 'state')
  String? state;

  @JsonKey(name: 'result')
  DGRecommendedResult? result;

  DouguoRecommendedResp({this.state, this.result});

  factory DouguoRecommendedResp.fromJson(Map<String, dynamic> srcJson) =>
      _$DouguoRecommendedRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DouguoRecommendedRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DGRecommendedResult {
  @JsonKey(name: 'list')
  List<DGRecommendedList>? list;

  @JsonKey(name: 'show_health_information')
  int? showHealthInformation;

  DGRecommendedResult({this.list, this.showHealthInformation});

  factory DGRecommendedResult.fromJson(Map<String, dynamic> srcJson) =>
      _$DGRecommendedResultFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DGRecommendedResultToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DGRecommendedList {
  @JsonKey(name: 'type')
  int? type;

  // 这个应该是菜谱概要信息，在搜索API的结果中有个类似的r
  // 我就简单构建为粗略的信息
  @JsonKey(name: 'r')
  DGRoughItem? r;

  DGRecommendedList({this.type, this.r});

  factory DGRecommendedList.fromJson(Map<String, dynamic> srcJson) =>
      _$DGRecommendedListFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DGRecommendedListToJson(this);
}

// 推荐菜谱概要信息(有删除一些比如收藏信息等栏位)
// 搜索结果中的r也是类似，但会多一些栏位，揉在一起了
@JsonSerializable(explicitToJson: true)
class DGRoughItem {
  @JsonKey(name: 'id')
  int? id;

  // 名称
  @JsonKey(name: 'n')
  String? n;

  // 二级名称
  @JsonKey(name: 'trim_title')
  String? trimTitle;

  // 菜肴的预览图
  @JsonKey(name: 'img')
  String? img;

  // 原图尺寸
  @JsonKey(name: 'pw')
  int? pw;

  @JsonKey(name: 'ph')
  int? ph;

  // 可能有预览的视频?
  @JsonKey(name: 'vu')
  String? vu;

  @JsonKey(name: 'vfurl')
  String? vfurl;

  // 这个应该是菜谱的作者
  @JsonKey(name: 'a')
  DGRoughAuthor? a;

  // 菜品的标准名称
  @JsonKey(name: 'stdname')
  String? stdname;

  // 菜品的gif图片和原图
  @JsonKey(name: 'gif')
  String? gif;

  @JsonKey(name: 'p')
  String? p;

  // 可能是看过人数
  @JsonKey(name: 'vc')
  String? vc;

  // 可能是添加到收藏或在最爱的人数
  @JsonKey(name: 'fc')
  int? fc;

  // 可能是添加到收藏或在最爱的人数文本形式
  @JsonKey(name: 'collect_count_text')
  String? collectCountText;

  /// 搜索结果中也有一个r的栏位，内容比较相似，这里加一点搜索结果中额外的
  // 难度
  @JsonKey(name: 'cook_difficulty')
  String? cookDifficulty;

  // 烹饪时间
  @JsonKey(name: 'cook_time')
  String? cookTime;

  @JsonKey(name: 'major')
  List<DGRoughMajor>? major;

  @JsonKey(name: 'tags')
  List<DGRoughTag>? tags;

  DGRoughItem({
    this.id,
    this.n,
    this.trimTitle,
    this.img,
    this.pw,
    this.ph,
    this.vu,
    this.vfurl,
    this.a,
    this.stdname,
    this.gif,
    this.p,
    this.vc,
    this.fc,
    this.collectCountText,
    this.cookDifficulty,
    this.cookTime,
    this.major,
    this.tags,
  });

  factory DGRoughItem.fromJson(Map<String, dynamic> srcJson) =>
      _$DGRoughItemFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DGRoughItemToJson(this);
}

// 主要原材料-粗略信息(菜谱详情信息更多)
@JsonSerializable(explicitToJson: true)
class DGRoughMajor {
  @JsonKey(name: 'note')
  String? note;

  @JsonKey(name: 'title')
  String? title;

  DGRoughMajor({this.note, this.title});

  factory DGRoughMajor.fromJson(Map<String, dynamic> srcJson) =>
      _$DGRoughMajorFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DGRoughMajorToJson(this);
}

// 菜谱标签
@JsonSerializable(explicitToJson: true)
class DGRoughTag {
  @JsonKey(name: 't')
  String? t;

  DGRoughTag({this.t});

  factory DGRoughTag.fromJson(Map<String, dynamic> srcJson) =>
      _$DGRoughTagFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DGRoughTagToJson(this);
}

// 菜谱的作者信息
@JsonSerializable(explicitToJson: true)
class DGRoughAuthor {
  // 这个作者id也可能是字符串
  @JsonKey(name: 'id')
  dynamic id;

  // 名称
  @JsonKey(name: 'n')
  String? n;

  @JsonKey(name: 'v')
  int? v;

  // 头像
  @JsonKey(name: 'p')
  String? p;

  // 等级
  @JsonKey(name: 'lvl')
  int? lvl;

  // 是否是会员
  @JsonKey(name: 'is_prime')
  bool? isPrime;

  // 应该是一些认证信息
  @JsonKey(name: 'verified_image')
  String? verifiedImage;

  @JsonKey(name: 'progress_image')
  String? progressImage;

  @JsonKey(name: 'verified_url')
  String? verifiedUrl;

  DGRoughAuthor({
    this.id,
    this.n,
    this.v,
    this.p,
    this.lvl,
    this.isPrime,
    this.verifiedImage,
    this.progressImage,
    this.verifiedUrl,
  });

  factory DGRoughAuthor.fromJson(Map<String, dynamic> srcJson) =>
      _$DGRoughAuthorFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DGRoughAuthorToJson(this);
}
