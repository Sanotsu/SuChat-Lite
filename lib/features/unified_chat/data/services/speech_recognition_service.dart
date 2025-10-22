import 'dart:io';
import 'package:dio/dio.dart';

import '../../../../core/network/dio_client/cus_http_client.dart';
import '../models/unified_platform_spec.dart';
import '../models/speech_recognition_request.dart';
import '../models/speech_recognition_response.dart';

/// 语音识别服务
class SpeechRecognitionService {
  /// 执行语音识别
  static Future<SpeechRecognitionResponse> recognizeSpeech({
    required UnifiedPlatformSpec platform,
    required SpeechRecognitionRequest request,
    required String apiKey,
  }) async {
    try {
      switch (platform.id) {
        case 'aliyun':
          return await _recognizeWithAliyun(platform, request, apiKey);
        case 'siliconCloud':
          return await _recognizeWithSiliconCloud(platform, request, apiKey);
        case 'zhipu':
          return await _recognizeWithZhipu(platform, request, apiKey);
        default:
          throw Exception('不支持的平台: ${platform.id}');
      }
    } catch (e) {
      throw Exception('语音识别请求失败: $e');
    }
  }

  /// 阿里百炼语音识别
  static Future<SpeechRecognitionResponse> _recognizeWithAliyun(
    UnifiedPlatformSpec platform,
    SpeechRecognitionRequest request,
    String apiKey,
  ) async {
    final url = platform.getSpeechToTextUrl();
    if (url == null) {
      throw Exception('阿里百炼平台未配置语音识别端点');
    }

    // 阿里百炼需要先将文件上传到公网平台，得到公网url
    final audioFile = request.getAudioFile();

    if (audioFile == null || !audioFile.existsSync()) {
      throw Exception('音频文件不存在或路径无效');
    }

    // 1 直接上传文件到 https://tmpfiles.org/ 最大100M，60分钟后自动删除
    // qwen-asr最大只支持10M和3分钟内的音频文件
    final directLink = await uploadToTmpFiles(audioFile, maxSizeMB: 10);

    // 2 使用直接链接调用阿里百炼语音识别API
    final requestData = request.toAliyunFormat(audioUrl: directLink);

    final responseData = await HttpUtils.post(
      path: url,
      data: requestData,
      showLoading: false,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
    );

    return SpeechRecognitionResponse.fromAliyunResponse(responseData);
  }

  /// 硅基流动语音识别
  static Future<SpeechRecognitionResponse> _recognizeWithSiliconCloud(
    UnifiedPlatformSpec platform,
    SpeechRecognitionRequest request,
    String apiKey,
  ) async {
    final url = platform.getSpeechToTextUrl();
    if (url == null) {
      throw Exception('硅基流动平台未配置语音识别端点');
    }
    final audioFile = request.getAudioFile();

    if (audioFile == null || !audioFile.existsSync()) {
      throw Exception('音频文件不存在或路径无效');
    }

    // 创建FormData
    final formData = FormData();

    // 添加音频文件
    formData.files.add(
      MapEntry(
        'file',
        await MultipartFile.fromFile(
          audioFile.path,
          filename: audioFile.path.split('/').last,
        ),
      ),
    );

    // 添加其他参数
    final formParams = request.toSiliconCloudFormData();
    formParams.forEach((key, value) {
      formData.fields.add(MapEntry(key, value.toString()));
    });

    final responseData = await HttpUtils.post(
      path: url,
      data: formData,
      showLoading: false,
      headers: {'Authorization': 'Bearer $apiKey'},
    );

    return SpeechRecognitionResponse.fromSiliconCloudResponse(responseData);
  }

  /// 智谱语音识别
  static Future<SpeechRecognitionResponse> _recognizeWithZhipu(
    UnifiedPlatformSpec platform,
    SpeechRecognitionRequest request,
    String apiKey,
  ) async {
    final url = platform.getSpeechToTextUrl();
    if (url == null) {
      throw Exception('智谱平台未配置语音识别端点');
    }
    final audioFile = request.getAudioFile();

    if (audioFile == null || !audioFile.existsSync()) {
      throw Exception('音频文件不存在或路径无效');
    }

    // 创建FormData
    final formData = FormData();

    // 添加音频文件
    formData.files.add(
      MapEntry(
        'file',
        await MultipartFile.fromFile(
          audioFile.path,
          filename: audioFile.path.split('/').last,
        ),
      ),
    );

    // 添加其他参数
    final formParams = request.toZhipuFormData();
    formParams.forEach((key, value) {
      formData.fields.add(MapEntry(key, value.toString()));
    });

    final responseData = await HttpUtils.post(
      path: url,
      data: formData,
      showLoading: false,
      headers: {'Authorization': 'Bearer $apiKey'},
    );

    return SpeechRecognitionResponse.fromZhipuResponse(responseData);
  }

  /// 验证音频文件格式
  static bool isValidAudioFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return false;

    final extension = filePath.toLowerCase().split('.').last;
    const supportedFormats = [
      'mp3',
      'wav',
      'aac',
      'amr',
      'flac',
      'ogg',
      'opus',
      'm4a',
    ];

    return supportedFormats.contains(extension);
  }

  /// 获取音频文件大小（MB）
  static double getAudioFileSizeMB(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return 0.0;

    final bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }

  /// 验证音频文件大小
  static bool isValidAudioFileSize(String filePath, {double maxSizeMB = 25.0}) {
    final sizeMB = getAudioFileSizeMB(filePath);
    return sizeMB > 0 && sizeMB <= maxSizeMB;
  }

  /// 上传文件到tmpfiles.org
  static Future<String> uploadToTmpFiles(
    File file, {
    double maxSizeMB = 25.0,
  }) async {
    if (!isValidAudioFileSize(file.path, maxSizeMB: maxSizeMB)) {
      throw Exception('文件大小超过限制');
    }

    // 直接上传文件到 https://tmpfiles.org/
    // 最大100M，60分钟后自动删除
    final formData = FormData();
    formData.files.add(
      MapEntry(
        'file',
        await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      ),
    );

    final uploadResponse = await HttpUtils.post(
      path: 'https://tmpfiles.org/api/v1/upload',
      data: formData,
    );

    // 从上传响应中获取下载地址
    final downloadUrl = uploadResponse['data']['url'] as String?;
    if (downloadUrl == null) {
      throw Exception(
        '无法获取上传到tmpfiles.org的下载地址。\nuploadResponse:$uploadResponse',
      );
    }

    // 步骤3: 创建直接链接
    // 注意：响应中的地址类似(浏览器访问得到下载按钮)
    // http://tmpfiles.org/3978861/4c6de638-49e4-4e9a-a555-4cb9f1fa8553.mp3
    // 但下载地址需要(直接的文件地址)
    // https://tmpfiles.org/dl/3978861/4c6de638-49e4-4e9a-a555-4cb9f1fa8553.mp3
    final directLink = downloadUrl.replaceFirst(
      'http://tmpfiles.org',
      'https://tmpfiles.org/dl',
    );

    return directLink;
  }
}
