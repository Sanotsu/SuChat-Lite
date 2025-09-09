import 'package:json_annotation/json_annotation.dart';

part 'douguo_recipe_resp.g.dart';

///
/// 豆果 菜谱详情
///
/// API数据来源：
/// https://apis.netstart.cn/douguo/#/
///
/// DouGuoRecipe -> DGRecipe
///
/// 栏位很多，有删减
///
///
@JsonSerializable(explicitToJson: true)
class DouguoRecipeResp {
  @JsonKey(name: 'state')
  String? state;

  // 菜谱详情放在了一个result栏位中
  @JsonKey(name: 'result')
  DGRecipeResult? result;

  DouguoRecipeResp({this.state, this.result});

  factory DouguoRecipeResp.fromJson(Map<String, dynamic> srcJson) =>
      _$DouguoRecipeRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DouguoRecipeRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DGRecipeResult {
  @JsonKey(name: 'recipe')
  DGRecipe? recipe;

  DGRecipeResult({this.recipe});

  factory DGRecipeResult.fromJson(Map<String, dynamic> srcJson) =>
      _$DGRecipeResultFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DGRecipeResultToJson(this);
}

/// 菜谱详情，删除了大量的栏位，只留了部分我认为需要的
@JsonSerializable(explicitToJson: true)
class DGRecipe {
  @JsonKey(name: 'cook_id')
  String? cookId;

  @JsonKey(name: 'as')
  int? as;

  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'thumb_path')
  String? thumbPath;

  @JsonKey(name: 'photo_path')
  String? photoPath;

  @JsonKey(name: 'original_photo_path')
  String? originalPhotoPath;

  @JsonKey(name: 'tips')
  String? tips;

  @JsonKey(name: 'cookstory')
  String? cookstory;

  @JsonKey(name: 'cookstep')
  List<DGCookStep>? cookstep;

  @JsonKey(name: 'cook_time')
  String? cookTime;

  @JsonKey(name: 'cook_difficulty')
  String? cookDifficulty;

  @JsonKey(name: 'major')
  List<DGRecipeMajor>? major;

  @JsonKey(name: 'create_time')
  String? createTime;

  @JsonKey(name: 'cook_difficulty_text')
  String? cookDifficultyText;

  @JsonKey(name: 'cook_difficulty_image')
  String? cookDifficultyImage;

  @JsonKey(name: 'vu')
  String? vu;

  @JsonKey(name: 'pvurl')
  String? pvurl;

  // 这是一个营养成分的地址，直接访问这个，或在WebView构建
  @JsonKey(name: 'nutrition_facts_url')
  String? nutritionFactsUrl;

  @JsonKey(name: 'release_time')
  String? releaseTime;

  @JsonKey(name: 'user')
  DGRecipeUser? user;

  // 评论数
  @JsonKey(name: 'comments_count')
  int? commentsCount;

  // 收藏数
  @JsonKey(name: 'favo_counts')
  int? favoCounts;

  // 浏览数
  @JsonKey(name: 'vc')
  int? vc;

  DGRecipe({
    this.cookId,
    this.as,
    this.title,
    this.thumbPath,
    this.photoPath,
    this.originalPhotoPath,
    this.tips,
    this.cookstory,
    this.cookstep,
    this.cookTime,
    this.cookDifficulty,
    this.major,
    this.createTime,
    this.cookDifficultyText,
    this.cookDifficultyImage,
    this.vu,
    this.pvurl,
    this.nutritionFactsUrl,
    this.releaseTime,
    this.user,
    this.commentsCount,
    this.favoCounts,
    this.vc,
  });

  factory DGRecipe.fromJson(Map<String, dynamic> srcJson) =>
      _$DGRecipeFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DGRecipeToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DGCookStep {
  // 可能是int可能是String
  @JsonKey(name: 'position')
  dynamic position;

  @JsonKey(name: 'content')
  String? content;

  @JsonKey(name: 'thumb')
  String? thumb;

  @JsonKey(name: 'image_width')
  int? imageWidth;

  @JsonKey(name: 'image_height')
  int? imageHeight;

  @JsonKey(name: 'frame')
  String? frame;

  @JsonKey(name: 'image')
  String? image;

  @JsonKey(name: 'step_content')
  List<DGCookStepContent>? stepContent;

  DGCookStep({
    this.position,
    this.content,
    this.thumb,
    this.imageWidth,
    this.imageHeight,
    this.frame,
    this.image,
    this.stepContent,
  });

  factory DGCookStep.fromJson(Map<String, dynamic> srcJson) =>
      _$DGCookStepFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DGCookStepToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DGCookStepContent {
  @JsonKey(name: 'is_keyword')
  bool? isKeyword;

  @JsonKey(name: 'name')
  String? name;

  DGCookStepContent({this.isKeyword, this.name});

  factory DGCookStepContent.fromJson(Map<String, dynamic> srcJson) =>
      _$DGCookStepContentFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DGCookStepContentToJson(this);
}

// 菜谱主要食材
@JsonSerializable(explicitToJson: true)
class DGRecipeMajor {
  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'note')
  String? note;

  // 食材详情-直接显示url
  @JsonKey(name: 'tu')
  String? tu;

  @JsonKey(name: 'major_name')
  List<DGRecipeMajorName>? majorName;

  DGRecipeMajor({this.title, this.note, this.tu, this.majorName});

  factory DGRecipeMajor.fromJson(Map<String, dynamic> srcJson) =>
      _$DGRecipeMajorFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DGRecipeMajorToJson(this);
}

// 主要适材适所名称
@JsonSerializable()
class DGRecipeMajorName {
  @JsonKey(name: 'is_keyword')
  bool? isKeyword;

  @JsonKey(name: 'name')
  String? name;

  DGRecipeMajorName({this.isKeyword, this.name});

  factory DGRecipeMajorName.fromJson(Map<String, dynamic> srcJson) =>
      _$DGRecipeMajorNameFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DGRecipeMajorNameToJson(this);
}

// 菜谱详情页的用户信息
// 和推荐、搜索结果中的作者信息栏位差别挺大的
@JsonSerializable(explicitToJson: true)
class DGRecipeUser {
  // 可能是字符串，可能是数值
  @JsonKey(name: 'user_id')
  dynamic userId;

  @JsonKey(name: 'nick')
  String? nick;

  @JsonKey(name: 'nickname')
  String? nickname;

  @JsonKey(name: 'user_photo')
  String? userPhoto;

  @JsonKey(name: 'avatar_medium')
  String? avatarMedium;

  @JsonKey(name: 'verified')
  int? verified;

  @JsonKey(name: 'lvl')
  int? lvl;

  @JsonKey(name: 'is_prime')
  bool? isPrime;

  @JsonKey(name: 'verified_image')
  String? verifiedImage;

  @JsonKey(name: 'relationship')
  int? relationship;

  DGRecipeUser({
    this.userId,
    this.nick,
    this.nickname,
    this.userPhoto,
    this.avatarMedium,
    this.verified,
    this.lvl,
    this.isPrime,
    this.verifiedImage,
    this.relationship,
  });

  factory DGRecipeUser.fromJson(Map<String, dynamic> srcJson) =>
      _$DGRecipeUserFromJson(srcJson);

  Map<String, dynamic> toJson() => _$DGRecipeUserToJson(this);
}
