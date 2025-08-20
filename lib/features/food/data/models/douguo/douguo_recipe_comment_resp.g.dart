// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'douguo_recipe_comment_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DouguoRecipeCommentResp _$DouguoRecipeCommentRespFromJson(
  Map<String, dynamic> json,
) => DouguoRecipeCommentResp(
  state: json['state'] as String?,
  result: json['result'] == null
      ? null
      : DGRecipeCommentResult.fromJson(json['result'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DouguoRecipeCommentRespToJson(
  DouguoRecipeCommentResp instance,
) => <String, dynamic>{
  'state': instance.state,
  'result': instance.result?.toJson(),
};

DGRecipeCommentResult _$DGRecipeCommentResultFromJson(
  Map<String, dynamic> json,
) => DGRecipeCommentResult(
  comments: (json['comments'] as List<dynamic>?)
      ?.map((e) => DGRecipeComment.fromJson(e as Map<String, dynamic>))
      .toList(),
  cc: (json['cc'] as num?)?.toInt(),
);

Map<String, dynamic> _$DGRecipeCommentResultToJson(
  DGRecipeCommentResult instance,
) => <String, dynamic>{
  'comments': instance.comments?.map((e) => e.toJson()).toList(),
  'cc': instance.cc,
};

DGRecipeComment _$DGRecipeCommentFromJson(Map<String, dynamic> json) =>
    DGRecipeComment(
      id: json['id'],
      u: json['u'] == null
          ? null
          : DGRoughAuthor.fromJson(json['u'] as Map<String, dynamic>),
      content: (json['content'] as List<dynamic>?)
          ?.map(
            (e) => DGRecipeCommentContent.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      time: json['time'] as String?,
      replyId: (json['reply_id'] as num?)?.toInt(),
      likeCount: (json['like_count'] as num?)?.toInt(),
      city: json['city'] as String?,
      at: json['at'] as String?,
      ipAddressLocation: json['ip_address_location'] as String?,
      childComments: (json['child_comments'] as List<dynamic>?)
          ?.map((e) => DGRecipeComment.fromJson(e as Map<String, dynamic>))
          .toList(),
      replyUser: json['reply_user'] == null
          ? null
          : DGRoughAuthor.fromJson(json['reply_user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DGRecipeCommentToJson(DGRecipeComment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'u': instance.u?.toJson(),
      'content': instance.content?.map((e) => e.toJson()).toList(),
      'time': instance.time,
      'reply_id': instance.replyId,
      'like_count': instance.likeCount,
      'city': instance.city,
      'at': instance.at,
      'ip_address_location': instance.ipAddressLocation,
      'child_comments': instance.childComments?.map((e) => e.toJson()).toList(),
      'reply_user': instance.replyUser?.toJson(),
    };

DGRecipeCommentContent _$DGRecipeCommentContentFromJson(
  Map<String, dynamic> json,
) => DGRecipeCommentContent(c: json['c'] as String?);

Map<String, dynamic> _$DGRecipeCommentContentToJson(
  DGRecipeCommentContent instance,
) => <String, dynamic>{'c': instance.c};
