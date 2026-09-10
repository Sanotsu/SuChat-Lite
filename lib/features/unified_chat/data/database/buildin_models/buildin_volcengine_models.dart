// 火山方舟(豆包)平台模型
// 2026-09-10 选择截至当前时间分类最新的几个模型
final volcengineModels = [
  // ===== 文本对话 =====
  {
    'id': 'doubao-seed-2-1-pro-260628',
    'platform_id': 'volcengine',
    'model_name': 'doubao-seed-2-1-pro-260628',
    'display_name': 'Seed-2.1-pro',
    'model_type': 'cc',
    'supports_thinking': 1,
    'supports_vision': 1,
    'supports_tool_calling': 1,
  },
  {
    'id': 'doubao-seed-2-1-turbo-260628',
    'platform_id': 'volcengine',
    'model_name': 'doubao-seed-2-1-turbo-260628',
    'display_name': 'Seed-2.1-turbo',
    'model_type': 'cc',
    'supports_thinking': 1,
    'supports_vision': 1,
    'supports_tool_calling': 1,
  },
  {
    'id': 'deepseek-v4-pro-ga-260813',
    'platform_id': 'volcengine',
    'model_name': 'deepseek-v4-pro-ga-260813',
    'display_name': 'DeepSeek-V4-Pro正式版',
    'model_type': 'cc',
    'supports_thinking': 1,
    'supports_tool_calling': 1,
  },
  {
    'id': 'deepseek-v4-flash-ga-260731',
    'platform_id': 'volcengine',
    'model_name': 'deepseek-v4-flash-ga-260731',
    'display_name': 'DeepSeek-V4-Flash正式版',
    'model_type': 'cc',
    'supports_thinking': 1,
    'supports_tool_calling': 1,
  },

  // ===== 图片生成 =====
  {
    'id': 'doubao-seedream-5-0-pro-260628',
    'platform_id': 'volcengine',
    'model_name': 'doubao-seedream-5-0-pro-260628',
    'display_name': 'Seedream-5.0-pro(图片生成)',
    'model_type': 'image',
    'supports_image_input': 1,
  },
  {
    'id': 'doubao-seedream-5-0-260128',
    'platform_id': 'volcengine',
    'model_name': 'doubao-seedream-5-0-260128',
    'display_name': 'Seedream-5.0-lite(图片生成)',
    'model_type': 'image',
    'supports_image_input': 1,
  },
  // ===== 视频生成 =====
  {
    'id': 'doubao-seedance-2-5-260628',
    'platform_id': 'volcengine',
    'model_name': 'doubao-seedance-2-5-260628',
    'display_name': 'Seedance 2.5(视频生成)',
    'model_type': 'video',
    'supports_image_input': 1,
  },
  {
    'id': 'doubao-seedance-2-0-260128',
    'platform_id': 'volcengine',
    'model_name': 'doubao-seedance-2-0-260128',
    'display_name': 'Seedance-2.0(视频生成)',
    'model_type': 'video',
    'supports_image_input': 1,
  },
  {
    'id': 'doubao-seedance-2-0-mini-260615',
    'platform_id': 'volcengine',
    'model_name': 'doubao-seedance-2-0-mini-260615',
    'display_name': 'Seedance-2.0-mini(视频生成)',
    'model_type': 'video',
    'supports_image_input': 1,
  },
];
