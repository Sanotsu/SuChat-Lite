import 'package:json_annotation/json_annotation.dart';

import 'douguo_recommended_resp.dart';

part 'douguo_recipe_comment_resp.g.dart';

///
/// 豆果 菜谱评论详情
///
/// API数据来源：
/// https://apis.netstart.cn/douguo/#/
///
/// DouGuoRecipeComment -> DGRecipeComment
///
/// 栏位很多，有删减
///
@JsonSerializable(explicitToJson: true)
class DouguoRecipeCommentResp {
  @JsonKey(name: 'state')
  String? state;

  @JsonKey(name: 'result')
  DGRecipeCommentResult? result;

  DouguoRecipeCommentResp({this.state, this.result});

  factory DouguoRecipeCommentResp.fromJson(Map<String, dynamic> srcJson) =>
      _$DouguoRecipeCommentRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DouguoRecipeCommentRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DGRecipeCommentResult {
  @JsonKey(name: 'comments')
  List<DGRecipeComment>? comments;

  // 评论总数
  @JsonKey(name: 'cc')
  int? cc;

  DGRecipeCommentResult({this.comments, this.cc});

  factory DGRecipeCommentResult.fromJson(Map<String, dynamic> srcJson) =>
      _$DGRecipeCommentResultFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DGRecipeCommentResultToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DGRecipeComment {
  // 可能是int或者String
  @JsonKey(name: 'id')
  dynamic id;

  // 这个u和推荐列表或者搜索列表中的r是一样的结构，都是粗略的用户信息，这里就是评论人的基本信息
  @JsonKey(name: 'u')
  DGRoughAuthor? u;

  // 评论的具体内容
  @JsonKey(name: 'content')
  List<DGRecipeCommentContent>? content;

  // 应该是评论的时间，但目前api返回的都是空字符串
  @JsonKey(name: 'time')
  String? time;

  // 如果是第一层评论菜谱本身的，这个是0；
  // 如果是回复某条评论的，这里是被回复评论的id
  @JsonKey(name: 'reply_id')
  int? replyId;

  // 评论被喜欢的数量
  @JsonKey(name: 'like_count')
  int? likeCount;

  // 用户所在的城市
  @JsonKey(name: 'city')
  String? city;

  @JsonKey(name: 'at')
  String? at;

  // 评论的IP地址
  @JsonKey(name: 'ip_address_location')
  String? ipAddressLocation;

  // 如果有嵌套的子评论，这里就是子评论
  // 子评论的结构和菜谱直接的评论相比，多一个reply_user，其他一样，所以放在一个类型中
  @JsonKey(name: 'child_comments')
  List<DGRecipeComment>? childComments;

  /// 子评论才有的回复评论的用户信息
  @JsonKey(name: 'reply_user')
  DGRoughAuthor? replyUser;

  DGRecipeComment({
    this.id,
    this.u,
    this.content,
    this.time,
    this.replyId,
    this.likeCount,
    this.city,
    this.at,
    this.ipAddressLocation,
    this.childComments,
    this.replyUser,
  });

  factory DGRecipeComment.fromJson(Map<String, dynamic> srcJson) =>
      _$DGRecipeCommentFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DGRecipeCommentToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DGRecipeCommentContent {
  @JsonKey(name: 'c')
  String? c;

  DGRecipeCommentContent({this.c});

  factory DGRecipeCommentContent.fromJson(Map<String, dynamic> srcJson) =>
      _$DGRecipeCommentContentFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DGRecipeCommentContentToJson(this);
}
