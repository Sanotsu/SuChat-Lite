import 'package:json_annotation/json_annotation.dart';

part 'openai_response.g.dart';

/// OpenAI聊天完成响应
/// 流式非流式的通用响应，不单独拆分，减少逻辑
@JsonSerializable(explicitToJson: true)
class OpenAIChatCompletionResponse {
  final String id;
  final String? object;
  final int? created;
  final String? model;

  @JsonKey(name: 'system_fingerprint')
  final String? systemFingerprint;

  //流式和非流式的choices是不一样的，在内部兼容处理
  final List<OpenAIChoice> choices;

  final OpenAIUsage? usage;

  // 自定义消息栏位(直接获取message和delta中用于展示的消息内容，方便显示时直接获得)
  String customText;

  OpenAIChatCompletionResponse({
    required this.id,
    this.object,
    this.created,
    this.model,
    this.systemFingerprint,
    required this.choices,
    this.usage,
    String? customText,
  }) : customText = customText ?? _generateCustomText(choices);

  // 自定义的响应文本(比如流式返回最后是个[DONE]没法转型，但可以自行设定；而正常响应时可以从其他值中得到)
  static String _generateCustomText(List<OpenAIChoice>? choices) {
    // 非流式的
    if (choices != null && choices.isNotEmpty && choices[0].message != null) {
      return choices[0].message!.content ?? "";
    }
    // 流式的
    if (choices != null && choices.isNotEmpty && choices[0].delta != null) {
      // TODO：2025-05-30 千问omni多模态时，请求中设置了audio属性，位置和常规不一样
      return choices[0].delta!.content ?? "";
    }

    return '';
  }

  factory OpenAIChatCompletionResponse.fromJson(Map<String, dynamic> json) =>
      _$OpenAIChatCompletionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIChatCompletionResponseToJson(this);
}

/// 选择项
@JsonSerializable(explicitToJson: true)
class OpenAIChoice {
  final int index;

  // 非流式的message
  final OpenAIMessage? message;

  // 流式的delta(只是参数不一样，内部结构一样的)
  final OpenAIMessage? delta;

  @JsonKey(name: 'finish_reason')
  final String? finishReason;

  final OpenAILogprobs? logprobs;

  const OpenAIChoice({
    required this.index,
    this.message,
    this.delta,
    this.finishReason,
    this.logprobs,
  });

  factory OpenAIChoice.fromJson(Map<String, dynamic> json) =>
      _$OpenAIChoiceFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIChoiceToJson(this);
}

/// 消息
@JsonSerializable(explicitToJson: true)
class OpenAIMessage {
  final String? role;
  final String? content;

  // deepseek等推理内容
  @JsonKey(name: 'reasoning_content')
  final String? reasoningContent;

  @JsonKey(name: 'function_call')
  final OpenAIFunctionCall? functionCall;

  @JsonKey(name: 'tool_calls')
  final List<OpenAIToolCall>? toolCalls;

  const OpenAIMessage({
    this.role,
    this.content,
    this.reasoningContent,
    this.functionCall,
    this.toolCalls,
  });

  factory OpenAIMessage.fromJson(Map<String, dynamic> json) =>
      _$OpenAIMessageFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIMessageToJson(this);
}

/// 函数调用
@JsonSerializable(explicitToJson: true)
class OpenAIFunctionCall {
  final String? name;
  final String? arguments;

  const OpenAIFunctionCall({this.name, this.arguments});

  factory OpenAIFunctionCall.fromJson(Map<String, dynamic> json) =>
      _$OpenAIFunctionCallFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIFunctionCallToJson(this);
}

/// 函数调用增量
@JsonSerializable(explicitToJson: true)
class OpenAIFunctionCallDelta {
  final String? name;
  final String? arguments;

  const OpenAIFunctionCallDelta({this.name, this.arguments});

  factory OpenAIFunctionCallDelta.fromJson(Map<String, dynamic> json) =>
      _$OpenAIFunctionCallDeltaFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIFunctionCallDeltaToJson(this);
}

/// 工具调用
@JsonSerializable(explicitToJson: true)
class OpenAIToolCall {
  final int? index;
  final String? id;
  final String? type;
  final OpenAIFunctionCall? function;

  const OpenAIToolCall({this.index, this.id, this.type, this.function});

  factory OpenAIToolCall.fromJson(Map<String, dynamic> json) =>
      _$OpenAIToolCallFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIToolCallToJson(this);
}

/// 工具调用增量
@JsonSerializable(explicitToJson: true)
class OpenAIToolCallDelta {
  final int index;
  final String? id;
  final String? type;
  final OpenAIFunctionCallDelta? function;

  const OpenAIToolCallDelta({
    required this.index,
    this.id,
    this.type,
    this.function,
  });

  factory OpenAIToolCallDelta.fromJson(Map<String, dynamic> json) =>
      _$OpenAIToolCallDeltaFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIToolCallDeltaToJson(this);
}

/// 使用统计
@JsonSerializable(explicitToJson: true)
class OpenAIUsage {
  @JsonKey(name: 'prompt_tokens')
  final int promptTokens;
  @JsonKey(name: 'completion_tokens')
  final int completionTokens;
  @JsonKey(name: 'total_tokens')
  final int totalTokens;
  @JsonKey(name: 'prompt_tokens_details')
  final OpenAIPromptTokensDetails? promptTokensDetails;
  @JsonKey(name: 'completion_tokens_details')
  final OpenAICompletionTokensDetails? completionTokensDetails;

  const OpenAIUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
    this.promptTokensDetails,
    this.completionTokensDetails,
  });

  factory OpenAIUsage.fromJson(Map<String, dynamic> json) =>
      _$OpenAIUsageFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIUsageToJson(this);
}

/// 提示词token详情
@JsonSerializable(explicitToJson: true)
class OpenAIPromptTokensDetails {
  @JsonKey(name: 'cached_tokens')
  final int? cachedTokens;

  const OpenAIPromptTokensDetails({this.cachedTokens});

  factory OpenAIPromptTokensDetails.fromJson(Map<String, dynamic> json) =>
      _$OpenAIPromptTokensDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIPromptTokensDetailsToJson(this);
}

/// 完成token详情
@JsonSerializable(explicitToJson: true)
class OpenAICompletionTokensDetails {
  @JsonKey(name: 'reasoning_tokens')
  final int? reasoningTokens;

  const OpenAICompletionTokensDetails({this.reasoningTokens});

  factory OpenAICompletionTokensDetails.fromJson(Map<String, dynamic> json) =>
      _$OpenAICompletionTokensDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAICompletionTokensDetailsToJson(this);
}

/// 日志概率
@JsonSerializable(explicitToJson: true)
class OpenAILogprobs {
  final List<OpenAITokenLogprob>? content;

  const OpenAILogprobs({this.content});

  factory OpenAILogprobs.fromJson(Map<String, dynamic> json) =>
      _$OpenAILogprobsFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAILogprobsToJson(this);
}

/// Token日志概率
@JsonSerializable(explicitToJson: true)
class OpenAITokenLogprob {
  final String token;
  final double logprob;
  final List<int>? bytes;
  @JsonKey(name: 'top_logprobs')
  final List<OpenAITopLogprob>? topLogprobs;

  const OpenAITokenLogprob({
    required this.token,
    required this.logprob,
    this.bytes,
    this.topLogprobs,
  });

  factory OpenAITokenLogprob.fromJson(Map<String, dynamic> json) =>
      _$OpenAITokenLogprobFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAITokenLogprobToJson(this);
}

/// 顶部日志概率
@JsonSerializable(explicitToJson: true)
class OpenAITopLogprob {
  final String token;
  final double logprob;
  final List<int>? bytes;

  const OpenAITopLogprob({
    required this.token,
    required this.logprob,
    this.bytes,
  });

  factory OpenAITopLogprob.fromJson(Map<String, dynamic> json) =>
      _$OpenAITopLogprobFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAITopLogprobToJson(this);
}

/// 模型信息
@JsonSerializable(explicitToJson: true)
class OpenAIModel {
  final String id;
  final String object;
  final int created;
  @JsonKey(name: 'owned_by')
  final String ownedBy;

  const OpenAIModel({
    required this.id,
    required this.object,
    required this.created,
    required this.ownedBy,
  });

  factory OpenAIModel.fromJson(Map<String, dynamic> json) =>
      _$OpenAIModelFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIModelToJson(this);
}

/// 模型列表响应
@JsonSerializable(explicitToJson: true)
class OpenAIModelsResponse {
  final String object;
  final List<OpenAIModel> data;

  const OpenAIModelsResponse({required this.object, required this.data});

  factory OpenAIModelsResponse.fromJson(Map<String, dynamic> json) =>
      _$OpenAIModelsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIModelsResponseToJson(this);
}

/// 嵌入数据
@JsonSerializable(explicitToJson: true)
class OpenAIEmbeddingData {
  final String object;
  final List<double> embedding;
  final int index;

  const OpenAIEmbeddingData({
    required this.object,
    required this.embedding,
    required this.index,
  });

  factory OpenAIEmbeddingData.fromJson(Map<String, dynamic> json) =>
      _$OpenAIEmbeddingDataFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIEmbeddingDataToJson(this);
}

/// 嵌入响应
@JsonSerializable(explicitToJson: true)
class OpenAIEmbeddingResponse {
  final String object;
  final List<OpenAIEmbeddingData> data;
  final String model;
  final OpenAIUsage usage;

  const OpenAIEmbeddingResponse({
    required this.object,
    required this.data,
    required this.model,
    required this.usage,
  });

  factory OpenAIEmbeddingResponse.fromJson(Map<String, dynamic> json) =>
      _$OpenAIEmbeddingResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIEmbeddingResponseToJson(this);
}

/// 图片数据
@JsonSerializable(explicitToJson: true)
class OpenAIImageData {
  final String? url;
  @JsonKey(name: 'b64_json')
  final String? b64Json;
  @JsonKey(name: 'revised_prompt')
  final String? revisedPrompt;

  const OpenAIImageData({this.url, this.b64Json, this.revisedPrompt});

  factory OpenAIImageData.fromJson(Map<String, dynamic> json) =>
      _$OpenAIImageDataFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIImageDataToJson(this);
}

/// 图片生成响应
@JsonSerializable(explicitToJson: true)
class OpenAIImageGenerationResponse {
  final int created;
  final List<OpenAIImageData> data;

  const OpenAIImageGenerationResponse({
    required this.created,
    required this.data,
  });

  factory OpenAIImageGenerationResponse.fromJson(Map<String, dynamic> json) =>
      _$OpenAIImageGenerationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIImageGenerationResponseToJson(this);
}

/// 转录响应
@JsonSerializable(explicitToJson: true)
class OpenAITranscriptionResponse {
  final String text;
  final String? task;
  final String? language;
  final double? duration;
  final List<OpenAITranscriptionSegment>? segments;
  final List<OpenAITranscriptionWord>? words;

  const OpenAITranscriptionResponse({
    required this.text,
    this.task,
    this.language,
    this.duration,
    this.segments,
    this.words,
  });

  factory OpenAITranscriptionResponse.fromJson(Map<String, dynamic> json) =>
      _$OpenAITranscriptionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAITranscriptionResponseToJson(this);
}

/// 转录片段
@JsonSerializable(explicitToJson: true)
class OpenAITranscriptionSegment {
  final int id;
  final int seek;
  final double start;
  final double end;
  final String text;
  final List<int> tokens;
  final double temperature;
  @JsonKey(name: 'avg_logprob')
  final double avgLogprob;
  @JsonKey(name: 'compression_ratio')
  final double compressionRatio;
  @JsonKey(name: 'no_speech_prob')
  final double noSpeechProb;

  const OpenAITranscriptionSegment({
    required this.id,
    required this.seek,
    required this.start,
    required this.end,
    required this.text,
    required this.tokens,
    required this.temperature,
    required this.avgLogprob,
    required this.compressionRatio,
    required this.noSpeechProb,
  });

  factory OpenAITranscriptionSegment.fromJson(Map<String, dynamic> json) =>
      _$OpenAITranscriptionSegmentFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAITranscriptionSegmentToJson(this);
}

/// 转录单词
@JsonSerializable(explicitToJson: true)
class OpenAITranscriptionWord {
  final String word;
  final double start;
  final double end;

  const OpenAITranscriptionWord({
    required this.word,
    required this.start,
    required this.end,
  });

  factory OpenAITranscriptionWord.fromJson(Map<String, dynamic> json) =>
      _$OpenAITranscriptionWordFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAITranscriptionWordToJson(this);
}

/// 错误响应
@JsonSerializable(explicitToJson: true)
class OpenAIErrorResponse {
  final OpenAIError error;

  const OpenAIErrorResponse({required this.error});

  factory OpenAIErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$OpenAIErrorResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIErrorResponseToJson(this);
}

/// 错误详情
@JsonSerializable(explicitToJson: true)
class OpenAIError {
  final String message;
  final String type;
  final String? param;
  final String? code;

  const OpenAIError({
    required this.message,
    required this.type,
    this.param,
    this.code,
  });

  factory OpenAIError.fromJson(Map<String, dynamic> json) =>
      _$OpenAIErrorFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAIErrorToJson(this);
}
