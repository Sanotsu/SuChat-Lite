import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/simple_tools.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../viewmodels/unified_chat_viewmodel.dart';
import '../pages/search_tools_settings_page.dart';

/// 聊天页面顶部应用栏
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuPressed;

  const ChatAppBar({super.key, required this.onMenuPressed});

  @override
  Widget build(BuildContext context) {
    return Consumer<UnifiedChatViewModel>(
      builder: (context, viewModel, child) {
        return AppBar(
          // leading: IconButton(
          //   onPressed: onMenuPressed,
          //   icon: const Icon(Icons.menu),
          // ),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                viewModel.currentConversation?.title ?? '新对话',
                style: const TextStyle(fontSize: 16),
              ),
              if (viewModel.currentModel != null)
                Text(
                  viewModel.currentModel!.displayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
          actions: [
            // // 流式状态指示器
            // if (viewModel.isStreaming)
            //   Container(
            //     margin: const EdgeInsets.only(right: 8),
            //     child: Row(
            //       mainAxisSize: MainAxisSize.min,
            //       children: [
            //         SizedBox(
            //           width: 16,
            //           height: 16,
            //           child: CircularProgressIndicator(
            //             strokeWidth: 2,
            //             valueColor: AlwaysStoppedAnimation<Color>(
            //               Theme.of(context).colorScheme.primary,
            //             ),
            //           ),
            //         ),
            //         const SizedBox(width: 8),
            //         Text(
            //           '生成中...',
            //           style: Theme.of(context).textTheme.bodySmall,
            //         ),
            //       ],
            //     ),
            //   ),

            // // 停止生成按钮
            // if (viewModel.isStreaming)
            //   IconButton(
            //     onPressed: () => viewModel.stopStreaming(),
            //     icon: const Icon(Icons.stop),
            //     tooltip: '停止生成',
            //   ),
            IconButton(onPressed: onMenuPressed, icon: const Icon(Icons.menu)),

            // 更多操作菜单
            PopupMenuButton<String>(
              onSelected: (value) =>
                  _handleMenuAction(context, value, viewModel),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'search_tools',
                  child: Row(
                    children: [
                      Icon(Icons.search),
                      SizedBox(width: 8),
                      Text('搜索工具设置'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all),
                      SizedBox(width: 8),
                      Text('清空对话'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.download),
                      SizedBox(width: 8),
                      Text('导出对话'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'new',
                  child: Row(
                    children: [
                      Icon(Icons.add),
                      SizedBox(width: 8),
                      Text('新建对话'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    UnifiedChatViewModel viewModel,
  ) {
    switch (action) {
      case 'search_tools':
        _openSearchToolsSettings(context);
        break;
      case 'clear':
        _showClearConfirmDialog(context, viewModel);
        break;
      case 'export':
        _exportConversation(context, viewModel);
        break;
      case 'new':
        _createNewConversation(context, viewModel);
        break;
    }
  }

  void _showClearConfirmDialog(
    BuildContext context,
    UnifiedChatViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空对话'),
        content: const Text('确定要清空当前对话的所有消息吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.clearConversation();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _exportConversation(
    BuildContext context,
    UnifiedChatViewModel viewModel,
  ) async {
    try {
      bool flag = await requestStoragePermission();
      if (!flag) {
        ToastUtils.showError("未授权访问设备外部存储，无法导出对话。");
        return;
      }

      final filePath = await viewModel.exportConversation();
      if (filePath != null && context.mounted) {
        ToastUtils.showSuccess('对话已导出到: $filePath');
      }
    } catch (e) {
      ToastUtils.showError('导出失败: $e');
      rethrow;
    }
  }

  void _createNewConversation(
    BuildContext context,
    UnifiedChatViewModel viewModel,
  ) {
    viewModel.createNewConversation();
  }

  void _openSearchToolsSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchToolsSettingsPage()),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
