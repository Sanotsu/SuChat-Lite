import 'package:sqflite/sqflite.dart';

import '../../../core/storage/db_init.dart';
import '../../../core/storage/ddl_diet_diary.dart';
import '../domain/entities/meal_food_record.dart';
import '../domain/entities/meal_food_detail.dart';

class MealFoodRecordDao {
  static final MealFoodRecordDao _dao = MealFoodRecordDao._createInstance();
  factory MealFoodRecordDao() => _dao;
  MealFoodRecordDao._createInstance();

  final dbInit = DBInit();

  ///***********************************************/
  /// 餐次食品记录相关方法
  ///
  ///
  Future<int> insert(MealFoodRecord record) async {
    final db = await dbInit.database;
    return await db.insert(
      DietDiaryDdl.tableMealFoodRecord,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<int>> batchInsert(List<MealFoodRecord> items) async {
    final db = await dbInit.database;
    final batch = db.batch();

    for (var item in items) {
      batch.insert(
        DietDiaryDdl.tableMealFoodRecord,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final results = await batch.commit();
    return results.cast<int>();
  }

  Future<int> update(MealFoodRecord record) async {
    final db = await dbInit.database;
    return await db.update(
      DietDiaryDdl.tableMealFoodRecord,
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await dbInit.database;
    return await db.delete(
      DietDiaryDdl.tableMealFoodRecord,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<MealFoodRecord?> getById(int id) async {
    final db = await dbInit.database;
    final maps = await db.query(
      DietDiaryDdl.tableMealFoodRecord,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return MealFoodRecord.fromMap(maps.first);
  }

  Future<List<MealFoodRecord>> getByMealRecordId(int mealRecordId) async {
    final db = await dbInit.database;
    final result = await db.query(
      DietDiaryDdl.tableMealFoodRecord,
      where: 'mealRecordId = ?',
      whereArgs: [mealRecordId],
    );

    return result.map((map) => MealFoodRecord.fromMap(map)).toList();
  }

  // 获取餐次中的食品详情（包含食品信息）
  Future<List<MealFoodDetail>> getMealFoodDetails(int mealRecordId) async {
    final db = await dbInit.database;

    const query = '''
    SELECT 
      mfr.id, 
      mfr.mealRecordId, 
      mfr.foodItemId, 
      mfr.quantity, 
      mfr.unit,
      mfr.gmtCreate,
      mfr.gmtModified,
      f.name, 
      f.foodCode,
      f.imageUrl, 
      f.caloriesPer100g, 
      f.carbsPer100g, 
      f.proteinPer100g, 
      f.fatPer100g,
      f.fiberPer100g,
      f.cholesterolPer100g,
      f.sodiumPer100g,
      f.calciumPer100g,
      f.ironPer100g,
      f.vitaminAPer100g,
      f.vitaminCPer100g,
      f.vitaminEPer100g,
      f.isFavorite
    FROM 
      ${DietDiaryDdl.tableMealFoodRecord} mfr
    JOIN 
      ${DietDiaryDdl.tableFoodItem} f ON mfr.foodItemId = f.id
    WHERE 
      mfr.mealRecordId = ?
    ORDER BY 
      f.name ASC
    ''';

    final result = await db.rawQuery(query, [mealRecordId]);
    return result.map((map) => MealFoodDetail.fromMap(map)).toList();
  }

  // 计算餐次的营养总量
  Future<Map<String, double>> calculateMealNutrition(int mealRecordId) async {
    final mealFoodDetails = await getMealFoodDetails(mealRecordId);

    double totalCalories = 0;
    double totalCarbs = 0;
    double totalProtein = 0;
    double totalFat = 0;

    for (final detail in mealFoodDetails) {
      // 使用MealFoodDetail的getter方法计算实际摄入量
      totalCalories += detail.calories;
      totalCarbs += detail.carbs;
      totalProtein += detail.protein;
      totalFat += detail.fat;
    }

    return {
      'calories': totalCalories,
      'carbs': totalCarbs,
      'protein': totalProtein,
      'fat': totalFat,
    };
  }

  // 计算一天的营养总量
  Future<Map<String, double>> calculateDailyNutrition(DateTime date) async {
    final db = await dbInit.database;
    final dateString = date.toIso8601String().split('T')[0];

    const query = '''
    SELECT 
      SUM(f.caloriesPer100g * mfr.quantity / 100) as totalCalories,
      SUM(f.carbsPer100g * mfr.quantity / 100) as totalCarbs,
      SUM(f.proteinPer100g * mfr.quantity / 100) as totalProtein,
      SUM(f.fatPer100g * mfr.quantity / 100) as totalFat
    FROM 
      ${DietDiaryDdl.tableMealRecord} mr
    JOIN 
      ${DietDiaryDdl.tableMealFoodRecord} mfr ON mr.id = mfr.mealRecordId
    JOIN 
      ${DietDiaryDdl.tableFoodItem} f ON mfr.foodItemId = f.id
    WHERE 
      mr.date = ?
    ''';

    final result = await db.rawQuery(query, [dateString]);

    if (result.isEmpty || result.first['totalCalories'] == null) {
      return {'calories': 0.0, 'carbs': 0.0, 'protein': 0.0, 'fat': 0.0};
    }

    return {
      'calories': result.first['totalCalories'] as double? ?? 0.0,
      'carbs': result.first['totalCarbs'] as double? ?? 0.0,
      'protein': result.first['totalProtein'] as double? ?? 0.0,
      'fat': result.first['totalFat'] as double? ?? 0.0,
    };
  }

  // 获取一段时间内的每日营养摄入量
  Future<List<Map<String, dynamic>>> getDailyNutritionByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await dbInit.database;
    final startDateString = startDate.toIso8601String().split('T')[0];
    final endDateString = endDate.toIso8601String().split('T')[0];

    const query = '''
    SELECT 
      mr.date,
      SUM(f.caloriesPer100g * mfr.quantity / 100) as totalCalories,
      SUM(f.carbsPer100g * mfr.quantity / 100) as totalCarbs,
      SUM(f.proteinPer100g * mfr.quantity / 100) as totalProtein,
      SUM(f.fatPer100g * mfr.quantity / 100) as totalFat
    FROM 
      ${DietDiaryDdl.tableMealRecord} mr
    JOIN 
      ${DietDiaryDdl.tableMealFoodRecord} mfr ON mr.id = mfr.mealRecordId
    JOIN 
      ${DietDiaryDdl.tableFoodItem} f ON mfr.foodItemId = f.id
    WHERE 
      mr.date >= ? AND mr.date <= ?
    GROUP BY 
      mr.date
    ORDER BY 
      mr.date ASC
    ''';

    final result = await db.rawQuery(query, [startDateString, endDateString]);
    return result;
  }

  // 检查食品是否已存在于餐次中
  Future<MealFoodRecord?> checkFoodExistsInMeal(
    int mealRecordId,
    int foodItemId,
  ) async {
    final db = await dbInit.database;
    final result = await db.query(
      DietDiaryDdl.tableMealFoodRecord,
      where: 'mealRecordId = ? AND foodItemId = ?',
      whereArgs: [mealRecordId, foodItemId],
    );

    if (result.isEmpty) {
      return null;
    }

    return MealFoodRecord.fromMap(result.first);
  }

  // 更新餐次中食品的数量
  Future<int> updateFoodQuantity(
    int recordId,
    double newQuantity,
    String? unit,
  ) async {
    final db = await dbInit.database;
    return await db.update(
      DietDiaryDdl.tableMealFoodRecord,
      {
        'quantity': newQuantity,
        if (unit != null) 'unit': unit,
        'gmtModified': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }
}
