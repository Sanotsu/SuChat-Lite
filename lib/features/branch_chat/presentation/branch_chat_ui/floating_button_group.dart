import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/utils/screen_helper.dart';
import '../branch_chat_state/branch_chat_state.dart';
import '../branch_chat_handler/branch_session_handler.dart';
import '../branch_chat_handler/scroll_handler.dart';

/// 浮动按钮组
class FloatingButtonGroup extends StatefulWidget {
  final BranchChatState state;
  final Function setState;
  final BranchSessionHandler branchSessionHandler;
  final ScrollHandler scrollHandler;

  const FloatingButtonGroup({
    super.key,
    required this.state,
    required this.setState,
    required this.branchSessionHandler,
    required this.scrollHandler,
  });

  @override
  State<FloatingButtonGroup> createState() => _FloatingButtonGroupState();
}

class _FloatingButtonGroupState extends State<FloatingButtonGroup> {
  BranchChatState get state => widget.state;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      // 悬浮按钮有设定上下间距，根据其他组件布局适当调整位置
      bottom: state.isStreaming ? state.inputHeight + 5 : state.inputHeight - 5,
      child: Container(
        // 新版本输入框为了更多输入内容，左右边距为0
        padding: EdgeInsets.symmetric(horizontal: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 图标按钮的默认尺寸是48*48,占位宽度默认48
            SizedBox(width: 48),
            if (state.displayMessages.isNotEmpty && !state.isStreaming)
              // 新加对话按钮的背景色
              Padding(
                // 这里的上下边距，和下面maxHeight的和，要等于默认图标按钮高度的48sp
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  // 限制按钮的最大尺寸
                  constraints: BoxConstraints(maxWidth: 124, maxHeight: 32),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      // 设置按钮的背景色为透明
                      backgroundColor: Colors.transparent,
                      alignment: Alignment.center, // 让内容居中
                    ),
                    onPressed: _handleNewChat,
                    child: Text(
                      '开启新对话',
                      style: TextStyle(fontSize: 12.sp, color: Colors.white),
                    ),
                  ),
                ),
              ),
            if (state.showScrollToBottom)
              // 按钮图标变小，但为了和下方的发送按钮对齐，所以补足占位宽度
              IconButton(
                iconSize: 24,
                icon: Icon(Icons.arrow_circle_down_outlined),
                onPressed: () => widget.scrollHandler.resetContentHeight(),
              ),
            // 不显示滚动按钮时，添加空白区域保持布局一致
            if (!state.showScrollToBottom)
              SizedBox(width: ScreenHelper.isDesktop() ? 40 : 48),
          ],
        ),
      ),
    );
  }

  /// 处理新建对话
  void _handleNewChat() {
    if (state.currentCharacter != null) {
      widget.branchSessionHandler.createNewChat(isNewBranch: false);
    } else {
      widget.branchSessionHandler.createNewChat();
    }
  }
}
