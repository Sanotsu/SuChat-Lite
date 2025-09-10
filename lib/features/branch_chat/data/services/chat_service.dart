import 'dart:async';
import 'dart:ui';

import '../../../../core/entities/cus_llm_model.dart';
import '../../../../shared/constants/constant_llm_enum.dart';
import '../../../../shared/constants/default_models.dart';
import '../../../../core/storage/cus_get_storage.dart';
import '../../domain/advanced_options_presets.dart';
import '../../domain/entities/input_message_data.dart';
import '../datasources/openai_compatible_apis.dart';
import '../models/chat_completion_response.dart';
import '../models/chat_completion_request.dart';

/// 2025-02-13 改版后所有平台都使用open API兼容的版本，不兼容的就不用了。
///     讯飞每个模型的AK都单独的，太麻烦了，而且效果并不出类拔萃，放弃支持它平台的调用了
/// 当前文档地址：
/// 阿里 https://help.aliyun.com/zh/model-studio/developer-reference/compatibility-of-openai-with-dashscope
/// 百度 https://cloud.baidu.com/doc/WENXINWORKSHOP/s/Fm2vrveyu
/// 腾讯 https://console.cloud.tencent.com/hunyuan/start
/// 智谱 https://open.bigmodel.cn/dev/api/normal-model/glm-4
/// 深度求索 https://api-docs.deepseek.com/zh-cn/
/// 零一万物 https://platform.lingyiwanwu.com/docs/api-reference
/// 硅基流动 https://docs.siliconflow.cn/cn/api-reference/chat-completions/chat-completions
/// 无问芯穹 https://docs.infini-ai.com/gen-studio/api/maas.html#/operations/chatCompletions

class ChatService {
  // 暴露出去
  static String getBaseUrl(ApiPlatform platform) => _getBaseUrl(platform);
  static Future<String> getApiKey(CusLLMSpec model) => _getApiKey(model);
  static Future<Map<String, String>> getHeaders(CusLLMSpec model) =>
      _getHeaders(model);

  // 私有方法
  static String _getBaseUrl(ApiPlatform platform) {
    switch (platform) {
      case ApiPlatform.aliyun:
        return 'https://dashscope.aliyuncs.com/compatible-mode/v1';
      case ApiPlatform.baidu:
        return 'https://qianfan.baidubce.com/v2';
      case ApiPlatform.tencent:
        return 'https://api.hunyuan.cloud.tencent.com/v1';
      case ApiPlatform.deepseek:
        return 'https://api.deepseek.com/v1';
      case ApiPlatform.lingyiwanwu:
        return 'https://api.lingyiwanwu.com/v1';
      case ApiPlatform.zhipu:
        return 'https://open.bigmodel.cn/api/paas/v4';
      case ApiPlatform.siliconCloud:
        return 'https://api.siliconflow.cn/v1';
      case ApiPlatform.infini:
        return 'https://cloud.infini-ai.com/maas/v1';
      case ApiPlatform.volcengine:
        return 'https://ark.cn-beijing.volces.com/api/v3';
      case ApiPlatform.volcesBot:
        return 'https://ark.cn-beijing.volces.com/api/v3/bots';
      default:
        return "";
    }
  }

  static Future<String> _getApiKey(CusLLMSpec model) async {
    if (model.cusLlmSpecId.endsWith('_builtin')) {
      // 使用内置的 API Key
      // （有免费的模型我才使用自己的ak，自用收费的也自己导入）
      switch (model.platform) {
        case ApiPlatform.baidu:
          return DefaultApiKeys.baiduApiKey;
        case ApiPlatform.tencent:
          return DefaultApiKeys.tencentApiKey;
        case ApiPlatform.zhipu:
          return DefaultApiKeys.zhipuAK;
        case ApiPlatform.siliconCloud:
          return DefaultApiKeys.siliconCloudAK;
        default:
          throw Exception('不支持的平台');
      }
    } else {
      // 使用用户的 API Key
      final userKeys = CusGetStorage().getUserAKMap();
      String? apiKey;

      switch (model.platform) {
        case ApiPlatform.aliyun:
          apiKey = userKeys[ApiPlatformAKLabel.USER_ALIYUN_API_KEY.name];
          break;
        case ApiPlatform.baidu:
          apiKey = userKeys[ApiPlatformAKLabel.USER_BAIDU_API_KEY_V2.name];
          break;
        case ApiPlatform.tencent:
          apiKey = userKeys[ApiPlatformAKLabel.USER_TENCENT_API_KEY.name];
          break;

        case ApiPlatform.deepseek:
          apiKey = userKeys[ApiPlatformAKLabel.USER_DEEPSEEK_API_KEY.name];
          break;
        case ApiPlatform.lingyiwanwu:
          apiKey = userKeys[ApiPlatformAKLabel.USER_LINGYIWANWU_API_KEY.name];
          break;
        case ApiPlatform.zhipu:
          apiKey = userKeys[ApiPlatformAKLabel.USER_ZHIPU_API_KEY.name];
          break;

        case ApiPlatform.siliconCloud:
          apiKey = userKeys[ApiPlatformAKLabel.USER_SILICONCLOUD_API_KEY.name];
          break;
        case ApiPlatform.infini:
          apiKey =
              userKeys[ApiPlatformAKLabel.USER_INFINI_GEN_STUDIO_API_KEY.name];
          break;
        case ApiPlatform.volcengine:
          apiKey = userKeys[ApiPlatformAKLabel.USER_VOLCENGINE_API_KEY.name];
          break;
        case ApiPlatform.volcesBot:
          apiKey = userKeys[ApiPlatformAKLabel.USER_VOLCESBOT_API_KEY.name];
          break;
        default:
          return "";
      }

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('未配置 ${model.platform} 平台的 API Key');
      }
      return apiKey;
    }
  }

  static Future<Map<String, String>> _getHeaders(CusLLMSpec model) async {
    final apiKey = await _getApiKey(model);

    if (ApiPlatform.values.contains(model.platform)) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      };
    }
    throw Exception('不支持的平台');
  }

  /// 分支/角色对话发送消息调用大模型API
  static Future<(Stream<ChatCompletionResponse>, VoidCallback)> sendMessage(
    CusLLMSpec model,
    List<Map<String, dynamic>> messages, {
    bool stream = true,
    Map<String, dynamic>? advancedOptions,
    bool enableWebSearch = false,
  }) async {
    // 如果是自定义平台模型，url、apikey等直接在模型规格中
    Map<String, String> headers;
    String baseUrl;
    if (model.platform == ApiPlatform.custom) {
      headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${model.apiKey}',
      };
      baseUrl = "${model.baseUrl}/chat/completions";
    } else {
      headers = await _getHeaders(model);
      baseUrl = "${_getBaseUrl(model.platform)}/chat/completions";
    }

    // 处理高级参数
    Map<String, dynamic>? additionalParams;
    if (advancedOptions != null) {
      additionalParams = AdvancedOptionsManager.buildAdvancedParams(
        advancedOptions,
        model.platform,
      );
    }

    // 阿里云多模态，如果有选择具体音色，则输出文本+语音；如果选择无音色，则只输出文本
    if (model.platform == ApiPlatform.aliyun &&
        model.model.contains('qwen-omni')) {
      // 因为在使用omni如果选择了音色，会把音色放在高级选项中去传递，但在上面build时，可能就过滤掉了
      // 所以这里手动取得音色数据

      String? audioVoice = advancedOptions?["omni_audio_voice"];

      // 简单处理，如果选择无音色，则不输出音频
      if (audioVoice != null && audioVoice.contains("无")) {
        audioVoice = null;
      }

      additionalParams = {
        // "stream_options": {"include_usage": true},
        "modalities": audioVoice != null ? ["text", "audio"] : ['text'],
      };

      if (audioVoice != null) {
        // 2025-05-30 注意，添加了这个参数，返回的结构和之前默认的不一样
        // 文本放在了 {"choices":[{"delta":{"audio":{"transcript":"xxx"}},"finish_reason":null,"index":0,"logprobs":null}]
        // 音频放在了 {"choices":[{"delta":{"audio":{"data":"<音频base64>","expires_at":1748568662,"id":"audio_240e9bb8-77d4-9b9f-8b96-066ddfef4323"}},
        // 之前通用是 {"choices":[{"delta":{"content":"'xxx"},"finish_reason":null,"index":0,"logprobs":null}]
        additionalParams["audio"] = {"voice": audioVoice, "format": "wav"};
      }
    }

    // 2025-09-10 阿里云的部分模型支持联网搜索，这里配置这些模型的请求参数
    // 文档: https://help.aliyun.com/zh/model-studio/web-search
    if (enableWebSearch &&
        model.platform == ApiPlatform.aliyun &&
        aliyunWebSearchModels.contains(model.model)) {
      additionalParams = {
        ...?additionalParams,
        "enable_search": true,
        "search_options": {
          "forced_search": true,
          // 搜索策略可选 turbo max
          "search_strategy": "turbo",
        },
      };
    }

    // 智谱开放平台的搜索
    // 文档: https://docs.bigmodel.cn/api-reference/工具-api/网络搜索
    if (enableWebSearch &&
        model.platform == ApiPlatform.zhipu &&
        zhipuWebSearchModels.contains(model.model)) {
      additionalParams = {
        ...?additionalParams,
        "tools": [
          {
            "type": "web_search",
            "web_search": {
              // 是否启用搜索功能，默认值为 false，启用时设置为 true
              "search_enable": true,
              // search_std (0.01元 / 次)、
              // search_pro (0.03元 / 次)、
              // search_pro_sogou (0.05元 / 次)、
              // search_pro_quark (0.05元 / 次)。
              "search_engine": "search_std",
              // 是否进行搜索意图识别，默认执行搜索意图识别。
              // true：执行搜索意图识别，有搜索意图后执行搜索；
              // false：跳过搜索意图识别，直接执行搜索
              "search_intent": false,
              // 返回结果的条数。可填范围：1-50，最大单次搜索返回50条，默认为10。
              // 支持的搜索引擎：search_std、search_pro、search_pro_sogou。
              // 对于search_pro_sogou: 可选枚举值，10、20、30、40、50
              "search_count": 10,
            },
          },
        ],
        "tool_choice": "auto",
      };
    }

    final request = ChatCompletionRequest(
      model: model.model,
      messages: messages,
      stream: stream,
      additionalParams: additionalParams,
    );

    final requestBody = request.toRequestBody();
    // print('角色对话请求体: $requestBody');

    return getStreamResponse(baseUrl, headers, requestBody, stream: stream);
  }
}
