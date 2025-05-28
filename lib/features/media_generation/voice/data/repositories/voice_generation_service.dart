import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import '../../../../../core/entities/cus_llm_model.dart';
import '../../../../../shared/constants/constant_llm_enum.dart';
import '../../../../../core/storage/db_helper.dart';
import '../../../../../core/storage/cus_get_storage.dart';
import '../datasources/aliyun_voice_list.dart';

class AliyunVoiceType {
  // 这几个是选择时用到，会构建请求参数
  final String name;
  final String id;
  final String scene;
  // 试听时看到的
  final String sampleName;
  final String sampleUrl;
  final String sampleType;

  AliyunVoiceType(
    this.name,
    this.id,
    this.scene,
    this.sampleName,
    this.sampleUrl,
    this.sampleType,
  );

  // 新增copyWith方法
  AliyunVoiceType copyWith({
    String? name,
    String? id,
    String? scene,
    String? sampleName,
    String? sampleUrl,
    String? sampleType,
  }) {
    return AliyunVoiceType(
      name ?? this.name,
      id ?? this.id,
      scene ?? this.scene,
      sampleName ?? this.sampleName,
      sampleUrl ?? this.sampleUrl,
      sampleType ?? this.sampleType,
    );
  }
}

/// 阿里云语音合成服务
/// 使用WebSocket实现，支持实时流式合成
class VoiceGenerationService {
  static const String _wsUrl =
      'wss://dashscope.aliyuncs.com/api-ws/v1/inference';
  static const int _defaultSampleRate = 22050;
  static const String _defaultFormat = 'mp3';

  /// 获取API Key
  static Future<String> _getApiKey(CusLLMSpec model) async {
    if (model.cusLlmSpecId.endsWith('_builtin')) {
      // 使用内置的 API Key
      throw Exception('不支持使用内置的API Key');
    } else {
      // 使用用户的 API Key
      final userKeys = CusGetStorage().getUserAKMap();
      String? apiKey = userKeys[ApiPlatformAKLabel.USER_ALIYUN_API_KEY.name];

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('未配置阿里云平台的 API Key');
      }
      return apiKey;
    }
  }

  /// 创建WebSocket连接的请求头
  static Future<Map<String, String>> _getHeaders(CusLLMSpec model) async {
    final apiKey = await _getApiKey(model);
    return {
      "Authorization": "bearer $apiKey",
      "X-DashScope-DataInspection": "enable",
    };
  }

  /// 生成语音并保存为文件
  /// 返回保存的文件路径
  static Future<String> generateVoice({
    required CusLLMSpec model,
    required String text,
    String voice = 'longxiaochun_v2', // 默认音色
    String format = _defaultFormat,
    int sampleRate = _defaultSampleRate,
    int? volume, // 音量 0-100
    double? rate, // 语速 0.5-2.0
    double? pitch, // 音调 0.5-2.0
    bool? wordTimestampEnabled, // Sambert特有参数：是否启用单词时间戳
    bool? phonemeTimestampEnabled, // Sambert特有参数：是否启用音素时间戳
  }) async {
    if (model.platform != ApiPlatform.aliyun) {
      throw Exception('语音合成服务仅支持阿里云平台');
    }

    final headers = await _getHeaders(model);
    final taskId = const Uuid().v4();
    final tempDir = await getTemporaryDirectory();
    final outputFilePath = path.join(tempDir.path, 'voice_$taskId.$format');

    final outputFile = File(outputFilePath);
    if (await outputFile.exists()) {
      await outputFile.delete();
    }

    final outputSink = outputFile.openWrite();
    final completer = Completer<String>();
    WebSocketChannel? ws;

    try {
      ws = IOWebSocketChannel.connect(Uri.parse(_wsUrl), headers: headers);

      // 监听WebSocket消息
      ws.stream.listen(
        (message) async {
          try {
            if (message is List<int>) {
              // 二进制数据 - 音频流
              outputSink.add(message);
            } else if (message is String) {
              final jsonMsg = jsonDecode(message);
              debugPrint('============>');
              debugPrint('$jsonMsg');

              if (jsonMsg['header']['event'] == 'task-started') {
                debugPrint('任务已开始');

                // 对于 Sambert 模型，不需要后续发送任何消息
                if (_isCosyVoice(model.model)) {
                  debugPrint('发送文本给Cosy模型');
                  // 对于 CosyVoice，需要发送文本和结束消息
                  final continueTaskMessage = jsonEncode({
                    'header': {
                      'action': 'continue-task',
                      'task_id': taskId,
                      'streaming': 'duplex',
                    },
                    'payload': {
                      'input': {'text': text},
                    },
                  });
                  ws?.sink.add(continueTaskMessage);

                  // 结束任务
                  final finishTaskMessage = jsonEncode({
                    'header': {
                      'action': 'finish-task',
                      'task_id': taskId,
                      'streaming': 'duplex',
                    },
                    'payload': {'input': {}},
                  });
                  ws?.sink.add(finishTaskMessage);
                }
              } else if (jsonMsg['header']['event'] == 'task-finished') {
                debugPrint('任务已完成');
                await outputSink.flush();
                await outputSink.close();
                if (!completer.isCompleted) {
                  completer.complete(outputFilePath);
                }
              } else if (jsonMsg['header']['event'] == 'task-failed') {
                final errorMessage =
                    jsonMsg['header']['error_message'] ?? '语音合成失败';
                debugPrint('任务失败: $errorMessage');

                if (!completer.isCompleted) {
                  completer.completeError(Exception(errorMessage));
                }
              }
            }
          } catch (e) {
            debugPrint('处理消息时出错: $e');
            if (!completer.isCompleted) {
              completer.completeError(e);
            }
          }
        },
        onError: (error) {
          debugPrint('WebSocket错误: $error');
          outputSink.close();
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
        onDone: () {
          debugPrint('WebSocket连接已关闭');
          outputSink.close();
          if (!completer.isCompleted) {
            completer.completeError(Exception('WebSocket连接已关闭'));
          }
        },
      );

      // 发送初始化任务消息
      final runTaskMessage = _buildRunTaskMessage(
        taskId: taskId,
        model: model.model,
        voice: voice,
        text: _isSambert(model.model) ? text : null, // Sambert模型直接在初始消息中发送文本
        format: format,
        sampleRate: sampleRate,
        volume: volume,
        rate: rate,
        pitch: pitch,
        wordTimestampEnabled: wordTimestampEnabled,
        phonemeTimestampEnabled: phonemeTimestampEnabled,
      );

      debugPrint('开始发送初始化指令$runTaskMessage');
      ws.sink.add(runTaskMessage);
      debugPrint('发送完了');

      // 等待完成或超时
      return await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('语音合成超时');
          if (!completer.isCompleted) {
            completer.completeError(Exception('语音合成超时'));
          }
          ws?.sink.close();
          outputSink.close();
          throw Exception('语音合成超时');
        },
      );
    } catch (e) {
      debugPrint('发生异常: $e');
      await outputSink.close();
      ws?.sink.close();
      if (await outputFile.exists()) {
        await outputFile.delete();
      }
      rethrow;
    }
  }

  /// 流式生成语音
  /// 返回音频数据流
  static Stream<Uint8List> streamVoice({
    required CusLLMSpec model,
    required String text,
    String voice = 'longxiaochun_v2', // 默认音色
    String format = _defaultFormat,
    int sampleRate = _defaultSampleRate,
    int? volume, // 音量 0-100
    double? rate, // 语速 0.5-2.0
    double? pitch, // 音调 0.5-2.0
    bool? wordTimestampEnabled, // Sambert特有参数
    bool? phonemeTimestampEnabled, // Sambert特有参数
  }) async* {
    if (model.platform != ApiPlatform.aliyun) {
      throw Exception('语音合成服务仅支持阿里云平台');
    }

    final headers = await _getHeaders(model);
    final taskId = const Uuid().v4();

    final streamController = StreamController<Uint8List>();
    WebSocketChannel? ws;

    try {
      ws = IOWebSocketChannel.connect(Uri.parse(_wsUrl), headers: headers);

      // 监听WebSocket消息
      ws.stream.listen(
        (message) {
          try {
            if (message is List<int>) {
              // 二进制数据 - 音频流
              streamController.add(Uint8List.fromList(message));
            } else if (message is String) {
              final jsonMsg = jsonDecode(message);

              if (jsonMsg['header']['event'] == 'task-started') {
                // 对于 Sambert 模型，不需要发送任何后续消息
                if (_isCosyVoice(model.model)) {
                  // 对于 CosyVoice，需要发送文本和结束消息
                  final continueTaskMessage = jsonEncode({
                    'header': {
                      'action': 'continue-task',
                      'task_id': taskId,
                      'streaming': 'duplex',
                    },
                    'payload': {
                      'input': {'text': text},
                    },
                  });
                  ws?.sink.add(continueTaskMessage);

                  // 结束任务
                  final finishTaskMessage = jsonEncode({
                    'header': {
                      'action': 'finish-task',
                      'task_id': taskId,
                      'streaming': 'duplex',
                    },
                    'payload': {'input': {}},
                  });
                  ws?.sink.add(finishTaskMessage);
                }
              } else if (jsonMsg['header']['event'] == 'task-finished') {
                if (!streamController.isClosed) {
                  streamController.close();
                }
              } else if (jsonMsg['header']['event'] == 'task-failed') {
                final errorMessage =
                    jsonMsg['header']['error_message'] ?? '语音合成失败';
                if (!streamController.isClosed) {
                  streamController.addError(Exception(errorMessage));
                  streamController.close();
                }
              }
            }
          } catch (e) {
            if (!streamController.isClosed) {
              streamController.addError(e);
              streamController.close();
            }
          }
        },
        onError: (error) {
          if (!streamController.isClosed) {
            streamController.addError(error);
            streamController.close();
          }
        },
        onDone: () {
          if (!streamController.isClosed) {
            streamController.close();
          }
        },
      );

      // 发送初始化任务消息
      final runTaskMessage = _buildRunTaskMessage(
        taskId: taskId,
        model: model.model,
        voice: voice,
        text: _isSambert(model.model) ? text : null, // Sambert模型直接在初始消息中发送文本
        format: format,
        sampleRate: sampleRate,
        volume: volume,
        rate: rate,
        pitch: pitch,
        wordTimestampEnabled: wordTimestampEnabled,
        phonemeTimestampEnabled: phonemeTimestampEnabled,
      );

      ws.sink.add(runTaskMessage);

      yield* streamController.stream;
    } catch (e) {
      ws?.sink.close();
      if (!streamController.isClosed) {
        streamController.addError(e);
        streamController.close();
      }
      rethrow;
    }
  }

  /// 分段文本流式生成语音
  /// 当有大段文本需要合成时，可以分段发送，适合边合成边播放的场景
  /// 注意：分段文本仅适用于CosyVoice模型，Sambert模型无法使用此功能
  static Stream<Uint8List> streamLongText({
    required CusLLMSpec model,
    required List<String> textSegments,
    Duration segmentDelay = const Duration(milliseconds: 500), // 每段文本之间的延迟
    String voice = 'longxiaochun_v2', // 默认音色
    String format = _defaultFormat,
    int sampleRate = _defaultSampleRate,
    int? volume, // 音量 0-100
    double? rate, // 语速 0.5-2.0
    double? pitch, // 音调 0.5-2.0
  }) async* {
    if (model.platform != ApiPlatform.aliyun) {
      throw Exception('语音合成服务仅支持阿里云平台');
    }

    if (_isSambert(model.model)) {
      throw Exception('Sambert模型不支持分段文本合成');
    }

    final headers = await _getHeaders(model);
    final taskId = const Uuid().v4();

    final streamController = StreamController<Uint8List>();
    WebSocketChannel? ws;

    try {
      ws = IOWebSocketChannel.connect(Uri.parse(_wsUrl), headers: headers);

      int segmentIndex = 0;

      // 发送下一段文本
      void sendNextSegment() {
        if (segmentIndex >= textSegments.length) {
          // 所有文本段都已发送，结束任务
          final finishTaskMessage = jsonEncode({
            'header': {
              'action': 'finish-task',
              'task_id': taskId,
              'streaming': 'duplex',
            },
            'payload': {'input': {}},
          });
          ws?.sink.add(finishTaskMessage);
          return;
        }

        // 发送当前段落
        final continueTaskMessage = jsonEncode({
          'header': {
            'action': 'continue-task',
            'task_id': taskId,
            'streaming': 'duplex',
          },
          'payload': {
            'input': {'text': textSegments[segmentIndex]},
          },
        });
        ws?.sink.add(continueTaskMessage);
        segmentIndex++;

        // 延迟发送下一段
        if (segmentIndex < textSegments.length) {
          Future.delayed(segmentDelay, sendNextSegment);
        } else {
          // 最后一段发送完毕，等待一段时间后结束任务
          Future.delayed(const Duration(seconds: 1), () {
            final finishTaskMessage = jsonEncode({
              'header': {
                'action': 'finish-task',
                'task_id': taskId,
                'streaming': 'duplex',
              },
              'payload': {'input': {}},
            });
            ws?.sink.add(finishTaskMessage);
          });
        }
      }

      // 监听WebSocket消息
      ws.stream.listen(
        (message) {
          try {
            if (message is List<int>) {
              // 二进制数据 - 音频流
              streamController.add(Uint8List.fromList(message));
            } else if (message is String) {
              final jsonMsg = jsonDecode(message);

              if (jsonMsg['header']['event'] == 'task-started') {
                // 开始发送第一段文本
                sendNextSegment();
              } else if (jsonMsg['header']['event'] == 'task-finished') {
                if (!streamController.isClosed) {
                  streamController.close();
                }
              } else if (jsonMsg['header']['event'] == 'task-failed') {
                final errorMessage =
                    jsonMsg['header']['error_message'] ?? '语音合成失败';
                if (!streamController.isClosed) {
                  streamController.addError(Exception(errorMessage));
                  streamController.close();
                }
              }
            }
          } catch (e) {
            if (!streamController.isClosed) {
              streamController.addError(e);
              streamController.close();
            }
          }
        },
        onError: (error) {
          if (!streamController.isClosed) {
            streamController.addError(error);
            streamController.close();
          }
        },
        onDone: () {
          if (!streamController.isClosed) {
            streamController.close();
          }
        },
      );

      // 发送初始化任务消息
      final runTaskMessage = _buildRunTaskMessage(
        taskId: taskId,
        model: model.model,
        voice: voice,
        format: format,
        sampleRate: sampleRate,
        volume: volume,
        rate: rate,
        pitch: pitch,
      );

      ws.sink.add(runTaskMessage);

      yield* streamController.stream;
    } catch (e) {
      ws?.sink.close();
      if (!streamController.isClosed) {
        streamController.addError(e);
        streamController.close();
      }
      rethrow;
    }
  }

  /// 判断是否为CosyVoice模型
  static bool _isCosyVoice(String model) {
    return model.toLowerCase().contains('cosy');
  }

  /// 判断是否为Sambert模型
  static bool _isSambert(String model) {
    return model.toLowerCase().contains('sambert');
  }

  /// 构建任务初始化消息
  /// 根据模型类型构建不同的消息格式
  static String _buildRunTaskMessage({
    required String taskId,
    required String model,
    required String voice,
    String? text, // Sambert模型需要在初始消息中提供文本
    String? format,
    int? sampleRate,
    int? volume,
    double? rate,
    double? pitch,
    bool? wordTimestampEnabled, // Sambert特有参数
    bool? phonemeTimestampEnabled, // Sambert特有参数
  }) {
    final bool isSambert = _isSambert(model);
    final Map<String, dynamic> baseMessage = {
      'header': {
        'action': 'run-task',
        'task_id': taskId,
        // Sambert使用out，CosyVoice使用duplex
        'streaming': isSambert ? 'out' : 'duplex',
      },
      'payload': {
        'model': isSambert ? '$model-$voice-v1' : model,
        'task_group': 'audio',
        'task': 'tts',
        'function': 'SpeechSynthesizer',
        'parameters': {
          'text_type': 'PlainText',
          'format': format ?? 'mp3',
          // Sambert默认使用16000采样率
          'sample_rate': sampleRate ?? (isSambert ? 16000 : 22050),
          'volume': volume ?? 50,
          'rate': rate ?? 1.0,
          'pitch': pitch ?? 1.0,
        },
        'input': {},
      },
    };

    final Map<String, dynamic> parameters =
        (baseMessage['payload'] as Map<String, dynamic>)['parameters']
            as Map<String, dynamic>;

    // 针对Sambert模型的特殊处理
    if (isSambert) {
      // 添加Sambert特有参数
      if (wordTimestampEnabled != null) {
        parameters['word_timestamp_enabled'] = wordTimestampEnabled;
      }

      if (phonemeTimestampEnabled != null) {
        parameters['phoneme_timestamp_enabled'] = phonemeTimestampEnabled;
      }

      // Sambert 需要在初始消息中提供文本
      if (text != null) {
        (baseMessage['payload'] as Map<String, dynamic>)['input'] = {
          'text': text,
        };
      }
    }

    // Sambert默认 parameters中不需要音色参数，因为是拼在model中，但cosy中是必要的
    if (!isSambert) {
      parameters['voice'] = voice;
    }

    return jsonEncode(baseMessage);
  }

  /// 获取V1版本可用音色列表
  /// v2中的音色都在v1里面，但是id需要_v2后缀，可v1版本不需要，所以分开
  static List<AliyunVoiceType> getV1AvailableVoices() {
    return AliyunVoiceList.cosyVoiceV1List + AliyunVoiceList.cosyVoiceV2List;
  }

  /// 获取V2版本可用音色列表
  static List<AliyunVoiceType> getV2AvailableVoices() {
    return AliyunVoiceList.cosyVoiceV2List
        .map((e) => e.copyWith(id: "${e.id}_v2"))
        .toList();
  }

  /// 获取Sambert模型可用音色列表
  static List<AliyunVoiceType> getSambertVoices() {
    return AliyunVoiceList.sambertList;
  }

  /// 获取QwenTTS模型可用音色列表
  static List<AliyunVoiceType> getQwenTTSVoices() {
    return AliyunVoiceList.qwenTTSList;
  }

  /// 获取可用的语音合成模型列表
  static Future<List<CusLLMSpec>> getAvailableTtsModels() async {
    // 从数据库或缓存中获取用户配置的模型
    final dbHelper = DBHelper();
    return await dbHelper.queryCusLLMSpecList(
      modelType: LLModelType.tts,
      platform: ApiPlatform.aliyun, // 当前只支持阿里云平台
    );
  }
}
