import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../../shared/constants/constant_llm_enum.dart';

part 'cus_llm_model.g.dart';

///
/// 通用自定义模型规格
///
@JsonSerializable(explicitToJson: true)
class CusLLMSpec {
  // 唯一编号
  String cusLlmSpecId;
  // 模型所在的云平台
  ApiPlatform platform;
  // 模型字符串(平台API参数的那个model的值)、
  String model;
  // 模型类型(cc、vision、audio、tti、iti、ttv……)
  LLModelType modelType;
  // 用于显示的模型名称
  String? name;
  // 是否免费
  bool? isFree;
  // 数据创建的时候(一般排序用)
  DateTime? gmtCreate;
  // 是否是内置模型(内置模型不允许删除)
  bool isBuiltin;

  // 2025-04-11 用户自定义平台模型，直接存入url、model、apikey等关键信息
  String? baseUrl;
  String? apiKey;

  // 2025-04-23 预留一个想随意填写的栏位，供记录其他内容
  String? description;

  CusLLMSpec(
    this.platform,
    this.model,
    this.modelType, {
    this.name,
    this.isFree,
    required this.cusLlmSpecId,
    this.gmtCreate,
    this.isBuiltin = false,
    this.baseUrl,
    this.apiKey,
    this.description,
  });

  // 从字符串转
  factory CusLLMSpec.fromRawJson(String str) =>
      CusLLMSpec.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory CusLLMSpec.fromJson(Map<String, dynamic> srcJson) =>
      _$CusLLMSpecFromJson(srcJson);

  Map<String, dynamic> toJson() => _$CusLLMSpecToJson(this);

  factory CusLLMSpec.fromMap(Map<String, dynamic> map) {
    return CusLLMSpec(
      ApiPlatform.values.firstWhere((e) => e.toString() == map['platform']),
      map['model'],
      LLModelType.values.firstWhere((e) => e.toString() == map['modelType']),
      name: map['name'],
      isFree: map['isFree'] == 1 ? true : false,
      cusLlmSpecId: map['cusLlmSpecId'],
      gmtCreate:
          map['gmtCreate'] != null ? DateTime.parse(map['gmtCreate']) : null,
      isBuiltin: map['isBuiltin'] == 1 ? true : false,
      baseUrl: map['baseUrl'],
      apiKey: map['apiKey'],
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cusLlmSpecId': cusLlmSpecId,
      'platform': platform.toString(),
      'model': model,
      'modelType': modelType.toString(),
      'name': name,
      'isFree': isFree ?? false ? 1 : 0,
      'gmtCreate': gmtCreate?.toIso8601String(),
      'isBuiltin': isBuiltin ? 1 : 0,
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'description': description,
    };
  }

  ///
  /// 2024-08-29
  /// 在 Dart 中，默认的对象比较是基于实例的引用，而不是对象的内容。
  /// 比如在平台和模型下拉框的时候，如果有更新当前选中的平台和模型，会判断是否在预选列表中
  /// 虽然看起来在(比如selectedModelSpec.name相等)，但可能引用不同，
  /// 两个CusLLMSpec实例判等就失败了
  /// 之前没注意是因为平台列表是enum，不存在这个问题
  ///
  ///
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CusLLMSpec &&
          runtimeType == other.runtimeType &&
          cusLlmSpecId == other.cusLlmSpecId &&
          platform == other.platform &&
          model == other.model &&
          modelType == other.modelType &&
          name == other.name &&
          isFree == other.isFree &&
          gmtCreate == other.gmtCreate &&
          isBuiltin == other.isBuiltin &&
          baseUrl == other.baseUrl &&
          apiKey == other.apiKey &&
          description == other.description;

  @override
  int get hashCode =>
      cusLlmSpecId.hashCode ^
      platform.hashCode ^
      model.hashCode ^
      modelType.hashCode ^
      name.hashCode ^
      isFree.hashCode ^
      gmtCreate.hashCode ^
      isBuiltin.hashCode ^
      baseUrl.hashCode ^
      apiKey.hashCode ^
      description.hashCode;
}
