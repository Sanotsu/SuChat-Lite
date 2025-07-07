import 'package:sqflite/sqflite.dart';

import '../../features/media_generation/common/entities/media_generation_history.dart';
import '../../features/voice_recognition/domain/entities/voice_recognition_task_info.dart';
import '../../shared/constants/constant_llm_enum.dart';
import '../entities/cus_llm_model.dart';
import '../entities/user_info.dart';
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
  /// 统一用户信息表操作
  /// 合并了训练助手和饮食日记的用户信息
  ///

  // 获取用户信息，如果不存在则创建默认用户
  Future<UserInfo> getUserInfo({String? userId}) async {
    Database db = await database;

    // 如果没有指定userId，获取第一个用户
    if (userId == null) {
      final users = await db.query(DBDdl.tableUserInfo);
      if (users.isNotEmpty) {
        return UserInfo.fromMap(users.first);
      } else {
        // 创建默认用户
        final defaultUser = UserInfo.createDefault();
        await saveUserInfo(defaultUser);
        return defaultUser;
      }
    }

    // 查询指定userId的用户
    final users = await db.query(
      DBDdl.tableUserInfo,
      where: 'userId = ?',
      whereArgs: [userId],
    );

    if (users.isNotEmpty) {
      return UserInfo.fromMap(users.first);
    } else {
      // 创建指定ID的默认用户
      final defaultUser = UserInfo.createDefault(userId: userId);
      await saveUserInfo(defaultUser);
      return defaultUser;
    }
  }

  // 获取所有用户
  Future<List<UserInfo>> getAllUsers() async {
    Database db = await database;
    final users = await db.query(DBDdl.tableUserInfo, orderBy: 'name ASC');
    return users.map((user) => UserInfo.fromMap(user)).toList();
  }

  // 保存用户信息（新增或更新）
  Future<void> saveUserInfo(UserInfo userInfo) async {
    Database db = await database;

    // 检查用户是否已存在
    final existingUsers = await db.query(
      DBDdl.tableUserInfo,
      where: 'userId = ?',
      whereArgs: [userInfo.userId],
    );

    if (existingUsers.isEmpty) {
      // 新增用户
      await db.insert(DBDdl.tableUserInfo, userInfo.toMap());
    } else {
      // 更新用户
      await db.update(
        DBDdl.tableUserInfo,
        userInfo.toMap(),
        where: 'userId = ?',
        whereArgs: [userInfo.userId],
      );
    }
  }

  Future<List<int>> batchInsert(List<UserInfo> items) async {
    Database db = await database;
    final batch = db.batch();

    for (var item in items) {
      batch.insert(
        DBDdl.tableUserInfo,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final results = await batch.commit();
    return results.cast<int>();
  }

  // 删除用户
  Future<void> deleteUserInfo(String userId) async {
    Database db = await database;
    await db.delete(
      DBDdl.tableUserInfo,
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<UserInfo?> getById(String userId) async {
    Database db = await database;
    final maps = await db.query(
      DBDdl.tableUserInfo,
      where: 'userId = ?',
      whereArgs: [userId],
    );

    if (maps.isEmpty) {
      return null;
    }

    return UserInfo.fromMap(maps.first);
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
}
