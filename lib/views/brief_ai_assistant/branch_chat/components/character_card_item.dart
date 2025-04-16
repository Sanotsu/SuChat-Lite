import 'package:flutter/material.dart';
import '../../../../common/utils/screen_helper.dart';
import '../../../../models/brief_ai_tools/branch_chat/character_card.dart';
import '../../_chat_components/_small_tool_widgets.dart';

class CharacterCardItem extends StatelessWidget {
  final CharacterCard character;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CharacterCardItem({
    super.key,
    required this.character,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ScreenHelper.isDesktop();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: GestureDetector(
        onTap: onTap,
        onLongPress:
            ScreenHelper.isMobile() ? () => _showContextMenu(context) : null,
        onSecondaryTapDown:
            isDesktop
                ? (details) =>
                    _showDesktopContextMenu(context, details.globalPosition)
                : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 角色头像
            avatarArea(),

            SizedBox(height: 4.0),

            // 角色信息
            infoArea(context),
          ],
        ),
      ),
    );
  }

  Widget avatarArea() {
    return Expanded(
      flex: 2,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        child: buildAvatarClipOval(character.avatar, clipBehavior: Clip.none),
      ),
    );
  }

  Widget infoArea(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 角色名称和系统标签
            Row(
              children: [
                Expanded(
                  child: Text(
                    character.name,
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (character.isSystem)
                  Container(
                    padding: EdgeInsets.all(2.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '系统',
                      style: TextStyle(fontSize: 10.0, color: Colors.blue),
                    ),
                  ),
              ],
            ),
            if (ScreenHelper.isDesktop()) SizedBox(height: 8),
            // 角色描述
            Expanded(
              child: Text(
                character.description,
                style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
                maxLines: ScreenHelper.isDesktop() ? 3 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 移动端长按菜单
  void _showContextMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          onTap: onEdit,
          child: Row(
            children: [
              Icon(Icons.edit, color: Theme.of(context).primaryColor),
              SizedBox(width: 8),
              Text('编辑角色'),
            ],
          ),
        ),
        // if (!character.isSystem)
        PopupMenuItem(
          onTap: onDelete,
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text('删除角色'),
            ],
          ),
        ),
      ],
    );
  }

  // 桌面端右键菜单
  void _showDesktopContextMenu(BuildContext context, Offset position) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: Theme.of(context).primaryColor, size: 20),
              SizedBox(width: 8),
              Text('编辑角色'),
            ],
          ),
        ),
        // if (!character.isSystem)
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('删除角色'),
            ],
          ),
        ),
      ],
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ).then((value) {
      if (value == null) return;

      switch (value) {
        case 'edit':
          onEdit();
          break;
        case 'delete':
          onDelete();
          break;
      }
    });
  }
}
