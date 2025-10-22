import 'dart:io';
import 'dart:convert'; // 用于 Utf8Codec
import 'package:flutter/foundation.dart'; // 用于 kDebugMode
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';

import 'get_dir.dart';

class LogHelper {
  static late final Logger _logger;
  static late final File _logFile;

  // 私有构造函数
  LogHelper._();

  static Future<void> init() async {
    // 获取存储路径
    final directory = await getBackupDir();

    // 根据当前日期创建文件名
    final String formattedDate = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now());
    _logFile = File('${directory.path}/suchat_log_$formattedDate.txt');

    // 创建一个可以同时输出到控制台和文件的Logger
    // 在Release模式下，我们可能只想写入文件
    final List<LogOutput> outputs = [
      FileOutput(
        file: _logFile,
        overrideExisting: false, // 设置为 false 来追加日志
        encoding: const Utf8Codec(), // 明确使用UTF-8编码以支持中文
      ),
    ];

    // 在Debug模式下，同时输出到控制台
    if (kDebugMode) {
      outputs.add(ConsoleOutput());
    }

    _logger = Logger(
      // 使用MultiOutput将日志分发到多个目的地
      output: MultiOutput(outputs),
      // 自定义打印样式
      printer: PrettyPrinter(
        methodCount: 1,
        errorMethodCount: 5,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
    );

    // 记录一条初始化信息
    info("Logger 初始化成功。日志将写入: ${_logFile.path}");
  }

  // 提供静态方法方便全局调用
  static void debug(dynamic message) {
    _logger.d(message);
  }

  static void info(dynamic message) {
    _logger.i(message);
  }

  static void warning(dynamic message) {
    _logger.w(message);
  }

  static void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  static void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}
