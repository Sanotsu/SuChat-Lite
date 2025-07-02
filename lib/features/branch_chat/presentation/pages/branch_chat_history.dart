import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/simple_tools.dart';
import '../../../../shared/constants/constant_llm_enum.dart';
import '../../../../core/utils/screen_helper.dart';
import '../../../../core/storage/cus_get_storage.dart';
import '../../../../shared/constants/constants.dart';
import '../../../settings/index.dart';
import '../../../model_management/index.dart';
import '../../domain/entities/branch_chat_session.dart';
import '../../../../app/routes.dart';
import '../viewmodels/branch_store.dart';

///
/// 【桌面端】历史记录侧边栏内容面板
///
class BranchChatHistoryPanel extends StatelessWidget {
  // 当前选中的对话ID
  final int? currentSessionId;
  // 选中对话的回调
  final Function(BranchChatSession) onSessionSelected;
  // 导入模型、删除或重命名对话后，要通知父组件做一些事情
  final Function({BranchChatSession? session, String? action})? onCompleted;

  const BranchChatHistoryPanel({
    super.key,
    this.currentSessionId,
    required this.onSessionSelected,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    // 使用共享的核心组件
    return BranchChatHistoryCore(
      currentSessionId: currentSessionId,
      onSessionSelected: onSessionSelected,
      onCompleted: onCompleted,
      // 桌面端不需要关闭当前上下文
      needPopContext: false,
      isPageMode: false, // 侧边栏模式，非页面模式
      title: '对话记录与设置',
    );
  }
}

/// 【移动端】聊天历史记录页面
class BranchChatHistoryPage extends StatelessWidget {
  // 当前选中的对话ID
  final int? currentSessionId;
  // 选中对话的回调
  final Function(BranchChatSession) onSessionSelected;
  // 导入模型、删除或重命名对话后，要通知父组件做一些事情
  final Function({BranchChatSession? session, String? action})? onCompleted;

  const BranchChatHistoryPage({
    super.key,
    this.currentSessionId,
    required this.onSessionSelected,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    // 使用共享的核心组件
    return BranchChatHistoryCore(
      currentSessionId: currentSessionId,
      onSessionSelected: onSessionSelected,
      onCompleted: onCompleted,
      isPageMode: true, // 页面模式
      title: '对话记录',
      // 移动端需要关闭当前上下文
      needPopContext: true,
    );
  }
}

/// 聊天历史记录核心组件
/// 被BranchChatHistoryPanel和ChatHistoryPage复用的核心功能
class BranchChatHistoryCore extends StatefulWidget {
  // 当前选中的对话ID
  final int? currentSessionId;
  // 选中对话的回调
  final Function(BranchChatSession) onSessionSelected;
  // 导入模型、删除或重命名对话后，要通知父组件做一些事情
  final Function({BranchChatSession? session, String? action})? onCompleted;
  // 是否需要关闭当前上下文
  final bool needPopContext;
  // 是否显示为页面模式（带有AppBar）
  final bool isPageMode;
  // 自定义标题
  final String? title;
  // 自定义背景色
  final Color? initialBgColor;

  const BranchChatHistoryCore({
    super.key,
    this.currentSessionId,
    required this.onSessionSelected,
    this.onCompleted,
    this.needPopContext = true,
    this.isPageMode = false,
    this.title,
    this.initialBgColor,
  });

  @override
  State<BranchChatHistoryCore> createState() => _BranchChatHistoryCoreState();
}

class _BranchChatHistoryCoreState extends State<BranchChatHistoryCore> {
  Color? _bgColor;
  // 本地会话列表状态
  List<BranchChatSession> _sessions = [];
  // 本地当前会话ID
  int? _currentSessionId;
  // 存储服务
  late BranchStore _store;
  // 是否正在加载
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentSessionId = widget.currentSessionId;

    if (widget.initialBgColor != null) {
      _bgColor = widget.initialBgColor;
    } else {
      getPanelColor();
    }

    // 初始化存储服务并加载会话列表
    _initStore();
  }

  @override
  void didUpdateWidget(BranchChatHistoryCore oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当前会话ID变化时更新
    if (widget.currentSessionId != oldWidget.currentSessionId) {
      setState(() {
        _currentSessionId = widget.currentSessionId;
      });
    }
  }

  // 初始化存储服务并加载会话列表
  Future<void> _initStore() async {
    // 初始化存储服务
    _store = await BranchStore.create();

    // 加载会话列表
    await _loadSessions();
  }

  // 加载会话列表
  Future<void> _loadSessions() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final sessions = _store.sessionBox.getAll();
      // 按更新时间排序，最新的在前面
      sessions.sort((a, b) => b.updateTime.compareTo(a.updateTime));

      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      pl.e('加载会话列表失败: $e');
      setState(() {
        _sessions = [];
        _isLoading = false;
      });
    }
  }

  Future<void> getPanelColor() async {
    int? colorValue =
        (await CusGetStorage().getBranchChatHistoryPanelBgColor());

    // 有缓存侧边栏背景色，就使用;没有就白色
    // 侧边栏背景色在每次切换对话主页背景图时都会缓存
    Color sidebarColor = colorValue != null ? Color(colorValue) : Colors.white;

    setState(() {
      _bgColor = sidebarColor;
    });
  }

  Future<void> setDefaultColor() async {
    await CusGetStorage().saveBranchChatHistoryPanelBgColor(
      Colors.grey.shade50.toARGB32(),
    );

    setState(() {
      _bgColor = Colors.grey.shade50;
    });
  }

  // 显示颜色选择器对话框
  void _showColorPickerDialog() {
    // 当前颜色或默认颜色
    Color pickerColor = _bgColor ?? Colors.white;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择背景颜色'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (Color color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.8,
              displayThumbColor: true,
              paletteType: PaletteType.hsvWithHue,
              portraitOnly: true,
              enableAlpha: true,
              labelTypes: const [ColorLabelType.hex, ColorLabelType.rgb],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('恢复默认'),
              onPressed: () {
                Navigator.of(context).pop();
                setDefaultColor();
              },
            ),
            TextButton(
              child: const Text('确定'),
              onPressed: () {
                Navigator.of(context).pop();
                _applySelectedColor(pickerColor);
              },
            ),
          ],
        );
      },
    );
  }

  // 应用选择的颜色
  void _applySelectedColor(Color color) async {
    // 保存颜色设置
    await CusGetStorage().saveBranchChatHistoryPanelBgColor(color.toARGB32());

    // 更新UI
    setState(() {
      _bgColor = color;
    });
  }

  // 处理会话操作完成后的刷新
  void _handleCompleted({BranchChatSession? session, String? action}) async {
    // 如果提供了回调，则通知父组件
    if (widget.onCompleted != null) {
      widget.onCompleted!(session: session, action: action);
    }

    // 重新加载会话列表
    await _loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    Widget contentWidget;

    if (_isLoading) {
      contentWidget = Center(child: CircularProgressIndicator());
    } else {
      contentWidget = Container(
        color: _bgColor,
        child: Column(
          children: [
            // 在页面模式下不需要状态栏占位
            if (!widget.isPageMode)
              SizedBox(height: MediaQuery.of(context).padding.top),

            // 构建标题栏
            _buildHeader(),

            // 构建会话列表
            Expanded(child: Container(color: _bgColor, child: buildItemList())),

            // 底部按钮
            _buildBottomButtons(),
          ],
        ),
      );
    }

    // 如果是页面模式，添加Scaffold和AppBar
    if (widget.isPageMode) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title ?? '对话记录'),
          actions: [
            IconButton(
              onPressed: () {
                _showColorPickerDialog();
              },
              tooltip: "自定义背景色",
              icon: Icon(Icons.color_lens, size: 20),
            ),
          ],
        ),
        body: contentWidget,
      );
    } else {
      // 否则直接返回内容
      return contentWidget;
    }
  }

  // 构建头部
  Widget _buildHeader() {
    // 页面模式不需要头部，因为有AppBar
    if (widget.isPageMode) return SizedBox();

    return Row(
      children: [
        Expanded(child: ListTile(title: Text(widget.title ?? '对话记录与设置'))),
        IconButton(
          onPressed: () {
            _showColorPickerDialog();
          },
          tooltip: "自定义背景色",
          icon: Icon(Icons.color_lens, size: 18),
        ),
      ],
    );
  }

  // 底部按钮区域
  Widget _buildBottomButtons() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: _bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBottomButton(
            icon: Icons.grid_view,
            label: '更多功能',
            onTap: () {
              if (widget.needPopContext) {
                Navigator.pop(context);
              }
              Navigator.pushNamed(context, AppRoutes.aiTool);
            },
          ),
          _buildBottomButton(
            icon: Icons.import_export,
            label: '模型配置',
            onTap: () {
              if (widget.needPopContext) {
                Navigator.pop(context);
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ModelConfig()),
              ).then((value) {
                // 导入后要重新加载模型列表
                _handleCompleted(action: 'model-import');
              });
            },
          ),
          _buildBottomButton(
            icon: Icons.settings,
            label: '用户设置',
            onTap: () {
              if (widget.needPopContext) {
                Navigator.pop(context);
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserAndSettings()),
              );
            },
          ),
        ],
      ),
    );
  }

  // 底部按钮样式
  Widget _buildBottomButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // 历史对话列表
  Widget buildItemList() {
    return (_sessions.isEmpty)
        ? Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              '暂无历史对话',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        )
        : RefreshIndicator(
          onRefresh: _loadSessions,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              children:
                  _sessions.map((session) {
                    final isSelected = session.id == _currentSessionId;
                    return _buildChatHistoryItem(session, isSelected);
                  }).toList(),
            ),
          ),
        );
  }

  // 历史对话列表项
  Widget _buildChatHistoryItem(BranchChatSession session, bool isSelected) {
    var subtitle =
        session.character != null
            ? session.character!.name
            : "${CP_NAME_MAP[session.llmSpec.platform]!} > ${session.llmSpec.name}";

    return GestureDetector(
      child: Builder(
        builder:
            (context) => GestureDetector(
              // 移动端使用长按
              onLongPressStart:
                  ScreenHelper.isMobile()
                      ? (details) {
                        _showContextMenu(
                          context,
                          session,
                          details.globalPosition,
                        );
                      }
                      : null,
              // 桌面端使用右键点击
              onSecondaryTapDown:
                  ScreenHelper.isDesktop()
                      ? (details) {
                        _showContextMenu(
                          context,
                          session,
                          details.globalPosition,
                        );
                      }
                      : null,
              child: Container(
                decoration: BoxDecoration(
                  color: _bgColor,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey, width: 1.0),
                  ),
                ),
                child: ListTile(
                  title: Text(
                    session.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    "${DateFormat(formatToYMDHMS).format(session.updateTime)}\n$subtitle",
                    style: TextStyle(fontSize: 12),
                  ),
                  selected: isSelected,
                  onTap: () {
                    if (widget.needPopContext) {
                      Navigator.pop(context);
                    }
                    widget.onSessionSelected(session);
                  },
                ),
              ),
            ),
      ),
    );
  }

  // 显示上下文菜单
  void _showContextMenu(
    BuildContext context,
    BranchChatSession session,
    Offset position,
  ) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 200, // 菜单宽度
        position.dy + 100, // 菜单高度
      ),
      items: [
        PopupMenuItem(
          child: _buildTextWithIcon(Icons.edit, '重命名', Colors.blue),
          onTap: () {
            Future.delayed(Duration.zero, () {
              if (!context.mounted) return;
              _editSessionTitle(context, session);
            });
          },
        ),
        PopupMenuItem(
          child: _buildTextWithIcon(Icons.delete, '删除', Colors.red),
          onTap: () {
            Future.delayed(Duration.zero, () {
              if (!context.mounted) return;
              _deleteSession(context, session);
            });
          },
        ),
      ],
    );
  }

  // 重命名、删除按钮，改为带有图标的文本
  Widget _buildTextWithIcon(IconData icon, String text, Color? color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 16, color: color),
        SizedBox(width: 8), // 添加一些间距
        Text(text, style: TextStyle(fontSize: 14, color: color)),
      ],
    );
  }

  // 修改标题
  Future<void> _editSessionTitle(
    BuildContext context,
    BranchChatSession session,
  ) async {
    final controller = TextEditingController(text: session.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('修改标题'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: '对话标题'),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('确定'),
              ),
            ],
          ),
    );

    if (newTitle != null && newTitle.isNotEmpty && newTitle != session.title) {
      session.title = newTitle;
      session.updateTime = DateTime.now();

      // 保存修改的会话
      _store.sessionBox.put(session);

      // 通知完成操作并刷新列表
      _handleCompleted(session: session, action: 'edit');
    }
  }

  // 删除对话
  Future<void> _deleteSession(
    BuildContext context,
    BranchChatSession session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('删除对话'),
            content: const Text('确定要删除这个对话吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('删除'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      // 删除会话
      await _store.deleteSession(session);

      // 通知完成操作并刷新列表
      _handleCompleted(session: session, action: 'delete');
    }
  }
}
