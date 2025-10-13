import '../../../../core/network/dio_client/cus_http_client.dart';
import '../models/unified_model_spec.dart';
import '../models/unified_platform_spec.dart';
import '../models/image_generation_request.dart';
import '../models/image_generation_response.dart';
import 'unified_secure_storage.dart';

/// 图片生成服务
class ImageGenerationService {
  static final ImageGenerationService _instance =
      ImageGenerationService._internal();
  factory ImageGenerationService() => _instance;
  ImageGenerationService._internal();

  /// 生成图片
  Future<ImageGenerationResponse> generateImage({
    required ImageGenerationRequest request,
    required UnifiedPlatformSpec platform,
    required UnifiedModelSpec model,
  }) async {
    // 获取API密钥
    final apiKey = await UnifiedSecureStorage.getApiKey(platform.id);
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('未找到 ${platform.displayName} 的API密钥');
    }

    final url = platform.getImageGenerationUrl();
    if (url == null) {
      throw Exception('平台 ${platform.displayName} 不支持图片生成');
    }

    // 根据平台转换请求格式
    Map<String, dynamic> requestBody;
    switch (platform.id) {
      case 'aliyun':
        requestBody = request.toAliyunFormat(model);
        break;
      case 'siliconCloud':
        requestBody = request.toSiliconCloudFormat();
        break;
      case 'zhipu':
        requestBody = request.toZhipuFormat();
        break;
      case 'volcengine':
        requestBody = request.toVolcengineFormat();
        break;
      default:
        requestBody = request.toSiliconCloudFormat();
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    // 阿里百炼[异步请求]才需要特殊的请求头(旧版本的生图模型需要，新的qwen-image不需要)
    if (platform.id == UnifiedPlatformId.aliyun.name &&
        !model.modelName.contains('qwen-image')) {
      headers['X-DashScope-Async'] = 'enable';
    }

    // 是阿里云的新同步请求版本的模型，才使用指定的地址
    bool isAliyunSync =
        platform.id == UnifiedPlatformId.aliyun.name &&
        model.modelName.contains('qwen-image');

    try {
      final responseData = await HttpUtils.post(
        path: isAliyunSync
            ? "https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation"
            : url,
        headers: headers,
        data: requestBody,
        showLoading: false,
      );

      // 根据平台解析响应
      switch (platform.id) {
        case 'aliyun':
          // 同步的图片生成url为  /multimodal-generation/generation
          // 异步的图片生成url为  /text2image/image-synthesis (wanx2、wan2.5、flux等)
          return isAliyunSync
              ? ImageGenerationResponse.fromAliyunSyncResponse(responseData)
              : _handleAliyunResponse(responseData, apiKey, url);
        case 'siliconCloud':
          return ImageGenerationResponse.fromSiliconCloudResponse(responseData);
        case 'zhipu':
          return ImageGenerationResponse.fromZhipuResponse(responseData);
        case 'volcengine':
          return ImageGenerationResponse.fromVolcengineResponse(responseData);
        default:
          return ImageGenerationResponse.fromSiliconCloudResponse(responseData);
      }
    } catch (e) {
      throw Exception('图片生成请求失败: $e');
    }
  }

  /// 处理阿里百炼异步响应
  Future<ImageGenerationResponse> _handleAliyunResponse(
    Map<String, dynamic> responseData,
    String apiKey,
    String baseUrl,
  ) async {
    final taskId = responseData['output']?['task_id'] as String?;
    if (taskId == null) {
      throw Exception('阿里百炼响应中未找到任务ID');
    }

    const maxAttempts = 30;
    const pollInterval = Duration(seconds: 2);

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      await Future.delayed(pollInterval);

      final pollData = await HttpUtils.get(
        path: 'https://dashscope.aliyuncs.com/api/v1/tasks/$taskId',
        headers: {'Authorization': 'Bearer $apiKey'},
        showLoading: false,
      );

      final taskStatus = pollData['output']?['task_status'] as String?;

      if (taskStatus == 'SUCCEEDED') {
        return ImageGenerationResponse.fromAliyunAsyncResponse(pollData);
      } else if (taskStatus == 'FAILED') {
        final errorMessage =
            pollData['output']?['message'] as String? ?? '未知错误';
        throw Exception('阿里百炼图片生成失败: $errorMessage');
      }
      // 其他状态（PENDING、RUNNING等）继续轮询
    }

    throw Exception('阿里百炼图片生成超时');
  }
}
