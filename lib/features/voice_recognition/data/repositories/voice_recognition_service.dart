import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import 'package:uuid/uuid.dart';

import '../../../../shared/constants/constants.dart';
import '../../../../shared/constants/constant_llm_enum.dart';
import '../../../unified_chat/data/models/speech_recognition_request.dart';
import '../../../unified_chat/data/models/unified_model_spec.dart';
import '../../../unified_chat/data/models/unified_platform_spec.dart';
import '../../../unified_chat/data/services/speech_recognition_service.dart';
import '../../../unified_chat/data/services/unified_secure_storage.dart';
import '../../../../core/entities/cus_llm_model.dart';
import '../../../../core/network/dio_client/cus_http_client.dart';
import '../../../../core/storage/db_helper.dart';
import '../../../../shared/services/tmp_file_upload_service.dart';
import '../../domain/entities/voice_recognition_task_info.dart';
import '../models/sense_voice.dart';

///
/// 阿里云录音识别服务
///
class VoiceRecognitionService {
  // 创建dio实例用于网络请求
  static final _dio = Dio();

  // 数据库帮助类实例
  static final _dbHelper = DBHelper();

  // 阿里云录音识别API地址
  static const String _recognitionBaseUrl =
      'https://dashscope.aliyuncs.com/api/v1/services/audio/asr/transcription';

  // 任务查询API地址
  static String _getTaskQueryUrl(String taskId) =>
      'https://dashscope.aliyuncs.com/api/v1/tasks/$taskId';

  /// 获取API Key
  /// 2026-09-03 AK统一到平台管理：从统一安全存储读取阿里云平台密钥
  /// (旧CusGetStorage AKMap配置入口已移除，仅作存量兼容不再使用)
  static Future<String> _getApiKey() async {
    final apiKey = await UnifiedSecureStorage.getApiKey('aliyun');

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('未配置阿里云平台的 API Key，请在聊天页-平台管理中配置');
    }
    return apiKey;
  }

  // 用于提交前检查等外部使用
  static Future<String> getAliyunAK() => _getApiKey();

  /// 提交录音识别任务
  /// [audioPath] - 音频文件路径
  /// [cloudAudioUrl] - 云端音频URL，如果提供则优先使用
  /// 2025-05-07 暂时没用到
  /// [languageHint] - 语音中的语言代码，例如中文为"zh"，英文为"en"
  /// 返回识别任务ID
  static Future<String> submitRecognitionTask({
    required CusLLMSpec model,
    required String audioPath,
    String? cloudAudioUrl,
    String? languageHint,
  }) async {
    try {
      String audioUrl;

      // 如果提供了云端URL，直接使用
      if (cloudAudioUrl != null && cloudAudioUrl.isNotEmpty) {
        // 验证URL是否有效
        if (!cloudAudioUrl.startsWith('http://') &&
            !cloudAudioUrl.startsWith('https://')) {
          throw '无效的云端音频URL，必须以 http:// 或 https:// 开头';
        }
        audioUrl = cloudAudioUrl;
      } else {
        // 没有提供云端URL，使用本地文件并上传到GitHub
        // 检查音频文件是否存在
        final audioFile = File(audioPath);
        if (!await audioFile.exists()) {
          throw '音频文件不存在';
        }

        // 上传音频文件到GitHub
        audioUrl = await _uploadAudioFile(audioFile);
        if (audioUrl.isEmpty) {
          throw '上传音频文件失败';
        }
      }

      // 2. 调用阿里云API提交录音识别任务
      final apiKey = await _getApiKey();
      final headers = {
        'content-type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'X-DashScope-Async': 'enable',
      };

      // 具体参数参考文档，这里是使用必填的和一些简单的
      // https://help.aliyun.com/zh/model-studio/developer-reference/sensevoice-recorded-speech-recognition-restful-api#b52292e65768b
      // https://help.aliyun.com/zh/model-studio/paraformer-recorded-speech-recognition-restful-api#b52292e65768b
      // 2026-09-03 新一代模型适配(以2026-09官方文档核实)：
      // qwen3-asr-flash-filetrans的input为file_url(单数)，
      // 其余(Qwen-Audio-3.0-ASR-Flash-Filetrans/Fun-ASR/Paraformer)均为file_urls(数组)
      final isQwen3Filetrans = model.model.startsWith(
        'qwen3-asr-flash-filetrans',
      );
      final Map<String, dynamic> params = {
        // 指定模型名
        'model': model.model,
        'input': isQwen3Filetrans
            ? {'file_url': audioUrl}
            : {
                // 待识别音/视频文件的URL列表，单次请求最多支持100个URL
                'file_urls': [audioUrl],
              },
        'parameters': {
          // 指定在多音轨文件中需要进行语音识别的音轨索引
          // [0]表示仅识别第一条音轨，[0, 1]表示同时识别前两条音轨。
          'channel_id': [0],
          // 过滤语气词，默认关闭
          'disfluency_removal_enabled': false,
          // 2025-05-07 非必填项，简单点就自动识别，不需要手动选择
          // 'language_hints': [languageHint ?? 'auto'],

          /// 上面是SenseVoice的参数，下面是Paraformer的额外参数
          /// 实测使用senseVoice时带上这些参数不会报错，虽然没效
          // 是否启用时间戳校准功能，默认关闭。
          // "timestamp_alignment_enabled": true,

          // 敏感词过滤功能，支持开启或关闭，支持自定义敏感词。
          // 该参数可实现：不处理（默认，即展示原文）、过滤、替换为*。
          // "special_word_filter": ['肏'],

          // 更多热词等参数就不设置了
        },
      };

      // 启用diarization自动说话人分离(可选)
      // 支持范围(2026-09官方文档)：Paraformer系列、Qwen-Audio-3.0-ASR-Flash-Filetrans、
      // Fun-ASR/Fun-ASR-MTL(flash版不支持)；qwen3-asr-flash-filetrans不支持
      final modelName = model.model.toLowerCase();
      final supportsDiarization =
          modelName.contains('paraformer') ||
          modelName.startsWith('qwen-audio-3.0-asr-flash-filetrans') ||
          (modelName.startsWith('fun-asr') && !modelName.contains('flash'));
      if (supportsDiarization) {
        (params['parameters'] as Map<String, dynamic>)['diarization_enabled'] =
            true;
      }

      final response = await HttpUtils.post(
        path: _recognitionBaseUrl,
        data: params,
        headers: headers,
        showLoading: false,
      );

      if (response != null) {
        // 解析响应为标准模型
        final senseVoiceResp = SenseVoiceJobResp.fromJson(response);
        final taskId = senseVoiceResp.output!.taskId;
        final taskStatus = senseVoiceResp.output!.taskStatus;

        // 创建本地任务信息
        final taskInfo = VoiceRecognitionTaskInfo(
          taskId: taskId,
          localAudioPath: cloudAudioUrl == null ? audioPath : null,
          // 字段名沿用历史(原GitHub存储)，现存放tmpfiles.org临时直链
          githubAudioUrl: audioUrl,
          languageHint: languageHint ?? 'auto',
          taskStatus: taskStatus,
          gmtCreate: DateTime.now(),
          llmSpec: model,
          jobResponse: senseVoiceResp,
        );

        // 保存任务到数据库
        await _dbHelper.saveVoiceRecognitionTask(taskInfo);

        return taskId;
      } else {
        throw '提交录音识别任务失败: 响应为空';
      }
    } catch (e) {
      debugPrint('提交录音识别任务异常: $e');
      rethrow;
    }
  }

  /// 查询录音识别任务状态
  /// [taskId] - 任务ID
  static Future<VoiceRecognitionTaskInfo> queryTaskStatus(String taskId) async {
    try {
      final apiKey = await _getApiKey();
      final url = _getTaskQueryUrl(taskId);

      final headers = {
        'content-type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'X-DashScope-Async': 'enable',
      };

      final response = await HttpUtils.post(
        path: url,
        headers: headers,
        showLoading: false,
      );

      if (response != null) {
        // 解析响应为标准模型
        final senseVoiceResp = SenseVoiceJobResp.fromJson(response);

        // 获取已存在的任务信息
        final existingTask = await _dbHelper.getVoiceRecognitionTaskById(
          taskId,
        );

        if (existingTask == null) {
          throw Exception('未找到ID为 $taskId 的语音识别任务');
        }

        // 更新基本任务信息
        var updatedTask = existingTask.copyWith(
          taskStatus: senseVoiceResp.output!.taskStatus,
          jobResponse: senseVoiceResp,
        );

        // 如果任务已成功完成，尝试获取识别结果
        if (senseVoiceResp.output!.taskStatus == 'SUCCEEDED' &&
            updatedTask.transcriptionUrl != null) {
          // 下载和解析识别结果
          final detailedResponse = await _downloadTranscriptionResult(
            updatedTask.transcriptionUrl!,
          );

          if (detailedResponse != null) {
            // 进一步更新任务信息，包含识别结果
            updatedTask = updatedTask.copyWith(
              recognitionResponse: detailedResponse,
            );
          }
        }

        // 保存更新后的任务到数据库
        await _dbHelper.updateVoiceRecognitionTask(updatedTask);

        return updatedTask;
      } else {
        throw '查询任务失败: 响应为空';
      }
    } catch (e) {
      debugPrint('查询任务状态异常: $e');
      rethrow;
    }
  }

  /// 下载识别结果
  static Future<SenseVoiceRecogResp?> _downloadTranscriptionResult(
    String url,
  ) async {
    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        return SenseVoiceRecogResp.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('下载识别结果失败: $e');
      return null;
    }
  }

  /// 将识别后文本的语气等标记全都移除
  static String cleanText(String originalText) {
    // 移除所有的<|...|>标签
    return originalText.replaceAll(RegExp(r'<\|.*?\|>'), '').trim();
  }

  /// 删除录音识别任务
  static Future<void> deleteRecognitionTask(String taskId) async {
    try {
      // 从数据库中删除任务记录
      await _dbHelper.deleteVoiceRecognitionTask(taskId);

      // 从数据库中删除任务记录
      await _dbHelper.deleteMediaGenerationHistoryByRequestId(taskId);
    } catch (e) {
      debugPrint('删除录音识别任务失败: $e');
      throw Exception('删除录音识别任务失败: $e');
    }
  }

  /// 获取所有录音识别任务
  static Future<List<VoiceRecognitionTaskInfo>> getRecognitionTasks() async {
    try {
      final tasks = await _dbHelper.getAllVoiceRecognitionTasks();
      return tasks;
    } catch (e) {
      debugPrint('获取录音识别任务列表失败: $e');
      return [];
    }
  }

  /// 上传音频文件到临时存储服务，返回可公开访问的URL
  /// 2026-09-03 改用tmpfiles.org临时存储(免配置，100M内，暂存1小时)，
  /// 替代原GitHub公共仓库方案(需用户配置仓库与令牌，过重)；
  /// DashScope任务提交后通常数分钟内即拉取音频URL，暂存时长足够
  static Future<String> _uploadAudioFile(File audioFile) async {
    // 2026-09-03 改用tmpfile.link(响应直接给下载直链，匿名保存7天)
    return TmpFileUploadService.upload(audioFile, maxSizeMB: 100.0);
  }

  /// 使用平台管理中配置的模型执行同步识别(2026-09-03 打通统一配置)
  /// 适用于用户自建平台/统一模型库中的asr模型(OpenAI兼容/v1/audio/transcriptions)；
  /// 同步接口一般限制25MB内，超长音频请使用内置的阿里云异步模型
  static Future<VoiceRecognitionTaskInfo> recognizeWithUnifiedConfig({
    required UnifiedModelSpec model,
    required UnifiedPlatformSpec platform,
    required String audioPath,
  }) async {
    final apiKey = await UnifiedSecureStorage.getApiKey(platform.id);
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('平台[${platform.displayName}]未配置API Key，请在平台管理中配置');
    }

    final request = SpeechRecognitionRequest(
      model: model.modelName,
      audioPath: audioPath,
    );

    final response = await SpeechRecognitionService.recognizeSpeech(
      platform: platform,
      request: request,
      apiKey: apiKey,
    );

    // 将同步结果转换为标准任务实体，复用任务列表/详情页的展示与复制逻辑
    // segments(秒) -> sentences(毫秒时间戳)
    final sentences = response.segments
        ?.map(
          (s) => SenseVoiceRRTranscriptSentence(
            (s.start * 1000).round(),
            (s.end * 1000).round(),
            s.text,
            null,
            null,
            null,
          ),
        )
        .toList();
    final recogResp = SenseVoiceRecogResp(null, null, [
      SenseVoiceRRTranscript(0, 0, response.text, sentences ?? []),
    ]);

    final taskInfo = VoiceRecognitionTaskInfo(
      taskId: const Uuid().v4(),
      localAudioPath: audioPath,
      languageHint: response.language,
      taskStatus: 'SUCCEEDED',
      gmtCreate: DateTime.now(),
      llmSpec: CusLLMSpec(
        // platform字段仅为展示(统一配置平台无对应枚举值，统一以阿里占位)
        ApiPlatform.aliyun,
        model.modelName,
        LLModelType.asr,
        description: '平台管理·${platform.displayName}',
        cusLlmSpecId: const Uuid().v4(),
      ),
      recognitionResponse: recogResp,
    );

    await _dbHelper.saveVoiceRecognitionTask(taskInfo);
    return taskInfo;
  }

  /// 通过任务ID获取录音识别任务
  static Future<VoiceRecognitionTaskInfo?> getRecognitionTaskById(
    String taskId,
  ) async {
    try {
      return await _dbHelper.getVoiceRecognitionTaskById(taskId);
    } catch (e) {
      debugPrint('获取录音识别任务失败: $e');
      return null;
    }
  }

  /// 根据选中的模型获取支持的语言列表
  /// https://help.aliyun.com/zh/model-studio/paraformer-recorded-speech-recognition-restful-api#1564da7efa42e
  static List<CusLabel> getLanguageOptions(CusLLMSpec selectedModel) {
    final List<CusLabel> baseOptions = [
      CusLabel(cnLabel: "自动识别", value: "auto"),
      CusLabel(cnLabel: "中文", value: "zh"),
    ];

    final List<CusLabel> languageOptions = [
      ...baseOptions,
      CusLabel(cnLabel: "英文", value: "en"),
      CusLabel(cnLabel: "粤语", value: "yue"),
      CusLabel(cnLabel: "日语", value: "ja"),
      CusLabel(cnLabel: "韩语", value: "ko"),
      CusLabel(cnLabel: "俄语", value: "ru"),
      CusLabel(cnLabel: "法语", value: "fr"),
      CusLabel(cnLabel: "意大利语", value: "it"),
      CusLabel(cnLabel: "德语", value: "de"),
      CusLabel(cnLabel: "西班牙语", value: "es"),
    ];

    if (selectedModel.model == 'paraformer-8k-v2' ||
        selectedModel.model == 'paraformer-8k-v1') {
      return baseOptions;
    } else if (selectedModel.model == 'paraformer-v1') {
      return [...baseOptions, CusLabel(cnLabel: "英文", value: "en")];
    } else if (selectedModel.model == 'paraformer-v2') {
      return [
        ...baseOptions,
        CusLabel(cnLabel: "日语", value: "ja"),
        CusLabel(cnLabel: "韩语", value: "ko"),
      ];
    } else {
      // paraformer-mtl-v1 和 sensevoice-v1 返回所有
      return languageOptions;
    }
  }
}
