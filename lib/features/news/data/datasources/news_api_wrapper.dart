import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';

import '../../../../core/network/dio_client/cus_http_client.dart';
import '../../../../core/network/dio_client/cus_http_request.dart';
import 'news_init.dart';

/// 新闻API包装类，提供统一的保护措施
class NewsApiWrapper {
  static final NewsApiWrapper _instance = NewsApiWrapper._internal();
  factory NewsApiWrapper() => _instance;
  NewsApiWrapper._internal() {
    // 确保存储已初始化
    _ensureInitialized();
  }

  // 缓存存储
  final GetStorage _cacheStorage = GetStorage(NewsApiInit.newsCacheKey);

  // 请求记录存储
  final GetStorage _requestLogStorage = GetStorage(
    NewsApiInit.newsRequestLogKey,
  );

  // 默认缓存时间（10分钟）
  static const Duration defaultCacheDuration = Duration(minutes: 10);

  // 请求间隔限制
  // 目前所有的新闻都有缓存机制，在缓存时间内重复请求是直接返回的缓存数据，
  // 所以这里请求频率限制requestInterval，可以取消，或者设置很小
  static const Duration requestInterval = Duration(seconds: 1);

  // 最大重试次数
  static const int maxRetries = 3;

  // 重试延迟（指数退避）
  static const Duration baseRetryDelay = Duration(seconds: 1);

  /// 确保存储已初始化
  Future<void> _ensureInitialized() async {
    if (!NewsApiInit.isInitialized) {
      await NewsApiInit.init();
    }
  }

  /// 安全headers配置
  static Map<String, String> get _safeHeaders => {
    'User-Agent': _getRandomUserAgent(),
    'Accept': 'application/json, text/plain, */*',
    'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
    'Accept-Encoding': 'gzip, deflate, br',
    'Connection': 'keep-alive',
    'Cache-Control': 'no-cache',
    'Pragma': 'no-cache',
    'Sec-Fetch-Dest': 'empty',
    'Sec-Fetch-Mode': 'cors',
    'Sec-Fetch-Site': 'cross-site',
    'X-Requested-With': 'XMLHttpRequest',
  };

  /// 获取随机User-Agent
  static String _getRandomUserAgent() {
    final userAgents = [
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0',
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:121.0) Gecko/20100101 Firefox/121.0',
    ];
    return userAgents[Random().nextInt(userAgents.length)];
  }

  /// 生成缓存键
  String _generateCacheKey(String url, Map<String, dynamic>? params) {
    final paramString = params != null ? json.encode(params) : '';
    return '${url}_$paramString';
  }

  /// 检查是否需要强制刷新
  bool _shouldForceRefresh(String cacheKey, Duration? cacheDuration) {
    final lastRequestTime = _requestLogStorage.read('${cacheKey}_last_request');
    if (lastRequestTime == null) return true;

    final lastTime = DateTime.parse(lastRequestTime);
    final now = DateTime.now();
    final duration = cacheDuration ?? defaultCacheDuration;

    return now.difference(lastTime) > duration;
  }

  /// 检查请求频率限制
  /// 实际上目前所有的新闻都有缓存机制，在缓存时间内重复请求是直接返回的缓存数据，
  /// 所以这里请求频率限制requestInterval，可以取消，或者设置很小
  bool _isRequestRateLimited(String cacheKey) {
    final lastRequestTime = _requestLogStorage.read('${cacheKey}_last_request');
    if (lastRequestTime == null) return false;

    final lastTime = DateTime.parse(lastRequestTime);
    final now = DateTime.now();

    return now.difference(lastTime) < requestInterval;
  }

  /// 获取缓存数据
  dynamic _getCachedData(String cacheKey) {
    final cachedData = _cacheStorage.read(cacheKey);
    if (cachedData != null) {
      final cacheTime = _cacheStorage.read('${cacheKey}_time');
      if (cacheTime != null) {
        final cachedDateTime = DateTime.parse(cacheTime);
        final now = DateTime.now();
        // 缓存未过期
        if (now.difference(cachedDateTime) < defaultCacheDuration) {
          return cachedData;
        }
      }
    }
    return null;
  }

  /// 保存缓存数据
  void _saveCacheData(String cacheKey, dynamic data) {
    _cacheStorage.write(cacheKey, data);
    _cacheStorage.write('${cacheKey}_time', DateTime.now().toIso8601String());
  }

  /// 记录请求时间
  void _logRequest(String cacheKey) {
    _requestLogStorage.write(
      '${cacheKey}_last_request',
      DateTime.now().toIso8601String(),
    );
  }

  /// 带重试的HTTP请求
  Future<dynamic> _requestWithRetry({
    required String path,
    required CusHttpMethod method,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    dynamic data,
    int retryCount = 0,
  }) async {
    try {
      // 合并安全headers
      final finalHeaders = Map<String, dynamic>.from(_safeHeaders);
      if (headers != null) {
        finalHeaders.addAll(headers);
      }

      switch (method) {
        case CusHttpMethod.get:
          return await HttpUtils.get(
            path: path,
            queryParameters: queryParameters,
            // headers: finalHeaders,
            showLoading: false,
          );
        case CusHttpMethod.post:
          return await HttpUtils.post(
            path: path,
            data: data,
            // headers: finalHeaders,
            showLoading: false,
          );
        default:
          throw UnsupportedError('Unsupported HTTP method: $method');
      }
    } catch (e) {
      if (retryCount < maxRetries && _shouldRetry(e)) {
        // 指数退避重试
        final delay = Duration(
          milliseconds: (baseRetryDelay.inMilliseconds * pow(2, retryCount))
              .toInt(),
        );
        await Future.delayed(delay);
        return _requestWithRetry(
          path: path,
          method: method,
          queryParameters: queryParameters,
          headers: headers,
          data: data,
          retryCount: retryCount + 1,
        );
      }
      rethrow;
    }
  }

  /// 判断是否应该重试
  bool _shouldRetry(dynamic error) {
    if (error is DioException) {
      // 网络错误、超时、服务器错误等可以重试
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError ||
          (error.response?.statusCode != null &&
              error.response!.statusCode! >= 500);
    }
    return false;
  }

  /// 主要的API请求方法
  Future<dynamic> request({
    required String path,
    required CusHttpMethod method,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    dynamic data,
    Duration? cacheDuration,
    bool forceRefresh = false,
    String? customCacheKey,
  }) async {
    // 确保存储已初始化
    await _ensureInitialized();

    final cacheKey = customCacheKey ?? _generateCacheKey(path, queryParameters);

    // 检查请求频率限制
    if (!forceRefresh && _isRequestRateLimited(cacheKey)) {
      throw Exception('请求过于频繁，请间隔至少10秒，请稍后再试');
    }

    // 检查缓存
    if (!forceRefresh) {
      final cachedData = _getCachedData(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }
    }

    // 检查是否需要强制刷新
    if (!forceRefresh && !_shouldForceRefresh(cacheKey, cacheDuration)) {
      final cachedData = _getCachedData(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }
    }

    try {
      // 执行请求
      final response = await _requestWithRetry(
        path: path,
        method: method,
        queryParameters: queryParameters,
        headers: headers,
        data: data,
      );

      // 记录请求时间
      _logRequest(cacheKey);

      // 缓存响应数据
      _saveCacheData(cacheKey, response);

      return response;
    } catch (e) {
      // 如果请求失败但有缓存数据，返回缓存数据
      if (!forceRefresh) {
        final cachedData = _getCachedData(cacheKey);
        if (cachedData != null) {
          return cachedData;
        }
      }
      rethrow;
    }
  }

  /// 清理缓存
  void clearCache([String? cacheKey]) {
    if (cacheKey != null) {
      _cacheStorage.remove(cacheKey);
      _cacheStorage.remove('${cacheKey}_time');
    } else {
      _cacheStorage.erase();
    }
  }

  /// 清理请求日志
  void clearRequestLog([String? cacheKey]) {
    if (cacheKey != null) {
      _requestLogStorage.remove('${cacheKey}_last_request');
    } else {
      _requestLogStorage.erase();
    }
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    final keys = _cacheStorage.getKeys();
    final requestKeys = _requestLogStorage.getKeys();

    return {
      'cache_count': keys.length,
      'request_log_count': requestKeys.length,
      'cache_keys': keys.toList(),
      'request_log_keys': requestKeys.toList(),
    };
  }
}

/// 便捷的GET请求方法
Future<dynamic> newsGet({
  required String path,
  Map<String, dynamic>? queryParameters,
  Map<String, dynamic>? headers,
  Duration? cacheDuration,
  bool forceRefresh = false,
  String? customCacheKey,
}) {
  return NewsApiWrapper().request(
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
Future<dynamic> newsPost({
  required String path,
  Map<String, dynamic>? queryParameters,
  Map<String, dynamic>? headers,
  dynamic data,
  Duration? cacheDuration,
  bool forceRefresh = false,
  String? customCacheKey,
}) {
  return NewsApiWrapper().request(
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
