// 翻译相关模型

import '../../../../shared/services/translation_service.dart';

/// 支持的语言列表
/// 暂时只列出少量内容，更多可参考：
/// https://bailian.console.aliyun.com/?switchAgent=10147514&productCode=p_efm&switchUserType=3&tab=doc#/doc/?type=model&url=2860790
class SupportedLanguages {
  static const List<LanguageOption> languages = [
    LanguageOption(
      code: 'auto',
      name: '自动',
      nativeName: '自动',
      value: TargetLanguage.auto,
    ),
    LanguageOption(
      code: 'zh',
      name: '简体中文',
      nativeName: '简体中文',
      value: TargetLanguage.zh,
    ),
    LanguageOption(
      code: 'zh_tw',
      name: '繁体中文',
      nativeName: '繁體中文',
      value: TargetLanguage.zh_tw,
    ),
    LanguageOption(
      code: 'en',
      name: '英语',
      nativeName: 'English',
      value: TargetLanguage.en,
    ),
    LanguageOption(
      code: 'ja',
      name: '日语',
      nativeName: '日本語',
      value: TargetLanguage.ja,
    ),
    LanguageOption(
      code: 'fr',
      name: '法语',
      nativeName: 'Français',
      value: TargetLanguage.fr,
    ),
    LanguageOption(
      code: 'ru',
      name: '俄语',
      nativeName: 'Русский',
      value: TargetLanguage.ru,
    ),
    LanguageOption(
      code: 'ko',
      name: '韩语',
      nativeName: '한국어',
      value: TargetLanguage.ko,
    ),
    LanguageOption(
      code: 'es',
      name: '西班牙语',
      nativeName: 'Español',
      value: TargetLanguage.es,
    ),
    LanguageOption(
      code: 'pt',
      name: '葡萄牙语',
      nativeName: 'Português',
      value: TargetLanguage.pt,
    ),

    LanguageOption(
      code: 'de',
      name: '德语',
      nativeName: 'Deutsch',
      value: TargetLanguage.de,
    ),
    LanguageOption(
      code: 'vi',
      name: '越南语',
      nativeName: 'Tiếng Việt',
      value: TargetLanguage.vi,
    ),

    LanguageOption(
      code: 'ar',
      name: '阿拉伯语',
      nativeName: 'العربية',
      value: TargetLanguage.ar,
    ),

    LanguageOption(
      code: 'it',
      name: '意大利语',
      nativeName: 'Italiano',
      value: TargetLanguage.it,
    ),
    LanguageOption(
      code: 'th',
      name: '泰语',
      nativeName: 'ไทย',
      value: TargetLanguage.th,
    ),
  ];

  static LanguageOption? getLanguage(String code) {
    try {
      return languages.firstWhere((lang) => lang.code == code);
    } catch (e) {
      return null;
    }
  }

  static String getLanguageName(String code) {
    final lang = getLanguage(code);
    return lang?.name ?? code;
  }
}

/// 语言选项
class LanguageOption {
  final String code;
  final String name;
  final String nativeName;
  final TargetLanguage value;

  const LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.value,
  });

  @override
  String toString() => '$name ($nativeName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanguageOption &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          value == other.value;

  @override
  int get hashCode => code.hashCode ^ value.hashCode;
}
