import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:objectbox/objectbox.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';

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

  // 新增角色专属背景图片
  String? background;
  // 新增角色专属背景透明度
  double? backgroundOpacity;

  // 可选的额外设置以JSON字符串形式存储
  String? additionalSettingsJson;

  // 非持久化字段，仅用于运行时
  // @Transient() 的作用是避免字段被存储，但 ObjectBox 仍然会检查字段类型并发出警告。
  @Transient()
  List<String>? _tags;

  @Transient()
  CusBriefLLMSpec? _preferredModel;

  @Transient()
  Map<String, dynamic>? _additionalSettings;

  // 获取标签
  List<String> get tags {
    if (_tags == null && tagsJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(tagsJson);
        _tags = decoded.cast<String>();
      } catch (e) {
        if (kDebugMode) {
          print('解析tags失败: $e');
        }
        _tags = [];
      }
    }
    return _tags ?? [];
  }

  // 设置标签
  set tags(List<String> value) {
    _tags = value;
    try {
      tagsJson = jsonEncode(value);
    } catch (e) {
      if (kDebugMode) {
        print('序列化tags失败: $e');
      }
      tagsJson = '[]';
    }
  }

  // 获取偏好模型
  CusBriefLLMSpec? get preferredModel {
    if (_preferredModel == null &&
        preferredModelJson != null &&
        preferredModelJson!.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(preferredModelJson!);
        _preferredModel = CusBriefLLMSpec.fromJson(decoded);
      } catch (e) {
        if (kDebugMode) {
          print('解析preferredModel失败: $e');
        }
        _preferredModel = null;
      }
    }
    return _preferredModel;
  }

  // 设置偏好模型
  set preferredModel(CusBriefLLMSpec? value) {
    _preferredModel = value;
    if (value != null) {
      try {
        preferredModelJson = jsonEncode(value.toJson());
      } catch (e) {
        if (kDebugMode) {
          print('序列化preferredModel失败: $e');
        }
        preferredModelJson = null;
      }
    } else {
      preferredModelJson = null;
    }
  }

  // 获取额外设置
  Map<String, dynamic> get additionalSettings {
    if (_additionalSettings == null &&
        additionalSettingsJson != null &&
        additionalSettingsJson!.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(
          additionalSettingsJson!,
        );
        _additionalSettings = decoded;
      } catch (e) {
        if (kDebugMode) {
          print('解析additionalSettings失败: $e');
        }
        _additionalSettings = {};
      }
    }
    return _additionalSettings ?? {};
  }

  // 设置额外设置
  set additionalSettings(Map<String, dynamic> value) {
    _additionalSettings = value;
    try {
      additionalSettingsJson = jsonEncode(value);
    } catch (e) {
      if (kDebugMode) {
        print('序列化additionalSettings失败: $e');
      }
      additionalSettingsJson = '{}';
    }
  }

  CharacterCard({
    this.id = 0,
    String? characterId,
    required this.name,
    required this.avatar,
    required this.description,
    this.personality = '',
    this.scenario = '',
    this.firstMessage = '',
    this.exampleDialogue = '',
    List<String>? tags,
    CusBriefLLMSpec? preferredModel,
    DateTime? createTime,
    DateTime? updateTime,
    this.isSystem = false,
    this.background,
    this.backgroundOpacity,
    Map<String, dynamic>? additionalSettings,
  }) : characterId = characterId ?? identityHashCode(name).toString(),
       tagsJson = '[]',
       createTime = createTime ?? DateTime.now(),
       updateTime = updateTime ?? DateTime.now(),
       preferredModelJson = null,
       additionalSettingsJson = null {
    // 使用setter来正确处理JSON序列化
    this.tags = tags ?? [];
    this.preferredModel = preferredModel;
    this.additionalSettings = additionalSettings ?? {};
  }

  // 生成系统提示词
  String generateSystemPrompt() {
    final buffer = StringBuffer();

    // 核心角色定义
    buffer.writeln('# 角色定义');
    buffer.writeln('你现在将扮演: $name');
    buffer.writeln('');

    // 详细描述
    buffer.writeln('## 角色背景');
    buffer.writeln(description);
    buffer.writeln('');

    // 性格特点（如果有）
    if (personality.trim().isNotEmpty) {
      buffer.writeln('## 性格特点');
      buffer.writeln(personality);
      buffer.writeln('');
    }

    // 场景设定（如果有）
    if (scenario.trim().isNotEmpty) {
      buffer.writeln('## 场景设定');
      buffer.writeln(scenario);
      buffer.writeln('');
    }

    // 对话示例（如果有）
    if (exampleDialogue.trim().isNotEmpty) {
      buffer.writeln('## 对话示例');
      buffer.writeln(exampleDialogue);
      buffer.writeln('');
    }

    // 角色行为指南
    buffer.writeln('## 行为指南');
    buffer.writeln('1. 始终保持角色一致性，不要破坏角色设定');
    buffer.writeln('2. 使用第一人称回应用户，展现出你的专业知识和个性');
    buffer.writeln('3. 不要提及你是AI、语言模型或程序，完全沉浸在角色中');
    buffer.writeln('4. 根据用户的问题和需求提供相关、有帮助的回应');
    buffer.writeln('5. 如果用户的请求超出你的角色能力范围，可以礼貌地引导话题回到你的专业领域');
    buffer.writeln('6. 保持你的性格特点和说话风格，使回应符合角色形象');
    buffer.writeln('7. 在适当的情况下使用表情、动作描述等增强角色的真实感');

    // 根据角色标签添加特定指导
    _addTagSpecificGuidelines(buffer);

    // 添加角色特定的额外指导
    _addCharacterSpecificGuidelines(buffer);

    return buffer.toString();
  }

  // 根据标签添加特定指导
  void _addTagSpecificGuidelines(StringBuffer buffer) {
    // 工具类角色的特定指导
    if (tags.contains('虚拟') || tags.contains('角色扮演')) {
      buffer.writeln('\n## 角色扮演指导');
      buffer.writeln('- 完全沉浸在角色中，保持一致的语气、用词和行为模式');
      buffer.writeln('- 使用角色特有的表达方式、习惯用语或口头禅');
      buffer.writeln('- 通过描述动作、表情和语气增强互动的沉浸感');
      buffer.writeln('- 根据角色背景做出符合逻辑的反应和决定');
      buffer.writeln('- 在角色知识范围内回应，对未知信息可以创造性地处理');
    }
  }

  // 添加角色特定的额外指导
  void _addCharacterSpecificGuidelines(StringBuffer buffer) {}

  // JSON序列化方法
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'characterId': characterId,
      'name': name,
      'avatar': avatar,
      'description': description,
      'personality': personality,
      'scenario': scenario,
      'firstMessage': firstMessage,
      'exampleDialogue': exampleDialogue,
      'tags': tags,
      'preferredModel': preferredModel?.toJson(),
      'createTime': createTime.toIso8601String(),
      'updateTime': updateTime.toIso8601String(),
      'isSystem': isSystem,
      'background': background,
      'backgroundOpacity': backgroundOpacity,
      'additionalSettings': additionalSettings,
    };
  }

  // 从JSON创建对象 - 主要用于导入导出功能
  factory CharacterCard.fromJson(Map<String, dynamic> json) {
    final card = CharacterCard(
      id: json['id'] != null ? (json['id'] as num).toInt() : 0,
      characterId: json['characterId'] ?? json['id']?.toString(),
      name: json['name'],
      avatar: json['avatar'],
      description: json['description'],
      personality: json['personality'] ?? '',
      scenario: json['scenario'] ?? '',
      firstMessage: json['firstMessage'] ?? '',
      exampleDialogue: json['exampleDialogue'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      preferredModel:
          json['preferredModel'] != null
              ? CusBriefLLMSpec.fromJson(json['preferredModel'])
              : null,
      createTime:
          json['createTime'] != null
              ? DateTime.parse(json['createTime'])
              : null,
      updateTime:
          json['updateTime'] != null
              ? DateTime.parse(json['updateTime'])
              : null,
      isSystem: json['isSystem'] ?? false,
      background: json['background'],
      backgroundOpacity:
          json['backgroundOpacity'] != null
              ? (json['backgroundOpacity'] as num).toDouble()
              : null,
      additionalSettings: json['additionalSettings'] ?? {},
    );
    return card;
  }
}
