import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:suchat_lite/common/constants/constants.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';

import '../common/llm_spec/constant_llm_enum.dart';
import '../common/llm_spec/cus_brief_llm_model.dart';
import '../common/utils/dio_client/cus_http_client.dart';
import '../common/utils/db_tools/db_brief_ai_tool_helper.dart';
import '../models/brief_ai_tools/media_generation_history/media_generation_history.dart';
import '../models/voice_recognition/sense_voice.dart';

import 'cus_get_storage.dart';
import 'github_storage_service.dart';

// 与 cus_get_storage.dart 中保持一致
final box = GetStorage('SuChatGetStorage');

/// 本地存储的任务模型，包含阿里云任务信息和本地信息
class VoiceRecognitionTaskInfo {
  final String taskId;
  final String? localAudioPath; // 本地音频文件路径
  final String? githubAudioUrl; // GitHub上的音频URL
  final String? languageHint; // 语言类型
  final String? taskStatus; // 任务状态
  final DateTime? gmtCreate; // 创建时间
  final CusBriefLLMSpec? llmSpec; // 任务模型
  final SenseVoiceJobResp? jobResponse; // 阿里云任务响应
  final SenseVoiceRecogResp? recognitionResponse; // 阿里云识别结果

  VoiceRecognitionTaskInfo({
    required this.taskId,
    this.localAudioPath,
    this.githubAudioUrl,
    this.languageHint,
    this.taskStatus,
    this.gmtCreate,
    this.llmSpec,
    this.jobResponse,
    this.recognitionResponse,
  });

  // 从JSON创建任务
  factory VoiceRecognitionTaskInfo.fromJson(Map<String, dynamic> json) {
    return VoiceRecognitionTaskInfo(
      taskId: json['taskId'],
      localAudioPath: json['localAudioPath'],
      githubAudioUrl: json['githubAudioUrl'],
      languageHint: json['languageHint'],
      taskStatus: json['taskStatus'],
      gmtCreate:
          json['gmtCreate'] != null ? DateTime.parse(json['gmtCreate']) : null,
      llmSpec:
          json['llmSpec'] != null
              ? CusBriefLLMSpec.fromJson(jsonDecode(json['llmSpec']))
              : null,
      jobResponse:
          json['jobResponse'] != null
              ? SenseVoiceJobResp.fromJson(jsonDecode(json['jobResponse']))
              : null,
      recognitionResponse:
          json['recognitionResponse'] != null
              ? SenseVoiceRecogResp.fromJson(
                jsonDecode(json['recognitionResponse']),
              )
              : null,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'localAudioPath': localAudioPath,
      'githubAudioUrl': githubAudioUrl,
      'languageHint': languageHint,
      'taskStatus': taskStatus,
      'gmtCreate': gmtCreate?.toIso8601String(),
      'llmSpec': llmSpec != null ? jsonEncode(llmSpec!.toJson()) : null,
      'jobResponse':
          jobResponse != null ? jsonEncode(jobResponse!.toJson()) : null,
      'recognitionResponse':
          recognitionResponse != null
              ? jsonEncode(recognitionResponse!.toJson())
              : null,
    };
  }

  // 复制对象并更新部分属性
  VoiceRecognitionTaskInfo copyWith({
    String? taskId,
    String? localAudioPath,
    String? githubAudioUrl,
    String? languageHint,
    String? taskStatus,
    DateTime? gmtCreate,
    CusBriefLLMSpec? llmSpec,
    SenseVoiceJobResp? jobResponse,
    SenseVoiceRecogResp? recognitionResponse,
  }) {
    return VoiceRecognitionTaskInfo(
      taskId: taskId ?? this.taskId,
      localAudioPath: localAudioPath ?? this.localAudioPath,
      githubAudioUrl: githubAudioUrl ?? this.githubAudioUrl,
      languageHint: languageHint ?? this.languageHint,
      taskStatus: taskStatus ?? this.taskStatus,
      gmtCreate: gmtCreate ?? this.gmtCreate,
      llmSpec: llmSpec ?? this.llmSpec,
      jobResponse: jobResponse ?? this.jobResponse,
      recognitionResponse: recognitionResponse ?? this.recognitionResponse,
    );
  }

  // 获取识别文本
  String? get recognizedText {
    if (recognitionResponse?.transcripts != null &&
        recognitionResponse!.transcripts!.isNotEmpty) {
      return recognitionResponse!.transcripts!.first.text;
    }
    return null;
  }

  // 获取错误信息
  String? get errorMessage {
    // 从jobResponse中提取错误信息，如果有的话
    if (jobResponse?.output?.code != null &&
        jobResponse!.output!.code!.isNotEmpty) {
      return '${jobResponse!.output!.code} - ${jobResponse?.output?.message}';
    }
    return null;
  }

  // 获取分段句子列表
  List<SenseVoiceRRTranscriptSentence>? get sentences {
    if (recognitionResponse?.transcripts != null &&
        recognitionResponse!.transcripts!.isNotEmpty) {
      return recognitionResponse!.transcripts!.first.sentences;
    }
    return null;
  }

  // 获取音频文件URL
  String? get audioFileUrl {
    // 优先使用本地路径
    return localAudioPath ?? githubAudioUrl;
  }

  // 获取音频时长（毫秒）
  int? get audioDurationMs {
    if (recognitionResponse?.properties?.originalDurationInMilliseconds !=
        null) {
      return recognitionResponse!.properties!.originalDurationInMilliseconds;
    }
    return null;
  }

  // 获取识别结果URL
  String? get transcriptionUrl {
    if (jobResponse?.output?.results != null &&
        jobResponse!.output!.results!.isNotEmpty) {
      return jobResponse!.output!.results!.first.transcriptionUrl;
    }
    return null;
  }
}

///
/// 阿里云录音识别服务
///
class VoiceRecognitionService {
  static const _recognitionTasksKey = 'voice_recognition_tasks';

  // 创建dio实例用于网络请求
  static final _dio = Dio();

  // 数据库帮助类实例
  static final _dbHelper = DBBriefAIToolHelper();

  // 阿里云录音识别API地址
  static const String _recognitionBaseUrl =
      'https://dashscope.aliyuncs.com/api/v1/services/audio/asr/transcription';

  // 任务查询API地址
  static String _getTaskQueryUrl(String taskId) =>
      'https://dashscope.aliyuncs.com/api/v1/tasks/$taskId';

  /// 获取API Key
  static Future<String> _getApiKey() async {
    // 使用用户的 API Key
    final userKeys = MyGetStorage().getUserAKMap();
    String? apiKey = userKeys[ApiPlatformAKLabel.USER_ALIYUN_API_KEY.name];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('未配置阿里云平台的 API Key');
    }
    return apiKey;
  }

  /// 提交录音识别任务
  /// [audioPath] - 音频文件路径
  /// 2025-05-07 暂时没用到
  /// [languageHint] - 语音中的语言代码，例如中文为"zh"，英文为"en"
  /// 返回识别任务ID
  static Future<String> submitRecognitionTask({
    required CusBriefLLMSpec model,
    required String audioPath,
    String? languageHint,
  }) async {
    try {
      // 检查音频文件是否存在
      final audioFile = File(audioPath);
      if (!await audioFile.exists()) {
        throw '音频文件不存在';
      }

      // 1. 上传音频文件到GitHub
      final audioUrl = await _uploadAudioFile(audioFile);
      if (audioUrl.isEmpty) {
        throw '上传音频文件失败';
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
      final Map<String, dynamic> params = {
        // 指定模型名
        'model': model.model,
        // 待识别音/视频文件的URL列表，支持HTTP / HTTPS协议，单次请求最多支持100个URL
        'input': {
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

      // 2025-05-07 如果模型是paraformer，则启用diarization 自动说话人分离，可选
      if (model.model.toLowerCase().contains('paraformer')) {
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
          localAudioPath: audioPath,
          githubAudioUrl: audioUrl,
          languageHint: languageHint ?? 'auto',
          taskStatus: taskStatus,
          gmtCreate: DateTime.now(),
          llmSpec: model,
          jobResponse: senseVoiceResp,
        );

        // 保存任务到本地存储
        await _saveTaskInfo(taskInfo);

        // 保存任务到数据库，表示处理中状态
        final mediaHistory = _taskInfoToMediaGenerationHistory(taskInfo);

        // 查询数据库中是否已存在该任务
        final existingHistories = await _dbHelper.queryMediaGenerationHistory(
          isProcessing: true,
        );

        final existingHistory =
            existingHistories
                .where((h) => h.taskId == taskId || h.requestId == taskId)
                .toList();

        if (existingHistory.isEmpty) {
          // 如果不存在，则插入
          await _dbHelper.insertMediaGenerationHistory(mediaHistory);
        }

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
        final existingTasks = await getRecognitionTasks();
        final existingTask = existingTasks.firstWhere(
          (t) => t.taskId == taskId,
          orElse:
              () => VoiceRecognitionTaskInfo(
                taskId: taskId,
                languageHint: 'auto',
                gmtCreate: DateTime.now(),
              ),
        );

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

        // 保存更新后的任务到本地存储
        await _updateTaskInfo(updatedTask);

        // 如果任务已完成，更新数据库记录
        if (updatedTask.taskStatus == 'SUCCEEDED' &&
            updatedTask.recognizedText != null) {
          final mediaHistory = _taskInfoToMediaGenerationHistory(updatedTask);

          // 查询数据库中是否已存在该任务
          final existingHistories = await _dbHelper.queryMediaGenerationHistory(
            isProcessing: true,
          );
          final existingHistory =
              existingHistories
                  .where((h) => h.taskId == taskId || h.requestId == taskId)
                  .toList();

          if (existingHistory.isNotEmpty) {
            // 如果已存在，则更新
            await _dbHelper.updateMediaGenerationHistoryByRequestId(taskId, {
              'isSuccess': 1,
              'isProcessing': 0,
              'isFailed': 0,
              'otherParams': mediaHistory.otherParams,
            });
          } else {
            // 如果不存在，则插入
            await _dbHelper.insertMediaGenerationHistory(mediaHistory);
          }
        }

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
      // 从本地存储中删除任务
      await _removeTaskInfo(taskId);

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
      final tasks = await _getLocalTaskInfos();
      // 按照创建时间倒序排序，最新的任务显示在前面
      tasks.sort(
        (a, b) => (b.gmtCreate ?? DateTime.now()).compareTo(
          a.gmtCreate ?? DateTime.now(),
        ),
      );
      return tasks;
    } catch (e) {
      debugPrint('获取录音识别任务列表失败: $e');
      return [];
    }
  }

  /// 上传音频文件到临时存储服务，返回可公开访问的URL
  /// 使用GitHub存储服务进行上传
  static Future<String> _uploadAudioFile(File audioFile) async {
    try {
      // 从存储中获取GitHub配置
      final storage = MyGetStorage();
      final githubUsername = storage.getGithubUsername();
      final githubRepo = storage.getGithubRepo();
      final githubToken = storage.getGithubToken();

      // 检查GitHub配置是否存在
      if (githubUsername.isEmpty || githubRepo.isEmpty || githubToken.isEmpty) {
        throw Exception('未配置GitHub存储，请在设置中配置GitHub用户名、仓库名和访问令牌');
      }

      // 创建GitHub存储服务
      final githubStorage = GitHubStorageService(
        username: githubUsername,
        repoName: githubRepo,
        accessToken: githubToken,
        targetDirectory: 'voice_recognition_audio',
      );

      // 验证GitHub凭证
      final isValid = await githubStorage.validateCredentials();
      if (!isValid) {
        throw Exception('GitHub凭证验证失败，请检查访问令牌是否有效');
      }

      // 确保目标目录存在
      await githubStorage.ensureDirectoryExists();

      // 上传文件并获取公开URL
      final fileUrl = await githubStorage.uploadFile(audioFile);

      return fileUrl;
    } catch (e) {
      throw Exception('上传音频文件失败：$e - 请确保GitHub配置正确');
    }
  }

  /// 从本地存储获取录音识别任务列表
  static Future<List<VoiceRecognitionTaskInfo>> _getLocalTaskInfos() async {
    try {
      final tasksData = box.read(_recognitionTasksKey);
      if (tasksData == null) return [];

      final tasksJson = tasksData as List<dynamic>;

      return tasksJson
          .map((json) => VoiceRecognitionTaskInfo.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('获取本地录音识别任务失败：$e');
      return [];
    }
  }

  /// 保存录音识别任务到本地存储
  static Future<void> _saveTaskInfo(VoiceRecognitionTaskInfo taskInfo) async {
    try {
      final tasks = await _getLocalTaskInfos();
      tasks.add(taskInfo);
      await _saveLocalTaskInfos(tasks);
    } catch (e) {
      debugPrint('保存录音识别任务到本地失败：$e');
    }
  }

  /// 更新本地存储中的录音识别任务
  static Future<void> _updateTaskInfo(
    VoiceRecognitionTaskInfo updatedTask,
  ) async {
    try {
      final tasks = await _getLocalTaskInfos();
      final index = tasks.indexWhere(
        (task) => task.taskId == updatedTask.taskId,
      );

      if (index != -1) {
        tasks[index] = updatedTask;
        await _saveLocalTaskInfos(tasks);
      } else {
        // 如果任务不存在，则添加
        await _saveTaskInfo(updatedTask);
      }
    } catch (e) {
      debugPrint('更新录音识别任务失败：$e');
    }
  }

  /// 从本地存储中删除录音识别任务
  static Future<void> _removeTaskInfo(String taskId) async {
    try {
      final tasks = await _getLocalTaskInfos();
      tasks.removeWhere((task) => task.taskId == taskId);
      await _saveLocalTaskInfos(tasks);
    } catch (e) {
      debugPrint('删除录音识别任务失败：$e');
    }
  }

  /// 保存录音识别任务列表到本地存储
  static Future<void> _saveLocalTaskInfos(
    List<VoiceRecognitionTaskInfo> tasks,
  ) async {
    try {
      final tasksJson = tasks.map((task) => task.toJson()).toList();
      await box.write(_recognitionTasksKey, tasksJson);
    } catch (e) {
      debugPrint('保存录音识别任务到本地失败：$e');
    }
  }

  /// 转换录音识别任务为MediaGenerationHistory (用于数据库存储)
  static MediaGenerationHistory _taskInfoToMediaGenerationHistory(
    VoiceRecognitionTaskInfo taskInfo,
  ) {
    // 创建一个包含识别结果的其他参数对象
    final otherParamsMap = {
      'recognizedText': taskInfo.recognizedText,
      'errorMessage': taskInfo.errorMessage,
      'fileUrl': taskInfo.audioFileUrl,
      'audioDuration': taskInfo.audioDurationMs,
    };

    return MediaGenerationHistory(
      requestId: taskInfo.taskId,
      taskId: taskInfo.taskId,
      prompt: taskInfo.languageHint ?? 'auto',
      refImageUrls: [],
      videoUrls: null,
      isSuccess: taskInfo.taskStatus == 'SUCCEEDED',
      isProcessing:
          taskInfo.taskStatus == 'RUNNING' || taskInfo.taskStatus == 'PENDING',
      isFailed: taskInfo.taskStatus == 'FAILED',
      otherParams: jsonEncode(otherParamsMap),
      gmtCreate: taskInfo.gmtCreate ?? DateTime.now(),
      llmSpec:
          taskInfo.llmSpec ??
          CusBriefLLMSpec(
            ApiPlatform.aliyun,
            'paraformer-v1',
            LLModelType.asr,
            cusLlmSpecId: const Uuid().v4(),
          ),
      modelType: LLModelType.asr,
    );
  }

  /// 通过任务ID获取录音识别任务
  static Future<VoiceRecognitionTaskInfo?> getRecognitionTaskById(
    String taskId,
  ) async {
    try {
      final tasks = await _getLocalTaskInfos();
      final task = tasks.firstWhere(
        (task) => task.taskId == taskId,
        orElse: () => throw Exception('未找到ID为 $taskId 的录音识别任务'),
      );
      return task;
    } catch (e) {
      debugPrint('获取录音识别任务失败: $e');
      return null;
    }
  }

  /// 根据选中的模型获取支持的语言列表
  /// https://help.aliyun.com/zh/model-studio/paraformer-recorded-speech-recognition-restful-api#1564da7efa42e
  static List<CusLabel> getLanguageOptions(CusBriefLLMSpec selectedModel) {
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
