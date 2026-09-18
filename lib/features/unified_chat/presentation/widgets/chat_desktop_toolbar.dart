import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../../ai_tool_page.dart';
import '../../data/database/unified_chat_db_init.dart';
import '../pages/chat_background_picker_page.dart';
import '../pages/media_library_page.dart';
import '../pages/mcp_servers_settings_page.dart';
import '../pages/search_tools_settings_page.dart';
import '../pages/skills_settings_page.dart';
import '../viewmodels/unified_chat_viewmodel.dart';
import 'appearance_tool_widgets.dart';

/// 桌面端右侧功能工具栏（2026-09-05 恢复旧版 branch_chat 桌面右侧工具栏）
///
/// 条目与聊天页右上角"更多操作"菜单(三点按钮)完全一致；桌面端由本工具栏
/// 承担这些入口后，AppBar 的三点按钮不再显示(移动端保留)。
class ChatDesktopToolbar extends StatelessWidget {
  const ChatDesktopToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UnifiedChatViewModel>(
      builder: (context, viewModel, _) {
        return SingleChildScrollView(
          child: Column(
            children: [
              // 更多功能
              buildIconWithTextButton(
                icon: Icons.apps,
                label: '更多功能',
                onTap: () => _openMoreTools(context),
                context: context,
              ),
              // 搜索工具设置
              buildIconWithTextButton(
                icon: Icons.search,
                label: '搜索设置',
                onTap: () => _openSearchToolsSettings(context),
                context: context,
              ),
              // MCP工具管理(2026-09-11 MCP集成P1-4)
              buildIconWithTextButton(
                icon: Icons.extension,
                label: 'MCP 工具',
                onTap: () => _openMcpServersSettings(context, viewModel),
                context: context,
              ),
              // 技能管理(2026-09-16 SKILLS P1-5)
              buildIconWithTextButton(
                icon: Icons.school_outlined,
                label: 'Skills 技能',
                onTap: () => _openSkillsSettings(context),
                context: context,
              ),
              // 媒体面板(2026-09-09 跨会话查看AI生成的图片/视频/语音及生成条件)
              buildIconWithTextButton(
                icon: Icons.perm_media,
                label: '媒体面板',
                onTap: () => _openMediaLibrary(context, viewModel),
                context: context,
              ),
              const SizedBox(width: 48, child: Divider(height: 16)),
              // 文字大小
              buildIconWithTextButton(
                icon: Icons.format_size,
                label: '文字大小',
                onTap: () => adjustTextScale(
                  context,
                  viewModel.textScaleFactor,
                  (value) {
                    Navigator.of(context).pop();
                    viewModel.setTextScale(value);
                  },
                ),
                context: context,
              ),
              // 更换背景
              buildIconWithTextButton(
                icon: Icons.image,
                label: '更换背景',
                onTap: () => _openBackgroundPicker(context, viewModel),
                context: context,
              ),
              // 简洁显示/详细显示切换
              buildIconWithTextButton(
                icon: viewModel.isBriefDisplay
                    ? Icons.details
                    : Icons.visibility_off,
                label: viewModel.isBriefDisplay ? '详细显示' : '简洁显示',
                onTap: () async {
                  await viewModel.toggleBriefDisplay();
                  ToastUtils.showInfo(
                    viewModel.isBriefDisplay ? '已切换为简洁显示' : '已切换为详细显示',
                  );
                },
                context: context,
              ),
              const SizedBox(width: 48, child: Divider(height: 16)),
              // 清空消息
              buildIconWithTextButton(
                icon: Icons.clear_all,
                label: '清空消息',
                onTap: () => _showClearConfirmDialog(context, viewModel),
                context: context,
              ),
              // 新建会话
              buildIconWithTextButton(
                icon: Icons.add,
                label: '新建会话',
                onTap: () => viewModel.createNewConversation(),
                context: context,
              ),
              // 导出会话
              buildIconWithTextButton(
                icon: Icons.download,
                label: '导出会话',
                onTap: () => _exportConversation(viewModel),
                context: context,
              ),
            ],
          ),
        );
      },
    );
  }

  void _openMoreTools(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AIToolPage()),
    );
  }

  void _openSearchToolsSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchToolsSettingsPage()),
    );
  }

  // 2026-09-16 设置页只写storage(路由不在聊天页局部provider子树，
  // 回写会错实例)，返回后刷新viewmodel全局MCP态驱动输入框按钮显隐
  void _openMcpServersSettings(
    BuildContext context,
    UnifiedChatViewModel viewModel,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const McpServersSettingsPage()),
    );
    await viewModel.refreshMcpGlobalState();
  }

  void _openSkillsSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SkillsSettingsPage()),
    );
  }

  // 2026-09-09 必须传入聊天页持有的viewModel实例(聊天页是局部
  // ChangeNotifierProvider.value实例，与suchat_app的全局实例不同)，
  // 否则面板里loadConversation切换的不是聊天页正在显示的会话
  void _openMediaLibrary(BuildContext context, UnifiedChatViewModel viewModel) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MediaLibraryPage(viewModel: viewModel)),
    );
  }

  void _openBackgroundPicker(
    BuildContext context,
    UnifiedChatViewModel viewModel,
  ) {
    // 跨页面异步返回后再刷新，提前取用 viewModel 避免 BuildContext 跨 async
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatBackgroundPickerPage(title: '聊天背景设置'),
      ),
    ).then((confirmed) {
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

  void _exportConversation(UnifiedChatViewModel viewModel) async {
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
    } catch (e) {
      ToastUtils.showError('导出失败: $e');
      rethrow;
    }
  }
}
