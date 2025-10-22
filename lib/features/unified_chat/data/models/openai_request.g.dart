// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'openai_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OpenAIChatCompletionRequest _$OpenAIChatCompletionRequestFromJson(
  Map<String, dynamic> json,
) => OpenAIChatCompletionRequest(
  model: json['model'] as String,
  messages: (json['messages'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
  temperature: (json['temperature'] as num?)?.toDouble(),
  maxTokens: (json['max_tokens'] as num?)?.toInt(),
  topP: (json['top_p'] as num?)?.toDouble(),
  frequencyPenalty: (json['frequency_penalty'] as num?)?.toDouble(),
  presencePenalty: (json['presence_penalty'] as num?)?.toDouble(),
  stream: json['stream'] as bool?,
  streamOptions: json['stream_options'] == null
      ? null
      : OpenAIStreamOptions.fromJson(
          json['stream_options'] as Map<String, dynamic>,
        ),
  enableThinking: json['enable_thinking'] as bool? ?? false,
  omniParams: json['omni_params'] as Map<String, dynamic>?,
  stop: (json['stop'] as List<dynamic>?)?.map((e) => e as String).toList(),
  n: (json['n'] as num?)?.toInt(),
  user: json['user'] as String?,
  functions: (json['functions'] as List<dynamic>?)
      ?.map((e) => OpenAIFunction.fromJson(e as Map<String, dynamic>))
      .toList(),
  functionCall: json['function_call'],
  tools: (json['tools'] as List<dynamic>?)
      ?.map((e) => OpenAITool.fromJson(e as Map<String, dynamic>))
      .toList(),
  toolChoice: json['tool_choice'],
  responseFormat: json['response_format'] == null
      ? null
      : OpenAIResponseFormat.fromJson(
          json['response_format'] as Map<String, dynamic>,
        ),
  seed: (json['seed'] as num?)?.toInt(),
  logitBias: (json['logit_bias'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, (e as num).toInt()),
  ),
  logprobs: json['logprobs'] as bool?,
  topLogprobs: (json['top_logprobs'] as num?)?.toInt(),
);

Map<String, dynamic> _$OpenAIChatCompletionRequestToJson(
  OpenAIChatCompletionRequest instance,
) => <String, dynamic>{
  'model': instance.model,
  'messages': instance.messages,
  'temperature': instance.temperature,
  'max_tokens': instance.maxTokens,
  'top_p': instance.topP,
  'frequency_penalty': instance.frequencyPenalty,
  'presence_penalty': instance.presencePenalty,
  'stream': instance.stream,
  'stream_options': instance.streamOptions?.toJson(),
  'enable_thinking': instance.enableThinking,
  'omni_params': instance.omniParams,
  'stop': instance.stop,
  'n': instance.n,
  'user': instance.user,
  'functions': instance.functions?.map((e) => e.toJson()).toList(),
  'function_call': instance.functionCall,
  'tools': instance.tools?.map((e) => e.toJson()).toList(),
  'tool_choice': instance.toolChoice,
  'response_format': instance.responseFormat?.toJson(),
  'seed': instance.seed,
  'logit_bias': instance.logitBias,
  'logprobs': instance.logprobs,
  'top_logprobs': instance.topLogprobs,
};

OpenAIStreamOptions _$OpenAIStreamOptionsFromJson(Map<String, dynamic> json) =>
    OpenAIStreamOptions(includeUsage: json['include_usage'] as bool? ?? false);

Map<String, dynamic> _$OpenAIStreamOptionsToJson(
  OpenAIStreamOptions instance,
) => <String, dynamic>{'include_usage': instance.includeUsage};

OpenAIFunction _$OpenAIFunctionFromJson(Map<String, dynamic> json) =>
    OpenAIFunction(
      name: json['name'] as String,
      description: json['description'] as String?,
      parameters: json['parameters'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$OpenAIFunctionToJson(OpenAIFunction instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'parameters': instance.parameters,
    };

OpenAITool _$OpenAIToolFromJson(Map<String, dynamic> json) => OpenAITool(
  type: json['type'] as String,
  function: OpenAIFunction.fromJson(json['function'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OpenAIToolToJson(OpenAITool instance) =>
    <String, dynamic>{
      'type': instance.type,
      'function': instance.function.toJson(),
    };

OpenAIResponseFormat _$OpenAIResponseFormatFromJson(
  Map<String, dynamic> json,
) => OpenAIResponseFormat(
  type: json['type'] as String,
  jsonSchema: json['json_schema'] == null
      ? null
      : OpenAIJsonSchema.fromJson(json['json_schema'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OpenAIResponseFormatToJson(
  OpenAIResponseFormat instance,
) => <String, dynamic>{
  'type': instance.type,
  'json_schema': instance.jsonSchema?.toJson(),
};

OpenAIJsonSchema _$OpenAIJsonSchemaFromJson(Map<String, dynamic> json) =>
    OpenAIJsonSchema(
      name: json['name'] as String,
      description: json['description'] as String?,
      schema: json['schema'] as Map<String, dynamic>,
      strict: json['strict'] as bool?,
    );

Map<String, dynamic> _$OpenAIJsonSchemaToJson(OpenAIJsonSchema instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'schema': instance.schema,
      'strict': instance.strict,
    };

OpenAIModelsRequest _$OpenAIModelsRequestFromJson(Map<String, dynamic> json) =>
    OpenAIModelsRequest();

Map<String, dynamic> _$OpenAIModelsRequestToJson(
  OpenAIModelsRequest instance,
) => <String, dynamic>{};

OpenAIEmbeddingRequest _$OpenAIEmbeddingRequestFromJson(
  Map<String, dynamic> json,
) => OpenAIEmbeddingRequest(
  model: json['model'] as String,
  input: json['input'],
  encodingFormat: json['encoding_format'] as String?,
  dimensions: (json['dimensions'] as num?)?.toInt(),
  user: json['user'] as String?,
);

Map<String, dynamic> _$OpenAIEmbeddingRequestToJson(
  OpenAIEmbeddingRequest instance,
) => <String, dynamic>{
  'model': instance.model,
  'input': instance.input,
  'encoding_format': instance.encodingFormat,
  'dimensions': instance.dimensions,
  'user': instance.user,
};

OpenAIImageGenerationRequest _$OpenAIImageGenerationRequestFromJson(
  Map<String, dynamic> json,
) => OpenAIImageGenerationRequest(
  prompt: json['prompt'] as String,
  model: json['model'] as String?,
  n: (json['n'] as num?)?.toInt(),
  quality: json['quality'] as String?,
  responseFormat: json['response_format'] as String?,
  size: json['size'] as String?,
  style: json['style'] as String?,
  user: json['user'] as String?,
);

Map<String, dynamic> _$OpenAIImageGenerationRequestToJson(
  OpenAIImageGenerationRequest instance,
) => <String, dynamic>{
  'prompt': instance.prompt,
  'model': instance.model,
  'n': instance.n,
  'quality': instance.quality,
  'response_format': instance.responseFormat,
  'size': instance.size,
  'style': instance.style,
  'user': instance.user,
};

OpenAITranscriptionRequest _$OpenAITranscriptionRequestFromJson(
  Map<String, dynamic> json,
) => OpenAITranscriptionRequest(
  file: json['file'] as String,
  model: json['model'] as String,
  language: json['language'] as String?,
  prompt: json['prompt'] as String?,
  responseFormat: json['response_format'] as String?,
  temperature: (json['temperature'] as num?)?.toDouble(),
  timestampGranularities: (json['timestamp_granularities'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$OpenAITranscriptionRequestToJson(
  OpenAITranscriptionRequest instance,
) => <String, dynamic>{
  'file': instance.file,
  'model': instance.model,
  'language': instance.language,
  'prompt': instance.prompt,
  'response_format': instance.responseFormat,
  'temperature': instance.temperature,
  'timestamp_granularities': instance.timestampGranularities,
};

OpenAITextToSpeechRequest _$OpenAITextToSpeechRequestFromJson(
  Map<String, dynamic> json,
) => OpenAITextToSpeechRequest(
  model: json['model'] as String,
  input: json['input'] as String,
  voice: json['voice'] as String,
  responseFormat: json['response_format'] as String?,
  speed: (json['speed'] as num?)?.toDouble(),
);

Map<String, dynamic> _$OpenAITextToSpeechRequestToJson(
  OpenAITextToSpeechRequest instance,
) => <String, dynamic>{
  'model': instance.model,
  'input': instance.input,
  'voice': instance.voice,
  'response_format': instance.responseFormat,
  'speed': instance.speed,
};
