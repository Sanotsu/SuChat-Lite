import 'package:sqflite/sqflite.dart';

import '../../../core/storage/db_init.dart';
import '../../../core/storage/ddl_diet_diary.dart';
import '../domain/entities/weight_record.dart';

class WeightRecordDao {
  static final WeightRecordDao _dao = WeightRecordDao._createInstance();
  factory WeightRecordDao() => _dao;
  WeightRecordDao._createInstance();

  final dbInit = DBInit();

  Future<int> insert(WeightRecord weightRecord) async {
    final db = await dbInit.database;
    return await db.insert(
      DietDiaryDdl.tableWeightRecord,
      weightRecord.toMap(),
    );
  }

  Future<List<int>> batchInsert(List<WeightRecord> items) async {
    final db = await dbInit.database;
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
    final db = await dbInit.database;
    return await db.update(
      DietDiaryDdl.tableWeightRecord,
      weightRecord.toMap(),
      where: 'id = ?',
      whereArgs: [weightRecord.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await dbInit.database;
    return await db.delete(
      DietDiaryDdl.tableWeightRecord,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<WeightRecord?> getById(int id) async {
    final db = await dbInit.database;
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

  Future<List<WeightRecord>> getByUserId(String userId) async {
    final db = await dbInit.database;
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
    final db = await dbInit.database;
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
    final db = await dbInit.database;
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
