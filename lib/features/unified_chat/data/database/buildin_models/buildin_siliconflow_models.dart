// 硅基流动平台模型
// 2026-09-10 选择截至当前时间分类最新的几个模型
final siliconflowModels = [
  // ===== 文本对话 =====
  {
    'id': 'deepseek-ai/DeepSeek-V4-Flash',
    'platform_id': 'siliconCloud',
    'model_name': 'deepseek-ai/DeepSeek-V4-Flash',
    'display_name': 'DeepSeek-V4-Flash(0731)',
    'model_type': 'cc',
    'supports_thinking': 1,
    'supports_tool_calling': 1,
  },
  {
    'id': 'zai-org/GLM-5.3',
    'platform_id': 'siliconCloud',
    'model_name': 'zai-org/GLM-5.3',
    'display_name': 'GLM-5.3',
    'model_type': 'cc',
    'supports_thinking': 1,
    'supports_tool_calling': 1,
  },
  // ===== 图片生成 =====
  {
    'id': 'Tongyi-MAI/Z-Image-Turbo',
    'platform_id': 'siliconCloud',
    'model_name': 'Tongyi-MAI/Z-Image-Turbo',
    'display_name': 'Z-Image-Turbo',
    'model_type': 'image',
  },
  {
    'id': 'Tongyi-MAI/Z-Image',
    'platform_id': 'siliconCloud',
    'model_name': 'Tongyi-MAI/Z-Image',
    'display_name': 'Z-Image',
    'model_type': 'image',
  },
  {
    'id': 'Kwai-Kolors/Kolors',
    'platform_id': 'siliconCloud',
    'model_name': 'Kwai-Kolors/Kolors',
    'display_name': 'Kolors(旧但免费)',
    'model_type': 'image',
  },
  // ===== 视频生成(硅基当前仅有万相2.2系) =====
  {
    'id': 'Wan-AI/Wan2.2-T2V-A14B',
    'platform_id': 'siliconCloud',
    'model_name': 'Wan-AI/Wan2.2-T2V-A14B',
    'display_name': 'Wan2.2-T2V-A14B',
    'model_type': 'video',
  },
  {
    'id': 'Wan-AI/Wan2.2-I2V-A14B',
    'platform_id': 'siliconCloud',
    'model_name': 'Wan-AI/Wan2.2-I2V-A14B',
    'display_name': 'Wan2.2-I2V-A14B',
    'model_type': 'video',
    'supports_image_input': 1,
  },
  // ===== 语音合成 =====
  {
    'id': 'fnlp/MOSS-TTSD-v0.5',
    'platform_id': 'siliconCloud',
    'model_name': 'fnlp/MOSS-TTSD-v0.5',
    'display_name': 'MOSS-TTSD-v0.5',
    'model_type': 'tts',
  },
  {
    'id': 'FunAudioLLM/CosyVoice2-0.5B',
    'platform_id': 'siliconCloud',
    'model_name': 'FunAudioLLM/CosyVoice2-0.5B',
    'display_name': 'CosyVoice2-0.5B',
    'model_type': 'tts',
  },
  // ===== 语音识别 =====
  {
    'id': 'XingChenAGI/XingChenGSR-V1.0',
    'platform_id': 'siliconCloud',
    'model_name': 'XingChenAGI/XingChenGSR-V1.0',
    'display_name': 'XingChenGSR V1.0',
    'model_type': 'asr',
  },
  {
    'id': 'XingChenAGI/XingChenASR-V3.2-Ultra',
    'platform_id': 'siliconCloud',
    'model_name': 'XingChenAGI/XingChenASR-V3.2-Ultra',
    'display_name': 'XingChenASR V3.2-Ultra',
    'model_type': 'asr',
  },
];
