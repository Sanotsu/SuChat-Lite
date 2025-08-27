import 'dart:convert';

import '../network/dio_client/cus_http_request.dart';
import 'base_api_config.dart';
import 'base_api_wrapper.dart';

/// 通用API管理器基类
/// 提供统一的API管理功能和便捷方法
abstract class BaseApiManager<T extends BaseApiConfig> {
  late final T _config;
  late final BaseApiWrapper _wrapper;

  BaseApiManager(T config) {
    _config = config;
    _wrapper = BaseApiWrapper(_config);
  }

  /// 获取配置
  T get config => _config;

  /// 便捷的GET请求方法
  Future<dynamic> get({
    required String path,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Duration? cacheDuration,
    bool forceRefresh = false,
    String? customCacheKey,
  }) {
    return _wrapper.request(
      path: path,
      method: CusHttpMethod.get,
      queryParameters: queryParameters,
      headers: headers,
      cacheDuration: cacheDuration,
      forceRefresh: forceRefresh,
      customCacheKey: customCacheKey,
    );
  }

  /// 便捷的POST请求方法
  Future<dynamic> post({
    required String path,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    dynamic data,
    Duration? cacheDuration,
    bool forceRefresh = false,
    String? customCacheKey,
  }) {
    return _wrapper.request(
      path: path,
      method: CusHttpMethod.post,
      queryParameters: queryParameters,
      headers: headers,
      data: data,
      cacheDuration: cacheDuration,
      forceRefresh: forceRefresh,
      customCacheKey: customCacheKey,
    );
  }

  /// 处理响应数据的通用方法
  /// 自动处理字符串JSON解析
  dynamic processResponse(dynamic respData) {
    if (respData.runtimeType == String) {
      return json.decode(respData);
    }
    return respData;
  }

  /// 清理所有缓存
  void clearAllCache() {
    _wrapper.clearCache();
    _wrapper.clearRequestLog();
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    return _wrapper.getCacheStats();
  }
}
