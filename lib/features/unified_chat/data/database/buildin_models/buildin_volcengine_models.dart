// 火山方舟(豆包)平台模型
// 2026-09-02 核对：doubao-seed-1-6系仍为现役旗舰文本模型；
// 视频新增Seedance 2.5；Seedream 3.0/seededit 3.0(已被4.0替代)与
// doubao-1-5-pro(2025初旧款)不再内置
final volcengineModels = [
  // ===== 文本对话 =====
  {
    'id': 'doubao-seed-1-6-250615',
    'platform_id': 'volcengine',
    'model_name': 'doubao-seed-1-6-250615',
    'display_name': '豆包Seed 1.6(旗舰)',
    'model_type': 'cc',
    'supports_thinking': 1,
    'supports_vision': 1,
    'supports_tool_calling': 1,
  },
  {
    'id': 'doubao-seed-1-6-thinking-250715',
    'platform_id': 'volcengine',
    'model_name': 'doubao-seed-1-6-thinking-250715',
    'display_name': '豆包Seed 1.6-Thinking(深度思考)',
    'model_type': 'cc',
    'supports_thinking': 1,
    'supports_vision': 1,
    'supports_tool_calling': 1,
  },
  {
    'id': 'doubao-seed-1-6-flash-250828',
    'platform_id': 'volcengine',
    'model_name': 'doubao-seed-1-6-flash-250828',
    'display_name': '豆包Seed 1.6-Flash(快速)',
    'model_type': 'cc',
    'supports_thinking': 1,
    'supports_vision': 1,
    'supports_tool_calling': 1,
  },
  {
    'id': 'doubao-seed-1-6-vision-250815',
    'platform_id': 'volcengine',
    'model_name': 'doubao-seed-1-6-vision-250815',
    'display_name': '豆包Seed 1.6-Vision(视觉理解)',
    'model_type': 'cc',
    'supports_vision': 1,
    'supports_tool_calling': 1,
  },
  // ===== 图片生成 =====
  {
    'id': 'doubao-seedream-4-0-250828',
    'platform_id': 'volcengine',
    'model_name': 'doubao-seedream-4-0-250828',
    'display_name': 'Seedream 4.0(图片生成)',
    'model_type': 'image',
    'supports_image_input': 1,
  },
  // ===== 视频生成 =====
  {
    'id': 'doubao-seedance-2-5-260628',
    'platform_id': 'volcengine',
    'model_name': 'doubao-seedance-2-5-260628',
    'display_name': 'Seedance 2.5(视频生成,音视频联合)',
    'model_type': 'video',
    'supports_image_input': 1,
  },
  {
    'id': 'doubao-seedance-1-5-pro',
    'platform_id': 'volcengine',
    'model_name': 'doubao-seedance-1-5-pro',
    'display_name': 'Seedance 1.5-Pro(视频生成)',
    'model_type': 'video',
    'supports_image_input': 1,
  },
];
