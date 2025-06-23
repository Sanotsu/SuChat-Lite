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

  // 2025-07-10 统一用户信息表
  // 合并了训练助手和饮食日记中的用户表，包含所有用户相关字段
  static const tableUserInfo = '${DBInitConfig.tablePerfix}user_info';

  // gender 和 goal 使用枚举的index，所以是INTEGER类型
  static const ddlForUserInfo = """
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
