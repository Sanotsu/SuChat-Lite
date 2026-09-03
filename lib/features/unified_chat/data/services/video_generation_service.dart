import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';

import '../../../../core/network/dio_client/cus_http_client.dart';
import '../models/unified_model_spec.dart';
import '../models/unified_platform_spec.dart';
import 'unified_secure_storage.dart';

/// 视频生成任务的标准化状态
enum VideoTaskStatus { submitting, processing, succeeded, failed }

/// 视频生成任务查询结果(跨平台统一)
class VideoTaskResult {
  final VideoTaskStatus status;

  /// 生成完成的视频网络地址(仅 succeeded 时有值)
  final List<String> videoUrls;

  /// 任务平台侧编号(提交后回填，用于退出页面后续查)
  final String? taskId;

  final String? error;

  const VideoTaskResult({
    required this.status,
    this.videoUrls = const [],
    this.taskId,
    this.error,
  });
}

/// 聊天模块的视频生成服务
/// 2026-09-02 随媒体生成并入聊天新增：三平台(阿里百炼/智谱/硅基流动)都是
/// "提交任务 + 查询任务"的异步模式；本服务只做单次提交/单次查询，
/// 轮询节奏由 viewmodel 控制(便于任务态持久化到消息、页面退出后可续查)
class VideoGenerationService {
  static final VideoGenerationService _instance =
      VideoGenerationService._internal();
  factory VideoGenerationService() => _instance;
  VideoGenerationService._internal();

  Future<Map<String, String>> _getHeaders(
    UnifiedPlatformSpec platform,
    bool isAliyunAsync,
  ) async {
    final apiKey = await UnifiedSecureStorage.getApiKey(platform.id);
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('未找到 ${platform.displayName} 的API密钥');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
      // 阿里百炼视频生成是异步任务提交
      if (isAliyunAsync) 'X-DashScope-Async': 'enable',
    };
  }

  /// 提交视频生成任务，返回平台侧任务编号
  Future<String> submitVideoTask({
    required String prompt,
    List<String>? referenceImagePaths,
    Map<String, dynamic>? settings,
    required UnifiedPlatformSpec platform,
    required UnifiedModelSpec model,
  }) async {
    final url = platform.getVideoGenerationUrl();
    if (url == null) {
      throw Exception('平台 ${platform.displayName} 不支持视频生成');
    }

    // 参考图(首帧图)：本地文件读字节转dataURL，平台字段名各异
    String? refImage;
    if (referenceImagePaths != null && referenceImagePaths.isNotEmpty) {
      final bytes = await File(referenceImagePaths.first).readAsBytes();
      final mimeType = lookupMimeType(referenceImagePaths.first);
      refImage = 'data:$mimeType;base64,${base64Encode(bytes)}';
    }

    final isAliyun = platform.id == UnifiedPlatformId.aliyun.name;
    final headers = await _getHeaders(platform, isAliyun);

    final requestBody = _buildRequestBody(
      platform: platform,
      model: model.modelName,
      prompt: prompt,
      refImage: refImage,
      settings: settings,
    );

    try {
      final resp = await HttpUtils.post(
        path: url,
        headers: headers,
        data: requestBody,
        showLoading: false,
      );

      // 各平台提交响应的任务编号字段不同
      switch (platform.id) {
        case 'aliyun':
          final taskId = resp['output']?['task_id'] as String?;
          if (taskId == null || taskId.isEmpty) {
            throw Exception('阿里百炼响应中未找到任务ID');
          }
          return taskId;
        case 'zhipu':
          final id = resp['id'] as String?;
          if (id == null || id.isEmpty) {
            throw Exception('智谱响应中未找到任务ID');
          }
          return id;
        case 'siliconCloud':
          final requestId = resp['requestId'] as String?;
          if (requestId == null || requestId.isEmpty) {
            throw Exception('硅基流动响应中未找到任务ID');
          }
          return requestId;
        case 'volcengine':
          // 火山方舟内容生成异步任务API：POST /v3/contents/generations/tasks
          final id = resp['id'] as String?;
          if (id == null || id.isEmpty) {
            throw Exception('火山方舟响应中未找到任务ID');
          }
          return id;
        default:
          throw Exception('平台 ${platform.displayName} 暂不支持视频生成');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 查询一次任务状态(跨平台统一状态)
  Future<VideoTaskResult> queryVideoTask({
    required String taskId,
    required UnifiedPlatformSpec platform,
  }) async {
    final headers = await _getHeaders(platform, false);

    dynamic resp;
    switch (platform.id) {
      case 'siliconCloud':
        // 硅基流动是POST，任务编号在body中
        resp = await HttpUtils.post(
          path: '${platform.hostUrl}/v1/video/status',
          headers: headers,
          data: {'requestId': taskId},
          showErrorMessage: false,
          showLoading: false,
        );
        break;
      case 'aliyun':
        resp = await HttpUtils.get(
          path: '${platform.hostUrl}/api/v1/tasks/$taskId',
          headers: headers,
          showErrorMessage: false,
          showLoading: false,
        );
        break;
      case 'zhipu':
        resp = await HttpUtils.get(
          path: '${platform.hostUrl}/v4/async-result/$taskId',
          headers: headers,
          showErrorMessage: false,
          showLoading: false,
        );
        break;
      case 'volcengine':
        // 火山方舟内容生成任务查询：GET /v3/contents/generations/tasks/{id}
        resp = await HttpUtils.get(
          path: '${platform.hostUrl}/v3/contents/generations/tasks/$taskId',
          headers: headers,
          showErrorMessage: false,
          showLoading: false,
        );
        break;
      default:
        return const VideoTaskResult(
          status: VideoTaskStatus.failed,
          error: '平台暂不支持视频任务查询',
        );
    }

    return _parseTaskResponse(platform.id, taskId, resp);
  }

  /// 各平台任务状态解析(终态判断沿用旧媒体生成页验证过的行为)
  VideoTaskResult _parseTaskResponse(
    String platformId,
    String taskId,
    dynamic resp,
  ) {
    switch (platformId) {
      case 'siliconCloud':
        // taskStatus: Succeed/Failed/InQueue/Processing
        final status = resp['taskStatus'] as String?;
        if (status == 'Succeed') {
          final videos =
              (resp['results']?['videos'] as List?)
                  ?.map((v) => v['url'] as String)
                  .where((u) => u.isNotEmpty)
                  .toList() ??
              [];
          return VideoTaskResult(
            status: VideoTaskStatus.succeeded,
            taskId: taskId,
            videoUrls: videos,
          );
        }
        if (status == 'Failed') {
          return VideoTaskResult(
            status: VideoTaskStatus.failed,
            taskId: taskId,
            error: resp['reason'] as String? ?? '视频生成失败',
          );
        }
        return VideoTaskResult(
          status: VideoTaskStatus.processing,
          taskId: taskId,
        );

      case 'aliyun':
        // task_status: PENDING/RUNNING/SUCCEEDED/FAILED/UNKNOWN/CANCELED
        final status = resp['output']?['task_status'] as String?;
        if (status == 'SUCCEEDED') {
          final videoUrl = resp['output']?['video_url'] as String?;
          return VideoTaskResult(
            status: VideoTaskStatus.succeeded,
            taskId: taskId,
            videoUrls: videoUrl != null && videoUrl.isNotEmpty
                ? [videoUrl]
                : [],
          );
        }
        if (status == 'FAILED' || status == 'UNKNOWN' || status == 'CANCELED') {
          return VideoTaskResult(
            status: VideoTaskStatus.failed,
            taskId: taskId,
            error: resp['output']?['message'] as String? ?? '视频生成失败',
          );
        }
        return VideoTaskResult(
          status: VideoTaskStatus.processing,
          taskId: taskId,
        );

      case 'zhipu':
        // task_status: SUCCESS/FAIL/PROCESSING
        // 2026-09-02 官方新文档字段为snake_case的task_status，旧版本为taskStatus，双兼容
        final status = (resp['task_status'] ?? resp['taskStatus']) as String?;
        if (status == 'SUCCESS') {
          final videos =
              (resp['videoResult'] as List?)
                  ?.map((v) => v['url'] as String)
                  .where((u) => u.isNotEmpty)
                  .toList() ??
              [];
          return VideoTaskResult(
            status: VideoTaskStatus.succeeded,
            taskId: taskId,
            videoUrls: videos,
          );
        }
        if (status == 'FAIL') {
          return VideoTaskResult(
            status: VideoTaskStatus.failed,
            taskId: taskId,
            error: '视频生成失败',
          );
        }
        return VideoTaskResult(
          status: VideoTaskStatus.processing,
          taskId: taskId,
        );

      case 'volcengine':
        // 方舟内容生成任务状态：queued/running/succeeded/failed/cancelled
        final status = resp['status'] as String?;
        if (status == 'succeeded') {
          // 成功结果在content数组中，视频项形如 {type:'video_url', video_url:{url:...}}
          final videos =
              (resp['content'] as List?)
                  ?.map((item) => item['video_url']?['url'] as String?)
                  .where((u) => u != null && u.isNotEmpty)
                  .map((u) => u!)
                  .toList() ??
              [];
          return VideoTaskResult(
            status: VideoTaskStatus.succeeded,
            taskId: taskId,
            videoUrls: videos,
          );
        }
        if (status == 'failed' || status == 'cancelled') {
          final error = resp['error']?['message'] as String?;
          return VideoTaskResult(
            status: VideoTaskStatus.failed,
            taskId: taskId,
            error: error?.isNotEmpty == true ? error : '视频生成失败',
          );
        }
        return VideoTaskResult(
          status: VideoTaskStatus.processing,
          taskId: taskId,
        );

      default:
        return const VideoTaskResult(
          status: VideoTaskStatus.failed,
          error: '平台暂不支持视频任务查询',
        );
    }
  }

  /// 按平台构造提交请求体(字段结构移植自已验证的旧媒体生成页实现)
  Map<String, dynamic> _buildRequestBody({
    required UnifiedPlatformSpec platform,
    required String model,
    required String prompt,
    String? refImage,
    Map<String, dynamic>? settings,
  }) {
    switch (platform.id) {
      case 'aliyun':
        // 百炼视频模型族(万相/HappyHorse/爱诗等)共用同一异步任务框架，
        // 但请求体分四类协议(2026-09-02 依官方文档核定，HH经实测修正)：
        //  1. wan3.0：input.media数组(首帧可选)，parameters用resolution+ratio(含adaptive)+duration[2,30]+audio
        //  2. HappyHorse：t2v仅prompt；i2v的input.media必选(仅1张首帧)且不支持ratio；duration[3,15]，watermark默认true
        //  3. wan2.7/2.6：input.img_url，parameters用resolution+ratio+duration
        //  4. wan2.2及更早/PixVerse等：input.img_url，parameters用size像素值(必选)+duration
        // 注意：resolution/duration直接影响计费，平台默认1080P为最贵档；
        // 未配置时这里默认720P(画质与费用平衡)，可经设置弹窗调整
        final isWan3 = model.startsWith('wan3.');
        final isHappyHorse = model.startsWith('happyhorse');
        final isResolutionStyle =
            !isHappyHorse &&
            (model.startsWith('wan2.7') || model.startsWith('wan2.6'));

        if (isWan3) {
          return {
            'model': model,
            'input': {
              'prompt': prompt,
              if (refImage != null)
                'media': [
                  {'type': 'first_frame', 'url': refImage},
                ],
            },
            'parameters': {
              'prompt_extend': true,
              'resolution': settings?['resolution'] ?? '720P',
              if (settings?['ratio'] != null) 'ratio': settings!['ratio'],
              if (settings?['duration'] != null)
                'duration': settings!['duration'],
              if (settings?['audio'] != null) 'audio': settings!['audio'],
              if (settings?['watermark'] != null)
                'watermark': settings!['watermark'],
              if (settings?['seed'] != null) 'seed': settings!['seed'],
            },
          };
        }

        if (isHappyHorse) {
          // i2v宽高比自动跟随首帧，仅t2v接受ratio；
          // watermark平台默认true(右下角"Happy Horse")，这里默认false可经弹窗开启
          return {
            'model': model,
            'input': {
              'prompt': prompt,
              if (refImage != null)
                'media': [
                  {'type': 'first_frame', 'url': refImage},
                ],
            },
            'parameters': {
              'resolution': settings?['resolution'] ?? '720P',
              if (refImage == null && settings?['ratio'] != null)
                'ratio': settings!['ratio'],
              if (settings?['duration'] != null)
                'duration': settings!['duration'],
              if (settings?['watermark'] != null)
                'watermark': settings!['watermark'],
              if (settings?['seed'] != null) 'seed': settings!['seed'],
            },
          };
        }

        if (isResolutionStyle) {
          return {
            'model': model,
            'input': {'prompt': prompt, 'img_url': ?refImage},
            'parameters': {
              'prompt_extend': true,
              'resolution': settings?['resolution'] ?? '720P',
              if (settings?['ratio'] != null) 'ratio': settings!['ratio'],
              if (settings?['duration'] != null)
                'duration': settings!['duration'],
              if (settings?['watermark'] != null)
                'watermark': settings!['watermark'],
              if (settings?['seed'] != null) 'seed': settings!['seed'],
            },
          };
        }

        // 旧协议：size为必选参数(像素值)，无配置时用720P标准尺寸兜底
        return {
          'model': model,
          'input': {'prompt': prompt, 'img_url': ?refImage},
          'parameters': {
            'size': settings?['size'] ?? '1280*720',
            if (settings?['duration'] != null)
              'duration': settings!['duration'],
            if (settings?['watermark'] != null)
              'watermark': settings!['watermark'],
            if (settings?['seed'] != null) 'seed': settings!['seed'],
          },
        };

      case 'zhipu':
        return {
          'model': model,
          'prompt': prompt,
          'image_url': ?refImage,
          if (settings?['withAudio'] != null)
            'with_audio': settings!['withAudio'],
          if (settings?['quality'] != null) 'quality': settings!['quality'],
          if (settings?['size'] != null) 'size': settings!['size'],
          if (settings?['fps'] != null) 'fps': settings!['fps'],
        };

      case 'siliconCloud':
        return {
          'model': model,
          'prompt': prompt,
          'image': ?refImage,
          if (settings?['imageSize'] != null)
            'image_size': settings!['imageSize'],
          if (settings?['negativePrompt'] != null)
            'negative_prompt': settings!['negativePrompt'],
          if (settings?['seed'] != null) 'seed': settings!['seed'],
        };

      case 'volcengine':
        // 火山方舟内容生成异步任务：content数组携带文本+首帧图
        return {
          'model': model,
          'content': [
            {'type': 'text', 'text': prompt},
            if (refImage != null)
              {
                'type': 'image_url',
                'image_url': {'url': refImage},
              },
          ],
        };

      default:
        return {'model': model, 'prompt': prompt};
    }
  }
}
