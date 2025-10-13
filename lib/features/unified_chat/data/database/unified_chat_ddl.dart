import 'package:sqflite/sqflite.dart';

import '../../../../core/storage/db_config.dart';
import '../models/unified_chat_partner.dart';

class UnifiedChatDdl {
  /// 平台规格表
  /// 2025-09-15 精简一下，只留必要栏位
  /// id 就是内部逻辑用的字符串，比如获取平台头像等，值例如: aliyun, siliconCloud, deepseek
  ///   内置的最后有个平台枚举
  /// display_name 就是显示用的字符串，值例如: 阿里云, 硅基流动, DeepSeek
  /// host_url: 类似 http://api.openai.com
  /// api_prefix:  类似 /v1/chat/completions
  ///   host_url+api_prefix 才是完整的API路径
  // 验证都是统一的请求头中添加: "Authorization: Bearer <API Key>"，所以这里不做额外参数保留
  static const tableUnifiedPlatformSpec =
      '${DBInitConfig.tablePerfix}unified_platform_spec';

  static const ddlForUnifiedPlatformSpec =
      '''
      CREATE TABLE $tableUnifiedPlatformSpec (
        id                            TEXT      PRIMARY KEY,
        display_name                  TEXT      NOT NULL,
        host_url                      TEXT      NOT NULL,
        api_prefix                    TEXT      NOT NULL    DEFAULT '/v1/chat/completions',
        image_generation_prefix       TEXT,
        text_to_speech_prefix         TEXT,
        speech_to_text_prefix         TEXT,
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
  static Future<void> initDefaultPlatforms(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 【注意】：平台id要和 UnifiedPlatformId 枚举一致
    List<Map<String, dynamic>> platforms = [
      {
        'id': 'aliyun',
        'display_name': '阿里百炼',
        'host_url': 'https://dashscope.aliyuncs.com',
        'api_prefix': '/compatible-mode/v1/chat/completions',
        // 2025-10-08 目前仅少数生图模型（qwen-image）支持同步任务，所以这里用轮询的异步任务前缀
        'image_generation_prefix':
            '/api/v1/services/aigc/text2image/image-synthesis',
        // 2025-10-09 语言合成 qwen-tts和qwen3-tts 都是同步任务了(和文生图同步任务一样的前缀)
        'text_to_speech_prefix':
            '/api/v1/services/aigc/multimodal-generation/generation',
        'speech_to_text_prefix':
            '/api/v1/services/aigc/multimodal-generation/generation',
      },
      {
        'id': 'siliconCloud',
        'display_name': '硅基流动',
        'host_url': 'https://api.siliconflow.cn',
        'api_prefix': '/v1/chat/completions',
        'image_generation_prefix': '/v1/images/generations',
        'text_to_speech_prefix': '/v1/audio/speech',
        'speech_to_text_prefix': '/v1/audio/transcriptions',
      },
      {
        'id': 'zhipu',
        'display_name': '智谱',
        'host_url': 'https://open.bigmodel.cn/api/paas',
        'api_prefix': '/v4/chat/completions',
        'image_generation_prefix': '/v4/images/generations',
        'text_to_speech_prefix': '/v4/audio/speech',
        'speech_to_text_prefix': '/v4/audio/transcriptions',
      },
      {
        'id': 'deepseek',
        'display_name': 'DeepSeek',
        'host_url': 'https://api.deepseek.com',
        'api_prefix': '/v1/chat/completions',
      },
      {
        'id': 'infini',
        'display_name': '无问芯穹',
        'host_url': 'https://cloud.infini-ai.com/maas',
        'api_prefix': '/v1/chat/completions',
      },
      {
        'id': 'lingyiwanwu',
        'display_name': '零一万物',
        'host_url': 'https://api.lingyiwanwu.com',
        'api_prefix': '/v1/chat/completions',
      },
      {
        'id': 'volcengine',
        'display_name': '火山方舟',
        'host_url': 'https://ark.cn-beijing.volces.com/api',
        'api_prefix': '/v3/chat/completions',
      },
    ];

    final batch = db.batch();
    for (var platform in platforms) {
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
    await _insertDefaultModels(db, now);
  }

  static Future<void> _insertDefaultModels(Database db, int timestamp) async {
    // 阿里百炼模型
    final aliyunModels = [
      {
        'id': 'qwen-plus-2025-09-11',
        'platform_id': 'aliyun',
        'model_name': 'qwen-plus-2025-09-11',
        'display_name': '通义千问-Plus-2025-09-11',
        'model_type': 'cc',
        'supports_thinking': 1,
        'supports_vision': 0,
        'supports_tool_calling': 1,
        'description': '通义千问-Plus-2025-09-11',
      },
      {
        'id': 'qwen-vl-plus-2025-08-15',
        'platform_id': 'aliyun',
        'model_name': 'qwen-vl-plus-2025-08-15',
        'display_name': '通义千问-Vision-Plus-2025-08-15',
        'model_type': 'cc',
        'supports_thinking': 0,
        'supports_vision': 1,
        'supports_tool_calling': 0,
        'description': '通义千问-Vision-Plus-2025-08-15',
      },
      {
        'id': 'qwen-flash-2025-07-28',
        'platform_id': 'aliyun',
        'model_name': 'qwen-flash-2025-07-28',
        'display_name': '通义千问-Flash-2025-07-28',
        'model_type': 'cc',
        'supports_thinking': 1,
        'supports_vision': 0,
        'supports_tool_calling': 1,
        'description': '通义千问系列速度最快、成本极低的模型，适合简单任务.',
      },
      // 阿里百炼图片生成模型(可同步任务)
      {
        'id': 'qwen-image-plus',
        'platform_id': 'aliyun',
        'model_name': 'qwen-image-plus',
        'display_name': 'Qwen-Image-Plus',
        'model_type': 'textToImage',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 0,
      },
      {
        'id': 'qwen-image',
        'platform_id': 'aliyun',
        'model_name': 'qwen-image',
        'display_name': 'Qwen-Image',
        'model_type': 'textToImage',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 0,
      },
      {
        'id': 'qwen-image-edit',
        'platform_id': 'aliyun',
        'model_name': 'qwen-image-edit',
        'display_name': 'Qwen-Image-Edit',
        'model_type': 'imageToImage',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 0,
      },
      // 异步任务的部分模型
      {
        'id': 'wan2.5-t2i-preview',
        'platform_id': 'aliyun',
        'model_name': 'wan2.5-t2i-preview',
        'display_name': 'wan2.5-t2i-preview',
        'model_type': 'textToImage',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 0,
      },
      {
        'id': 'wan2.2-t2i-flash',
        'platform_id': 'aliyun',
        'model_name': 'wan2.2-t2i-flash',
        'display_name': 'wan2.2-t2i-flash',
        'model_type': 'textToImage',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 0,
      },
      {
        'id': 'wan2.2-t2i-plus',
        'platform_id': 'aliyun',
        'model_name': 'wan2.2-t2i-plus',
        'display_name': 'wan2.2-t2i-plus',
        'model_type': 'textToImage',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 0,
      },
      {
        'id': 'flux-schnell',
        'platform_id': 'aliyun',
        'model_name': 'flux-schnell',
        'display_name': 'flux-schnell',
        'model_type': 'textToImage',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 0,
      },
      {
        'id': 'flux-dev',
        'platform_id': 'aliyun',
        'model_name': 'flux-dev',
        'display_name': 'flux-dev',
        'model_type': 'textToImage',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 0,
      },
      {
        'id': 'flux-merged',
        'platform_id': 'aliyun',
        'model_name': 'flux-merged',
        'display_name': 'flux-merged',
        'model_type': 'textToImage',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 0,
      },
      // 阿里百炼语音合成模型
      {
        'id': 'qwen-tts',
        'platform_id': 'aliyun',
        'model_name': 'qwen-tts',
        'display_name': 'qwen-tts',
        'model_type': 'textToSpeech',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 0,
        'description': '中文、英文,每1秒的音频对应 50个 Token',
      },
      {
        'id': 'qwen-tts-latest',
        'platform_id': 'aliyun',
        'model_name': 'qwen-tts-latest',
        'display_name': 'qwen-tts-latest',
        'model_type': 'textToSpeech',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 0,
        'description': '中文、英文,每1秒的音频对应 50个 Token',
      },
      {
        'id': 'qwen-tts-2025-05-22',
        'platform_id': 'aliyun',
        'model_name': 'qwen-tts-2025-05-22',
        'display_name': 'qwen-tts-2025-05-22',
        'model_type': 'textToSpeech',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 0,
        'description': '中文、英文,每1秒的音频对应 50个 Token',
      },
      {
        'id': 'qwen-tts-2025-04-10',
        'platform_id': 'aliyun',
        'model_name': 'qwen-tts-2025-04-10',
        'display_name': 'qwen-tts-2025-04-10',
        'model_type': 'textToSpeech',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 0,
        'description': '中文、英文,每1秒的音频对应 50个 Token',
      },
      {
        'id': 'qwen3-tts-flash',
        'platform_id': 'aliyun',
        'model_name': 'qwen3-tts-flash',
        'display_name': 'qwen3-tts-flash',
        'model_type': 'textToSpeech',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 0,
        'description':
            '中文（普通话、北京、上海、四川、南京、陕西、闽南、天津、粤语）、英文、西班牙语、俄语、意大利语、法语、韩语、日语、德语、葡萄牙语;0.8元/万字符,一个汉字 = 2个字符',
      },
      {
        'id': 'qwen3-tts-flash-2025-09-18',
        'platform_id': 'aliyun',
        'model_name': 'qwen3-tts-flash-2025-09-18',
        'display_name': 'qwen3-tts-flash-2025-09-18',
        'model_type': 'textToSpeech',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 0,
        'description': '阿里百炼语音合成模型',
      },
      // 阿里百炼语音识别模型
      {
        'id': 'qwen3-asr-flash',
        'platform_id': 'aliyun',
        'model_name': 'qwen3-asr-flash',
        'display_name': 'Qwen3-ASR-Flash',
        'model_type': 'speechToText',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 0,
        'description': '录音文件识别-通义千问;0.00022元/秒',
      },
      {
        'id': 'qwen3-asr-flash-2025-09-08',
        'platform_id': 'aliyun',
        'model_name': 'qwen3-asr-flash-2025-09-08',
        'display_name': 'Qwen3-ASR-Flash-2025-09-08',
        'model_type': 'speechToText',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 0,
        'description': '录音文件识别-通义千问;0.00022元/秒',
      },
    ];

    // siliconflow 模型
    final siliconflowModels = [
      {
        'id': 'glm-4.1v-9b-thinking',
        'platform_id': 'siliconCloud',
        'model_name': 'THUDM/GLM-4.1V-9B-Thinking',
        'display_name': 'GLM-4.1V-9B-Thinking',
        'model_type': 'cc',
        'supports_thinking': 1,
        'supports_vision': 1,
        'supports_tool_calling': 0,
        'description': ' GLM 系列的视觉推理模型',
      },
      {
        'id': 'glm-4-9b-0414',
        'platform_id': 'siliconCloud',
        'model_name': 'THUDM/GLM-4-9B-0414',
        'display_name': 'GLM-4-9B-0414',
        'model_type': 'cc',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 1,
        'description': 'GLM 系列的小型对话模型',
      },
      {
        'id': 'glm-z1-9b-0414',
        'platform_id': 'siliconCloud',
        'model_name': 'THUDM/GLM-Z1-9B-0414',
        'display_name': 'GLM-Z1-9B-0414',
        'model_type': 'cc',
        'supports_thinking': 1,
        'supports_vision': 0,
        'supports_tool_calling': 1,
        'description': 'GLM 系列的小型推理模型',
      },
      // 硅基流动图片生成模型
      {
        'id': 'qwen-image-siliconcloud',
        'platform_id': 'siliconCloud',
        'model_name': 'Qwen/Qwen-Image',
        'display_name': 'Qwen-Image',
        'model_type': 'textToImage',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 0,
      },
      {
        'id': 'kolors-siliconcloud',
        'platform_id': 'siliconCloud',
        'model_name': 'Kwai-Kolors/Kolors',
        'display_name': 'Kolors',
        'model_type': 'textToImage',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 0,
      },
      // 硅基流动语音合成模型
      {
        'id': 'fnlp-moss-ttsd-v0.5',
        'platform_id': 'siliconCloud',
        'model_name': 'fnlp/MOSS-TTSD-v0.5',
        'display_name': 'fnlp/MOSS-TTSD-v0.5',
        'model_type': 'textToSpeech',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 0,
        'description': '¥50/ M UTF-8 bytes',
      },
      {
        'id': 'funaudio-llm-cosyvoice2-0.5b',
        'platform_id': 'siliconCloud',
        'model_name': 'FunAudioLLM/CosyVoice2-0.5B',
        'display_name': 'FunAudioLLM/CosyVoice2-0.5B',
        'model_type': 'textToSpeech',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 0,
        'description': '硅基流动语音合成模型',
      },
      // 硅基流动语音识别模型
      {
        'id': 'funaudio-llm-sensevoicesmall',
        'platform_id': 'siliconCloud',
        'model_name': 'FunAudioLLM/SenseVoiceSmall',
        'display_name': 'FunAudioLLM/SenseVoiceSmall',
        'model_type': 'speechToText',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 0,
      },
      {
        'id': 'teleai-telespeechasr',
        'platform_id': 'siliconCloud',
        'model_name': 'TeleAI/TeleSpeechASR',
        'display_name': 'TeleAI/TeleSpeechASR',
        'model_type': 'speechToText',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 0,
      },
    ];

    // 智谱模型
    final zhipuModels = [
      {
        'id': 'glm-4.5-flash',
        'platform_id': 'zhipu',
        'model_name': 'glm-4.5-flash',
        'display_name': 'GLM-4.5-Flash',
        'model_type': 'cc',
        'supports_thinking': 1,
        'supports_vision': 0,
        'supports_tool_calling': 1,
        'description': '智谱轻量级对话模型',
      },
      {
        'id': 'glm-4-flash-250414',
        'platform_id': 'zhipu',
        'model_name': 'glm-4-flash-250414',
        'display_name': 'GLM-4-Flash-250414',
        'model_type': 'cc',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 1,
      },
      {
        'id': 'glm-z1-flash',
        'platform_id': 'zhipu',
        'model_name': 'glm-z1-flash',
        'display_name': 'GLM-Z1-Flash',
        'model_type': 'cc',
        'supports_thinking': 1,
        'supports_vision': 0,
        'supports_tool_calling': 1,
        'description': '智谱轻量级推理模型',
      },
      {
        'id': 'glm-4v-flash',
        'platform_id': 'zhipu',
        'model_name': 'glm-4v-flash',
        'display_name': 'GLM-4V-Flash',
        'model_type': 'cc',
        'supports_thinking': 0,
        'supports_vision': 1,
        'supports_tool_calling': 0,
        'description': '智谱轻量级视觉模型',
      },
      {
        'id': 'glm-4.1v-thinking-flash',
        'platform_id': 'zhipu',
        'model_name': 'glm-4.1v-thinking-flash',
        'display_name': 'GLM-4.1V-Thinking-Flash',
        'model_type': 'cc',
        'supports_thinking': 1,
        'supports_vision': 1,
        'supports_tool_calling': 0,
        'description': '智谱轻量级视觉推理模型',
      },
      // 智谱图片生成模型
      {
        'id': 'cogview-4-250304-zhipu',
        'platform_id': 'zhipu',
        'model_name': 'cogview-4-250304',
        'display_name': 'CogView-4-250304',
        'model_type': 'textToImage',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 0,
      },
      {
        'id': 'cogview-4-zhipu',
        'platform_id': 'zhipu',
        'model_name': 'cogview-4',
        'display_name': 'CogView-4',
        'model_type': 'textToImage',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 0,
      },
      {
        'id': 'cogview-3-flash',
        'platform_id': 'zhipu',
        'model_name': 'cogview-3-flash',
        'display_name': 'CogView-3-Flash',
        'model_type': 'textToImage',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 0,
      },
      // 智谱语音合成模型
      {
        'id': 'cogtts',
        'platform_id': 'zhipu',
        'model_name': 'cogtts',
        'display_name': 'CogTTS',
        'model_type': 'textToSpeech',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 0,
        'description': '¥4/万字符',
      },
      // 智谱语音识别模型
      {
        'id': 'glm-asr',
        'platform_id': 'zhipu',
        'model_name': 'glm-asr',
        'display_name': 'GLM-ASR',
        'model_type': 'speechToText',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 0,
        'description': '0.06 元/分钟',
      },
    ];

    // DeepSeek模型
    final deepseekModels = [
      {
        'id': 'deepseek-chat',
        'platform_id': 'deepseek',
        'model_name': 'deepseek-chat',
        'display_name': 'DeepSeek Chat',
        'model_type': 'cc',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 1,
        'description': 'DeepSeek的对话模型',
      },
      {
        'id': 'deepseek-reasoner',
        'platform_id': 'deepseek',
        'model_name': 'deepseek-reasoner',
        'display_name': 'DeepSeek Reasoner',
        'model_type': 'cc',
        'supports_thinking': 1,
        'supports_vision': 0,
        'supports_tool_calling': 1,
        'description': 'DeepSeek的推理模型',
      },
    ];

    // 无问芯穹模型
    final infiniModels = [
      {
        'id': 'deepseek-v3.1',
        'platform_id': 'infini',
        'model_name': 'deepseek-v3.1',
        'display_name': 'DeepSeek V3.1',
        'model_type': 'cc',
        'supports_thinking': 1,
        'supports_vision': 0,
        'supports_tool_calling': 1,
      },
      {
        'id': 'kimi-k2-instruct',
        'platform_id': 'infini',
        'model_name': 'kimi-k2-instruct',
        'display_name': 'Kimi K2 Instruct',
        'model_type': 'cc',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 1,
      },
      {
        'id': 'glm-4.5',
        'platform_id': 'infini',
        'model_name': 'glm-4.5',
        'display_name': 'GLM-4.5',
        'model_type': 'cc',
        'supports_thinking': 1,
        'supports_vision': 0,
        'supports_tool_calling': 1,
      },
      {
        'id': 'glm-4.5v',
        'platform_id': 'infini',
        'model_name': 'glm-4.5v',
        'display_name': 'GLM-4.5V',
        'model_type': 'cc',
        'supports_thinking': 1,
        'supports_vision': 1,
        'supports_tool_calling': 0,
      },
    ];

    // 零一万物模型
    final lingyiwanwuModels = [
      {
        'id': 'yi-lightning',
        'platform_id': 'lingyiwanwu',
        'model_name': 'yi-lightning',
        'display_name': 'Yi Lightning',
        'model_type': 'cc',
        'supports_thinking': 0,
        'supports_vision': 0,
        'supports_tool_calling': 1,
      },
      {
        'id': 'yi-vision-v2',
        'platform_id': 'lingyiwanwu',
        'model_name': 'yi-vision-v2',
        'display_name': 'Yi Vision V2',
        'model_type': 'cc',
        'supports_thinking': 0,
        'supports_vision': 1,
        'supports_tool_calling': 0,
      },
    ];

    // 火山方舟
    final volcengineModels = [
      {
        'id': 'doubao-seed-1-6-250615',
        'platform_id': 'volcengine',
        'model_name': 'doubao-seed-1-6-250615',
        'display_name': 'Doubao-Seed-1.6-250615',
        'model_type': 'cc',
        'supports_thinking': 1,
        'supports_vision': 1,
        'supports_tool_calling': 1,
      },
      {
        'id': 'doubao-seed-1-6-thinking-250715',
        'platform_id': 'volcengine',
        'model_name': 'doubao-seed-1-6-thinking-250715',
        'display_name': 'Doubao-Seed-1.6-thinking-250715',
        'model_type': 'cc',
        'supports_thinking': 1,
        'supports_vision': 1,
        'supports_tool_calling': 1,
      },
      {
        'id': 'doubao-seed-1-6-flash-250828',
        'platform_id': 'volcengine',
        'model_name': 'doubao-seed-1-6-flash-250828',
        'display_name': 'Doubao-Seed-1.6-flash-250828',
        'model_type': 'cc',
        'supports_thinking': 1,
        'supports_vision': 1,
        'supports_tool_calling': 1,
      },
      {
        'id': 'doubao-seed-1-6-vision-250815',
        'platform_id': 'volcengine',
        'model_name': 'doubao-seed-1-6-vision-250815',
        'display_name': 'Doubao-Seed-1.6-vision-250815',
        'model_type': 'cc',
        'supports_thinking': 1,
        'supports_vision': 1,
        'supports_tool_calling': 1,
      },
      {
        'id': 'doubao-1-5-pro-32k-250115',
        'platform_id': 'volcengine',
        'model_name': 'doubao-1-5-pro-32k-250115',
        'display_name': 'Doubao-1.5-pro-32k-250115',
        'model_type': 'cc',
        'supports_thinking': 1,
        'supports_vision': 0,
        'supports_tool_calling': 1,
      },
      {
        'id': 'doubao-1-5-pro-256k-250115',
        'platform_id': 'volcengine',
        'model_name': 'doubao-1-5-pro-256k-250115',
        'display_name': 'Doubao-1.5-pro-256k-250115',
        'model_type': 'cc',
        'supports_thinking': 1,
        'supports_vision': 0,
        'supports_tool_calling': 1,
      },
    ];

    final batch = db.batch();
    for (final model in [
      ...aliyunModels,
      ...siliconflowModels,
      ...deepseekModels,
      ...zhipuModels,
      ...infiniModels,
      ...lingyiwanwuModels,
      ...volcengineModels,
    ]) {
      batch.insert(tableUnifiedModelSpec, {
        ...model,
        'is_active': 1,
        'is_built_in': 1,
        'is_favorite': 0,
        'created_at': timestamp,
        'updated_at': timestamp,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit();
  }

  /// 初始化预设搭档
  static Future<void> initDefaultPartners(Database db) async {
    final now = DateTime.now();

    // 确保同名的搭档工具id始终是一样的，不用uuid，使用identityHashCode
    final defaultPartners = [
      UnifiedChatPartner(
        id: identityHashCode('翻译助手').toString(),
        name: '翻译助手',
        prompt:
            '你是一个好用的翻译助手。请将我的中文翻译成英文，将所有非中文的翻译成中文。我发给你所有的话都是需要翻译的内容，你不需要回答翻译结果。翻译结果请符合中文的语言习惯。',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      UnifiedChatPartner(
        id: identityHashCode('夸夸机').toString(),
        name: '夸夸机',
        prompt:
            '你是我的私人助理，你最重要的工作就是不断地鼓励我、激励我、夸赞我。你需要以温柔、体贴、亲切的语气和我聊天。你的聊天风格要以特别可爱有趣，你的每一个回答都要体现这一点。',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      UnifiedChatPartner(
        id: identityHashCode('图片文字翻译大师').toString(),
        name: '图片文字翻译大师',
        prompt:
            '你是一个图片文字翻译大师，将用户给你发送的图片识别成文字，然后返回给用户。如果图片中文字不是中文，则将其翻译为中文。只翻译，不做任何其他操作。',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      UnifiedChatPartner(
        id: identityHashCode('图片文字识别大师').toString(),
        name: '图片文字识别大师',
        prompt: '你是一个图片文字识别大师，将用户给你发送的图片识别成文字，然后返回给用户。只识别，不做任何其他操作。',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      UnifiedChatPartner(
        id: identityHashCode('长文总结').toString(),
        name: '长文总结',
        prompt: '当用户给你一大段文字时，你首先需要将其精简总结。如果用户有提问题，你再回答问题。始终先总结文段，再回答问题。',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      UnifiedChatPartner(
        id: identityHashCode('图片生成大师').toString(),
        name: '图片生成大师',
        prompt:
            '你是一个专业的图片生成助手。当用户描述想要的图片时，你会帮助优化和完善提示词，使其更适合AI图片生成。你会：1. 分析用户需求，提供详细的英文提示词；2. 建议合适的图片尺寸和风格；3. 如果用户提供的描述不够详细，主动询问更多细节。请始终用中文回复用户，但生成的提示词要用英文。',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      UnifiedChatPartner(
        id: identityHashCode('创意绘画师').toString(),
        name: '创意绘画师',
        prompt:
            '你是一位富有创意的艺术家，擅长将抽象的想法转化为具体的视觉描述。当用户想要生成图片时，你会：1. 理解用户的创意意图；2. 提供富有艺术感的详细描述；3. 建议不同的艺术风格（如写实、卡通、油画、水彩等）；4. 优化构图和色彩搭配建议。用中文与用户交流，生成英文提示词。',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
      UnifiedChatPartner(
        id: identityHashCode('商业设计师').toString(),
        name: '商业设计师',
        prompt:
            '你是一位专业的商业设计师，专注于商业用途的图片生成。你会帮助用户：1. 创建适合商业使用的图片描述；2. 考虑品牌调性和目标受众；3. 建议合适的商业图片风格（如产品展示、广告海报、社交媒体配图等）；4. 确保生成的图片符合商业标准。用中文交流，提供英文提示词。',
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    // 测试，先删除，再新增内置的
    await db.delete(UnifiedChatDdl.tableUnifiedChatPartner);

    for (final partner in defaultPartners) {
      await db.insert(
        UnifiedChatDdl.tableUnifiedChatPartner,
        partner.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }
}
