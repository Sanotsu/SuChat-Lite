import 'dart:convert';
import 'package:objectbox/objectbox.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../common/llm_spec/constant_llm_enum.dart';
import 'branch_chat_message.dart';
import 'character_card.dart';

@Entity()
class BranchChatSession {
  @Id()
  int id;

  String title;
  @Property(type: PropertyType.date)
  DateTime createTime;
  @Property(type: PropertyType.date)
  DateTime updateTime;

  // 修改字段名，使其成为普通属性而不是私有属性
  String? llmSpecJson;
  String? modelTypeStr;

  // 角色相关字段
  String? characterId; // 会话使用的角色ID，如果不是角色会话则为null
  String? characterJson; // 序列化后的角色数据，用于存储角色信息

  @Transient() // 标记为非持久化字段
  CusBriefLLMSpec? _llmSpec;

  @Transient() // 标记为非持久化字段
  LLModelType? _modelType;

  @Transient() // 标记为非持久化字段
  CharacterCard? _character; // 运行时角色对象

  // Getter 和 Setter
  CusBriefLLMSpec get llmSpec {
    if (_llmSpec == null && llmSpecJson != null) {
      try {
        _llmSpec = CusBriefLLMSpec.fromJson(jsonDecode(llmSpecJson!));
      } catch (e) {
        rethrow;
      }
    }
    return _llmSpec!;
  }

  set llmSpec(CusBriefLLMSpec value) {
    _llmSpec = value;
    llmSpecJson = jsonEncode(value.toJson());
  }

  LLModelType get modelType {
    if (_modelType == null && modelTypeStr != null) {
      _modelType = LLModelType.values.firstWhere(
        (e) => e.toString() == modelTypeStr,
      );
    }
    return _modelType!;
  }

  set modelType(LLModelType value) {
    _modelType = value;
    modelTypeStr = value.toString();
  }

  // 角色的Getter和Setter
  CharacterCard? get character {
    if (_character == null && characterJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(characterJson!);
        _character = CharacterCard.fromJson(decoded);
      } catch (e) {
        _character = null;
      }
    }
    return _character;
  }

  set character(CharacterCard? value) {
    _character = value;
    characterId = value?.characterId;
    if (value != null) {
      try {
        characterJson = jsonEncode(value.toJson());
      } catch (e) {
        characterJson = null;
      }
    } else {
      characterJson = null;
    }
  }

  @Backlink('session')
  final messages = ToMany<BranchChatMessage>();

  // 添加默认构造函数
  BranchChatSession({
    this.id = 0,
    required this.title,
    required this.createTime,
    required this.updateTime,
    this.llmSpecJson,
    this.modelTypeStr,
    this.characterId,
    this.characterJson,
    CharacterCard? character,
  }) {
    if (character != null) {
      this.character = character;
    }
  }

  // 添加命名构造函数用于创建新会话
  factory BranchChatSession.create({
    required String title,
    required CusBriefLLMSpec llmSpec,
    required LLModelType modelType,
    CharacterCard? character,
    DateTime? createTime,
    DateTime? updateTime,
  }) {
    final session = BranchChatSession(
      title: title,
      createTime: createTime ?? DateTime.now(),
      updateTime: updateTime ?? DateTime.now(),
      character: character,
    );
    session.llmSpec = llmSpec;
    session.modelType = modelType;
    return session;
  }
}
