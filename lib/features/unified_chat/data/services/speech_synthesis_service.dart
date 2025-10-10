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

          return SpeechSynthesisResponse.fromBinaryData(
            audioBytes,
            format: request.responseFormat ?? 'mp3',
            source: platform.id,
          );

        default:
          throw Exception('不支持的平台: ${platform.id}');
      }
    } catch (e) {
      throw Exception('语音合成请求失败: $e');
    }
  }
}
