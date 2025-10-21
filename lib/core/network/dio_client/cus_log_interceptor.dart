import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

final logPrint = debugPrint;

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
    this.compact = true,
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

    logPrint('');
    logPrint('╔╣ Custom Request ║ $method ');
    logPrint('║  $uri');
    logPrint('╚${'═' * math.min(maxWidth, uri.toString().length + 10)}╝');

    // 打印Headers
    if (options.headers.isNotEmpty) {
      logPrint('╔ Headers ');
      options.headers.forEach((key, value) {
        logPrint('╟ $key: $value');
      });
      logPrint('╚${'═' * maxWidth}╝');
    }

    // 打印Body（关键部分：处理嵌套数据截断）
    if (options.data != null) {
      logPrint('╔ Body ');
      final processedData = _processDataForLog(options.data);
      final jsonString = _formatJson(processedData);
      _safePrint(jsonString);
      logPrint('╚${'═' * maxWidth}╝');
    }
  }

  void _logResponse(Response response) {
    final uri = response.requestOptions.uri;
    final method = response.requestOptions.method.toUpperCase();
    final statusCode = response.statusCode;
    final statusMessage = response.statusMessage ?? '';

    logPrint('');
    logPrint(
      '╔╣ Custom Response ║ $method ║ Status: $statusCode $statusMessage',
    );
    logPrint('║  $uri');
    logPrint('╚${'═' * maxWidth}╝');

    // 打印Headers
    if (response.headers.map.isNotEmpty) {
      logPrint('╔ Headers ');
      response.headers.map.forEach((key, value) {
        logPrint('╟ $key: $value');
      });
      logPrint('╚${'═' * maxWidth}╝');
    }

    // 打印Body - 关键修改：识别二进制数据
    if (response.data != null) {
      logPrint('╔ Body');
      logPrint('║');

      if (_isBinaryData(response.data)) {
        // 处理二进制数据
        _logBinaryData(response.data);
      } else {
        // 处理文本数据
        // final responseBody = response.data.toString();
        // if (responseBody.length > 1000) {
        //   logPrint('║ ${responseBody.substring(0, 1000)}...[响应过长，已截断]');
        // } else {
        //   logPrint('║ $responseBody');
        // }

        // // 和自定义请求一样的处理
        // final processedData = _processDataForLog(response.data);
        // final jsonString = _formatJson(processedData);
        // _safePrint(jsonString);

        // logPrint(
        //   "处理非二进制数据 ${response.runtimeType} ${response.data.runtimeType}}",
        // );

        // // 这个是pretty_dio_looger中的显示方法(直接复制的代码)
        _printResponse(response);
      }
      logPrint('║');
      logPrint('╚${'═' * maxWidth}╝');
    }
  }

  void _logError(DioException err) {
    logPrint('');
    logPrint('╔╣ Custom Error ║ ${err.type}');
    if (err.response != null) {
      logPrint('║  ${err.response!.requestOptions.uri}');
      logPrint(
        '║  Status: ${err.response!.statusCode} ${err.response!.statusMessage}',
      );
    }
    logPrint('╟ Message: ${err.message}');
    logPrint('╚${'═' * maxWidth}╝');
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
        logPrint('║ [二进制数据 - 无法解析]');
        return;
      }
    } else {
      logPrint('║ [未知的二进制数据类型: ${binaryData.runtimeType}]');
      return;
    }

    logPrint('║ [二进制数据 - ${bytes.length} 字节]');
    logPrint('║ 类型: ${_guessBinaryType(bytes)}');

    if (bytes.length <= binaryMaxDisplayLength) {
      logPrint(
        '║ 数据: ${bytes.sublist(0, math.min(bytes.length, binaryMaxDisplayLength))}',
      );
    } else {
      logPrint(
        '║ 数据 (前$binaryMaxDisplayLength字节): ${bytes.sublist(0, binaryMaxDisplayLength)}',
      );
      logPrint('║ ...[剩余 ${bytes.length - binaryMaxDisplayLength} 字节已省略]');
    }

    // 显示十六进制预览（可选）
    if (bytes.isNotEmpty) {
      logPrint(
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
        // return data;
        // 不是json的字符串，也截断返回
        return data.length <= truncateLength
            ? data
            : '${data.substring(0, truncateLength)}……[不是JSON的字符串]$truncateIndicator';
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
    //   logPrint('$prefix$text');
    //   return;
    // }

    // 按行分割并逐行打印
    final lines = text.split('\n');
    for (final line in lines) {
      if (line.length <= maxLength) {
        logPrint('$prefix$line');
      } else {
        // 如果单行还是太长，按字符分段
        for (int i = 0; i < line.length; i += maxLength) {
          final end = math.min(i + maxLength, line.length);
          final segment = line.substring(i, end);
          logPrint('$prefix$segment');
        }
      }
    }
  }

  /// *******************************************************************
  /// 以下 这个打印response相关辅助函数，直接复制处理pretty_dio_looger的代码
  /// *******************************************************************
  void _printResponse(Response response) async {
    if (response.data != null) {
      if (response.data is Map) {
        _printPrettyMap(response.data as Map);
      } else if (response.data is Uint8List) {
        logPrint('║${_indent()}[');
        _printUint8List(response.data as Uint8List);
        logPrint('║${_indent()}]');
      } else if (response.data is List) {
        logPrint('║${_indent()}[');
        _printList(response.data as List);
        logPrint('║${_indent()}]');
      } else if (response.data is ResponseBody) {
        _printBlock(response.data.toString());

        // 注意：流只能单次消费，也不能深拷贝，所以这里不处理流式响应的内容(留着可以测试时使用)
        // await printResponseBody(response.data);
      } else {
        _printBlock(response.data.toString());
      }
    }
  }

  // InitialTab count to logPrint json response
  static const int kInitialTab = 1;
  // 1 tab length
  static const String tabStep = '    ';
  // Print compact json response
  final bool compact;
  // Size in which the Uint8List will be split
  static const int chunkSize = 20;

  String _indent([int tabCount = kInitialTab]) => tabStep * tabCount;

  bool _canFlattenMap(Map map) {
    return map.values
            .where((dynamic val) => val is Map || val is List)
            .isEmpty &&
        map.toString().length < maxWidth;
  }

  bool _canFlattenList(List list) {
    return list.length < 10 && list.toString().length < maxWidth;
  }

  void _printPrettyMap(
    Map data, {
    int initialTab = kInitialTab,
    bool isListItem = false,
    bool isLast = false,
  }) {
    var tabs = initialTab;
    final isRoot = tabs == kInitialTab;
    final initialIndent = _indent(tabs);
    tabs++;

    if (isRoot || isListItem) logPrint('║$initialIndent{');

    for (var index = 0; index < data.length; index++) {
      final isLast = index == data.length - 1;
      final key = '"${data.keys.elementAt(index)}"';
      dynamic value = data[data.keys.elementAt(index)];
      if (value is String) {
        value = '"${value.toString().replaceAll(RegExp(r'([\r\n])+'), " ")}"';
      }
      if (value is Map) {
        if (compact && _canFlattenMap(value)) {
          logPrint('║${_indent(tabs)} $key: $value${!isLast ? ',' : ''}');
        } else {
          logPrint('║${_indent(tabs)} $key: {');
          _printPrettyMap(value, initialTab: tabs);
        }
      } else if (value is List) {
        if (compact && _canFlattenList(value)) {
          logPrint('║${_indent(tabs)} $key: ${value.toString()}');
        } else {
          logPrint('║${_indent(tabs)} $key: [');
          _printList(value, tabs: tabs);
          logPrint('║${_indent(tabs)} ]${isLast ? '' : ','}');
        }
      } else {
        final msg = value.toString().replaceAll('\n', '');
        final indent = _indent(tabs);
        final linWidth = maxWidth - indent.length;
        if (msg.length + indent.length > linWidth) {
          final lines = (msg.length / linWidth).ceil();
          for (var i = 0; i < lines; ++i) {
            final multilineKey = i == 0 ? "$key:" : "";
            logPrint(
              '║${_indent(tabs)} $multilineKey ${msg.substring(i * linWidth, math.min<int>(i * linWidth + linWidth, msg.length))}',
            );
          }
        } else {
          logPrint('║${_indent(tabs)} $key: $msg${!isLast ? ',' : ''}');
        }
      }
    }

    logPrint('║$initialIndent}${isListItem && !isLast ? ',' : ''}');
  }

  void _printUint8List(Uint8List list, {int tabs = kInitialTab}) {
    var chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(
        list.sublist(
          i,
          i + chunkSize > list.length ? list.length : i + chunkSize,
        ),
      );
    }
    for (var element in chunks) {
      logPrint('║${_indent(tabs)} ${element.join(", ")}');
    }
  }

  void _printList(List list, {int tabs = kInitialTab}) {
    for (var i = 0; i < list.length; i++) {
      final element = list[i];
      final isLast = i == list.length - 1;
      if (element is Map) {
        if (compact && _canFlattenMap(element)) {
          logPrint('║${_indent(tabs)}  $element${!isLast ? ',' : ''}');
        } else {
          _printPrettyMap(
            element,
            initialTab: tabs + 1,
            isListItem: true,
            isLast: isLast,
          );
        }
      } else {
        logPrint('║${_indent(tabs + 2)} $element${isLast ? '' : ','}');
      }
    }
  }

  /// 测试保留: 从 ResponseBody 中读取字符串内容
  Future<void> printResponseBody(ResponseBody body) async {
    try {
      // 将字节流转换为字符串
      final bytesBuilder = BytesBuilder();
      await for (final chunk in body.stream) {
        bytesBuilder.add(chunk);
      }
      final bytes = bytesBuilder.toBytes();

      logPrint(" ║ ${utf8.decode(bytes)}");
    } catch (e) {
      logPrint('读取响应体失败: $e');
    }
  }

  void _printBlock(String msg) {
    final lines = (msg.length / maxWidth).ceil();
    for (var i = 0; i < lines; ++i) {
      logPrint(
        (i >= 0 ? '║ ' : '') +
            msg.substring(
              i * maxWidth,
              math.min<int>(i * maxWidth + maxWidth, msg.length),
            ),
      );
    }
  }
}
