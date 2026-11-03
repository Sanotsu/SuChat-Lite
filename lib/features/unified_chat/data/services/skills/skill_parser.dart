import 'package:yaml/yaml.dart';

/// Agent Skills 解析结果
/// 2026-09-16 SKILLS P0-3：SKILL.md = YAML frontmatter + Markdown 正文
class SkillParseResult {
  SkillParseResult({
    required this.name,
    required this.description,
    required this.body,
    this.license,
    this.scalarFields = const {},
  });

  /// frontmatter 的 name（已校验合法性）
  final String name;

  /// frontmatter 的 description（可为空，超长已截断）
  final String? description;

  /// frontmatter 之后的 Markdown 正文（保留原始内容，可能为空串）
  final String body;

  /// 可选 license 字段（仅存档展示）
  final String? license;

  /// frontmatter 中其他标量字段（version/metadata 等，仅展示用，不进 DB）
  final Map<String, String> scalarFields;
}

/// 解析失败（携带用户可读的中文原因）
class SkillParseException implements Exception {
  SkillParseException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// SKILL.md 解析器
/// 采用官方 yaml 包完整解析 frontmatter；读取端宽容——嵌套/列表等
/// 非标量值忽略不报错，只取需要的标量字段
class SkillParser {
  SkillParser._();

  /// 标准约定：小写字母数字连字符，≤64 字符，不以连字符开头结尾
  static final RegExp _namePattern = RegExp(r'^[a-z0-9]([a-z0-9-]*[a-z0-9])?$');

  static const int maxNameLength = 64;
  static const int maxDescriptionLength = 1024;

  static bool isValidName(String name) =>
      name.length <= maxNameLength && _namePattern.hasMatch(name);

  /// 解析 SKILL.md 原文。任何失败抛 [SkillParseException]，message 为
  /// 用户可读中文（导入对话框直接展示）
  static SkillParseResult parse(String raw) {
    // BOM 剥离（部分编辑器保存的文件带 BOM）
    var text = raw;
    if (text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
      text = text.substring(1);
    }

    // 1. 首行必须是 --- 围栏（允许行尾 \r）
    final lines = text.split('\n');
    if (lines.isEmpty || lines.first.trimRight() != '---') {
      throw SkillParseException('缺少 YAML frontmatter（文件需以 --- 行开头）');
    }

    // 2. 定位闭合围栏
    var closeIndex = -1;
    for (var i = 1; i < lines.length; i++) {
      if (lines[i].trimRight() == '---') {
        closeIndex = i;
        break;
      }
    }
    if (closeIndex == -1) {
      throw SkillParseException('frontmatter 未闭合（缺少结束的 --- 行）');
    }

    final frontmatterText = lines.sublist(1, closeIndex).join('\n');
    final body = lines.sublist(closeIndex + 1).join('\n').trim();

    // 3. YAML 解析（异常转可读提示）
    dynamic yamlNode;
    try {
      yamlNode = loadYaml(frontmatterText);
    } on YamlException catch (e) {
      throw SkillParseException('frontmatter YAML 格式不正确: ${e.message}');
    }

    if (yamlNode is! YamlMap) {
      throw SkillParseException('frontmatter 必须是键值对形式');
    }

    // 4. 宽容读取：标量转字符串，非标量(列表/映射)忽略
    final scalars = <String, String>{};
    yamlNode.forEach((key, value) {
      if (value == null || key == null) return;
      if (value is YamlList || value is YamlMap) return;
      final v = value.toString().trim();
      if (v.isNotEmpty) scalars[key.toString().trim()] = v;
    });

    // 5. name 必需且需合法
    final name = scalars['name'];
    if (name == null || name.isEmpty) {
      throw SkillParseException('frontmatter 缺少 name 字段');
    }
    if (!isValidName(name)) {
      throw SkillParseException(
        'name "$name" 不合法：仅支持小写字母、数字、连字符，'
        '≤$maxNameLength 字符且不以连字符开头结尾',
      );
    }

    // 6. description 可缺失，超长截断到标准上限
    var description = scalars['description'];
    if (description != null && description.length > maxDescriptionLength) {
      description = description.substring(0, maxDescriptionLength);
    }

    return SkillParseResult(
      name: name,
      description: description,
      body: body,
      license: scalars['license'],
      scalarFields: scalars,
    );
  }
}
