// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../storage/cus_get_storage.dart';
import '../storage/db_config.dart';
import '../utils/get_dir.dart';
import '../utils/simple_tools.dart';
import '../../features/unified_chat/data/database/unified_chat_ddl.dart';

/// 0.1.4 → 0.1.5 升级迁移器（一次性，幂等）
///
/// 背景：0.1.5 起核心数据全部移入应用私有区（零权限），
/// 旧版数据根 SuChatFiles 仅在升级时读取迁移：
/// 1. sqlite 两库文件复制到私有区（须在任何数据库打开前执行）
/// 2. 媒体/附件/录音目录整体移动（后台，copy→verify→delete 逐文件可续传）
/// 3. unified 消息/搭档/全局背景中的旧路径前缀重写
/// 4. 旧根改名封存（不删，ObjectBox 残留用于备份中转兜底指引）
///
/// 旧聊天 ObjectBox 数据不在迁移范围（0.1.5 已移除该依赖），
/// 唯一入口 = 0.1.4 全量备份 zip 中转，见方案文档目标 4。
class UpgradeMigrator {
  static const String doneKey = 'upgrade_migration_015_done_at';
  static const String permAskedKey = 'upgrade_migration_015_perm_asked';
  static const String objectBoxFoundKey = 'upgrade_migration_objectbox_found';

  /// 已完成迁移(或确认无旧数据)
  static bool isDone() => CusGetStorage().box.read(doneKey) != null;

  /// 需要迁移的旧根子目录 → 新位置(懒加载函数，桌面端媒体会指向公共目录)
  static final Map<String, Future<Directory> Function()> _dirMappings = {
    'AI_GEN/images': getImageGenDir,
    'AI_GEN/videos': getVideoGenDir,
    'AI_GEN/voices/translator': getTranslatorVoiceGenDir,
    'AI_GEN/voices/omni_chat': getOmniChatVoiceGenDir,
    'AI_GEN/voices': getVoiceGenDir,
    'AI_GEN/unified_chat_media': getUnifiedChatMediaDir,
    'NET_DL': () => getAppPrivateDir(subfolder: 'NET_DL'),
    'FILE_PICK': () => getAppPrivateDir(subfolder: 'FILE_PICK'),
    'VOICE_REC': () => getAppPrivateDir(subfolder: 'VOICE_REC'),
    'BAKUP': () => getAppPrivateDir(subfolder: 'BAKUP'),
    'DB/sqlite_db': getSqliteDbDir,
  };

  /// 入口：探测旧根并执行迁移。
  ///
  /// [quickOnly] = true 时仅执行"必须阻塞启动"的部分（sqlite 复制），
  /// 媒体移动/路径重写作为后台任务返回；false（手动重跑）时全部完成后返回。
  static Future<UpgradeMigrationResult> runIfNeeded({
    bool force = false,
    bool quickOnly = false,
  }) async {
    if (!force && isDone()) {
      return UpgradeMigrationResult._(migrated: false, objectBoxFound: false);
    }

    // ---------- 1. 探测旧根 ----------
    final candidates = await getLegacyHomeCandidatesAsync();
    Directory? legacyRoot;
    for (final dir in candidates) {
      try {
        if (dir.existsSync() && _hasAnyContent(dir)) {
          legacyRoot = dir;
          break;
        }
      } catch (_) {}
    }

    // Android：两个候选都探测不到时，可能是有外部旧数据但无权限读取
    if (legacyRoot == null && Platform.isAndroid) {
      final asked = CusGetStorage().box.read(permAskedKey) == true;
      if (force || !asked) {
        await CusGetStorage().box.write(permAskedKey, true);
        final granted = await requestStoragePermission();
        if (granted) {
          final external = candidates.first;
          try {
            if (external.existsSync() && _hasAnyContent(external)) {
              legacyRoot = external;
            }
          } catch (_) {}
        }
      }
    }

    if (legacyRoot == null) {
      await _markDone();
      return UpgradeMigrationResult._(migrated: false, objectBoxFound: false);
    }

    print('[UpgradeMigrator] 发现旧版数据根: ${legacyRoot.path}');

    // ---------- 2. sqlite 库复制(阻塞，须先于任何 DB 打开) ----------
    final dbFilesCopied = await _copySqliteDbs(legacyRoot);

    // ---------- 3. ObjectBox 残留标记(备份中转引导用) ----------
    var objectBoxFound = false;
    try {
      final obDir = Directory(p.join(legacyRoot.path, 'DB/objectbox'));
      objectBoxFound =
          obDir.existsSync() && obDir.listSync(followLinks: false).isNotEmpty;
    } catch (_) {}
    if (objectBoxFound) {
      await CusGetStorage().box.write(objectBoxFoundKey, true);
    }

    // ---------- 4. 媒体移动 + 路径重写(可后台) ----------
    Future<void> heavyWork() async {
      try {
        await _moveLegacyDirs(legacyRoot!);
        await _rewritePaths(legacyRoot, dbFilesCopied);
        await _rewriteGlobalBackgroundPath(legacyRoot);
        await _sealLegacyRoot(legacyRoot);
        await _markDone();
        print('[UpgradeMigrator] 迁移全部完成');
      } catch (e) {
        print('[UpgradeMigrator] 后台迁移中断(下次启动可续传): $e');
      }
    }

    if (quickOnly) {
      unawaited(heavyWork());
    } else {
      await heavyWork();
    }

    return UpgradeMigrationResult._(
      migrated: true,
      objectBoxFound: objectBoxFound,
    );
  }

  /// 目录下有任意文件/子目录才算有旧数据(避免空壳目录误判)
  static bool _hasAnyContent(Directory dir) {
    try {
      return dir.listSync(followLinks: false).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// 复制主库与 unified 库文件(含 journal/wal/shm)
  /// 目标已存在且比源旧时才覆盖；启动早期 DB 未打开，覆盖安全
  static Future<bool> _copySqliteDbs(Directory legacyRoot) async {
    final srcDir = Directory(p.join(legacyRoot.path, 'DB/sqlite_db'));
    if (!srcDir.existsSync()) return false;

    final targetDir = await getSqliteDbDir();
    var copied = false;

    for (final name in [DBInitConfig.databaseName, DBInitConfig.chatDbName]) {
      for (final suffix in ['', '-journal', '-wal', '-shm']) {
        final src = File(p.join(srcDir.path, '$name$suffix'));
        if (!src.existsSync()) continue;
        // -journal/-wal/-shm 只在主文件存在时才有意义
        final dst = File(p.join(targetDir.path, '$name$suffix'));
        final srcMain = File(p.join(srcDir.path, name));
        final srcHasMain = srcMain.existsSync();
        if (suffix.isNotEmpty && !srcHasMain) continue;

        try {
          if (dst.existsSync()) {
            // 目标已存在：源修改时间更新才覆盖
            if (dst.lastModifiedSync().isAfter(src.lastModifiedSync())) {
              continue;
            }
            dst.deleteSync();
          }
          await src.copy(dst.path);
          copied = true;
          print('[UpgradeMigrator] 已复制数据库文件: $name$suffix');
        } catch (e) {
          print('[UpgradeMigrator] 复制 $name$suffix 失败: $e');
        }
      }
    }
    return copied;
  }

  /// 移动旧根下的媒体/附件/录音/备份目录到新位置
  /// 逐文件 copy→delete，中断后重跑自动续传(目标已存在则跳过)
  static Future<void> _moveLegacyDirs(Directory legacyRoot) async {
    for (final entry in _dirMappings.entries) {
      final src = Directory(p.join(legacyRoot.path, entry.key));
      if (!src.existsSync()) continue;
      final target = await entry.value();
      await _moveDirContents(src, target);
    }

    // AI_GEN 下未知子目录兜底进私有区 AI_GEN/<sub>
    final aiGen = Directory(p.join(legacyRoot.path, 'AI_GEN'));
    if (aiGen.existsSync()) {
      for (final sub in aiGen.listSync(followLinks: false)) {
        if (sub is Directory) {
          final known = _dirMappings.keys.any(
            (k) => k == 'AI_GEN/${p.basename(sub.path)}',
          );
          if (!known) {
            await _moveDirContents(
              sub,
              await getAppPrivateDir(
                subfolder: 'AI_GEN/${p.basename(sub.path)}',
              ),
            );
          }
        }
      }
    }
  }

  static Future<void> _moveDirContents(Directory src, Directory target) async {
    try {
      if (!target.existsSync()) {
        target.createSync(recursive: true);
      }
      final entities = src.listSync(followLinks: false);
      var moved = 0;
      for (final entity in entities) {
        if (entity is File) {
          final dst = File(p.join(target.path, p.basename(entity.path)));
          if (!dst.existsSync()) {
            await entity.copy(dst.path);
          }
          // 校验大小一致后才删除源，保证可续传
          if (dst.existsSync() && dst.lengthSync() == entity.lengthSync()) {
            entity.deleteSync();
            moved++;
          }
        } else if (entity is Directory) {
          await _moveDirContents(
            entity,
            Directory(p.join(target.path, p.basename(entity.path))),
          );
        }
      }
      // 目录空了才移除源目录本身
      try {
        if (src.listSync(followLinks: false).isEmpty) {
          src.deleteSync();
        }
      } catch (_) {}
      if (moved > 0) {
        print('[UpgradeMigrator] 已移动 ${src.path} → ${target.path} ($moved 文件)');
      }
    } catch (e) {
      print('[UpgradeMigrator] 移动目录失败 ${src.path}: $e');
    }
  }

  /// 重写 unified 库消息/搭档中的旧路径前缀
  /// [dbFilesCopied] = false 时(库未迁移)消息本来就不在新库，跳过
  static Future<void> _rewritePaths(
    Directory legacyRoot,
    bool dbFilesCopied,
  ) async {
    if (!dbFilesCopied) return;
    final dbDir = await getSqliteDbDir();
    final dbPath = p.join(dbDir.path, DBInitConfig.chatDbName);
    if (!File(dbPath).existsSync()) return;

    // 源前缀 → 目标前缀(长路径优先，避免子目录被父目录替换截断)
    final pairs = <MapEntry<String, String>>[];
    for (final entry in _dirMappings.entries) {
      // sqlite_db 自身无需重写
      if (entry.key == 'DB/sqlite_db') continue;
      final srcPrefix = p.join(legacyRoot.path, entry.key);
      final target = await entry.value();
      pairs.add(MapEntry(srcPrefix, target.path));
    }
    // 兜底：旧根其他任意子路径 → 私有区根
    final privateRoot = await getAppPrivateDir();
    pairs.add(MapEntry(legacyRoot.path, privateRoot.path));
    pairs.sort((a, b) => b.key.length.compareTo(a.key.length));

    Database? db;
    try {
      db = await openDatabase(dbPath);
      for (final pair in pairs) {
        for (final tableCols in [
          (
            UnifiedChatDdl.tableUnifiedChatMessage,
            ['content', 'multimodal_content', 'metadata'],
          ),
          (
            UnifiedChatDdl.tableUnifiedChatPartner,
            ['avatar_url', 'background'],
          ),
        ]) {
          for (final col in tableCols.$2) {
            final n = await db.rawUpdate(
              "UPDATE ${tableCols.$1} SET $col = REPLACE($col, ?, ?) "
              "WHERE $col IS NOT NULL AND instr($col, ?) > 0",
              [pair.key, pair.value, pair.key],
            );
            if (n > 0) {
              print(
                '[UpgradeMigrator] 路径重写 ${tableCols.$1}.$col: $n 行 '
                '(${pair.key} → ${pair.value})',
              );
            }
          }
        }
      }
    } catch (e) {
      print('[UpgradeMigrator] 路径重写失败: $e');
    } finally {
      await db?.close();
    }
  }

  /// 全局聊天背景图路径重写(GetStorage)
  static Future<void> _rewriteGlobalBackgroundPath(Directory legacyRoot) async {
    try {
      final box = CusGetStorage().box;
      final bg = box.read('chat_background');
      if (bg is String && bg.contains(legacyRoot.path)) {
        final privateRoot = await getAppPrivateDir();
        await box.write(
          'chat_background',
          bg.replaceAll(legacyRoot.path, privateRoot.path),
        );
      }
    } catch (_) {}
  }

  /// 旧根改名封存(不删；ObjectBox 残留供"降级 0.1.4 补备份"兜底)
  static Future<void> _sealLegacyRoot(Directory legacyRoot) async {
    try {
      // 仍被占用的文件(如迁移中断)会导致改名失败，静默忽略下次续传
      if (legacyRoot.existsSync() &&
          legacyRoot.listSync(followLinks: false).isEmpty) {
        legacyRoot.deleteSync();
        return;
      }
      final sealed = Directory('${legacyRoot.path}_migrated_0.1.5');
      if (!sealed.existsSync()) {
        legacyRoot.renameSync(sealed.path);
      } else {
        // 封存目录已存在(极端)：把剩余内容并入后删除源
        await _moveDirContents(legacyRoot, sealed);
        if (legacyRoot.listSync(followLinks: false).isEmpty) {
          legacyRoot.deleteSync();
        }
      }
    } catch (e) {
      print('[UpgradeMigrator] 旧根封存跳过(可能被占用): $e');
    }
  }

  static Future<void> _markDone() async {
    await CusGetStorage().box.write(
      doneKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}

class UpgradeMigrationResult {
  /// 是否实际执行了迁移(发现旧数据)
  final bool migrated;

  /// 旧根是否残留 ObjectBox 数据(需要备份中转引导)
  final bool objectBoxFound;

  const UpgradeMigrationResult._({
    required this.migrated,
    required this.objectBoxFound,
  });
}
