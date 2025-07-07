import 'db_config.dart';

class TrainingDdl {
  // 训练助手 - 训练计划表
  static const tableTrainingPlan = '${DBInitConfig.tablePerfix}training_plan';

  static const ddlForTrainingPlan = """
    CREATE TABLE $tableTrainingPlan (
      planId              TEXT    NOT NULL,
      userId              TEXT    NOT NULL,
      planName            TEXT    NOT NULL,
      targetGoal          TEXT    NOT NULL,
      targetMuscleGroups  TEXT    NOT NULL,
      duration            INTEGER NOT NULL,
      frequency           TEXT    NOT NULL,
      difficulty          TEXT    NOT NULL,
      description         TEXT,
      equipment           TEXT,
      isActive            INTEGER NOT NULL,
      gmtCreate           TEXT    NOT NULL,
      gmtModified         TEXT,
      PRIMARY KEY(planId)
    );
    """;

  // 训练助手 - 训练计划详情表
  static const tableTrainingPlanDetail =
      '${DBInitConfig.tablePerfix}training_plan_detail';

  static const ddlForTrainingPlanDetail = """
    CREATE TABLE $tableTrainingPlanDetail (
      detailId            TEXT    NOT NULL,
      planId              TEXT    NOT NULL,
      day                 INTEGER NOT NULL,
      exerciseName        TEXT    NOT NULL,
      muscleGroup         TEXT    NOT NULL,
      sets                INTEGER NOT NULL,
      reps                TEXT    NOT NULL,
      countdown           INTEGER NOT NULL,
      restTime            INTEGER NOT NULL,
      instructions        TEXT,
      imageUrl            TEXT,
      gmtCreate           TEXT    NOT NULL,
      PRIMARY KEY(detailId)
    );
    """;

  // 训练助手 - 训练记录表
  static const tableTrainingRecord =
      '${DBInitConfig.tablePerfix}training_record';

  static const ddlForTrainingRecord = """
    CREATE TABLE $tableTrainingRecord (
      recordId            TEXT    NOT NULL,
      planId              TEXT    NOT NULL,
      userId              TEXT    NOT NULL,
      date                TEXT    NOT NULL,
      duration            INTEGER NOT NULL,
      caloriesBurned      INTEGER,
      completionRate      REAL    NOT NULL,
      feedback            TEXT,
      gmtCreate           TEXT    NOT NULL,
      PRIMARY KEY(recordId)
    );
    """;

  // 训练助手 - 训练记录详情表
  static const tableTrainingRecordDetail =
      '${DBInitConfig.tablePerfix}training_record_detail';

  static const ddlForTrainingRecordDetail = """
    CREATE TABLE $tableTrainingRecordDetail (
      detailRecordId      TEXT    NOT NULL,
      recordId            TEXT    NOT NULL,
      detailId            TEXT    NOT NULL,
      exerciseName        TEXT    NOT NULL,
      completed           INTEGER NOT NULL,
      actualSets          INTEGER NOT NULL,
      actualReps          TEXT    NOT NULL,
      notes               TEXT,
      gmtCreate           TEXT    NOT NULL,
      PRIMARY KEY(detailRecordId)
    );
    """;
}
