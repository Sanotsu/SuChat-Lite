import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/screen_helper.dart';
import '../../../ai_tool_page.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../data/database/unified_chat_db_init.dart';
import '../viewmodels/unified_chat_viewmodel.dart';
import '../pages/chat_background_picker_page.dart';
import '../pages/search_tools_settings_page.dart';
import 'appearance_tool_widgets.dart';

/// 聊天页面顶部应用栏
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuPressed;

  /// 桌面：内容区宽度切换回调(标准880限宽/宽屏铺满)；null=不显示切换按钮(移动端)
  final VoidCallback? onToggleWidescreen;
  final bool isWidescreen;

  const ChatAppBar({
    super.key,
    required this.onMenuPressed,
    this.onToggleWidescreen,
    this.isWidescreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UnifiedChatViewModel>(
      builder: (context, viewModel, child) {
        return AppBar(
          // 背景图模式下AppBar透明，背景从页面顶层透出(对齐旧版)
          backgroundColor: viewModel.hasBackgroundImage
              ? Colors.transparent
              : null,
          // 首页即聊天页：左上角为对话历史抽屉入口(不再是返回按钮)
          leading: IconButton(
            onPressed: onMenuPressed,
            icon: const Icon(Icons.menu),
            tooltip: '对话历史',
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                viewModel.currentConversation?.title ?? '新对话',
                style: const TextStyle(fontSize: 15),
              ),
              if (viewModel.currentModel != null)
                Text(
                  viewModel.currentModel!.modelName,
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
            // 用户设置入口已收敛到侧栏/抽屉底部(避免重复入口)，此处不再放设置图标

            // 桌面：内容区宽度切换(对齐Chatbox的做法)
            if (onToggleWidescreen != null)
              IconButton(
                onPressed: onToggleWidescreen,
                icon: Icon(
                  isWidescreen ? Icons.width_full : Icons.width_normal,
                ),
                tooltip: isWidescreen ? '切换为标准宽度' : '切换为宽屏模式',
              ),

            if (ScreenHelper.isMobile())
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AIToolPage()),
                  );
                },
                icon: Icon(Icons.apps),
                tooltip: '更多功能',
              ),

            // 更多操作菜单
            PopupMenuButton<String>(
              onSelected: (value) =>
                  _handleMenuAction(context, value, viewModel),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'more_tools',
                  child: Row(
                    children: [
                      Icon(Icons.apps),
                      SizedBox(width: 8),
                      Text('更多功能'),
                    ],
                  ),
                ),
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
                // ===== 外观设置(从旧版branch_chat移植) =====
                const PopupMenuItem(
                  value: 'text_size',
                  child: Row(
                    children: [
                      Icon(Icons.format_size),
                      SizedBox(width: 8),
                      Text('文字大小'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'background',
                  child: const Row(
                    children: [
                      Icon(Icons.image),
                      SizedBox(width: 8),
                      Text('切换背景'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'brief_mode',
                  child: Row(
                    children: [
                      const Icon(Icons.visibility_off),
                      const SizedBox(width: 8),
                      Text(viewModel.isBriefDisplay ? '详细显示' : '简洁显示'),
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
                  value: 'new',
                  child: Row(
                    children: [
                      Icon(Icons.add),
                      SizedBox(width: 8),
                      Text('新建对话'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.download),
                      SizedBox(width: 8),
                      Text('导出数据'),
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
      case 'more_tools':
        // 0.1.5: 旧版首页下拉手势入口迁移到聊天菜单
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AIToolPage()),
        );
        break;
      case 'search_tools':
        _openSearchToolsSettings(context);
        break;
      case 'text_size':
        _adjustTextScale(context, viewModel);
        break;
      case 'background':
        _openBackgroundPicker(context, viewModel);
        break;
      case 'brief_mode':
        viewModel.toggleBriefDisplay();
        ToastUtils.showInfo(viewModel.isBriefDisplay ? '已切换为简洁显示' : '已切换为详细显示');
        break;
      case 'clear':
        _showClearConfirmDialog(context, viewModel);
        break;
      case 'new':
        _createNewConversation(context, viewModel);
        break;
      case 'export':
        _exportConversation(context, viewModel);
        break;
    }
  }

  /// 调整消息文字大小(复用旧版branch_chat的滑块弹窗，存储key共用)
  void _adjustTextScale(BuildContext context, UnifiedChatViewModel viewModel) {
    adjustTextScale(context, viewModel.textScaleFactor, (value) {
      Navigator.of(context).pop();
      viewModel.setTextScale(value);
    });
  }

  /// 打开背景选择页(复用旧版branch_chat的背景选择页面，存储key共用)
  void _openBackgroundPicker(
    BuildContext context,
    UnifiedChatViewModel viewModel,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatBackgroundPickerPage(title: '聊天背景设置'),
      ),
    ).then((confirmed) {
      // 保存返回true后重载背景与字体颜色配置
      if (confirmed == true) {
        viewModel.refreshBackgroundSettings();
      }
    });
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
      final closeToast = ToastUtils.showLoading("正在导出对话数据...");

      // 导出数据库
      final UnifiedChatDBInit dbInit = UnifiedChatDBInit();
      String filePath = await dbInit.exportDatabase();

      closeToast();

      ToastUtils.showSuccess(
        '数据已导出到: $filePath',
        duration: Duration(seconds: 5),
      );

      // final filePath = await viewModel.exportConversation();
      // if (filePath != null && context.mounted) {
      //   ToastUtils.showSuccess('对话已导出到: $filePath');
      // }
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
