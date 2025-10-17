import 'package:sqflite/sqflite.dart';

import '../../../../core/storage/db_config.dart';
import '../models/unified_platform_spec.dart';
import 'buildin_models/index.dart';
import 'builtin_partners.dart';
import 'builtin_platforms.dart';

class UnifiedChatDdl {
  /// 平台规格表
  /// 2025-09-15 精简一下，只留必要栏位
  /// id 就是内部逻辑用的字符串，比如获取平台头像等，值例如: aliyun, siliconCloud, deepseek
  ///   内置的最后有个平台枚举
  /// display_name 就是显示用的字符串，值例如: 阿里云, 硅基流动, DeepSeek
  /// host_url: 类似 http://api.openai.com
  /// cc_prefix:  类似 /v1/chat/completions
  ///   host_url+cc_prefix 才是完整的API路径
  // 验证都是统一的请求头中添加: "Authorization: Bearer <API Key>"，所以这里不做额外参数保留
  static const tableUnifiedPlatformSpec =
      '${DBInitConfig.tablePerfix}unified_platform_spec';

  static const ddlForUnifiedPlatformSpec =
      '''
      CREATE TABLE $tableUnifiedPlatformSpec (
        id                            TEXT      PRIMARY KEY,
        display_name                  TEXT      NOT NULL,
        host_url                      TEXT      NOT NULL,
        cc_prefix                     TEXT      NOT NULL    DEFAULT '/v1/chat/completions',
        img_gen_prefix                TEXT,
        tts_prefix                    TEXT,
        asr_prefix                    TEXT,
        is_built_in                   INTEGER   NOT NULL    DEFAULT 0,
        is_active                     INTEGER   NOT NULL    DEFAULT 0,
        description                   TEXT,
        extra_params                  TEXT,
        created_at                    INTEGER   NOT NULL,
        updated_at                    INTEGER   NOT NULL
      )
    ''';

  /// 模型规格表
  /// 2025-09-15 精简一下，只留必要栏位
  /// id 可以是uuid，只做主键
  /// model_name 为作为参数的模型代号
  /// display_name 为显示用的模型名称
  /// model_type 为模型的简单分类：对话 、 嵌入 、重排
  ///     对话模型还有额外的是否支持 视觉、推理、工具调用 等选项；嵌入 、重排则没有这些选项
  /// context_length\max_output_tokens\input_price_per_1k\output_price_per_1k这一堆都是无关紧要的，可以不要
  /// is_favorite 为是否收藏,收藏的排序可以放在最上面
  /// is_active 是否启用,用户可能先添加了很多模型,但是只启用一部分,因为列表显示是未启用的不显示会少很多
  static const tableUnifiedModelSpec =
      '${DBInitConfig.tablePerfix}unified_model_spec';

  static const ddlForUnifiedModelSpec =
      '''
      CREATE TABLE $tableUnifiedModelSpec (
        id                          TEXT      PRIMARY KEY,
        platform_id                 TEXT      NOT NULL,
        model_name                  TEXT      NOT NULL,
        display_name                TEXT      NOT NULL,
        model_type                  TEXT      NOT NULL,
        supports_thinking           INTEGER   NOT NULL    DEFAULT 0,
        supports_vision             INTEGER   NOT NULL    DEFAULT 0,
        supports_tool_calling       INTEGER   NOT NULL    DEFAULT 0,
        is_built_in                 INTEGER   NOT NULL    DEFAULT 0,
        is_active                   INTEGER   NOT NULL    DEFAULT 1,
        is_favorite                 INTEGER   NOT NULL    DEFAULT 0,
        description                 TEXT,
        extra_config                TEXT,
        created_at                  INTEGER   NOT NULL,
        updated_at                  INTEGER   NOT NULL,
        FOREIGN KEY (platform_id) REFERENCES $tableUnifiedPlatformSpec (id) ON DELETE CASCADE
      )
    ''';

  /// 聊天搭档表
  /// 这就和之前的角色功能类似,但是只适用最基础的配置
  /// 最主要就是: 系统提示词\创造性参数等内容,context_message_length为调用API时最多发送的消息数量
  static const String tableUnifiedChatPartner =
      '${DBInitConfig.tablePerfix}unified_chat_partner';

  /// 聊天搭档表创建语句
  static const String ddlForUnifiedChatPartner =
      '''
      CREATE TABLE IF NOT EXISTS $tableUnifiedChatPartner (
        id                            TEXT      PRIMARY KEY,
        name                          TEXT      NOT NULL,
        prompt                        TEXT      NOT NULL,
        avatar_url                    TEXT,
        is_built_in                   INTEGER   NOT NULL    DEFAULT 0,
        is_active                     INTEGER   NOT NULL    DEFAULT 1,
        is_favorite                   INTEGER   NOT NULL    DEFAULT 0,
        context_message_length        INTEGER               DEFAULT 6,
        temperature                   REAL,
        top_p                         REAL,
        max_tokens                    INTEGER,
        is_stream                     INTEGER               DEFAULT 1,
        created_at                    INTEGER   NOT NULL,
        updated_at                    INTEGER   NOT NULL
      )
    ''';

  /// 对话记录表
  /// 对话记录简单保留基础对话设置,更多的内容放在extra_params栏位中
  /// 注意:有设计搭档工具功能,在对话时可能会选择,所以也要一并记录编号
  ///     (20250917 其实对话中的搭档信息主要是提示词,外面有单独的栏位了,目前查询对话时暂不需要级联查询搭档信息)
  /// context_message_length : 表示该对话调用API时最多发送的消息长度.比如设置6,那调用API时最多发送最近6条对话消息
  static const tableUnifiedConversation =
      '${DBInitConfig.tablePerfix}unified_conversation';

  static const ddlForUnifiedConversation =
      '''
      CREATE TABLE $tableUnifiedConversation (
        id                          TEXT      PRIMARY KEY,
        title                       TEXT      NOT NULL,
        model_id                    TEXT      NOT NULL,
        platform_id                 TEXT      NOT NULL,
        partner_id                  TEXT,
        system_prompt               TEXT,
        temperature                 REAL                    DEFAULT 0.7,
        max_tokens                  INTEGER   NOT NULL      DEFAULT 4096,
        top_p                       REAL                    DEFAULT 1.0,
        frequency_penalty           REAL                    DEFAULT 0.0,
        presence_penalty            REAL                    DEFAULT 0.0,
        context_message_length      INTEGER   NOT NULL      DEFAULT 6,
        is_stream                   INTEGER   NOT NULL      DEFAULT 1,
        extra_params                TEXT,
        message_count               INTEGER   NOT NULL      DEFAULT 0,
        total_tokens                INTEGER   NOT NULL      DEFAULT 0,
        total_cost                  REAL      NOT NULL      DEFAULT 0.0,
        is_pinned                   INTEGER   NOT NULL      DEFAULT 0,
        is_archived                 INTEGER   NOT NULL      DEFAULT 0,
        created_at                  INTEGER   NOT NULL,
        updated_at                  INTEGER   NOT NULL,
        FOREIGN KEY (model_id) REFERENCES $tableUnifiedModelSpec (id),
        FOREIGN KEY (platform_id) REFERENCES $tableUnifiedPlatformSpec (id)
      )
    ''';

  /// 对话消息表
  /// 每个对话都要保留使用的平台和模型名(作为请求参数的那个)
  /// model_name_used platform_id_used 具体的模型平台信息、以及音频视频等媒体资源的地址信息，都放在metadata中
  static const tableUnifiedChatMessage =
      '${DBInitConfig.tablePerfix}unified_chat_message';

  static const ddlForUnifiedChatMessage =
      '''
     CREATE TABLE $tableUnifiedChatMessage (
        id                  TEXT      PRIMARY KEY,
        conversation_id     TEXT      NOT NULL,
        role                TEXT      NOT NULL     CHECK (role IN ('system', 'user', 'assistant', 'function', 'tool')),
        thinking_content    TEXT,
        thinking_time       INTEGER,
        content             TEXT,
        content_type        TEXT      NOT NULL     DEFAULT 'text',
        multimodal_content  TEXT,
        function_call       TEXT,
        tool_calls          TEXT,
        tool_call_id        TEXT,
        name                TEXT,
        finish_reason       TEXT,
        token_count         INTEGER                DEFAULT 0,
        cost                REAL                   DEFAULT 0.0,
        model_name_used     TEXT,
        platform_id_used    TEXT,
        response_time_ms    INTEGER,
        search_references   TEXT,
        is_streaming        INTEGER   NOT NULL     DEFAULT 0,
        is_error            INTEGER   NOT NULL     DEFAULT 0,
        error_message       TEXT,
        metadata            TEXT,
        created_at          INTEGER   NOT NULL,
        updated_at          INTEGER   NOT NULL,
        FOREIGN KEY (conversation_id) REFERENCES $tableUnifiedConversation (id) ON DELETE CASCADE
      )
    ''';

  // API密钥表
  static const tableUnifiedApiKey =
      '${DBInitConfig.tablePerfix}unified_api_key';

  static const ddlForUnifiedApiKey =
      '''
      CREATE TABLE $tableUnifiedApiKey (
        id                  TEXT      NOT NULL,
        platform_id         TEXT      NOT NULL,
        key_name            TEXT      NOT NULL,
        is_active           INTEGER   NOT NULL     DEFAULT 1,
        last_used_at        INTEGER,
        usage_count         INTEGER                DEFAULT 0,
        created_at          INTEGER   NOT NULL,
        updated_at          INTEGER   NOT NULL,
        FOREIGN KEY (platform_id) REFERENCES $tableUnifiedPlatformSpec (id) ON DELETE CASCADE
      )
    ''';

  // 初始化一些内置平台和模型
  static Future<void> initDefaultPlatforms(
    Database db, {
    UnifiedPlatformId? platformId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final batch = db.batch();

    // 如果没有传入平台编号，则全部平台都重新加载；如果有传入平台编号，则只重新加载该平台
    for (var platform in BUILD_IN_PLATFORMS) {
      // 有传入平台编号,但是当前平台不是该平台,则跳过
      if (platformId != null && platform['id'] != platformId.name) {
        continue;
      }
      // 没有传入平台编号或者传入平台编号和当前平台编号一致,则插入该平台数据
      batch.insert(tableUnifiedPlatformSpec, {
        ...platform,
        'is_built_in': 1,
        'is_active': 0,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();

    // 插入默认模型
    await _insertDefaultModels(db, now, platformId: platformId);
  }

  static Future<void> _insertDefaultModels(
    Database db,
    int timestamp, {
    UnifiedPlatformId? platformId,
  }) async {
    final batch = db.batch();

    // 如果有传入平台编号，则只重新加载该平台内置模型;否则全部平台内置模型都重新加载
    for (final model in BUILD_IN_MODELS) {
      // 有传入平台编号,但是当前模型不是该平台,则跳过
      if (platformId != null && model['platform_id'] != platformId.name) {
        continue;
      }

      // 没有传入平台编号或者传入平台编号和当前平台编号一致,则插入该模型数据
      batch.insert(tableUnifiedModelSpec, {
        ...model,
        'is_active': 1,
        'is_built_in': 1,
        'is_favorite': 0,
        'created_at': timestamp,
        'updated_at': timestamp,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }

  /// 初始化预设搭档
  static Future<void> initDefaultPartners(Database db) async {
    // 测试，先删除，再新增内置的
    await db.delete(UnifiedChatDdl.tableUnifiedChatPartner);

    for (final partner in BUILD_IN_PARTNERS) {
      await db.insert(
        UnifiedChatDdl.tableUnifiedChatPartner,
        partner.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
