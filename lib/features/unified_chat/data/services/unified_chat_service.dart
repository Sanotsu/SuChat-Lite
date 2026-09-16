import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mcp_dart/mcp_dart.dart';

import '../../../../core/storage/cus_get_storage.dart';
import '../../../../core/network/dio_client/cus_http_client.dart';
import '../../../../core/network/dio_client/cus_http_request.dart';
import '../../../../core/network/dio_client/interceptor_error.dart';
import '../../../../core/network/dio_sse_transformer.dart';
import '../../../../core/utils/simple_tools.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../database/unified_chat_dao.dart';
import '../models/mcp_models.dart';
import '../models/unified_conversation.dart';
import '../models/unified_model_spec.dart';
import '../models/unified_platform_spec.dart';
import '../models/unified_chat_message.dart';
import '../models/openai_request.dart';
import '../models/openai_response.dart';
import 'unified_secure_storage.dart';
import 'builtin_datetime_tool.dart';
import 'builtin_shell_tool.dart';
import 'builtin_web_search_registry.dart';
import 'web_search_tool_manager.dart';
import 'mcp/mcp_server_manager.dart';

/// 统一聊天服务
class UnifiedChatService {
  static final UnifiedChatService _instance = UnifiedChatService._internal();
  factory UnifiedChatService() => _instance;
  UnifiedChatService._internal() {
    // 2026-09-15 P4-3 MCP sampling：server反向调用本机LLM的处理转发到
    // 当前对话配置(上下文由viewmodel在sendMessage时更新)
    _mcpManager.samplingHandler = _handleMcpSampling;
  }

  final UnifiedChatDao _chatDao = UnifiedChatDao();
  final WebSearchToolManager _searchToolManager = WebSearchToolManager();

  // 2026-09-11 MCP集成(P1-1)：MCP工具管理器(ChatToolProvider第一个实现)
  final McpServerManager _mcpManager = McpServerManager();

  /// 2026-09-14 P3-13 内置工具审批处理器(viewmodel注入，弹横幅等用户
  /// 决定)；P3-11 shell工具非只读命令执行前调用；null时非只读命令拒绝执行
  ToolApprovalHandler? builtinToolApprovalHandler;

  /// 2026-09-15 P4-3 MCP sampling上下文(viewmodel在sendMessage时更新)——
  /// server反向请求LLM补全时用当前对话的平台/密钥/模型
  ({UnifiedPlatformSpec platform, String apiKey, UnifiedModelSpec model})?
  _mcpSamplingContext;

  /// 更新sampling上下文(每次发消息时调用)
  void updateMcpSamplingContext(
    UnifiedPlatformSpec platform,
    String apiKey,
    UnifiedModelSpec model,
  ) {
    _mcpSamplingContext = (platform: platform, apiKey: apiKey, model: model);
  }

  /// P4-3 处理MCP server的sampling/createMessage反向请求：
  /// 把server给的提示词转发到当前对话模型做一次非流式补全并返回文本。
  /// server声明的tools/context能力未启用(声明里tools/context均为false)，
  /// 请求带tools或includeContext时SDK层已先拒绝
  Future<CreateMessageResult> _handleMcpSampling(
    CreateMessageRequest params,
  ) async {
    final ctx = _mcpSamplingContext;
    if (ctx == null) {
      throw StateError('sampling上下文未就绪(当前无进行中的对话)');
    }

    final messages = <Map<String, dynamic>>[
      if (params.systemPrompt != null && params.systemPrompt!.trim().isNotEmpty)
        {'role': 'system', 'content': params.systemPrompt},
      for (final m in params.messages)
        {
          'role': m.role == SamplingMessageRole.assistant
              ? 'assistant'
              : 'user',
          'content': _samplingContentText(m),
        },
    ];

    final request = OpenAIChatCompletionRequest(
      model: ctx.model.modelName,
      messages: messages,
      temperature: params.temperature,
      // sampling上限保护：防server传异常值撑爆上下文
      maxTokens: params.maxTokens.clamp(1, 8192),
      stream: false,
    );

    final responses = await _handleResponse(
      ctx.platform,
      ctx.apiKey,
      request,
      CancelToken(),
      stream: false,
    ).toList();

    final text = responses
        .map((r) => r.customText)
        .whereType<String>()
        .join()
        .trim();
    if (text.isEmpty) {
      throw StateError('sampling补全返回空结果');
    }

    return CreateMessageResult(
      model: ctx.model.modelName,
      role: SamplingMessageRole.assistant,
      content: TextContent(text: text),
      stopReason: StopReason.endTurn,
    );
  }

  /// sampling消息内容转文本(文本块拼接；非文本块占位说明)
  String _samplingContentText(SamplingMessage message) {
    final buffer = StringBuffer();
    for (final block in message.contentBlocks) {
      if (buffer.isNotEmpty) buffer.write('\n');
      if (block is SamplingTextContent) {
        buffer.write(block.text);
      } else {
        buffer.write('[非文本内容: ${block.runtimeType}]');
      }
    }
    return buffer.toString();
  }

  /// 2026-09-14 P3-2 工具调用续传最大轮数(全局GetStorage配置，读时生效)
  int get maxToolCallRounds =>
      CusGetStorage().box.read(_toolRoundsKey) ?? _defaultToolCallRounds;

  /// 2026-09-14 P3-2 单工具执行超时(秒，shell默认超时/MCP超时共用)
  int get toolCallTimeoutSec =>
      CusGetStorage().box.read(_toolTimeoutKey) ?? _defaultToolTimeoutSec;

  /// 2026-09-11 实测反馈：工具执行期间无任何提示，等待感明显。
  /// 当前正在执行的工具友好名(执行中非空，结束置null)；
  /// UI(消息气泡的生成中区域)监听显示"正在调用工具: xxx"
  final ValueNotifier<String?> activeToolCall = ValueNotifier<String?>(null);

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

    /// 2026-09-11 MCP集成(P1-1)：会话级MCP工具开关
    bool isMcpEnabled = false,

    /// 2026-09-14 P3-11 内置终端命令工具开关(全局设置，桌面端生效)
    bool isShellToolEnabled = false,
  }) async* {
    // 获取请求配置
    final requestConfig = await _prepareRequestConfig(
      conversationId,
      platformId,
      modelId,
      isWebSearch,
      isMcpEnabled: isMcpEnabled,
    );

    // 2026-09-15 P4-3 MCP sampling上下文(server反向调用LLM时用当前
    // 对话的平台/密钥/模型)
    updateMcpSamplingContext(
      requestConfig.platform,
      requestConfig.apiKey,
      requestConfig.model,
    );

    // 构建请求体
    final request = await _buildChatRequest(
      messages: messages,
      model: requestConfig.model,
      conversation: requestConfig.conversation,
      isWebSearch: isWebSearch,
      isMcpEnabled: isMcpEnabled,
      isShellToolEnabled: isShellToolEnabled,
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
    bool isWebSearch, {
    bool isMcpEnabled = false,
  }) async {
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

    // 2026-09-11 MCP集成(P1-1)：加载启用的MCP server配置(连接是懒式的)
    if (isMcpEnabled) {
      await _mcpManager.initialize();
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
    bool isMcpEnabled = false,
    bool isShellToolEnabled = false,
    required String platformId,
    required bool stream,
  }) async {
    // 构建工具列表（如果开启联网搜索且有可用工具）
    List<OpenAITool>? tools;

    // 2026-09-12 搜索渠道偏好重构(全局设置，见SearchChannelPreference)：
    // 联网开关开启时按偏好注入一种搜索工具，杜绝第三方web_search与
    // MCP搜索源重复注入；无工具可用时回落平台自带搜索
    // (_handleWebSearch按adapter拼配置，原有per-platform模式仍生效)
    if (isWebSearch) {
      tools = await _resolveSearchTools(model);
    }

    // 2026-09-11 MCP集成(P1-1)：会话开启MCP且有可用server工具时注入。
    // 2026-09-12 渠道化：排除标记为"搜索源"的server——其工具只通过
    // 联网搜索渠道注入(见_resolveSearchTools)，避免重复
    // 同样受模型工具调用能力约束；懒连接失败的server本轮跳过，模型
    // 看不到该server工具属正常降级，不阻断聊天
    if (isMcpEnabled) {
      if (model.supportsToolCalling == true) {
        await _mcpManager.ensureAllConnected();
        final mcpTools = _mcpManager.getTools(excludeSearchSources: true);
        pl.i('MCP工具注入: ${mcpTools.length}个(已排除搜索源server)');
        // 2026-09-15 诊断提示(Ubuntu实测教训)：搜索源server的工具只通过
        // 联网搜索渠道注入——只开MCP不开联网搜索时它对模型完全不可见
        if (!isWebSearch && _mcpManager.hasEnabledSearchSourceServers) {
          pl.w('存在搜索源server但联网搜索未开启，其工具本轮不注入(如需使用请在输入区开启联网搜索)');
        }
        if (mcpTools.isNotEmpty) {
          tools = tools == null ? mcpTools : [...tools, ...mcpTools];
        }
      } else {
        pl.w('MCP开关已开但当前模型不支持工具调用，跳过MCP工具注入');
      }
    }

    // 2026-09-14 内置时间工具：解决模型不知道"今天/明天/昨天"等相对
    // 表述对应实际日期的问题(设备本地时钟，无需联网，调研无免费公共
    // 远程时间MCP故内置)；支持工具调用的模型恒注入，与搜索/MCP开关解耦
    if (model.supportsToolCalling == true) {
      final timeTool = BuiltinDateTimeTool.buildTool();
      tools = tools == null ? [timeTool] : [...tools, timeTool];
    }

    // 2026-09-14 P3-11 内置终端命令工具：桌面端+全局开关开启时注入；
    // 非只读命令执行前走审批横幅(P3-12安全策略拦截危险命令)
    if (isShellToolEnabled &&
        BuiltinShellTool.isSupported &&
        model.supportsToolCalling == true) {
      final shellTool = BuiltinShellTool.buildTool();
      tools = tools == null ? [shellTool] : [...tools, shellTool];
      pl.i('内置终端命令工具注入(桌面端)');
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

  /// 2026-09-12 按全局搜索渠道偏好解析联网搜索的注入工具(渠道互斥，
  /// 保证同一时刻只有一个搜索渠道生效)。
  /// 返回null表示无工具注入(调用方路径回落平台自带搜索配置)。
  /// - platformOnly: 恒null(直接走平台自带，按平台计费)
  /// - thirdPartyOnly: 已配置第三方Key→web_search工具；无Key回落平台自带
  /// - mcpOnly: 已连接搜索源server→其工具；无则回落平台自带
  /// - auto(默认): 第三方Key > MCP搜索源 > 平台自带
  /// 模型不支持工具调用时恒null(平台自带搜索不受工具能力约束)
  Future<List<OpenAITool>?> _resolveSearchTools(UnifiedModelSpec model) async {
    if (model.supportsToolCalling != true) {
      pl.i('模型不支持工具调用，联网搜索走平台自带搜索(如平台支持)');
      return null;
    }

    final pref = await _searchToolManager.getSearchChannelPreference();

    switch (pref) {
      case SearchChannelPreference.platformOnly:
        pl.i('搜索渠道=平台自带(全局偏好指定)');
        return null;

      case SearchChannelPreference.thirdPartyOnly:
        if (!_searchToolManager.hasAvailableTools()) {
          pl.w('搜索渠道=第三方但未配置任何搜索Key，回落平台自带搜索');
          return null;
        }
        pl.i('搜索渠道=第三方工具(web_search)');
        return _searchToolManager.getSearchTools();

      case SearchChannelPreference.mcpOnly:
        await _mcpManager.ensureAllConnected();
        final mcpTools = _mcpManager.getSearchSourceTools();
        if (mcpTools.isEmpty) {
          pl.w('搜索渠道=MCP但无已连接的搜索源server，回落平台自带搜索');
          return null;
        }
        pl.i('搜索渠道=MCP搜索源(${mcpTools.length}个工具)');
        return mcpTools;

      case SearchChannelPreference.auto:
        if (_searchToolManager.hasAvailableTools()) {
          pl.i('搜索渠道=auto→第三方工具');
          return _searchToolManager.getSearchTools();
        }
        await _mcpManager.ensureAllConnected();
        final mcpTools = _mcpManager.getSearchSourceTools();
        if (mcpTools.isNotEmpty) {
          pl.i('搜索渠道=auto→MCP搜索源(${mcpTools.length}个工具)');
          return mcpTools;
        }
        pl.i('搜索渠道=auto→无第三方Key无MCP搜索源，回落平台自带搜索');
        return null;
    }
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
    // 2026-09-14 终态防御：实测部分平台/网关会在finishReason终态(stop/
    // length/error/content_filter)后把内容原样重推一遍——用户看到正文
    // 连续重复两份、error chunk双发。协议上终态后不应再有内容chunk，
    // 丢弃并记日志(终态判定排除tool_calls：其break后还有工具续传流程)
    var sawTerminalFinish = false;
    var droppedChunkCount = 0;
    String? lastErrorSignature;

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
        // 2026-09-14 同一错误只上屏一次(实测平台error双发→报错文本重复两份)
        final errorResponse = _extractStreamErrorResponse(json);
        if (errorResponse != null) {
          final signature = json is Map<String, dynamic>
              ? json['error'].toString()
              : null;
          if (sawTerminalFinish || signature == lastErrorSignature) {
            pl.w('[终态防御] 丢弃终态后重复/二次推送的错误帧: $data');
            continue;
          }
          lastErrorSignature = signature;
          sawTerminalFinish = true;
          yield errorResponse;
          continue;
        }

        final streamResponse = OpenAIChatCompletionResponse.fromJson(json);
        final finishReason = streamResponse.choices.isNotEmpty
            ? streamResponse.choices.first.finishReason
            : null;

        if (sawTerminalFinish) {
          // 2026-09-14 usage统计帧放行：stream_options.include_usage开启时
          // 平台在stop帧后会发一个choices:[]只带usage的统计chunk(实测硅基
          // 流动Qwen3.8)——此前误判为"平台重发"丢弃，导致token消耗不显示
          if (streamResponse.choices.isEmpty) {
            yield streamResponse;
            continue;
          }
          if (finishReason == null) {
            droppedChunkCount++;
            if (droppedChunkCount <= 3) {
              // 2026-09-14 按用户要求打印被丢弃chunk的具体内容(诊断用)
              pl.w('[终态防御] 丢弃终态后的内容chunk(疑似平台重发响应): $data');
            }
            continue;
          }
          if (finishReason != 'tool_calls') continue;
        }
        if (finishReason != null && finishReason != 'tool_calls') {
          sawTerminalFinish = true;
        }

        // 即时透传给UI(流式追加的关键)
        yield streamResponse;
      } catch (e) {
        // 虽然解析出错，但继续处理
        pl.i('解析JSON失败: $e, 数据: "$data"');
      }
    }
    if (droppedChunkCount > 0) {
      pl.w('[终态防御] 普通流共丢弃$droppedChunkCount个终态后chunk');
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
  /// 2026-09-11 流式透传重构(实测反馈：工具调用后回答整块显示不流式)：
  /// 此前实现是 await 把整个流消费完累积到列表后再批量yield——所有带
  /// tools的请求(包括最后一轮最终回答)都变成"伪流式"，模型输出要等
  /// 流结束后才一次性上屏。现改为边收chunk边yield(同时累积tool_calls
  /// 状态)，真正流式追加；联网搜索路径同样受益
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
    final accumulatedToolCalls = <int, Map<String, dynamic>>{};
    String? assistantContent;
    var hasCompleteToolCalls = false;

    // 2026-09-14 终态防御(与普通流同款)：终态(stop/length/error等，
    // 排除tool_calls——其break后还有工具续传)后平台重推的内容chunk与
    // 重复error帧一律丢弃，避免正文/报错文本重复两份
    var sawTerminalFinish = false;
    var droppedChunkCount = 0;
    String? lastErrorSignature;

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
        // 2026-09-14 同一错误只上屏一次(实测平台error双发→报错文本重复两份)
        final errorResponse = _extractStreamErrorResponse(json);
        if (errorResponse != null) {
          final signature = json is Map<String, dynamic>
              ? json['error'].toString()
              : null;
          if (sawTerminalFinish || signature == lastErrorSignature) {
            pl.w('[终态防御] 丢弃终态后重复/二次推送的错误帧: $data');
            continue;
          }
          lastErrorSignature = signature;
          sawTerminalFinish = true;
          yield errorResponse;
          continue;
        }

        final response = OpenAIChatCompletionResponse.fromJson(json);

        // 2026-09-14 终态防御：终态后到达的内容chunk丢弃(不透传不累积)
        final finishReason = response.choices.isNotEmpty
            ? response.choices.first.finishReason
            : null;
        if (sawTerminalFinish) {
          // 2026-09-14 usage统计帧放行(与普通流同款，见彼处注释)
          if (response.choices.isEmpty) {
            yield response;
            continue;
          }
          if (finishReason == null) {
            droppedChunkCount++;
            if (droppedChunkCount <= 3) {
              pl.w('[终态防御] 丢弃终态后的内容chunk(疑似平台重发响应): $data');
            }
            continue;
          }
          if (finishReason != 'tool_calls') continue;
        }
        if (finishReason != null && finishReason != 'tool_calls') {
          sawTerminalFinish = true;
        }

        // 即时透传给UI(流式追加的关键)
        yield response;

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

    // 流结束：如果有完整的工具调用，执行工具并重新请求
    // 2026-09-09 轮数上限：超过maxToolCallRounds不再执行工具，防止模型循环调用
    // 2026-09-12 判定放宽：部分中转平台流式tool_calls结束时finishReason
    // 返回'stop'而非'tool_calls'，仅靠finishReason会漏掉已完整到达的
    // 工具调用(表现为模型说完引导语就无声结束)——补充以实际累积结果
    // 判定(arguments分片拼装完整即可执行)；取消时不执行(可能只有残片)
    final hasExecutableToolCalls =
        hasCompleteToolCalls || accumulatedToolCalls.isNotEmpty;
    if (droppedChunkCount > 0) {
      pl.w('[终态防御] 工具流共丢弃$droppedChunkCount个终态后chunk');
    }
    pl.i(
      '[工具调试] 流结束: hasComplete=$hasCompleteToolCalls '
      'accumulated=${accumulatedToolCalls.keys.toList()} '
      'contentLen=${assistantContent?.length ?? 0} '
      'cancelled=${cancelToken.isCancelled}',
    );
    if (!cancelToken.isCancelled &&
        toolCallDepth < maxToolCallRounds &&
        hasExecutableToolCalls) {
      pl.i('检测到完整工具调用，开始执行: ${accumulatedToolCalls.keys}');

      yield* _executeToolsAndContinue(
        _ToolCallStreamResult(
          accumulatedToolCalls: accumulatedToolCalls,
          assistantContent: assistantContent,
          hasCompleteToolCalls: hasCompleteToolCalls,
        ),
        platform,
        apiKey,
        originalRequest,
        cancelToken,
        isWebSearch: isWebSearch,
        toolCallDepth: toolCallDepth,
      );
    } else if (!cancelToken.isCancelled &&
        toolCallDepth >= maxToolCallRounds &&
        hasExecutableToolCalls) {
      // 2026-09-09 达到轮数上限后不再静默中断：不执行工具，但仍强制续传
      // 一次(不带tools)，让模型基于已收集的搜索结果生成最终回答，
      // 否则消息会停在工具调用阶段，前面的引导语显得毫无意义
      pl.w('已达到最大工具调用轮数($maxToolCallRounds)，强制无工具续传生成最终回答');
      yield* _continueWithoutTools(
        accumulatedToolCalls,
        assistantContent,
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

  /// 2026-09-11 已废弃删除：原_processToolCallStream"整流await后批量返回"
  /// 的累积方式是带tools请求伪流式的根因，累积逻辑已内联进
  /// _handleStreamWithToolCalls(边收边yield)

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
    // 2026-09-15 防御兜底：各工具分支虽均有catch，但Ubuntu实测曾出现
    // 执行层未知异常无日志直达onError致"生成失败"且无工具卡片段——
    // 这层最后防线把任何批量执行异常转为合成错误tool消息(保住
    // tool_call_id配对)继续续传，不让单次工具层异常杀掉整条流
    List<Map<String, dynamic>> toolResults;
    try {
      toolResults = await _executeToolCalls(
        toolCallResult.accumulatedToolCalls,
      );
    } catch (e, st) {
      pl.e('工具批量执行异常(防御兜底转错误回填): $e\n$st');
      toolResults = toolCallResult.accumulatedToolCalls.values.map((tc) {
        final id = (tc['id'] as String?) ?? '';
        return {
          'tool_call_id': id.isEmpty
              ? 'tool_call_${DateTime.now().millisecondsSinceEpoch}'
              : id,
          'role': 'tool',
          'name': tc['function']['name'],
          'content': '工具执行发生内部错误，已跳过本次调用: $e',
        };
      }).toList();
    }

    if (toolResults.isNotEmpty) {
      // 2026-09-12 段化哨兵(P3-10)：本轮每个工具调用注入一个标记响应，
      // viewmodel据此在气泡内插入"工具调用段"(内嵌卡片)并封上一段；
      // 放在工具执行结果返回后、续传请求前，保证段序：思考→正文→工具→下一轮
      // 2026-09-14 哨兵直接携带结果与参数摘要(viewmodel写入段并落库，
      // 消息气泡内工具卡片可展开查看原始终端输出/工具结果)
      var i = 0;
      for (final toolCallData in toolCallResult.accumulatedToolCalls.values) {
        yield OpenAIChatCompletionResponse(
          id: 'tool-invoking',
          choices: const [],
          toolInvoking: _friendlyToolName(
            toolCallData['function']['name'] as String,
          ),
          toolArgsSummary: _summarizeToolArgs(
            toolCallData['function']['arguments'] as String?,
          ),
          toolResult: i < toolResults.length
              ? toolResults[i]['content'] as String?
              : null,
          // P3-14 工具卡片显示执行耗时
          toolElapsedMs: i < toolResults.length
              ? toolResults[i]['elapsed_ms'] as int?
              : null,
        );
        i++;
      }

      // 创建新请求，保留工具配置以便模型能够理解上下文
      final newRequest = _buildRequestWithToolResults(
        originalRequest,
        toolCallResult.assistantContent,
        toolCallResult.accumulatedToolCalls,
        toolResults,
      );

      pl.i('发送包含工具结果的新请求，等待模型生成最终回答...');

      // 递归调用处理新请求(轮数+1)
      // 2026-09-12 空流重试链(白山中转实测)：字节级日志证实续传请求收到
      // "只含data:[DONE]的合法空响应"(14字节，协议正常但模型零输出)，
      // 同body curl却完整回答——间歇性/计数型风控特征。三层兜底：
      // ①原样重试一次(间歇性时空流不复发) → ②内联降级(工具结果转
      // user消息不带tools) → ③viewmodel空回答兜底提示
      var yieldedCount = 0;
      await for (final response in _handleResponse(
        platform,
        apiKey,
        newRequest,
        cancelToken,
        stream: true,
        isWebSearch: isWebSearch,
        toolCallDepth: toolCallDepth + 1,
      )) {
        yieldedCount++;
        yield response;
      }

      // ①原样重试：同请求再发一次(新连接，风控计数特征下第二次大概率正常)
      if (yieldedCount == 0 && !cancelToken.isCancelled) {
        pl.w('续传轮流为空(收到空completion)，原样重试一次...');
        await for (final response in _handleResponse(
          platform,
          apiKey,
          newRequest,
          cancelToken,
          stream: true,
          isWebSearch: isWebSearch,
          toolCallDepth: toolCallDepth + 1,
        )) {
          yieldedCount++;
          yield response;
        }
      }

      // ②内联降级：工具结果转user文本消息重试(绕开role:tool形态)
      if (yieldedCount == 0 && !cancelToken.isCancelled) {
        pl.w('原样重试仍为空，以内联形态降级重试');
        final fallbackRequest = _buildFallbackRequestWithInlineToolResults(
          originalRequest,
          toolResults,
        );
        await for (final response in _handleResponse(
          platform,
          apiKey,
          fallbackRequest,
          cancelToken,
          stream: true,
          isWebSearch: isWebSearch,
          toolCallDepth: toolCallDepth + 1,
        )) {
          yieldedCount++;
          yield response;
        }
      }
    }
  }

  /// 2026-09-12 空流降级请求：工具结果不走标准role:tool消息，内联为
  /// user文本消息追加到原始对话后；不带tools让模型直接基于结果作答
  /// (用于不支持role:tool续传的中转平台，白山api.edgefn.net实测空流)
  OpenAIChatCompletionRequest _buildFallbackRequestWithInlineToolResults(
    OpenAIChatCompletionRequest originalRequest,
    List<Map<String, dynamic>> toolResults,
  ) {
    final buffer = StringBuffer('以下是工具调用的结果，请基于这些结果回答我之前的问题：\n\n');
    for (final result in toolResults) {
      buffer.writeln('【${result['name'] ?? '工具'}】');
      buffer.writeln(result['content'] ?? '');
      buffer.writeln();
    }

    final newMessages = List<Map<String, dynamic>>.from(
      originalRequest.messages,
    )..add({'role': 'user', 'content': buffer.toString()});

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
      // 不带tools：模型基于内联结果直接生成最终回答，无从再发起工具调用
    );
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

    // 添加助手的工具调用消息
    // 2026-09-12 content规范化：模型只输出tool_calls无正文时assistantContent
    // 为空串，OpenAI标准形态应为null(部分中转对"content":""+tool_calls
    // 的组合校验异常)
    final normalizedAssistantContent =
        (assistantContent == null || assistantContent.trim().isEmpty)
        ? null
        : assistantContent;

    newMessages.add({
      'role': 'assistant',
      'content': normalizedAssistantContent,
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
    if (toolCallDepth >= maxToolCallRounds) {
      if (toolCalls.isNotEmpty) {
        pl.w('已达到最大工具调用轮数($maxToolCallRounds)，强制无工具续传生成最终回答');
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
  /// 2026-09-14 P3-6 并行化：多个工具并发执行(审批横幅在viewmodel侧
  /// 排队串行弹出)，结果按提交顺序回收——tool_call_id对应与引用合并
  /// 顺序保持稳定；执行中提示显示并行数量
  Future<List<Map<String, dynamic>>> _executeToolCalls(
    Map<int, Map<String, dynamic>> accumulatedToolCalls,
  ) async {
    final entries = accumulatedToolCalls.values.toList();
    if (entries.isEmpty) return [];

    // 执行中提示：单个显示工具名，多个显示数量
    activeToolCall.value = entries.length > 1
        ? '并行执行 ${entries.length} 个工具'
        : _friendlyToolName(entries.first['function']['name'] as String);

    try {
      final outcomes = await Future.wait(entries.map(_executeSingleToolCall));

      // 引用按提交顺序合并去重(多轮递归时在上一轮基础上累积，语义不变)
      final collected = _lastSearchReferences ?? <Map<String, dynamic>>[];
      for (final outcome in outcomes) {
        final refs = outcome.refs;
        if (refs != null && refs.isNotEmpty) {
          final seenUrls = collected.map((r) => r['url']).toSet();
          collected.addAll(refs.where((r) => !seenUrls.contains(r['url'])));
        }
      }
      if (collected.isNotEmpty) _lastSearchReferences = collected;

      return outcomes.map((o) => o.result).toList();
    } finally {
      // 全部工具执行结束清空提示
      activeToolCall.value = null;
    }
  }

  /// 执行单个工具调用(P3-6 从顺序循环体抽取)；异常不rethrow，
  /// 一律回填错误文本由模型向用户解释。
  /// 2026-09-14 P3-14 外层包装计时，耗时写入result map的elapsed_ms
  /// (哨兵读取展示于工具卡片，不污染发给模型的content)
  Future<({Map<String, dynamic> result, List<Map<String, dynamic>>? refs})>
  _executeSingleToolCall(Map<String, dynamic> toolCallData) async {
    final stopwatch = Stopwatch()..start();
    final outcome = await _executeSingleToolCallInner(toolCallData);
    stopwatch.stop();
    outcome.result['elapsed_ms'] = stopwatch.elapsedMilliseconds;
    return outcome;
  }

  Future<({Map<String, dynamic> result, List<Map<String, dynamic>>? refs})>
  _executeSingleToolCallInner(Map<String, dynamic> toolCallData) async {
    final functionName = toolCallData['function']['name'] as String;
    final argumentsStr = toolCallData['function']['arguments'] as String;

    final toolCallId = toolCallData['id'] as String;
    final actualToolCallId = toolCallId.isEmpty
        ? 'tool_call_${DateTime.now().millisecondsSinceEpoch}'
        : toolCallId;

    // 2026-09-14 P3-9 收敛：按provider注册顺序分发——搜索provider
    // (web_search)→MCP provider(mcp__前缀)；内置时间/shell保持静态
    // 分支(无manager状态，无硬编码债)。所有provider的异常均不rethrow，
    // 一律回填错误文本由模型向用户解释

    // 搜索provider(第三方web_search，引用走ToolResult.references)
    if (_searchToolManager.canHandle(functionName)) {
      try {
        if (argumentsStr.trim().isEmpty) {
          throw FormatException('工具调用参数为空');
        }

        final arguments = _parseToolCallArguments(argumentsStr);
        final result = await _searchToolManager.handleToolCall(
          functionName,
          arguments,
        );

        return (
          result: <String, dynamic>{
            'tool_call_id': actualToolCallId,
            'role': 'tool',
            'name': functionName,
            'content': _truncateToolResult(result.content),
          },
          refs: result.references,
        );
      } catch (e) {
        pl.e('工具调用执行失败: $e');
        // 单个工具失败不影响已收集的其他工具引用
        return (
          result: <String, dynamic>{
            'tool_call_id': actualToolCallId,
            'role': 'tool',
            'name': functionName,
            'content': '搜索失败: $e',
          },
          refs: null,
        );
      }
    }

    // 内置时间工具：纯读本地时钟(2026-09-15 补catch防平台时区层异常)
    if (functionName == BuiltinDateTimeTool.toolName) {
      String content;
      try {
        content = BuiltinDateTimeTool.execute();
      } catch (e) {
        pl.e('内置时间工具执行异常: $e');
        content = '获取本地时间失败: $e';
      }
      return (
        result: <String, dynamic>{
          'tool_call_id': actualToolCallId,
          'role': 'tool',
          'name': functionName,
          'content': content,
        },
        refs: null,
      );
    }

    // 2026-09-14 P3-11/P3-12 内置终端命令工具：
    // 黑名单直接拒绝 > 只读白名单直接执行 > 其余审批横幅
    if (functionName == BuiltinShellTool.toolName) {
      return (
        result: await _executeShellToolCall(
          actualToolCallId,
          functionName,
          argumentsStr,
        ),
        refs: null,
      );
    }

    // MCP provider路由(P1-2引入；P3-9改为canHandle分发，与搜索provider
    // 同构，后续新provider按此模式接入)
    if (_mcpManager.canHandle(functionName)) {
      try {
        if (argumentsStr.trim().isEmpty) {
          throw FormatException('工具调用参数为空');
        }

        final arguments = _parseToolCallArguments(argumentsStr);
        final result = await _mcpManager.handleToolCall(
          functionName,
          arguments,
        );

        return (
          result: <String, dynamic>{
            'tool_call_id': actualToolCallId,
            'role': 'tool',
            'name': functionName,
            'content': _truncateToolResult(result.content),
          },
          // P3-5 MCP工具结果中的URL引用(web_search同结构，回收层去重合并)
          refs: result.references,
        );
      } catch (e) {
        pl.e('MCP工具调用执行失败: $e');
        // 单个工具失败回填错误文本，让模型自行向用户解释(与搜索一致)
        return (
          result: <String, dynamic>{
            'tool_call_id': actualToolCallId,
            'role': 'tool',
            'name': functionName,
            'content': '工具执行失败: $e',
          },
          refs: null,
        );
      }
    }

    // 未知工具名兜底(模型幻觉出的工具)
    return (
      result: <String, dynamic>{
        'tool_call_id': actualToolCallId,
        'role': 'tool',
        'name': functionName,
        'content': '未知工具: $functionName',
      },
      refs: null,
    );
  }

  /// 工具名转UI友好显示名
  String _friendlyToolName(String functionName) {
    if (functionName == 'web_search') return '联网搜索';
    if (functionName == BuiltinDateTimeTool.toolName) return '获取当前时间';
    if (functionName == BuiltinShellTool.toolName) return '执行终端命令';
    // mcp__<server>__<tool> → server.tool
    final parsed = McpServerManager.parseNamespacedToolName(functionName);
    if (parsed != null) return '${parsed.serverName}.${parsed.toolName}';
    return functionName;
  }

  /// 2026-09-14 哨兵携带的参数摘要：截断到200字符(段JSON落库，
  /// 摘要即可，完整参数在请求消息里)
  static String _summarizeToolArgs(String? raw) {
    final t = raw?.trim() ?? '';
    if (t.isEmpty) return '';
    const maxLen = 200;
    if (t.length <= maxLen) return t;
    return '${t.substring(0, maxLen)}…';
  }

  /// 2026-09-12 工具结果体积限制：实测白山中转(api.edgefn.net)对messages
  /// 含大体积工具结果的请求(Exa搜索10条新闻约几十KB)返回200但零chunk空流，
  /// 小payload正常——统一截断到上限保住续传可用性(模型仍能拿到核心信息)
  static String _truncateToolResult(String content) {
    const maxLen = 6000;
    if (content.length <= maxLen) return content;
    var end = maxLen;
    // 2026-09-14 UTF-16代理对保护：截断点落在emoji等代理对中间会产生
    // 孤立代理项，渲染时抛"string is not well-formed UTF-16"
    final lastUnit = content.codeUnitAt(end - 1);
    if (lastUnit >= 0xD800 && lastUnit <= 0xDBFF) end--;
    return '${content.substring(0, end)}\n\n[…工具结果过长已截断]';
  }

  /// 2026-09-14 P3-11/P3-12 内置终端命令工具执行：
  /// 安全判定(黑名单拒绝>白名单放行>审批横幅) → 执行回填。
  /// 所有异常路径均以文本回填，单次失败不中断Agent循环
  Future<Map<String, dynamic>> _executeShellToolCall(
    String toolCallId,
    String functionName,
    String argumentsStr,
  ) async {
    String content;
    try {
      if (argumentsStr.trim().isEmpty) throw const FormatException('参数为空');
      final arguments = _parseToolCallArguments(argumentsStr);
      final command = arguments['command']?.toString() ?? '';
      if (command.trim().isEmpty) throw const FormatException('缺少command参数');

      final safety = BuiltinShellTool.classify(command);
      if (safety == ShellSafety.dangerous) {
        // 黑名单：直接拒绝不询问，告知模型与用户原因
        pl.w('shell命令被安全策略拦截: $command');
        content =
            '该命令命中危险命令安全策略，已被拦截且不会执行: $command\n'
            '请勿重试相同或相似命令，改为向用户口头说明或建议用户手动执行。';
      } else if (safety == ShellSafety.readOnly) {
        // 只读白名单：免审批直接执行
        content = await BuiltinShellTool.execute(
          command: command,
          workingDirectory: arguments['working_directory']?.toString(),
          timeoutSeconds:
              (arguments['timeout_seconds'] as num?)?.toInt() ??
              toolCallTimeoutSec,
        );
      } else {
        // 普通命令：走审批横幅；无审批处理器时拒绝执行(安全默认)
        final handler = builtinToolApprovalHandler;
        if (handler == null) {
          content = '终端命令执行未获得授权(approval handler不可用)，已取消: $command';
        } else {
          final decision = await handler(
            ToolApprovalRequest(
              serverName: null,
              title: '执行终端命令',
              displayDetail: command,
              sessionAllowKey: BuiltinShellTool.sessionAllowKey(command),
            ),
          );
          if (decision == ToolApprovalDecision.deny) {
            pl.i('用户拒绝shell命令: $command');
            content =
                '用户拒绝了本次命令执行，不会执行: $command\n'
                '请尊重用户决定，不要重试相同或相似命令，'
                '改为口头说明或询问用户希望如何处理。';
          } else {
            content = await BuiltinShellTool.execute(
              command: command,
              workingDirectory: arguments['working_directory']?.toString(),
              timeoutSeconds:
                  (arguments['timeout_seconds'] as num?)?.toInt() ??
                  toolCallTimeoutSec,
            );
          }
        }
      }
    } catch (e) {
      pl.e('内置终端命令工具执行失败: $e');
      content = '命令执行失败: $e';
    }

    // 显式类型参数：async return的map literal不继承Future泛型上下文的
    // 场景下防窄化(见FIX_LOG六十八的Map<String,String>事故)
    return <String, dynamic>{
      'tool_call_id': toolCallId,
      'role': 'tool',
      'name': functionName,
      'content': _truncateToolResult(content),
    };
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
  // 2026-09-11 流式透传重构后不再收集responses(已内联yield)，仅保留
  // 流结束后的工具调用累积状态
  final Map<int, Map<String, dynamic>> accumulatedToolCalls;
  final String? assistantContent;
  final bool hasCompleteToolCalls;

  _ToolCallStreamResult({
    required this.accumulatedToolCalls,
    required this.assistantContent,
    required this.hasCompleteToolCalls,
  });
}

// 2026-09-09 工具调用续传的最大轮数(防模型循环调用工具)
// 2026-09-14 P3-2 配置化：改为读全局GetStorage(内存同步读开销可忽略，
// 设置页修改即时生效无需重启)，MCP设置页"Agent执行设置"卡配置
const String _toolRoundsKey = 'unified_chat_tool_rounds';
const int _defaultToolCallRounds = 10;

const String _toolTimeoutKey = 'unified_chat_tool_timeout_sec';
const int _defaultToolTimeoutSec = 60;
