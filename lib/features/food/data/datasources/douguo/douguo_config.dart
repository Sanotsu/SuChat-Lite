import '../../../../../core/api/base_api_config.dart';

/// 豆果模块API配置
class DouguoApiConfig extends BaseApiConfig {
  static final DouguoApiConfig _instance = DouguoApiConfig._internal();
  factory DouguoApiConfig() => _instance;
  DouguoApiConfig._internal();

  @override
  String get moduleName => 'douguo';

  @override
  Duration get defaultCacheDuration => const Duration(minutes: 10);

  @override
  Duration get requestInterval => const Duration(seconds: 1);

  @override
  int get maxRetries => 3;

  @override
  Duration get baseRetryDelay => const Duration(seconds: 1);

  @override
  bool get enableSafeHeaders => true; // 豆果启用安全headers

  @override
  Map<String, String> get customHeaders => {};
}
