import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/simple_tool_widget.dart';
import '../viewmodels/unified_chat_viewmodel.dart';
import '../widgets/chat_message_list.dart';
import '../widgets/chat_input_widget.dart';
import '../widgets/chat_history_drawer.dart';
import '../widgets/chat_app_bar.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    _viewModel = UnifiedChatViewModel();
    await _viewModel.initialize();
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
      child: Scaffold(
        key: _scaffoldKey,
        appBar: ChatAppBar(
          onMenuPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
        ),
        endDrawer: const ChatHistoryDrawer(),
        body: GestureDetector(
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
                        'SuChat',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '选择并配置AI大模型平台和模型',
                        style: Theme.of(context).textTheme.bodyMedium,
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
                            viewModel.refreshPlatformsAndModels();

                            await viewModel.initialize();
                          });
                        },
                        child: const Text('使用自己的API Key'),
                      ),
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

                  // 输入组件
                  ChatInputWidget(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// 构建选中搭档卡片
  Widget _buildSelectedPartnerCard(UnifiedChatViewModel viewModel) {
    final partner = viewModel.currentPartner!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: partner.avatarUrl != null && partner.avatarUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      partner.avatarUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          color: Theme.of(context).colorScheme.onPrimary,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
          ),
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
