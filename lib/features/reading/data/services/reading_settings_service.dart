import '../../../../core/storage/cus_get_storage.dart';

/// 阅读设置服务 - 管理阅读相关的用户偏好设置
class ReadingSettingsService {
  static const String _fontSizeKey = 'reading_font_size';
  static const String _isDarkModeKey = 'reading_is_dark_mode';
  
  final CusGetStorage _storage = CusGetStorage();
  
  /// 获取字体大小
  double getFontSize() {
    return _storage.box.read(_fontSizeKey) ?? 16.0;
  }
  
  /// 设置字体大小
  Future<void> setFontSize(double fontSize) async {
    await _storage.box.write(_fontSizeKey, fontSize);
  }
  
  /// 获取夜间模式状态
  bool getIsDarkMode() {
    return _storage.box.read(_isDarkModeKey) ?? false;
  }
  
  /// 设置夜间模式状态
  Future<void> setIsDarkMode(bool isDarkMode) async {
    await _storage.box.write(_isDarkModeKey, isDarkMode);
  }
}
