import 'dart:io';

/// 定义消息数据类
/// 点击发送按钮时，根据选择和输入等内容返回的对象
class InputMessageData {
  final String text;
  final List<File>? images;
  // 音频文件(选择音频文件、或者直接语音输入不是使用转文字而是发送语音也是这个变量)
  final File? audio;
  // 本地可用获取文档文件
  final File? file;
  // 云端只能获取文档的文件名
  final String? cloudFileName;
  // 本地云端都使用同一个文档内容变量，两者不会同时存在
  final String? fileContent;
  final List<File>? videos;
  // 可以根据需要添加更多类型

  const InputMessageData({
    required this.text,
    this.images,
    this.audio,
    this.file,
    this.cloudFileName,
    this.fileContent,
    this.videos,
  });
}
