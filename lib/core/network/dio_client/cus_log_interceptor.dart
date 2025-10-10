// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:typed_data';
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

  /// 二进制数据最大显示长度（字节数）
  final int binaryMaxDisplayLength;

  CustomLogInterceptor({
    this.sensitiveKeys = const ['url', 'video_url', 'audio_url', 'data'],
    this.truncateLength = 50,
    this.truncateIndicator = '……[截断][TRUNCATED]',
    this.requestEnabled = true,
    this.responseEnabled = true,
    this.errorEnabled = true,
    this.maxWidth = 100,
    this.binaryMaxDisplayLength = 30, // 默认显示前30个字节
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

    // 打印Body - 关键修改：识别二进制数据
    if (response.data != null) {
      print('╔ Body');
      print('║');

      if (_isBinaryData(response.data)) {
        // 处理二进制数据
        _logBinaryData(response.data);
      } else {
        // 处理文本数据
        final responseBody = response.data.toString();
        if (responseBody.length > 1000) {
          print('║ ${responseBody.substring(0, 1000)}...[响应过长，已截断]');
        } else {
          print('║ $responseBody');
        }
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

  /// 判断是否为二进制数据
  bool _isBinaryData(dynamic data) {
    return data is Uint8List ||
        data is List<int> ||
        (data is String && data.length > 1000 && _looksLikeBinaryString(data));
  }

  /// 粗略判断字符串是否看起来像二进制数据的字符串表示
  bool _looksLikeBinaryString(String data) {
    // 如果字符串主要由数字、逗号和空格组成，且长度很长，可能是二进制数组的字符串表示
    if (data.length < 100) return false;

    final lines = data.split('\n');
    if (lines.length < 3) return false;

    // 检查前几行是否都是数字和逗号模式
    int binaryLikeLines = 0;
    for (int i = 0; i < math.min(5, lines.length); i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // 匹配数字、逗号、空格模式
      if (RegExp(r'^[\d,\s\[\]]+$').hasMatch(line)) {
        binaryLikeLines++;
      }
    }

    return binaryLikeLines >= 2;
  }

  /// 记录二进制数据日志
  void _logBinaryData(dynamic binaryData) {
    Uint8List bytes;

    if (binaryData is Uint8List) {
      bytes = binaryData;
    } else if (binaryData is List<int>) {
      bytes = Uint8List.fromList(binaryData);
    } else if (binaryData is String) {
      // 如果是已经转换成字符串的二进制数据，尝试解析回字节数组
      try {
        final cleanString = binaryData.replaceAll(RegExp(r'[\[\]\s]'), '');
        final numberStrings = cleanString.split(',');
        bytes = Uint8List.fromList(
          numberStrings.where((s) => s.isNotEmpty).map(int.parse).toList(),
        );
      } catch (e) {
        print('║ [二进制数据 - 无法解析]');
        return;
      }
    } else {
      print('║ [未知的二进制数据类型: ${binaryData.runtimeType}]');
      return;
    }

    print('║ [二进制数据 - ${bytes.length} 字节]');
    print('║ 类型: ${_guessBinaryType(bytes)}');

    if (bytes.length <= binaryMaxDisplayLength) {
      print(
        '║ 数据: ${bytes.sublist(0, math.min(bytes.length, binaryMaxDisplayLength))}',
      );
    } else {
      print(
        '║ 数据 (前$binaryMaxDisplayLength字节): ${bytes.sublist(0, binaryMaxDisplayLength)}',
      );
      print('║ ...[剩余 ${bytes.length - binaryMaxDisplayLength} 字节已省略]');
    }

    // 显示十六进制预览（可选）
    if (bytes.isNotEmpty) {
      print(
        '║ 十六进制开头: ${_bytesToHex(bytes.sublist(0, math.min(16, bytes.length)))}',
      );
    }
  }

  /// 猜测二进制数据类型
  String _guessBinaryType(Uint8List bytes) {
    if (bytes.length < 4) return '未知二进制数据';

    // 检查常见文件类型的魔数
    if (bytes.length >= 4) {
      // JPEG
      if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
        return 'JPEG 图像';
      }
      // PNG
      if (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        return 'PNG 图像';
      }
      // GIF
      if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
        return 'GIF 图像';
      }
      // PDF
      if (bytes[0] == 0x25 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x44 &&
          bytes[3] == 0x46) {
        return 'PDF 文档';
      }
      // ZIP (也包括DOCX, XLSX等)
      if (bytes[0] == 0x50 &&
          bytes[1] == 0x4B &&
          bytes[2] == 0x03 &&
          bytes[3] == 0x04) {
        return 'ZIP 压缩文件';
      }
    }

    return '二进制数据';
  }

  /// 将字节数组转换为十六进制字符串
  String _bytesToHex(List<int> bytes) {
    return bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join(' ');
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

    // if (text.length <= maxLength) {
    //   print('$prefix$text');
    //   return;
    // }

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
