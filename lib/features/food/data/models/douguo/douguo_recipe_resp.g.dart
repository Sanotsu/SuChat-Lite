// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'douguo_recipe_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DouguoRecipeResp _$DouguoRecipeRespFromJson(Map<String, dynamic> json) =>
    DouguoRecipeResp(
      state: json['state'] as String?,
      result: json['result'] == null
          ? null
          : DGRecipeResult.fromJson(json['result'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DouguoRecipeRespToJson(DouguoRecipeResp instance) =>
    <String, dynamic>{
      'state': instance.state,
      'result': instance.result?.toJson(),
    };

DGRecipeResult _$DGRecipeResultFromJson(Map<String, dynamic> json) =>
    DGRecipeResult(
      recipe: json['recipe'] == null
          ? null
          : DGRecipe.fromJson(json['recipe'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DGRecipeResultToJson(DGRecipeResult instance) =>
    <String, dynamic>{'recipe': instance.recipe?.toJson()};

DGRecipe _$DGRecipeFromJson(Map<String, dynamic> json) => DGRecipe(
  cookId: json['cook_id'] as String?,
  as: (json['as'] as num?)?.toInt(),
  title: json['title'] as String?,
  thumbPath: json['thumb_path'] as String?,
  photoPath: json['photo_path'] as String?,
  originalPhotoPath: json['original_photo_path'] as String?,
  tips: json['tips'] as String?,
  cookstory: json['cookstory'] as String?,
  cookstep: (json['cookstep'] as List<dynamic>?)
      ?.map((e) => DGCookStep.fromJson(e as Map<String, dynamic>))
      .toList(),
  cookTime: json['cook_time'] as String?,
  cookDifficulty: json['cook_difficulty'] as String?,
  major: (json['major'] as List<dynamic>?)
      ?.map((e) => DGRecipeMajor.fromJson(e as Map<String, dynamic>))
      .toList(),
  createTime: json['create_time'] as String?,
  cookDifficultyText: json['cook_difficulty_text'] as String?,
  cookDifficultyImage: json['cook_difficulty_image'] as String?,
  vu: json['vu'] as String?,
  pvurl: json['pvurl'] as String?,
  nutritionFactsUrl: json['nutrition_facts_url'] as String?,
  releaseTime: json['release_time'] as String?,
  user: json['user'] == null
      ? null
      : DGRecipeUser.fromJson(json['user'] as Map<String, dynamic>),
  commentsCount: (json['comments_count'] as num?)?.toInt(),
  favoCounts: (json['favo_counts'] as num?)?.toInt(),
  vc: (json['vc'] as num?)?.toInt(),
);

Map<String, dynamic> _$DGRecipeToJson(DGRecipe instance) => <String, dynamic>{
  'cook_id': instance.cookId,
  'as': instance.as,
  'title': instance.title,
  'thumb_path': instance.thumbPath,
  'photo_path': instance.photoPath,
  'original_photo_path': instance.originalPhotoPath,
  'tips': instance.tips,
  'cookstory': instance.cookstory,
  'cookstep': instance.cookstep?.map((e) => e.toJson()).toList(),
  'cook_time': instance.cookTime,
  'cook_difficulty': instance.cookDifficulty,
  'major': instance.major?.map((e) => e.toJson()).toList(),
  'create_time': instance.createTime,
  'cook_difficulty_text': instance.cookDifficultyText,
  'cook_difficulty_image': instance.cookDifficultyImage,
  'vu': instance.vu,
  'pvurl': instance.pvurl,
  'nutrition_facts_url': instance.nutritionFactsUrl,
  'release_time': instance.releaseTime,
  'user': instance.user?.toJson(),
  'comments_count': instance.commentsCount,
  'favo_counts': instance.favoCounts,
  'vc': instance.vc,
};

DGCookStep _$DGCookStepFromJson(Map<String, dynamic> json) => DGCookStep(
  position: json['position'],
  content: json['content'] as String?,
  thumb: json['thumb'] as String?,
  imageWidth: (json['image_width'] as num?)?.toInt(),
  imageHeight: (json['image_height'] as num?)?.toInt(),
  frame: json['frame'] as String?,
  image: json['image'] as String?,
  stepContent: (json['step_content'] as List<dynamic>?)
      ?.map((e) => DGCookStepContent.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DGCookStepToJson(DGCookStep instance) =>
    <String, dynamic>{
      'position': instance.position,
      'content': instance.content,
      'thumb': instance.thumb,
      'image_width': instance.imageWidth,
      'image_height': instance.imageHeight,
      'frame': instance.frame,
      'image': instance.image,
      'step_content': instance.stepContent?.map((e) => e.toJson()).toList(),
    };

DGCookStepContent _$DGCookStepContentFromJson(Map<String, dynamic> json) =>
    DGCookStepContent(
      isKeyword: json['is_keyword'] as bool?,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$DGCookStepContentToJson(DGCookStepContent instance) =>
    <String, dynamic>{'is_keyword': instance.isKeyword, 'name': instance.name};

DGRecipeMajor _$DGRecipeMajorFromJson(Map<String, dynamic> json) =>
    DGRecipeMajor(
      title: json['title'] as String?,
      note: json['note'] as String?,
      tu: json['tu'] as String?,
      majorName: (json['major_name'] as List<dynamic>?)
          ?.map((e) => DGRecipeMajorName.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DGRecipeMajorToJson(DGRecipeMajor instance) =>
    <String, dynamic>{
      'title': instance.title,
      'note': instance.note,
      'tu': instance.tu,
      'major_name': instance.majorName?.map((e) => e.toJson()).toList(),
    };

DGRecipeMajorName _$DGRecipeMajorNameFromJson(Map<String, dynamic> json) =>
    DGRecipeMajorName(
      isKeyword: json['is_keyword'] as bool?,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$DGRecipeMajorNameToJson(DGRecipeMajorName instance) =>
    <String, dynamic>{'is_keyword': instance.isKeyword, 'name': instance.name};

DGRecipeUser _$DGRecipeUserFromJson(Map<String, dynamic> json) => DGRecipeUser(
  userId: json['user_id'],
  nick: json['nick'] as String?,
  nickname: json['nickname'] as String?,
  userPhoto: json['user_photo'] as String?,
  avatarMedium: json['avatar_medium'] as String?,
  verified: (json['verified'] as num?)?.toInt(),
  lvl: (json['lvl'] as num?)?.toInt(),
  isPrime: json['is_prime'] as bool?,
  verifiedImage: json['verified_image'] as String?,
  relationship: (json['relationship'] as num?)?.toInt(),
);

Map<String, dynamic> _$DGRecipeUserToJson(DGRecipeUser instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'nick': instance.nick,
      'nickname': instance.nickname,
      'user_photo': instance.userPhoto,
      'avatar_medium': instance.avatarMedium,
      'verified': instance.verified,
      'lvl': instance.lvl,
      'is_prime': instance.isPrime,
      'verified_image': instance.verifiedImage,
      'relationship': instance.relationship,
    };
