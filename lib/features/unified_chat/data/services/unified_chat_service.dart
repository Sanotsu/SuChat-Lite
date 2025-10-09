// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

import '../../../../core/network/dio_client/cus_http_client.dart';
import '../../../../core/network/dio_client/cus_http_request.dart';
import '../../../../core/network/dio_client/interceptor_error.dart';
import '../../../../core/utils/simple_tools.dart';
import '../../../branch_chat/domain/entities/input_message_data.dart';
import '../database/unified_chat_dao.dart';
import '../models/unified_platform_spec.dart';
import '../models/unified_chat_message.dart';
import '../models/openai_request.dart';
import '../models/openai_response.dart';
import 'unified_secure_storage.dart';
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

  // 临时存储最后一次搜索的参考链接
  List<Map<String, dynamic>>? _lastSearchReferences;

  /// 统一发送消息方法（流式和非流式）
  Stream<OpenAIChatCompletionResponse> sendMessage({
    required String conversationId,
    required List<UnifiedChatMessage> messages,
    required String modelId,
    required String platformId,
    bool stream = true,
    bool isWebSearch = false,
  }) async* {
    // 获取平台与模型
    final platform = await _chatDao.getPlatformSpec(platformId);
    final model = await _chatDao.getModelSpec(modelId);
    if (platform == null || model == null) {
      throw Exception('平台或模型不存在');
    }

    // 获取API Key
    final apiKey = await UnifiedSecureStorage.getApiKey(platformId);
    if (apiKey == null) {
      throw Exception('API密钥未配置');
    }

    // 获取会话配置
    final conversation = await _chatDao.getConversation(conversationId);
    if (conversation == null) {
      throw Exception('对话不存在');
    }

    // 初始化搜索工具管理器
    await _searchToolManager.initialize();

    // 构建工具列表（如果开启联网搜索且有可用工具）
    List<OpenAITool>? tools;
    print(
      "联网搜索状态: isWebSearch=$isWebSearch, hasAvailableTools=${_searchToolManager.hasAvailableTools()}",
    );
    if (isWebSearch && _searchToolManager.hasAvailableTools()) {
      // 注意：阿里百炼平台和智谱平台有自己的联网搜索配置(在_handleResponse中处理)，就不需要在这里添加tools了
      // 还要注意：这里只是简化逻辑，阿里百炼支持联网搜索的模型并不多，但这里都没有使用tools让不支持联网模型可以联网
      // 再说一句：非内置可联网的模型使用tools外部工具调用，所以需要模型也支持tools
      if (platform.id != UnifiedPlatformId.aliyun.name &&
          platform.id != UnifiedPlatformId.zhipu.name &&
          model.supportsToolCalling) {
        tools = _searchToolManager.getSearchTools();
        print("已添加联网搜索工具: ${tools.length}个");
        print("工具定义: ${tools.map((t) => t.toJson()).toList()}");
      }
    } else {
      print(
        "未添加联网搜索工具 - isWebSearch: $isWebSearch, hasAvailableTools: ${_searchToolManager.hasAvailableTools()}",
      );
    }

    print(
      "**************是否启用了思考模式: ${conversation.extraParams?['enableThinking'] ?? false} ",
    );

    // 构建请求体
    final request = OpenAIChatCompletionRequest.fromMessages(
      model: model.modelName,
      messages: messages,
      temperature: conversation.temperature,
      maxTokens: conversation.maxTokens,
      topP: conversation.topP,
      frequencyPenalty: conversation.frequencyPenalty,
      presencePenalty: conversation.presencePenalty,
      stream: stream,
      enableThinking: conversation.extraParams?['enableThinking'] ?? false,
      tools: tools,
      // 2025-10-07 测试时openrouter有些模型工具调用，报错Tool choice must be auto
      // 所以这里简单设置auto，不强制
      toolChoice: tools != null ? 'auto' : null,
      // toolChoice: tools != null
      //     ? (
      //       // 如果消息中包含"搜索"、"查询"、"最新"等关键词，强制调用工具
      //       messages.any(
      //             (msg) =>
      //                 msg.content?.contains(RegExp(r'搜索|查询|最新|今天|新闻|资讯')) ==
      //                 true,
      //           )
      //           ? {
      //               'type': 'function',
      //               'function': {'name': 'web_search'},
      //             }
      //           : 'auto')
      //     : (tools != null &&
      //           tools.where((t) => t.function.name == 'web_search').isNotEmpty)
      //     ? "auto"
      //     : null,
      platformId: platformId,
    );

    print("发送请求到AI平台: ${platform.displayName}");
    print("请求模型: ${model.modelName}");
    print("工具数量: ${tools?.length ?? 0}");
    print("工具选择: ${request.toolChoice}");

    final cancelToken = CancelToken();
    _globalStreamingTokens.add(cancelToken);

    try {
      // 流式处理
      yield* _handleResponse(
        platform,
        apiKey,
        request,
        cancelToken,
        stream: stream,
        isWebSearch: isWebSearch,
      );
    } on CusHttpException catch (e) {
      print("CusHttpExceptionxxxxxxxxxxxxxx错误类型 ${e.runtimeType}");

      // 出错了也要构建一个报错的同类型响应，在对话页面中正确显示
      yield OpenAIChatCompletionResponse(
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
    } catch (e) {
      print("未处理的错误类型 ${e.runtimeType}");

      rethrow;
    } finally {
      _globalStreamingTokens.remove(cancelToken);
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
  }) async* {
    var requestBody = request.toRequestBody(platform: platform);

    // 构建部分平台支持联网搜索的配置
    if (isWebSearch) {
      final webSearchConfig = _handleWebSearch(platform.id, request.model);
      if (webSearchConfig != null) {
        requestBody.addAll(webSearchConfig);
      }
    }

    pl.d('实际发送的消息内容>>>>>>>>>>>>>>>>>>>>>>>>>>>>: ${requestBody.length}');

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

      // 检查非流式响应是否有工具调用
      if (response.choices.isNotEmpty) {
        final choice = response.choices.first;
        final message = choice.message;
        if (message?.toolCalls != null && message!.toolCalls!.isNotEmpty) {
          print("非流式响应检测到工具调用，开始处理...");
          yield* _handleNonStreamToolCalls(
            response,
            platform,
            apiKey,
            request,
            cancelToken,
          );
          return;
        }
      }

      yield response;
      return;
    }

    // 流式响应处理
    final responseBody = responseData as ResponseBody;
    StreamTransformer<Uint8List, List<int>> unit8Transformer =
        StreamTransformer.fromHandlers(
          handleData: (data, sink) {
            sink.add(List<int>.from(data));
          },
        );

    // 如果有工具调用，使用工具调用处理器
    if (request.tools != null && request.tools!.isNotEmpty) {
      yield* _handleStreamWithToolCalls(
        responseBody.stream.transform(unit8Transformer).transform(utf8.decoder),
        platform,
        apiKey,
        request,
        cancelToken,
      );
    } else {
      // 直接处理流式响应
      await for (final chunk
          in responseBody.stream
              .transform(unit8Transformer)
              .transform(utf8.decoder)) {
        if (cancelToken.isCancelled) break;

        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          if (!line.startsWith('data:')) continue;

          final data = line.substring(5).trim();
          if (data.contains('[DONE]')) break;

          try {
            final json = jsonDecode(data);
            final streamResponse = OpenAIChatCompletionResponse.fromJson(json);
            yield streamResponse;
          } catch (e) {
            print('解析JSON失败: $e, 数据: "$data"');
          }
        }
      }
    }
  }

  /// 处理带工具调用的流式响应
  Stream<OpenAIChatCompletionResponse> _handleStreamWithToolCalls(
    Stream<String> dataStream,
    UnifiedPlatformSpec platform,
    String apiKey,
    OpenAIChatCompletionRequest originalRequest,
    CancelToken cancelToken,
  ) async* {
    print('开始处理带工具调用的流式响应...');

    // 用于累积工具调用信息
    final Map<int, Map<String, dynamic>> accumulatedToolCalls = {};
    String? assistantContent;
    bool hasCompleteToolCalls = false;

    await for (final chunk in dataStream) {
      if (cancelToken.isCancelled) break;

      final lines = chunk.split('\n');
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        if (!line.startsWith('data:')) continue;

        final data = line.substring(5).trim();
        if (data.contains('[DONE]')) break;

        try {
          final json = jsonDecode(data);
          final response = OpenAIChatCompletionResponse.fromJson(json);

          // 先返回响应给UI显示
          yield response;

          if (response.choices.isEmpty) {
            print(
              '收到空的choices chunk: id=${response.id}, usage=${response.usage}',
            );
            continue;
          }

          final choice = response.choices.first;
          final message = choice.delta ?? choice.message;

          // 累积助手内容
          if (message?.content != null) {
            assistantContent = (assistantContent ?? '') + message!.content!;
          }

          // 处理工具调用信息
          final toolCalls = message?.toolCalls ?? [];
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
                accumulatedToolCalls[index]!['function']['name'] =
                    function.name!;
              }
              if (function.arguments != null &&
                  function.arguments!.isNotEmpty) {
                accumulatedToolCalls[index]!['function']['arguments'] +=
                    function.arguments!;
              }
            }
          }

          // 检查是否完成了工具调用
          if (choice.finishReason == 'tool_calls') {
            hasCompleteToolCalls = true;
            break;
          }
        } catch (e) {
          print('解析JSON失败: $e, 数据11111111111: "$data"');
        }
      }
    }

    // 执行工具调用并获取结果
    if (hasCompleteToolCalls && accumulatedToolCalls.isNotEmpty) {
      print('检测到完整工具调用，开始执行: ${accumulatedToolCalls.keys}');

      final toolResults = await _executeToolCalls(accumulatedToolCalls);

      if (toolResults.isNotEmpty) {
        // 构建包含工具结果的新请求
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

        // 创建新请求，保留工具配置以便模型能够理解上下文
        final newRequest = OpenAIChatCompletionRequest(
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
          // 保留工具配置，但不强制调用
          tools: originalRequest.tools,
          toolChoice: 'auto', // 让模型自动决定是否需要调用工具
        );

        print('发送包含工具结果的新请求，等待模型生成最终回答...');

        // 递归调用处理新请求
        yield* _handleResponse(
          platform,
          apiKey,
          newRequest,
          cancelToken,
          stream: true,
        );
      }
    }
  }

  /// 处理非流式响应中的工具调用
  Stream<OpenAIChatCompletionResponse> _handleNonStreamToolCalls(
    OpenAIChatCompletionResponse response,
    UnifiedPlatformSpec platform,
    String apiKey,
    OpenAIChatCompletionRequest originalRequest,
    CancelToken cancelToken,
  ) async* {
    print('开始处理非流式响应中的工具调用...');

    // 先返回当前响应给UI显示
    yield response;

    final choice = response.choices.first;
    final message = choice.message;
    final toolCalls = message?.toolCalls ?? [];

    if (toolCalls.isNotEmpty) {
      // 构建工具调用数据结构
      final Map<int, Map<String, dynamic>> accumulatedToolCalls = {};

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
        // 构建包含工具结果的新请求
        final newMessages = List<Map<String, dynamic>>.from(
          originalRequest.messages,
        );

        // 添加助手的工具调用消息
        final toolCallsForMessage = accumulatedToolCalls.values.map((toolCall) {
          return {
            'id': toolCall['id'],
            'type': toolCall['type'],
            'function': toolCall['function'],
          };
        }).toList();

        newMessages.add({
          'role': 'assistant',
          'content': message?.content,
          'tool_calls': toolCallsForMessage,
        });

        // 添加工具调用结果
        newMessages.addAll(toolResults);

        // 创建新请求
        final newRequest = OpenAIChatCompletionRequest(
          model: originalRequest.model,
          messages: newMessages,
          temperature: originalRequest.temperature,
          maxTokens: originalRequest.maxTokens,
          topP: originalRequest.topP,
          frequencyPenalty: originalRequest.frequencyPenalty,
          presencePenalty: originalRequest.presencePenalty,
          stream: originalRequest.stream,
          enableThinking: originalRequest.enableThinking,
          tools: originalRequest.tools,
          toolChoice: 'auto',
        );

        print('发送包含工具结果的新请求，等待模型生成最终回答...');

        // 递归调用处理新请求
        yield* _handleResponse(
          platform,
          apiKey,
          newRequest,
          cancelToken,
          stream: false,
        );
      }
    }
  }

  /// 执行工具调用
  Future<List<Map<String, dynamic>>> _executeToolCalls(
    Map<int, Map<String, dynamic>> accumulatedToolCalls,
  ) async {
    final toolResults = <Map<String, dynamic>>[];

    for (final toolCallData in accumulatedToolCalls.values) {
      final functionName = toolCallData['function']['name'] as String;
      final argumentsStr = toolCallData['function']['arguments'] as String;

      print("参数字符串》》》》》》》》》》》》》$argumentsStr");

      final toolCallId = toolCallData['id'] as String;

      final actualToolCallId = toolCallId.isEmpty
          ? 'tool_call_${DateTime.now().millisecondsSinceEpoch}'
          : toolCallId;

      if (functionName == 'web_search') {
        try {
          print('执行联网搜索工具调用: $argumentsStr');

          if (argumentsStr.trim().isEmpty) {
            throw FormatException('工具调用参数为空');
          }

          // 注意，实际测试发现，这个参数字符不一定是满足json格式的，可能类似下面字符串：
          // <tool_call> {"query": "阿里巴巴最新股价","max_results": 5}</tool_call>
          // 还有可能不是正确格式，类似: <think> xxx一段思考内容xxx </think>
          // 这些在转为json时会报错

          // final arguments = jsonDecode(argumentsStr);

          Map<String, dynamic> arguments = {};

          try {
            // 尝试直接解析整个字符串
            arguments = jsonDecode(argumentsStr);
          } catch (e) {
            // 如果直接解析失败，尝试用正则表达式提取JSON部分
            final regex = RegExp(r'\{[^{}]*\}');
            final match = regex.firstMatch(argumentsStr);

            if (match != null) {
              try {
                final jsonString = match.group(0);
                arguments = jsonDecode(jsonString!);
              } catch (e) {
                print('提取的JSON解析失败: $e');
                arguments = {};
              }
            }

            print('未找到有效的JSON格式内容');
            arguments = {};
          }

          final result = await _searchToolManager.handleToolCall(
            functionName: 'web_search',
            arguments: arguments,
          );

          // 保存搜索结果链接到全局变量，稍后添加到消息中
          _lastSearchReferences =
              result['searchReferences'] as List<Map<String, dynamic>>?;

          toolResults.add({
            'tool_call_id': actualToolCallId,
            'role': 'tool',
            'name': 'web_search',
            'content': result['content'] as String,
          });

          print('搜索工具调用完成，结果长度: ${(result['content'] as String).length}');
          print('搜索链接数量: ${_lastSearchReferences?.length ?? 0}');
        } catch (e) {
          print('工具调用执行失败: $e');
          _lastSearchReferences = null;
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
      if (apiKey == null) return false;

      // 有些平台支持查询模型，还支持查询模型的类型
      Map<String, dynamic>? params;
      if (type != null && type.trim().isNotEmpty) {
        params = {"type": type.trim()};
      }

      String apiPerfix = "/v1/models";
      // 注意，20250916 实测智谱开放平台的API版本是v4,所以获取模型的API也是v4
      if (platformId == UnifiedPlatformId.zhipu.name) {
        apiPerfix = "/v4/models";
      }

      // 2025-10-08 因为阿里云的cc和多媒体资源生成的url差异很多，直接hostUrl拼接v1/models是不完整的
      if (platformId == UnifiedPlatformId.aliyun.name) {
        apiPerfix = "/compatible-mode/v1/models";
      }

      // TODO 火山方舟无法获取模型列表，所以这里不测试
      if (platformId == UnifiedPlatformId.volcengine.name) {
        return true;
      }

      // 使用简单的模型列表请求测试连接
      await HttpUtils.get(
        path: '${platform.hostUrl}$apiPerfix',
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
    print("开始获取平台模型");

    try {
      final platform = await _chatDao.getPlatformSpec(platformId);
      if (platform == null) return [];

      final apiKey = await UnifiedSecureStorage.getApiKey(platformId);
      if (apiKey == null) return [];

      String apiPerfix = "/v1/models";

      // 注意，20250916 实测智谱开放平台的API版本是v4,所以获取模型的API也是v4
      if (platformId == UnifiedPlatformId.zhipu.name) {
        apiPerfix = "/v4/models";
      }

      // 2025-10-08 同测试连接
      if (platformId == UnifiedPlatformId.aliyun.name) {
        apiPerfix = "/compatible-mode/v1/models";
      }

      // TODO 火山方舟无法获取模型列表，所以这里不测试
      if (platformId == UnifiedPlatformId.volcengine.name) {
        return [];
      }

      // 使用简单的模型列表请求测试连接
      final response = await HttpUtils.get(
        path: '${platform.hostUrl}$apiPerfix',
        headers: platform.getAuthHeaders(apiKey),
        showLoading: false,
        showErrorMessage: false,
      );

      print("================$response ${response.runtimeType}");

      /**
     * 结构类似:
     * {
     *  "object": "list",
     *  "data": [{"id": "Qwen/Qwen3-8B","object": "model","created": 0,"owned_by": ""}]
     * }
     */

      List<String> models = [];
      if (response != null) {
        models =
            (response['data'] as List?)
                ?.map((model) => model['id'] as String)
                .toList() ??
            [];
      }

      print("指定平台获取的模型列表: $models");
      return models;
    } catch (e) {
      print("查询模型列表报错 $e");
      rethrow;
    }
  }

  // 处理部分平台的联网搜索设置
  Map<String, dynamic>? _handleWebSearch(String platformId, String modelName) {
    print("处理联网配置的平台-------------------: $platformId, 模型: $modelName");

    // 2025-09-27 看文档，好像是所有模型都支持联网搜索
    // https://docs.bigmodel.cn/cn/guide/tools/web-search
    // https://docs.bigmodel.cn/api-reference/%E5%B7%A5%E5%85%B7-api/%E7%BD%91%E7%BB%9C%E6%90%9C%E7%B4%A2
    // if (platformId == UnifiedPlatformId.zhipu.name && zhipuWebSearchModels.contains(modelName))
    if (platformId == UnifiedPlatformId.zhipu.name) {
      return {
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
    } else if (platformId == UnifiedPlatformId.aliyun.name &&
        aliyunWebSearchModels.contains(modelName)) {
      return {
        "enable_search": true,
        "search_options": {
          // 让模型自己选择，有时候开启联网但并没有需要搜索的内容，就浪费了
          "forced_search": false,
          // 搜索策略可选 turbo max
          // (2025-09-25 有新的 agent 可选， qwen3-max 模型可用，一次0.004元)
          "search_strategy": "turbo",
          // 开启垂域搜索
          "enable_search_extension": true,
        },
      };
    }
    // 注意：火山方舟的联网搜索是Responses API，和通用的对话API从url到参数结构都不一样，不能和阿里智谱一样处理
    // https://www.volcengine.com/docs/82379/1756990
    // else if (platformId == UnifiedPlatformId.volcengine.name &&
    //     volcengineWebSearchModels.contains(modelName)) {
    //   return {
    //     "tools": [
    //       {
    //         "type": "web_search",
    //         // 最多返回10个搜索结果
    //         // "limit": 10,
    //         // 联网搜索来源 https://www.volcengine.com/docs/82379/1338550
    //         // 联网搜索开通 https://console.volcengine.com/ark/region:ark+cn-beijing/components
    //       },
    //     ],
    //     "tool_choice": "auto",
    //   };
    // }
    return null;
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
