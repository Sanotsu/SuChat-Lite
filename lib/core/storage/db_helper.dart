import 'package:sqflite/sqflite.dart';

import '../entities/user_info.dart';
import '../../features/voice_recognition/domain/entities/voice_recognition_task_info.dart';
import 'db_init.dart';
import 'db_ddl.dart';

///
/// 数据库操作
/// 2026-09-07 LLM旧体系退役：cus_llm_spec 与 media_generation_history 两死表
/// 相关方法删除(查询/写入路径已随旧体系消失，主库不再建表，残留表无害)
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
