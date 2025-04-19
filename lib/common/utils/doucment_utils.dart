// ignore_for_file: constant_identifier_names

// 定义标记和处理函数
class DocumentUtils {
  static const String DOC_START_PREFIX = "[[DOC_START:";
  static const String DOC_END = "[[DOC_END]]";

  // 包装文档内容
  static String wrapDocumentContent(String content, String fileName) {
    return "$DOC_START_PREFIX$fileName]]\n$content\n$DOC_END";
  }

  // 检查消息是否包含文档
  static bool hasDocument(String message) {
    return message.contains(DOC_START_PREFIX) && message.contains(DOC_END);
  }

  // 提取显示消息（用于UI显示）
  static String getDisplayMessage(String message) {
    if (!hasDocument(message)) return message;

    final RegExp regex = RegExp(
      r'\[\[DOC_START:(.*?)\]\][\s\S]*?\[\[DOC_END\]\]',
    );
    return message.replaceAllMapped(regex, (match) {
      final fullMatch = match.group(0) ?? '';
      final fileName = extractFileName(fullMatch);

      // 替换为文件引用提示
      return "[📄 文件: $fileName]";
    });
  }

  // 提取文件名
  static String extractFileName(String message) {
    final RegExp regex = RegExp(r'\[\[DOC_START:(.*?)\]\]');
    final match = regex.firstMatch(message);
    return match?.group(1) ?? '未知文件';
  }

  // 提取文档内容（用于API调用）
  static String extractDocumentContent(String message) {
    final RegExp regex = RegExp(
      r'\[\[DOC_START:.*?\]\]\n([\s\S]*?)\n\[\[DOC_END\]\]',
    );
    final match = regex.firstMatch(message);
    return match?.group(1) ?? '';
  }
}
