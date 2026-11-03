/// Agent Skills 元数据模型（对应 DB 表 unified_skill）
/// 2026-09-16 SKILLS P0-1：技能本体(SKILL.md+附属文件)存应用支持目录，
/// DB 只存元数据与索引；id 即 frontmatter name（name 已唯一，不设 uuid）
class SkillMeta {
  SkillMeta({
    required this.id,
    required this.name,
    this.description,
    this.source = 'import',
    this.sourceUrl,
    this.enabled = true,
    required this.dirPath,
    this.auxCount = 0,
    this.fileSize = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 即 frontmatter name（主键与唯一名合一）
  final String id;

  /// frontmatter name（已由解析器校验合法性）
  final String name;

  /// frontmatter description（可为空）
  final String? description;

  /// 来源：`import`(本地导入) / `github:owner/repo` / `local`(应用内置预留)
  final String source;

  /// 来源地址（GitHub 仓库 URL 等，可空）
  final String? sourceUrl;

  /// 全局启用开关（Level 1 注入条件之一）
  final bool enabled;

  /// 技能目录绝对路径（含 SKILL.md 与附属文件）
  final String dirPath;

  /// 附属文件数（不含 SKILL.md）
  final int auxCount;

  /// SKILL.md + 附属文件总字节数
  final int fileSize;

  final int createdAt;
  final int updatedAt;

  factory SkillMeta.fromMap(Map<String, dynamic> map) {
    return SkillMeta(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      source: (map['source'] as String?) ?? 'import',
      sourceUrl: map['source_url'] as String?,
      enabled: (map['enabled'] as int? ?? 1) == 1,
      dirPath: map['dir_path'] as String,
      auxCount: map['aux_count'] as int? ?? 0,
      fileSize: map['file_size'] as int? ?? 0,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'source': source,
      'source_url': sourceUrl,
      'enabled': enabled ? 1 : 0,
      'dir_path': dirPath,
      'aux_count': auxCount,
      'file_size': fileSize,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  SkillMeta copyWith({
    String? description,
    String? source,
    String? sourceUrl,
    bool? enabled,
    String? dirPath,
    int? auxCount,
    int? fileSize,
    int? updatedAt,
  }) {
    return SkillMeta(
      id: id,
      name: name,
      description: description ?? this.description,
      source: source ?? this.source,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      enabled: enabled ?? this.enabled,
      dirPath: dirPath ?? this.dirPath,
      auxCount: auxCount ?? this.auxCount,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
