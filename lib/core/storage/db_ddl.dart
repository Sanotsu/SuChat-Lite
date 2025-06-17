import 'db_config.dart';

class DBDdl {
  // 2025-02-14 新的简洁版生成式任务记录
  // 2025-02-19 图片生成、视频生成任务都放在这里面，后续可能音频生成相关的也放在这里
  //     图片可能直接返回结果，那么task相关栏位就为空
  //     但阿里云的图片和所有的视频生成，都是先返回任务提交结果，然后查询任务状态，这些内容都放在这个生成记录中
  // 栏位只保留必要的，其他参数通过otherParams字段存入json
  // 不同平台的任务状态枚举不一样，所以除了存放taskStatus，还存放了是否完成等栏位
  //     isSuccess + isProcessing + isFailed ，都是前端根据taskStatus来判断，方便直接查询
  // 因为多种媒体资源生成任务和结果都在这里，所以需要指定调用模型的类型modelType和模型信息llmSpec
  static const tableMediaGenerationHistory =
      '${DBInitConfig.tablePerfix}brief_media_generation_history';

  static const ddlForMediaGenerationHistory = """
    CREATE TABLE $tableMediaGenerationHistory (
      requestId           TEXT    NOT NULL,
      prompt              TEXT    NOT NULL,
      negativePrompt      TEXT,
      refImageUrls        TEXT,
      modelType           TEXT    NOT NULL,
      llmSpec             TEXT    NOT NULL,
      taskId              TEXT,
      taskStatus          TEXT,
      isSuccess           INTEGER,
      isProcessing        INTEGER,
      isFailed            INTEGER,
      imageUrls           TEXT,
      videoUrls           TEXT,
      audioUrls           TEXT,
      voice               TEXT,
      otherParams         TEXT,
      gmtCreate           TEXT    NOT NULL,
      gmtModified         TEXT,
      PRIMARY KEY(requestId)
    );
    """;

  static const tableCusLlmSpec =
      '${DBInitConfig.tablePerfix}brief_cus_llm_spec';

  static const ddlForCusLlmSpec = """
    CREATE TABLE $tableCusLlmSpec (
      cusLlmSpecId   TEXT    NOT NULL,
      platform       TEXT    NOT NULL,
      model          TEXT    NOT NULL,
      modelType      TEXT    NOT NULL,
      name           TEXT,
      isFree         INTEGER,
      gmtCreate      TEXT    NOT NULL,
      isBuiltin      INTEGER NOT NULL,
      baseUrl        TEXT,
      apiKey         TEXT,
      description    TEXT,
      PRIMARY KEY(cusLlmSpecId),
      UNIQUE(platform,model,modelType)
    );
    """;

  // 2025-05-08 录音识别任务表
  // 专门用于存储录音识别的详细信息
  static const tableVoiceRecognitionTask =
      '${DBInitConfig.tablePerfix}voice_recognition_task';

  static const ddlForVoiceRecognitionTask = """
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

  // 训练助手 - 用户信息表
  static const tableTrainingUserInfo =
      '${DBInitConfig.tablePerfix}training_user_info';

  static const ddlForTrainingUserInfo = """
    CREATE TABLE $tableTrainingUserInfo (
      userId              TEXT    NOT NULL,
      gender              TEXT    NOT NULL,
      height              REAL    NOT NULL,
      weight              REAL    NOT NULL,
      age                 INTEGER,
      fitnessLevel        TEXT,
      healthConditions    TEXT,
      gmtCreate           TEXT    NOT NULL,
      gmtModified         TEXT,
      PRIMARY KEY(userId)
    );
    """;

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
