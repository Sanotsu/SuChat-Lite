import 'dart:io';

/// 定义消息数据类
/// 点击发送按钮时，根据选择和输入等内容返回的对象
class InputMessageData {
  final String text;
  // 这个是直接语音转文字但点击发送语音的音频(不会用来构建大模型请求参数)
  final File? sttAudio;
  final List<File>? images;
  // 2025-05-30 这个是用户输入时选择的音频文件(会用来构建大模型请求参数)
  final List<File>? audios;
  final List<File>? videos;
  // 本地可用获取文档文件
  final File? file;
  // 云端只能获取文档的文件名
  final String? cloudFileName;
  // 本地云端都使用同一个文档内容变量，两者不会同时存在
  final String? fileContent;

  // 可以根据需要添加更多类型
  // 2025-05-30 如果是千问omni模型，可指定输出语音的音色(如果是无，则不生成语音)
  final String? omniAudioVoice;

  // 2025-09-10 是否联网搜索(阿里云的部分模型支持)
  final bool? enableWebSearch;

  const InputMessageData({
    required this.text,
    this.sttAudio,
    this.images,
    this.audios,
    this.videos,
    this.file,
    this.cloudFileName,
    this.fileContent,
    this.omniAudioVoice,
    this.enableWebSearch = false,
  });

  bool get isAllEmpty {
    return text.isEmpty &&
        sttAudio == null &&
        (images == null || images!.isEmpty) &&
        (videos == null || videos!.isEmpty) &&
        (audios == null || audios!.isEmpty) &&
        file == null &&
        cloudFileName == null &&
        fileContent == null &&
        omniAudioVoice == null;
  }
}

// 2025-09-10 阿里云百炼平台中支持联网的模型列表
// https://help.aliyun.com/zh/model-studio/web-search
const List<String> aliyunWebSearchModels = [
  "qwen3-max",
  "qwen3-max-2025-09-23",
  "qwen-max",
  "qwen-max-latest",
  "qwen-plus",
  "qwen-plus-latest",
  "qwen-plus-2025-07-14",
  "qwen-plus-2025-07-28",
  "qwen-plus-2025-09-11",
  "qwen-flash",
  "qwen-flash-2025-07-28",
  "qwen-turbo",
  "qwen-turbo-latest",
  "qwen-turbo-2025-07-15",
  "qwq-plus",
  "Moonshot-Kimi-K2-Instruct",
];

// 2025-09-10 智谱开放平台中支持联网的模型列表
// https://docs.bigmodel.cn/api-reference/模型-api/对话补全#response-web-search
const List<String> zhipuWebSearchModels = [
  "glm-4.5",
  "glm-4.5-air",
  "glm-4.5-x",
  "glm-4.5-airx",
  "glm-4.5-flash",
  "glm-4-plus",
  "glm-4-air-250414",
  "glm-4-airx",
  "glm-4-flashx",
  "glm-4-flashx-250414",
];

// 2025-09-27 火山方舟大模型平台中支持联网的模型列表
// https://www.volcengine.com/docs/82379/1330310#dd261e17
const List<String> volcengineWebSearchModels = [
  "deepseek-v3-1-terminus",
  "deepseek-v3-1-250821",
  "doubao-seed-1-6-250615",
  "doubao-seed-1-6-flash-250828",
  "doubao-seed-1-6-thinking-250715",
];
