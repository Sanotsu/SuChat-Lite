import 'dart:convert';

import 'package:dio/dio.dart';

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

    // 2026-10-14 阿里Qwen-Audio-TTS系列端点特殊处理(不落库，按模型名判定)：
    // 官方文档(qwen-audio-tts-http-api)该系列走
    // /api/v1/services/audio/tts/SpeechSynthesizer，与Qwen-TTS系的
    // multimodal-generation不同。当前仅此一例特例，暂不做通用的模型级
    // 端点配置；后续端点分化增多或启用业务空间专属域名时再重构
    String? url;
    if (platform.id == 'aliyun' && model.modelName.startsWith('qwen-audio-')) {
      final host = platform.hostUrl.replaceAll(RegExp(r'/+$'), '');
      url = '$host/api/v1/services/audio/tts/SpeechSynthesizer';
    } else {
      url = platform.getTextToSpeechUrl();
    }
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
          // 阿里百炼返回JSON格式，音频以OSS临时链接下发(约24小时过期)
          final responseData = await HttpUtils.post(
            path: url,
            headers: headers,
            data: requestBody,
            showLoading: false,
          );
          final aliyunResp = SpeechSynthesisResponse.fromAliyunResponse(
            responseData,
          );
          // 2026-10-14 FIX：直接把OSS远程链接当播放地址和翻译历史的audioPath不行——明文http链接在Android默认被禁止，
          // 播放器加载挂起导致界面一直loading；远程链接也非本地文件，历史记录存在性检查误报"音频文件不存在或已被清理"。
          // 与其他平台统一：下载音频落地本地文件后再返回。
          final ossUrl = aliyunResp.audioUrl;
          if (ossUrl == null || ossUrl.isEmpty) {
            throw Exception('阿里百炼语音合成响应中无音频链接');
          }
          // OSS结果链接同时支持https，升级以规避明文流量限制
          // 2026-10-14 FIX：OSS签名链接对请求头敏感——项目HTTP单例默认
          // 携带application/json的Content-Type，会被OSS服务端纳入签名
          // 计算，触发403 SignatureDoesNotMatch；因此用无拦截器、无默认
          // 请求头的干净Dio实例下载
          final cleanDio = Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(minutes: 5),
            ),
          );
          final ossResp = await cleanDio.get<List<int>>(
            ossUrl.replaceFirst('http://', 'https://'),
            options: Options(responseType: ResponseType.bytes),
          );
          final audioBytes = ossResp.data ?? <int>[];

          // 阿里qwen-tts系列默认输出wav格式
          return await SpeechSynthesisResponse.fromBinaryData(
            audioBytes,
            format: 'wav',
            source: 'aliyun',
          );

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
