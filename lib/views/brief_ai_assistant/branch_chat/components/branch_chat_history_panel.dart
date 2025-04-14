import 'package:flutter/material.dart';
import '../../../../common/llm_spec/constant_llm_enum.dart';
import '../../../../common/utils/screen_helper.dart';
import '../../../../models/brief_ai_tools/branch_chat/branch_chat_session.dart';
import '../../../../services/cus_get_storage.dart';
import '../../../user_and_settings/index.dart';
import '../../model_config/index.dart';

/// 历史记录侧边栏内容面板
/// 可以被用于抽屉或者桌面端的侧边栏
class BranchChatHistoryPanel extends StatefulWidget {
  // 历史对话列表
  final List<BranchChatSession> sessions;
  // 当前选中的对话
  final int? currentSessionId;
  // 选中对话的回调
  final Function(BranchChatSession) onSessionSelected;
  // 删除或重命名对话后，要刷新对话列表
  final Function({BranchChatSession? session, String? action}) onRefresh;
  // 是否需要弹出关闭对话框(移动端抽屉需要关闭，桌面端侧边栏不需要)
  final bool needCloseDrawer;

  const BranchChatHistoryPanel({
    super.key,
    required this.sessions,
    this.currentSessionId,
    required this.onSessionSelected,
    required this.onRefresh,
    this.needCloseDrawer = true,
  });

  @override
  State<BranchChatHistoryPanel> createState() => _BranchChatHistoryPanelState();
}

class _BranchChatHistoryPanelState extends State<BranchChatHistoryPanel> {
  Color? _bgColor;

  @override
  void initState() {
    super.initState();
    getPanelColor();
  }

  getPanelColor() async {
    int? colorValue = (await MyGetStorage().getBranchChatHistoryPanelBgColor());

    // 有缓存侧边栏背景色，就使用;没有就白色
    // 侧边栏背景色在每次切换对话主页背景图时都会缓存
    Color sidebarColor = colorValue != null ? Color(colorValue) : Colors.white;

    setState(() {
      _bgColor = sidebarColor;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // decoration: BoxDecoration(
      //   gradient: SweepGradient(
      //     colors: [
      //       Colors.lightBlue.shade100, // 浅蓝色
      //       Colors.purple.shade50, // 浅紫色
      //       Colors.pink.shade100, // 浅粉色
      //     ],
      //     center: Alignment.topCenter, // 渐变中心点
      //     startAngle: 0.0, // 起始角度（0.0 表示从正右方开始）
      //     endAngle: 3.14, // 结束角度（3.14 ≈ π，即180°）
      //   ),
      // ),
      color: _bgColor,
      child: Column(
        children: [
          // 使用 SizedBox 来占位状态栏的高度
          SizedBox(height: MediaQuery.of(context).padding.top),

          _buildMoreFeatures(),

          Expanded(
            child: Container(
              color: _bgColor,
              // decoration: BoxDecoration(
              //   gradient: SweepGradient(
              //     colors: [
              //       Colors.lightBlue.shade100, // 浅蓝色
              //       Colors.purple.shade50, // 浅紫色
              //       Colors.pink.shade100, // 浅粉色
              //     ],
              //     center: Alignment.topCenter, // 渐变中心点
              //     startAngle: 0.0, // 起始角度（0.0 表示从正右方开始）
              //     endAngle: 3.14, // 结束角度（3.14 ≈ π，即180°）
              //   ),
              // ),
              child: buildItemList(),
            ),
          ),
        ],
      ),
    );
  }

  // 构建更多功能
  Widget _buildMoreFeatures() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('对话记录与设置'),
        ),

        Row(
          children: [
            // Expanded(
            //   child: InkWell(
            //     onTap: () async {
            //       bool flag = await requestStoragePermission();

            //       if (!mounted) return;
            //       if (!flag) {
            //         commonHintDialog(context, "提示", "无存储权限，无法备份");
            //         return;
            //       }

            //       if (widget.needCloseDrawer) {
            //         Navigator.pop(context);
            //       }
            //       Navigator.push(
            //         context,
            //         MaterialPageRoute(
            //           builder: (context) => ChatExportImportPage(),
            //         ),
            //       ).then((value) {
            //         // 导入后要重新加载会话，这里的参数其实没有实际用到，只是兼容写法
            //         widget.onRefresh(action: 'import');
            //       });
            //     },
            //     child: Card(
            //       elevation: 0,
            //       child: ListTile(
            //         leading: const Icon(Icons.import_export),
            //         title: Text(
            //           '备份',
            //           style: TextStyle(
            //             fontSize: 14,
            //             fontWeight: FontWeight.bold,
            //           ),
            //           textAlign: TextAlign.center,
            //         ),
            //       ),
            //     ),
            //   ),
            // ),

            // 2025-04-11 备份和首页的pop按钮中有重复，这里改为跳转到模型管理页面？
            Expanded(
              child: InkWell(
                onTap: () async {
                  if (widget.needCloseDrawer) {
                    Navigator.pop(context);
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BriefModelConfig()),
                  ).then((value) {
                    // 导入后要重新加载模型列表
                    widget.onRefresh(action: 'model-import');
                  });
                },
                child: Card(
                  elevation: 1,
                  color: _bgColor?.withValues(alpha: 0.9),
                  child: ListTile(
                    leading: const Icon(Icons.import_export),
                    title: Text(
                      '模型',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: InkWell(
                onTap: () {
                  if (widget.needCloseDrawer) {
                    Navigator.pop(context);
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UserAndSettings()),
                  );
                },
                child: Card(
                  elevation: 1,
                  color: _bgColor?.withValues(alpha: 0.9),
                  child: ListTile(
                    leading: const Icon(Icons.settings),
                    title: Text(
                      '设置',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 10),
      ],
    );
  }

  // 历史对话列表
  Widget buildItemList() {
    return (widget.sessions.isEmpty)
        ? Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              '暂无历史对话',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        )
        : SingleChildScrollView(
          child: Column(
            children:
                widget.sessions.map((session) {
                  final isSelected = session.id == widget.currentSessionId;
                  return _buildChatHistoryItem(session, isSelected);
                }).toList(),
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
              child: ListTile(
                title: Text(
                  session.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  "${session.updateTime.toString().substring(0, 19)}\n$subtitle",
                  style: TextStyle(fontSize: 12),
                ),
                selected: isSelected,
                selectedTileColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.1),
                onTap: () {
                  if (widget.needCloseDrawer) {
                    Navigator.pop(context);
                  }
                  widget.onSessionSelected(session);
                },
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

      widget.onRefresh(session: session, action: 'edit');
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
      widget.onRefresh(session: session, action: 'delete');
    }
  }
}
