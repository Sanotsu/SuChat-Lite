import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

/// 新闻API初始化类
/// 确保新闻API相关的存储正确初始化
class NewsApiInit {
  static bool _initialized = false;

  static const String newsCacheKey = "suchat_news_cache";
  static const String newsRequestLogKey = "suchat_news_request_log";

  /// 初始化新闻API存储
  static Future<void> init() async {
    if (_initialized) return;

    try {
      // 初始化新闻缓存存储
      await GetStorage.init(newsCacheKey);

      // 初始化新闻请求日志存储
      await GetStorage.init(newsRequestLogKey);

      _initialized = true;
      if (kDebugMode) {
        print('✅ 新闻API存储初始化完成');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 新闻API存储初始化失败: $e');
      }
      rethrow;
    }
  }

  /// 检查是否已初始化
  static bool get isInitialized => _initialized;

  /// 清理所有新闻相关存储
  static Future<void> clearAllStorage() async {
    try {
      final cacheStorage = GetStorage(newsCacheKey);
      final logStorage = GetStorage(newsRequestLogKey);

      await cacheStorage.erase();
      await logStorage.erase();

      if (kDebugMode) {
        print('✅ 新闻API存储清理完成');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 新闻API存储清理失败: $e');
      }
    }
  }
}
