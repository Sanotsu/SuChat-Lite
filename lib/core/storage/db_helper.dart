import 'package:sqflite/sqflite.dart';

import '../../features/media_generation/common/entities/media_generation_history.dart';
import '../../features/voice_recognition/domain/entities/voice_recognition_task_info.dart';
import '../../features/training_assistant/domain/entities/training_user_info.dart';
import '../../features/training_assistant/domain/entities/training_plan.dart';
import '../../features/training_assistant/domain/entities/training_plan_detail.dart';
import '../../features/training_assistant/domain/entities/training_record.dart';
import '../../features/training_assistant/domain/entities/training_record_detail.dart';
import '../../shared/constants/constant_llm_enum.dart';
import '../entities/cus_llm_model.dart';
import 'db_init.dart';
import 'db_ddl.dart';

///
/// 数据库操作
///
class DBHelper {
  // 单例模式
  static final DBHelper _dbHelper = DBHelper._createInstance();
  // 构造函数，返回单例
  factory DBHelper() => _dbHelper;

  // 命名的构造函数用于创建DatabaseHelper的实例
  DBHelper._createInstance();

  // 获取数据库实例(每次操作都从 DBInit 获取，不缓存)
  Future<Database> get database async => DBInit().database;

  ///
  ///  Helper 的相关方法
  ///

  ///***********************************************/
  /// 2025-02-14 简洁版本的 自定义的LLM信息管理
  ///

  // 查询所有模型信息
  Future<List<CusLLMSpec>> queryCusLLMSpecList({
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
      DBDdl.tableCusLlmSpec,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: "gmtCreate DESC",
    );

    return rows.map((row) => CusLLMSpec.fromMap(row)).toList();
  }

  // 删除单条
  Future<int> deleteCusLLMSpecById(String cusLlmSpecId) async =>
      (await database).delete(
        DBDdl.tableCusLlmSpec,
        where: "cusLlmSpecId = ?",
        whereArgs: [cusLlmSpecId],
      );

  // 清空所有模型信息
  Future<int> clearCusLLMSpecs() async => (await database).delete(
    DBDdl.tableCusLlmSpec,
    where: "cusLlmSpecId != ?",
    whereArgs: ["cusLlmSpecId"],
  );

  // 新增
  Future<List<Object?>> saveCusLLMSpecs(List<CusLLMSpec> rsts) async {
    var batch = (await database).batch();
    for (var item in rsts) {
      batch.insert(DBDdl.tableCusLlmSpec, item.toMap());
    }
    return await batch.commit();
  }

  ///***********************************************/
  /// AI 媒体资源生成的相关操作
  /// 文生视频（后续语音合成也可能）也用这个
  ///

  // 插入媒体资源生成历史
  Future<String> saveMediaGenerationHistory(
    MediaGenerationHistory history,
  ) async {
    Database db = await database;
    await db.insert(DBDdl.tableMediaGenerationHistory, history.toMap());
    return history.requestId;
  }

  // 批量插入媒体资源生成记录
  Future<List<Object?>> saveMediaGenerationHistories(
    List<MediaGenerationHistory> histories,
  ) async {
    var batch = (await database).batch();
    for (var item in histories) {
      batch.insert(DBDdl.tableMediaGenerationHistory, item.toMap());
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
      DBDdl.tableMediaGenerationHistory,
      values,
      where: 'requestId = ?',
      whereArgs: [requestId],
    );
  }

  // 实例更新媒体资源生成历史
  Future<void> updateMediaGenerationHistory(MediaGenerationHistory item) async {
    Database db = await database;
    await db.update(
      DBDdl.tableMediaGenerationHistory,
      item.toMap(),
      where: 'requestId = ?',
      whereArgs: [item.requestId],
    );
  }

  // 指定requestId删除媒体资源生成历史
  Future<void> deleteMediaGenerationHistoryByRequestId(String requestId) async {
    Database db = await database;
    await db.delete(
      DBDdl.tableMediaGenerationHistory,
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
      DBDdl.tableMediaGenerationHistory,
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
  Future<void> saveVoiceRecognitionTask(VoiceRecognitionTaskInfo task) async {
    Database db = await database;
    await db.insert(
      DBDdl.tableVoiceRecognitionTask,
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // 如果已存在则替换
    );
  }

  /// 批量保存录音识别任务到数据库
  Future<void> saveVoiceRecognitionTasks(
    List<VoiceRecognitionTaskInfo> tasks,
  ) async {
    Database db = await database;

    // 使用事务操作批量插入
    await db.transaction((txn) async {
      for (var task in tasks) {
        await txn.insert(
          DBDdl.tableVoiceRecognitionTask,
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
      DBDdl.tableVoiceRecognitionTask,
      task.toMap(),
      where: 'taskId = ?',
      whereArgs: [task.taskId],
    );
  }

  /// 删除录音识别任务
  Future<void> deleteVoiceRecognitionTask(String taskId) async {
    Database db = await database;
    await db.delete(
      DBDdl.tableVoiceRecognitionTask,
      where: 'taskId = ?',
      whereArgs: [taskId],
    );
  }

  /// 获取所有录音识别任务
  Future<List<VoiceRecognitionTaskInfo>> getAllVoiceRecognitionTasks() async {
    Database db = await database;
    final rows = await db.query(
      DBDdl.tableVoiceRecognitionTask,
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
      DBDdl.tableVoiceRecognitionTask,
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
      DBDdl.tableVoiceRecognitionTask,
      where: 'taskStatus = ?',
      whereArgs: [status],
      orderBy: 'gmtCreate DESC',
    );

    return rows.map((row) => VoiceRecognitionTaskInfo.fromMap(row)).toList();
  }

  ///***********************************************/
  /// 训练助手 - 用户信息相关操作
  ///

  /// 保存用户信息(可多个)
  Future<void> saveTrainingUsers(List<TrainingUserInfo> users) async {
    Database db = await database;
    await db.transaction((txn) async {
      for (var user in users) {
        await txn.insert(
          DBDdl.tableTrainingUserInfo,
          user.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// 更新用户信息
  Future<void> updateTrainingUserInfo(TrainingUserInfo userInfo) async {
    Database db = await database;
    await db.update(
      DBDdl.tableTrainingUserInfo,
      userInfo.toMap(),
      where: 'userId = ?',
      whereArgs: [userInfo.userId],
    );
  }

  /// 获取用户信息
  Future<TrainingUserInfo?> getTrainingUserInfo(String userId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DBDdl.tableTrainingUserInfo,
      where: 'userId = ?',
      whereArgs: [userId],
    );

    if (maps.isEmpty) {
      return null;
    }

    return TrainingUserInfo.fromMap(maps.first);
  }

  /// 获取所有用户信息
  Future<List<TrainingUserInfo>> getAllTrainingUserInfo() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DBDdl.tableTrainingUserInfo,
      orderBy: 'gmtCreate DESC',
    );

    return List.generate(maps.length, (i) {
      return TrainingUserInfo.fromMap(maps[i]);
    });
  }

  /// 删除用户信息
  Future<void> deleteTrainingUserInfo(String userId) async {
    Database db = await database;
    await db.delete(
      DBDdl.tableTrainingUserInfo,
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  ///***********************************************/
  /// 训练助手 - 训练计划相关操作
  ///

  /// 保存训练计划
  Future<void> saveTrainingPlans(List<TrainingPlan> plans) async {
    Database db = await database;
    await db.transaction((txn) async {
      for (var plan in plans) {
        await txn.insert(
          DBDdl.tableTrainingPlan,
          plan.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// 更新训练计划
  Future<void> updateTrainingPlan(TrainingPlan plan) async {
    Database db = await database;
    await db.update(
      DBDdl.tableTrainingPlan,
      plan.toMap(),
      where: 'planId = ?',
      whereArgs: [plan.planId],
    );
  }

  /// 获取特定训练计划
  Future<TrainingPlan?> getTrainingPlan(String planId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DBDdl.tableTrainingPlan,
      where: 'planId = ?',
      whereArgs: [planId],
    );

    if (maps.isEmpty) {
      return null;
    }

    return TrainingPlan.fromMap(maps.first);
  }

  /// 获取用户的所有训练计划
  Future<List<TrainingPlan>> getUserTrainingPlans(String userId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DBDdl.tableTrainingPlan,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'gmtCreate DESC',
    );

    return List.generate(maps.length, (i) {
      return TrainingPlan.fromMap(maps[i]);
    });
  }

  /// 获取用户的活跃训练计划
  Future<List<TrainingPlan>> getUserActiveTrainingPlans(String userId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DBDdl.tableTrainingPlan,
      where: 'userId = ? AND isActive = ?',
      whereArgs: [userId, 1],
      orderBy: 'gmtCreate DESC',
    );

    return List.generate(maps.length, (i) {
      return TrainingPlan.fromMap(maps[i]);
    });
  }

  /// 删除训练计划
  Future<void> deleteTrainingPlan(String planId) async {
    Database db = await database;
    await db.transaction((txn) async {
      // 删除计划详情
      await txn.delete(
        DBDdl.tableTrainingPlanDetail,
        where: 'planId = ?',
        whereArgs: [planId],
      );

      // 删除训练记录
      await txn.delete(
        DBDdl.tableTrainingRecord,
        where: 'planId = ?',
        whereArgs: [planId],
      );

      // 删除计划本身
      await txn.delete(
        DBDdl.tableTrainingPlan,
        where: 'planId = ?',
        whereArgs: [planId],
      );
    });
  }

  ///***********************************************/
  /// 训练助手 - 训练计划详情相关操作
  ///

  /// 批量保存训练计划详情
  Future<void> saveTrainingPlanDetails(List<TrainingPlanDetail> details) async {
    Database db = await database;
    await db.transaction((txn) async {
      for (var detail in details) {
        await txn.insert(
          DBDdl.tableTrainingPlanDetail,
          detail.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// 获取训练计划的所有详情
  Future<List<TrainingPlanDetail>> getTrainingPlanDetails(String planId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DBDdl.tableTrainingPlanDetail,
      where: 'planId = ?',
      whereArgs: [planId],
      orderBy: 'day ASC',
    );

    return List.generate(maps.length, (i) {
      return TrainingPlanDetail.fromMap(maps[i]);
    });
  }

  /// 获取训练计划特定天的详情
  Future<List<TrainingPlanDetail>> getTrainingPlanDetailsForDay(
    String planId,
    int day,
  ) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DBDdl.tableTrainingPlanDetail,
      where: 'planId = ? AND day = ?',
      whereArgs: [planId, day],
    );

    return List.generate(maps.length, (i) {
      return TrainingPlanDetail.fromMap(maps[i]);
    });
  }

  /// 删除训练计划详情
  Future<void> deleteTrainingPlanDetail(String detailId) async {
    Database db = await database;
    await db.delete(
      DBDdl.tableTrainingPlanDetail,
      where: 'detailId = ?',
      whereArgs: [detailId],
    );
  }

  /// 删除训练计划的所有详情
  Future<void> deleteAllTrainingPlanDetails(String planId) async {
    Database db = await database;
    await db.delete(
      DBDdl.tableTrainingPlanDetail,
      where: 'planId = ?',
      whereArgs: [planId],
    );
  }

  ///***********************************************/
  /// 训练助手 - 训练记录相关操作
  ///

  /// 保存训练记录
  Future<void> saveTrainingRecords(List<TrainingRecord> records) async {
    Database db = await database;
    await db.transaction((txn) async {
      for (var record in records) {
        await txn.insert(
          DBDdl.tableTrainingRecord,
          record.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// 获取特定训练记录
  Future<TrainingRecord?> getTrainingRecord(String recordId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DBDdl.tableTrainingRecord,
      where: 'recordId = ?',
      whereArgs: [recordId],
    );

    if (maps.isEmpty) {
      return null;
    }

    return TrainingRecord.fromMap(maps.first);
  }

  /// 获取训练计划的所有记录
  Future<List<TrainingRecord>> getTrainingRecordsForPlan(String planId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DBDdl.tableTrainingRecord,
      where: 'planId = ?',
      whereArgs: [planId],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return TrainingRecord.fromMap(maps[i]);
    });
  }

  /// 获取用户的所有训练记录
  Future<List<TrainingRecord>> getUserTrainingRecords(String userId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DBDdl.tableTrainingRecord,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return TrainingRecord.fromMap(maps[i]);
    });
  }

  /// 获取用户在特定日期范围内的训练记录
  Future<List<TrainingRecord>> getUserTrainingRecordsInDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DBDdl.tableTrainingRecord,
      where: 'userId = ? AND date >= ? AND date <= ?',
      whereArgs: [
        userId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return TrainingRecord.fromMap(maps[i]);
    });
  }

  /// 删除训练记录
  Future<void> deleteTrainingRecord(String recordId) async {
    Database db = await database;
    await db.delete(
      DBDdl.tableTrainingRecord,
      where: 'recordId = ?',
      whereArgs: [recordId],
    );
  }

  /// 删除训练计划的所有记录
  Future<void> deleteAllTrainingRecordsForPlan(String planId) async {
    Database db = await database;
    await db.delete(
      DBDdl.tableTrainingRecord,
      where: 'planId = ?',
      whereArgs: [planId],
    );
  }

  /// 保存训练记录详情
  Future<void> saveTrainingRecordDetails(
    List<TrainingRecordDetail> details,
  ) async {
    Database db = await database;
    await db.transaction((txn) async {
      for (var detail in details) {
        await txn.insert(
          DBDdl.tableTrainingRecordDetail,
          detail.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// 获取训练记录详情
  Future<List<TrainingRecordDetail>> getTrainingRecordDetails(
    String recordId,
  ) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DBDdl.tableTrainingRecordDetail,
      where: 'recordId = ?',
      whereArgs: [recordId],
    );

    return List.generate(maps.length, (i) {
      return TrainingRecordDetail.fromMap(maps[i]);
    });
  }
}
