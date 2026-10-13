// 旧版(0.1.4)分支聊天 ObjectBox 实体——仅供 UpgradeMigrator 读取
// 旧库数据直接升级迁移用，业务代码禁止使用。
//
// 2026-10-12 最小集成移植自 dc9a93d(0.1.4-beta.1)：
// - 持久化字段/关系/命名与0.1.4完全一致(schema uid 匹配旧库)
// - 剥离了@Transient运行时字段及其getter/setter(引用已退役的
//   CusLLMSpec/LLModelType/CharacterCard)——Transient不进model
//   schema，删除不影响uid；迁移器自行解析llmSpecJson等原始字符串
// - 版本冻结：此文件不再演进，仅当旧库schema变更需要时才同步
import 'package:objectbox/objectbox.dart';

import 'branch_chat_message.dart';

@Entity()
class BranchChatSession {
  @Id()
  int id;

  String title;
  @Property(type: PropertyType.date)
  DateTime createTime;
  @Property(type: PropertyType.date)
  DateTime updateTime;

  // 旧LLM规格的原始JSON串(迁移器jsonDecode后转BranchChatSessionExport)
  String? llmSpecJson;
  String? modelTypeStr;

  // 角色相关字段
  String? characterId; // 会话使用的角色ID，如果不是角色会话则为null
  String? characterJson; // 序列化后的角色数据，用于存储角色信息

  @Backlink('session')
  final messages = ToMany<BranchChatMessage>();

  BranchChatSession({
    this.id = 0,
    required this.title,
    required this.createTime,
    required this.updateTime,
    this.llmSpecJson,
    this.modelTypeStr,
    this.characterId,
    this.characterJson,
  });
}
