import 'db_config.dart';

class DietDiaryDdl {
  // 创建食品表
  static const tableFoodItem = '${DBInitConfig.tablePerfix}food_item';
  static const ddlForFoodItem =
      """
    CREATE TABLE $tableFoodItem (
      id                  INTEGER PRIMARY KEY AUTOINCREMENT,
      name                TEXT NOT NULL,
      imageUrl            TEXT,
      foodCode            TEXT NOT NULL,
      caloriesPer100g     REAL NOT NULL,
      carbsPer100g        REAL NOT NULL,
      proteinPer100g      REAL NOT NULL,
      fatPer100g          REAL NOT NULL,
      fiberPer100g        REAL,
      cholesterolPer100g  REAL,
      sodiumPer100g       REAL,
      calciumPer100g      REAL,
      ironPer100g         REAL,
      vitaminAPer100g     REAL,
      vitaminCPer100g     REAL,
      vitaminEPer100g     REAL,
      otherParams         TEXT,
      isFavorite          INTEGER NOT NULL,
      gmtCreate           TEXT NOT NULL,
      gmtModified         TEXT NOT NULL
    );
    """;

  // 创建餐次记录表
  static const tableMealRecord = '${DBInitConfig.tablePerfix}meal_record';
  static const ddlForMealRecord =
      """
    CREATE TABLE $tableMealRecord (
      id                  INTEGER PRIMARY KEY AUTOINCREMENT,
      date                TEXT NOT NULL,
      mealType            INTEGER NOT NULL,
      imageUrls           TEXT,
      description         TEXT,
      gmtCreate           TEXT NOT NULL,
      gmtModified         TEXT NOT NULL
    );
    """;

  // 创建餐次食品记录表
  static const tableMealFoodRecord =
      '${DBInitConfig.tablePerfix}meal_food_record';
  static const ddlForMealFoodRecord =
      """
    CREATE TABLE $tableMealFoodRecord (
      id                  INTEGER PRIMARY KEY AUTOINCREMENT,
      mealRecordId        INTEGER NOT NULL,
      foodItemId          INTEGER NOT NULL,
      quantity            REAL NOT NULL,
      unit                TEXT,
      gmtCreate           TEXT NOT NULL,
      gmtModified         TEXT NOT NULL,
      // 2026-09-07 A-6 修复：原外键引用 meal_records/food_items 等不存在的
      // 表名（sqflite 默认未开启 foreign_keys 故从未爆发）；改为真实表名。
      // 注意本项目未开启 PRAGMA foreign_keys，级联仍不生效，删除清理由 DAO 层负责
      FOREIGN KEY (mealRecordId) REFERENCES $tableMealRecord (id) ON DELETE CASCADE,
      FOREIGN KEY (foodItemId) REFERENCES $tableFoodItem (id) ON DELETE RESTRICT
    );
    """;

  // 创建体重记录表
  static const tableWeightRecord = '${DBInitConfig.tablePerfix}weight_record';
  static const ddlForWeightRecord =
      """
    CREATE TABLE $tableWeightRecord (
      id                  INTEGER PRIMARY KEY AUTOINCREMENT,
      userId              TEXT NOT NULL,
      weight              REAL NOT NULL,
      date                TEXT NOT NULL,
      note                TEXT,
      gmtCreate         TEXT NOT NULL,
      gmtModified         TEXT NOT NULL
      // 2026-09-07 A-6 修复：原外键引用不存在的 user_profiles 表（userId
      // 语义是主库 user_info.user_id 文本，无本库表可引用），删除该假外键
    );
    """;

  // 创建饮食分析表
  static const tableDietAnalysis = '${DBInitConfig.tablePerfix}diet_analysis';
  static const ddlForDietAnalysis =
      """
    CREATE TABLE $tableDietAnalysis (
      id                  INTEGER PRIMARY KEY AUTOINCREMENT,
      date                TEXT NOT NULL,
      content             TEXT NOT NULL,
      modelName           TEXT NOT NULL,
      gmtCreate           TEXT NOT NULL,
      gmtModified         TEXT NOT NULL
    );
    """;

  // 创建食谱表
  static const tableDietRecipe = '${DBInitConfig.tablePerfix}diet_recipe';
  static const ddlForDietRecipe =
      """
    CREATE TABLE $tableDietRecipe (
      id                  INTEGER PRIMARY KEY AUTOINCREMENT,
      date                TEXT NOT NULL,
      content             TEXT NOT NULL,
      modelName           TEXT NOT NULL,
      days                INTEGER NOT NULL,
      mealsPerDay         INTEGER NOT NULL,
      dietaryPreference   TEXT,
      analysisId          INTEGER,
      gmtCreate           TEXT NOT NULL,
      gmtModified         TEXT NOT NULL
    );
    """;
}
