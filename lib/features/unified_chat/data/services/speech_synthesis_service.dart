import 'dart:convert';

import '../../../../core/network/dio_client/cus_http_client.dart';
import '../../../../core/network/dio_client/cus_http_request.dart';
import '../models/speech_synthesis_request.dart';
import '../models/speech_synthesis_response.dart';
import '../models/unified_model_spec.dart';
import '../models/unified_platform_spec.dart';
import 'unified_secure_storage.dart';

/// 语音合成服务
class SpeechSynthesisService {
  static final SpeechSynthesisService _instance =
      SpeechSynthesisService._internal();
  factory SpeechSynthesisService() => _instance;
  SpeechSynthesisService._internal();

  /// 语音合成
  Future<SpeechSynthesisResponse> synthesizeSpeech({
    required SpeechSynthesisRequest request,
    required UnifiedPlatformSpec platform,
    required UnifiedModelSpec model,
  }) async {
    // 获取API密钥
    final apiKey = await UnifiedSecureStorage.getApiKey(platform.id);
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('未找到 ${platform.displayName} 的API密钥');
    }

    final url = platform.getTextToSpeechUrl();
    if (url == null) {
      throw Exception('平台 ${platform.displayName} 不支持语音合成');
    }

    // 根据平台转换请求格式
    Map<String, dynamic> requestBody;
    switch (platform.id) {
      case 'aliyun':
        requestBody = request.toAliyunFormat();
        break;
      case 'siliconCloud':
        requestBody = request.toSiliconCloudFormat();
        break;
      case 'zhipu':
        requestBody = request.toZhipuFormat();
        break;
      case 'mimo':
        requestBody = request.toMimoFormat();
        break;
      default:
        requestBody = request.toSiliconCloudFormat();
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    try {
      // 根据平台处理不同的响应类型
      switch (platform.id) {
        case 'aliyun':
          // 阿里百炼返回JSON格式
          final responseData = await HttpUtils.post(
            path: url,
            headers: headers,
            data: requestBody,
            showLoading: false,
          );
          return SpeechSynthesisResponse.fromAliyunResponse(responseData);

        case 'siliconCloud':
        case 'zhipu':
          // 硅基流动和智谱返回二进制音频数据
          final audioBytes = await HttpUtils.post(
            path: url,
            headers: headers,
            data: requestBody,
            responseType: CusRespType.bytes,
            showLoading: false,
          );

          return await SpeechSynthesisResponse.fromBinaryData(
            audioBytes,
            format: request.responseFormat ?? 'mp3',
            source: platform.id,
          );

        case 'mimo':
          // 2026-09-10 小米MiMo：chat completions风格，返回JSON，
          // 合成音频以base64编码在choices[0].message.audio.data
          final responseData = await HttpUtils.post(
            path: url,
            headers: headers,
            data: requestBody,
            showLoading: false,
          );

          final choices = responseData['choices'] as List<dynamic>?;
          final message = choices?.isNotEmpty == true
              ? (choices!.first as Map<String, dynamic>)['message']
                    as Map<String, dynamic>?
              : null;
          final audio = message?['audio'] as Map<String, dynamic>?;
          final audioBase64 = audio?['data'] as String?;

          if (audioBase64 == null || audioBase64.isEmpty) {
            throw Exception('MiMo语音合成响应中无音频数据');
          }

          return await SpeechSynthesisResponse.fromBinaryData(
            base64Decode(audioBase64),
            format: request.responseFormat ?? 'wav',
            source: platform.id,
          );

        default:
          // 2026-09-03 通用化：用户自建平台按OpenAI兼容(/audio/speech)处理，
          // 返回二进制音频数据
          final audioBytes = await HttpUtils.post(
            path: url,
            headers: headers,
            data: requestBody,
            responseType: CusRespType.bytes,
            showLoading: false,
          );

          return await SpeechSynthesisResponse.fromBinaryData(
            audioBytes,
            format: request.responseFormat ?? 'mp3',
            source: platform.id,
          );
      }
    } catch (e) {
      throw Exception('语音合成请求失败: $e');
    }
  }
}
