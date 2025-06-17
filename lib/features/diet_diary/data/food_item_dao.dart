import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import '../../../core/storage/db_init.dart';
import '../../../core/utils/simple_tools.dart';
import '../domain/entities/food_item.dart';
import '../../../core/storage/diet_diary_ddl.dart';

class FoodItemDao {
  // 单例模式
  static final FoodItemDao _dbHelper = FoodItemDao._createInstance();
  // 构造函数，返回单例
  factory FoodItemDao() => _dbHelper;

  // 命名的构造函数用于创建DatabaseHelper的实例
  FoodItemDao._createInstance();

  // 获取数据库实例(每次操作都从 DBInit 获取，不缓存)
  Future<Database> get database async => DBInit().database;

  ///***********************************************/
  /// 食品相关方法
  ///
  ///
  Future<int> insert(FoodItem foodItem) async {
    Database db = await database;
    return await db.insert(
      DietDiaryDdl.tableFoodItem,
      foodItem.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<int>> batchInsert(List<FoodItem> foodItems) async {
    final db = await database;
    final batch = db.batch();

    for (var foodItem in foodItems) {
      batch.insert(
        DietDiaryDdl.tableFoodItem,
        foodItem.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final results = await batch.commit();
    return results.cast<int>();
  }

  Future<int> update(FoodItem foodItem) async {
    final db = await database;
    return await db.update(
      DietDiaryDdl.tableFoodItem,
      foodItem.toMap(),
      where: 'id = ?',
      whereArgs: [foodItem.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await database;

    // 检查是否有关联的餐次食品记录
    final List<Map<String, dynamic>> result = await db.query(
      DietDiaryDdl.tableMealFoodRecord,
      where: 'foodItemId = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) {
      throw Exception('该食品已被使用，无法删除');
    }

    return await db.delete(
      DietDiaryDdl.tableFoodItem,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<FoodItem?> getById(int id) async {
    final db = await database;
    final maps = await db.query(
      DietDiaryDdl.tableFoodItem,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return FoodItem.fromMap(maps.first);
  }

  Future<FoodItem?> getByFoodCode(String foodCode) async {
    final db = await database;
    final maps = await db.query(
      DietDiaryDdl.tableFoodItem,
      where: 'foodCode = ?',
      whereArgs: [foodCode],
    );

    if (maps.isEmpty) {
      return null;
    }

    return FoodItem.fromMap(maps.first);
  }

  Future<List<FoodItem>> getAll({
    int limit = 100,
    int offset = 0,
    String orderBy = 'name ASC',
  }) async {
    final db = await database;
    final result = await db.query(
      DietDiaryDdl.tableFoodItem,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    return result.map((map) => FoodItem.fromMap(map)).toList();
  }

  Future<List<FoodItem>> search(String query, {int limit = 50}) async {
    final db = await database;
    final result = await db.query(
      DietDiaryDdl.tableFoodItem,
      where: 'name LIKE ? OR foodCode LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
      limit: limit,
    );
    return result.map((map) => FoodItem.fromMap(map)).toList();
  }

  Future<List<FoodItem>> getFavorites({int limit = 100, int offset = 0}) async {
    final db = await database;
    final result = await db.query(
      DietDiaryDdl.tableFoodItem,
      where: 'isFavorite = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
      limit: limit,
      offset: offset,
    );
    return result.map((map) => FoodItem.fromMap(map)).toList();
  }

  Future<bool> toggleFavorite(int id) async {
    final foodItem = await getById(id);

    if (foodItem == null) {
      return false;
    }

    final updatedFoodItem = foodItem.copyWith(
      isFavorite: !foodItem.isFavorite,
      updatedAt: DateTime.now(),
    );

    final result = await update(updatedFoodItem);
    return result > 0;
  }

  // 检查食品名称是否已存在
  Future<bool> isNameExists(String name, {int? excludeId}) async {
    final db = await database;

    String whereClause = 'name = ?';
    List<dynamic> whereArgs = [name];

    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final result = await db.query(
      DietDiaryDdl.tableFoodItem,
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // 检查食品编码是否已存在
  Future<bool> isFoodCodeExists(String foodCode, {int? excludeId}) async {
    if (foodCode.isEmpty) return false;

    final db = await database;

    String whereClause = 'foodCode = ?';
    List<dynamic> whereArgs = [foodCode];

    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final result = await db.query(
      DietDiaryDdl.tableFoodItem,
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    return result.isNotEmpty;
  }

  /// 从JSON字符串导入食品数据
  /// 这个是专门兼容老数据格式: https://github.com/Sanotsu/china-food-composition-data
  Future<int> importFromCFCDJson(String jsonString) async {
    try {
      final List<dynamic> jsonData = json.decode(jsonString);
      final List<FoodItem> foodItems = [];

      for (var data in jsonData) {
        final foodItem = FoodItem.fromCFCDJsonData(data);

        // 检查食品编码是否已存在
        if (foodItem.foodCode != null && foodItem.foodCode!.isNotEmpty) {
          final exists = await isFoodCodeExists(foodItem.foodCode!);
          if (exists) continue; // 跳过已存在的食品
        }

        foodItems.add(foodItem);
      }

      if (foodItems.isEmpty) {
        return 0;
      }

      final results = await batchInsert(foodItems);
      return results.length;
    } catch (e) {
      pl.e('从JSON导入食品数据失败: $e');
      return 0;
    }
  }

  // 获取食品总数
  Future<int> count() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DietDiaryDdl.tableFoodItem}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
