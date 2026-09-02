// ignore_for_file: avoid_print, constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/storage/cus_get_storage.dart';
import '../../../core/storage/db_config.dart';
import '../../../core/storage/db_init.dart';
import '../../../core/utils/get_dir.dart';
import '../../unified_chat/data/database/unified_chat_db_init.dart';
import '../../unified_chat/data/database/unified_chat_ddl.dart';

// 全量备份导出的文件的前缀(_时间戳.zip)
const String ZIP_FILE_PREFIX = 'SuChat全量数据备份_';
// 大媒体独立包前缀
const String MEDIA_PACK_PREFIX = 'SuChat媒体文件包_';
// 旧版(0.1.4)备份包中的角色/聊天json文件名(恢复兼容用)
const String CHARACTER_CARD_LIST_FILE_NAME = 'suchat_character_card_list.json';
const String BRANCH_CHAT_HISTORY_FILE_NAME = 'suchat_branch_chat_history.json';
// 备份清单与外观设置文件名
const String MANIFEST_FILE_NAME = 'backup_manifest.json';
const String APPEARANCE_FILE_NAME = 'appearance_settings.json';
// zip内媒体文件目录
const String FILES_DIR_IN_ZIP = 'files';
const String ZIP_TEMP_DIR_AT_UNZIP = 'temp_de_zip';
const String ZIP_TEMP_DIR_AT_RESTORE = 'temp_auto_zip';

// 媒体分级阈值：单文件 ≤10MB 且总量 ≤500MB 进数据包，其余进媒体包
const int kSmallMediaThresholdBytes = 10 * 1024 * 1024;
const int kSmallMediaQuotaBytes = 500 * 1024 * 1024;

// 外观设置(与旧版共用的存储key)
const List<String> kAppearanceKeys = [
  'chat_list_area_scale',
  'chat_background',
  'chat_background_opacity',
  'message_font_color',
  'unified_chat_brief_display',
  'branch_chat_history_panel_bg_color',
];

/// 备份构建结果
class BackupBuildResult {
  final String zipPath;
  final int includedCount;
  final int includedBytes;
  final int excludedCount;
  final int excludedBytes;

  const BackupBuildResult({
    required this.zipPath,
    this.includedCount = 0,
    this.includedBytes = 0,
    this.excludedCount = 0,
    this.excludedBytes = 0,
  });
}

/// 媒体引用扫描结果
class MediaScanResult {
  /// 小媒体(入数据包)：File + zip内相对路径
  final List<MapEntry<File, String>> small;

  /// 大媒体(媒体包)：File + zip内相对路径
  final List<MapEntry<File, String>> large;

  const MediaScanResult({required this.small, required this.large});

  int get smallBytes => small.fold(0, (s, e) => s + e.key.lengthSync());
  int get largeBytes => large.fold(0, (s, e) => s + e.key.lengthSync());
}

/// 备份工具(2026-09-01 从 backup_and_restore_page 提取；
/// 2026-09-01 0.1.5 改版重写：流式zip、媒体分级双包、外观设置入包、
/// 移除旧版 ObjectBox 导出——旧聊天数据统一经备份zip中转转换)
class BackupUtils {
  /// 构建全量(数据)备份包：流式写入 [zipPath]，内存占用 O(1)
  ///
  /// 包结构：
  ///   `主库各表.json / unified各表.json`
  ///   appearance_settings.json   外观设置(背景图base64内嵌)
  ///   backup_manifest.json       清单(备份机私有区根/媒体统计/排除清单)
  ///   files/...                  小媒体文件(消息引用的图片/语音等)
  static Future<BackupBuildResult> buildDataPack({
    required String zipPath,
    bool includeMedia = true,
    void Function(String stage)? onStage,
  }) async {
    // ---------- 1. 数据json ----------
    onStage?.call('正在导出主库数据...');
    await DBInit().exportDatabase();

    final cacheDir = await getApplicationCacheDirectory();
    final exportDir = Directory(p.join(cacheDir.path, DBInitConfig.exportDir));
    if (!exportDir.existsSync()) exportDir.createSync(recursive: true);

    onStage?.call('正在导出新版聊天数据...');
    await UnifiedChatDBInit().exportDatabase(targetDir: exportDir);

    onStage?.call('正在收集外观设置...');
    await _exportAppearance(exportDir);

    // ---------- 2. 媒体收集 ----------
    MediaScanResult scan;
    if (includeMedia) {
      onStage?.call('正在扫描消息引用的媒体文件...');
      scan = await scanMediaReferences();
    } else {
      scan = const MediaScanResult(small: [], large: []);
    }

    // 配额截断：超出后按最后修改时间保留较新的
    var included = scan.small;
    var quotaCut = 0;
    if (scan.smallBytes > kSmallMediaQuotaBytes) {
      final sorted = [...scan.small]
        ..sort(
          (a, b) =>
              b.key.lastModifiedSync().compareTo(a.key.lastModifiedSync()),
        );
      var acc = 0;
      final kept = <MapEntry<File, String>>[];
      for (final e in sorted) {
        acc += e.key.lengthSync();
        if (acc > kSmallMediaQuotaBytes) break;
        kept.add(e);
      }
      quotaCut = scan.small.length - kept.length;
      included = kept;
    }

    // ---------- 3. 清单 ----------
    onStage?.call('正在写入备份清单...');
    final privateRoot = await getAppPrivateDir();
    final manifest = <String, dynamic>{
      'version': '0.1.5',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'privateRoot': privateRoot.path,
      'media': {
        'includedCount': included.length,
        'includedBytes': included.fold(0, (s, e) => s + e.key.lengthSync()),
        'quotaCut': quotaCut,
        'excludedCount': scan.large.length,
        'excludedBytes': scan.largeBytes,
        'excluded': scan.large
            .map((e) => {'path': e.value, 'bytes': e.key.lengthSync()})
            .toList(),
      },
    };
    File(
      p.join(exportDir.path, MANIFEST_FILE_NAME),
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(manifest));

    // ---------- 4. 流式打包 ----------
    onStage?.call('正在压缩打包...');
    final encoder = ZipFileEncoder();
    encoder.create(zipPath);
    try {
      for (final entity in exportDir.listSync(followLinks: false)) {
        if (entity is File) {
          encoder.addFile(entity, p.basename(entity.path));
        }
      }
      for (final entry in included) {
        encoder.addFile(entry.key, entry.value);
      }
    } finally {
      encoder.closeSync();
    }

    // 清理导出临时json
    await deleteFilesInDirectory(exportDir.path);

    return BackupBuildResult(
      zipPath: zipPath,
      includedCount: included.length,
      includedBytes: manifest['media']['includedBytes'] as int,
      excludedCount: scan.large.length,
      excludedBytes: scan.largeBytes,
    );
  }

  /// 构建大媒体独立包(视频等超过阈值的消息媒体)
  static Future<BackupBuildResult> buildMediaPack({
    required String zipPath,
    void Function(String stage)? onStage,
  }) async {
    onStage?.call('正在扫描大媒体文件...');
    final scan = await scanMediaReferences();
    if (scan.large.isEmpty) {
      return BackupBuildResult(zipPath: zipPath);
    }

    onStage?.call('正在压缩打包(${scan.large.length}个文件)...');
    final encoder = ZipFileEncoder();
    encoder.create(zipPath);
    try {
      for (final entry in scan.large) {
        encoder.addFile(entry.key, entry.value);
      }
    } finally {
      encoder.closeSync();
    }

    return BackupBuildResult(
      zipPath: zipPath,
      includedCount: scan.large.length,
      includedBytes: scan.largeBytes,
    );
  }

  // ================= 媒体引用扫描 =================

  /// 扫描消息/搭档/全局设置中引用的本地媒体文件并按大小分级
  static Future<MediaScanResult> scanMediaReferences() async {
    final candidates = <String>{};
    final roots = await _rootPrefixesAsync();

    // 1. unified库：消息3列 + 搭档2列
    try {
      final dbPath = p.join(
        (await getSqliteDbDir()).path,
        DBInitConfig.chatDbName,
      );
      if (File(dbPath).existsSync()) {
        final db = await openDatabase(dbPath);
        try {
          final rows = await db.rawQuery(
            'SELECT content, multimodal_content, metadata FROM '
            '${UnifiedChatDdl.tableUnifiedChatMessage}',
          );
          for (final row in rows) {
            for (final v in row.values) {
              if (v is String) {
                candidates.addAll(_extractFilePaths(v, roots));
              }
            }
          }
          final partnerRows = await db.rawQuery(
            'SELECT avatar_url, background FROM '
            '${UnifiedChatDdl.tableUnifiedChatPartner}',
          );
          for (final row in partnerRows) {
            for (final v in row.values) {
              if (v is String) {
                candidates.addAll(_extractFilePaths(v, roots));
              }
            }
          }
        } finally {
          await db.close();
        }
      }
    } catch (e) {
      print('扫描消息媒体引用失败: $e');
    }

    // 2. 全局聊天背景
    try {
      final bg = CusGetStorage().box.read('chat_background');
      if (bg is String) candidates.addAll(_extractFilePaths(bg, roots));
    } catch (_) {}

    // 3. 存在性过滤 + 相对路径 + 分级
    final small = <MapEntry<File, String>>[];
    final large = <MapEntry<File, String>>[];
    for (final path in candidates) {
      final f = File(path);
      if (!f.existsSync()) continue;
      final rel = await _zipRelPathOf(f);
      if (rel == null) continue;
      final entry = MapEntry(f, rel);
      if (f.lengthSync() <= kSmallMediaThresholdBytes) {
        small.add(entry);
      } else {
        large.add(entry);
      }
    }
    return MediaScanResult(small: small, large: large);
  }

  /// 从任意文本中提取"可读根目录下"的文件路径
  /// (消息内容为markdown、metadata为json串，路径可能被引号/括号/逗号包围)
  static Set<String> _extractFilePaths(String text, List<String> roots) {
    final out = <String>{};
    for (final root in roots) {
      final re = RegExp('${RegExp.escape(root)}([^"\n\r]*)');
      for (final m in re.allMatches(text)) {
        var path = root + (m.group(1) ?? '');
        // 去掉markdown/json包裹的尾部字符
        path = path.replaceAll(RegExp(r'[)\]},;]+\s*$'), '');
        if (path.length > root.length) out.add(path);
      }
    }
    return out;
  }

  /// 可提取文件的根前缀集合(异步)
  static Future<List<String>> _rootPrefixesAsync() async {
    final roots = <String>[];
    roots.add((await getAppPrivateDir()).path);
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final home = getDesktopHomePath();
      if (home != null) {
        for (final kind in ['Pictures', 'Movies', 'Music', 'Videos']) {
          roots.add(p.join(home, kind));
        }
      }
    }
    return roots;
  }

  /// File -> zip内相对路径(files/<根别名>/<相对根路径>)
  /// 无法归属已知根的文件返回null(不打包)
  static Future<String?> _zipRelPathOf(File f) async {
    final appRoot = await getAppPrivateDir();
    String norm(String s) => s.replaceAll('\\', '/');
    final fp = norm(f.path);
    final app = norm(appRoot.path);
    if (fp.startsWith('$app/')) {
      return '$FILES_DIR_IN_ZIP/app/${fp.substring(app.length + 1)}';
    }
    // 桌面公共媒体区(~/Pictures|Movies|Music/SuChat)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final home = getDesktopHomePath();
      if (home != null) {
        for (final kind in ['Pictures', 'Movies', 'Music', 'Videos']) {
          final base = norm(p.join(home, kind));
          if (fp.startsWith('$base/')) {
            return '$FILES_DIR_IN_ZIP/pub/${fp.substring(base.length + 1)}';
          }
        }
      }
    }
    return null;
  }

  // ================= 外观设置 =================

  static Future<void> _exportAppearance(Directory dir) async {
    try {
      final box = CusGetStorage().box;
      final data = <String, dynamic>{};
      for (final key in kAppearanceKeys) {
        final v = box.read(key);
        if (v != null) data[key] = v;
      }
      // 背景图内嵌(恢复时无需依赖文件包)
      final bg = data['chat_background'];
      if (bg is String) {
        final f = File(bg);
        if (f.existsSync() && f.lengthSync() <= kSmallMediaThresholdBytes) {
          data['chat_background_b64'] = base64Encode(f.readAsBytesSync());
        }
      }
      File(
        p.join(dir.path, APPEARANCE_FILE_NAME),
      ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
    } catch (e) {
      print('导出外观设置失败: $e');
    }
  }

  // ================= 通用 =================

  /// 删除指定文件夹下所有文件(不递归子目录)
  static Future<void> deleteFilesInDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (await directory.exists()) {
      await for (var file in directory.list()) {
        if (file is File) {
          await file.delete();
        }
      }
    }
  }

  /// 解压备份zip到指定目录(先清空旧解压残留)
  static Future<List<File>> unzipBackup(File zipFile, String unzipPath) async {
    await deleteFilesInDirectory(unzipPath);
    await extractFileToDisk(zipFile.path, unzipPath);

    return Directory(unzipPath)
        .listSync()
        .where((entity) => entity is File && entity.path.endsWith('.json'))
        .map((entity) => entity as File)
        .toList();
  }
}
