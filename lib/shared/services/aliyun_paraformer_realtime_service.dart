import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';

import '../../features/translator/data/models/aliyun_asr_realtime_models.dart';

///
/// 阿里云实时语音识别的 ws API 服务
///  快速翻译模块、统一对话的语音输入模块会用到
///
class AliyunParaformerRealtimeService {
  static const String _speechRecognitionWsUrl =
      'wss://dashscope.aliyuncs.com/api-ws/v1/inference';

  WebSocketChannel? _wsChannel;
  StreamController<AsrRtResult>? _recognitionController;
  String? _currentTaskId;
  bool _taskStarted = false;

  AliyunParaformerRealtimeService();

  /// 初始化语音识别WebSocket连接
  Future<Stream<AsrRtResult>> initSpeechRecognition({
    required String apiKey,
    String modelName = "paraformer-realtime-v2",
    AsrRtParameter? params,
  }) async {
    try {
      // 关闭之前的连接
      await _closeSpeechRecognition();

      _recognitionController = StreamController<AsrRtResult>.broadcast();
      _taskStarted = false;

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
        // 模型用默认的
        model: modelName,
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

  /// 释放资源
  void dispose() {
    _closeSpeechRecognition();
  }
}
