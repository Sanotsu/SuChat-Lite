// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:math' as math;
import 'package:dio/dio.dart';

/// 自定义日志拦截器，支持对嵌套参数值进行长度限制
class CustomLogInterceptor extends Interceptor {
  /// 需要截断的敏感字段名列表
  final List<String> sensitiveKeys;

  /// 截断长度，默认50个字符
  final int truncateLength;

  /// 截断标识符
  final String truncateIndicator;

  /// 是否启用请求日志
  final bool requestEnabled;

  /// 是否启用响应日志
  final bool responseEnabled;

  /// 是否启用错误日志
  final bool errorEnabled;

  /// 日志最大宽度
  final int maxWidth;

  CustomLogInterceptor({
    this.sensitiveKeys = const ['url', 'video_url', 'audio_url', 'data'],
    this.truncateLength = 50,
    this.truncateIndicator = '……[截断][TRUNCATED]',
    this.requestEnabled = true,
    this.responseEnabled = true,
    this.errorEnabled = true,
    this.maxWidth = 100,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (requestEnabled) {
      _logRequest(options);
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (responseEnabled) {
      _logResponse(response);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (errorEnabled) {
      _logError(err);
    }
    handler.next(err);
  }

  void _logRequest(RequestOptions options) {
    final uri = options.uri;
    final method = options.method.toUpperCase();

    print('');
    print('╔╣ Custom Request ║ $method ');
    print('║  $uri');
    print('╚${'═' * math.min(maxWidth, uri.toString().length + 10)}╝');

    // 打印Headers
    if (options.headers.isNotEmpty) {
      print('╔ Headers ');
      options.headers.forEach((key, value) {
        print('╟ $key: $value');
      });
      print('╚${'═' * maxWidth}╝');
    }

    // 打印Body（关键部分：处理嵌套数据截断）
    if (options.data != null) {
      print('╔ Body ');
      final processedData = _processDataForLog(options.data);
      final jsonString = _formatJson(processedData);
      _safePrint(jsonString);
      print('╚${'═' * maxWidth}╝');
    }
  }

  void _logResponse(Response response) {
    final uri = response.requestOptions.uri;
    final method = response.requestOptions.method.toUpperCase();
    final statusCode = response.statusCode;
    final statusMessage = response.statusMessage ?? '';

    print('');
    print('╔╣ Custom Response ║ $method ║ Status: $statusCode $statusMessage');
    print('║  $uri');
    print('╚${'═' * maxWidth}╝');

    // 打印Headers
    if (response.headers.map.isNotEmpty) {
      print('╔ Headers ');
      response.headers.map.forEach((key, value) {
        print('╟ $key: $value');
      });
      print('╚${'═' * maxWidth}╝');
    }

    // 打印Body
    if (response.data != null) {
      print('╔ Body');
      print('║');
      final responseBody = response.data.toString();
      if (responseBody.length > 1000) {
        print('║ ${responseBody.substring(0, 1000)}...[响应过长，已截断]');
      } else {
        print('║ $responseBody');
      }
      print('║');
      print('╚${'═' * maxWidth}╝');
    }
  }

  void _logError(DioException err) {
    print('');
    print('╔╣ Custom Error ║ ${err.type}');
    if (err.response != null) {
      print('║  ${err.response!.requestOptions.uri}');
      print(
        '║  Status: ${err.response!.statusCode} ${err.response!.statusMessage}',
      );
    }
    print('╟ Message: ${err.message}');
    print('╚${'═' * maxWidth}╝');
  }

  /// 处理数据，对敏感字段进行截断（仅用于日志显示，不影响原始数据）
  dynamic _processDataForLog(dynamic data) {
    if (data == null) return null;

    if (data is Map<String, dynamic>) {
      final Map<String, dynamic> processedMap = {};
      data.forEach((key, value) {
        if (sensitiveKeys.contains(key) &&
            value is String &&
            value.length > truncateLength) {
          // 对敏感字段进行截断
          processedMap[key] =
              '${value.substring(0, truncateLength)}$truncateIndicator';
        } else if (value is Map || value is List) {
          // 递归处理嵌套对象
          processedMap[key] = _processDataForLog(value);
        } else {
          processedMap[key] = value;
        }
      });
      return processedMap;
    } else if (data is List) {
      return data.map((item) => _processDataForLog(item)).toList();
    } else if (data is String) {
      try {
        // 尝试解析JSON字符串
        final decoded = jsonDecode(data);
        final processed = _processDataForLog(decoded);
        return jsonEncode(processed);
      } catch (e) {
        // 如果不是JSON字符串，直接返回
        return data;
      }
    }

    return data;
  }

  /// 格式化JSON输出
  String _formatJson(dynamic data) {
    try {
      if (data is String) {
        // 如果已经是字符串，尝试解析后重新格式化
        try {
          final decoded = jsonDecode(data);
          return const JsonEncoder.withIndent('  ').convert(decoded);
        } catch (e) {
          return data;
        }
      } else {
        return const JsonEncoder.withIndent('  ').convert(data);
      }
    } catch (e) {
      return data.toString();
    }
  }

  /// 安全打印长文本，避免Flutter print长度限制
  void _safePrint(String text, {String prefix = '╟ '}) {
    const int maxLength = 800; // Flutter print的安全长度限制

    if (text.length <= maxLength) {
      print('$prefix$text');
      return;
    }

    // 按行分割并逐行打印
    final lines = text.split('\n');
    for (final line in lines) {
      if (line.length <= maxLength) {
        print('$prefix$line');
      } else {
        // 如果单行还是太长，按字符分段
        for (int i = 0; i < line.length; i += maxLength) {
          final end = math.min(i + maxLength, line.length);
          final segment = line.substring(i, end);
          print('$prefix$segment');
        }
      }
    }
  }
}
