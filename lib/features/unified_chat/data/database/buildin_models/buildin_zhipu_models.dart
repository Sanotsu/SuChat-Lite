// 智谱平台模型
// 2026-09-02 按官方文档核对：GLM-5.3为强制思考旗舰(仅支持开启思考，传false会400)；
// GLM-4.x全系调用时会自动切换至GLM-5.3，不再内置
final zhipuModels = [
  // ===== 文本对话 =====
  {
    'id': 'glm-5.3',
    'platform_id': 'zhipu',
    'model_name': 'glm-5.3',
    'display_name': 'GLM-5.3(旗舰,强制思考)',
    'model_type': 'cc',
    'supports_thinking': 1,
    'supports_vision': 1,
    'supports_tool_calling': 1,
  },
  {
    'id': 'glm-5.3-flash',
    'platform_id': 'zhipu',
    'model_name': 'glm-5.3-flash',
    'display_name': 'GLM-5.3-Flash(普惠多模态)',
    'model_type': 'cc',
    'supports_thinking': 1,
    'supports_vision': 1,
    'supports_tool_calling': 1,
  },
  {
    'id': 'glm-5.2',
    'platform_id': 'zhipu',
    'model_name': 'glm-5.2',
    'display_name': 'GLM-5.2(长程任务)',
    'model_type': 'cc',
    'supports_thinking': 1,
    'supports_tool_calling': 1,
  },
  // ===== 图片生成 =====
  {
    'id': 'cogview-4-250304',
    'platform_id': 'zhipu',
    'model_name': 'cogview-4-250304',
    'display_name': 'CogView-4(图像生成)',
    'model_type': 'image',
  },
  // ===== 视频生成 =====
  {
    'id': 'cogvideox-flash',
    'platform_id': 'zhipu',
    'model_name': 'cogvideox-flash',
    'display_name': 'CogVideoX-Flash(视频生成)',
    'model_type': 'video',
  },
  // ===== 语音合成 =====
  {
    'id': 'cogtts',
    'platform_id': 'zhipu',
    'model_name': 'cogtts',
    'display_name': 'CogTTS(语音合成)',
    'model_type': 'tts',
  },
  // ===== 语音识别 =====
  {
    'id': 'glm-asr',
    'platform_id': 'zhipu',
    'model_name': 'glm-asr',
    'display_name': 'GLM-ASR(语音识别)',
    'model_type': 'asr',
  },
];
