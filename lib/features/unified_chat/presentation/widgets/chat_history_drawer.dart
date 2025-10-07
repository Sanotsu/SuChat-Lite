import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/toast_utils.dart';
import '../pages/my_partners_page.dart';
import '../pages/platform_list_page.dart';
import '../viewmodels/unified_chat_viewmodel.dart';
import '../../data/models/unified_conversation.dart';
import '../../data/database/unified_chat_dao.dart';

/// 聊天历史记录抽屉/侧边栏
class ChatHistoryDrawer extends StatefulWidget {
  const ChatHistoryDrawer({super.key});

  @override
  State<ChatHistoryDrawer> createState() => _ChatHistoryDrawerState();
}

class _ChatHistoryDrawerState extends State<ChatHistoryDrawer> {
  final UnifiedChatDao _chatDao = UnifiedChatDao();
  List<UnifiedConversation> _conversations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final conversations = await _chatDao.getConversations(
        orderBy: ["is_pinned DESC,is_archived DESC"],
      );
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ToastUtils.showError('加载对话历史失败: $e');
    }
  }

  List<UnifiedConversation> get _filteredConversations {
    if (_searchQuery.isEmpty) return _conversations;
    return _conversations
        .where(
          (conv) =>
              conv.title.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        // 使用 RoundedRectangleBorder 定义形状
        borderRadius: BorderRadius.only(
          topRight: Radius.zero,
          bottomRight: Radius.zero,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 抽屉头部
          SizedBox(height: 100.0, child: _buildDrawerHeader()),

          // 搜索框
          _buildSearchBox(),

          // 对话列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildConversationList(),
          ),

          // 底部配置按钮
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.smart_toy,
                size: 32,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Text(
                'SuChat',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索对话...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.all(4),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildConversationList() {
    final filteredConversations = _filteredConversations;

    if (filteredConversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? '未找到匹配的对话' : '暂无对话历史',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredConversations.length,
      itemBuilder: (context, index) {
        final conversation = filteredConversations[index];
        return _buildConversationItem(conversation);
      },
    );
  }

  Widget _buildConversationItem(UnifiedConversation conversation) {
    return Consumer<UnifiedChatViewModel>(
      builder: (context, viewModel, child) {
        final isSelected = viewModel.currentConversation?.id == conversation.id;

        return Container(
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.5)
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            dense: true,
            leading: conversation.isPinned
                ? CircleAvatar(
                    radius: 12,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    child: Icon(
                      Icons.push_pin,
                      size: 12,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  )
                : null,
            title: Text(
              conversation.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${conversation.messageCount} 条消息 • ${conversation.lastActivityDescription}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (conversation.totalCost > 0)
                  Text(
                    '费用: ${conversation.formattedCost}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_horiz,
                color: Theme.of(context).primaryColor,
              ),
              onSelected: (value) =>
                  _handleConversationAction(value, conversation),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'update',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('修改'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'pin',
                  child: Row(
                    children: [
                      Icon(Icons.push_pin),
                      SizedBox(width: 8),
                      Text('置顶'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(Icons.archive),
                      SizedBox(width: 8),
                      Text('归档'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('删除', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () {
              Navigator.pop(context);
              _loadConversation(conversation);
            },
          ),
        );
      },
    );
  }

  Widget _buildBottomActions() {
    return Consumer<UnifiedChatViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: IconButton(
                  icon: const Icon(Icons.people),
                  tooltip: '我的搭档',
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyPartnersPage(),
                      ),
                    ).then((value) {
                      // print("从我的搭档返回刷新用户偏好设置");
                      viewModel.refreshUserPreferences();
                    });
                  },
                ),
              ),
              Expanded(
                child: IconButton(
                  icon: const Icon(Icons.storage),
                  tooltip: '平台管理',
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PlatformListPage(),
                      ),
                    ).then((value) async {
                      // print("从平台列表返回刷新可用平台和模型");
                      viewModel.refreshPlatformsAndModels();

                      // await viewModel.initialize();
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _loadConversation(UnifiedConversation conversation) {
    final viewModel = Provider.of<UnifiedChatViewModel>(context, listen: false);
    viewModel.loadConversation(conversation.id);
  }

  void _handleConversationAction(
    String action,
    UnifiedConversation conversation,
  ) async {
    switch (action) {
      case 'update':
        await _updateConversationTitle(conversation);
        break;
      case 'pin':
        await _togglePin(conversation);
        break;
      case 'archive':
        await _toggleArchive(conversation);
        break;
      case 'delete':
        _showDeleteConfirmDialog(conversation);
        break;
    }
  }

  // 修改对话标题
  Future<void> _updateConversationTitle(
    UnifiedConversation conversation,
  ) async {
    // 创建文本控制器并设置初始值
    final titleController = TextEditingController(text: conversation.title);

    // 首先弹窗，让用户输入新的对话标题
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改对话标题'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '请输入对话标题',
          ),
          onSubmitted: (value) {
            // 支持按回车键确认
            if (value.trim().isNotEmpty) {
              Navigator.pop(context, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final text = titleController.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(context, text);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (newTitle == null ||
        newTitle.isEmpty ||
        newTitle == conversation.title) {
      return;
    }

    try {
      final updatedConversation = conversation.copyWith(
        title: newTitle,
        updatedAt: DateTime.now(),
      );
      await _chatDao.updateConversation(updatedConversation);
      _loadConversations();

      ToastUtils.showSuccess('标题修改成功');
    } catch (e) {
      ToastUtils.showError('标题修改失败: $e');
    } finally {
      titleController.dispose();
    }
  }

  // TODO 这里置顶也只是修改记录栏位，没有实际逻辑
  Future<void> _togglePin(UnifiedConversation conversation) async {
    try {
      final updatedConversation = conversation.copyWith(
        isPinned: !conversation.isPinned,
        updatedAt: DateTime.now(),
      );
      await _chatDao.updateConversation(updatedConversation);
      _loadConversations();
    } catch (e) {
      ToastUtils.showError('置顶失败: $e');
    }
  }

  // 归档对话
  // TODO 2025-09-15 归档设定暂无任何额外逻辑，只是修改了该条记录的归档时间栏位
  Future<void> _toggleArchive(UnifiedConversation conversation) async {
    try {
      final updatedConversation = conversation.copyWith(
        isArchived: !conversation.isArchived,
        updatedAt: DateTime.now(),
      );
      await _chatDao.updateConversation(updatedConversation);
      _loadConversations();
    } catch (e) {
      ToastUtils.showError('归档失败: $e');
    }
  }

  void _showDeleteConfirmDialog(UnifiedConversation conversation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除对话'),
        content: Text('确定要删除对话"${conversation.title}"吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteConversation(conversation);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteConversation(UnifiedConversation conversation) async {
    try {
      await _chatDao.deleteConversation(conversation.id);
      _loadConversations();

      // 如果删除的是当前对话，创建新对话
      if (mounted) {
        final viewModel = Provider.of<UnifiedChatViewModel>(
          context,
          listen: false,
        );
        if (viewModel.currentConversation?.id == conversation.id) {
          viewModel.createNewConversation();
        }
      }
    } catch (e) {
      ToastUtils.showError('删除失败: $e');
    }
  }
}
