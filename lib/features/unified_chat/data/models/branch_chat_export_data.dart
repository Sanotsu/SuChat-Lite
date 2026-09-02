import 'package:json_annotation/json_annotation.dart';

import '../../../../shared/constants/constant_llm_enum.dart';
import '../../../../core/entities/cus_llm_model.dart';

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
  final CusLLMSpec llmSpec;
  final LLModelType modelType;
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
  final String branchPath;
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
    required this.branchPath,
    this.parentMessageId,
    this.characterId,
  });

  factory BranchChatMessageExport.fromJson(Map<String, dynamic> json) =>
      _$BranchChatMessageExportFromJson(json);

  Map<String, dynamic> toJson() => _$BranchChatMessageExportToJson(this);
}
