// DeepSeek官方平台模型
// 2026-09-02 按官方API文档核对：V4系列为当前主力，
// 旧deepseek-chat/deepseek-reasoner(V3时代别名)不再内置
final deepseekModels = [
  {
    'id': 'deepseek-v4-pro',
    'platform_id': 'deepseek',
    'model_name': 'deepseek-v4-pro',
    'display_name': 'DeepSeek-V4-Pro(旗舰)',
    'model_type': 'cc',
    'supports_thinking': 1,
    'supports_tool_calling': 1,
  },
  {
    'id': 'deepseek-v4-flash',
    'platform_id': 'deepseek',
    'model_name': 'deepseek-v4-flash',
    'display_name': 'DeepSeek-V4-Flash(快速)',
    'model_type': 'cc',
    'supports_thinking': 1,
    'supports_tool_calling': 1,
  },
];
