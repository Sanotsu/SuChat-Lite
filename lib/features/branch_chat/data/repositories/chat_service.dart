import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:io';

import '../../../../core/entities/cus_llm_model.dart';
import '../../../../shared/constants/constant_llm_enum.dart';
import '../../../../shared/constants/default_models.dart';
import '../../../../core/storage/cus_get_storage.dart';
import '../../domain/advanced_options_presets.dart';
import '../../domain/entities/branch_chat_message.dart';
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
        throw Exception('未配置该平台的 API Key');
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

  /// 分支对话发送消息调用大模型API(和常规的类似)
  static Future<(Stream<ChatCompletionResponse>, VoidCallback)>
  sendBranchMessage(
    CusLLMSpec model,
    List<BranchChatMessage> messages, {
    bool stream = true,
    Map<String, dynamic>? advancedOptions,
  }) async {
    final headers = await _getHeaders(model);
    final baseUrl = "${_getBaseUrl(model.platform)}/chat/completions";

    // 处理高级参数
    Map<String, dynamic>? additionalParams;
    if (advancedOptions != null) {
      additionalParams = AdvancedOptionsManager.buildAdvancedParams(
        advancedOptions,
        model.platform,
      );
    }

    // 2025-03-25 文档中智谱AI模型支持 web_search，但实测没有用
    // 高级的Web-Search-Pro工具0.03元/次，且单独API调用，还要手动处理成输入token处理？
    if (model.platform == ApiPlatform.zhipu) {
      additionalParams = {
        'tools': [
          {
            "type": "web_search",
            "web_search": {
              "enable": true,
              "search_result": true,
              // "search_query": messages.last.content
            },
          },
        ],
      };
    }

    final request = ChatCompletionRequest(
      model: model.model,
      messages: _buildAPIContent(messages),
      stream: stream,
      additionalParams: additionalParams,
    );

    final requestBody = request.toRequestBody();
    // print('分支对话请求体: $requestBody');

    return getStreamResponse(baseUrl, headers, requestBody, stream: stream);
  }

  /// 角色对话发送消息调用大模型API
  static Future<(Stream<ChatCompletionResponse>, VoidCallback)>
  sendCharacterMessage(
    CusLLMSpec model,
    List<Map<String, dynamic>> messages, {
    bool stream = true,
    Map<String, dynamic>? advancedOptions,
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

List<Map<String, dynamic>> _buildAPIContent(List<BranchChatMessage> messages) {
  final messagesList =
      messages.map((m) {
        // 初始化内容列表
        final contentList = [];

        // 添加文本内容
        if (m.content.isNotEmpty) {
          // 如果只有文本内容，则直接添加
          if (m.imagesUrl != null || m.videosUrl != null) {
            contentList.add({'type': 'text', 'text': m.content});
          } else {
            return {'role': m.role, 'content': m.content};
          }
        }

        // 处理图片(按逗号分割图片地址)
        if (m.imagesUrl != null && m.imagesUrl!.trim().isNotEmpty) {
          final imageUrls = m.imagesUrl!.split(',');
          for (final url in imageUrls) {
            final bytes = File(url.trim()).readAsBytesSync();
            final base64Image = base64Encode(bytes);
            contentList.add({
              'type': 'image_url',
              'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
            });
          }
        }

        // 暂时不启用
        // // 处理视频(按逗号分割视频地址)
        // if (m.videosUrl != null && m.videosUrl!.trim().isNotEmpty) {
        //   final videoUrls = m.videosUrl!.split(',');
        //   for (final url in videoUrls) {
        //     final bytes = File(url.trim()).readAsBytesSync();
        //     final base64Video = base64Encode(bytes);
        //     contentList.add({
        //       'type': 'video_url',
        //       'video_url': {'url': 'data:video/mp4;base64,$base64Video'}
        //     });
        //   }
        // }

        // // 处理音频(暂时只有单个音频，仅支持mp3格式)
        // if (m.contentVoicePath != null && m.contentVoicePath!.trim().isNotEmpty) {
        //   final bytes = File(m.contentVoicePath!).readAsBytesSync();
        //   final base64Audio = base64Encode(bytes);
        //   contentList.add({
        //     'type': 'input_audio',
        //     'input_audio': {
        //       'data': 'data:audio/mp3;base64,$base64Audio',
        //       'format': 'mp3',
        //     }
        //   });
        // }

        // 返回最终的消息结构
        return {'role': m.role, 'content': contentList};
      }).toList();

  return messagesList;
}
