// 旧版(0.1.4)角色卡 ObjectBox 实体——仅供 UpgradeMigrator 读取旧库，
// 业务代码禁止使用。此实体必须保留：旧库 data.mdb 中存在该实体 Box，
// model缺少会导致打开旧库schema校验失败。移植说明见
// branch_chat_session.dart 头注释(与0.1.4 schema一致，@Transient剥离)。
import 'package:objectbox/objectbox.dart';

@Entity()
class CharacterCard {
  @Id(assignable: true)
  int id;

  String characterId;
  String name;
  String avatar;
  String description;
  String personality;
  String scenario;
  String firstMessage;
  String exampleDialogue;

  // 标签以JSON字符串形式存储
  String tagsJson;

  // 角色偏好的模型，序列化为JSON字符串存储
  String? preferredModelJson;

  @Property(type: PropertyType.date)
  DateTime createTime;
  @Property(type: PropertyType.date)
  DateTime updateTime;
  bool isSystem; // 是否是系统预设角色

  // 角色专属背景图片
  String? background;
  // 角色专属背景透明度
  double? backgroundOpacity;

  // 可选的额外设置以JSON字符串形式存储
  String? additionalSettingsJson;

  // 0.1.4的generator把tags getter生成为持久化属性(type 30)——
  // 必须保留同型字段否则打开旧库schema校验失败；迁移器不读写它
  List<String>? tags;

  CharacterCard({
    this.id = 0,
    required this.characterId,
    required this.name,
    this.avatar = '',
    this.description = '',
    this.personality = '',
    this.scenario = '',
    this.firstMessage = '',
    this.exampleDialogue = '',
    this.tagsJson = '[]',
    this.preferredModelJson,
    required this.createTime,
    required this.updateTime,
    this.isSystem = false,
    this.background,
    this.backgroundOpacity,
    this.additionalSettingsJson,
  });
}
