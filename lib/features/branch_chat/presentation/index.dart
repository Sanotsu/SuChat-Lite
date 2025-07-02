import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/storage/cus_get_storage.dart';
import '../../../core/utils/screen_helper.dart';
import '../../../shared/constants/constant_llm_enum.dart';
import '../../../shared/widgets/simple_marquee_or_text.dart';
import '../../../shared/widgets/simple_tool_widget.dart';
import '../domain/entities/branch_chat_session.dart';
import '../domain/entities/character_card.dart';
import '../domain/entities/message_font_color.dart';
import 'branch_chat_handler/index.dart';
import 'branch_chat_state/index.dart';
import 'branch_chat_ui/index.dart';

import 'pages/branch_chat_history.dart';
import 'widgets/index.dart';
import 'pages/character_list_page.dart';

/// 分支聊天页面，重构后的入口
class BranchChatPage extends StatefulWidget {
  // 角色对话的角色卡
  final CharacterCard? character;

  const BranchChatPage({super.key, this.character});

  @override
  State<BranchChatPage> createState() => _BranchChatPageState();
}

class _BranchChatPageState extends State<BranchChatPage>
    with WidgetsBindingObserver {
  // 状态
  final BranchChatState state = BranchChatState();

  // 处理器
  late InitHandler _initHandler;
  late ScrollHandler _scrollHandler;
  late BranchMessageHandler _messageHandler;
  late AIResponseHandler _aiResponseHandler;
  late BranchSessionHandler _branchSessionHandler;
  late UserInteractionHandler _userInteractionHandler;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 初始化状态
    state.currentCharacter = widget.character;
    state.isSidebarVisible = _isDesktop();
    state.colorConfig = MessageFontColor.defaultConfig();
    state.textScaleFactor = CusGetStorage().getChatMessageTextScale();

    // 初始化处理器
    _initHandler = InitHandler(state, setState);
    _scrollHandler = ScrollHandler(state, setState);
    _messageHandler = BranchMessageHandler(state, setState);
    _aiResponseHandler = AIResponseHandler(state, setState);
    _branchSessionHandler = BranchSessionHandler(state, setState);
    _userInteractionHandler = UserInteractionHandler(state, setState, context);

    // 初始化存储和监听
    _initHandler.initStore();
    _initHandler.setupScrollListener();

    // 初始化应用
    _initHandler.initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 初始化用户交互处理器 (需要context)
    _userInteractionHandler = UserInteractionHandler(state, setState, context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    state.dispose();
    super.dispose();
  }

  // 布局发生变化时（如键盘弹出/收起）
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    // 流式响应还未完成且不是用户手动滚动，滚动到底部
    if (state.isStreaming && !state.isUserScrolling) {
      _scrollHandler.resetContentHeight();
    }
  }

  bool _isDesktop() {
    return ScreenHelper.isDesktop();
  }

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 移动端的历史记录是新页面，桌面端的是侧边栏
    // 但从新页面或者侧边栏组建返回时，都是执行同样的刷新操作
    Future<void> onHistoryActionCompleted({
      BranchChatSession? session,
      String? action,
    }) async {
      if (session != null && action == 'edit') {
        // 会话已在历史记录组件内部更新，这里只需要更新UI
        setState(() {});
      } else if (session != null && action == 'delete') {
        // 如果删除的是当前会话，创建新会话
        if (session.id == state.currentSessionId) {
          await _branchSessionHandler.createNewChat();
        }
        setState(() {});
      } else if (action == 'model-import') {
        await _initHandler.initModels();
      }

      // 重新加载会话列表并更新UI
      final updatedSessions = _initHandler.loadSessions();

      // 强制更新UI
      setState(() {
        state.sessionList = updatedSessions;
      });
    }

    // 创建应用栏
    final customAppBar = AppBar(
      backgroundColor: Colors.transparent,
      title: SimpleMarqueeOrText(
        data:
            state.currentCharacter != null
                ? "${state.currentCharacter?.name}"
                : "${CP_NAME_MAP[state.selectedModel?.platform]} > ${state.selectedModel?.model}",
        velocity: 30,
        width: 0.6.sw,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
      // 移动端历史记录按钮
      leading: IconButton(
        icon: Icon(Icons.menu_outlined),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => BranchChatHistoryPage(
                    currentSessionId: state.currentSessionId,
                    onSessionSelected: (session) async {
                      if (!mounted) return;
                      await _branchSessionHandler.switchSession(session.id);
                    },
                    onCompleted: onHistoryActionCompleted,
                  ),
            ),
          );
        },
      ),
      actions: [
        if (ScreenHelper.isMobile())
          _userInteractionHandler.buildPopupMenuButton(),
        IconButton(
          onPressed:
              !state.isStreaming
                  ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CharacterListPage(),
                      ),
                    );
                  }
                  : null,
          tooltip: '角色管理',
          icon: Icon(Icons.people),
        ),
      ],
    );

    // 创建主体内容
    final mainBody = Stack(
      children: [
        Column(
          children: [
            /// 添加模型过滤器
            ModelTypeFilter(
              models: state.modelList,
              selectedType: state.selectedType,
              onTypeChanged:
                  state.isStreaming
                      ? null
                      : _userInteractionHandler.handleTypeChanged,
              onModelSelect:
                  state.isStreaming
                      ? null
                      : _userInteractionHandler.showModelSelector,
              isStreaming: state.isStreaming,
              isCusChip: true,
            ),

            /// 聊天内容
            Expanded(
              child:
                  state.displayMessages.isEmpty
                      ? buildEmptyMessageHint(state.currentCharacter)
                      : MessageList(
                        state: state,
                        setState: setState,
                        aiResponseHandler: _aiResponseHandler,
                        userInteractionHandler: _userInteractionHandler,
                      ),
            ),

            /// 流式响应时显示进度条
            if (state.isStreaming) ResponseLoading(),

            /// 输入框
            BranchChatInputBar(
              controller: state.inputController,
              focusNode: state.inputFocusNode,
              onSend: _messageHandler.handleSendMessage,
              onCancel:
                  state.currentEditingMessage != null
                      ? _userInteractionHandler.handleCancelEditUserMessage
                      : null,
              isEditing: state.currentEditingMessage != null,
              isStreaming: state.isStreaming,
              onStop: _aiResponseHandler.handleStopStreaming,
              model: state.selectedModel,
              onHeightChanged: (height) {
                setState(() => state.inputHeight = height);
              },
            ),
          ],
        ),

        /// 悬浮按钮
        FloatingButtonGroup(
          state: state,
          setState: setState,
          branchSessionHandler: _branchSessionHandler,
          scrollHandler: _scrollHandler,
        ),
      ],
    );

    // 使用自适应布局组件
    return AdaptiveChatLayout(
      key: ValueKey(
        "${state.currentSessionId}-${state.currentCharacter?.name}",
      ),
      isLoading: state.isLoading,
      body: GestureDetector(
        // 允许子控件（如TextField）接收点击事件
        behavior: HitTestBehavior.translucent,
        // 点击空白处可以移除焦点，关闭键盘
        onTap: unfocusHandle,
        child: mainBody,
      ),
      // 桌面端历史记录侧边栏
      historyContent: BranchChatHistoryPanel(
        key: ValueKey(
          '${state.backgroundImage.hashCode}-${state.sessionList.length}',
        ),
        currentSessionId: state.currentSessionId,
        onSessionSelected: (session) async {
          await _branchSessionHandler.switchSession(session.id);
        },
        onCompleted: onHistoryActionCompleted,
      ),
      rightSidebar:
          _isDesktop()
              ? _userInteractionHandler.buildDesktopRightSidebarPanel()
              : null,
      appBar: customAppBar,
      title: customAppBar.title,
      actions: customAppBar.actions,
      isHistorySidebarVisible: state.isSidebarVisible,
      onHistorySidebarToggled: (isVisible) {
        setState(() => state.isSidebarVisible = isVisible);
      },
      background: ChatBackground(
        backgroundImage: state.backgroundImage,
        opacity: state.backgroundOpacity,
      ),
      floatingAvatarButton: Stack(
        children: [
          // 角色头像预览
          // 有角色头像且抽屉未展开且桌面端侧边栏未展开
          if ((state.currentCharacter != null &&
              state.currentCharacter!.avatar.isNotEmpty))
            DraggableCharacterAvatarPreview(
              key: ValueKey(state.currentCharacter!.avatar),
              character: state.currentCharacter!,
              left:
                  state.isSidebarVisible
                      ? (ScreenHelper.isMobile() ? 0.8.sw + 4 : 284)
                      : 4,
            ),
        ],
      ),
    );
  }
}
