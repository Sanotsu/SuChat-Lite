// ignore_for_file: constant_identifier_names

import 'init_db.dart';

///
/// 2025-04-01 sqlite只存放AI图片视频生成的结果、自定义模型列表
///
class BriefAIToolDdl {
  // 2025-02-14 新的简洁版生成式任务记录
  // 2025-02-19 图片生成、视频生成任务都放在这里面，后续可能音频生成相关的也放在这里
  //     图片可能直接返回结果，那么task相关栏位就为空
  //     但阿里云的图片和所有的视频生成，都是先返回任务提交结果，然后查询任务状态，这些内容都放在这个生成记录中
  // 栏位只保留必要的，其他参数通过otherParams字段存入json
  // 不同平台的任务状态枚举不一样，所以除了存放taskStatus，还存放了是否完成等栏位
  //     isSuccess + isProcessing + isFailed ，都是前端根据taskStatus来判断，方便直接查询
  // 因为多种媒体资源生成任务和结果都在这里，所以需要指定调用模型的类型modelType和模型信息llmSpec
  static const tableNameOfMediaGenerationHistory =
      '${DB_TABLE_PREFIX}brief_media_generation_history';

  static const String ddlForMediaGenerationHistory = """
    CREATE TABLE $tableNameOfMediaGenerationHistory (
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
      otherParams         TEXT,
      gmtCreate           TEXT    NOT NULL,
      gmtModified         TEXT,
      PRIMARY KEY(requestId)
    );
    """;

  static const tableNameOfCusBriefLlmSpec =
      '${DB_TABLE_PREFIX}brief_cus_llm_spec';

  static const String ddlForCusBriefLlmSpec = """
    CREATE TABLE $tableNameOfCusBriefLlmSpec (
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
}
