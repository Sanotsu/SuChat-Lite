import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';

import 'simple_tools.dart';

/// TTS助手类，用于文本转语音
/// 队列管理：确保语音按顺序播放，避免互相打断
/// 错误处理：捕获并记录所有可能的错误，确保应用不会因 TTS 错误而崩溃
/// 状态管理：正确跟踪语音播放状态，避免状态不一致(使用 Completer 来跟踪语音播放的完成状态，确保语音能够完整播放)
/// 超时处理：为关键操作添加超时机制，避免永久阻塞
/// 平台兼容性：处理不同平台上 TTS API 行为的差异
///
class TTSHelper {
  static final TTSHelper _instance = TTSHelper._internal();

  /// 单例模式
  factory TTSHelper() => _instance;

  TTSHelper._internal();

  /// Flutter TTS实例
  final FlutterTts _flutterTts = FlutterTts();

  /// 是否已初始化
  bool _isInitialized = false;

  /// 是否正在说话
  bool _isSpeaking = false;

  /// 语言
  String _language = 'zh-CN';

  /// 语速
  double _speechRate = 0.5;

  /// 音量
  double _volume = 1.0;

  /// 音调
  double _pitch = 1.0;

  /// 语音队列
  final List<String> _speechQueue = [];

  /// 是否正在处理队列
  bool _isProcessingQueue = false;

  /// 用于等待语音完成的 Completer
  Completer<void>? _speechCompleter;

  /// 是否支持TTS
  final bool _isSupported = _checkTTSSupport();

  /// 检查当前平台是否支持TTS
  static bool _checkTTSSupport() {
    // flutter_tts 支持的平台: Android, iOS, macOS, Windows, Web
    // 不支持 Linux
    if (kIsWeb) return true;

    return Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isWindows;
  }

  /// 是否支持TTS功能
  bool get isSupported => _isSupported;

  /// 是否正在说话
  bool get isSpeaking => _isSupported && _isSpeaking;

  /// 获取队列长度
  int get queueLength => _speechQueue.length;

  /// 初始化TTS
  Future<void> init() async {
    if (_isInitialized || !_isSupported) return;

    try {
      await _flutterTts.setLanguage(_language);
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setVolume(_volume);
      await _flutterTts.setPitch(_pitch);

      // 设置完成回调
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _completeSpeech();
      });

      // 设置错误回调
      _flutterTts.setErrorHandler((error) {
        pl.e('TTS错误: $error');
        _isSpeaking = false;
        _completeSpeech(hasError: true);
      });

      // 设置取消回调
      _flutterTts.setCancelHandler(() {
        pl.i('TTS已取消');
        _isSpeaking = false;
        _completeSpeech(isCancelled: true);
      });

      _isInitialized = true;
    } catch (e) {
      pl.e('TTS初始化错误: $e');
      _isInitialized = false;
    }
  }

  /// 完成当前语音播放，处理下一个队列项
  void _completeSpeech({bool hasError = false, bool isCancelled = false}) {
    // 完成当前的 Completer
    if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
      if (hasError) {
        _speechCompleter!.completeError('TTS错误');
      } else {
        _speechCompleter!.complete();
      }
    }

    // 如果取消了，清空整个队列
    if (isCancelled) {
      _speechQueue.clear();
      _isProcessingQueue = false;
      return;
    }

    // 延迟一点时间再处理下一个，避免太快连续播放
    Future.delayed(const Duration(milliseconds: 200), () {
      _processNextInQueue();
    });
  }

  /// 处理队列中的下一个文本
  Future<void> _processNextInQueue() async {
    if (_speechQueue.isEmpty) {
      _isProcessingQueue = false;
      return;
    }

    _isProcessingQueue = true;
    final text = _speechQueue.removeAt(0);

    if (text.trim().isEmpty) {
      // 如果文本为空，直接处理下一个
      _processNextInQueue();
      return;
    }

    // 创建新的 Completer
    _speechCompleter = Completer<void>();

    // 播放文本
    _isSpeaking = true;
    try {
      // 在某些平台上，speak 方法返回 int 而不是 String
      await _flutterTts.speak(text);
    } catch (e) {
      pl.e('TTS播放错误: $e');
      _isSpeaking = false;
      _completeSpeech(hasError: true);
      return;
    }

    // 等待播放完成
    try {
      await _speechCompleter!.future;
    } catch (e) {
      pl.e('等待TTS完成时出错: $e');
    }
  }

  /// 设置语言
  Future<void> setLanguage(String language) async {
    if (!_isSupported) return;

    _language = language;
    await _flutterTts.setLanguage(language);
  }

  /// 设置语速 (0.0-1.0)
  Future<void> setSpeechRate(double rate) async {
    if (!_isSupported) return;

    _speechRate = rate;
    await _flutterTts.setSpeechRate(rate);
  }

  /// 设置音量 (0.0-1.0)
  Future<void> setVolume(double volume) async {
    if (!_isSupported) return;

    _volume = volume;
    await _flutterTts.setVolume(volume);
  }

  /// 设置音调 (0.5-2.0)
  Future<void> setPitch(double pitch) async {
    if (!_isSupported) return;

    _pitch = pitch;
    await _flutterTts.setPitch(pitch);
  }

  /// 播放文本
  /// 文本会被添加到队列中，按顺序播放
  Future<void> speak(String text) async {
    if (!_isSupported) return;

    if (!_isInitialized) {
      await init();
    }

    // 如果文本为空，直接返回
    if (text.trim().isEmpty) return;

    // 添加到队列
    _speechQueue.add(text);

    // 如果队列未在处理中，开始处理
    if (!_isProcessingQueue) {
      _processNextInQueue();
    }

    return Future.value();
  }

  /// 立即播放文本（清空队列，立即播放）
  Future<void> speakNow(String text) async {
    if (!_isSupported) return;

    if (!_isInitialized) {
      await init();
    }

    // 停止当前播放和清空队列
    await stop();

    // 如果文本为空，直接返回
    if (text.trim().isEmpty) return;

    // 直接播放，不添加到队列
    _isSpeaking = true;
    _speechCompleter = Completer<void>();

    try {
      await _flutterTts.speak(text);

      // 等待播放完成
      await _speechCompleter!.future.timeout(
        Duration(seconds: text.length ~/ 3 + 3), // 根据文本长度动态设置超时时间
        onTimeout: () {
          pl.i('TTS播放超时，可能已完成但未触发完成回调');
          // 如果超时，则手动完成
          if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
            _speechCompleter!.complete();
          }
        },
      );
    } catch (e) {
      pl.e('立即播放TTS错误: $e');
      // 确保即使出错也完成 Completer
      if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
        _speechCompleter!.completeError('立即播放TTS错误');
      }
    } finally {
      _isSpeaking = false;
    }
  }

  /// 停止播放并清空队列
  Future<void> stop() async {
    if (!_isSupported) return;

    // 清空队列
    _speechQueue.clear();
    _isProcessingQueue = false;

    // 如果正在播放，停止播放
    if (_isSpeaking) {
      _isSpeaking = false;
      try {
        await _flutterTts.stop();
      } catch (e) {
        pl.e('停止TTS播放错误: $e');
      }

      // 手动触发完成回调，因为有些平台在stop后不会调用completionHandler
      if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
        _speechCompleter!.complete();
      }
    }
  }

  /// 暂停播放
  Future<void> pause() async {
    if (!_isSupported || !_isSpeaking) return;

    try {
      await _flutterTts.pause();
    } catch (e) {
      pl.e('暂停TTS播放错误: $e');
    }
  }

  /// 继续播放
  Future<void> resume() async {
    if (!_isSupported) return;

    // 有些平台不支持恢复功能，所以我们简单地继续队列处理
    if (!_isProcessingQueue && _speechQueue.isNotEmpty) {
      _processNextInQueue();
    }
  }

  /// 销毁TTS实例
  Future<void> dispose() async {
    if (!_isSupported) return;

    await stop();

    try {
      await _flutterTts.stop();
    } catch (e) {
      pl.e('销毁TTS实例时出错: $e');
    }
  }
}
