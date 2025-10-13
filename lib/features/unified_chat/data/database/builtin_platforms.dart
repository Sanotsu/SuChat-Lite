// ignore_for_file: non_constant_identifier_names

// 【注意】：平台id要和 UnifiedPlatformId 枚举一致
List<Map<String, dynamic>> BUILD_IN_PLATFORMS = [
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
    'image_generation_prefix': '/v3/images/generations',
  },
];
