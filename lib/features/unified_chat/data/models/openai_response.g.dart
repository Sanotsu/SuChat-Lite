// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'openai_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OpenAIChatCompletionResponse _$OpenAIChatCompletionResponseFromJson(
  Map<String, dynamic> json,
) => OpenAIChatCompletionResponse(
  id: json['id'] as String,
  object: json['object'] as String?,
  created: (json['created'] as num?)?.toInt(),
  model: json['model'] as String?,
  systemFingerprint: json['system_fingerprint'] as String?,
  choices: (json['choices'] as List<dynamic>)
      .map((e) => OpenAIChoice.fromJson(e as Map<String, dynamic>))
      .toList(),
  usage: json['usage'] == null
      ? null
      : OpenAIUsage.fromJson(json['usage'] as Map<String, dynamic>),
  customText: json['customText'] as String?,
);

Map<String, dynamic> _$OpenAIChatCompletionResponseToJson(
  OpenAIChatCompletionResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'object': instance.object,
  'created': instance.created,
  'model': instance.model,
  'system_fingerprint': instance.systemFingerprint,
  'choices': instance.choices.map((e) => e.toJson()).toList(),
  'usage': instance.usage?.toJson(),
  'customText': instance.customText,
};

OpenAIChoice _$OpenAIChoiceFromJson(Map<String, dynamic> json) => OpenAIChoice(
  index: (json['index'] as num).toInt(),
  message: json['message'] == null
      ? null
      : OpenAIMessage.fromJson(json['message'] as Map<String, dynamic>),
  delta: json['delta'] == null
      ? null
      : OpenAIMessage.fromJson(json['delta'] as Map<String, dynamic>),
  finishReason: json['finish_reason'] as String?,
  logprobs: json['logprobs'] == null
      ? null
      : OpenAILogprobs.fromJson(json['logprobs'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OpenAIChoiceToJson(OpenAIChoice instance) =>
    <String, dynamic>{
      'index': instance.index,
      'message': instance.message?.toJson(),
      'delta': instance.delta?.toJson(),
      'finish_reason': instance.finishReason,
      'logprobs': instance.logprobs?.toJson(),
    };

OpenAIMessage _$OpenAIMessageFromJson(Map<String, dynamic> json) =>
    OpenAIMessage(
      role: json['role'] as String?,
      content: json['content'] as String?,
      reasoningContent: json['reasoning_content'] as String?,
      audio: json['audio'] as Map<String, dynamic>?,
      functionCall: json['function_call'] == null
          ? null
          : OpenAIFunctionCall.fromJson(
              json['function_call'] as Map<String, dynamic>,
            ),
      toolCalls: (json['tool_calls'] as List<dynamic>?)
          ?.map((e) => OpenAIToolCall.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OpenAIMessageToJson(OpenAIMessage instance) =>
    <String, dynamic>{
      'role': instance.role,
      'content': instance.content,
      'reasoning_content': instance.reasoningContent,
      'audio': instance.audio,
      'function_call': instance.functionCall?.toJson(),
      'tool_calls': instance.toolCalls?.map((e) => e.toJson()).toList(),
    };

OmniAudio _$OmniAudioFromJson(Map<String, dynamic> json) =>
    OmniAudio(OmniAudioData.fromJson(json['audio'] as Map<String, dynamic>));

Map<String, dynamic> _$OmniAudioToJson(OmniAudio instance) => <String, dynamic>{
  'audio': instance.audio.toJson(),
};

OmniAudioData _$OmniAudioDataFromJson(Map<String, dynamic> json) =>
    OmniAudioData(
      json['data'] as String,
      (json['expires_at'] as num).toInt(),
      json['id'] as String,
    );

Map<String, dynamic> _$OmniAudioDataToJson(OmniAudioData instance) =>
    <String, dynamic>{
      'data': instance.data,
      'expires_at': instance.expiresAt,
      'id': instance.id,
    };

OpenAIFunctionCall _$OpenAIFunctionCallFromJson(Map<String, dynamic> json) =>
    OpenAIFunctionCall(
      name: json['name'] as String?,
      arguments: json['arguments'] as String?,
    );

Map<String, dynamic> _$OpenAIFunctionCallToJson(OpenAIFunctionCall instance) =>
    <String, dynamic>{'name': instance.name, 'arguments': instance.arguments};

OpenAIFunctionCallDelta _$OpenAIFunctionCallDeltaFromJson(
  Map<String, dynamic> json,
) => OpenAIFunctionCallDelta(
  name: json['name'] as String?,
  arguments: json['arguments'] as String?,
);

Map<String, dynamic> _$OpenAIFunctionCallDeltaToJson(
  OpenAIFunctionCallDelta instance,
) => <String, dynamic>{'name': instance.name, 'arguments': instance.arguments};

OpenAIToolCall _$OpenAIToolCallFromJson(Map<String, dynamic> json) =>
    OpenAIToolCall(
      index: (json['index'] as num?)?.toInt(),
      id: json['id'] as String?,
      type: json['type'] as String?,
      function: json['function'] == null
          ? null
          : OpenAIFunctionCall.fromJson(
              json['function'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$OpenAIToolCallToJson(OpenAIToolCall instance) =>
    <String, dynamic>{
      'index': instance.index,
      'id': instance.id,
      'type': instance.type,
      'function': instance.function?.toJson(),
    };

OpenAIToolCallDelta _$OpenAIToolCallDeltaFromJson(Map<String, dynamic> json) =>
    OpenAIToolCallDelta(
      index: (json['index'] as num).toInt(),
      id: json['id'] as String?,
      type: json['type'] as String?,
      function: json['function'] == null
          ? null
          : OpenAIFunctionCallDelta.fromJson(
              json['function'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$OpenAIToolCallDeltaToJson(
  OpenAIToolCallDelta instance,
) => <String, dynamic>{
  'index': instance.index,
  'id': instance.id,
  'type': instance.type,
  'function': instance.function?.toJson(),
};

OpenAIUsage _$OpenAIUsageFromJson(Map<String, dynamic> json) => OpenAIUsage(
  promptTokens: (json['prompt_tokens'] as num).toInt(),
  completionTokens: (json['completion_tokens'] as num).toInt(),
  totalTokens: (json['total_tokens'] as num).toInt(),
  promptTokensDetails: json['prompt_tokens_details'] == null
      ? null
      : OpenAIPromptTokensDetails.fromJson(
          json['prompt_tokens_details'] as Map<String, dynamic>,
        ),
  completionTokensDetails: json['completion_tokens_details'] == null
      ? null
      : OpenAICompletionTokensDetails.fromJson(
          json['completion_tokens_details'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$OpenAIUsageToJson(OpenAIUsage instance) =>
    <String, dynamic>{
      'prompt_tokens': instance.promptTokens,
      'completion_tokens': instance.completionTokens,
      'total_tokens': instance.totalTokens,
      'prompt_tokens_details': instance.promptTokensDetails?.toJson(),
      'completion_tokens_details': instance.completionTokensDetails?.toJson(),
    };

OpenAIPromptTokensDetails _$OpenAIPromptTokensDetailsFromJson(
  Map<String, dynamic> json,
) => OpenAIPromptTokensDetails(
  cachedTokens: (json['cached_tokens'] as num?)?.toInt(),
);

Map<String, dynamic> _$OpenAIPromptTokensDetailsToJson(
  OpenAIPromptTokensDetails instance,
) => <String, dynamic>{'cached_tokens': instance.cachedTokens};

OpenAICompletionTokensDetails _$OpenAICompletionTokensDetailsFromJson(
  Map<String, dynamic> json,
) => OpenAICompletionTokensDetails(
  reasoningTokens: (json['reasoning_tokens'] as num?)?.toInt(),
);

Map<String, dynamic> _$OpenAICompletionTokensDetailsToJson(
  OpenAICompletionTokensDetails instance,
) => <String, dynamic>{'reasoning_tokens': instance.reasoningTokens};

OpenAILogprobs _$OpenAILogprobsFromJson(Map<String, dynamic> json) =>
    OpenAILogprobs(
      content: (json['content'] as List<dynamic>?)
          ?.map((e) => OpenAITokenLogprob.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OpenAILogprobsToJson(OpenAILogprobs instance) =>
    <String, dynamic>{
      'content': instance.content?.map((e) => e.toJson()).toList(),
    };

OpenAITokenLogprob _$OpenAITokenLogprobFromJson(Map<String, dynamic> json) =>
    OpenAITokenLogprob(
      token: json['token'] as String,
      logprob: (json['logprob'] as num).toDouble(),
      bytes: (json['bytes'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      topLogprobs: (json['top_logprobs'] as List<dynamic>?)
          ?.map((e) => OpenAITopLogprob.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OpenAITokenLogprobToJson(OpenAITokenLogprob instance) =>
    <String, dynamic>{
      'token': instance.token,
      'logprob': instance.logprob,
      'bytes': instance.bytes,
      'top_logprobs': instance.topLogprobs?.map((e) => e.toJson()).toList(),
    };

OpenAITopLogprob _$OpenAITopLogprobFromJson(Map<String, dynamic> json) =>
    OpenAITopLogprob(
      token: json['token'] as String,
      logprob: (json['logprob'] as num).toDouble(),
      bytes: (json['bytes'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$OpenAITopLogprobToJson(OpenAITopLogprob instance) =>
    <String, dynamic>{
      'token': instance.token,
      'logprob': instance.logprob,
      'bytes': instance.bytes,
    };

OpenAIModel _$OpenAIModelFromJson(Map<String, dynamic> json) => OpenAIModel(
  id: json['id'] as String,
  object: json['object'] as String,
  created: (json['created'] as num).toInt(),
  ownedBy: json['owned_by'] as String,
);

Map<String, dynamic> _$OpenAIModelToJson(OpenAIModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'object': instance.object,
      'created': instance.created,
      'owned_by': instance.ownedBy,
    };

OpenAIModelsResponse _$OpenAIModelsResponseFromJson(
  Map<String, dynamic> json,
) => OpenAIModelsResponse(
  object: json['object'] as String,
  data: (json['data'] as List<dynamic>)
      .map((e) => OpenAIModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$OpenAIModelsResponseToJson(
  OpenAIModelsResponse instance,
) => <String, dynamic>{
  'object': instance.object,
  'data': instance.data.map((e) => e.toJson()).toList(),
};

OpenAIEmbeddingData _$OpenAIEmbeddingDataFromJson(Map<String, dynamic> json) =>
    OpenAIEmbeddingData(
      object: json['object'] as String,
      embedding: (json['embedding'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      index: (json['index'] as num).toInt(),
    );

Map<String, dynamic> _$OpenAIEmbeddingDataToJson(
  OpenAIEmbeddingData instance,
) => <String, dynamic>{
  'object': instance.object,
  'embedding': instance.embedding,
  'index': instance.index,
};

OpenAIEmbeddingResponse _$OpenAIEmbeddingResponseFromJson(
  Map<String, dynamic> json,
) => OpenAIEmbeddingResponse(
  object: json['object'] as String,
  data: (json['data'] as List<dynamic>)
      .map((e) => OpenAIEmbeddingData.fromJson(e as Map<String, dynamic>))
      .toList(),
  model: json['model'] as String,
  usage: OpenAIUsage.fromJson(json['usage'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OpenAIEmbeddingResponseToJson(
  OpenAIEmbeddingResponse instance,
) => <String, dynamic>{
  'object': instance.object,
  'data': instance.data.map((e) => e.toJson()).toList(),
  'model': instance.model,
  'usage': instance.usage.toJson(),
};

OpenAIImageData _$OpenAIImageDataFromJson(Map<String, dynamic> json) =>
    OpenAIImageData(
      url: json['url'] as String?,
      b64Json: json['b64_json'] as String?,
      revisedPrompt: json['revised_prompt'] as String?,
    );

Map<String, dynamic> _$OpenAIImageDataToJson(OpenAIImageData instance) =>
    <String, dynamic>{
      'url': instance.url,
      'b64_json': instance.b64Json,
      'revised_prompt': instance.revisedPrompt,
    };

OpenAIImageGenerationResponse _$OpenAIImageGenerationResponseFromJson(
  Map<String, dynamic> json,
) => OpenAIImageGenerationResponse(
  created: (json['created'] as num).toInt(),
  data: (json['data'] as List<dynamic>)
      .map((e) => OpenAIImageData.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$OpenAIImageGenerationResponseToJson(
  OpenAIImageGenerationResponse instance,
) => <String, dynamic>{
  'created': instance.created,
  'data': instance.data.map((e) => e.toJson()).toList(),
};

OpenAITranscriptionResponse _$OpenAITranscriptionResponseFromJson(
  Map<String, dynamic> json,
) => OpenAITranscriptionResponse(
  text: json['text'] as String,
  task: json['task'] as String?,
  language: json['language'] as String?,
  duration: (json['duration'] as num?)?.toDouble(),
  segments: (json['segments'] as List<dynamic>?)
      ?.map(
        (e) => OpenAITranscriptionSegment.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  words: (json['words'] as List<dynamic>?)
      ?.map((e) => OpenAITranscriptionWord.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$OpenAITranscriptionResponseToJson(
  OpenAITranscriptionResponse instance,
) => <String, dynamic>{
  'text': instance.text,
  'task': instance.task,
  'language': instance.language,
  'duration': instance.duration,
  'segments': instance.segments?.map((e) => e.toJson()).toList(),
  'words': instance.words?.map((e) => e.toJson()).toList(),
};

OpenAITranscriptionSegment _$OpenAITranscriptionSegmentFromJson(
  Map<String, dynamic> json,
) => OpenAITranscriptionSegment(
  id: (json['id'] as num).toInt(),
  seek: (json['seek'] as num).toInt(),
  start: (json['start'] as num).toDouble(),
  end: (json['end'] as num).toDouble(),
  text: json['text'] as String,
  tokens: (json['tokens'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  temperature: (json['temperature'] as num).toDouble(),
  avgLogprob: (json['avg_logprob'] as num).toDouble(),
  compressionRatio: (json['compression_ratio'] as num).toDouble(),
  noSpeechProb: (json['no_speech_prob'] as num).toDouble(),
);

Map<String, dynamic> _$OpenAITranscriptionSegmentToJson(
  OpenAITranscriptionSegment instance,
) => <String, dynamic>{
  'id': instance.id,
  'seek': instance.seek,
  'start': instance.start,
  'end': instance.end,
  'text': instance.text,
  'tokens': instance.tokens,
  'temperature': instance.temperature,
  'avg_logprob': instance.avgLogprob,
  'compression_ratio': instance.compressionRatio,
  'no_speech_prob': instance.noSpeechProb,
};

OpenAITranscriptionWord _$OpenAITranscriptionWordFromJson(
  Map<String, dynamic> json,
) => OpenAITranscriptionWord(
  word: json['word'] as String,
  start: (json['start'] as num).toDouble(),
  end: (json['end'] as num).toDouble(),
);

Map<String, dynamic> _$OpenAITranscriptionWordToJson(
  OpenAITranscriptionWord instance,
) => <String, dynamic>{
  'word': instance.word,
  'start': instance.start,
  'end': instance.end,
};

OpenAIErrorResponse _$OpenAIErrorResponseFromJson(Map<String, dynamic> json) =>
    OpenAIErrorResponse(
      error: OpenAIError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OpenAIErrorResponseToJson(
  OpenAIErrorResponse instance,
) => <String, dynamic>{'error': instance.error.toJson()};

OpenAIError _$OpenAIErrorFromJson(Map<String, dynamic> json) => OpenAIError(
  message: json['message'] as String,
  type: json['type'] as String,
  param: json['param'] as String?,
  code: json['code'] as String?,
);

Map<String, dynamic> _$OpenAIErrorToJson(OpenAIError instance) =>
    <String, dynamic>{
      'message': instance.message,
      'type': instance.type,
      'param': instance.param,
      'code': instance.code,
    };
