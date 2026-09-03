// 硅基流动平台模型
// 2026-09-02 按官方模型中心核对：保留当前在架的主力开源模型；
// GLM-4.x全系、DeepSeek-V3.x/R1、Qwen3-8B等旧模型不再内置
final siliconflowModels = [
  // ===== 文本对话 =====
  {
    'id': 'deepseek-ai/DeepSeek-V4-Pro',
    'platform_id': 'siliconCloud',
    'model_name': 'deepseek-ai/DeepSeek-V4-Pro',
    'display_name': 'DeepSeek-V4-Pro(旗舰)',
    'model_type': 'cc',
    'supports_thinking': 1,
    'supports_tool_calling': 1,
  },
  {
    'id': 'deepseek-ai/DeepSeek-V4-Flash',
    'platform_id': 'siliconCloud',
    'model_name': 'deepseek-ai/DeepSeek-V4-Flash',
    'display_name': 'DeepSeek-V4-Flash(快速)',
    'model_type': 'cc',
    'supports_thinking': 1,
    'supports_tool_calling': 1,
  },
  {
    'id': 'zai-org/GLM-5.3',
    'platform_id': 'siliconCloud',
    'model_name': 'zai-org/GLM-5.3',
    'display_name': 'GLM-5.3(旗舰,强制思考)',
    'model_type': 'cc',
    'supports_thinking': 1,
    'supports_vision': 1,
    'supports_tool_calling': 1,
  },
  {
    'id': 'moonshotai/Kimi-K3',
    'platform_id': 'siliconCloud',
    'model_name': 'moonshotai/Kimi-K3',
    'display_name': 'Kimi-K3',
    'model_type': 'cc',
    'supports_thinking': 1,
    'supports_tool_calling': 1,
  },
  {
    'id': 'Qwen/Qwen3-VL-235B-A22B-Instruct',
    'platform_id': 'siliconCloud',
    'model_name': 'Qwen/Qwen3-VL-235B-A22B-Instruct',
    'display_name': 'Qwen3-VL-235B-A22B-Instruct(视觉)',
    'model_type': 'cc',
    'supports_vision': 1,
    'supports_tool_calling': 1,
  },
  // ===== 图片生成 =====
  {
    'id': 'Qwen/Qwen-Image',
    'platform_id': 'siliconCloud',
    'model_name': 'Qwen/Qwen-Image',
    'display_name': 'Qwen-Image(图像生成)',
    'model_type': 'image',
  },
  // ===== 视频生成(硅基当前仅有万相2.2系) =====
  {
    'id': 'Wan-AI/Wan2.2-T2V-A14B',
    'platform_id': 'siliconCloud',
    'model_name': 'Wan-AI/Wan2.2-T2V-A14B',
    'display_name': 'Wan2.2-T2V-A14B(文生视频)',
    'model_type': 'video',
  },
  {
    'id': 'Wan-AI/Wan2.2-I2V-A14B',
    'platform_id': 'siliconCloud',
    'model_name': 'Wan-AI/Wan2.2-I2V-A14B',
    'display_name': 'Wan2.2-I2V-A14B(图生视频首帧)',
    'model_type': 'video',
    'supports_image_input': 1,
  },
  // ===== 语音合成 =====
  {
    'id': 'FunAudioLLM/CosyVoice2-0.5B',
    'platform_id': 'siliconCloud',
    'model_name': 'FunAudioLLM/CosyVoice2-0.5B',
    'display_name': 'CosyVoice2-0.5B(语音合成)',
    'model_type': 'tts',
  },
  // ===== 语音识别 =====
  {
    'id': 'FunAudioLLM/SenseVoiceSmall',
    'platform_id': 'siliconCloud',
    'model_name': 'FunAudioLLM/SenseVoiceSmall',
    'display_name': 'SenseVoiceSmall(语音识别)',
    'model_type': 'asr',
  },
];
