// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';

import '../storage/cus_get_storage.dart';
import '../storage/db_config.dart';
import '../storage/db_init.dart';
import '../utils/get_dir.dart';
import '../../features/unified_chat/data/database/unified_chat_db_init.dart';
import '../../features/unified_chat/data/database/unified_chat_ddl.dart';
import '../../features/unified_chat/data/services/branch_chat_importer.dart';
import 'legacy_branch_chat_reader.dart';

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
  static const String permDeniedKey = 'upgrade_migration_015_perm_denied';
  static const String objectBoxFoundKey = 'upgrade_migration_objectbox_found';

  /// 已完成迁移(或确认无旧数据)
  static bool isDone() => CusGetStorage().box.read(doneKey) != null;

  /// 权限引导门(启动链用)：Android 且未完成迁移且未授权且用户未拒绝过。
  /// true 时启动链应先走说明弹窗(用户同意后调 requestLegacyPermission，
  /// 拒绝则调 markPermissionDenied)，不要静默请求系统权限。
  static Future<bool> needsPermissionGate() async {
    if (!Platform.isAndroid) return false;
    if (isDone()) return false;
    if (await isLegacyPermissionGranted()) return false;
    // 用户明确拒绝过：不再自动弹(设置页"重新扫描本机旧版数据"手动兜底)
    if (CusGetStorage().box.read(permDeniedKey) == true) return false;
    return true;
  }

  /// 检查(不请求)旧数据读取权限是否已授予
  static Future<bool> isLegacyPermissionGranted() async {
    if (!Platform.isAndroid) return true;
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 30) {
      return await Permission.manageExternalStorage.isGranted;
    }
    return await Permission.storage.isGranted;
  }

  /// 请求旧数据读取权限(仅供引导页在用户明确同意后调用；
  /// 已授权时立即返回true不弹窗)
  static Future<bool> requestLegacyPermission() =>
      _ensureLegacyReadPermission();

  /// 用户在说明弹窗中拒绝迁移：记录标记，本次及后续启动不再自动弹
  static Future<void> markPermissionDenied() =>
      CusGetStorage().box.write(permDeniedKey, true);

  /// 需要迁移的旧根子目录 → 新位置(懒加载函数，桌面端媒体会指向公共目录)
  /// 注意(2026-09-18 FIX)：不含DB/sqlite_db——库文件由_copySqliteDbs在
  /// 启动阻塞段专门复制(先于任何DB打开)；若放进后台搬移清单，会对
  /// 已被app打开的库文件再copy/delete，sqlite锁竞争导致首页/侧边栏
  /// 全部查询挂起转圈，甚至损坏打开中的库
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
  };

  /// 入口：探测旧根并执行迁移。
  ///
  /// [quickOnly] = true 时仅执行"必须阻塞启动"的部分（sqlite 复制），
  /// 媒体移动/路径重写作为后台任务返回；false（手动重跑）时全部完成后返回。
  ///
  /// 2026-10-12 权限交互收编：本方法**不再主动请求权限**——Android
  /// 未授权时直接返回 needsPermission=true，由引导页(先弹说明框取得
  /// 用户同意后请求系统权限)走完授权再重新进入。此前静默弹系统权限
  /// 且用户拒绝后被 markDone，旧数据永远失去迁移机会。
  static Future<UpgradeMigrationResult> runIfNeeded({
    bool force = false,
    bool quickOnly = false,
  }) async {
    if (!force && isDone()) {
      return UpgradeMigrationResult._(migrated: false, objectBoxFound: false);
    }

    // ---------- 0. Android 权限门：未授权不探测不请求 ----------
    if (Platform.isAndroid && !await isLegacyPermissionGranted()) {
      print('[UpgradeMigrator] 未授予旧数据读取权限，跳过迁移(待引导授权)');
      return const UpgradeMigrationResult._(
        migrated: false,
        needsPermission: true,
        objectBoxFound: false,
      );
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

    if (legacyRoot == null) {
      // 已授权前提下探测不到 = 确认无旧数据；Android 未授权场景已在
      // 上面拦截不会走到这里(不会误标完成)
      await _markDone();
      return UpgradeMigrationResult._(migrated: false, objectBoxFound: false);
    }

    print('[UpgradeMigrator] 发现旧版数据根: ${legacyRoot.path}');

    // ---------- 2. Android存储权限预授权(2026-09-18 FIX) ----------
    // scoped storage下公共目录"顶层可见、子目录内容不可见"(listSync
    // 返回空/stat失败)是常态，等复制失败再补救为时已晚。发现旧根后
    // 直接确保权限——已授权时request立即返回不弹窗；被拒则如实失败
    // 且不标记完成。此前该设备的症状：顶层探测成功但库/媒体目录全部
    // 不可见，复制零执行却被标记"迁移全部完成"
    if (Platform.isAndroid) {
      final granted = await _ensureLegacyReadPermission();
      if (!granted) {
        print('[UpgradeMigrator] 未授予存储权限，迁移中止(不标记完成)');
        return const UpgradeMigrationResult._(
          migrated: true,
          success: false,
          error: '读取旧版数据需要"所有文件访问"权限，请在系统设置中授权后重新扫描',
          objectBoxFound: false,
        );
      }
    }

    // ---------- 3. 可读性预检 ----------
    if (!_canReadDeep(legacyRoot)) {
      print('[UpgradeMigrator] 授权后旧根仍不可读，迁移中止(不标记完成)');
      return const UpgradeMigrationResult._(
        migrated: true,
        success: false,
        error: '已授权但仍无法读取旧版数据，请检查旧数据目录是否完整后重试',
        objectBoxFound: false,
      );
    }

    // ---------- 4. sqlite 库复制(阻塞，须先于任何 DB 打开) ----------
    // (ok, copied)：ok=false表示有库文件但复制失败——库是核心数据，
    // 此时整个迁移视为失败，绝不标记完成(否则新库是空的，用户数据"消失")
    final (copyOk, dbFilesCopied) = await _copySqliteDbs(legacyRoot);

    // ---------- 5. ObjectBox 残留标记(备份中转引导用) ----------
    var objectBoxFound = false;
    try {
      final obDir = Directory(p.join(legacyRoot.path, 'DB/objectbox'));
      objectBoxFound =
          obDir.existsSync() && obDir.listSync(followLinks: false).isNotEmpty;
    } catch (_) {}
    if (objectBoxFound) {
      await CusGetStorage().box.write(objectBoxFoundKey, true);
    }

    // ---------- 6. 媒体移动 + 路径重写(可后台) ----------
    Future<void> heavyWork() async {
      try {
        // 闭包捕获的可空变量无法跨await保持类型提升，先接住一次断言
        final root = legacyRoot!;

        // ---------- 6.0 旧分支聊天转换(必须在封存前读旧库) ----------
        // 2026-10-12 最小集成：ObjectBox只读打开旧库→转导出格式→
        // 复用BranchChatImporter导入链(平台/搭档映射、幂等判重、
        // 分支回填)。旧库文件原样留在封存目录兜底，不删不改
        if (objectBoxFound) {
          try {
            await _migrateLegacyBranchChats(root);
          } catch (e) {
            print('[UpgradeMigrator] 旧分支聊天转换失败(重扫可重试): $e');
          }
        }

        await _moveLegacyDirs(root);
        await _rewritePaths(root, dbFilesCopied);
        await _rewriteGlobalBackgroundPath(root);
        await _sealLegacyRoot(root);
        if (copyOk) {
          await _markDone();
          print('[UpgradeMigrator] 迁移全部完成');
        } else {
          // 2026-09-18 FIX：库复制失败不标记完成——否则失败的迁移被
          // 标成完成，后续重扫被isDone短路，用户永远拿不回数据
          print('[UpgradeMigrator] 库文件复制失败，迁移未完成(重扫可续传)');
        }
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
      success: copyOk,
      error: copyOk ? null : '数据库文件复制失败(权限或IO错误)，迁移未完成',
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

  /// 深度可读探测(2026-09-18 FIX)：递归必须实际stat到至少一个文件
  /// 才算可读。注意MIUI等ROM的FUSE层对无权限目录listSync可能返回
  /// 空列表而非抛错——空列表一律判不可读(能被选为legacyRoot说明
  /// 探测时非空，空/不可列即权限异常，保守中止走权限引导)
  static bool _canReadDeep(Directory dir) {
    try {
      final entities = dir.listSync(followLinks: false);
      if (entities.isEmpty) return false;
      for (final e in entities) {
        if (e is File) {
          e.lengthSync();
          return true;
        }
        if (e is Directory && _canReadDeep(e)) return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 旧数据读取权限确保(2026-09-18 FIX)：迁移专用分流。
  /// 通用requestStoragePermission以sdk32为界走READ权限——但scoped
  /// storage自Android 11(sdk 30)起强制，READ权限读不了公共根目录
  /// 自定义文件夹(0.1.4的SuChatFiles正是此类)，必须"所有文件访问"。
  /// 已授权时request立即返回不弹窗
  static Future<bool> _ensureLegacyReadPermission() async {
    if (!Platform.isAndroid) return true;
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;
    if (sdkInt >= 30) {
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    }
    // sdk<30(legacy storage)：runtime读写权限即可访问公共目录
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  /// 复制主库与 unified 库文件(含 journal/wal/shm)
  /// 目标已存在且比源旧时才覆盖。
  /// 2026-10-12 复制前先关闭应用的两个库连接：手动重扫时 app 早已
  /// 打开库，Windows 对打开中的文件强制锁(errno 32)会复制失败；
  /// Android 虽允许替换打开中文件，关连接同样更稳。连接随后由各
  /// DBInit 的 getter 懒加载重开(指向新文件)
  /// 返回(ok, copied)：ok=false=存在库文件但复制失败(核心数据迁移
  /// 失败，调用方据此判定整个迁移未完成)；copied=是否实际复制了文件
  static Future<(bool, bool)> _copySqliteDbs(Directory legacyRoot) async {
    final srcDir = Directory(p.join(legacyRoot.path, 'DB/sqlite_db'));
    // 目录不可见时无法区分"不存在"与"无权读取"，但入口处已做
    // _canReadDeep预检，走到这里仍不可见多半是旧数据本就无库
    if (!srcDir.existsSync()) return (true, false);

    // 先关库连接(未打开时close是no-op)
    try {
      await DBInit().closeDB();
    } catch (_) {}
    try {
      await UnifiedChatDBInit().closeDatabase();
    } catch (_) {}

    final targetDir = await getSqliteDbDir();
    var copied = false;
    var ok = true;

    for (final name in [DBInitConfig.databaseName, DBInitConfig.chatDbName]) {
      for (final suffix in ['', '-journal', '-wal', '-shm']) {
        final src = File(p.join(srcDir.path, '$name$suffix'));
        try {
          if (!src.existsSync()) continue;
          // -journal/-wal/-shm 只在主文件存在时才有意义
          final dst = File(p.join(targetDir.path, '$name$suffix'));
          final srcMain = File(p.join(srcDir.path, name));
          final srcHasMain = srcMain.existsSync();
          if (suffix.isNotEmpty && !srcHasMain) continue;

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
          // 2026-09-18 FIX：复制失败必须向上传导——此前此处只打日志
          // 返回copied，失败被吞后整个迁移照样标记完成
          ok = false;
          print('[UpgradeMigrator] 复制 $name$suffix 失败: $e');
        }
      }
    }
    return (ok, copied);
  }

  /// 复制旧根下的媒体/附件/录音/备份目录到新位置
  /// 2026-10-12 改move为纯复制：目标位置是应用私有区(用户文件管理器
  /// 不可见)，此前copy→delete源导致旧目录只剩空壳、用户无从找回。
  /// 现源内容原样保留，最后由_sealLegacyRoot整体改名封存——用户在
  /// 文件管理器中仍能看到完整的旧数据副本。逐文件copy，目标已存在
  /// 则跳过(大小一致)，中断重跑自动续传
  static Future<void> _moveLegacyDirs(Directory legacyRoot) async {
    // 2026-10-12 FIX：父目录映射(如AI_GEN/voices)复制时会递归重复
    // 已单独映射的子目录(translator/omni_chat)——父目录复制时跳过
    final skipFor = <String, Set<String>>{};
    for (final key in _dirMappings.keys) {
      final subs = <String>{};
      for (final other in _dirMappings.keys) {
        if (other == key || !other.startsWith('$key/')) continue;
        subs.add(other.substring(key.length + 1).split('/').first);
      }
      if (subs.isNotEmpty) skipFor[key] = subs;
    }

    for (final entry in _dirMappings.entries) {
      final src = Directory(p.join(legacyRoot.path, entry.key));
      if (!src.existsSync()) continue;
      final target = await entry.value();
      await _copyDirContents(src, target, skipTopDirs: skipFor[entry.key]);
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
            await _copyDirContents(
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

  static Future<void> _copyDirContents(
    Directory src,
    Directory target, {
    Set<String>? skipTopDirs,
  }) async {
    try {
      if (!target.existsSync()) {
        target.createSync(recursive: true);
      }
      final entities = src.listSync(followLinks: false);
      var copied = 0;
      for (final entity in entities) {
        // 仅顶层生效(skipTopDirs不传给递归调用)：跳过已单独映射的子目录
        if (skipTopDirs != null &&
            skipTopDirs.contains(p.basename(entity.path))) {
          continue;
        }
        if (entity is File) {
          final dst = File(p.join(target.path, p.basename(entity.path)));
          if (!dst.existsSync() || dst.lengthSync() != entity.lengthSync()) {
            await entity.copy(dst.path);
          }
          copied++;
        } else if (entity is Directory) {
          await _copyDirContents(
            entity,
            Directory(p.join(target.path, p.basename(entity.path))),
          );
        }
      }
      if (copied > 0) {
        print(
          '[UpgradeMigrator] 已复制 ${src.path} → ${target.path} ($copied 文件)',
        );
      }
    } catch (e) {
      print('[UpgradeMigrator] 复制目录失败 ${src.path}: $e');
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
      // 2026-09-18 FIX：singleInstance:false——sqflite默认同path共享
      // 全局单例，这里close()会把app主流程正在使用的连接一起关掉，
      // 引发启动后第一次查库报DatabaseException(database_closed)。
      // 独立连接用完即关，互不影响
      db = await openDatabase(dbPath, singleInstance: false);
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
            try {
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
            } catch (e) {
              // 2026-09-18 FIX：逐列容错——本方法在库升级(onUpgrade)之前
              // 执行，此时库还是v1结构(如partner.background列尚不存在)，
              // 单列失败不应中断其余列的重写(外层整体catch会一列缺失
              // 全部跳过)
              print('[UpgradeMigrator] 路径重写跳过 ${tableCols.$1}.$col: $e');
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

  /// 旧分支聊天(ObjectBox)→新版统一聊天转换导入
  /// (heavyWork内调用，失败由调用方兜底提示重扫)
  static Future<void> _migrateLegacyBranchChats(Directory legacyRoot) async {
    if (!LegacyBranchChatReader.hasData(legacyRoot)) {
      print('[UpgradeMigrator] 旧ObjectBox目录无分支聊天数据，跳过转换');
      return;
    }

    final errors = <String>[];
    final sessions = await LegacyBranchChatReader.read(
      legacyRoot,
      errors: errors,
    );
    if (sessions.isEmpty) {
      print(
        '[UpgradeMigrator] 旧分支聊天无可转换会话${errors.isEmpty ? '' : '：${errors.take(3)}'}',
      );
      return;
    }

    final importer = BranchChatImporter();
    final result = await importer.importFromJson({
      'sessions': sessions.map((s) => s.toJson()).toList(),
    });

    print(
      '[UpgradeMigrator] 旧分支聊天转换完成: 导入${result.importedCount}'
      ' 跳过${result.skippedCount} 失败${result.failedCount}'
      '${errors.isEmpty ? '' : ' 转换错误${errors.length}条'}',
    );
  }

  /// 旧根整体改名封存。
  /// 2026-10-12 媒体改纯复制后，旧根内容不再被搬空——封存的是
  /// 完整旧数据副本(库文件/媒体/objectbox全在)，用户在文件管理器
  /// 可见可找回，也为"降级0.1.4补备份"兜底
  static Future<void> _sealLegacyRoot(Directory legacyRoot) async {
    try {
      // 完全无内容才直接删(改名分支通常总有DB目录在)
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
        await _copyDirContents(legacyRoot, sealed);
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

  /// 迁移是否成功完成(migrated=false时恒true；false=库复制失败或
  /// 权限不足，未标记完成，可重扫续传)
  final bool success;

  /// 失败原因摘要(仅success=false时有值，供UI直接展示)
  final String? error;

  /// 旧根是否残留 ObjectBox 数据(需要备份中转引导)
  final bool objectBoxFound;

  /// Android 未授权：需要引导页弹说明框取得用户同意后再请求权限，
  /// 授权后重新进入迁移。此时未探测旧目录、未标记完成
  final bool needsPermission;

  const UpgradeMigrationResult._({
    required this.migrated,
    this.success = true,
    this.error,
    required this.objectBoxFound,
    this.needsPermission = false,
  });
}
