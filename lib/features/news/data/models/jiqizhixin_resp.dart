import 'package:json_annotation/json_annotation.dart';

part 'jiqizhixin_resp.g.dart';

///
/// 机器之心官网控制台看到的
///
/// https://www.jiqizhixin.com/api/v4/articles.json?sort=time&page=1&per=12
///

@JsonSerializable(explicitToJson: true)
class JiqizhixinResp {
  @JsonKey(name: 'success')
  bool? success;

  @JsonKey(name: 'articles')
  List<JiqizhixinArticle>? articles;

  @JsonKey(name: 'tags')
  List<String>? tags;

  @JsonKey(name: 'totalCount')
  int? totalCount;

  @JsonKey(name: 'hasNextPage')
  bool? hasNextPage;

  @JsonKey(name: 'publishedArticlesCount')
  int? publishedArticlesCount;

  @JsonKey(name: 'elapsedDays')
  int? elapsedDays;

  JiqizhixinResp(
    this.success,
    this.articles,
    this.tags,
    this.totalCount,
    this.hasNextPage,
    this.publishedArticlesCount,
    this.elapsedDays,
  );

  factory JiqizhixinResp.fromJson(Map<String, dynamic> srcJson) =>
      _$JiqizhixinRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$JiqizhixinRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class JiqizhixinArticle {
  @JsonKey(name: 'id')
  String? id;

  @JsonKey(name: 'title')
  String? title;

  @JsonKey(name: 'coverImageUrl')
  String? coverImageUrl;

  @JsonKey(name: 'category')
  String? category;

  @JsonKey(name: 'slug')
  String? slug;

  @JsonKey(name: 'tagList')
  List<String>? tagList;

  @JsonKey(name: 'author')
  String? author;

  @JsonKey(name: 'publishedAt')
  String? publishedAt;

  @JsonKey(name: 'content')
  String? content;

  @JsonKey(name: 'source')
  String? source;

  JiqizhixinArticle(
    this.id,
    this.title,
    this.coverImageUrl,
    this.category,
    this.slug,
    this.tagList,
    this.author,
    this.publishedAt,
    this.content,
    this.source,
  );

  factory JiqizhixinArticle.fromJson(Map<String, dynamic> srcJson) =>
      _$JiqizhixinArticleFromJson(srcJson);

  Map<String, dynamic> toJson() => _$JiqizhixinArticleToJson(this);
}
