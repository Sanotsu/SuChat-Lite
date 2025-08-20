import 'dart:ui';

import '../../features/branch_chat/data/datasources/openai_compatible_apis.dart';
import '../../features/branch_chat/data/models/chat_completion_response.dart';
import '../../features/branch_chat/data/services/chat_service.dart';
import '../../shared/constants/constant_llm_enum.dart';
import '../../shared/widgets/toast_utils.dart';
import '../entities/cus_llm_model.dart';

/// 非常简化，使用文本对话大模型，调用同步响应API，得到翻译结果
/// 暂时就翻译成英文或者中文
///
///
// 可供翻译的目标语言
enum TargetLanguage {
  simplifiedChinese, // 中文(简体)
  traditionalChinese, // 中文(繁体)
  english, // 英语
  japanese, // 日语
  french, // 法语
  russian, // 俄语
  korean, // 韩语
  spanish, // 西班牙语
  portuguese, // 葡萄牙语
  german, // 德语
  vietnamese, // 越南语
  arabic, // 阿拉伯语
}

/// 非常简化，使用文本对话大模型，调用同步响应API，得到翻译结果
Future<String> getAITranslation(
  String text, {
  String? systemPrompt,
  TargetLanguage? tl,
}) async {
  try {
    final result = await _commonTranslateHandle(
      text,
      systemPrompt: systemPrompt,
      tl: tl,
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

// 如果要流式响应，需要在调用处处理
Future<(Stream<ChatCompletionResponse>, VoidCallback)> getStreamAITranslation(
  String text, {
  String? systemPrompt,
  TargetLanguage? tl,
}) async {
  try {
    final result = await _commonTranslateHandle(
      text,
      systemPrompt: systemPrompt,
      tl: tl,
      stream: true,
    );

    // 完全没处理错误情况
    return getStreamResponse(
      result["baseUrl"],
      result["headers"],
      result["requestBody"],
      stream: true,
    );
  } catch (e) {
    // 大模型翻译报错的话，直接弹窗提示，然后返回原文
    ToastUtils.showError("翻译出错：${e.toString()}");
    return (Stream<ChatCompletionResponse>.empty(), () {});
  }
}

Future<Map<String, dynamic>> _commonTranslateHandle(
  String text, {
  String? systemPrompt,
  TargetLanguage? tl,
  bool stream = false,
}) async {
  // 理论上提示词和目标语言至少必须传一个；如果都传，提示词优先
  // 如果提示词为空，根据目标语言设置默认提示词
  //    如果提示词为空，目标语言也为空，则默认使用中文
  if (systemPrompt == null || systemPrompt.trim().isEmpty) {
    tl ??= TargetLanguage.simplifiedChinese;
    systemPrompt = "你是一个翻译助手。请将用户输入的文本翻译成${tl.name}，保持原文的格式和风格。只返回翻译结果，不需要解释。";
  }

  // 2025-02-28 这里非常简单的使用指定内嵌的一个模型，理论上这个模型一定在的，也便宜
  CusLLMSpec model = CusLLMSpec(
    ApiPlatform.zhipu,
    "glm-4-flash-250414",
    LLModelType.cc,
    cusLlmSpecId: 'zhipu_glm_4_flash_250414_builtin',
  );

  // 默认智谱，可以简单使用内置的地址和密钥等
  Map<String, String> headers = await ChatService.getHeaders(model);
  String baseUrl = "${ChatService.getBaseUrl(model.platform)}/chat/completions";

  // 直接构建请求体
  final requestBody = {
    'model': model.model,
    'messages': [
      {"role": "system", "content": systemPrompt},
      {"role": "user", "content": text},
    ],
    'stream': stream,
  };

  // print("调用翻译API================");
  // print(baseUrl);
  // print(headers);
  // print(requestBody);

  return {"baseUrl": baseUrl, "headers": headers, "requestBody": requestBody};
}
