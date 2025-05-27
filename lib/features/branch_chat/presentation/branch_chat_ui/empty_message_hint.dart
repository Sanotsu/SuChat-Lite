import 'package:flutter/material.dart';

import '../../domain/entities/character_card.dart';
import '../widgets/index.dart';

/// 当没有消息时显示的提示组件
class EmptyMessageHint extends StatelessWidget {
  final CharacterCard? character;

  const EmptyMessageHint({super.key, this.character});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child:
                  character != null
                      ? buildAvatarClipOval(character!.avatar)
                      : Icon(Icons.chat, size: 36, color: Colors.blue),
            ),
            Text(
              '嗨，我是${character?.name ?? "SuChat"}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            Text(
              character != null ? '让我们开始聊天吧！' : '我可以帮您完成很多任务，让我们开始吧！',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
