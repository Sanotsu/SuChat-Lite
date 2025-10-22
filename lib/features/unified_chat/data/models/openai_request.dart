import 'package:json_annotation/json_annotation.dart';
import 'unified_chat_message.dart';
import 'unified_platform_spec.dart';

part 'openai_request.g.dart';

/// OpenAI聊天完成请求
@JsonSerializable(explicitToJson: true)
class OpenAIChatCompletionRequest {
  final String model;
  final List<Map<String, dynamic>> messages;
  final double? temperature;
  @JsonKey(name: 'max_tokens')
  final int? maxTokens;
  @JsonKey(name: 'top_p')
  final double? topP;
  @JsonKey(name: 'frequency_penalty')
  final double? frequencyPenalty;
  @JsonKey(name: 'presence_penalty')
  final double? presencePenalty;
  final bool? stream;

  @JsonKey(name: 'stream_options')
  final OpenAIStreamOptions? streamOptions;

  // 是否启用思考模式
  // 阿里百炼、硅基流动、无问芯穹 等平台的Qwen3等模型，可以控制是否启动思考模式
  // 智谱 等平台的GLM4.5 新模型，参数是thinking，值为 enabled, disabled
  @JsonKey(name: 'enable_thinking')
  final bool? enableThinking;

  // qwen-omni还有输出音频和音色等配置，直接简化
  @JsonKey(name: 'omni_params')
  final Map<String, dynamic>? omniParams;

  final List<String>? stop;
  final int? n;
  final String? user;
  final List<OpenAIFunction>? functions;
  @JsonKey(name: 'function_call')
  final dynamic functionCall;
  final List<OpenAITool>? tools;
  @JsonKey(name: 'tool_choice')
  final dynamic toolChoice;
  @JsonKey(name: 'response_format')
  final OpenAIResponseFormat? responseFormat;
  final int? seed;
  @JsonKey(name: 'logit_bias')
  final Map<String, int>? logitBias;
  @JsonKey(name: 'logprobs')
  final bool? logprobs;
  @JsonKey(name: 'top_logprobs')
  final int? topLogprobs;

  const OpenAIChatCompletionRequest({
    required this.model,
    required this.messages,
    this.temperature,
    this.maxTokens,
    this.topP,
    this.frequencyPenalty,
    this.presencePenalty,
    this.stream,
    this.streamOptions,
    this.enableThinking = false,
    this.omniParams,
    this.stop,
    this.n,
    this.user,
    this.functions,
    this.functionCall,
    this.tools,
    this.toolChoice,
    this.responseFormat,
    this.seed,
    this.logitBias,
    this.logprobs,
    this.topLogprobs,
  });

  factory OpenAIChatCompletionRequest.fromJson(Map<String, dynamic> json) =>
      _$OpenAIChatCompletionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIChatCompletionRequestToJson(this);

  // 移除null值的属性
  Map<String, dynamic> toRequestBody({UnifiedPlatformSpec? platform}) {
    if (platform?.id == UnifiedPlatformId.zhipu.name) {
      return toZhipuBody();
    }
    if (platform?.id == UnifiedPlatformId.siliconCloud.name) {
      return toSiliconCloudBody();
    }
    if (platform?.id == UnifiedPlatformId.volcengine.name) {
      return toVolcengineBody();
    }

    final json = toJson();
    json.removeWhere((key, value) => value == null);

    // 如果有单独omni的参数，进行构建
    if (omniParams != null) {
      json['modalities'] = omniParams?['modalities'];
      if ((omniParams?['modalities'] as List?)?.contains('audio') ?? false) {
        json['audio'] = omniParams?['audio'];
      }
      // 拆分了omniParams后，这里要移除这个属性
      json.remove('omni_params');
    }

    // 测试：移除不支持的参数
    json.remove('frequency_penalty');
    json.remove('presence_penalty');

    // TEST: 移除不支持的参数
    // json.remove('tool_choice');
    // json.remove('stream');
    // json.remove('stream_options');
    // json.remove('enable_thinking');
    // json.remove('max_tokens');
    // json.remove('top_p');
    // json.remove('temperature');

    return json;
  }

  // 智谱平台的对话好像有些参数不支持，设置了会报错而不是被忽略
  Map<String, dynamic> toZhipuBody() {
    final json = toJson();
    json.removeWhere((key, value) => value == null);

    // 移除不支持的参数
    json.remove('frequency_penalty');
    json.remove('presence_penalty');
    json.remove('stream_options');

    // 获得thinking参数
    final enableThinking = json['enable_thinking'];
    if (enableThinking != null) {
      json['thinking'] = {'type': enableThinking ? 'enabled' : 'disabled'};
      json.remove('enable_thinking');
    }

    return json;
  }

  // 实测，类似GLM-4-9B-0414等不支持enable_thinking参数的模型设置了会报错
  Map<String, dynamic> toSiliconCloudBody() {
    final json = toJson();
    json.removeWhere((key, value) => value == null);

    // 测试：移除不支持的参数
    json.remove('frequency_penalty');
    json.remove('presence_penalty');

    // 2025-09-26 如果不是这些关键字的模型，不要添加enable_thinking参数，否则调用会报错
    List<String> removedModelKeywords = [
      'qwen3',
      'hunyuan-a13b-instruct',
      'glm-4.5v',
      'deepseek-v3.1',
    ];
    if (!removedModelKeywords.any(
      (keyword) => model.toLowerCase().contains(keyword),
    )) {
      json.remove('enable_thinking');
    }
    return json;
  }

  // 智谱平台的对话好像有些参数不支持，设置了会报错而不是被忽略
  Map<String, dynamic> toVolcengineBody() {
    final json = toJson();
    json.removeWhere((key, value) => value == null);

    // 获得thinking参数
    final enableThinking = json['enable_thinking'];
    if (enableThinking != null) {
      json['thinking'] = {'type': enableThinking ? 'enabled' : 'disabled'};
      json.remove('enable_thinking');
    }

    return json;
  }

  factory OpenAIChatCompletionRequest.fromMessages({
    required String model,
    required List<UnifiedChatMessage> messages,
    double? temperature,
    int? maxTokens,
    double? topP,
    double? frequencyPenalty,
    double? presencePenalty,
    bool stream = false,
    bool enableThinking = false,
    Map<String, dynamic>? omniParams,
    List<String>? stop,
    String? user,
    List<OpenAIFunction>? functions,
    dynamic functionCall,
    List<OpenAITool>? tools,
    dynamic toolChoice,
    OpenAIResponseFormat? responseFormat,
    String? platformId,
  }) {
    // 根据平台ID调整参数
    final adjustedMessages = _adjustMessagesForPlatform(messages, platformId);
    final adjustedModel = _adjustModelForPlatform(model, platformId);

    return OpenAIChatCompletionRequest(
      model: adjustedModel,
      messages: adjustedMessages,
      temperature: temperature,
      maxTokens: maxTokens,
      topP: topP,
      frequencyPenalty: frequencyPenalty,
      presencePenalty: presencePenalty,
      stream: stream,
      streamOptions: stream
          ? const OpenAIStreamOptions(includeUsage: true)
          : null,
      enableThinking: enableThinking,
      omniParams: omniParams,
      stop: stop,
      user: user,
      functions: functions,
      functionCall: functionCall,
      tools: tools,
      toolChoice: toolChoice,
      responseFormat: responseFormat,
    );
  }

  /// 根据平台调整消息格式
  static List<Map<String, dynamic>> _adjustMessagesForPlatform(
    List<UnifiedChatMessage> messages,
    String? platformId,
  ) {
    final baseMessages = messages.map((msg) => msg.toOpenAIFormat()).toList();

    if (platformId == null) return baseMessages;

    // TODO: 20251013这些还没用到
    switch (platformId.toLowerCase()) {
      case 'claude':
      case 'anthropic':
        // Claude平台的特殊处理
        return _adjustForClaude(baseMessages);
      case 'gemini':
      case 'google':
        // Gemini平台的特殊处理
        return _adjustForGemini(baseMessages);

      default:
        return baseMessages;
    }
  }

  /// 根据平台调整模型名称
  static String _adjustModelForPlatform(String model, String? platformId) {
    if (platformId == null) return model;

    // 某些平台可能需要特定的模型名称格式
    switch (platformId.toLowerCase()) {
      case 'claude':
      case 'anthropic':
        // Claude模型名称通常需要完整版本号
        if (!model.contains('claude-3') && model.startsWith('claude')) {
          return 'claude-3-sonnet-20240229';
        }
        return model;
      default:
        return model;
    }
  }

  /// Claude平台消息格式调整
  static List<Map<String, dynamic>> _adjustForClaude(
    List<Map<String, dynamic>> messages,
  ) {
    // Claude对system消息的处理可能不同
    return messages.map((msg) {
      if (msg['role'] == 'system') {
        // Claude可能需要将system消息转换为user消息
        return {'role': 'user', 'content': '[System]: ${msg['content']}'};
      }
      return msg;
    }).toList();
  }

  /// Gemini平台消息格式调整
  static List<Map<String, dynamic>> _adjustForGemini(
    List<Map<String, dynamic>> messages,
  ) {
    // Gemini使用不同的角色名称
    return messages.map((msg) {
      final role = msg['role'];
      switch (role) {
        case 'assistant':
          return {...msg, 'role': 'model'};
        case 'system':
          // Gemini可能需要特殊处理system消息
          return {'role': 'user', 'content': msg['content']};
        default:
          return msg;
      }
    }).toList();
  }
}

/// 流式选项
@JsonSerializable(explicitToJson: true)
class OpenAIStreamOptions {
  @JsonKey(name: 'include_usage')
  final bool includeUsage;

  const OpenAIStreamOptions({this.includeUsage = false});

  factory OpenAIStreamOptions.fromJson(Map<String, dynamic> json) =>
      _$OpenAIStreamOptionsFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIStreamOptionsToJson(this);
}

/// 函数定义
@JsonSerializable(explicitToJson: true)
class OpenAIFunction {
  final String name;
  final String? description;
  final Map<String, dynamic> parameters;

  const OpenAIFunction({
    required this.name,
    this.description,
    required this.parameters,
  });

  factory OpenAIFunction.fromJson(Map<String, dynamic> json) =>
      _$OpenAIFunctionFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIFunctionToJson(this);
}

/// 工具定义
@JsonSerializable(explicitToJson: true)
class OpenAITool {
  final String type;
  final OpenAIFunction function;

  const OpenAITool({required this.type, required this.function});

  factory OpenAITool.fromJson(Map<String, dynamic> json) =>
      _$OpenAIToolFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIToolToJson(this);

  factory OpenAITool.function(OpenAIFunction function) {
    return OpenAITool(type: 'function', function: function);
  }
}

/// 响应格式
@JsonSerializable(explicitToJson: true)
class OpenAIResponseFormat {
  final String type;
  @JsonKey(name: 'json_schema')
  final OpenAIJsonSchema? jsonSchema;

  const OpenAIResponseFormat({required this.type, this.jsonSchema});

  factory OpenAIResponseFormat.fromJson(Map<String, dynamic> json) =>
      _$OpenAIResponseFormatFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIResponseFormatToJson(this);

  factory OpenAIResponseFormat.text() {
    return const OpenAIResponseFormat(type: 'text');
  }

  factory OpenAIResponseFormat.jsonObject() {
    return const OpenAIResponseFormat(type: 'json_object');
  }

  factory OpenAIResponseFormat.jsonSchema(OpenAIJsonSchema schema) {
    return OpenAIResponseFormat(type: 'json_schema', jsonSchema: schema);
  }
}

/// JSON Schema定义
@JsonSerializable(explicitToJson: true)
class OpenAIJsonSchema {
  final String name;
  final String? description;
  final Map<String, dynamic> schema;
  final bool? strict;

  const OpenAIJsonSchema({
    required this.name,
    this.description,
    required this.schema,
    this.strict,
  });

  factory OpenAIJsonSchema.fromJson(Map<String, dynamic> json) =>
      _$OpenAIJsonSchemaFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIJsonSchemaToJson(this);
}

/// 模型列表请求
@JsonSerializable(explicitToJson: true)
class OpenAIModelsRequest {
  const OpenAIModelsRequest();

  factory OpenAIModelsRequest.fromJson(Map<String, dynamic> json) =>
      _$OpenAIModelsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIModelsRequestToJson(this);
}

/// 嵌入请求
@JsonSerializable(explicitToJson: true)
class OpenAIEmbeddingRequest {
  final String model;
  final dynamic input; // string or array of strings
  @JsonKey(name: 'encoding_format')
  final String? encodingFormat;
  final int? dimensions;
  final String? user;

  const OpenAIEmbeddingRequest({
    required this.model,
    required this.input,
    this.encodingFormat,
    this.dimensions,
    this.user,
  });

  factory OpenAIEmbeddingRequest.fromJson(Map<String, dynamic> json) =>
      _$OpenAIEmbeddingRequestFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIEmbeddingRequestToJson(this);
}

/// 图片生成请求
@JsonSerializable(explicitToJson: true)
class OpenAIImageGenerationRequest {
  final String prompt;
  final String? model;
  final int? n;
  final String? quality;
  @JsonKey(name: 'response_format')
  final String? responseFormat;
  final String? size;
  final String? style;
  final String? user;

  const OpenAIImageGenerationRequest({
    required this.prompt,
    this.model,
    this.n,
    this.quality,
    this.responseFormat,
    this.size,
    this.style,
    this.user,
  });

  factory OpenAIImageGenerationRequest.fromJson(Map<String, dynamic> json) =>
      _$OpenAIImageGenerationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIImageGenerationRequestToJson(this);
}

/// 语音转文字请求
@JsonSerializable(explicitToJson: true)
class OpenAITranscriptionRequest {
  final String file; // 文件路径或base64
  final String model;
  final String? language;
  final String? prompt;
  @JsonKey(name: 'response_format')
  final String? responseFormat;
  final double? temperature;
  @JsonKey(name: 'timestamp_granularities')
  final List<String>? timestampGranularities;

  const OpenAITranscriptionRequest({
    required this.file,
    required this.model,
    this.language,
    this.prompt,
    this.responseFormat,
    this.temperature,
    this.timestampGranularities,
  });

  factory OpenAITranscriptionRequest.fromJson(Map<String, dynamic> json) =>
      _$OpenAITranscriptionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAITranscriptionRequestToJson(this);
}

/// 文字转语音请求
@JsonSerializable(explicitToJson: true)
class OpenAITextToSpeechRequest {
  final String model;
  final String input;
  final String voice;
  @JsonKey(name: 'response_format')
  final String? responseFormat;
  final double? speed;

  const OpenAITextToSpeechRequest({
    required this.model,
    required this.input,
    required this.voice,
    this.responseFormat,
    this.speed,
  });

  factory OpenAITextToSpeechRequest.fromJson(Map<String, dynamic> json) =>
      _$OpenAITextToSpeechRequestFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAITextToSpeechRequestToJson(this);
}
