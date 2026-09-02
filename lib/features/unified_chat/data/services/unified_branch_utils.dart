import '../models/unified_chat_message.dart';

/// 统一聊天的分支视图算法(纯内存计算，不涉及数据库)
/// 语义与旧版 branch_chat 的 BranchManager 对齐：
/// - 当前分支视图 = 指定路径的祖先链 + 从该路径末端沿"每层最大branch_index"下行
/// - 未指定路径(默认)时 = 从根开始每层取最大branch_index的最新链
class UnifiedBranchUtils {
  /// 计算当前分支的显示消息列表(不含system消息，按树深度升序)
  ///
  /// [all] 会话全部消息
  /// [path] 当前分支路径；null或无效时按默认最新链计算
  static List<UnifiedChatMessage> computeDisplayMessages(
    List<UnifiedChatMessage> all,
    String? path,
  ) {
    final treeMessages = all.where((m) => !m.isSystem).toList();
    if (treeMessages.isEmpty) return [];

    final byPath = <String, UnifiedChatMessage>{
      for (final m in treeMessages) m.branchPath: m,
    };

    // 确定起点路径
    var startPath = path;
    if (startPath == null || !byPath.containsKey(startPath)) {
      startPath = defaultLatestPath(treeMessages);
    }
    if (startPath == null) return [];

    // 1. 路径前缀链：比如 "0/1/2" -> ["0", "0/1", "0/1/2"] 对应的消息
    final parts = startPath.split('/');
    final chain = <UnifiedChatMessage>[];
    for (var i = 0; i < parts.length; i++) {
      final prefix = parts.sublist(0, i + 1).join('/');
      final m = byPath[prefix];
      if (m != null) chain.add(m);
    }

    // 2. 从起点末端沿每层最大branch_index继续向下
    var current = byPath[startPath];
    while (current != null) {
      final child = _maxIndexChild(treeMessages, current.id);
      if (child == null) break;
      chain.add(child);
      current = child;
    }

    return chain;
  }

  /// 计算默认最新链路径：从根(每层取最大branch_index)一直到叶子
  /// 没有任何树消息时返回null
  static String? defaultLatestPath(List<UnifiedChatMessage> all) {
    final treeMessages = all.where((m) => !m.isSystem).toList();
    if (treeMessages.isEmpty) return null;

    // 根消息中branch_index最大的
    final roots = treeMessages.where((m) => m.parentId == null).toList()
      ..sort((a, b) => a.branchIndex.compareTo(b.branchIndex));

    if (roots.isEmpty) return null;

    var current = roots.last;
    // 沿每层最大子节点下行
    while (true) {
      final child = _maxIndexChild(treeMessages, current.id);
      if (child == null) break;
      current = child;
    }
    return current.branchPath;
  }

  /// 获取指定消息的同级兄弟列表(同parentId、同role、非system，按branch_index升序)
  /// 用于分支切换器显示"第n/共m个"
  static List<UnifiedChatMessage> siblingsOf(
    List<UnifiedChatMessage> all,
    UnifiedChatMessage message,
  ) {
    if (message.isSystem) return [message];

    return all
        .where(
          (m) =>
              !m.isSystem &&
              m.parentId == message.parentId &&
              m.role == message.role,
        )
        .toList()
      ..sort((a, b) => a.branchIndex.compareTo(b.branchIndex));
  }

  /// 计算指定消息在其兄弟列表中的位置(从0开始)
  static int siblingIndexOf(
    List<UnifiedChatMessage> all,
    UnifiedChatMessage message,
  ) {
    final siblings = siblingsOf(all, message);
    return siblings.indexWhere((m) => m.id == message.id);
  }

  /// 获取指定父节点下branch_index最大的子消息；没有子消息返回null
  static UnifiedChatMessage? _maxIndexChild(
    List<UnifiedChatMessage> all,
    String parentId,
  ) {
    UnifiedChatMessage? maxChild;
    for (final m in all) {
      if (m.parentId == parentId) {
        if (maxChild == null || m.branchIndex > maxChild.branchIndex) {
          maxChild = m;
        }
      }
    }
    return maxChild;
  }

  /// 判断某路径是否在指定分支路径上(自身或其后代)
  static bool isOnBranch(String messagePath, String branchPath) {
    return messagePath == branchPath || messagePath.startsWith('$branchPath/');
  }
}
