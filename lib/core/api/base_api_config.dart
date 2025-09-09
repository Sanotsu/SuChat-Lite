/// API配置基类
/// 定义API模块的基础配置信息
abstract class BaseApiConfig {
  /// 模块名称，用于缓存键前缀和存储命名
  String get moduleName;
  
  /// 缓存存储键
  String get cacheKey => "suchat_${moduleName}_cache";
  
  /// 请求日志存储键
  String get requestLogKey => "suchat_${moduleName}_request_log";
  
  /// 默认缓存时长
  Duration get defaultCacheDuration => const Duration(minutes: 10);
  
  /// 请求间隔限制
  Duration get requestInterval => const Duration(seconds: 1);
  
  /// 最大重试次数
  int get maxRetries => 3;
  
  /// 重试基础延迟
  Duration get baseRetryDelay => const Duration(seconds: 1);
  
  /// 是否启用安全Headers
  bool get enableSafeHeaders => false;
  
  /// 自定义Headers
  Map<String, String> get customHeaders => {};
}
