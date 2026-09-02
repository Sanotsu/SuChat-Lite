import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/screen_helper.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../../settings/index.dart';
import '../../data/database/unified_chat_dao.dart';
import '../../data/models/unified_conversation.dart';
import '../pages/my_partners_page.dart';
import '../pages/platform_list_page.dart';
import '../viewmodels/unified_chat_viewmodel.dart';

/// 聊天历史面板：抽屉与桌面常驻侧栏共用的内容实现。
///
/// [onBeforeNavigate] 在点击会话条目/底部入口前调用：
/// - 移动端抽屉传入 `Navigator.pop(context)` 关闭抽屉
/// - 桌面常驻侧栏传 null（无需关闭）
class ChatHistoryPanel extends StatefulWidget {
  const ChatHistoryPanel({super.key, this.onBeforeNavigate, this.width});

  final void Function()? onBeforeNavigate;
  final double? width;

  @override
  State<ChatHistoryPanel> createState() => _ChatHistoryPanelState();
}

class _ChatHistoryPanelState extends State<ChatHistoryPanel> {
  final UnifiedChatDao _chatDao = UnifiedChatDao();
  List<UnifiedConversation> _conversations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _listController = ScrollController();

  // 侧栏常驻时的列表同步信号：viewmodel 当前会话引用变化后刷新列表
  UnifiedConversation? _lastTrackedConversation;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listController.dispose();
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

  void _navigate(void Function() action) {
    widget.onBeforeNavigate?.call();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final content = Consumer<UnifiedChatViewModel>(
      builder: (context, viewModel, child) {
        // 常驻侧栏同步：当前会话被切换/新建/替换后刷新列表
        final current = viewModel.currentConversation;
        if (!identical(current, _lastTrackedConversation)) {
          _lastTrackedConversation = current;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadConversations();
          });
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBox(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildConversationList(),
            ),
            _buildBottomActions(),
          ],
        );
      },
    );

    if (widget.width != null) {
      return SizedBox(width: widget.width, child: content);
    }
    return content;
  }

  Widget _buildHeader() {
    return Container(
      height: widget.width != null ? 88 : 100,
      width: double.infinity,
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: widget.width != null ? 12 : 24,
        bottom: 12,
      ),
      child: Row(
        children: [
          Icon(
            Icons.smart_toy,
            size: 32,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          Text(
            'SuChat',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
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
          isDense: true,
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

    // 桌面常驻列表显示滚动条
    final listView = ListView.builder(
      controller: _listController,
      itemCount: filteredConversations.length,
      itemBuilder: (context, index) {
        final conversation = filteredConversations[index];
        return _buildConversationItem(conversation);
      },
    );

    if (!ScreenHelper.isDesktop()) return listView;

    return Scrollbar(
      controller: _listController,
      thumbVisibility: true,
      child: listView,
    );
  }

  Widget _buildConversationItem(UnifiedConversation conversation) {
    return Consumer<UnifiedChatViewModel>(
      builder: (context, viewModel, child) {
        final isSelected = viewModel.currentConversation?.id == conversation.id;
        final isDesktop = ScreenHelper.isDesktop();

        final tile = ListTile(
          dense: true,
          leading: conversation.isPinned || conversation.isArchived
              ? CircleAvatar(
                  radius: 12,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: Icon(
                    conversation.isPinned ? Icons.push_pin : Icons.archive,
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
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz, color: Theme.of(context).primaryColor),
            onSelected: (value) =>
                _handleConversationAction(value, conversation),
            itemBuilder: (context) => _buildItemMenuItems(),
          ),
          onTap: () => _navigate(() => _loadConversation(conversation)),
        );

        // 桌面右键直接弹条目菜单；移动端靠 trailing 按钮
        // 选中背景色画在 Material 上(ListTile 的背景/墨水效果也画在最近的
        // Material 祖先；若夹一层带背景色的 DecoratedBox/Container 会遮挡
        // 并触发框架断言"ListTile background color may be invisible")
        return GestureDetector(
          onSecondaryTapUp: isDesktop
              ? (details) => _showItemMenu(conversation, details.globalPosition)
              : null,
          child: Material(
            color: isSelected
                ? Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: tile,
          ),
        );
      },
    );
  }

  List<PopupMenuItem<String>> _buildItemMenuItems() {
    return const [
      PopupMenuItem(
        value: 'update',
        child: Row(
          children: [Icon(Icons.edit), SizedBox(width: 8), Text('修改')],
        ),
      ),
      PopupMenuItem(
        value: 'pin',
        child: Row(
          children: [Icon(Icons.push_pin), SizedBox(width: 8), Text('置顶')],
        ),
      ),
      PopupMenuItem(
        value: 'archive',
        child: Row(
          children: [Icon(Icons.archive), SizedBox(width: 8), Text('归档')],
        ),
      ),
      PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 8),
            Text('删除', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    ];
  }

  // 桌面右键菜单：按点击位置弹出，坐标钳制在安全范围内
  void _showItemMenu(UnifiedConversation conversation, Offset position) {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final screenSize = MediaQuery.of(context).size;
    final dx = position.dx.clamp(0.0, screenSize.width - 200);
    final dy = position.dy.clamp(0.0, screenSize.height - 240);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        dx,
        dy,
        overlay == null ? dx : overlay.size.width - dx,
        overlay == null ? dy + 100 : overlay.size.height - dy,
      ),
      items: _buildItemMenuItems(),
    ).then((value) {
      if (value != null) _handleConversationAction(value, conversation);
    });
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
                  onPressed: () => _navigate(() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyPartnersPage(),
                      ),
                    ).then((value) {
                      viewModel.refreshUserPreferences();
                    });
                  }),
                ),
              ),
              Expanded(
                child: IconButton(
                  icon: const Icon(Icons.storage),
                  tooltip: '平台管理',
                  onPressed: () => _navigate(() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PlatformListPage(),
                      ),
                    ).then((value) async {
                      viewModel.refreshPlatformsAndModels();
                    });
                  }),
                ),
              ),

              // 用户设置(备份恢复/数据迁移等入口)
              Expanded(
                child: IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: '用户设置',
                  onPressed: () => _navigate(() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserAndSettings(),
                      ),
                    );
                  }),
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

  // 置顶
  Future<void> _togglePin(UnifiedConversation conversation) async {
    try {
      final updatedConversation = conversation.copyWith(
        isPinned: !conversation.isPinned,
      );
      await _chatDao.updateConversation(updatedConversation);
      _loadConversations();
    } catch (e) {
      ToastUtils.showError('置顶失败: $e');
    }
  }

  // 归档对话(如果当前对话已归档，在对话消息列表页面不会显示输入区域)
  Future<void> _toggleArchive(UnifiedConversation conversation) async {
    try {
      final updatedConversation = conversation.copyWith(
        isArchived: !conversation.isArchived,
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
