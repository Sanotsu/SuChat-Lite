import 'package:flutter/material.dart';
import '../../../../common/constants/constants.dart';
import '../../../../common/utils/screen_helper.dart';
import '../../../../models/brief_ai_tools/branch_chat/branch_chat_message.dart';

class BranchTreeDialog extends StatefulWidget {
  final List<BranchChatMessage> messages;
  final String currentPath;
  final Function(String) onPathSelected;

  const BranchTreeDialog({
    super.key,
    required this.messages,
    required this.currentPath,
    required this.onPathSelected,
  });

  @override
  State<BranchTreeDialog> createState() => _BranchTreeDialogState();
}

class _BranchTreeDialogState extends State<BranchTreeDialog> {
  late String selectedPath;

  @override
  void initState() {
    super.initState();
    selectedPath = widget.currentPath;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
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
            preferredSize: Size.fromHeight(48),
            child: Container(
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  _buildLegendItem(Colors.blue, '用户消息'),
                  SizedBox(width: 16),
                  _buildLegendItem(Colors.green, 'AI响应'),
                  SizedBox(width: 16),
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
              child: ExpansionTile(
                initiallyExpanded: true,
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.account_tree, size: 16),
                    SizedBox(width: 8),
                    Text(
                      '当前分支路径',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '(${selectedPath.split('/').length ~/ 2} 轮对话)',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: _buildCurrentPathInfo(context),
                  ),
                ],
              ),
            ),
            Padding(
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
                  padding: EdgeInsets.all(8),
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
      ),
    );
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

  Widget _buildBranchTree(BuildContext context) {
    final sortedMessages = List<BranchChatMessage>.from(widget.messages)
      ..sort((a, b) => a.createTime.compareTo(b.createTime));

    return _buildTreeNode(
      context,
      sortedMessages.where((m) => m.parent.target == null).toList(),
      sortedMessages,
      0,
    );
  }

  Widget _buildTreeNode(
    BuildContext context,
    List<BranchChatMessage> nodes,
    List<BranchChatMessage> allMessages,
    int depth,
  ) {
    final availableNodes =
        nodes.where((node) => allMessages.contains(node)).toList()
          ..sort((a, b) => a.branchIndex.compareTo(b.branchIndex));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          availableNodes.map((node) {
            final isCurrentPath =
                node.branchPath == selectedPath ||
                selectedPath.startsWith('${node.branchPath}/');

            final children =
                allMessages
                    .where(
                      (m) =>
                          m.parent.target?.id == node.id &&
                          allMessages.contains(m),
                    )
                    .toList()
                  ..sort((a, b) => a.branchIndex.compareTo(b.branchIndex));

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
                      onTap:
                          () => setState(() => selectedPath = node.branchPath),
                      child: Container(
                        margin: EdgeInsets.only(left: depth * 24),
                        padding: EdgeInsets.all(8),
                        constraints: BoxConstraints(
                          maxWidth: ScreenHelper.isDesktop() ? 640 : 300,
                          minWidth: ScreenHelper.isDesktop() ? 640 : 300,
                        ),
                        decoration: BoxDecoration(
                          color:
                              node.branchPath == selectedPath
                                  ? (node.role == CusRole.user.name
                                      ? Colors.blue.withValues(alpha: 0.1)
                                      : Colors.green.withValues(alpha: 0.1))
                                  : null,
                          border: Border.all(
                            color:
                                node.role == CusRole.user.name
                                    ? Colors.blue
                                    : Colors.green,
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
                                  node.role == CusRole.user.name
                                      ? Icons.person
                                      : Icons.smart_toy,
                                  size: 16,
                                  color:
                                      node.role == CusRole.user.name
                                          ? Colors.blue
                                          : Colors.green,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  node.role == CusRole.user.name ? '用户' : 'AI',
                                  style: TextStyle(
                                    color:
                                        node.role == CusRole.user.name
                                            ? Colors.blue
                                            : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: EdgeInsets.symmetric(
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
                                      SizedBox(width: 4),
                                      Text(
                                        '${depth + 1}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      Container(
                                        margin: EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        width: 1,
                                        height: 10,
                                        color: Colors.grey[300],
                                      ),
                                      Icon(
                                        Icons.account_tree,
                                        size: 12,
                                        color: Colors.grey[600],
                                      ),
                                      SizedBox(width: 4),
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
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.blue,
                                    size: 16,
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              node.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (node.reasoningContent != null) ...[
                              SizedBox(height: 4),
                              Text(
                                node.reasoningContent!,
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
                  SizedBox(height: 8),
                  _buildTreeNode(context, children, allMessages, depth + 1),
                ],
              ],
            );
          }).toList(),
    );
  }

  Widget _buildCurrentPathInfo(BuildContext context) {
    final pathParts = selectedPath.split('/');
    final messages = widget.messages;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children:
          pathParts.asMap().entries.expand((entry) {
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
                Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                decoration: BoxDecoration(
                  color:
                      message.role == CusRole.user.name
                          ? Colors.blue.withValues(alpha: 0.1)
                          : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        message.role == CusRole.user.name
                            ? Colors.blue.withValues(alpha: 0.3)
                            : Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${int.parse(part) + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color:
                        message.role == CusRole.user.name
                            ? Colors.blue
                            : Colors.green,
                  ),
                ),
              ),
            ];
          }).toList(),
    );
  }
}
