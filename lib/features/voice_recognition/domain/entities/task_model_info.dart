import 'dart:convert';

/// 录音识别任务使用的模型信息（轻量记录）
/// 2026-09-07 旧 LLM 体系(CusLLMSpec)退役：DashScope 录音文件识别只关心
/// 模型名与描述，任务表 llmSpec 列继续存 JSON（本类的 toJson 结构）；
/// 解析时兼容旧 CusLLMSpec JSON 结构（model/description 字段同名直取）
class TaskModelInfo {
  /// 提交给 DashScope 的模型名
  final String model;

  /// 展示用描述
  final String? description;

  const TaskModelInfo({required this.model, this.description});

  factory TaskModelInfo.fromJson(Map<String, dynamic> json) {
    return TaskModelInfo(
      model: json['model'] as String? ?? '',
      description: json['description'] as String?,
    );
  }

  factory TaskModelInfo.fromRawJson(String str) =>
      TaskModelInfo.fromJson(jsonDecode(str) as Map<String, dynamic>);

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      if (description != null) 'description': description,
    };
  }

  String toRawJson() => jsonEncode(toJson());
}
