import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

import '../../../../core/network/dio_client/cus_http_client.dart';
import '../../../../core/network/dio_client/cus_http_request.dart';
import '../../../../core/network/dio_client/interceptor_error.dart';
import '../../../../core/network/dio_sse_transformer.dart';
import '../../../../core/utils/simple_tools.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../database/unified_chat_dao.dart';
import '../models/unified_conversation.dart';
import '../models/unified_model_spec.dart';
import '../models/unified_platform_spec.dart';
import '../models/unified_chat_message.dart';
import '../models/openai_request.dart';
import '../models/openai_response.dart';
import 'unified_secure_storage.dart';
import 'builtin_web_search_registry.dart';
import 'web_search_tool_manager.dart';

/// 统一聊天服务
class UnifiedChatService {
  static final UnifiedChatService _instance = UnifiedChatService._internal();
  factory UnifiedChatService() => _instance;
  UnifiedChatService._internal();

  final UnifiedChatDao _chatDao = UnifiedChatDao();
  final WebSearchToolManager _searchToolManager = WebSearchToolManager();

  // 全局流式请求取消令牌列表
  final List<CancelToken> _globalStreamingTokens = [];

  // 2026-09-09 当前请求的搜索引用(请求作用域：工具执行前/非联网请求开始时清空，
  // 智谱自带搜索与第三方工具搜索共用此通道，由viewmodel在流结束后立即取走)
  List<Map<String, dynamic>>? _lastSearchReferences;

  // Stream 转换器复用
  static final _unit8Transformer =
      StreamTransformer<Uint8List, List<int>>.fromHandlers(
        handleData: (data, sink) {
          sink.add(List<int>.from(data));
        },
      );

  ///
  /// 统一发送消息方法（流式和非流式）
  ///
  Stream<OpenAIChatCompletionResponse> sendMessage({
    required String conversationId,
    required List<UnifiedChatMessage> messages,
    required String modelId,
    required String platformId,
    bool stream = true,
    bool isWebSearch = false,
  }) async* {
    // 获取请求配置
    final requestConfig = await _prepareRequestConfig(
      conversationId,
      platformId,
      modelId,
      isWebSearch,
    );

    // 构建请求体
    final request = await _buildChatRequest(
      messages: messages,
      model: requestConfig.model,
      conversation: requestConfig.conversation,
      isWebSearch: isWebSearch,
      platformId: platformId,
      stream: stream,
    );

    final cancelToken = CancelToken();
    _globalStreamingTokens.add(cancelToken);

    try {
      yield* _handleResponse(
        requestConfig.platform,
        requestConfig.apiKey,
        request,
        cancelToken,
        stream: stream,
        isWebSearch: isWebSearch,
      );
    } on CusHttpException catch (e) {
      // 2026-09-09 用户主动取消(手动中断流式)是正常业务逻辑：
      // 静默结束流，不yield错误chunk(否则[ERROR]会被累加进消息内容)
      if (e.cusCode == -2) return;
      yield _buildErrorResponse(e);
    } catch (e) {
      ToastUtils.showError("响应异常 ${e.toString()}");
      rethrow;
    } finally {
      _globalStreamingTokens.remove(cancelToken);
    }
  }

  /// 准备请求配置
  Future<_RequestConfig> _prepareRequestConfig(
    String conversationId,
    String platformId,
    String modelId,
    bool isWebSearch,
  ) async {
    // 获取平台与模型
    final platform = await _chatDao.getPlatformSpec(platformId);
    final model = await _chatDao.getModelSpec(modelId);
    if (platform == null || model == null) {
      throw Exception('平台或模型不存在');
    }

    final apiKey = await UnifiedSecureStorage.getApiKey(platformId);
    if (apiKey == null) {
      throw Exception('API密钥未配置');
    }

    final conversation = await _chatDao.getConversation(conversationId);
    if (conversation == null) {
      throw Exception('对话不存在');
    }

    // 初始化搜索工具管理器(2026-09-09 已带缓存，仅首次或密钥变更后读存储)
    if (isWebSearch) {
      await _searchToolManager.initialize();
    }

    return _RequestConfig(
      platform: platform,
      model: model,
      apiKey: apiKey,
      conversation: conversation,
    );
  }

  /// 构建聊天请求
  Future<OpenAIChatCompletionRequest> _buildChatRequest({
    required List<UnifiedChatMessage> messages,
    required UnifiedModelSpec model,
    required UnifiedConversation conversation,
    required bool isWebSearch,
    required String platformId,
    required bool stream,
  }) async {
    // 构建工具列表（如果开启联网搜索且有可用工具）
    List<OpenAITool>? tools;

    if (isWebSearch && _searchToolManager.hasAvailableTools()) {
      // 2026-09-09 联网搜索策略化(注册表见builtin_web_search_registry.dart)：
      // - 平台无自带搜索能力(注册表无适配器，如DeepSeek/硅基流动/火山) → 始终走第三方工具
      // - builtinOnly → 不注入第三方工具，走平台自带搜索(按平台计费)
      // - auto(默认)/thirdPartyOnly → 有第三方Key且模型支持工具调用时注入
      //   (auto下有博查等第三方Key时优先第三方，省平台自带搜索的按次费用)
      final adapter = BuiltinWebSearchRegistry.adapterFor(platformId);
      final mode = adapter == null
          ? BuiltinWebSearchMode.thirdPartyOnly
          : await _searchToolManager.getPlatformSearchMode(platformId);

      if (mode != BuiltinWebSearchMode.builtinOnly &&
          model.supportsToolCalling == true) {
        tools = _searchToolManager.getSearchTools();
      }
    }

    // 构建请求体
    return OpenAIChatCompletionRequest.fromMessages(
      model: model.modelName,
      messages: messages,
      temperature: conversation.temperature,
      maxTokens: conversation.maxTokens,
      topP: conversation.topP,
      frequencyPenalty: conversation.frequencyPenalty,
      presencePenalty: conversation.presencePenalty,
      stream: stream,
      enableThinking: conversation.extraParams?['enableThinking'] ?? false,
      omniParams: conversation.extraParams?['omniParams'],
      // 用户在对话设置中输入的自定义JSON参数，发送时合并到请求体顶层
      customParams:
          conversation.extraParams?['customRequestParams']
              as Map<String, dynamic>?,
      tools: tools,
      toolChoice: tools != null ? 'auto' : null,
      platformId: platformId,
    );
  }

  /// 处理响应
  Stream<OpenAIChatCompletionResponse> _handleResponse(
    UnifiedPlatformSpec platform,
    String apiKey,
    OpenAIChatCompletionRequest request,
    CancelToken cancelToken, {
    bool stream = false,
    bool isWebSearch = false,
    // 2026-09-09 工具调用续传轮数上限，防止模型循环调用工具
    int toolCallDepth = 0,
  }) async* {
    var requestBody = request.toRequestBody(platform: platform);

    // 2026-09-09 引用按请求作用域管理：非联网请求开始时清掉上一次的残留
    if (!isWebSearch) {
      _lastSearchReferences = null;
    }

    // 构建部分平台支持联网搜索的配置(注册表适配器，见builtin_web_search_registry.dart)
    if (isWebSearch) {
      final webSearchConfig = await _handleWebSearch(request, platform.id);
      if (webSearchConfig != null) {
        requestBody.addAll(webSearchConfig);
      }
    }

    // 自带搜索引用解析适配器(当前仅智谱的web_search引用；阿里CC协议不支持返回来源)
    final searchAdapter = isWebSearch
        ? BuiltinWebSearchRegistry.adapterFor(platform.id)
        : null;

    final responseData = await HttpUtils.post(
      path: platform.getChatCompletionsUrl(),
      data: requestBody,
      headers: platform.getAuthHeaders(apiKey),
      responseType: stream ? CusRespType.stream : CusRespType.json,
      cancelToken: cancelToken,
      showLoading: false,
    );

    if (!stream) {
      final response = OpenAIChatCompletionResponse.fromJson(responseData);

      // 捕获平台自带搜索的引用(如智谱web_search字段)
      if (searchAdapter != null) {
        _captureBuiltinSearchReferences(searchAdapter, responseData);
      }

      // 检查非流式响应是否有工具调用
      if (response.choices.isNotEmpty) {
        final choice = response.choices.first;
        final message = choice.message;
        if (message?.toolCalls != null && message!.toolCalls!.isNotEmpty) {
          pl.i("开始处理非流式响应中的工具调用...");

          yield* _handleNonStreamToolCalls(
            response,
            platform,
            apiKey,
            request,
            cancelToken,
            isWebSearch: isWebSearch,
            toolCallDepth: toolCallDepth,
          );
          return;
        }
      }

      yield response;
      return;
    }

    // 流式响应处理
    final responseBody = responseData as ResponseBody;

    // 如果有工具调用，使用工具调用处理器
    if (request.tools != null && request.tools!.isNotEmpty) {
      pl.i("开始处理带工具调用的流式响应...");

      yield* _handleStreamWithToolCalls(
        responseBody.stream,
        platform,
        apiKey,
        request,
        cancelToken,
        isWebSearch: isWebSearch,
        searchAdapter: searchAdapter,
        toolCallDepth: toolCallDepth,
      );
    } else {
      // 直接处理流式响应
      yield* _handlePlainStreamResponse(
        responseBody.stream,
        cancelToken,
        searchAdapter: searchAdapter,
      );
    }
  }

  /// 捕获平台自带搜索返回的引用，走统一的引用通道供UI展示
  void _captureBuiltinSearchReferences(
    BuiltinWebSearchAdapter adapter,
    Map<String, dynamic> responseJson,
  ) {
    final refs = adapter.parseReferences(responseJson);
    if (refs != null && refs.isNotEmpty) {
      _lastSearchReferences = refs;
    }
  }

  /// 处理普通流式响应（无工具调用）
  Stream<OpenAIChatCompletionResponse> _handlePlainStreamResponse(
    Stream<Uint8List> responseStream,
    CancelToken cancelToken, {
    BuiltinWebSearchAdapter? searchAdapter,
  }) async* {
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
        final json = jsonDecode(data);

        // 捕获平台自带搜索的引用(如智谱web_search字段)
        if (searchAdapter != null && json is Map<String, dynamic>) {
          _captureBuiltinSearchReferences(searchAdapter, json);
        }

        // 2026-09-09 识别流内错误chunk(如内容审查失败data_inspection_failed)：
        // 转为可读错误内容追加到气泡，避免静默跳过后用户只看到被截断的半截回答
        final errorResponse = _extractStreamErrorResponse(json);
        if (errorResponse != null) {
          yield errorResponse;
          continue;
        }

        final streamResponse = OpenAIChatCompletionResponse.fromJson(json);
        yield streamResponse;
      } catch (e) {
        // 虽然解析出错，但继续处理
        pl.i('解析JSON失败: $e, 数据: "$data"');
      }
    }
  }

  /// 识别流式响应中的错误chunk(OpenAI兼容平台常见形状 {"error": {...}}，
  /// 例如魔搭的内容审查失败 data_inspection_failed)
  /// 2026-09-09 之前这类chunk解析失败后被静默跳过，而平台通常会随即断流，
  /// 用户看到的就是没有结尾的半截回答且无任何提示；现转为可读错误内容展示
  OpenAIChatCompletionResponse? _extractStreamErrorResponse(dynamic json) {
    if (json is! Map<String, dynamic> || json['error'] == null) return null;

    String code = 'unknown';
    String message = '未知错误';
    final err = json['error'];

    if (err is Map<String, dynamic>) {
      code = err['code']?.toString() ?? code;
      message = err['message']?.toString() ?? message;
    } else {
      message = err.toString();
    }

    pl.e('流式响应中平台返回错误: $code - $message');

    return OpenAIChatCompletionResponse(
      id:
          json['request_id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      choices: [
        OpenAIChoice(
          index: 0,
          delta: OpenAIMessage(
            role: 'assistant',
            content: '\n\n[平台返回错误，本次响应中断]\n错误代码: $code\n错误信息: $message\n',
          ),
          finishReason: 'error',
        ),
      ],
      customText: '平台在流式响应中返回错误: $code - $message',
    );
  }

  /// 处理带工具调用的流式响应
  Stream<OpenAIChatCompletionResponse> _handleStreamWithToolCalls(
    Stream<Uint8List> responseStream,
    UnifiedPlatformSpec platform,
    String apiKey,
    OpenAIChatCompletionRequest originalRequest,
    CancelToken cancelToken, {
    required bool isWebSearch,
    BuiltinWebSearchAdapter? searchAdapter,
    required int toolCallDepth,
  }) async* {
    final toolCallResult = await _processToolCallStream(
      responseStream,
      cancelToken,
      searchAdapter: searchAdapter,
    );

    // 返回所有流式响应
    for (final response in toolCallResult.responses) {
      yield response;
    }

    // 如果有完整的工具调用，执行工具并重新请求
    // 2026-09-09 轮数上限：超过_maxToolCallRounds不再执行工具，防止模型循环调用
    if (toolCallDepth < _maxToolCallRounds &&
        toolCallResult.hasCompleteToolCalls &&
        toolCallResult.accumulatedToolCalls.isNotEmpty) {
      pl.i('检测到完整工具调用，开始执行: ${toolCallResult.accumulatedToolCalls.keys}');

      yield* _executeToolsAndContinue(
        toolCallResult,
        platform,
        apiKey,
        originalRequest,
        cancelToken,
        isWebSearch: isWebSearch,
        toolCallDepth: toolCallDepth,
      );
    } else if (toolCallDepth >= _maxToolCallRounds &&
        toolCallResult.hasCompleteToolCalls) {
      // 2026-09-09 达到轮数上限后不再静默中断：不执行工具，但仍强制续传
      // 一次(不带tools)，让模型基于已收集的搜索结果生成最终回答，
      // 否则消息会停在工具调用阶段，前面的引导语显得毫无意义
      pl.w('已达到最大工具调用轮数($_maxToolCallRounds)，强制无工具续传生成最终回答');
      yield* _continueWithoutTools(
        toolCallResult.accumulatedToolCalls,
        toolCallResult.assistantContent,
        platform,
        apiKey,
        originalRequest,
        cancelToken,
        isWebSearch: isWebSearch,
        stream: true,
      );
    }
  }

  /// 2026-09-09 达到工具调用轮数上限后，构造不带tools的续传请求，
  /// 让模型放弃继续搜索、直接基于已有搜索结果整理最终回答
  /// (流式与非流式路径共用；toolCallDepth归零——新请求已无tools定义，
  /// 模型无从再发起工具调用，归零还可在异常平台行为下保留3轮吸收缓冲)
  Stream<OpenAIChatCompletionResponse> _continueWithoutTools(
    Map<int, Map<String, dynamic>> accumulatedToolCalls,
    String? assistantContent,
    UnifiedPlatformSpec platform,
    String apiKey,
    OpenAIChatCompletionRequest originalRequest,
    CancelToken cancelToken, {
    required bool isWebSearch,
    required bool stream,
  }) async* {
    final newMessages = List<Map<String, dynamic>>.from(
      originalRequest.messages,
    );

    // 助手的工具调用消息照常补进历史(协议要求tool消息前必须有对应调用)
    final toolCallsForMessage = accumulatedToolCalls.values.map((toolCall) {
      return {
        'id': toolCall['id'].toString().isEmpty
            ? 'tool_call_${DateTime.now().millisecondsSinceEpoch}'
            : toolCall['id'],
        'type': toolCall['type'],
        'function': toolCall['function'],
      };
    }).toList();

    newMessages.add({
      'role': 'assistant',
      'content': assistantContent,
      'tool_calls': toolCallsForMessage,
    });

    // 每个工具调用对应一条提示性的tool结果消息：不执行搜索，
    // 明确告知模型搜索次数已用完，必须直接作答
    final now = DateTime.now().millisecondsSinceEpoch;
    int seq = 0;
    for (final toolCall in accumulatedToolCalls.values) {
      final toolCallId = toolCall['id'].toString().isEmpty
          ? 'tool_call_$now${seq++}'
          : toolCall['id'];
      newMessages.add({
        'tool_call_id': toolCallId,
        'role': 'tool',
        'name': 'web_search',
        'content':
            '搜索次数已达上限，本次未执行搜索。请直接根据之前获得的搜索'
            '结果与你的知识整理最终回答，不要再尝试调用搜索工具。',
      });
    }

    final newRequest = OpenAIChatCompletionRequest(
      model: originalRequest.model,
      messages: newMessages,
      temperature: originalRequest.temperature,
      maxTokens: originalRequest.maxTokens,
      topP: originalRequest.topP,
      frequencyPenalty: originalRequest.frequencyPenalty,
      presencePenalty: originalRequest.presencePenalty,
      stream: stream,
      streamOptions: originalRequest.streamOptions,
      enableThinking: originalRequest.enableThinking,
      omniParams: originalRequest.omniParams,
      customParams: originalRequest.customParams,
      // 关键：不带tools，模型无从再发起工具调用，只能生成最终回答
    );

    yield* _handleResponse(
      platform,
      apiKey,
      newRequest,
      cancelToken,
      stream: stream,
      isWebSearch: isWebSearch,
      toolCallDepth: 0,
    );
  }

  /// 处理工具调用流数据
  Future<_ToolCallStreamResult> _processToolCallStream(
    Stream<Uint8List> responseStream,
    CancelToken cancelToken, {
    BuiltinWebSearchAdapter? searchAdapter,
  }) async {
    final accumulatedToolCalls = <int, Map<String, dynamic>>{};
    final responses = <OpenAIChatCompletionResponse>[];
    String? assistantContent;
    bool hasCompleteToolCalls = false;

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
        final json = jsonDecode(data);

        // 捕获平台自带搜索的引用(如智谱web_search字段)
        if (searchAdapter != null && json is Map<String, dynamic>) {
          _captureBuiltinSearchReferences(searchAdapter, json);
        }

        // 2026-09-09 识别流内错误chunk(如内容审查失败)，转为可读错误内容
        // (与普通流式路径一致，避免静默截断)
        final errorResponse = _extractStreamErrorResponse(json);
        if (errorResponse != null) {
          responses.add(errorResponse);
          continue;
        }

        final response = OpenAIChatCompletionResponse.fromJson(json);
        responses.add(response);

        if (response.choices.isEmpty) continue;

        final choice = response.choices.first;
        final message = choice.delta ?? choice.message;

        // 累积助手内容
        if (message?.content != null) {
          assistantContent = (assistantContent ?? '') + message!.content!;
        }

        // 处理工具调用信息
        _accumulateToolCallData(message?.toolCalls ?? [], accumulatedToolCalls);

        // 检查是否完成了工具调用
        if (choice.finishReason == 'tool_calls') {
          hasCompleteToolCalls = true;
          break;
        }
      } catch (e) {
        pl.e('解析JSON失败: $e, 数据: "$data"');
      }
    }

    return _ToolCallStreamResult(
      responses: responses,
      accumulatedToolCalls: accumulatedToolCalls,
      assistantContent: assistantContent,
      hasCompleteToolCalls: hasCompleteToolCalls,
    );
  }

  /// 累积工具调用数据
  void _accumulateToolCallData(
    List<OpenAIToolCall> toolCalls,
    Map<int, Map<String, dynamic>> accumulatedToolCalls,
  ) {
    for (final toolCall in toolCalls) {
      final index = toolCall.index ?? 0;

      // 初始化工具调用信息
      if (!accumulatedToolCalls.containsKey(index)) {
        accumulatedToolCalls[index] = {
          'id': '',
          'type': 'function',
          'function': {'name': '', 'arguments': ''},
        };
      }

      // 更新工具调用信息
      if (toolCall.id != null && toolCall.id!.isNotEmpty) {
        accumulatedToolCalls[index]!['id'] = toolCall.id!;
      }
      if (toolCall.type != null && toolCall.type!.isNotEmpty) {
        accumulatedToolCalls[index]!['type'] = toolCall.type!;
      }

      final function = toolCall.function;
      if (function != null) {
        if (function.name != null && function.name!.isNotEmpty) {
          accumulatedToolCalls[index]!['function']['name'] = function.name!;
        }
        if (function.arguments != null && function.arguments!.isNotEmpty) {
          accumulatedToolCalls[index]!['function']['arguments'] +=
              function.arguments!;
        }
      }
    }
  }

  /// 执行工具并继续对话
  Stream<OpenAIChatCompletionResponse> _executeToolsAndContinue(
    _ToolCallStreamResult toolCallResult,
    UnifiedPlatformSpec platform,
    String apiKey,
    OpenAIChatCompletionRequest originalRequest,
    CancelToken cancelToken, {
    required bool isWebSearch,
    required int toolCallDepth,
  }) async* {
    final toolResults = await _executeToolCalls(
      toolCallResult.accumulatedToolCalls,
    );

    if (toolResults.isNotEmpty) {
      // 创建新请求，保留工具配置以便模型能够理解上下文
      final newRequest = _buildRequestWithToolResults(
        originalRequest,
        toolCallResult.assistantContent,
        toolCallResult.accumulatedToolCalls,
        toolResults,
      );

      pl.i('发送包含工具结果的新请求，等待模型生成最终回答...');

      // 递归调用处理新请求(轮数+1)
      yield* _handleResponse(
        platform,
        apiKey,
        newRequest,
        cancelToken,
        stream: true,
        isWebSearch: isWebSearch,
        toolCallDepth: toolCallDepth + 1,
      );
    }
  }

  /// 构建包含工具结果的请求
  OpenAIChatCompletionRequest _buildRequestWithToolResults(
    OpenAIChatCompletionRequest originalRequest,
    String? assistantContent,
    Map<int, Map<String, dynamic>> accumulatedToolCalls,
    List<Map<String, dynamic>> toolResults,
  ) {
    final newMessages = List<Map<String, dynamic>>.from(
      originalRequest.messages,
    );

    // 添加助手的工具调用消息
    final toolCallsForMessage = accumulatedToolCalls.values.map((toolCall) {
      return {
        'id': toolCall['id'].toString().isEmpty
            ? 'tool_call_${DateTime.now().millisecondsSinceEpoch}'
            : toolCall['id'],
        'type': toolCall['type'],
        'function': toolCall['function'],
      };
    }).toList();

    newMessages.add({
      'role': 'assistant',
      'content': assistantContent,
      'tool_calls': toolCallsForMessage,
    });

    // 添加工具调用结果
    newMessages.addAll(toolResults);

    return OpenAIChatCompletionRequest(
      model: originalRequest.model,
      messages: newMessages,
      temperature: originalRequest.temperature,
      maxTokens: originalRequest.maxTokens,
      topP: originalRequest.topP,
      frequencyPenalty: originalRequest.frequencyPenalty,
      presencePenalty: originalRequest.presencePenalty,
      stream: originalRequest.stream,
      streamOptions: originalRequest.streamOptions,
      enableThinking: originalRequest.enableThinking,
      omniParams: originalRequest.omniParams,
      customParams: originalRequest.customParams,
      // 保留工具配置，但不强制调用
      tools: originalRequest.tools,
      // 让模型自动决定是否需要调用工具
      toolChoice: 'auto',
    );
  }

  /// 处理非流式响应中的工具调用
  Stream<OpenAIChatCompletionResponse> _handleNonStreamToolCalls(
    OpenAIChatCompletionResponse response,
    UnifiedPlatformSpec platform,
    String apiKey,
    OpenAIChatCompletionRequest originalRequest,
    CancelToken cancelToken, {
    required bool isWebSearch,
    required int toolCallDepth,
  }) async* {
    // 先返回当前响应给UI显示
    yield response;

    final choice = response.choices.first;
    final message = choice.message;
    final toolCalls = message?.toolCalls ?? [];

    // 2026-09-09 轮数上限：不再执行工具，但强制无tools续传让模型作答
    // (与流式路径一致，避免消息停在工具调用阶段显得中断)
    if (toolCallDepth >= _maxToolCallRounds) {
      if (toolCalls.isNotEmpty) {
        pl.w('已达到最大工具调用轮数($_maxToolCallRounds)，强制无工具续传生成最终回答');
        final accumulatedToolCalls = <int, Map<String, dynamic>>{};
        for (int i = 0; i < toolCalls.length; i++) {
          final toolCall = toolCalls[i];
          accumulatedToolCalls[i] = {
            'id':
                toolCall.id ??
                'tool_call_${DateTime.now().millisecondsSinceEpoch}',
            'type': toolCall.type ?? 'function',
            'function': {
              'name': toolCall.function?.name ?? '',
              'arguments': toolCall.function?.arguments ?? '',
            },
          };
        }
        yield* _continueWithoutTools(
          accumulatedToolCalls,
          message?.content,
          platform,
          apiKey,
          originalRequest,
          cancelToken,
          isWebSearch: isWebSearch,
          stream: false,
        );
      }
      return;
    }

    if (toolCalls.isNotEmpty) {
      // 构建工具调用数据结构
      final accumulatedToolCalls = <int, Map<String, dynamic>>{};
      for (int i = 0; i < toolCalls.length; i++) {
        final toolCall = toolCalls[i];
        accumulatedToolCalls[i] = {
          'id':
              toolCall.id ??
              'tool_call_${DateTime.now().millisecondsSinceEpoch}',
          'type': toolCall.type ?? 'function',
          'function': {
            'name': toolCall.function?.name ?? '',
            'arguments': toolCall.function?.arguments ?? '',
          },
        };
      }

      // 执行工具调用
      final toolResults = await _executeToolCalls(accumulatedToolCalls);

      if (toolResults.isNotEmpty) {
        final newRequest = _buildRequestWithToolResults(
          originalRequest,
          message?.content,
          accumulatedToolCalls,
          toolResults,
        );

        pl.i('发送包含工具结果的新请求，等待模型生成最终回答...');

        // 递归调用处理新请求(轮数+1)
        yield* _handleResponse(
          platform,
          apiKey,
          newRequest,
          cancelToken,
          stream: false,
          isWebSearch: isWebSearch,
          toolCallDepth: toolCallDepth + 1,
        );
      }
    }
  }

  /// 执行工具调用
  Future<List<Map<String, dynamic>>> _executeToolCalls(
    Map<int, Map<String, dynamic>> accumulatedToolCalls,
  ) async {
    final toolResults = <Map<String, dynamic>>[];

    // 2026-09-09 多轮工具调用(递归续传)时在上一轮基础上累积合并引用，
    // 按url去重——此前每轮开头清空导致后续轮的列表覆盖之前的显示。
    // 清空点只在_handleResponse入口(非联网请求)与viewmodel发送前
    final collectedReferences =
        _lastSearchReferences ?? <Map<String, dynamic>>[];

    for (final toolCallData in accumulatedToolCalls.values) {
      final functionName = toolCallData['function']['name'] as String;
      final argumentsStr = toolCallData['function']['arguments'] as String;

      final toolCallId = toolCallData['id'] as String;
      final actualToolCallId = toolCallId.isEmpty
          ? 'tool_call_${DateTime.now().millisecondsSinceEpoch}'
          : toolCallId;

      if (functionName == 'web_search') {
        try {
          if (argumentsStr.trim().isEmpty) {
            throw FormatException('工具调用参数为空');
          }

          final arguments = _parseToolCallArguments(argumentsStr);
          final result = await _searchToolManager.handleToolCall(
            functionName: 'web_search',
            arguments: arguments,
          );

          // 收集本轮所有工具调用的搜索结果链接(去重)
          final refs =
              result['searchReferences'] as List<Map<String, dynamic>>?;
          if (refs != null && refs.isNotEmpty) {
            final seenUrls = collectedReferences.map((r) => r['url']).toSet();
            collectedReferences.addAll(
              refs.where((r) => !seenUrls.contains(r['url'])),
            );
            _lastSearchReferences = collectedReferences;
          }

          toolResults.add({
            'tool_call_id': actualToolCallId,
            'role': 'tool',
            'name': 'web_search',
            'content': result['content'] as String,
          });
        } catch (e) {
          pl.e('工具调用执行失败: $e');
          // 单个工具失败不影响已收集的其他工具引用
          toolResults.add({
            'tool_call_id': actualToolCallId,
            'role': 'tool',
            'name': 'web_search',
            'content': '搜索失败: $e',
          });
        }
      }
    }

    return toolResults;
  }

  /// 解析工具调用参数
  /// 2026-09-09 用括号平衡扫描替代原单层正则(\{[^{}]*\})：
  /// 原实现遇到嵌套JSON(如audio对象参数)会截断，也处理不了转义引号
  Map<String, dynamic> _parseToolCallArguments(String argumentsStr) {
    // 注意，实际测试发现，这个参数字符不一定是满足json格式的，可能类似下面字符串：
    // <tool_call> {"query": "阿里巴巴最新股价","max_results": 5}</tool_call>
    // 还有可能不是正确格式，类似: <think> xxx一段思考内容xxx </think>
    // 这些在转为json时会报错

    // 先尝试直接解析整个字符串
    try {
      final decoded = jsonDecode(argumentsStr);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}

    // 提取第一个{到与之配对的}的子串(括号计数，跳过字符串字面量与转义)
    final start = argumentsStr.indexOf('{');
    if (start < 0) {
      pl.e('未找到有效的JSON格式内容');
      return {};
    }

    int depth = 0;
    bool inString = false;
    bool escaped = false;

    for (int i = start; i < argumentsStr.length; i++) {
      final ch = argumentsStr[i];

      if (escaped) {
        escaped = false;
        continue;
      }
      if (ch == r'\') {
        escaped = true;
        continue;
      }
      if (ch == '"') {
        inString = !inString;
        continue;
      }
      if (inString) continue;

      if (ch == '{') {
        depth++;
      } else if (ch == '}') {
        depth--;
        if (depth == 0) {
          try {
            final decoded = jsonDecode(argumentsStr.substring(start, i + 1));
            if (decoded is Map<String, dynamic>) return decoded;
          } catch (e) {
            pl.e('提取的JSON解析失败: $e');
          }
          break;
        }
      }
    }

    pl.e('未找到有效的JSON格式内容');
    return {};
  }

  /// 构建错误响应
  OpenAIChatCompletionResponse _buildErrorResponse(CusHttpException e) {
    return OpenAIChatCompletionResponse(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      choices: [
        OpenAIChoice(
          index: 0,
          delta: OpenAIMessage(role: 'assistant', content: '\n\n[ERROR]'),
          finishReason: 'error',
        ),
      ],
      customText:
          """HTTP请求响应异常:\n\n错误代码: ${e.cusCode}
          \n\n错误信息: ${e.cusMsg}
          \n\n错误原文: ${e.errMessage}
          \n\n原始信息: ${e.errRespString}
          \n\n""",
    );
  }

  ///
  /// service其他的一些方法
  ///
  /// 取消所有进行中的流式请求（供Provider无参调用）
  void cancelStreaming() {
    for (final token in List<CancelToken>.from(_globalStreamingTokens)) {
      if (!token.isCancelled) {
        token.cancel('用户取消');
      }
    }
    _globalStreamingTokens.clear();
  }

  /// 获取最后一次搜索的参考链接
  List<Map<String, dynamic>>? getLastSearchReferences() {
    return _lastSearchReferences;
  }

  /// 清除搜索参考链接
  void clearLastSearchReferences() {
    _lastSearchReferences = null;
  }

  /// 测试API连接
  Future<bool> testApiConnection(String platformId, {String? type}) async {
    try {
      final platform = await _chatDao.getPlatformSpec(platformId);
      if (platform == null) return false;

      final apiKey = await UnifiedSecureStorage.getApiKey(platformId);
      if (apiKey == null || apiKey.trim().isEmpty) return false;

      // 有些平台支持查询模型，还支持查询模型的类型
      Map<String, dynamic>? params;
      if (type != null && type.trim().isNotEmpty) {
        params = {"type": type.trim()};
      }

      final apiPrefix = _getModelsApiPrefix(platformId);

      // 使用简单的模型列表请求测试连接
      await HttpUtils.get(
        path: '${platform.hostUrl}$apiPrefix',
        headers: platform.getAuthHeaders(apiKey),
        showLoading: false,
        showErrorMessage: false,
        queryParameters: params,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取平台的模型列表
  Future<List<String>> getPlatformModels(String platformId) async {
    try {
      final platform = await _chatDao.getPlatformSpec(platformId);
      if (platform == null) return [];

      final apiKey = await UnifiedSecureStorage.getApiKey(platformId);
      if (apiKey == null || apiKey.trim().isEmpty) return [];

      final apiPrefix = _getModelsApiPrefix(platformId);

      final response = await HttpUtils.get(
        path: '${platform.hostUrl}$apiPrefix',
        headers: platform.getAuthHeaders(apiKey),
        showLoading: false,
        showErrorMessage: false,
      );

      /**
      * 结构类似:
      * {
      *  "object": "list",
      *  "data": [{"id": "Qwen/Qwen3-8B","object": "model","created": 0,"owned_by": ""}]
      * }
      *
      * 2026-09-09 火山方舟已提供OpenAI兼容的GET /api/v3/models(Bearer API Key)，
      * 返回同为data[].id结构；兜底兼容其管控风格的models[].id
      */
      List<String> models = [];
      if (response != null) {
        final dataList = response['data'] as List?;
        final modelsList = dataList ?? response['models'] as List?;
        models =
            modelsList
                ?.map(
                  (model) =>
                      (model is Map<String, dynamic> ? model['id'] : model)
                          as String,
                )
                .toList() ??
            [];
      }

      return models;
    } catch (e) {
      ToastUtils.showError("查询模型列表报错: $e");
      rethrow;
    }
  }

  /// 获取模型API前缀
  String _getModelsApiPrefix(String platformId) {
    switch (platformId) {
      // 注意，20250916 实测智谱开放平台的API版本是v4,所以获取模型的API也是v4
      case 'zhipu':
        return "/v4/models";
      // 2025-10-08 因为阿里云的cc和多媒体资源生成的url差异很多，直接hostUrl拼接v1/models是不完整的
      case 'aliyun':
        return "/compatible-mode/v1/models";
      // 2026-09-09 火山方舟：OpenAI兼容的模型列表在推理面v3
      // (hostUrl为https://ark.cn-beijing.volces.com/api → /api/v3/models，Bearer API Key)
      case 'volcengine':
        return "/v3/models";
      default:
        return "/v1/models";
    }
  }

  // 处理部分平台的联网搜索设置
  // 2026-09-09 策略化重构：
  // - 配置构造移入注册表适配器(builtin_web_search_registry.dart)，新平台注册即可扩展
  // - 已注入第三方搜索工具时不再拼自带配置(优先第三方，省平台按次付费)
  // - thirdPartyOnly模式下即使模型不支持工具调用(tools注入失败)也尊重配置不回落自带
  Future<Map<String, dynamic>?> _handleWebSearch(
    OpenAIChatCompletionRequest request,
    String platformId,
  ) async {
    final adapter = BuiltinWebSearchRegistry.adapterFor(platformId);
    if (adapter == null) return null;

    // 请求已带第三方搜索工具 → 走第三方，不拼自带搜索配置
    if (request.tools != null && request.tools!.isNotEmpty) return null;

    // 用户显式指定第三方工具时不回落自带搜索
    final mode = await _searchToolManager.getPlatformSearchMode(platformId);
    if (mode == BuiltinWebSearchMode.thirdPartyOnly) return null;

    // 白名单校验在适配器内(如阿里仅千问/DeepSeek部分系列支持；
    // 火山方舟的web_search仅Responses API提供，CC路径恒null)
    final config = adapter.buildConfig(request.model);
    if (config == null) {
      pl.w(
        '平台[$platformId]当前模型不支持CC自带联网搜索，'
        '请配置第三方搜索Key(联网开关将不产生实际搜索效果)',
      );
    }
    return config;
  }

  /// 清理资源
  void dispose() {
    for (final token in _globalStreamingTokens) {
      if (!token.isCancelled) {
        token.cancel();
      }
    }
    _globalStreamingTokens.clear();
  }
}

// 辅助数据类
class _RequestConfig {
  final UnifiedPlatformSpec platform;
  final UnifiedModelSpec model;
  final String apiKey;
  final UnifiedConversation conversation;

  _RequestConfig({
    required this.platform,
    required this.model,
    required this.apiKey,
    required this.conversation,
  });
}

class _ToolCallStreamResult {
  final List<OpenAIChatCompletionResponse> responses;
  final Map<int, Map<String, dynamic>> accumulatedToolCalls;
  final String? assistantContent;
  final bool hasCompleteToolCalls;

  _ToolCallStreamResult({
    required this.responses,
    required this.accumulatedToolCalls,
    required this.assistantContent,
    required this.hasCompleteToolCalls,
  });
}

// 2026-09-09 工具调用续传的最大轮数(防模型循环调用工具)
const int _maxToolCallRounds = 3;
