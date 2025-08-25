// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:ui';

import '../../core/entities/cus_llm_model.dart';
import '../../features/branch_chat/data/datasources/openai_compatible_apis.dart';
import '../../features/branch_chat/data/models/chat_completion_response.dart';
import '../../features/branch_chat/data/services/chat_service.dart';
import '../../shared/constants/constant_llm_enum.dart';
import '../../shared/widgets/toast_utils.dart';

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

  /// 同步翻译方法
  /// 2025-08-25 统一风格，不再支持手动传入翻译系统提示词，直接在这个service内嵌
  static Future<String> translate(
    String text,
    TargetLanguage targetLang, {
    TargetLanguage? sourceLang,
    CusLLMSpec? model,
  }) async {
    try {
      final result = await _buildTranslationRequest(
        text,
        targetLang,
        sourceLang: sourceLang,
        model: model,
        stream: false,
      );

      final (stream, cancelFunc) = await getStreamResponse(
        result["baseUrl"],
        result["headers"],
        result["requestBody"],
        stream: false,
      );

      // 处理流式响应的内容(简单获取最后结果)
      String finalContent = "";
      await for (final chunk in stream) {
        finalContent += chunk.cusText;
      }
      return finalContent;
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

  /// 流式翻译方法
  static Future<(Stream<ChatCompletionResponse>, VoidCallback)> translateStream(
    String text,
    TargetLanguage targetLang, {
    TargetLanguage? sourceLang,
    CusLLMSpec? model,
  }) async {
    try {
      final result = await _buildTranslationRequest(
        text,
        targetLang,
        sourceLang: sourceLang,
        model: model,
        stream: true,
      );

      return getStreamResponse(
        result["baseUrl"],
        result["headers"],
        result["requestBody"],
        stream: true,
      );
    } catch (e) {
      // 大模型翻译报错的话，直接弹窗提示，然后返回空流
      ToastUtils.showError("翻译出错：${e.toString()}");
      return (Stream<ChatCompletionResponse>.empty(), () {});
    }
  }

  /// 快速流式翻译到中文
  static Future<(Stream<ChatCompletionResponse>, VoidCallback)>
  translateStreamToChinese(String text, {bool simplified = true}) {
    return translateStream(
      text,
      simplified ? TargetLanguage.zh : TargetLanguage.zh_tw,
    );
  }

  /// 统一的翻译请求构建方法
  static Future<Map<String, dynamic>> _buildTranslationRequest(
    String text,
    TargetLanguage targetLang, {
    TargetLanguage? sourceLang,
    CusLLMSpec? model,
    required bool stream,
  }) async {
    // 确定使用的模型
    final usedModel =
        model ??
        CusLLMSpec(
          ApiPlatform.zhipu,
          "glm-4-flash-250414",
          LLModelType.cc,
          cusLlmSpecId: 'zhipu_glm_4_flash_250414_builtin',
        );

    // 获取API配置
    final headers = await ChatService.getHeaders(usedModel);
    final baseUrl =
        "${ChatService.getBaseUrl(usedModel.platform)}/chat/completions";

    // 构建请求体
    Map<String, dynamic> requestBody = {
      'model': usedModel.model,
      'stream': stream,
      'messages': [
        {"role": "user", "content": text},
      ],
    };

    // 如果是qwen-mt模型，使用专用配置（不需要系统提示词）
    if (usedModel.model.contains("qwen-mt")) {
      requestBody['translation_options'] = {
        "source_lang": sourceLang?.name ?? TargetLanguage.auto.name,
        "target_lang": targetLang.name,
      };
    } else {
      // 普通对话模型配置处理提示词
      final processedPrompt =
          "你是一个翻译助手。请将用户输入的文本翻译成${_getTargetLanguageName(targetLang)}，保持原文的格式和风格。只返回翻译结果，不需要解释。";

      requestBody['messages'] = [
        {"role": "system", "content": processedPrompt},
        {"role": "user", "content": text},
      ];
    }

    return {"baseUrl": baseUrl, "headers": headers, "requestBody": requestBody};
  }
}
