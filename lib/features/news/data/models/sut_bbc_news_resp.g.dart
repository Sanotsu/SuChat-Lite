// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sut_bbc_news_resp.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SutBbcNews _$SutBbcNewsFromJson(Map<String, dynamic> json) => SutBbcNews(
  title: json['title'] as String?,
  summary: json['summary'] as String?,
  newsLink: json['news_link'] as String?,
  imageLink: json['image_link'] as String?,
);

Map<String, dynamic> _$SutBbcNewsToJson(SutBbcNews instance) =>
    <String, dynamic>{
      'title': instance.title,
      'summary': instance.summary,
      'news_link': instance.newsLink,
      'image_link': instance.imageLink,
    };
