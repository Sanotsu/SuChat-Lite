// 智谱平台模型
// 2026-09-10 选择截至当前时间分类最新的几个模型
final zhipuModels = [
  // ===== 文本对话 =====
  {
    'id': 'glm-5.3',
    'platform_id': 'zhipu',
    'model_name': 'glm-5.3',
    'display_name': 'GLM-5.3',
    'model_type': 'cc',
    'supports_thinking': 1,
    'supports_tool_calling': 1,
  },
  {
    'id': 'glm-5.3-flash',
    'platform_id': 'zhipu',
    'model_name': 'glm-5.3-flash',
    'display_name': 'GLM-5.3-Flash',
    'model_type': 'cc',
    'supports_thinking': 1,
    'supports_vision': 1,
    'supports_tool_calling': 1,
  },
  // ===== 图片生成 =====
  {
    'id': 'glm-image',
    'platform_id': 'zhipu',
    'model_name': 'glm-image',
    'display_name': 'GLM-image',
    'model_type': 'image',
  },
  {
    'id': 'cogview-4-250304',
    'platform_id': 'zhipu',
    'model_name': 'cogview-4-250304',
    'display_name': 'CogView-4',
    'model_type': 'image',
  },
  // ===== 视频生成 =====
  {
    'id': 'cogvideox-3',
    'platform_id': 'zhipu',
    'model_name': 'cogvideox-3',
    'display_name': 'CogVideoX-3',
    'model_type': 'video',
  },
  // ===== 语音合成 =====
  {
    'id': 'glm-tts',
    'platform_id': 'zhipu',
    'model_name': 'glm-tts',
    'display_name': 'GLM-TTS',
    'model_type': 'tts',
  },
  // ===== 语音识别 =====
  {
    'id': 'glm-asr-2512',
    'platform_id': 'zhipu',
    'model_name': 'glm-asr-2512',
    'display_name': 'GLM-ASR-2512',
    'model_type': 'asr',
  },
];
