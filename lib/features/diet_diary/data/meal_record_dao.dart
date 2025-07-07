import 'package:sqflite/sqflite.dart';

import '../../../core/storage/db_init.dart';
import '../../../core/storage/ddl_diet_diary.dart';
import '../domain/entities/meal_record.dart';
import '../domain/entities/meal_type.dart';

class MealRecordDao {
  static final MealRecordDao _dao = MealRecordDao._createInstance();
  factory MealRecordDao() => _dao;
  MealRecordDao._createInstance();

  final dbInit = DBInit();

  ///***********************************************/
  /// 餐次记录相关方法
  ///
  ///

  Future<int> insert(MealRecord mealRecord) async {
    final db = await dbInit.database;
    return await db.insert(
      DietDiaryDdl.tableMealRecord,
      mealRecord.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<int>> batchInsert(List<MealRecord> items) async {
    final db = await dbInit.database;
    final batch = db.batch();

    for (var item in items) {
      batch.insert(
        DietDiaryDdl.tableMealRecord,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final results = await batch.commit();
    return results.cast<int>();
  }

  Future<int> update(MealRecord mealRecord) async {
    final db = await dbInit.database;
    return await db.update(
      DietDiaryDdl.tableMealRecord,
      mealRecord.toMap(),
      where: 'id = ?',
      whereArgs: [mealRecord.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await dbInit.database;

    // 删除关联的餐次食品记录
    await db.delete(
      DietDiaryDdl.tableMealFoodRecord,
      where: 'mealRecordId = ?',
      whereArgs: [id],
    );

    // 删除餐次记录
    return await db.delete(
      DietDiaryDdl.tableMealRecord,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<MealRecord?> getById(int id) async {
    final db = await dbInit.database;
    final maps = await db.query(
      DietDiaryDdl.tableMealRecord,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return MealRecord.fromMap(maps.first);
  }

  Future<List<MealRecord>> getByDate(DateTime date) async {
    final db = await dbInit.database;
    final dateString = date.toIso8601String().split('T')[0];

    final result = await db.query(
      DietDiaryDdl.tableMealRecord,
      where: 'date = ?',
      whereArgs: [dateString],
      orderBy: 'mealType ASC',
    );

    return result.map((map) => MealRecord.fromMap(map)).toList();
  }

  Future<MealRecord?> getByDateAndType(DateTime date, MealType mealType) async {
    final db = await dbInit.database;
    final dateString = date.toIso8601String().split('T')[0];

    final result = await db.query(
      DietDiaryDdl.tableMealRecord,
      where: 'date = ? AND mealType = ?',
      whereArgs: [dateString, mealType.index],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return MealRecord.fromMap(result.first);
  }

  // 获取或创建指定日期和类型的餐次记录
  Future<MealRecord> getOrCreateByDateAndType(
    DateTime date,
    MealType mealType,
  ) async {
    final existing = await getByDateAndType(date, mealType);

    if (existing != null) {
      return existing;
    }

    // 创建新的餐次记录
    final newMealRecord = MealRecord(date: date, mealType: mealType);

    final id = await insert(newMealRecord);
    return newMealRecord.copyWith(id: id);
  }

  // 获取日期范围内的所有餐次记录
  Future<List<MealRecord>> getByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await dbInit.database;
    final startDateString = startDate.toIso8601String().split('T')[0];
    final endDateString = endDate.toIso8601String().split('T')[0];

    final result = await db.query(
      DietDiaryDdl.tableMealRecord,
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDateString, endDateString],
      orderBy: 'date ASC, mealType ASC',
    );

    return result.map((map) => MealRecord.fromMap(map)).toList();
  }
}
