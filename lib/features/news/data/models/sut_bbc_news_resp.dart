import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'sut_bbc_news_resp.g.dart';

///
/// 来源于 https://github.com/Sayad-Uddin-Tahsin/BBC-News-API
/// 结构很奇怪，不同的语言结构不一样，且key是关键字，不同语言还不一样
///
/// Sayad-Uddin-Tahsin/BBC-News-API -> SUTBBCNews
///

class SutBbcNewsResp {
  final int? status;
  final List<SutBbcNewsCategory>? categories;
  final String? elapsedTime;
  final int? timestamp;

  SutBbcNewsResp({
    this.status,
    this.categories,
    this.elapsedTime,
    this.timestamp,
  });

  factory SutBbcNewsResp.fromJson(Map<String, dynamic> json) {
    final categories = <SutBbcNewsCategory>[];

    json.forEach((key, value) {
      if (key != 'status' && key != 'elapsed time' && key != 'timestamp') {
        if (value is List) {
          categories.add(
            SutBbcNewsCategory(
              categoryName: key,
              items: value.map((item) => SutBbcNews.fromJson(item)).toList(),
            ),
          );
        }
      }
    });

    return SutBbcNewsResp(
      status: json['status'],
      categories: categories,
      elapsedTime: json['elapsed time'],
      timestamp: json['timestamp'],
    );
  }
}

class SutBbcNewsCategory {
  final String categoryName;
  final List<SutBbcNews> items;

  SutBbcNewsCategory({required this.categoryName, required this.items});
}

@JsonSerializable(explicitToJson: true)
class SutBbcNews {
  @JsonKey(name: 'title')
  final String? title;
  @JsonKey(name: 'summary')
  final String? summary;
  @JsonKey(name: 'news_link')
  final String? newsLink;
  @JsonKey(name: 'image_link')
  final String? imageLink;

  SutBbcNews({this.title, this.summary, this.newsLink, this.imageLink});

  factory SutBbcNews.fromRawJson(String str) =>
      SutBbcNews.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory SutBbcNews.fromJson(Map<String, dynamic> srcJson) =>
      _$SutBbcNewsFromJson(srcJson);

  Map<String, dynamic> toJson() => _$SutBbcNewsToJson(this);
}
