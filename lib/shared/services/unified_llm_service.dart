import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show VoidCallback;

import 'package:dio/dio.dart';

import '../../core/network/dio_client/cus_http_client.dart';
import '../../core/network/dio_client/cus_http_request.dart';
import '../../core/network/dio_client/interceptor_error.dart';
import '../../core/network/dio_sse_transformer.dart';
import '../../features/unified_chat/data/database/unified_chat_dao.dart';
import '../../features/unified_chat/data/models/openai_request.dart';
import '../../features/unified_chat/data/models/openai_response.dart';
import '../../features/unified_chat/data/models/unified_model_spec.dart';
import '../../features/unified_chat/data/models/unified_platform_spec.dart';
import '../../features/unified_chat/data/services/unified_secure_storage.dart';

/// 统一模型条目：模型规格 + 所属平台（页面下拉与请求构建的最小完备信息）
typedef UnifiedModelEntry = ({
  UnifiedModelSpec model,
  UnifiedPlatformSpec platform,
});

/// 统一 LLM 门面（2026-09-07 旧体系退役后的扩展功能唯一 LLM 入口）
///
/// 旧体系（ChatService/openai_compatible_apis/UnifiedModelBridge）已删除，
/// 翻译/饮食/训练/语音识别等模块统一经由本门面：
/// - 模型来源 = 聊天页平台管理的统一模型库（激活平台 + 已配置 AK）
/// - 请求构建 = OpenAIChatCompletionRequest.toRequestBody 平台特化 + HttpUtils(SSE)
/// - 流式契约 = delta.reasoningContent 思考 / delta.content 正文；
///   取消注入 id='cancel' + content='[手动终止]'；
///   请求异常注入 id='error' + customText=完整错误信息（delta.content 仅为占位）
class UnifiedLLMService {
  UnifiedLLMService._();

  /// 加载统一模型库条目
  ///
  /// [types] 为 UnifiedModelType.name 集合（默认 {'cc'} 对话模型），
  /// [visionOnly] 仅返回支持视觉的模型；仅收录激活平台下已配置 AK 的模型。
  /// 无可用模型时返回空列表，调用方应提示用户前往聊天页-平台管理配置。
  static Future<List<UnifiedModelEntry>> loadModelEntries({
    Set<String> types = const {'cc'},
    bool visionOnly = false,
  }) async {
    final dao = UnifiedChatDao();
    final models = await dao.getModelSpecs();
    final platforms = await dao.getPlatformSpecs();
    final platformMap = {for (final p in platforms) p.id: p};

    final result = <UnifiedModelEntry>[];
    for (final m in models) {
      if (!m.isActive || !types.contains(m.modelType)) continue;
      if (visionOnly && !m.supportsVision) continue;
      final p = platformMap[m.platformId];
      if (p == null || !p.isActive) continue;

      final apiKey = await UnifiedSecureStorage.getApiKey(p.id);
      if (apiKey == null || apiKey.isEmpty) continue;

      result.add((model: m, platform: p));
    }
    return result;
  }

  /// 流式对话补全（裸调用：不写会话/消息库）
  ///
  /// [messages] 为 OpenAI 格式（{role, content}，content 可为多模态数组）；
  /// [extraParams] 合并到请求体顶层（如 qwen-mt 的 translation_options）
  static Future<(Stream<OpenAIChatCompletionResponse>, VoidCallback)>
  sendChatStream({
    required UnifiedModelEntry entry,
    required List<Map<String, dynamic>> messages,
    Map<String, dynamic>? extraParams,
  }) async {
    final apiKey = await UnifiedSecureStorage.getApiKey(entry.platform.id);
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API密钥未配置，请在聊天页-平台管理中配置');
    }

    final request = OpenAIChatCompletionRequest(
      model: entry.model.modelName,
      messages: messages,
      stream: true,
      streamOptions: const OpenAIStreamOptions(includeUsage: true),
      customParams: extraParams,
    );

    final cancelToken = CancelToken();
    final controller = StreamController<OpenAIChatCompletionResponse>();

    unawaited(() async {
      try {
        final responseData = await HttpUtils.post(
          path: entry.platform.getChatCompletionsUrl(),
          data: request.toRequestBody(platform: entry.platform),
          headers: entry.platform.getAuthHeaders(apiKey),
          responseType: CusRespType.stream,
          cancelToken: cancelToken,
          showLoading: false,
          showErrorMessage: false,
        );

        final responseStream = (responseData as ResponseBody).stream;
        await for (final chunk
            in responseStream
                .transform(_unit8Transformer)
                .transform(const Utf8Decoder())
                .transform(const LineSplitter())
                .transform(const SseTransformer())) {
          if (cancelToken.isCancelled) break;

          final data = chunk.data;
          if (data.contains('[DONE]')) break;

          try {
            controller.add(
              OpenAIChatCompletionResponse.fromJson(jsonDecode(data)),
            );
          } catch (_) {
            // 单块解析失败继续处理后续块
          }
        }

        // 取消时注入终止标记响应（与旧体系契约一致，页面可展示"[手动终止]"）
        if (cancelToken.isCancelled) {
          controller.add(_syntheticResponse('cancel', '[手动终止]'));
        }
      } on CusHttpException catch (e) {
        // 请求异常注入错误响应：customText 为完整错误信息(页面取此展示)，
        // delta.content 仅为占位
        controller.add(
          _syntheticResponse('error', '[ERROR]', customText: e.cusMsg),
        );
      } catch (e) {
        controller.add(
          _syntheticResponse('error', '[ERROR]', customText: e.toString()),
        );
      } finally {
        await controller.close();
      }
    }());

    return (
      controller.stream,
      () {
        if (!cancelToken.isCancelled) cancelToken.cancel();
      },
    );
  }

  /// 非流式对话补全（裸调用），请求失败抛 CusHttpException 由调用方处理
  static Future<OpenAIChatCompletionResponse> sendChat({
    required UnifiedModelEntry entry,
    required List<Map<String, dynamic>> messages,
    Map<String, dynamic>? extraParams,
  }) async {
    final apiKey = await UnifiedSecureStorage.getApiKey(entry.platform.id);
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API密钥未配置，请在聊天页-平台管理中配置');
    }

    final request = OpenAIChatCompletionRequest(
      model: entry.model.modelName,
      messages: messages,
      stream: false,
      customParams: extraParams,
    );

    final response = await HttpUtils.post(
      path: entry.platform.getChatCompletionsUrl(),
      data: request.toRequestBody(platform: entry.platform),
      headers: entry.platform.getAuthHeaders(apiKey),
      responseType: CusRespType.json,
      showLoading: false,
      showErrorMessage: false,
    );

    return OpenAIChatCompletionResponse.fromJson(
      response as Map<String, dynamic>,
    );
  }

  /// 便捷方法：纯文本单轮对话，直接返回 assistant 全部正文（非流式）
  static Future<String> sendChatText({
    required UnifiedModelEntry entry,
    String? systemPrompt,
    required String userText,
    Map<String, dynamic>? extraParams,
  }) async {
    final messages = <Map<String, dynamic>>[
      if (systemPrompt != null && systemPrompt.isNotEmpty)
        {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userText},
    ];
    final response = await sendChat(
      entry: entry,
      messages: messages,
      extraParams: extraParams,
    );
    return response.customText;
  }

  // ===== 内部实现 =====

  // Uint8List -> List<int>(Utf8Decoder 泛型要求)，与 UnifiedChatService 一致
  static final _unit8Transformer =
      StreamTransformer<Uint8List, List<int>>.fromHandlers(
        handleData: (data, sink) {
          sink.add(List<int>.from(data));
        },
      );

  static OpenAIChatCompletionResponse _syntheticResponse(
    String id,
    String content, {
    String? customText,
  }) {
    return OpenAIChatCompletionResponse(
      id: id,
      choices: [
        OpenAIChoice(
          index: 0,
          delta: OpenAIMessage(role: 'assistant', content: content),
          finishReason: id == 'cancel' ? 'cancelled' : 'error',
        ),
      ],
      customText: customText,
    );
  }
}
