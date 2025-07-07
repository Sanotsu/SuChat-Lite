import 'package:sqflite/sqflite.dart';

import '../../../core/storage/db_init.dart';
import '../../../core/storage/ddl_diet_diary.dart';
import '../domain/entities/diet_recipe.dart';

class DietRecipeDao {
  static final DietRecipeDao _dao = DietRecipeDao._createInstance();
  factory DietRecipeDao() => _dao;
  DietRecipeDao._createInstance();

  final dbInit = DBInit();

  // 插入食谱
  Future<int> insert(DietRecipe recipe) async {
    final db = await dbInit.database;
    return await db.insert(
      DietDiaryDdl.tableDietRecipe,
      recipe.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<int>> batchInsert(List<DietRecipe> items) async {
    final db = await dbInit.database;
    final batch = db.batch();

    for (var item in items) {
      batch.insert(
        DietDiaryDdl.tableDietRecipe,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final results = await batch.commit();
    return results.cast<int>();
  }

  // 更新食谱
  Future<int> update(DietRecipe recipe) async {
    final db = await dbInit.database;
    return await db.update(
      DietDiaryDdl.tableDietRecipe,
      recipe.toMap(),
      where: 'id = ?',
      whereArgs: [recipe.id],
    );
  }

  // 删除食谱
  Future<int> delete(int id) async {
    final db = await dbInit.database;
    return await db.delete(
      DietDiaryDdl.tableDietRecipe,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 获取指定ID的食谱
  Future<DietRecipe?> getById(int id) async {
    final db = await dbInit.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DietDiaryDdl.tableDietRecipe,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return DietRecipe.fromMap(maps.first);
  }

  // 获取指定日期的最新食谱
  Future<DietRecipe?> getLatestByDate(DateTime date) async {
    final db = await dbInit.database;
    final dateString = date.toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      DietDiaryDdl.tableDietRecipe,
      where: 'date = ?',
      whereArgs: [dateString],
      orderBy: 'gmtCreate DESC',
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return DietRecipe.fromMap(maps.first);
  }

  // 获取指定日期的所有食谱
  Future<List<DietRecipe>> getAllByDate(DateTime date) async {
    final db = await dbInit.database;
    final dateString = date.toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      DietDiaryDdl.tableDietRecipe,
      where: 'date = ?',
      whereArgs: [dateString],
      orderBy: 'gmtCreate DESC',
    );

    return List.generate(maps.length, (i) {
      return DietRecipe.fromMap(maps[i]);
    });
  }

  // 获取指定分析ID的所有食谱
  Future<List<DietRecipe>> getByAnalysisId(int analysisId) async {
    final db = await dbInit.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DietDiaryDdl.tableDietRecipe,
      where: 'analysisId = ?',
      whereArgs: [analysisId],
      orderBy: 'gmtCreate DESC',
    );

    return List.generate(maps.length, (i) {
      return DietRecipe.fromMap(maps[i]);
    });
  }

  // 获取所有食谱
  Future<List<DietRecipe>> getAll() async {
    final db = await dbInit.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DietDiaryDdl.tableDietRecipe,
      orderBy: 'date DESC, gmtCreate DESC',
    );

    return List.generate(maps.length, (i) {
      return DietRecipe.fromMap(maps[i]);
    });
  }
}
