import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/entities/cus_llm_model.dart';
import '../../../../core/utils/datetime_formatter.dart';
import '../../../../core/utils/get_dir.dart';
import '../../../../shared/services/translation_service.dart';
import '../../../branch_chat/data/services/chat_service.dart';
import '../../../media_generation/voice/data/repositories/qwen_tts_service.dart';
import '../../../media_generation/voice/data/repositories/voice_generation_service.dart';
import '../models/aliyun_asr_realtime_models.dart';

/// 阿里云API客户端
///
/// 注意:
/// 翻译有现成的服务 SimpleTranslateTool
/// 语音合成有现成的服务 QwenTtsService
/// 录音文件识别有现成的服务 VoiceRecognitionService (暂未用到)
/// 所以这里主要需要实现实时语音识别的 ws API 服务，并调用其他服务方法
///
class AliyunTranslatorApiClient {
  static const String _speechRecognitionWsUrl =
      'wss://dashscope.aliyuncs.com/api-ws/v1/inference';

  WebSocketChannel? _wsChannel;
  StreamController<AsrRtResult>? _recognitionController;
  String? _currentTaskId;
  bool _taskStarted = false;

  AliyunTranslatorApiClient();

  /// 初始化语音识别WebSocket连接
  Future<Stream<AsrRtResult>> initSpeechRecognition({
    required CusLLMSpec model,
    AsrRtParameter? params,
  }) async {
    try {
      // 关闭之前的连接
      await _closeSpeechRecognition();

      _recognitionController = StreamController<AsrRtResult>.broadcast();
      _taskStarted = false;

      // 这个只是为了拿到用户的阿里云密钥，模型没用到
      final String apiKey = await ChatService.getApiKey(model);

      // 建立WebSocket连接
      final uri = Uri.parse(_speechRecognitionWsUrl);
      _wsChannel = IOWebSocketChannel.connect(
        uri,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'X-DashScope-DataInspection': 'enable',
        },
      );

      // 监听WebSocket消息
      _wsChannel!.stream.listen(
        (data) {
          // print("监听识别的listem时的数据 $data");
          try {
            final jsonData = jsonDecode(data.toString());
            final response = AsrRtResult.fromJson(jsonData);

            // 处理不同类型的事件
            if (response.isTaskStarted) {
              _taskStarted = true;
              debugPrint('语音识别任务已启动: ${response.taskId}');
            } else if (response.isResultGenerated) {
              // 跳过心跳消息
              if (!response.shouldSkip &&
                  response.text != null &&
                  response.text!.isNotEmpty) {
                debugPrint('识别结果: ${response.text}');
              }
            } else if (response.isTaskFinished) {
              debugPrint('语音识别任务已完成');
              _taskStarted = false;
            } else if (response.isTaskFailed) {
              debugPrint('语音识别任务失败: ${response.errorMessage}');
              _taskStarted = false;
            }

            _recognitionController?.add(response);
          } catch (e) {
            debugPrint('解析WebSocket消息失败: $e');
            _recognitionController?.addError(e);
          }
        },
        onError: (error) {
          debugPrint('WebSocket连接错误: $error');
          _recognitionController?.addError(error);
          _taskStarted = false;
        },
        onDone: () {
          debugPrint('WebSocket连接已关闭');
          _recognitionController?.close();
          _taskStarted = false;
        },
      );

      // 等待连接建立后发送初始化消息
      await Future.delayed(const Duration(milliseconds: 100));

      // 生成任务ID并发送run-task指令
      _currentTaskId = TaskIdGenerator.generate();
      final configToUse = params ?? AsrRtParameter();
      final initMessage = AsrRtMessage.runTask(
        model: model.model,
        taskId: _currentTaskId!,
        params: configToUse,
      );

      debugPrint('发送run-task指令: ${jsonEncode(initMessage.toJson())}');
      _wsChannel!.sink.add(jsonEncode(initMessage.toJson()));

      return _recognitionController!.stream;
    } catch (e) {
      debugPrint('初始化语音识别失败: $e');
      throw Exception('初始化语音识别失败: $e');
    }
  }

  /// 完成语音识别
  void finishSpeechRecognition() {
    if (_wsChannel != null && _currentTaskId != null && _taskStarted) {
      final finishMessage = AsrRtMessage.finishTask(_currentTaskId!);
      debugPrint('发送finish-task指令: ${jsonEncode(finishMessage.toJson())}');
      _wsChannel!.sink.add(jsonEncode(finishMessage.toJson()));
    }
  }

  /// 发送音频数据
  void sendAudioData(Uint8List audioData) {
    if (_wsChannel != null && _taskStarted && audioData.isNotEmpty) {
      _wsChannel!.sink.add(audioData);
    }
  }

  /// 检查任务是否已启动
  bool get isTaskStarted => _taskStarted;

  /// 结束语音识别
  Future<void> endSpeechRecognition() async {
    if (_wsChannel == null) return;

    try {
      // 先发送finish-task指令
      finishSpeechRecognition();

      // 等待一段时间让服务器处理
      await Future.delayed(const Duration(milliseconds: 500));

      // 关闭连接
      await _closeSpeechRecognition();
    } catch (e) {
      debugPrint('结束语音识别失败: $e');
    }
  }

  /// 关闭语音识别连接
  Future<void> _closeSpeechRecognition() async {
    try {
      await _wsChannel?.sink.close();
    } catch (e) {
      debugPrint('关闭WebSocket失败: $e');
    }

    _wsChannel = null;
    _currentTaskId = null;
    _taskStarted = false;

    try {
      await _recognitionController?.close();
    } catch (e) {
      debugPrint('关闭识别控制器失败: $e');
    }

    _recognitionController = null;
  }

  /// 翻译文本
  Future<String> translateText(
    String text,
    CusLLMSpec model,
    TargetLanguage targetLanguage, {
    TargetLanguage? sourceLang,
  }) async {
    try {
      String translation = await TranslationService.translate(
        text,
        targetLanguage,
        sourceLang: sourceLang,
        model: model,
      );

      debugPrint("翻译响应结果: $translation");

      return translation;
    } catch (e) {
      debugPrint('翻译未知错误: $e');
      rethrow;
    }
  }

  /// 语音合成
  Future<String> synthesizeSpeech(
    String text,
    CusLLMSpec model,
    AliyunVoiceType voiceType,
  ) async {
    try {
      // 生成语音
      String voicePath = await QwenTtsService.generateVoice(
        model: model,
        text: text,
        voice: voiceType.id,
      );

      final voiceDir = await getTranslatorVoiceGenDir();
      if (!await voiceDir.exists()) {
        await voiceDir.create(recursive: true);
      }

      // 生成文件名，使用模型名、时间戳、文本标题
      final timestamp = fileTs(DateTime.now());

      // 移除所有空白字符(制表符、换行符等)
      // var title = text.trim().replaceAll(RegExp(r'\s+'), '');
      var title = text
          .trim()
          .replaceAll(RegExp(r'[^\w\s\u4e00-\u9fa5]'), '') // 移除非单词字符、非空格、非中文
          .replaceAll(RegExp(r'\s+'), ''); // 合并多余空格

      title = title.length > 10 ? title.substring(0, 10) : title;

      final filename =
          '${model.model}_${voiceType.name}_${timestamp}_$title.mp3';

      final outputPath = path.join(voiceDir.path, filename);

      // 复制到目标目录
      await File(voicePath).copy(outputPath);

      return outputPath;
    } catch (e) {
      debugPrint('语音合成未知错误: $e');
      rethrow;
    }
  }

  /// 释放资源
  void dispose() {
    _closeSpeechRecognition();
  }
}
