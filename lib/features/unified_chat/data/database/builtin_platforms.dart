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
    // 视频生成(异步任务提交)，查询统一走 /api/v1/tasks/{taskId}
    'video_gen_prefix':
        '/api/v1/services/aigc/video-generation/video-synthesis',
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
    // 视频生成(提交任务)，查询走 POST /v1/video/status
    'video_gen_prefix': '/v1/video/submit',
    'tts_prefix': '/v1/audio/speech',
    'asr_prefix': '/v1/audio/transcriptions',
  },
  {
    'id': 'zhipu',
    'display_name': '智谱',
    'host_url': 'https://open.bigmodel.cn/api/paas',
    'cc_prefix': '/v4/chat/completions',
    'img_gen_prefix': '/v4/images/generations',
    // 视频生成(提交任务)，查询走 GET /v4/async-result/{taskId}
    'video_gen_prefix': '/v4/videos/generations',
    'tts_prefix': '/v4/audio/speech',
    'asr_prefix': '/v4/audio/transcriptions',
  },
  {
    'id': 'volcengine',
    'display_name': '火山方舟',
    'host_url': 'https://ark.cn-beijing.volces.com/api',
    'cc_prefix': '/v3/chat/completions',
    'img_gen_prefix': '/v3/images/generations',
    // 视频生成(Seedance系列，内容生成异步任务)，查询走 GET /v3/contents/generations/tasks/{id}
    'video_gen_prefix': '/v3/contents/generations/tasks',
  },
  {
    'id': 'deepseek',
    'display_name': 'DeepSeek',
    'host_url': 'https://api.deepseek.com',
    'cc_prefix': '/v1/chat/completions',
  },
  // 2026-09-02 移除已停服的内置平台：零一万物(lingyiwanwu)、无问芯穹(infini)
];
