import 'package:json_annotation/json_annotation.dart';

part 'branch_chat_export_data.g.dart';

@JsonSerializable(explicitToJson: true)
class BranchChatExportData {
  final List<BranchChatSessionExport> sessions;

  BranchChatExportData({required this.sessions});

  factory BranchChatExportData.fromJson(Map<String, dynamic> json) =>
      _$BranchChatExportDataFromJson(json);

  Map<String, dynamic> toJson() => _$BranchChatExportDataToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BranchChatSessionExport {
  final int id;
  final String title;
  final DateTime createTime;
  final DateTime updateTime;
  // 2026-09-07 旧LLM体系(CusLLMSpec)退役：旧备份中的模型规格保留原始JSON，
  // 由导入器按需轻量解析(platform/model/modelType/name/baseUrl/apiKey)
  final Map<String, dynamic> llmSpec;
  // 旧LLModelType枚举名字符串(如 cc/reasoner/vision/tti...)
  final String modelType;
  final List<BranchChatMessageExport> messages;
  final String? characterId;

  BranchChatSessionExport({
    required this.id,
    required this.title,
    required this.createTime,
    required this.updateTime,
    required this.llmSpec,
    required this.modelType,
    required this.messages,
    this.characterId,
  });

  factory BranchChatSessionExport.fromJson(Map<String, dynamic> json) =>
      _$BranchChatSessionExportFromJson(json);

  Map<String, dynamic> toJson() => _$BranchChatSessionExportToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BranchChatMessageExport {
  final String messageId;
  final String role;
  final String content;
  final DateTime createTime;
  final String? reasoningContent;
  final int? thinkingDuration;
  final String? contentVoicePath;
  final String? imagesUrl;
  final String? videosUrl;
  final String? audiosUrl;
  final String? omniAudioVoice;
  final List<Map<String, dynamic>>? references;
  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;
  final String? modelLabel;
  final int branchIndex;
  final int depth;
  // 2026-09-18 FIX：0.1.4备份的消息json无branchPath字段(它是旧版运行时
  // 计算值，不落ObjectBox不导出)——非空required使fromJson的null as
  // String直接崩掉整个备份导入(恢复0会话)。改可空，导入后由
  // backfillBranchColumnsForRestore按单链重建分支字段
  final String? branchPath;
  final String? parentMessageId;
  final String? characterId;

  BranchChatMessageExport({
    required this.messageId,
    required this.role,
    required this.content,
    required this.createTime,
    this.reasoningContent,
    this.thinkingDuration,
    this.contentVoicePath,
    this.imagesUrl,
    this.videosUrl,
    this.audiosUrl,
    this.omniAudioVoice,
    this.references,
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
    this.modelLabel,
    required this.branchIndex,
    required this.depth,
    this.branchPath,
    this.parentMessageId,
    this.characterId,
  });

  factory BranchChatMessageExport.fromJson(Map<String, dynamic> json) =>
      _$BranchChatMessageExportFromJson(json);

  Map<String, dynamic> toJson() => _$BranchChatMessageExportToJson(this);
}
