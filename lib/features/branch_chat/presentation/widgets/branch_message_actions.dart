import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/widgets/audio_player_widget.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../../../shared/constants/constants.dart';
import '../../domain/entities/branch_chat_message.dart';

class BranchMessageActions extends StatelessWidget {
  // 当前消息
  final BranchChatMessage message;
  // 所有消息
  final List<BranchChatMessage> messages;
  // 重新生成回调
  final VoidCallback onRegenerate;
  // 是否正在重新生成
  final bool isRegenerating;
  // 是否有多条分支
  final bool hasMultipleBranches;
  // 当前分支索引
  final int currentBranchIndex;
  // 总分支数量
  final int totalBranches;
  // 切换分支回调
  final Function(BranchChatMessage, int)? onSwitchBranch;

  const BranchMessageActions({
    super.key,
    required this.message,
    required this.messages,
    required this.onRegenerate,
    this.isRegenerating = false,
    required this.hasMultipleBranches,
    required this.currentBranchIndex,
    required this.totalBranches,
    this.onSwitchBranch,
  });

  // 获取实际可用的分支数量和索引
  List<BranchChatMessage> _getAvailableSiblings() {
    if (!hasMultipleBranches) return [message];

    // 获取同级分支并按实际索引排序
    final siblings =
        messages
            .where(
              (m) =>
                  m.parent.target?.id == message.parent.target?.id &&
                  m.depth == message.depth,
            )
            .toList()
          ..sort((a, b) => a.branchIndex.compareTo(b.branchIndex));

    return siblings;
  }

  @override
  Widget build(BuildContext context) {
    final isUser =
        message.role == CusRole.user.name ||
        message.role == CusRole.system.name;

    // 获取实际可用的分支数量和索引
    final availableSiblings = _getAvailableSiblings();
    final showBranchControls = availableSiblings.length > 1;

    // 获取可用分支中最大的分支索引
    // totalBranches是所有分支的数量，maxBranchIndex是可用分支中最大的分支索引
    // 加入原本有分支1、2、3(当然存储时是0、1、2,显示时都+1)，现在删除了分支2，
    // 那么totalBranches=2，maxBranchIndex=3
    // 在切换时分支显示的时候，需要显示“分支1/3”、“分支3/3”，
    // 但作为是否可以切换判断的时候，需要判断 totalBranches =2
    final maxBranchIndex = availableSiblings
        .map((e) => e.branchIndex)
        .reduce((a, b) => a > b ? a : b);

    // 获取大模型合成音频URL(和用户选择的音频，都是同一个变量，但用户选择的这个组件不处理)
    List<String> ttsUrls = [];
    if (message.audiosUrl != null && message.audiosUrl!.trim() != "") {
      String audios = message.audiosUrl!;
      ttsUrls = audios.split(',');
    }

    return Container(
      padding: EdgeInsets.all(4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // 复制按钮
          IconButton(
            icon: Icon(Icons.copy, size: 20),
            visualDensity: VisualDensity.compact,
            tooltip: '复制内容',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: message.content));
              ToastUtils.showSuccess("已复制到剪贴板");
            },
          ),

          // 如果不是用户消息，且不是正在重新生成，则显示重新生成按钮
          if (!isUser && !isRegenerating)
            IconButton(
              icon: Icon(Icons.refresh, size: 20),
              onPressed: onRegenerate,
              tooltip: '重新生成',
            ),

          // 如果不是用户消息，但是在重新生成中，则显示加载
          // 2025-03-15 这会让对话列表中所有的AI响应消息体的工具栏都显示加载图标。
          // 理论上应该只是最后一条才对，现在这里不好处理，就改为流式响应中不显示重新生成图标
          // if (!isUser && isRegenerating)
          //   SizedBox(
          //     width: 16,
          //     height: 16,
          //     child: CircularProgressIndicator(strokeWidth: 2),
          //   ),

          /// 2025-06-09 语音播放按钮
          /// 只显示大模型合成的音频播放
          /// （如果是用户选择的语音不在消息功能按钮中显示)
          if (ttsUrls.isNotEmpty && message.role != CusRole.user.name)
            AudioPlayerWidget(
              audioUrl: ttsUrls.first,
              dense: true,
              onlyIcon: true,
              secondaryColor: Colors.green,
            ),

          // 如果是用户有语音转文字的原始语音内容，显示语音播放按钮
          // 【这个只有用户消息才会有，上面那个只处理大模型响应，所以理论上不会出现2个音频播放按钮】
          if (message.contentVoicePath != null &&
              message.contentVoicePath!.trim() != "")
            AudioPlayerWidget(
              audioUrl: message.contentVoicePath!,
              dense: true,
              onlyIcon: true,
            ),

          // 分支切换按钮
          if (showBranchControls && onSwitchBranch != null) ...[
            SizedBox(width: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios, size: 20),
                      padding: EdgeInsets.zero, // 移除边距
                      onPressed:
                          currentBranchIndex > 0 && onSwitchBranch != null
                              ? () => onSwitchBranch!(
                                message,
                                currentBranchIndex - 1,
                              )
                              : null,
                    ),
                  ),
                  Text(
                    '${message.branchIndex + 1} / ${maxBranchIndex + 1} ($totalBranches)',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: IconButton(
                      icon: Icon(Icons.arrow_forward_ios, size: 20),
                      padding: EdgeInsets.zero, // 移除边距
                      onPressed:
                          currentBranchIndex < totalBranches - 1 &&
                                  onSwitchBranch != null
                              ? () => onSwitchBranch!(
                                message,
                                currentBranchIndex + 1,
                              )
                              : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
