import '../../../../core/api/base_api_config.dart';

/// 新闻模块API配置
class NewsApiConfig extends BaseApiConfig {
  static final NewsApiConfig _instance = NewsApiConfig._internal();
  factory NewsApiConfig() => _instance;
  NewsApiConfig._internal();

  @override
  String get moduleName => 'news';

  @override
  Duration get defaultCacheDuration => const Duration(minutes: 10);

  @override
  Duration get requestInterval => const Duration(seconds: 1);

  @override
  int get maxRetries => 3;

  @override
  Duration get baseRetryDelay => const Duration(seconds: 1);

  @override
  bool get enableSafeHeaders => false; // 保持原有行为

  @override
  Map<String, String> get customHeaders => {};
}
