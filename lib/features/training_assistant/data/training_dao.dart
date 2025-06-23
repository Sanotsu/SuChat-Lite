import 'package:sqflite/sqflite.dart';

import '../../../../core/storage/db_init.dart';
import '../../../core/storage/ddl_training.dart';
import '../domain/entities/index.dart';

class TrainingDao {
  static final TrainingDao _dao = TrainingDao._createInstance();
  factory TrainingDao() => _dao;
  TrainingDao._createInstance();

  final dbInit = DBInit();

  ///***********************************************/
  /// 训练助手 - 训练计划相关操作
  ///

  /// 保存训练计划
  Future<void> insertTrainingPlans(List<TrainingPlan> plans) async {
    final db = await dbInit.database;
    await db.transaction((txn) async {
      for (var plan in plans) {
        await txn.insert(
          TrainingDdl.tableTrainingPlan,
          plan.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// 更新训练计划
  Future<void> updateTrainingPlan(TrainingPlan plan) async {
    final db = await dbInit.database;
    await db.update(
      TrainingDdl.tableTrainingPlan,
      plan.toMap(),
      where: 'planId = ?',
      whereArgs: [plan.planId],
    );
  }

  /// 获取特定训练计划
  Future<TrainingPlan?> getTrainingPlan(String planId) async {
    final db = await dbInit.database;
    final List<Map<String, dynamic>> maps = await db.query(
      TrainingDdl.tableTrainingPlan,
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
    final db = await dbInit.database;
    final List<Map<String, dynamic>> maps = await db.query(
      TrainingDdl.tableTrainingPlan,
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
    final db = await dbInit.database;
    final List<Map<String, dynamic>> maps = await db.query(
      TrainingDdl.tableTrainingPlan,
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
    final db = await dbInit.database;
    await db.transaction((txn) async {
      // 删除计划详情
      await txn.delete(
        TrainingDdl.tableTrainingPlanDetail,
        where: 'planId = ?',
        whereArgs: [planId],
      );

      // 删除训练记录
      await txn.delete(
        TrainingDdl.tableTrainingRecord,
        where: 'planId = ?',
        whereArgs: [planId],
      );

      // 删除计划本身
      await txn.delete(
        TrainingDdl.tableTrainingPlan,
        where: 'planId = ?',
        whereArgs: [planId],
      );
    });
  }

  ///***********************************************/
  /// 训练助手 - 训练计划详情相关操作
  ///

  /// 批量保存训练计划详情
  Future<void> insertTrainingPlanDetails(
    List<TrainingPlanDetail> details,
  ) async {
    final db = await dbInit.database;
    await db.transaction((txn) async {
      for (var detail in details) {
        await txn.insert(
          TrainingDdl.tableTrainingPlanDetail,
          detail.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// 获取训练计划的所有详情
  Future<List<TrainingPlanDetail>> getTrainingPlanDetails(String planId) async {
    final db = await dbInit.database;
    final List<Map<String, dynamic>> maps = await db.query(
      TrainingDdl.tableTrainingPlanDetail,
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
    final db = await dbInit.database;
    final List<Map<String, dynamic>> maps = await db.query(
      TrainingDdl.tableTrainingPlanDetail,
      where: 'planId = ? AND day = ?',
      whereArgs: [planId, day],
    );

    return List.generate(maps.length, (i) {
      return TrainingPlanDetail.fromMap(maps[i]);
    });
  }

  /// 删除训练计划详情
  Future<void> deleteTrainingPlanDetail(String detailId) async {
    final db = await dbInit.database;
    await db.delete(
      TrainingDdl.tableTrainingPlanDetail,
      where: 'detailId = ?',
      whereArgs: [detailId],
    );
  }

  /// 删除训练计划的所有详情
  Future<void> deleteAllTrainingPlanDetails(String planId) async {
    final db = await dbInit.database;
    await db.delete(
      TrainingDdl.tableTrainingPlanDetail,
      where: 'planId = ?',
      whereArgs: [planId],
    );
  }

  ///***********************************************/
  /// 训练助手 - 训练记录相关操作
  ///

  /// 保存训练记录
  Future<void> insertTrainingRecords(List<TrainingRecord> records) async {
    final db = await dbInit.database;
    await db.transaction((txn) async {
      for (var record in records) {
        await txn.insert(
          TrainingDdl.tableTrainingRecord,
          record.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// 获取特定训练记录
  Future<TrainingRecord?> getTrainingRecord(String recordId) async {
    final db = await dbInit.database;
    final List<Map<String, dynamic>> maps = await db.query(
      TrainingDdl.tableTrainingRecord,
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
    final db = await dbInit.database;
    final List<Map<String, dynamic>> maps = await db.query(
      TrainingDdl.tableTrainingRecord,
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
    final db = await dbInit.database;
    final List<Map<String, dynamic>> maps = await db.query(
      TrainingDdl.tableTrainingRecord,
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
    final db = await dbInit.database;
    final List<Map<String, dynamic>> maps = await db.query(
      TrainingDdl.tableTrainingRecord,
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
    final db = await dbInit.database;
    await db.delete(
      TrainingDdl.tableTrainingRecord,
      where: 'recordId = ?',
      whereArgs: [recordId],
    );
  }

  /// 删除训练计划的所有记录
  Future<void> deleteAllTrainingRecordsForPlan(String planId) async {
    final db = await dbInit.database;
    await db.delete(
      TrainingDdl.tableTrainingRecord,
      where: 'planId = ?',
      whereArgs: [planId],
    );
  }

  /// 保存训练记录详情
  Future<void> insertTrainingRecordDetails(
    List<TrainingRecordDetail> details,
  ) async {
    final db = await dbInit.database;
    await db.transaction((txn) async {
      for (var detail in details) {
        await txn.insert(
          TrainingDdl.tableTrainingRecordDetail,
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
    final db = await dbInit.database;
    final List<Map<String, dynamic>> maps = await db.query(
      TrainingDdl.tableTrainingRecordDetail,
      where: 'recordId = ?',
      whereArgs: [recordId],
    );

    return List.generate(maps.length, (i) {
      return TrainingRecordDetail.fromMap(maps[i]);
    });
  }
}
