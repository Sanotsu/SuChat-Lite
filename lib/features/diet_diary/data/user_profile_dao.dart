import 'package:sqflite/sqflite.dart';

import '../../../core/storage/db_init.dart';
import '../../../core/storage/diet_diary_ddl.dart';
import '../domain/entities/user_profile.dart';

class UserProfileDao {
  // 单例模式
  static final UserProfileDao _dbHelper = UserProfileDao._createInstance();
  // 构造函数，返回单例
  factory UserProfileDao() => _dbHelper;

  // 命名的构造函数用于创建DatabaseHelper的实例
  UserProfileDao._createInstance();

  // 获取数据库实例(每次操作都从 DBInit 获取，不缓存)
  Future<Database> get database async => DBInit().database;

  ///***********************************************/
  /// 用户相关方法
  ///
  ///

  Future<int> insert(UserProfile profile) async {
    final db = await database;
    return await db.insert(
      DietDiaryDdl.tableUserProfile,
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<int>> batchInsert(List<UserProfile> items) async {
    final db = await database;
    final batch = db.batch();

    for (var item in items) {
      batch.insert(
        DietDiaryDdl.tableUserProfile,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final results = await batch.commit();
    return results.cast<int>();
  }

  Future<int> update(UserProfile profile) async {
    final db = await database;
    return await db.update(
      DietDiaryDdl.tableUserProfile,
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await database;
    return await db.delete(
      DietDiaryDdl.tableUserProfile,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<UserProfile?> getById(int id) async {
    final db = await database;
    final maps = await db.query(
      DietDiaryDdl.tableUserProfile,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return UserProfile.fromMap(maps.first);
  }

  Future<List<UserProfile>> getAll() async {
    final db = await database;
    final result = await db.query(
      DietDiaryDdl.tableUserProfile,
      orderBy: 'name ASC',
    );
    return result.map((map) => UserProfile.fromMap(map)).toList();
  }

  // 获取或创建默认用户配置文件
  Future<UserProfile> getOrCreateDefault() async {
    final profiles = await getAll();

    if (profiles.isNotEmpty) {
      return profiles.first;
    }

    // 创建默认用户配置文件
    final defaultProfile = UserProfile.defaultProfile();
    final id = await insert(defaultProfile);
    return defaultProfile.copyWith(id: id);
  }

  // 根据用户配置文件计算每日推荐摄入量
  Future<Map<String, double>> calculateDailyRecommendedIntake(
    int profileId,
  ) async {
    final profile = await getById(profileId);

    if (profile == null) {
      throw Exception('用户配置文件不存在');
    }

    double targetCalories;

    // 根据目标调整卡路里
    switch (profile.goal) {
      case Goal.loseWeight:
        targetCalories = profile.tdee - 500; // 减脂：每日减少500卡路里
        break;
      case Goal.maintainWeight:
        targetCalories = profile.tdee; // 维持体重：保持当前消耗
        break;
      case Goal.gainMuscle:
        targetCalories = profile.tdee + 300; // 增肌：每日增加300卡路里
        break;
      case Goal.stayHealthy:
        targetCalories = profile.tdee; // 保持健康：保持当前消耗
        break;
    }

    // 确保卡路里不低于基础代谢率的1.2倍
    targetCalories = targetCalories.clamp(profile.bmr * 1.2, double.infinity);

    // 计算宏量营养素分配（蛋白质、碳水、脂肪）
    double targetProtein;
    double targetCarbs;
    double targetFat;

    switch (profile.goal) {
      case Goal.loseWeight:
        // 减脂：高蛋白，适中脂肪，低碳水
        targetProtein = profile.weight * 2.0; // 每公斤体重2克蛋白质
        targetFat = profile.weight * 1.0; // 每公斤体重1克脂肪
        // 剩余卡路里来自碳水
        targetCarbs = (targetCalories - targetProtein * 4 - targetFat * 9) / 4;
        break;
      case Goal.maintainWeight:
        // 维持体重：平衡的宏量营养素
        targetProtein = profile.weight * 1.6; // 每公斤体重1.6克蛋白质
        targetFat = profile.weight * 1.0; // 每公斤体重1克脂肪
        targetCarbs = (targetCalories - targetProtein * 4 - targetFat * 9) / 4;
        break;
      case Goal.gainMuscle:
        // 增肌：高蛋白，高碳水，适中脂肪
        targetProtein = profile.weight * 2.2; // 每公斤体重2.2克蛋白质
        targetFat = profile.weight * 0.8; // 每公斤体重0.8克脂肪
        targetCarbs = (targetCalories - targetProtein * 4 - targetFat * 9) / 4;
        break;
      case Goal.stayHealthy:
        // 保持健康：平衡的宏量营养素
        targetProtein = profile.weight * 1.5; // 每公斤体重1.5克蛋白质
        targetFat = profile.weight * 1.0; // 每公斤体重1克脂肪
        targetCarbs = (targetCalories - targetProtein * 4 - targetFat * 9) / 4;
        break;
    }

    // 确保宏量营养素不为负
    targetCarbs = targetCarbs.clamp(0, double.infinity);

    return {
      'calories': targetCalories,
      'protein': targetProtein,
      'carbs': targetCarbs,
      'fat': targetFat,
    };
  }

  // 更新用户目标
  Future<UserProfile> updateUserGoal(int profileId, Goal goal) async {
    final profile = await getById(profileId);

    if (profile == null) {
      throw Exception('用户配置文件不存在');
    }

    final updatedProfile = profile.copyWith(
      goal: goal,
      updatedAt: DateTime.now(),
    );

    await update(updatedProfile);
    return updatedProfile;
  }
}
