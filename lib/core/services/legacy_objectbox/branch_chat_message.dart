// 旧版(0.1.4)分支聊天 ObjectBox 实体——仅供 UpgradeMigrator 读取
// 旧库数据直接升级迁移用，业务代码禁止使用。
// 移植说明见 branch_chat_session.dart 头注释(与0.1.4 schema一致，
// @Transient运行时字段已剥离)。
import 'dart:convert';

import 'package:objectbox/objectbox.dart';

import 'branch_chat_session.dart';

@Entity()
class BranchChatMessage {
  @Id(assignable: true)
  int id;

  String messageId;
  String role;
  String content;
  @Property(type: PropertyType.date)
  DateTime createTime;

  // 角色相关字段
  String? characterId; // 角色ID，如果不是角色消息则为null
  String? characterJson; // 序列化后的角色数据，用于存储角色信息

  // 可选字段
  String? reasoningContent;
  int? thinkingDuration;
  // 用户语音输入时，语音转文字的原始音频
  String? contentVoicePath;
  String? imagesUrl;
  String? videosUrl;
  // 用户输入时选择的音频文件/大模型响应生成的音频
  String? audiosUrl;
  // 多模态合成语音的音色
  String? omniAudioVoice;

  // 联网搜索参考内容(序列化JSON串；迁移器自行jsonDecode)
  String? referencesJson;

  int? promptTokens;
  int? completionTokens;
  int? totalTokens;
  String? modelLabel;

  // 树形结构关系
  @Backlink('parent')
  final children = ToMany<BranchChatMessage>();

  final parent = ToOne<BranchChatMessage>();
  final session = ToOne<BranchChatSession>();

  // 分支相关
  int branchIndex; // 当前分支在同级分支中的索引
  int depth; // 分支深度，根节点为0
  String branchPath; // 从根到当前节点的分支路径，如 "0/1/0"

  BranchChatMessage({
    this.id = 0,
    required this.messageId,
    required this.role,
    required this.content,
    required this.createTime,
    this.branchIndex = 0,
    this.depth = 0,
    this.branchPath = "0",
    this.reasoningContent,
    this.thinkingDuration,
    this.contentVoicePath,
    this.imagesUrl,
    this.videosUrl,
    this.audiosUrl,
    this.omniAudioVoice,
    this.referencesJson,
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
    this.modelLabel,
    this.characterId,
    this.characterJson,
  });

  /// referencesJson的便捷解码(迁移转换用)
  List<Map<String, dynamic>>? decodeReferences() {
    if (referencesJson == null) return null;
    try {
      final decoded = jsonDecode(referencesJson!) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }
}
