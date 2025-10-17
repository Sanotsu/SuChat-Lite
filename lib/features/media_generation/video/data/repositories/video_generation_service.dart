import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';

import '../../../../../shared/constants/default_models.dart';
import '../../../../../core/entities/cus_llm_model.dart';
import '../../../../../shared/constants/constant_llm_enum.dart';
import '../../../../../core/network/dio_client/cus_http_client.dart';
import '../../../../../core/storage/cus_get_storage.dart';
import '../models/video_generation_request.dart';
import '../models/video_generation_response.dart';

class VideoGenerationService {
  static String _getBaseUrl(ApiPlatform platform) {
    switch (platform) {
      case ApiPlatform.aliyun:
        return 'https://dashscope.aliyuncs.com/api/v1/services/aigc/video-generation/video-synthesis';
      case ApiPlatform.zhipu:
        return 'https://open.bigmodel.cn/api/paas/v4/videos/generations';
      case ApiPlatform.siliconCloud:
        return 'https://api.siliconflow.cn/v1/video/submit';
      default:
        throw Exception('不支持的平台');
    }
  }

  static String _getBaseTaskUrl(ApiPlatform platform) {
    // 阿里云和智谱是GET，任务编号接在url后面，硅基流动是POST，任务编号接在body中
    switch (platform) {
      case ApiPlatform.aliyun:
        return 'https://dashscope.aliyuncs.com/api/v1/tasks';
      case ApiPlatform.zhipu:
        return 'https://open.bigmodel.cn/api/paas/v4/async-result';
      case ApiPlatform.siliconCloud:
        return 'https://api.siliconflow.cn/v1/video/status';

      default:
        throw Exception('不支持的平台');
    }
  }

  static Future<String> _getApiKey(CusLLMSpec model) async {
    if (model.cusLlmSpecId.endsWith('_builtin')) {
      // 使用内置的 API Key
      switch (model.platform) {
        case ApiPlatform.zhipu:
          return DefaultApiKeys.zhipuAK;
        default:
          throw Exception('不支持的平台');
      }
    } else {
      // 使用用户的 API Key
      final userKeys = CusGetStorage().getUserAKMap();
      String? apiKey;

      switch (model.platform) {
        case ApiPlatform.siliconCloud:
          apiKey = userKeys[ApiPlatformAKLabel.USER_SILICONCLOUD_API_KEY.name];
          break;
        case ApiPlatform.zhipu:
          apiKey = userKeys[ApiPlatformAKLabel.USER_ZHIPU_API_KEY.name];
          break;
        case ApiPlatform.aliyun:
          apiKey = userKeys[ApiPlatformAKLabel.USER_ALIYUN_API_KEY.name];
          break;

        default:
          throw Exception('不支持的平台');
      }

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('未配置该平台的 API Key');
      }
      return apiKey;
    }
  }

  static Future<Map<String, String>> _getHeaders(CusLLMSpec model) async {
    final apiKey = await _getApiKey(model);

    switch (model.platform) {
      case ApiPlatform.siliconCloud || ApiPlatform.zhipu:
        return {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        };
      case ApiPlatform.aliyun:
        return {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'X-DashScope-Async': 'enable',
        };

      // ... 其他平台的 headers
      default:
        throw Exception('不支持的平台');
    }
  }

  // 生成视频
  // 2025-02-25 返回提交任务的响应，而不是生成结果,因为视频生成耗时较长，需要轮询任务状态
  static Future<VideoGenerationSubmitResponse> generateVideo(
    CusLLMSpec model,
    String prompt, {
    String? referenceImagePath,
    int? fps,
    String? size,
    Map<String, dynamic>? extraParams,
  }) async {
    final headers = await _getHeaders(model);
    final baseUrl = _getBaseUrl(model.platform);

    // 处理参考图片
    String? referenceImage;
    if (referenceImagePath != null) {
      final bytes = await File(referenceImagePath).readAsBytes();
      final mimeType = lookupMimeType(referenceImagePath);
      referenceImage = "data:$mimeType;base64,${base64Encode(bytes)}";
    }

    final request = VideoGenerationRequest(
      model: model.model,
      prompt: prompt,
      refImage: referenceImage,
      // fps: fps,
      // size: size,
    );

    final requestBody = {
      ...request.toRequestBody(model.platform),
      ...?extraParams,
    };

    final response = await HttpUtils.post(
      path: baseUrl,
      headers: headers,
      data: requestBody,
      showLoading: false,
    );

    return VideoGenerationSubmitResponse.fromResponseBody(
      response,
      model.platform,
    );
  }

  static Future<CusUnifiedVideoGenResp> pollTaskStatus(
    String taskId,
    CusLLMSpec model, {
    VideoGenerationSubmitResponse? submitResp,
  }) async {
    const maxAttempts = 60; // 最大轮询次数
    const interval = Duration(seconds: 5); // 轮询间隔

    for (var i = 0; i < maxAttempts; i++) {
      final response = await queryTaskStatus(taskId, model);

      // 这里任务的状态都使用阿里云的枚举
      switch (model.platform) {
        case ApiPlatform.siliconCloud:
          if (response.taskStatus == 'Succeed') {
            return CusUnifiedVideoGenResp(
              requestId: submitResp?.requestId,
              taskId: taskId,
              status: 'SUCCEEDED',
              results: response.results?.videos ?? [],
            );
          }
          break;
        case ApiPlatform.aliyun:
          if (response.output?.taskStatus == 'SUCCEEDED') {
            return CusUnifiedVideoGenResp(
              requestId: submitResp?.requestId,
              taskId: taskId,
              status: 'SUCCEEDED',
              results: response.output?.videoUrl != null
                  ? [VideoResult(url: response.output?.videoUrl ?? '')]
                  : [],
            );
          }
          if (response.output?.taskStatus == 'FAILED' ||
              response.output?.taskStatus == 'UNKNOWN') {
            throw Exception('视频生成失败');
          }
          break;
        case ApiPlatform.zhipu:
          if (response.taskStatus == 'SUCCESS') {
            return CusUnifiedVideoGenResp(
              requestId: submitResp?.requestId,
              taskId: taskId,
              status: 'SUCCEEDED',
              results: response.videoResult ?? [],
            );
          }
          if (response.output?.taskStatus == 'FAIL') {
            throw Exception('视频生成失败');
          }
          break;
        default:
          throw Exception('不支持的平台');
      }

      await Future.delayed(interval);
    }

    throw Exception('视频生成任务超时(5分钟)');
  }

  // 查询任务状态
  static Future<VideoGenerationTaskResponse> queryTaskStatus(
    String taskId,
    CusLLMSpec model,
  ) async {
    final headers = await _getHeaders(model);

    dynamic taskResponse;

    switch (model.platform) {
      case ApiPlatform.siliconCloud:
        taskResponse = await HttpUtils.post(
          path: _getBaseTaskUrl(model.platform),
          headers: headers,
          data: {'requestId': taskId},
          showErrorMessage: false,
        );
        break;

      case ApiPlatform.aliyun:
        taskResponse = await HttpUtils.get(
          path: "${_getBaseTaskUrl(model.platform)}/$taskId",
          headers: headers,
          showErrorMessage: false,
        );
        break;

      case ApiPlatform.zhipu:
        taskResponse = await HttpUtils.get(
          path: "${_getBaseTaskUrl(model.platform)}/$taskId",
          headers: headers,
          showErrorMessage: false,
        );
        break;

      default:
        throw Exception('不支持的平台');
    }

    return VideoGenerationTaskResponse.fromJson(taskResponse);
  }
}
