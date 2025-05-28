import 'package:json_annotation/json_annotation.dart';

part 'qwen_tts_resp.g.dart';

@JsonSerializable(explicitToJson: true)
class QwenTTSResp {
  @JsonKey(name: 'output')
  QwenTTSOutput output;

  @JsonKey(name: 'usage')
  QwenTTSUsage usage;

  @JsonKey(name: 'request_id')
  String requestId;

  QwenTTSResp(this.output, this.usage, this.requestId);

  factory QwenTTSResp.fromJson(Map<String, dynamic> srcJson) =>
      _$QwenTTSRespFromJson(srcJson);

  Map<String, dynamic> toJson() => _$QwenTTSRespToJson(this);
}

@JsonSerializable(explicitToJson: true)
class QwenTTSOutput {
  @JsonKey(name: 'finish_reason')
  String finishReason;

  @JsonKey(name: 'audio')
  QwenTTSAudio audio;

  QwenTTSOutput(this.finishReason, this.audio);

  factory QwenTTSOutput.fromJson(Map<String, dynamic> srcJson) =>
      _$QwenTTSOutputFromJson(srcJson);

  Map<String, dynamic> toJson() => _$QwenTTSOutputToJson(this);
}

@JsonSerializable(explicitToJson: true)
class QwenTTSAudio {
  @JsonKey(name: 'expires_at')
  int expiresAt;

  @JsonKey(name: 'data')
  String data;

  @JsonKey(name: 'id')
  String id;

  @JsonKey(name: 'url')
  String url;

  QwenTTSAudio(this.expiresAt, this.data, this.id, this.url);

  factory QwenTTSAudio.fromJson(Map<String, dynamic> srcJson) =>
      _$QwenTTSAudioFromJson(srcJson);

  Map<String, dynamic> toJson() => _$QwenTTSAudioToJson(this);
}

@JsonSerializable(explicitToJson: true)
class QwenTTSUsage {
  @JsonKey(name: 'input_tokens_details')
  QwenTTSInputTokensDetails inputTokensDetails;

  @JsonKey(name: 'total_tokens')
  int totalTokens;

  @JsonKey(name: 'output_tokens')
  int outputTokens;

  @JsonKey(name: 'input_tokens')
  int inputTokens;

  @JsonKey(name: 'output_tokens_details')
  QwenTTSOutputTokensDetails outputTokensDetails;

  QwenTTSUsage(
    this.inputTokensDetails,
    this.totalTokens,
    this.outputTokens,
    this.inputTokens,
    this.outputTokensDetails,
  );

  factory QwenTTSUsage.fromJson(Map<String, dynamic> srcJson) =>
      _$QwenTTSUsageFromJson(srcJson);

  Map<String, dynamic> toJson() => _$QwenTTSUsageToJson(this);
}

@JsonSerializable(explicitToJson: true)
class QwenTTSInputTokensDetails {
  @JsonKey(name: 'text_tokens')
  int textTokens;

  QwenTTSInputTokensDetails(this.textTokens);

  factory QwenTTSInputTokensDetails.fromJson(Map<String, dynamic> srcJson) =>
      _$QwenTTSInputTokensDetailsFromJson(srcJson);

  Map<String, dynamic> toJson() => _$QwenTTSInputTokensDetailsToJson(this);
}

@JsonSerializable(explicitToJson: true)
class QwenTTSOutputTokensDetails {
  @JsonKey(name: 'audio_tokens')
  int audioTokens;

  @JsonKey(name: 'text_tokens')
  int textTokens;

  QwenTTSOutputTokensDetails(this.audioTokens, this.textTokens);

  factory QwenTTSOutputTokensDetails.fromJson(Map<String, dynamic> srcJson) =>
      _$QwenTTSOutputTokensDetailsFromJson(srcJson);

  Map<String, dynamic> toJson() => _$QwenTTSOutputTokensDetailsToJson(this);
}
