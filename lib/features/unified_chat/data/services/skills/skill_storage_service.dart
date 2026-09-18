import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../../../../../core/utils/get_dir.dart';
import '../../../../../core/utils/simple_tools.dart';
import '../../database/unified_chat_db_init.dart';
import '../../database/unified_chat_ddl.dart';
import '../../models/skill_models.dart';
import 'skill_parser.dart';

/// 导入失败（用户可读原因，UI 直接展示）
class SkillImportException implements Exception {
  SkillImportException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Agent Skills 存储服务（P0-2）
/// 职责：技能目录管理 + 导入（目录/zip）+ 删除 + DB 元数据 CRUD。
/// 单例，对齐 McpServerConfigService 的形态。
class SkillStorageService {
  // 单例
  static final SkillStorageService _instance = SkillStorageService._internal();
  factory SkillStorageService() => _instance;
  SkillStorageService._internal();

  final _dbInit = UnifiedChatDBInit();

  /// 限额：附属文件数与总体积（PLAN 4.2）。
  /// 2026-09-16 用户实测放宽：anthropics/skills 官方技能(pptx等)自带
  /// 几十个脚本/模板文件，原20个/2MB过紧导致官方技能装不上——
  /// 附属文件只是"存在"不进上下文(读取走read_skill分页)，放宽到
  /// 200个/16MB；read_skill 的 16000 分页仍是 token 防线
  static const int maxAuxFiles = 200;
  static const int maxTotalSize = 16 * 1024 * 1024;

  // =========================================================================
  // DB CRUD
  // =========================================================================

  /// 全部技能（按创建时间排序）
  Future<List<SkillMeta>> getAllSkills() async {
    final db = await _dbInit.database;
    final maps = await db.query(
      UnifiedChatDdl.tableUnifiedSkill,
      orderBy: 'created_at ASC',
    );
    return maps.map(SkillMeta.fromMap).toList();
  }

  /// 启用的技能（Level 1 注入数据源）
  Future<List<SkillMeta>> getEnabledSkills() async {
    final all = await getAllSkills();
    return all.where((s) => s.enabled).toList();
  }

  Future<SkillMeta?> getSkill(String name) async {
    final db = await _dbInit.database;
    final maps = await db.query(
      UnifiedChatDdl.tableUnifiedSkill,
      where: 'id = ?',
      whereArgs: [name],
      limit: 1,
    );
    return maps.isEmpty ? null : SkillMeta.fromMap(maps.first);
  }

  /// 启用/停用
  Future<void> setEnabled(String name, bool enabled) async {
    final db = await _dbInit.database;
    await db.update(
      UnifiedChatDdl.tableUnifiedSkill,
      {'enabled': enabled ? 1 : 0, 'updated_at': _now()},
      where: 'id = ?',
      whereArgs: [name],
    );
  }

  /// 删除技能（DB 行 + 磁盘目录）
  Future<void> deleteSkill(String name) async {
    final existing = await getSkill(name);
    final db = await _dbInit.database;
    await db.delete(
      UnifiedChatDdl.tableUnifiedSkill,
      where: 'id = ?',
      whereArgs: [name],
    );
    if (existing != null) {
      final dir = Directory(existing.dirPath);
      if (dir.existsSync()) {
        try {
          await dir.delete(recursive: true);
        } catch (e) {
          pl.w('技能目录删除失败(已移除DB记录): $e');
        }
      }
    }
  }

  Future<void> _upsertMeta(SkillMeta meta) async {
    final db = await _dbInit.database;
    await db.insert(
      UnifiedChatDdl.tableUnifiedSkill,
      meta.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  int _now() => DateTime.now().millisecondsSinceEpoch;

  // =========================================================================
  // 导入（目录 / zip）
  // =========================================================================

  /// 从技能目录导入（目录内直接含 SKILL.md 与附属文件）
  /// [source] 来源标记（import / github:owner/repo）；[sourceUrl] 来源地址。
  /// 已存在同名技能时覆盖（更新元数据与文件，来源以最后导入为准）。
  Future<SkillMeta> importFromDirectory(
    Directory skillDir, {
    String source = 'import',
    String? sourceUrl,
  }) async {
    final skillFile = File(p.join(skillDir.path, 'SKILL.md'));
    if (!skillFile.existsSync()) {
      throw SkillImportException('目录中未找到 SKILL.md');
    }

    final parsed = SkillParser.parse(skillFile.readAsStringSync());

    // 附属文件扫描（SKILL.md 之外的一切文件，不计空子目录）
    final auxFiles = <File>[];
    await for (final entity in skillDir.list(recursive: true)) {
      if (entity is File && p.basename(entity.path) != 'SKILL.md') {
        auxFiles.add(entity);
      }
    }
    if (auxFiles.length > maxAuxFiles) {
      throw SkillImportException(
        '附属文件过多(${auxFiles.length}个)，上限 $maxAuxFiles 个',
      );
    }
    var totalSize = skillFile.lengthSync();
    for (final f in auxFiles) {
      totalSize += f.lengthSync();
    }
    if (totalSize > maxTotalSize) {
      throw SkillImportException(
        '技能总体积 ${(totalSize / 1024 / 1024).toStringAsFixed(1)}MB，'
        '上限 ${(maxTotalSize / 1024 / 1024).toStringAsFixed(0)}MB',
      );
    }

    // 复制入存储目录（先删旧目录保证覆盖语义干净）
    final skillsRoot = await getSkillsDir();
    final targetDir = Directory(p.join(skillsRoot.path, parsed.name));
    if (targetDir.existsSync()) {
      await targetDir.delete(recursive: true);
    }
    await _copyDirectory(skillDir, targetDir);

    // 覆盖语义：沿用已有条目的创建时间
    final existing = await getSkill(parsed.name);
    final now = _now();
    final meta = SkillMeta(
      id: parsed.name,
      name: parsed.name,
      description: parsed.description,
      source: source,
      sourceUrl: sourceUrl,
      enabled: existing?.enabled ?? true,
      dirPath: targetDir.path,
      auxCount: auxFiles.length,
      fileSize: totalSize,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await _upsertMeta(meta);
    return meta;
  }

  /// 从 zip 包导入：解压到临时目录后定位 SKILL.md 所在目录
  /// （兼容 zip 根直接含 SKILL.md 与 `{repo}-{branch}/` 一级壳两种形态）
  Future<SkillMeta> importFromZip(File zipFile) async {
    final Archive archive;
    try {
      final bytes = zipFile.readAsBytesSync();
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      throw SkillImportException('zip 包解压失败: $e');
    }

    final tempDir = await Directory.systemTemp.createTemp('skill_import_');
    try {
      for (final file in archive) {
        if (file.isFile) {
          // zip 条目路径安全防护：拒绝绝对路径与路径穿越
          final entryPath = file.name.replaceAll('\\', '/');
          if (p.isAbsolute(entryPath) || entryPath.split('/').contains('..')) {
            throw SkillImportException('zip 包内含不安全路径: $entryPath');
          }
          final target = File(p.join(tempDir.path, entryPath));
          await target.create(recursive: true);
          await target.writeAsBytes(file.content as List<int>);
        }
      }

      // 定位 SKILL.md（浅层优先）
      final skillFiles = <File>[];
      await for (final entity in tempDir.list(recursive: true)) {
        if (entity is File && p.basename(entity.path) == 'SKILL.md') {
          skillFiles.add(entity);
        }
      }
      if (skillFiles.isEmpty) {
        throw SkillImportException('zip 包中未找到 SKILL.md');
      }
      if (skillFiles.length > 1) {
        throw SkillImportException(
          'zip 包中发现 ${skillFiles.length} 个 SKILL.md，'
          '多技能仓库请在 GitHub 安装功能中选择安装(P2)',
        );
      }

      return await importFromDirectory(skillFiles.first.parent);
    } finally {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    }
  }

  Future<void> _copyDirectory(Directory src, Directory dst) async {
    await dst.create(recursive: true);
    await for (final entity in src.list(recursive: true)) {
      final rel = p.relative(entity.path, from: src.path);
      final targetPath = p.join(dst.path, rel);
      if (entity is Directory) {
        await Directory(targetPath).create(recursive: true);
      } else if (entity is File) {
        await File(targetPath).parent.create(recursive: true);
        await entity.copy(targetPath);
      }
    }
  }

  // =========================================================================
  // 读取（P1 read_skill 数据源）
  // =========================================================================

  /// 读取 SKILL.md 全文
  Future<String> readSkillMarkdown(String name) async {
    final meta = await getSkill(name);
    if (meta == null) throw SkillImportException('技能 "$name" 不存在');
    final file = File(p.join(meta.dirPath, 'SKILL.md'));
    if (!file.existsSync()) {
      throw SkillImportException('技能 "$name" 的 SKILL.md 文件缺失(目录可能被手动删除)');
    }
    return file.readAsString();
  }

  /// 读取附属文件（相对路径，锁定在技能目录内防路径穿越）
  Future<String> readAuxFile(String name, String relativePath) async {
    final meta = await getSkill(name);
    if (meta == null) throw SkillImportException('技能 "$name" 不存在');

    final normalized = relativePath.replaceAll('\\', '/');
    if (p.isAbsolute(normalized) || normalized.split('/').contains('..')) {
      throw SkillImportException('非法路径: $relativePath');
    }

    final skillRoot = p.canonicalize(meta.dirPath);
    final target = p.canonicalize(p.join(skillRoot, normalized));
    if (!p.isWithin(skillRoot, target)) {
      throw SkillImportException('非法路径: $relativePath');
    }

    final file = File(target);
    if (!file.existsSync()) {
      throw SkillImportException('附属文件不存在: $relativePath');
    }
    return file.readAsString();
  }

  /// 列出附属文件（相对路径，排除 SKILL.md）
  Future<List<String>> listAuxFiles(String name) async {
    final meta = await getSkill(name);
    if (meta == null) return const [];
    final dir = Directory(meta.dirPath);
    if (!dir.existsSync()) return const [];

    final out = <String>[];
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final rel = p.relative(entity.path, from: dir.path);
        if (p.basename(entity.path) != 'SKILL.md') out.add(rel);
      }
    }
    out.sort();
    return out;
  }
}
