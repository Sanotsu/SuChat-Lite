import 'db_config.dart';

class DBDdl {
  // 2026-09-07 LLM旧体系退役：
  // 旧 brief_media_generation_history(媒体生成历史，新体系用unified_chat库) 与
  // brief_cus_llm_spec(旧模型表) 两张死表不再建表/读写；
  // 已装用户的残留表无害，备份导出时过滤(见DBInit.exportDatabase)

  // 2025-05-08 录音识别任务表
  // 专门用于存储录音识别的详细信息
  static const tableVoiceRecognitionTask =
      '${DBInitConfig.tablePerfix}voice_recognition_task';

  static const ddlForVoiceRecognitionTask =
      """
    CREATE TABLE $tableVoiceRecognitionTask (
      taskId              TEXT    NOT NULL,
      localAudioPath      TEXT,
      githubAudioUrl      TEXT,
      languageHint        TEXT,
      taskStatus          TEXT,
      gmtCreate           TEXT,
      llmSpec             TEXT,
      jobResponse         TEXT,
      recognitionResponse TEXT,
      PRIMARY KEY(taskId)
    );
    """;

  // 2025-07-10 统一用户信息表
  // 合并了训练助手和饮食日记中的用户表，包含所有用户相关字段
  static const tableUserInfo = '${DBInitConfig.tablePerfix}user_info';

  // gender 和 goal 使用枚举的index，所以是INTEGER类型
  static const ddlForUserInfo =
      """
    CREATE TABLE $tableUserInfo (
      userId              TEXT    NOT NULL,
      name                TEXT    NOT NULL,
      gender              INTEGER NOT NULL,
      age                 INTEGER NOT NULL,
      height              REAL    NOT NULL,
      weight              REAL    NOT NULL,
      fitnessLevel        TEXT,
      healthConditions    TEXT,
      goal                INTEGER NOT NULL,
      activityLevel       REAL,
      targetCalories      REAL,
      targetCarbs         REAL,
      targetProtein       REAL,
      targetFat           REAL,
      otherParams         TEXT,
      gmtCreate           TEXT    NOT NULL,
      gmtModified         TEXT,
      PRIMARY KEY(userId)
    );
    """;
}
