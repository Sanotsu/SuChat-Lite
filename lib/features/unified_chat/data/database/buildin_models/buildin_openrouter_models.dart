// OpenRouter聚合网关模型
// 2026-09-18 选择截至当前时间各厂商的代表性主力模型
// (OpenRouter的模型标识统一为"vendor/model"slug，与厂商官方名不同)
final openrouterModels = [
  {
    'id': 'anthropic/claude-sonnet-4.6',
    'platform_id': 'openrouter',
    'model_name': 'anthropic/claude-sonnet-4.6',
    'display_name': 'Claude Sonnet 4.6',
    'model_type': 'cc',
    'supports_thinking': 1,
    'supports_tool_calling': 1,
  },
  {
    'id': 'openai/gpt-5.4',
    'platform_id': 'openrouter',
    'model_name': 'openai/gpt-5.4',
    'display_name': 'GPT-5.4',
    'model_type': 'cc',
    'supports_thinking': 1,
    'supports_tool_calling': 1,
  },
  {
    'id': 'google/gemini-3.8-flash',
    'platform_id': 'openrouter',
    'model_name': 'google/gemini-3.8-flash',
    'display_name': 'Gemini 3.8 Flash',
    'model_type': 'cc',
    'supports_thinking': 1,
    'supports_tool_calling': 1,
  },
  {
    'id': 'deepseek/deepseek-v4-flash',
    'platform_id': 'openrouter',
    'model_name': 'deepseek/deepseek-v4-flash',
    'display_name': 'DeepSeek V4 Flash',
    'model_type': 'cc',
    'supports_thinking': 1,
    'supports_tool_calling': 1,
  },
];
