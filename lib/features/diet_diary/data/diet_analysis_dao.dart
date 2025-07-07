import 'package:sqflite/sqflite.dart';

import '../../../core/storage/db_init.dart';
import '../../../core/storage/ddl_diet_diary.dart';
import '../domain/entities/diet_analysis.dart';

class DietAnalysisDao {
  // 单例模式
  static final DietAnalysisDao _dao = DietAnalysisDao._createInstance();
  // 构造函数，返回单例
  factory DietAnalysisDao() => _dao;

  // 命名的构造函数用于创建DatabaseHelper的实例
  DietAnalysisDao._createInstance();

  // 获取数据库实例(每次操作都从 DBInit 获取，不缓存)
  final dbInit = DBInit();

  // 插入饮食分析记录
  Future<int> insert(DietAnalysis analysis) async {
    final db = await dbInit.database;
    return await db.insert(
      DietDiaryDdl.tableDietAnalysis,
      analysis.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<int>> batchInsert(List<DietAnalysis> items) async {
    final db = await dbInit.database;
    final batch = db.batch();

    for (var item in items) {
      batch.insert(
        DietDiaryDdl.tableDietAnalysis,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final results = await batch.commit();
    return results.cast<int>();
  }

  // 更新饮食分析记录
  Future<int> update(DietAnalysis analysis) async {
    final db = await dbInit.database;
    return await db.update(
      DietDiaryDdl.tableDietAnalysis,
      analysis.toMap(),
      where: 'id = ?',
      whereArgs: [analysis.id],
    );
  }

  // 删除饮食分析记录
  Future<int> delete(int id) async {
    final db = await dbInit.database;
    return await db.delete(
      DietDiaryDdl.tableDietAnalysis,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 获取指定日期的最新饮食分析记录
  Future<DietAnalysis?> getLatestByDate(DateTime date) async {
    final db = await dbInit.database;
    final dateString = date.toIso8601String().split('T')[0];

    final maps = await db.query(
      DietDiaryDdl.tableDietAnalysis,
      where: 'date = ?',
      whereArgs: [dateString],
      orderBy: 'gmtCreate DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return DietAnalysis.fromMap(maps.first);
    }
    return null;
  }

  // 获取指定日期的所有饮食分析记录
  Future<List<DietAnalysis>> getAllByDate(DateTime date) async {
    final db = await dbInit.database;
    final dateString = date.toIso8601String().split('T')[0];

    final maps = await db.query(
      DietDiaryDdl.tableDietAnalysis,
      where: 'date = ?',
      whereArgs: [dateString],
      orderBy: 'gmtCreate DESC',
    );

    return List.generate(maps.length, (i) {
      return DietAnalysis.fromMap(maps[i]);
    });
  }

  // 获取所有饮食分析记录
  Future<List<DietAnalysis>> getAll() async {
    final db = await dbInit.database;
    final maps = await db.query(
      DietDiaryDdl.tableDietAnalysis,
      orderBy: 'date DESC, gmtCreate DESC',
    );

    return List.generate(maps.length, (i) {
      return DietAnalysis.fromMap(maps[i]);
    });
  }

  // 获取或创建指定日期的饮食分析记录
  Future<DietAnalysis> getOrCreate(
    DateTime date,
    String content,
    String modelName,
  ) async {
    // 不再获取现有记录，而是直接创建新记录
    final newAnalysis = DietAnalysis(
      date: date,
      content: content,
      modelName: modelName,
    );

    final id = await insert(newAnalysis);
    return newAnalysis.copyWith(id: id);
  }
}
