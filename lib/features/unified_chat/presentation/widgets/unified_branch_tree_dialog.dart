import 'package:flutter/material.dart';

import '../../../../core/utils/screen_helper.dart';
import '../../data/models/unified_chat_message.dart';

/// 统一聊天的对话分支树对话框(从旧版 branch_chat 的 BranchTreeDialog 移植)
/// 数据源为会话全部消息(含所有分支)，按 parent_id 构建树
class UnifiedBranchTreeDialog extends StatefulWidget {
  // 会话全部消息(含所有分支)
  final List<UnifiedChatMessage> messages;

  // 当前选中的分支路径
  final String currentPath;

  // 选择路径后的回调
  final Function(String) onPathSelected;

  const UnifiedBranchTreeDialog({
    super.key,
    required this.messages,
    required this.currentPath,
    required this.onPathSelected,
  });

  @override
  State<UnifiedBranchTreeDialog> createState() =>
      _UnifiedBranchTreeDialogState();
}

class _UnifiedBranchTreeDialogState extends State<UnifiedBranchTreeDialog> {
  late String selectedPath;

  @override
  void initState() {
    super.initState();
    selectedPath = widget.currentPath;
  }

  @override
  Widget build(BuildContext context) {
    final content = Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('对话分支树'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('确定'),
            onPressed: () {
              widget.onPathSelected(selectedPath);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _buildLegendItem(Colors.blue, '用户消息'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.green, 'AI响应'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.blue.withValues(alpha: 0.1), '当前选中'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: ExpansionTile(
                initiallyExpanded: true,
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_tree, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      '当前分支路径',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${selectedPath.split('/').length} 条消息)',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: _buildCurrentPathInfo(context),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.account_tree, size: 16),
                SizedBox(width: 8),
                Text(
                  '对话分支消息',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width - 16,
                  ),
                  child: _buildBranchTree(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // 桌面用大尺寸窗口弹窗，移动端保持全屏
    if (ScreenHelper.isDesktop()) {
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 640),
          child: content,
        ),
      );
    }
    return Dialog.fullscreen(child: content);
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  List<UnifiedChatMessage> get _treeMessages =>
      widget.messages.where((m) => !m.isSystem).toList();

  Widget _buildBranchTree(BuildContext context) {
    final roots = _treeMessages.where((m) => m.parentId == null).toList()
      ..sort((a, b) => a.branchIndex.compareTo(b.branchIndex));

    return _buildTreeNode(context, roots, 0);
  }

  Widget _buildTreeNode(
    BuildContext context,
    List<UnifiedChatMessage> nodes,
    int depth,
  ) {
    final availableNodes = List<UnifiedChatMessage>.from(nodes)
      ..sort((a, b) => a.branchIndex.compareTo(b.branchIndex));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: availableNodes.map((node) {
        final isCurrentPath =
            node.branchPath == selectedPath ||
            selectedPath.startsWith('${node.branchPath}/');

        final children =
            _treeMessages.where((m) => m.parentId == node.id).toList()
              ..sort((a, b) => a.branchIndex.compareTo(b.branchIndex));

        final isUser = node.isUser;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                if (depth > 0)
                  Positioned(
                    left: (depth - 1) * 24 + 12,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 2, color: Colors.grey.shade200),
                  ),
                InkWell(
                  onTap: () => setState(() => selectedPath = node.branchPath),
                  child: Container(
                    margin: EdgeInsets.only(left: depth * 24),
                    padding: const EdgeInsets.all(8),
                    constraints: BoxConstraints(
                      maxWidth: ScreenHelper.isDesktop() ? 640 : 300,
                      minWidth: ScreenHelper.isDesktop() ? 640 : 300,
                    ),
                    decoration: BoxDecoration(
                      color: node.branchPath == selectedPath
                          ? (isUser
                                ? Colors.blue.withValues(alpha: 0.1)
                                : Colors.green.withValues(alpha: 0.1))
                          : null,
                      border: Border.all(
                        color: isUser ? Colors.blue : Colors.green,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isUser ? Icons.person : Icons.smart_toy,
                              size: 16,
                              color: isUser ? Colors.blue : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isUser ? '用户' : 'AI',
                              style: TextStyle(
                                color: isUser ? Colors.blue : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.layers,
                                    size: 12,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${depth + 1}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    width: 1,
                                    height: 10,
                                    color: Colors.grey.shade300,
                                  ),
                                  Icon(
                                    Icons.account_tree,
                                    size: 12,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${node.branchIndex + 1}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isCurrentPath) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.check_circle,
                                color: Colors.blue,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          node.content ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (node.thinkingContent != null &&
                            node.thinkingContent!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            node.thinkingContent!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (children.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildTreeNode(context, children, depth + 1),
            ],
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCurrentPathInfo(BuildContext context) {
    final pathParts = selectedPath.split('/');
    final messages = _treeMessages;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: pathParts.asMap().entries.expand((entry) {
        final i = entry.key;
        final part = entry.value;

        // 获取当前路径对应的消息
        final currentPath = pathParts.sublist(0, i + 1).join('/');
        final message = messages.firstWhere(
          (m) => m.branchPath == currentPath,
          orElse: () => messages.first,
        );

        return [
          if (i > 0)
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: message.isUser
                  ? Colors.blue.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: message.isUser
                    ? Colors.blue.withValues(alpha: 0.3)
                    : Colors.green.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '${(int.tryParse(part) ?? 0) + 1}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: message.isUser ? Colors.blue : Colors.green,
              ),
            ),
          ),
        ];
      }).toList(),
    );
  }
}
