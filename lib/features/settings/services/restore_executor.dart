// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../../core/entities/cus_llm_model.dart';
import '../../../core/entities/user_info.dart';
import '../../../core/storage/cus_get_storage.dart';
import '../../../core/storage/db_config.dart';
import '../../../core/storage/db_ddl.dart';
import '../../../core/storage/db_helper.dart';
import '../../../core/storage/ddl_diet_diary.dart';
import '../../../core/storage/ddl_notebook.dart';
import '../../../core/storage/ddl_simple_accounting.dart';
import '../../../core/storage/ddl_training.dart';
import '../../../core/utils/get_dir.dart';
import '../../diet_diary/data/index.dart';
import '../../diet_diary/domain/entities/index.dart';
import '../../../core/entities/media_generation_history.dart';
import '../../notebook/data/note_dao.dart';
import '../../notebook/domain/entities/index.dart';
import '../../simple_accounting/data/bill_dao.dart';
import '../../simple_accounting/domain/entities/bill_category.dart';
import '../../simple_accounting/domain/entities/bill_item.dart';
import '../../training_assistant/data/training_dao.dart';
import '../../training_assistant/domain/entities/index.dart';
import '../../unified_chat/data/database/unified_chat_dao.dart';
import '../../unified_chat/data/database/unified_chat_ddl.dart';
import '../../unified_chat/data/models/unified_chat_message.dart';
import '../../unified_chat/data/models/unified_chat_partner.dart';
import '../../unified_chat/data/models/unified_conversation.dart';
import '../../unified_chat/data/models/unified_model_spec.dart';
import '../../unified_chat/data/models/unified_platform_spec.dart';
import '../../unified_chat/data/services/branch_chat_importer.dart';
import '../../unified_chat/data/models/character_card.dart';
import '../../voice_recognition/domain/entities/voice_recognition_task_info.dart';
import 'backup_utils.dart';

/// 恢复选择(2026-09-01 恢复向导)
class RestoreSelection {
  /// 勾选要恢复的json文件名集合(小写，含.json后缀)
  final Set<String> selectedFiles;

  /// 新版聊天：勾选的会话id集合；null表示该模块全选
  final Set<String>? unifiedConvIds;

  const RestoreSelection({required this.selectedFiles, this.unifiedConvIds});
}

/// 单模块恢复结果
class RestoreModuleReport {
  final String module;
  final String fileName;
  int imported = 0;
  int skipped = 0;
  String? error;

  RestoreModuleReport(this.module, this.fileName);
}

/// 恢复执行的整体结果(含媒体文件恢复统计)
class RestoreOverallResult {
  final List<RestoreModuleReport> modules;

  /// 恢复的媒体文件数(files/目录)
  final int mediaRestored;

  /// 备份中未包含的大媒体数(提示用户可导入媒体包)
  final int mediaExcluded;

  /// 是否恢复了外观设置
  final bool appearanceRestored;

  const RestoreOverallResult({
    required this.modules,
    this.mediaRestored = 0,
    this.mediaExcluded = 0,
    this.appearanceRestored = false,
  });
}

/// 选择性合并恢复执行器(2026-09-01 从 backup_and_restore_page 提取并增强)
///
/// - 按勾选的文件/会话选择性恢复，未勾选的模块整表跳过
/// - 合并语义不变：同主键覆盖，库中现有其他数据全部保留
/// - 2026-09-01 0.1.5：旧聊天/角色恢复只转换导入新版(不再写 ObjectBox)；
///   新增 files/ 媒体文件恢复、备份路径前缀重写、外观设置恢复
/// - 支持模块级进度回调
class RestoreExecutor {
  final DBHelper _dbHelper = DBHelper();

  /// [unzipDir] 解压后的备份根目录(含json与files/)，
  /// 传入时启用媒体恢复/路径重写/外观恢复等 0.1.5 增强能力
  Future<RestoreOverallResult> execute({
    required List<File> jsonFiles,
    required RestoreSelection selection,
    Directory? unzipDir,
    void Function(String module, int done, int total)? onProgress,
  }) async {
    final reports = <RestoreModuleReport>[];

    // 依次处理：角色先行(旧聊天转换依赖) → 旧聊天 → unified → 主库各表
    final ordered = _orderFiles(jsonFiles);
    final total = ordered.length + 3; // +媒体/重写/外观三个收尾阶段
    var done = 0;

    for (final file in ordered) {
      final filename = p.basename(file.path).toLowerCase();
      final module = moduleNameOf(filename);
      final report = RestoreModuleReport(module, filename);

      if (!selection.selectedFiles.contains(filename)) {
        report.skipped = -1; // 用户未勾选
        reports.add(report);
        done++;
        onProgress?.call(module, done, total);
        continue;
      }

      try {
        final count = await _restoreSingleFile(filename, file, selection);
        report.imported = count;
      } catch (e) {
        print('恢复模块[$module]出错: $e');
        report.error = e.toString();
      }
      reports.add(report);
      done++;
      onProgress?.call(module, done, total);
    }

    // ===== 0.1.5 增强：媒体文件恢复 =====
    var mediaRestored = 0;
    if (unzipDir != null) {
      onProgress?.call('媒体文件', done, total);
      mediaRestored = await _restoreMediaFiles(unzipDir);
      done++;
      onProgress?.call('媒体文件', done, total);
    } else {
      done++;
    }

    // ===== 备份路径前缀重写(消息/搭档/全局背景) =====
    if (unzipDir != null) {
      onProgress?.call('路径适配', done, total);
      await _rewritePathsFromManifest(unzipDir);
      done++;
      onProgress?.call('路径适配', done, total);
    } else {
      done++;
    }

    // ===== 外观设置恢复 =====
    var appearanceRestored = false;
    var mediaExcluded = 0;
    if (unzipDir != null) {
      onProgress?.call('外观设置', done, total);
      appearanceRestored = await _restoreAppearance(unzipDir);
      mediaExcluded = _readExcludedCount(unzipDir);
      done++;
      onProgress?.call('外观设置', done, total);
    } else {
      done++;
    }

    return RestoreOverallResult(
      modules: reports,
      mediaRestored: mediaRestored,
      mediaExcluded: mediaExcluded,
      appearanceRestored: appearanceRestored,
    );
  }

  /// 处理顺序：角色最前(会话转换依赖角色)，旧聊天历史次之，其余原序
  List<File> _orderFiles(List<File> files) {
    final characterFiles = <File>[];
    final branchFiles = <File>[];
    final others = <File>[];

    for (final f in files) {
      final name = p.basename(f.path).toLowerCase();
      if (name == CHARACTER_CARD_LIST_FILE_NAME) {
        characterFiles.add(f);
      } else if (name == BRANCH_CHAT_HISTORY_FILE_NAME) {
        branchFiles.add(f);
      } else {
        others.add(f);
      }
    }
    return [...characterFiles, ...branchFiles, ...others];
  }

  /// 恢复单个文件，返回导入条数
  Future<int> _restoreSingleFile(
    String filename,
    File file,
    RestoreSelection selection,
  ) async {
    // ===== 角色卡：转换导入为搭档(0.1.5 起不再写旧版 ObjectBox) =====
    if (filename == CHARACTER_CARD_LIST_FILE_NAME) {
      final importer = BranchChatImporter();
      final list = json.decode(await file.readAsString()) as List;
      var count = 0;
      for (final e in list) {
        final card = CharacterCard.fromJson(
          Map<String, dynamic>.from(e as Map),
        );
        final created = await importer.importCharacter(card);
        if (created) count++;
      }
      return count;
    }

    // ===== 旧版聊天历史：转换导入新版(幂等) =====
    if (filename == BRANCH_CHAT_HISTORY_FILE_NAME) {
      final jsonData =
          json.decode(await file.readAsString()) as Map<String, dynamic>;
      final result = await BranchChatImporter().importFromJson(jsonData);
      print(
        '旧版聊天历史转换导入新版完成: '
        '导入${result.importedCount}个会话，'
        '跳过${result.skippedCount}个，失败${result.failedCount}个',
      );
      return result.importedCount;
    }

    // ===== 新版统一聊天模块 =====
    final unifiedCount = await _restoreUnifiedChatTable(
      filename,
      file,
      selection.unifiedConvIds,
    );
    if (unifiedCount != null) return unifiedCount;

    // ===== 主库各表 =====
    final jsonData = await file.readAsString();
    final jsonMapList = json.decode(jsonData) as List;

    if (filename == "${DBDdl.tableCusLlmSpec}.json") {
      await _dbHelper.saveCusLLMSpecs(
        jsonMapList.map((e) => CusLLMSpec.fromMap(e)).toList(),
      );
    } else if (filename == "${DBDdl.tableMediaGenerationHistory}.json") {
      await _dbHelper.saveMediaGenerationHistories(
        jsonMapList.map((e) => MediaGenerationHistory.fromMap(e)).toList(),
      );
    } else if (filename == "${DBDdl.tableVoiceRecognitionTask}.json") {
      await _dbHelper.saveVoiceRecognitionTasks(
        jsonMapList.map((e) => VoiceRecognitionTaskInfo.fromMap(e)).toList(),
      );
    } else if (filename == "${DBDdl.tableUserInfo}.json") {
      await _dbHelper.batchInsert(
        jsonMapList.map((e) => UserInfo.fromMap(e)).toList(),
      );
    } else if (filename == "${TrainingDdl.tableTrainingPlan}.json") {
      await TrainingDao().insertTrainingPlans(
        jsonMapList.map((e) => TrainingPlan.fromMap(e)).toList(),
      );
    } else if (filename == "${TrainingDdl.tableTrainingPlanDetail}.json") {
      await TrainingDao().insertTrainingPlanDetails(
        jsonMapList.map((e) => TrainingPlanDetail.fromMap(e)).toList(),
      );
    } else if (filename == "${TrainingDdl.tableTrainingRecord}.json") {
      await TrainingDao().insertTrainingRecords(
        jsonMapList.map((e) => TrainingRecord.fromMap(e)).toList(),
      );
    } else if (filename == "${TrainingDdl.tableTrainingRecordDetail}.json") {
      await TrainingDao().insertTrainingRecordDetails(
        jsonMapList.map((e) => TrainingRecordDetail.fromMap(e)).toList(),
      );
    } else if (filename == "${DietDiaryDdl.tableDietAnalysis}.json") {
      await DietAnalysisDao().batchInsert(
        jsonMapList.map((e) => DietAnalysis.fromMap(e)).toList(),
      );
    } else if (filename == "${DietDiaryDdl.tableDietRecipe}.json") {
      await DietRecipeDao().batchInsert(
        jsonMapList.map((e) => DietRecipe.fromMap(e)).toList(),
      );
    } else if (filename == "${DietDiaryDdl.tableFoodItem}.json") {
      await FoodItemDao().batchInsert(
        jsonMapList.map((e) => FoodItem.fromMap(e)).toList(),
      );
    } else if (filename == "${DietDiaryDdl.tableMealFoodRecord}.json") {
      await MealFoodRecordDao().batchInsert(
        jsonMapList.map((e) => MealFoodRecord.fromMap(e)).toList(),
      );
    } else if (filename == "${DietDiaryDdl.tableMealRecord}.json") {
      await MealRecordDao().batchInsert(
        jsonMapList.map((e) => MealRecord.fromMap(e)).toList(),
      );
    } else if (filename == "${DietDiaryDdl.tableWeightRecord}.json") {
      await WeightRecordDao().batchInsert(
        jsonMapList.map((e) => WeightRecord.fromMap(e)).toList(),
      );
    } else if (filename == "${SimpleAccountingDdl.tableBillCategory}.json") {
      await BillDao().batchInsertCategory(
        jsonMapList.map((e) => BillCategory.fromMap(e)).toList(),
      );
    } else if (filename == "${SimpleAccountingDdl.tableBillItem}.json") {
      await BillDao().batchInsertBillItem(
        jsonMapList.map((e) => BillItem.fromMap(e)).toList(),
      );
    } else if (filename == "${NotebookDdl.tableNoteCategory}.json") {
      await NoteDao().batchCreateCategory(
        jsonMapList.map((e) => NoteCategory.fromMap(e)).toList(),
      );
    } else if (filename == "${NotebookDdl.tableNoteTag}.json") {
      await NoteDao().batchCreateTag(
        jsonMapList.map((e) => NoteTag.fromMap(e)).toList(),
      );
    } else if (filename == "${NotebookDdl.tableNoteMedia}.json") {
      await NoteDao().batchCreateMedia(
        jsonMapList.map((e) => NoteMedia.fromMap(e)).toList(),
      );
    } else if (filename == "${NotebookDdl.tableNote}.json") {
      await NoteDao().batchCreateNote(
        jsonMapList.map((e) => Note.fromMap(e)).toList(),
      );
    } else if (filename == "${NotebookDdl.tableNoteTagRelation}.json") {
      await NoteDao().batchCreateNoteTagRelation(jsonMapList);
    }
    // 未知文件名：忽略(向前兼容新版本备份包)

    return jsonMapList.length;
  }

  /// unified_chat各表合并恢复；返回null表示非unified表
  /// [convIds] 非空时：会话/消息表只恢复勾选的会话(平台/模型/搭档仍全量)
  Future<int?> _restoreUnifiedChatTable(
    String filename,
    File file,
    Set<String>? convIds,
  ) async {
    final dao = UnifiedChatDao();

    // API密钥表未启用(密钥在SecureStorage中，不在备份包里)，跳过
    if (filename == "${UnifiedChatDdl.tableUnifiedApiKey}.json") {
      return 0;
    }

    try {
      if (filename == "${UnifiedChatDdl.tableUnifiedPlatformSpec}.json") {
        final list = _decodeJsonList(await file.readAsString());
        for (final e in list) {
          await dao.savePlatformSpec(UnifiedPlatformSpec.fromMap(e));
        }
        return list.length;
      } else if (filename == "${UnifiedChatDdl.tableUnifiedModelSpec}.json") {
        final list = _decodeJsonList(await file.readAsString());
        for (final e in list) {
          await dao.saveModelSpec(UnifiedModelSpec.fromMap(e));
        }
        return list.length;
      } else if (filename == "${UnifiedChatDdl.tableUnifiedChatPartner}.json") {
        final list = _decodeJsonList(await file.readAsString());
        for (final e in list) {
          await dao.saveChatPartner(UnifiedChatPartner.fromMap(e));
        }
        return list.length;
      } else if (filename ==
          "${UnifiedChatDdl.tableUnifiedConversation}.json") {
        final list = _decodeJsonList(await file.readAsString());
        var count = 0;
        for (final e in list) {
          if (convIds != null && !convIds.contains(e['id'] as String?)) {
            continue;
          }
          await dao.saveConversation(UnifiedConversation.fromMap(e));
          count++;
        }
        return count;
      } else if (filename == "${UnifiedChatDdl.tableUnifiedChatMessage}.json") {
        final list = _decodeJsonList(await file.readAsString());
        var count = 0;
        for (final e in list) {
          if (convIds != null &&
              !convIds.contains(e['conversation_id'] as String?)) {
            continue;
          }
          await dao.saveMessage(UnifiedChatMessage.fromMap(e));
          count++;
        }
        // v1旧备份的消息行没有分支字段，恢复后需要回填串链
        await dao.backfillBranchColumnsForRestore();
        return count;
      }
    } catch (e) {
      debugPrint('恢复unified_chat表[$filename]出错: $e');
      // 表处理出错也视为已消费该文件，避免落入主库分支报错
      return -1;
    }

    return null;
  }

  List<Map<String, dynamic>> _decodeJsonList(String jsonData) {
    final List list = json.decode(jsonData);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ================= 0.1.5 增强恢复 =================

  /// 恢复备份包 files/ 下的媒体文件到对应根目录
  /// files/app/... → 当前私有区；files/pub/... → 桌面公共媒体区
  static Future<int> _restoreMediaFiles(Directory unzipDir) async {
    final filesDir = Directory(p.join(unzipDir.path, FILES_DIR_IN_ZIP));
    if (!filesDir.existsSync()) return 0;

    var restored = 0;
    final appRoot = (await getAppPrivateDir()).path;
    String? home;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      home = getDesktopHomePath();
    }

    for (final entity in filesDir.listSync(recursive: true)) {
      if (entity is! File) continue;
      final rel = p.relative(
        entity.path,
        from: filesDir.path,
      ); // app/AI_GEN/x.png 或 pub/Pictures/SuChat/x.png
      final parts = rel.split(Platform.pathSeparator);
      if (parts.length < 2) continue;

      String? targetPath;
      if (parts[0] == 'app') {
        targetPath = p.joinAll([appRoot, ...parts.sublist(1)]);
      } else if (parts[0] == 'pub' && home != null && parts.length > 2) {
        // pub/Pictures/SuChat/... → ~/Pictures/SuChat/...
        targetPath = p.joinAll([home, ...parts.sublist(1)]);
      }
      if (targetPath == null) continue;

      try {
        final dst = File(targetPath);
        if (dst.existsSync() && dst.lengthSync() == entity.lengthSync()) {
          continue; // 已存在同大小文件，跳过(幂等)
        }
        await Directory(p.dirname(targetPath)).create(recursive: true);
        await entity.copy(targetPath);
        restored++;
      } catch (e) {
        print('恢复媒体文件失败[$targetPath]: $e');
      }
    }
    return restored;
  }

  /// 按备份清单把"备份机私有区根"重写为"当前私有区根"
  /// (同设备重装前缀一致零改动；跨设备/桌面用户名不同自动适配；
  ///  0.1.4 老备份的外部存储路径也在此统一重写到当前私有区)
  static Future<void> _rewritePathsFromManifest(Directory unzipDir) async {
    try {
      final manifestFile = File(p.join(unzipDir.path, MANIFEST_FILE_NAME));
      String? oldRoot;
      if (manifestFile.existsSync()) {
        final manifest = json.decode(manifestFile.readAsStringSync());
        oldRoot = manifest['privateRoot'] as String?;
      }

      final dbPath = p.join(
        (await getSqliteDbDir()).path,
        DBInitConfig.chatDbName,
      );
      if (!File(dbPath).existsSync()) return;
      final db = await openDatabase(dbPath);
      try {
        // 新版备份：备份私有区根 → 当前私有区根
        if (oldRoot != null && oldRoot.isNotEmpty) {
          final newRoot = (await getAppPrivateDir()).path;
          if (oldRoot != newRoot) {
            await _replacePathInTables(db, oldRoot, newRoot);
          }
        }
        // 0.1.4 老备份：外部存储旧根 → 当前私有区根(文件已无处可寻，
        // 但统一指向私有区以便将来用户手动补媒体包)
        final legacyRoots = await getLegacyHomeCandidatesAsync();
        final currentRoot = (await getAppPrivateDir()).path;
        for (final legacy in legacyRoots) {
          await _replacePathInTables(db, legacy.path, currentRoot);
        }
      } finally {
        await db.close();
      }

      // 全局背景路径重写
      final box = CusGetStorage().box;
      final bg = box.read('chat_background');
      if (bg is String) {
        var rewritten = bg;
        if (oldRoot != null && oldRoot.isNotEmpty) {
          final newRoot = (await getAppPrivateDir()).path;
          rewritten = rewritten.replaceAll(oldRoot, newRoot);
        }
        for (final legacy in await getLegacyHomeCandidatesAsync()) {
          rewritten = rewritten.replaceAll(
            legacy.path,
            (await getAppPrivateDir()).path,
          );
        }
        if (rewritten != bg) await box.write('chat_background', rewritten);
      }
    } catch (e) {
      print('路径重写失败(非致命): $e');
    }
  }

  static Future<void> _replacePathInTables(
    Database db,
    String oldPrefix,
    String newPrefix,
  ) async {
    for (final tableCols in [
      (
        UnifiedChatDdl.tableUnifiedChatMessage,
        ['content', 'multimodal_content', 'metadata'],
      ),
      (UnifiedChatDdl.tableUnifiedChatPartner, ['avatar_url', 'background']),
    ]) {
      for (final col in tableCols.$2) {
        try {
          await db.rawUpdate(
            "UPDATE ${tableCols.$1} SET $col = REPLACE($col, ?, ?) "
            "WHERE $col IS NOT NULL AND instr($col, ?) > 0",
            [oldPrefix, newPrefix, oldPrefix],
          );
        } catch (_) {}
      }
    }
  }

  /// 恢复外观设置(含背景图文件还原)
  static Future<bool> _restoreAppearance(Directory unzipDir) async {
    try {
      final f = File(p.join(unzipDir.path, APPEARANCE_FILE_NAME));
      if (!f.existsSync()) return false;
      final data = json.decode(f.readAsStringSync());
      if (data is! Map<String, dynamic>) return false;

      final box = CusGetStorage().box;
      final appRoot = (await getAppPrivateDir()).path;

      // 背景图文件还原(b64内嵌)
      final b64 = data.remove('chat_background_b64') as String?;
      if (b64 != null) {
        var bgPath = data['chat_background'] as String?;
        if (bgPath != null) {
          // 备份机路径 → 当前根
          final manifestFile = File(p.join(unzipDir.path, MANIFEST_FILE_NAME));
          if (manifestFile.existsSync()) {
            final manifest = json.decode(manifestFile.readAsStringSync());
            final oldRoot = manifest['privateRoot'] as String?;
            if (oldRoot != null && oldRoot.isNotEmpty) {
              bgPath = bgPath.replaceAll(oldRoot, appRoot);
              data['chat_background'] = bgPath;
            }
          }
          try {
            final img = File(bgPath);
            await Directory(p.dirname(img.path)).create(recursive: true);
            await img.writeAsBytes(base64Decode(b64));
          } catch (_) {}
        }
      }

      for (final entry in data.entries) {
        await box.write(entry.key, entry.value);
      }
      return true;
    } catch (e) {
      print('恢复外观设置失败: $e');
      return false;
    }
  }

  /// 读取备份清单中"未包含的大媒体"数量(报告提示用)
  static int _readExcludedCount(Directory unzipDir) {
    try {
      final manifestFile = File(p.join(unzipDir.path, MANIFEST_FILE_NAME));
      if (!manifestFile.existsSync()) return 0;
      final manifest = json.decode(manifestFile.readAsStringSync());
      final media = manifest['media'];
      if (media is Map<String, dynamic>) {
        return (media['excludedCount'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  /// json文件名 -> 模块显示名(恢复向导预览用)
  static String moduleNameOf(String filename) {
    final f = filename.toLowerCase();
    return switch (f) {
      CHARACTER_CARD_LIST_FILE_NAME => '旧版角色卡',
      BRANCH_CHAT_HISTORY_FILE_NAME => '旧版聊天历史',
      '${UnifiedChatDdl.tableUnifiedPlatformSpec}.json' => '新版聊天-平台配置',
      '${UnifiedChatDdl.tableUnifiedModelSpec}.json' => '新版聊天-模型列表',
      '${UnifiedChatDdl.tableUnifiedChatPartner}.json' => '新版聊天-搭档角色',
      '${UnifiedChatDdl.tableUnifiedConversation}.json' => '新版聊天-对话',
      '${UnifiedChatDdl.tableUnifiedChatMessage}.json' => '新版聊天-消息',
      '${UnifiedChatDdl.tableUnifiedApiKey}.json' => '新版聊天-密钥(跳过)',
      '${DBDdl.tableCusLlmSpec}.json' => 'AI工具-模型配置',
      '${DBDdl.tableMediaGenerationHistory}.json' => 'AI工具-生成历史',
      '${DBDdl.tableVoiceRecognitionTask}.json' => 'AI工具-语音任务',
      '${DBDdl.tableUserInfo}.json' => '用户信息',
      '${TrainingDdl.tableTrainingPlan}.json' => '训练助手',
      '${TrainingDdl.tableTrainingPlanDetail}.json' => '训练助手',
      '${TrainingDdl.tableTrainingRecord}.json' => '训练助手',
      '${TrainingDdl.tableTrainingRecordDetail}.json' => '训练助手',
      '${DietDiaryDdl.tableDietAnalysis}.json' => '饮食日记',
      '${DietDiaryDdl.tableDietRecipe}.json' => '饮食日记',
      '${DietDiaryDdl.tableFoodItem}.json' => '饮食日记',
      '${DietDiaryDdl.tableMealFoodRecord}.json' => '饮食日记',
      '${DietDiaryDdl.tableMealRecord}.json' => '饮食日记',
      '${DietDiaryDdl.tableWeightRecord}.json' => '饮食日记',
      '${SimpleAccountingDdl.tableBillCategory}.json' => '极简记账',
      '${SimpleAccountingDdl.tableBillItem}.json' => '极简记账',
      '${NotebookDdl.tableNoteCategory}.json' => '记事本',
      '${NotebookDdl.tableNoteTag}.json' => '记事本',
      '${NotebookDdl.tableNoteMedia}.json' => '记事本',
      '${NotebookDdl.tableNote}.json' => '记事本',
      '${NotebookDdl.tableNoteTagRelation}.json' => '记事本',
      _ => '其他数据',
    };
  }
}
