import 'package:sqflite/sqflite.dart';

import '../../../core/storage/db_init.dart';
import '../../../core/storage/diet_diary_ddl.dart';
import '../domain/entities/weight_record.dart';

class WeightRecordDao {
  // 单例模式
  static final WeightRecordDao _dbHelper = WeightRecordDao._createInstance();
  // 构造函数，返回单例
  factory WeightRecordDao() => _dbHelper;

  // 命名的构造函数用于创建DatabaseHelper的实例
  WeightRecordDao._createInstance();

  // 获取数据库实例(每次操作都从 DBInit 获取，不缓存)
  Future<Database> get database async => DBInit().database;

  Future<int> insert(WeightRecord weightRecord) async {
    final db = await database;
    return await db.insert(
      DietDiaryDdl.tableWeightRecord,
      weightRecord.toMap(),
    );
  }

  Future<List<int>> batchInsert(List<WeightRecord> items) async {
    final db = await database;
    final batch = db.batch();

    for (var item in items) {
      batch.insert(
        DietDiaryDdl.tableWeightRecord,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final results = await batch.commit();
    return results.cast<int>();
  }

  Future<int> update(WeightRecord weightRecord) async {
    final db = await database;
    return await db.update(
      DietDiaryDdl.tableWeightRecord,
      weightRecord.toMap(),
      where: 'id = ?',
      whereArgs: [weightRecord.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await database;
    return await db.delete(
      DietDiaryDdl.tableWeightRecord,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<WeightRecord?> getById(int id) async {
    final db = await database;
    final maps = await db.query(
      DietDiaryDdl.tableWeightRecord,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return WeightRecord.fromMap(maps.first);
    }
    return null;
  }

  Future<List<WeightRecord>> getByUserId(int userId) async {
    final db = await database;
    final maps = await db.query(
      DietDiaryDdl.tableWeightRecord,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) => WeightRecord.fromMap(maps[i]));
  }

  Future<List<WeightRecord>> getByDateRange(
    int userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final maps = await db.query(
      DietDiaryDdl.tableWeightRecord,
      where: 'userId = ? AND date BETWEEN ? AND ?',
      whereArgs: [
        userId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'date ASC',
    );

    return List.generate(maps.length, (i) => WeightRecord.fromMap(maps[i]));
  }

  Future<WeightRecord?> getLatest(int userId) async {
    final db = await database;
    final maps = await db.query(
      DietDiaryDdl.tableWeightRecord,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return WeightRecord.fromMap(maps.first);
    }
    return null;
  }
}
