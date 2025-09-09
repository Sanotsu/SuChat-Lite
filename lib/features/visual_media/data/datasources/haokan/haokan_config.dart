import '../../../../../core/api/base_api_config.dart';

/// 好看漫画模块API配置
class HaokanApiConfig extends BaseApiConfig {
  static final HaokanApiConfig _instance = HaokanApiConfig._internal();
  factory HaokanApiConfig() => _instance;
  HaokanApiConfig._internal();

  @override
  String get moduleName => 'haokan';

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
