// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:ui';

import '../widgets/toast_utils.dart';
import 'unified_llm_service.dart';

// 可供翻译的目标语言
enum TargetLanguage {
  auto,
  zh, // 中文(简体)
  zh_tw, // 中文(繁体)
  en, // 英语
  ja, // 日语
  fr, // 法语
  ru, // 俄语
  ko, // 韩语
  es, // 西班牙语
  pt, // 葡萄牙语
  de, // 德语
  vi, // 越南语
  ar, // 阿拉伯语
  it, // 意大利语
  th, // 泰语;
}

/// 翻译服务静态工具类
/// 2026-09-07 旧 LLM 体系退役：模型入参改为统一模型库条目
/// (UnifiedModelEntry = 模型 + 所属平台，来自聊天页平台管理)，
/// 经 UnifiedLLMService 门面调用；qwen-mt 系列专用 translation_options 协议保留
class TranslationService {
  TranslationService._();

  /// 获取目标语言的中文名称
  static String _getTargetLanguageName(TargetLanguage tl) {
    switch (tl) {
      case TargetLanguage.zh:
        return '中文(简体)';
      case TargetLanguage.zh_tw:
        return '中文(繁体)';
      case TargetLanguage.en:
        return '英语';
      case TargetLanguage.ja:
        return '日语';
      case TargetLanguage.fr:
        return '法语';
      case TargetLanguage.ru:
        return '俄语';
      case TargetLanguage.ko:
        return '韩语';
      case TargetLanguage.es:
        return '西班牙语';
      case TargetLanguage.pt:
        return '葡萄牙语';
      case TargetLanguage.de:
        return '德语';
      case TargetLanguage.vi:
        return '越南语';
      case TargetLanguage.ar:
        return '阿拉伯语';
      case TargetLanguage.it:
        return '意大利语';
      case TargetLanguage.th:
        return '泰语';
      default:
        return '自动';
    }
  }

  /// 解析实际使用的模型条目：未指定时取统一库第一个可用对话模型
  /// (2026-09-07 旧"内置默认模型"随作者 Key 一并退役，不再有免费默认)
  static Future<UnifiedModelEntry> _resolveEntry(
    UnifiedModelEntry? entry,
  ) async {
    if (entry != null) return entry;

    final available = await UnifiedLLMService.loadModelEntries();
    if (available.isEmpty) {
      throw Exception('暂无可用模型，请先在聊天页-平台管理中配置对话模型');
    }
    return available.first;
  }

  /// 同步翻译方法（返回译文；失败弹错并返回原文）
  static Future<String> translate(
    String text,
    TargetLanguage targetLang, {
    TargetLanguage? sourceLang,
    UnifiedModelEntry? entry,
  }) async {
    try {
      final usedEntry = await _resolveEntry(entry);
      final (messages, extraParams) = _buildTranslationRequest(
        text,
        targetLang,
        sourceLang: sourceLang,
        entry: usedEntry,
      );

      final response = await UnifiedLLMService.sendChat(
        entry: usedEntry,
        messages: messages,
        extraParams: extraParams,
      );

      final content = response.choices.isNotEmpty
          ? response.choices.first.message?.content
          : null;
      return content ?? response.customText;
    } catch (e) {
      // 大模型翻译报错的话，直接弹窗提示，然后返回原文
      ToastUtils.showError("翻译出错：${e.toString()}");
      return text;
    }
  }

  /// 快速翻译到中文
  static Future<String> translateToChinese(
    String text, {
    bool simplified = true,
  }) {
    return translate(
      text,
      simplified ? TargetLanguage.zh : TargetLanguage.zh_tw,
    );
  }

  /// 流式翻译方法（返回完整响应流，思考模型的 reasoning_content 由页面分类展示）
  static Future<(Stream, VoidCallback)> translateStream(
    String text,
    TargetLanguage targetLang, {
    TargetLanguage? sourceLang,
    UnifiedModelEntry? entry,
  }) async {
    try {
      final usedEntry = await _resolveEntry(entry);
      final (messages, extraParams) = _buildTranslationRequest(
        text,
        targetLang,
        sourceLang: sourceLang,
        entry: usedEntry,
      );

      return await UnifiedLLMService.sendChatStream(
        entry: usedEntry,
        messages: messages,
        extraParams: extraParams,
      );
    } catch (e) {
      // 大模型翻译报错的话，直接弹窗提示，然后返回空流
      ToastUtils.showError("翻译出错：${e.toString()}");
      return (const Stream.empty(), () {});
    }
  }

  /// 快速流式翻译到中文
  static Future<(Stream, VoidCallback)> translateStreamToChinese(
    String text, {
    bool simplified = true,
  }) {
    return translateStream(
      text,
      simplified ? TargetLanguage.zh : TargetLanguage.zh_tw,
    );
  }

  /// 统一的翻译请求构建方法
  /// 返回 (messages, extraParams)：qwen-mt 系列走专用 translation_options
  /// 协议(不需要系统提示词)，普通模型注入内嵌翻译助手提示词
  static (List<Map<String, dynamic>>, Map<String, dynamic>?)
  _buildTranslationRequest(
    String text,
    TargetLanguage targetLang, {
    TargetLanguage? sourceLang,
    required UnifiedModelEntry entry,
  }) {
    // 如果是qwen-mt模型，使用专用配置（不需要系统提示词）
    if (entry.model.modelName.contains("qwen-mt")) {
      final extraParams = {
        'translation_options': {
          "source_lang": sourceLang?.name ?? TargetLanguage.auto.name,
          "target_lang": targetLang.name,
        },
      };
      return (
        [
          {"role": "user", "content": text},
        ],
        extraParams,
      );
    }

    // 普通对话模型配置处理提示词
    final processedPrompt =
        "你是一个翻译助手。请将用户输入的文本翻译成${_getTargetLanguageName(targetLang)}，保持原文的格式和风格。只返回翻译结果，不需要解释。";

    return (
      [
        {"role": "system", "content": processedPrompt},
        {"role": "user", "content": text},
      ],
      null,
    );
  }
}
