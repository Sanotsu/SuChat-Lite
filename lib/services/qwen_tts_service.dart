import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../common/llm_spec/cus_brief_llm_model.dart';
import '../common/llm_spec/constant_llm_enum.dart';
import '../common/utils/dio_client/cus_http_client.dart';
import '../common/utils/dio_client/cus_http_request.dart';
import 'cus_get_storage.dart';

/// 通义千问语音合成服务
/// 基于REST API实现，支持流式和非流式合成
class QwenTtsService {
  // API端点
  static const String _apiBaseUrl =
      'https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation';

  /// 可用的音色
  static const List<Map<String, String>> availableVoices = [
    {'id': 'Cherry', 'name': 'Cherry', 'description': '中文女声'},
    {'id': 'Serena', 'name': 'Serena', 'description': '中文女声'},
    {'id': 'Ethan', 'name': 'Ethan', 'description': '中文男声'},
    {'id': 'Chelsie', 'name': 'Chelsie', 'description': '中英混合女声'},
  ];

  /// 获取API Key
  static Future<String> _getApiKey(CusBriefLLMSpec model) async {
    if (model.cusLlmSpecId.endsWith('_builtin')) {
      // 使用内置的 API Key
      throw Exception('不支持使用内置的API Key');
    } else {
      // 使用用户的 API Key
      final userKeys = MyGetStorage().getUserAKMap();
      String? apiKey = userKeys[ApiPlatformAKLabel.USER_ALIYUN_API_KEY.name];

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('未配置阿里云平台的 API Key');
      }
      return apiKey;
    }
  }

  /// 创建HTTP请求头
  static Future<Map<String, String>> _getHeaders(
    CusBriefLLMSpec model, {
    bool stream = false,
  }) async {
    final apiKey = await _getApiKey(model);
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    // 如果是流式输出，需要添加SSE请求头
    if (stream) {
      headers['X-DashScope-SSE'] = 'enable';
    }

    return headers;
  }

  /// 非流式生成语音并保存为文件
  /// 返回保存的文件路径
  static Future<String> generateVoice({
    required CusBriefLLMSpec model,
    required String text,
    String voice = 'Cherry', // 默认音色
    bool stream = false, // 是否使用流式输出
  }) async {
    if (model.platform != ApiPlatform.aliyun) {
      throw Exception('语音合成服务仅支持阿里云平台');
    }

    // 确保模型名称为qwen-tts
    if (!model.model.toLowerCase().contains('qwen-tts')) {
      throw Exception('此服务仅支持qwen-tts模型');
    }

    try {
      final headers = await _getHeaders(model, stream: stream);
      final requestBody = {
        'model': model.model,
        'input': {'text': text, 'voice': voice},
      };

      final tempDir = await getTemporaryDirectory();
      final fileName = 'qwen_tts_${DateTime.now().millisecondsSinceEpoch}.mp3';
      final outputFilePath = path.join(tempDir.path, fileName);

      if (stream) {
        // 流式处理
        return await _generateVoiceStream(headers, requestBody, outputFilePath);
      } else {
        // 非流式处理
        return await _generateVoiceNonStream(
          headers,
          requestBody,
          outputFilePath,
        );
      }
    } catch (e) {
      debugPrint('语音合成出错: $e');
      rethrow;
    }
  }

  /// 非流式方式生成语音
  static Future<String> _generateVoiceNonStream(
    Map<String, String> headers,
    Map<String, dynamic> requestBody,
    String outputFilePath,
  ) async {
    try {
      // 第一步：调用语音合成API获取音频URL
      debugPrint('开始请求语音合成API');
      final response = await HttpUtils.post(
        path: _apiBaseUrl,
        headers: headers,
        data: requestBody,
        responseType: CusRespType.json,
        showLoading: false,
        showErrorMessage: false,
      );

      // 从响应中提取音频URL
      final String? audioUrl = response['output']['audio']['url'];
      if (audioUrl == null || audioUrl.isEmpty) {
        throw Exception('未能获取到音频URL');
      }

      debugPrint('获取到音频URL: $audioUrl');

      // 使用直接的Dio实例下载音频内容并保存到文件
      final dio = Dio();
      try {
        final audioResponse = await dio.get(
          audioUrl,
          options: Options(
            responseType: ResponseType.bytes,
            followRedirects: true,
            validateStatus: (status) => status != null && status < 500,
          ),
          onReceiveProgress: (received, total) {
            if (total != -1) {
              debugPrint(
                '下载进度: ${(received / total * 100).toStringAsFixed(0)}%',
              );
            }
          },
        );

        if (audioResponse.statusCode != 200) {
          throw Exception('下载音频失败: ${audioResponse.statusCode}');
        }

        // 保存音频文件
        final outputFile = File(outputFilePath);
        await outputFile.writeAsBytes(audioResponse.data as List<int>);

        debugPrint('音频文件保存成功: $outputFilePath');
        return outputFilePath;
      } finally {
        dio.close();
      }
    } catch (e) {
      debugPrint('非流式生成语音出错: $e');
      rethrow;
    }
  }

  /// 流式方式生成语音
  static Future<String> _generateVoiceStream(
    Map<String, String> headers,
    Map<String, dynamic> requestBody,
    String outputFilePath,
  ) async {
    try {
      // 使用Dio发送流式请求
      final dio = Dio();
      final outputFile = File(outputFilePath);
      final outputSink = outputFile.openWrite();

      try {
        // 发送POST请求获取流式响应
        await dio
            .post(
              _apiBaseUrl,
              data: requestBody,
              options: Options(
                headers: headers,
                responseType: ResponseType.stream,
              ),
              onReceiveProgress: (received, total) {
                if (total != -1) {
                  debugPrint(
                    '流式下载进度: ${(received / total * 100).toStringAsFixed(0)}%',
                  );
                }
              },
            )
            .then((response) async {
              // 处理流式响应
              final Stream<List<int>> stream = response.data.stream;

              await for (final chunk in stream) {
                final String text = utf8.decode(chunk);
                final lines = text.split('\n');

                for (var line in lines) {
                  if (line.startsWith('data: ')) {
                    final jsonStr = line.substring(6).trim();
                    if (jsonStr == '[DONE]') continue;

                    try {
                      final jsonData = jsonDecode(jsonStr);
                      // 处理Base64音频数据
                      if (jsonData['output']?['audio']?['data'] != null) {
                        final base64Data = jsonData['output']['audio']['data'];
                        final audioBytes = base64Decode(base64Data);
                        outputSink.add(audioBytes);
                      }
                    } catch (e) {
                      debugPrint('解析SSE数据出错: $e');
                    }
                  }
                }
              }
            });

        await outputSink.flush();
        await outputSink.close();

        return outputFilePath;
      } catch (e) {
        debugPrint('流式请求出错: $e');
        rethrow;
      } finally {
        await outputSink.close();
        dio.close();
      }
    } catch (e) {
      debugPrint('流式生成语音出错: $e');
      rethrow;
    }
  }

  /// 流式生成语音
  /// 返回音频数据流
  static Stream<Uint8List> streamVoice({
    required CusBriefLLMSpec model,
    required String text,
    String voice = 'Cherry', // 默认音色
  }) async* {
    if (model.platform != ApiPlatform.aliyun) {
      throw Exception('语音合成服务仅支持阿里云平台');
    }

    // 确保模型名称为qwen-tts
    if (!model.model.toLowerCase().contains('qwen-tts')) {
      throw Exception('此服务仅支持qwen-tts模型');
    }

    final headers = await _getHeaders(model, stream: true);
    final requestBody = {
      'model': 'qwen-tts',
      'input': {'text': text, 'voice': voice},
    };

    final streamController = StreamController<Uint8List>();

    try {
      // 使用Dio发送流式请求
      final dio = Dio();

      try {
        // 发送POST请求获取流式响应
        dio
            .post(
              _apiBaseUrl,
              data: requestBody,
              options: Options(
                headers: headers,
                responseType: ResponseType.stream,
              ),
            )
            .then((response) {
              // 处理流式响应
              final Stream<List<int>> stream = response.data.stream;

              stream.listen(
                (chunk) {
                  final String text = utf8.decode(chunk);
                  final lines = text.split('\n');

                  for (var line in lines) {
                    if (line.startsWith('data: ')) {
                      final jsonStr = line.substring(6).trim();
                      if (jsonStr == '[DONE]') continue;

                      try {
                        final jsonData = jsonDecode(jsonStr);
                        // 处理Base64音频数据
                        if (jsonData['output']?['audio']?['data'] != null) {
                          final base64Data =
                              jsonData['output']['audio']['data'];
                          final audioBytes = base64Decode(base64Data);
                          streamController.add(Uint8List.fromList(audioBytes));
                        }
                      } catch (e) {
                        debugPrint('解析SSE数据出错: $e');
                      }
                    }
                  }
                },
                onError: (error) {
                  if (!streamController.isClosed) {
                    streamController.addError(error);
                    streamController.close();
                  }
                  dio.close();
                },
                onDone: () {
                  if (!streamController.isClosed) {
                    streamController.close();
                  }
                  dio.close();
                },
              );
            })
            .catchError((error) {
              if (!streamController.isClosed) {
                streamController.addError(error);
                streamController.close();
              }
              dio.close();
            });

        yield* streamController.stream;
      } finally {
        dio.close();
      }
    } catch (e) {
      if (!streamController.isClosed) {
        streamController.addError(e);
        streamController.close();
      }
      rethrow;
    }
  }
}
