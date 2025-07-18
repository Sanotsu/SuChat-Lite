import 'db_config.dart';

class DietDiaryDdl {
  // 创建食品表
  static const tableFoodItem = '${DBInitConfig.tablePerfix}food_item';
  static const ddlForFoodItem = """
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
  static const ddlForMealRecord = """
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
  static const ddlForMealFoodRecord = """
    CREATE TABLE $tableMealFoodRecord (
      id                  INTEGER PRIMARY KEY AUTOINCREMENT,
      mealRecordId        INTEGER NOT NULL,
      foodItemId          INTEGER NOT NULL,
      quantity            REAL NOT NULL,
      unit                TEXT,
      gmtCreate           TEXT NOT NULL,
      gmtModified         TEXT NOT NULL,
      FOREIGN KEY (mealRecordId) REFERENCES meal_records (id) ON DELETE CASCADE,
      FOREIGN KEY (foodItemId) REFERENCES food_items (id) ON DELETE RESTRICT
    );
    """;

  // 创建体重记录表
  static const tableWeightRecord = '${DBInitConfig.tablePerfix}weight_record';
  static const ddlForWeightRecord = """
    CREATE TABLE $tableWeightRecord (
      id                  INTEGER PRIMARY KEY AUTOINCREMENT,
      userId              TEXT NOT NULL,
      weight              REAL NOT NULL,
      date                TEXT NOT NULL,
      note                TEXT,
      gmtCreate         TEXT NOT NULL,
      gmtModified         TEXT NOT NULL,
      FOREIGN KEY (userId) REFERENCES user_profiles (id) ON DELETE CASCADE
    );
    """;

  // 创建饮食分析表
  static const tableDietAnalysis = '${DBInitConfig.tablePerfix}diet_analysis';
  static const ddlForDietAnalysis = """
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
  static const ddlForDietRecipe = """
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
