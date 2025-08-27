import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'base_api_config.dart';

/// 通用API初始化基类
/// 提供统一的存储初始化逻辑
class BaseApiInit {
  static final Map<String, bool> _initializedModules = {};

  /// 初始化指定模块的存储
  static Future<void> initModule(BaseApiConfig config) async {
    if (_initializedModules[config.moduleName] == true) return;

    try {
      // 初始化缓存存储
      await GetStorage.init(config.cacheKey);

      // 初始化请求日志存储
      await GetStorage.init(config.requestLogKey);

      _initializedModules[config.moduleName] = true;
      if (kDebugMode) {
        print('✅ ${config.moduleName} API存储初始化完成');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ${config.moduleName} API存储初始化失败: $e');
      }
      rethrow;
    }
  }

  /// 检查模块是否已初始化
  static bool isModuleInitialized(String moduleName) {
    return _initializedModules[moduleName] == true;
  }

  /// 清理指定模块的所有存储
  static Future<void> clearModuleStorage(BaseApiConfig config) async {
    try {
      final cacheStorage = GetStorage(config.cacheKey);
      final logStorage = GetStorage(config.requestLogKey);

      await cacheStorage.erase();
      await logStorage.erase();

      if (kDebugMode) {
        print('✅ ${config.moduleName} API存储清理完成');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ${config.moduleName} API存储清理失败: $e');
      }
    }
  }

  /// 清理所有模块的存储
  static Future<void> clearAllStorage() async {
    for (final moduleName in _initializedModules.keys) {
      try {
        final cacheStorage = GetStorage("suchat_${moduleName}_cache");
        final logStorage = GetStorage("suchat_${moduleName}_request_log");
        
        await cacheStorage.erase();
        await logStorage.erase();
      } catch (e) {
        if (kDebugMode) {
          print('❌ 清理 $moduleName 存储失败: $e');
        }
      }
    }
    
    _initializedModules.clear();
    if (kDebugMode) {
      print('✅ 所有API存储清理完成');
    }
  }
}
