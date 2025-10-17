// ignore_for_file: non_constant_identifier_names

// 【注意】：平台id要和 UnifiedPlatformId 枚举一致
List<Map<String, dynamic>> BUILD_IN_PLATFORMS = [
  {
    'id': 'aliyun',
    'display_name': '阿里百炼',
    'host_url': 'https://dashscope.aliyuncs.com',
    'cc_prefix': '/compatible-mode/v1/chat/completions',
    // 2025-10-08 目前仅少数生图模型（qwen-image）支持同步任务，所以这里用轮询的异步任务前缀
    'img_gen_prefix': '/api/v1/services/aigc/text2image/image-synthesis',
    // 2025-10-09 语言合成 qwen-tts和qwen3-tts 都是同步任务了(和文生图同步任务一样的前缀)
    'tts_prefix': '/api/v1/services/aigc/multimodal-generation/generation',
    'asr_prefix': '/api/v1/services/aigc/multimodal-generation/generation',
  },
  {
    'id': 'siliconCloud',
    'display_name': '硅基流动',
    'host_url': 'https://api.siliconflow.cn',
    'cc_prefix': '/v1/chat/completions',
    'img_gen_prefix': '/v1/images/generations',
    'tts_prefix': '/v1/audio/speech',
    'asr_prefix': '/v1/audio/transcriptions',
  },
  {
    'id': 'zhipu',
    'display_name': '智谱',
    'host_url': 'https://open.bigmodel.cn/api/paas',
    'cc_prefix': '/v4/chat/completions',
    'img_gen_prefix': '/v4/images/generations',
    'tts_prefix': '/v4/audio/speech',
    'asr_prefix': '/v4/audio/transcriptions',
  },
  {
    'id': 'volcengine',
    'display_name': '火山方舟',
    'host_url': 'https://ark.cn-beijing.volces.com/api',
    'cc_prefix': '/v3/chat/completions',
    'img_gen_prefix': '/v3/images/generations',
  },
  {
    'id': 'deepseek',
    'display_name': 'DeepSeek',
    'host_url': 'https://api.deepseek.com',
    'cc_prefix': '/v1/chat/completions',
  },
  {
    'id': 'lingyiwanwu',
    'display_name': '零一万物',
    'host_url': 'https://api.lingyiwanwu.com',
    'cc_prefix': '/v1/chat/completions',
  },
  {
    'id': 'infini',
    'display_name': '无问芯穹',
    'host_url': 'https://cloud.infini-ai.com/maas',
    'cc_prefix': '/v1/chat/completions',
  },
];
