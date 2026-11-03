/// 2026-09-09 媒体面板条目模型
/// 数据源为消息记录(方案B)：扫描助手消息metadata中的AI生成产物，
/// 关联同轮用户消息的prompt/模型/会话信息——资源与生成条件一并可见
enum MediaLibraryType { image, video, audio }

class MediaLibraryItem {
  final MediaLibraryType type;

  /// 产物本地路径(生成时已下载到unified_chat_media目录)
  final String filePath;

  /// 生成条件：同轮用户消息的提示词/合成文本
  final String prompt;

  /// 生成时的模型(消息modelNameUsed，如doubao-seedream、cosyvoice等)
  final String? modelName;

  final String? platformId;

  /// 所属会话(详情页可跳转回看完整上下文)
  final String conversationId;
  final String conversationTitle;

  final DateTime createdAt;

  /// 生成参数(图片尺寸/质量/steps、视频分辨率/时长、TTS音色/语速等)
  /// 2026-09-09起新生成的内容才有；历史存量数据为空
  final Map<String, dynamic> genParams;

  const MediaLibraryItem({
    required this.type,
    required this.filePath,
    required this.prompt,
    required this.conversationId,
    required this.conversationTitle,
    required this.createdAt,
    this.modelName,
    this.platformId,
    this.genParams = const {},
  });
}
