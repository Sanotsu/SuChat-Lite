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
