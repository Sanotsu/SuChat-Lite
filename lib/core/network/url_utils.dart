import 'package:dio/dio.dart';

class UrlUtils {
  // 私有构造函数防止实例化
  UrlUtils._();

  static final Dio _dio = Dio()
    ..options.connectTimeout = const Duration(seconds: 30)
    ..options.receiveTimeout = const Duration(seconds: 60);

  // 检查URL是否有效（格式正确且可访问）
  // 返回Future<bool>表示是否可用
  static Future<bool> isUrlAvailable(String url) async {
    if (!_isValidUrlFormat(url)) {
      return false;
    }

    return await _isUrlAccessible(url);
  }

  /// 检查URL格式是否有效
  static bool _isValidUrlFormat(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// 检查URL是否可访问
  static Future<bool> _isUrlAccessible(String url) async {
    try {
      // 发送HEAD请求，只获取响应头不下载内容
      final response = await _dio.head(url);

      // 2xx和3xx状态码都认为可用
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 400;
    } on DioException catch (e) {
      // 处理各种网络错误
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        // 超时视为不可用
        return false;
      }

      // 其他错误如404、500等也视为不可用
      return false;
    } catch (e) {
      // 其他异常情况
      return false;
    }
  }

  /// 关闭Dio实例（在应用退出时调用）
  static void dispose() {
    _dio.close();
  }
}
