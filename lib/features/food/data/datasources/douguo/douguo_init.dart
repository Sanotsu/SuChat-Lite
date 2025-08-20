import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

/// 豆果API初始化类
/// 确保豆果API相关的存储正确初始化
class DouGuoInit {
  static bool _initialized = false;

  static const String douguoCacheKey = "suchat_douguo_cache";
  static const String douguoRequestLogKey = "suchat_douguo_request_log";

  /// 初始化豆果API存储
  static Future<void> init() async {
    if (_initialized) return;

    try {
      // 初始化豆果缓存存储
      await GetStorage.init(douguoCacheKey);

      // 初始化豆果请求日志存储
      await GetStorage.init(douguoRequestLogKey);

      _initialized = true;
      if (kDebugMode) {
        print('✅ 豆果API存储初始化完成');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 豆果API存储初始化失败: $e');
      }
      rethrow;
    }
  }

  /// 检查是否已初始化
  static bool get isInitialized => _initialized;

  /// 清理所有豆果相关存储
  static Future<void> clearAllStorage() async {
    try {
      final cacheStorage = GetStorage(douguoCacheKey);
      final logStorage = GetStorage(douguoRequestLogKey);

      await cacheStorage.erase();
      await logStorage.erase();

      if (kDebugMode) {
        print('✅ 豆果API存储清理完成');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 豆果API存储清理失败: $e');
      }
    }
  }
}
