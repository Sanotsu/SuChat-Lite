import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/upgrade_migrator.dart';
import '../../../../core/storage/cus_get_storage.dart';
import '../../../../core/utils/screen_helper.dart';
import '../../../../shared/widgets/simple_tool_widget.dart';
import '../widgets/chat_background.dart';
import '../../../settings/pages/backup_and_restore_page.dart';
import '../viewmodels/unified_chat_viewmodel.dart';
import '../widgets/chat_message_list.dart';
import '../widgets/chat_input_widget.dart';
import '../widgets/chat_history_drawer.dart';
import '../widgets/chat_history_panel.dart';
import '../widgets/chat_app_bar.dart';
import '../widgets/chat_desktop_toolbar.dart';
import '../widgets/draggable_partner_avatar_preview.dart';
import '../widgets/mcp_approval_banner.dart';
import '../widgets/partner_horizontal_list.dart';
import 'platform_list_page.dart';

/// 统一AI聊天主页面
class UnifiedChatPage extends StatefulWidget {
  const UnifiedChatPage({super.key});

  @override
  State<UnifiedChatPage> createState() => _UnifiedChatPageState();
}

class _UnifiedChatPageState extends State<UnifiedChatPage> {
  late UnifiedChatViewModel _viewModel;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // 桌面常驻会话侧栏可见性(记忆用户偏好)
  static const _sidebarVisibleKey = 'desktop_sidebar_visible';
  bool _sidebarVisible = true;
  bool _sidebarReady = false;

  // 桌面内容区宽屏模式：false=限宽880居中(默认，保可读性)，true=铺满内容区
  // (对齐Chatbox/ChatGPT的"限宽为默认+可切换宽屏"做法，记忆用户偏好)
  static const _widescreenKey = 'desktop_content_widescreen';
  bool _widescreen = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _checkLegacyMigrationPrompt();
    _loadSidebarVisible();
    _loadWidescreen();
  }

  void _loadWidescreen() {
    final saved = CusGetStorage().box.read(_widescreenKey);
    if (saved is bool) {
      setState(() => _widescreen = saved);
    }
  }

  Future<void> _toggleWidescreen() async {
    setState(() => _widescreen = !_widescreen);
    await CusGetStorage().box.write(_widescreenKey, _widescreen);
  }

  void _loadSidebarVisible() {
    final saved = CusGetStorage().box.read(_sidebarVisibleKey);
    if (saved is bool) {
      setState(() {
        _sidebarVisible = saved;
        _sidebarReady = true;
      });
    } else {
      _sidebarReady = true;
    }
  }

  Future<void> _toggleSidebar() async {
    setState(() => _sidebarVisible = !_sidebarVisible);
    await CusGetStorage().box.write(_sidebarVisibleKey, _sidebarVisible);
  }

  Future<void> _initializeChat() async {
    _viewModel = UnifiedChatViewModel();
    await _viewModel.initialize();
  }

  /// 首启旧版聊天数据引导(2026-09-01 0.1.5 改版)：
  /// 0.1.5 已移除旧聊天模块与 ObjectBox 依赖，本机残留旧聊天数据
  /// 只能经 0.1.4 全量备份 zip 中转导入(升级迁移器已把库/媒体自动迁入私有区)
  bool _legacyPromptRunning = false;

  Future<void> _checkLegacyMigrationPrompt() async {
    if (_legacyPromptRunning) return;
    _legacyPromptRunning = true;

    try {
      final box = CusGetStorage().box;
      const promptShownKey = 'legacy_migration_prompt_shown';
      if (box.read(promptShownKey) == true) return;

      // 迁移器标记的 ObjectBox 残留(未做备份中转的旧聊天数据)
      final objectBoxFound =
          box.read(UpgradeMigrator.objectBoxFoundKey) == true;
      if (!objectBoxFound) return;

      await box.write(promptShownKey, true);
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('检测到旧版聊天数据'),
          content: const Text(
            '本机有旧版聊天模块的对话记录/角色卡数据。\n\n'
            '由于 0.1.5 已移除旧版聊天模块，需通过备份包导入：\n\n'
            '1. 若已在旧版本中做过"全量备份"，直接选择备份 zip 恢复即可\n'
            '2. 若未备份，可重新安装 0.1.4 完成一次全量备份后再升级\n'
            '(其他数据如媒体/配置已自动迁移完成)',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('知道了'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const BackupAndRestorePage(packageVersion: ''),
                  ),
                );
              },
              child: const Text('去恢复备份'),
            ),
          ],
        ),
      );
    } catch (_) {
      // 引导失败静默(不影响正常使用)
    } finally {
      _legacyPromptRunning = false;
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      // 背景铺在整个页面最底层(含AppBar/输入区域，对齐旧版AdaptiveChatLayout布局)：
      // Scaffold在背景模式下透明，背景从状态栏下方一直透到输入栏
      child: Consumer<UnifiedChatViewModel>(
        child: GestureDetector(
          // 允许子控件（如TextField）接收点击事件
          behavior: HitTestBehavior.translucent,
          // 点击空白处可以移除焦点，关闭键盘
          onTap: unfocusHandle,
          child: Consumer<UnifiedChatViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (viewModel.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '出现错误',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        viewModel.error ?? '未知错误',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _initializeChat(),
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                );
              }

              if (viewModel.currentModel == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '配置AI大模型平台和模型',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PlatformListPage(),
                            ),
                          ).then((value) async {
                            // print("从平台列表返回刷新可用平台和模型");
                            await viewModel.refreshPlatformsAndModels();

                            await viewModel.initialize();
                          });
                        },
                        child: const Text('使用自己的API Key'),
                      ),
                      const SizedBox(height: 64),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  // 消息列表
                  Expanded(child: ChatMessageList()),

                  // 搭档横向列表或选中搭档显示
                  if (viewModel.shouldShowPartnersList)
                    PartnerHorizontalList(
                      onPartnerSelected: (partner) async {
                        await viewModel.selectPartner(partner);
                      },
                    )
                  else if (viewModel.shouldShowSelectedPartner &&
                      viewModel.currentPartner != null)
                    _buildSelectedPartnerCard(viewModel),

                  // 2026-09-14 P3-1 工具调用审批横幅(输入框上方)：
                  // 挂起时展示工具名+参数，允许/拒绝后Agent循环继续
                  if (viewModel.pendingApproval != null)
                    McpApprovalBanner(
                      request: viewModel.pendingApproval!,
                      onAllow: () => viewModel.approveToolCall(),
                      onAllowAlways: () =>
                          viewModel.approveToolCall(alwaysForSession: true),
                      onDeny: () => viewModel.denyToolCall(),
                    ),

                  // 输入组件
                  ChatInputWidget(),
                ],
              );
            },
          ),
        ),
        builder: (context, viewModel, child) {
          final hasBg = viewModel.hasBackgroundImage;
          final isDesktop = ScreenHelper.isDesktop();
          return Stack(
            children: [
              // 2026-09-05 修复移动端自定义背景"一片黑"：Android 窗口底为黑色，
              // 半透明背景图叠在黑底上整体发暗且看不清内容；
              // 补一层主题底色后再叠背景图，两端表现一致
              Positioned.fill(
                child: ColoredBox(
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
              // ChatBackground内部自带Positioned.fill，铺满整个页面
              ChatBackground(
                backgroundImage: viewModel.backgroundImage,
                opacity: viewModel.backgroundOpacity,
              ),
              Scaffold(
                key: _scaffoldKey,
                backgroundColor: hasBg ? Colors.transparent : null,
                appBar: ChatAppBar(
                  // 桌面：菜单按钮切换常驻侧栏；移动：打开左侧历史抽屉
                  onMenuPressed: isDesktop
                      ? _toggleSidebar
                      : () => _scaffoldKey.currentState?.openDrawer(),
                  // 桌面：内容区宽度切换(标准880限宽/宽屏铺满)
                  onToggleWidescreen: isDesktop ? _toggleWidescreen : null,
                  isWidescreen: _widescreen,
                ),
                // 移动端抽屉放左侧(leading 菜单按钮在左，抽屉也从左弹出)
                drawer: isDesktop ? null : const ChatHistoryDrawer(),
                body: isDesktop ? _buildDesktopBody(hasBg, child) : child,
              ),
              // 搭档立绘：选中搭档且头像非空时显示，
              // 小立绘可点击放大为可拖动/缩放的悬浮预览(旧版特性)
              // 2026-09-07 移动端也显示(组件内已有单指拖动/双指缩放分支)
              if (viewModel.currentPartner?.avatarUrl != null &&
                  viewModel.currentPartner!.avatarUrl!.trim().isNotEmpty)
                DraggablePartnerAvatarPreview(
                  key: ValueKey(viewModel.currentPartner!.avatarUrl),
                  partner: viewModel.currentPartner!,
                  // 桌面端距左侧随会话侧栏可见性让位(侧栏固定宽280)；
                  // 移动端侧栏为抽屉无常驻面板，恒贴左缘
                  left: isDesktop && _sidebarVisible && _sidebarReady ? 284 : 4,
                  width: isDesktop ? 48 : 36,
                  height: isDesktop ? 64 : 48,
                ),
            ],
          );
        },
      ),
    );
  }

  /// 桌面布局：左侧常驻会话侧栏 + 主内容区 + 右侧功能工具栏
  /// 内容区默认限宽880居中保证宽屏可读性；宽屏模式(_widescreen)铺满
  /// 2026-09-05 两侧面板改为透明，让自定义背景延伸覆盖，消除割裂感
  Widget _buildDesktopBody(bool hasBg, Widget? content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_sidebarVisible && _sidebarReady)
          Material(
            color: Colors.transparent,
            child: ChatHistoryPanel(width: 280),
          ),
        if (_sidebarVisible && _sidebarReady)
          VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: _widescreen ? double.infinity : 880,
              ),
              child: content ?? const SizedBox.shrink(),
            ),
          ),
        ),
        // 2026-09-05 恢复旧版桌面右侧功能工具栏(条目对齐"更多操作"菜单)
        VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
        Material(
          color: Colors.transparent,
          child: SizedBox(width: 86, child: ChatDesktopToolbar()),
        ),
      ],
    );
  }

  /// 构建选中搭档卡片
  Widget _buildSelectedPartnerCard(UnifiedChatViewModel viewModel) {
    final partner = viewModel.currentPartner!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 搭档头像
          buildUserCircleAvatar(partner.avatarUrl, radius: 20),
          const SizedBox(width: 12),

          // 搭档信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partner.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  partner.prompt.length > 50
                      ? '${partner.prompt.substring(0, 50)}...'
                      : partner.prompt,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 关闭按钮
          IconButton(
            onPressed: () async => await viewModel.clearPartnerSelection(),
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            tooltip: '取消选择',
          ),
        ],
      ),
    );
  }
}
