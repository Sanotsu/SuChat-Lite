// 小米MiMo官方平台模型
// 2026-09-10 按官方模型页选择当前在售的V2.5系列模型
// (旧v2系列已于2026-06-30停服；voicedesign/voiceclone需音色描述或
// 克隆样本等额外交互，暂不内置)
// 能力备注：mimo-v2.5支持全模态理解(图像/音频/视频输入)，pro仅文本；
// 两者都支持深度思考/工具调用/结构化输出
final mimoModels = [
  {
    'id': 'mimo-v2.5-pro',
    'platform_id': 'mimo',
    'model_name': 'mimo-v2.5-pro',
    'display_name': 'MiMo-V2.5-Pro',
    'model_type': 'cc',
    'supports_thinking': 1,
    'supports_tool_calling': 1,
  },
  {
    'id': 'mimo-v2.5',
    'platform_id': 'mimo',
    'model_name': 'mimo-v2.5',
    'display_name': 'MiMo-V2.5',
    'model_type': 'cc',
    'supports_thinking': 1,
    'supports_tool_calling': 1,
    'supports_vision': 1,
    'supports_image_input': 1,
  },
  {
    'id': 'mimo-v2.5-asr',
    'platform_id': 'mimo',
    'model_name': 'mimo-v2.5-asr',
    'display_name': 'MiMo-V2.5-ASR',
    'model_type': 'asr',
  },
  {
    'id': 'mimo-v2.5-tts',
    'platform_id': 'mimo',
    'model_name': 'mimo-v2.5-tts',
    'display_name': 'MiMo-V2.5-TTS',
    'model_type': 'tts',
  },
];
