import 'package:sqflite/sqflite.dart';

import '../../../models/brief_ai_tools/media_generation_history/media_generation_history.dart';
import '../../../models/brief_ai_tools/voice_recognition/voice_recognition_task_info.dart';
import '../../llm_spec/cus_brief_llm_model.dart';
import '../../llm_spec/constant_llm_enum.dart';

import 'init_db.dart';
import 'ddl_brief_ai_tool.dart';

///
/// 简洁版AI工具相关数据库操作
///
class DBBriefAIToolHelper {
  // 单例模式
  static final DBBriefAIToolHelper _dbBriefHelper =
      DBBriefAIToolHelper._createInstance();
  // 构造函数，返回单例
  factory DBBriefAIToolHelper() => _dbBriefHelper;

  // 命名的构造函数用于创建DatabaseHelper的实例
  DBBriefAIToolHelper._createInstance();

  // 获取数据库实例(每次操作都从 DBInit 获取，不缓存)
  Future<Database> get database async => DBInit().database;

  ///
  ///  Helper 的相关方法
  ///

  ///***********************************************/
  /// 2025-02-14 简洁版本的 自定义的LLM信息管理
  ///

  // 查询所有模型信息
  Future<List<CusBriefLLMSpec>> queryBriefCusLLMSpecList({
    String? cusLlmSpecId, // 模型规格编号
    ApiPlatform? platform, // 平台
    String? name, // 模型名称
    LLModelType? modelType, // 模型分类枚举
    bool? isFree, // 是否收费(0要收费，1不收费)
    bool? isBuiltin, // 是否内置(0不是，1是)
  }) async {
    Database db = await database;

    // print("模型规格查询参数：");
    // print("uuid $cusLlmSpecId");
    // print("平台 $platform");
    // print("cusLlm $cusLlm");
    // print("name $name");
    // print("modelType $modelType");
    // print("isFree $isFree");

    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (cusLlmSpecId != null) {
      where.add('cusLlmSpecId = ?');
      whereArgs.add(cusLlmSpecId);
    }

    if (platform != null) {
      where.add('platform = ?');
      whereArgs.add(platform.toString());
    }
    if (name != null) {
      where.add('name = ?');
      whereArgs.add(name);
    }
    if (modelType != null) {
      where.add('modelType = ?');
      whereArgs.add(modelType.toString());
    }

    if (cusLlmSpecId != null) {
      where.add('isFree = ?');
      whereArgs.add(isFree == true ? 1 : 0);
    }

    if (isBuiltin != null) {
      where.add('isBuiltin = ?');
      whereArgs.add(isBuiltin == true ? 1 : 0);
    }

    final rows = await db.query(
      BriefAIToolDdl.tableNameOfCusBriefLlmSpec,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: "gmtCreate DESC",
    );

    return rows.map((row) => CusBriefLLMSpec.fromMap(row)).toList();
  }

  // 删除单条
  Future<int> deleteBriefCusLLMSpecById(String cusLlmSpecId) async =>
      (await database).delete(
        BriefAIToolDdl.tableNameOfCusBriefLlmSpec,
        where: "cusLlmSpecId = ?",
        whereArgs: [cusLlmSpecId],
      );

  // 清空所有模型信息
  Future<int> clearBriefCusLLMSpecs() async => (await database).delete(
    BriefAIToolDdl.tableNameOfCusBriefLlmSpec,
    where: "cusLlmSpecId != ?",
    whereArgs: ["cusLlmSpecId"],
  );

  // 新增
  Future<List<Object?>> insertBriefCusLLMSpecList(
    List<CusBriefLLMSpec> rsts,
  ) async {
    var batch = (await database).batch();
    for (var item in rsts) {
      batch.insert(BriefAIToolDdl.tableNameOfCusBriefLlmSpec, item.toMap());
    }
    return await batch.commit();
  }

  ///***********************************************/
  /// AI 媒体资源生成的相关操作
  /// 文生视频（后续语音合成也可能）也用这个
  ///

  // 插入媒体资源生成历史
  Future<String> insertMediaGenerationHistory(
    MediaGenerationHistory history,
  ) async {
    Database db = await database;
    await db.insert(
      BriefAIToolDdl.tableNameOfMediaGenerationHistory,
      history.toMap(),
    );
    return history.requestId;
  }

  // 批量插入媒体资源生成记录
  Future<List<Object?>> insertMediaGenerationHistoryList(
    List<MediaGenerationHistory> histories,
  ) async {
    var batch = (await database).batch();
    for (var item in histories) {
      batch.insert(
        BriefAIToolDdl.tableNameOfMediaGenerationHistory,
        item.toMap(),
      );
    }
    return await batch.commit();
  }

  // 指定requestId更新媒体资源生成历史
  Future<void> updateMediaGenerationHistoryByRequestId(
    String requestId,
    Map<String, dynamic> values,
  ) async {
    Database db = await database;
    await db.update(
      BriefAIToolDdl.tableNameOfMediaGenerationHistory,
      values,
      where: 'requestId = ?',
      whereArgs: [requestId],
    );
  }

  // 实例更新媒体资源生成历史
  Future<void> updateMediaGenerationHistory(MediaGenerationHistory item) async {
    Database db = await database;
    await db.update(
      BriefAIToolDdl.tableNameOfMediaGenerationHistory,
      item.toMap(),
      where: 'requestId = ?',
      whereArgs: [item.requestId],
    );
  }

  // 指定requestId删除媒体资源生成历史
  Future<void> deleteMediaGenerationHistoryByRequestId(String requestId) async {
    Database db = await database;
    await db.delete(
      BriefAIToolDdl.tableNameOfMediaGenerationHistory,
      where: 'requestId = ?',
      whereArgs: [requestId],
    );
  }

  // 查询媒体资源生成历史
  Future<List<MediaGenerationHistory>> queryMediaGenerationHistory({
    bool? isSuccess,
    bool? isProcessing,
    bool? isFailed,
    List<LLModelType>? modelTypes, // 在调用处取枚举，可多个
  }) async {
    Database db = await database;

    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (isSuccess != null) {
      where.add('isSuccess = ?');
      whereArgs.add(isSuccess ? 1 : 0);
    }

    if (isProcessing != null) {
      where.add('isProcessing = ?');
      whereArgs.add(isProcessing ? 1 : 0);
    }

    if (isFailed != null) {
      where.add('isFailed = ?');
      whereArgs.add(isFailed ? 1 : 0);
    }

    if (modelTypes != null && modelTypes.isNotEmpty) {
      where.add(
        'modelType IN (${List.filled(modelTypes.length, '?').join(',')})',
      );
      whereArgs.addAll(modelTypes.map((e) => e.toString()));
    }

    final rows = await db.query(
      BriefAIToolDdl.tableNameOfMediaGenerationHistory,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'gmtCreate DESC',
    );

    return rows.map((row) => MediaGenerationHistory.fromMap(row)).toList();
  }

  ///***********************************************/
  /// 录音识别任务相关操作
  ///

  /// 保存录音识别任务到数据库
  Future<void> insertVoiceRecognitionTask(VoiceRecognitionTaskInfo task) async {
    Database db = await database;
    await db.insert(
      BriefAIToolDdl.tableNameOfVoiceRecognitionTask,
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // 如果已存在则替换
    );
  }

  /// 批量保存录音识别任务到数据库
  Future<void> insertVoiceRecognitionTasks(
    List<VoiceRecognitionTaskInfo> tasks,
  ) async {
    Database db = await database;

    // 使用事务操作批量插入
    await db.transaction((txn) async {
      for (var task in tasks) {
        await txn.insert(
          BriefAIToolDdl.tableNameOfVoiceRecognitionTask,
          task.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// 更新录音识别任务
  Future<void> updateVoiceRecognitionTask(VoiceRecognitionTaskInfo task) async {
    Database db = await database;
    await db.update(
      BriefAIToolDdl.tableNameOfVoiceRecognitionTask,
      task.toMap(),
      where: 'taskId = ?',
      whereArgs: [task.taskId],
    );
  }

  /// 删除录音识别任务
  Future<void> deleteVoiceRecognitionTask(String taskId) async {
    Database db = await database;
    await db.delete(
      BriefAIToolDdl.tableNameOfVoiceRecognitionTask,
      where: 'taskId = ?',
      whereArgs: [taskId],
    );
  }

  /// 获取所有录音识别任务
  Future<List<VoiceRecognitionTaskInfo>> getAllVoiceRecognitionTasks() async {
    Database db = await database;
    final rows = await db.query(
      BriefAIToolDdl.tableNameOfVoiceRecognitionTask,
      orderBy: 'gmtCreate DESC', // 按创建时间降序排序
    );

    return rows.map((row) => VoiceRecognitionTaskInfo.fromMap(row)).toList();
  }

  /// 根据任务ID获取录音识别任务
  Future<VoiceRecognitionTaskInfo?> getVoiceRecognitionTaskById(
    String taskId,
  ) async {
    Database db = await database;
    final rows = await db.query(
      BriefAIToolDdl.tableNameOfVoiceRecognitionTask,
      where: 'taskId = ?',
      whereArgs: [taskId],
    );

    if (rows.isEmpty) {
      return null;
    }

    return VoiceRecognitionTaskInfo.fromMap(rows.first);
  }

  /// 根据任务状态获取录音识别任务
  Future<List<VoiceRecognitionTaskInfo>> getVoiceRecognitionTasksByStatus(
    String status,
  ) async {
    Database db = await database;
    final rows = await db.query(
      BriefAIToolDdl.tableNameOfVoiceRecognitionTask,
      where: 'taskStatus = ?',
      whereArgs: [status],
      orderBy: 'gmtCreate DESC',
    );

    return rows.map((row) => VoiceRecognitionTaskInfo.fromMap(row)).toList();
  }
}
