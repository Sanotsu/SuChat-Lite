import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math';

import '../../../common/components/toast_utils.dart';
import '../../../common/constants/constants.dart';
import '../../../common/utils/screen_helper.dart';
import '../../../common/utils/tools.dart';
import '../../../common/llm_spec/cus_brief_llm_model.dart';
import '../../../common/llm_spec/constant_llm_enum.dart';
import '../../../common/components/simple_marquee_or_text.dart';
import '../../../common/components/tool_widget.dart';
import '../../../common/utils/advanced_options_utils.dart';
import '../../../common/components/cus_markdown_renderer.dart';
import '../../../models/brief_ai_tools/branch_chat/branch_chat_message.dart';
import '../../../models/brief_ai_tools/branch_chat/branch_manager.dart';
import '../../../models/brief_ai_tools/branch_chat/branch_store.dart';
import '../../../models/brief_ai_tools/branch_chat/branch_chat_session.dart';
import '../../../models/brief_ai_tools/branch_chat/character_card.dart';
import '../../../models/brief_ai_tools/branch_chat/character_store.dart';
import '../../../services/model_manager_service.dart';
import '../../../services/chat_service.dart';
import '../../../services/cus_get_storage.dart';

import '../_chat_components/text_edit_dialog.dart';
import '../_chat_components/_small_tool_widgets.dart';
import '../_chat_components/model_filter.dart';
import '../_chat_components/chat_input_bar.dart';
import '../_chat_components/text_selection_dialog.dart';
import '../_chat_pages/chat_export_import_page.dart';
import '../_chat_pages/chat_background_picker_page.dart';

import 'components/branch_message_item.dart';
import 'components/branch_tree_dialog.dart';
import 'components/branch_message_actions.dart';
import 'components/adaptive_chat_layout.dart';
import 'components/branch_chat_history_panel.dart';
import 'components/adaptive_model_selector.dart';
import 'components/draggable_character_avatar_preview.dart';
import 'components/message_color_config.dart';
import 'pages/add_model_page.dart';
import 'pages/character_list_page.dart';

///
/// 分支对话主页面
///
/// 除非是某个函数内部使用且不再全局其他地方也能使用的方法设为私有，其他都不加下划线
///
class BranchChatPage extends StatefulWidget {
  // 角色对话的角色卡
  final CharacterCard? character;

  const BranchChatPage({super.key, this.character});

  @override
  State<BranchChatPage> createState() => _BranchChatPageState();
}

class _BranchChatPageState extends State<BranchChatPage>
    with WidgetsBindingObserver {
  // 分支管理器
  final BranchManager branchManager = BranchManager();
  // 分支存储器
  late final BranchStore store;
  // 缓存存储器
  final MyGetStorage storage = MyGetStorage();

  // 输入框控制器
  final TextEditingController inputController = TextEditingController();
  // 添加焦点控制器
  final FocusNode inputFocusNode = FocusNode();
  // 输入框高度状态(用于悬浮按钮的布局)
  // 输入框展开收起工具栏时，悬浮按钮(新加对话、滚动到底部)位置需要动态变化，始终在输入框的上方
  double inputHeight = 0;

  // 所有消息
  List<BranchChatMessage> allMessages = [];
  // 当前显示的消息
  List<BranchChatMessage> displayMessages = [];
  // 当前分支路径
  String currentBranchPath = "0";
  // 当前编辑的消息
  BranchChatMessage? currentEditingMessage;

  // 是否加载中
  bool isLoading = true;
  // 是否流式生成
  bool isStreaming = false;

  // 流式生成内容
  String streamingContent = '';
  // 流式生成推理内容(深度思考)
  String streamingReasoningContent = '';
  // 流式生成消息(追加显示的消息)
  BranchChatMessage? streamingMessage;

  // 是否全新分支对话
  bool isBranchNewChat = false;
  // 当前会话ID
  int? currentSessionId;
  // 重新生成消息ID
  int? regeneratingMessageId;

  // 添加模型相关状态
  List<CusBriefLLMSpec> modelList = [];
  LLModelType selectedType = LLModelType.cc;
  CusBriefLLMSpec? selectedModel;

  // 添加高级参数状态
  bool advancedEnabled = false;
  Map<String, dynamic>? advancedOptions;

  // 默认的页面主体的缩放比例(对话太小了就可以等比放大)
  // 直接全局缓存，所有使用ChatListArea的地方都改了
  double textScaleFactor = 1.0;

  // 是否简洁显示(如果是就不显示头像、消息工具列等内容)
  bool isBriefDisplay = false;

  // 对话列表滚动控制器
  final ScrollController scrollController = ScrollController();
  // 是否显示"滚动到底部"按钮
  bool showScrollToBottom = false;
  // 是否用户手动滚动
  bool isUserScrolling = false;
  // 最后内容高度(用于判断是否需要滚动到底部)
  double lastContentHeight = 0;

  // 添加背景图片状态
  String? backgroundImage;
  // 背景透明度,可调整
  double backgroundOpacity = 0.35;

  // 添加手动终止响应的取消回调
  VoidCallback? cancelResponse;

  // 添加会话列表状态
  List<BranchChatSession> sessionList = [];

  // 当前角色
  CharacterCard? currentCharacter;

  // 桌面端侧边栏状态
  bool isSidebarVisible = false;

  late MessageColorConfig _colorConfig;

  ///******************************************* */
  ///
  /// 在构建UI前，都是初始化和工具的方法
  ///
  ///******************************************* */

  @override
  void initState() {
    super.initState();

    // 初始化颜色配置为默认值，避免在异步加载前被访问
    _colorConfig = MessageColorConfig.defaultConfig();

    // 设置当前角色
    currentCharacter = widget.character;

    // 初始化桌面端侧边栏状态
    isSidebarVisible = ScreenHelper.isDesktop();

    // 初始化分支存储器
    _initStore();

    // 初始化模型列表和会话
    // (分支存储器不能重复初始化，但这个方法会重复调用，所以不放在一起)
    initialize();

    // 获取缓存中的正文文本缩放比例
    textScaleFactor = MyGetStorage().getChatMessageTextScale();

    // 获取缓存的高级选项配置
    if (selectedModel != null) {
      advancedEnabled = MyGetStorage().getAdvancedOptionsEnabled(
        selectedModel!,
      );
      if (advancedEnabled) {
        advancedOptions = MyGetStorage().getAdvancedOptions(selectedModel!);
      }
    }

    // 监听滚动事件
    scrollController.addListener(() {
      // 判断用户是否正在手动滚动
      if (scrollController.position.userScrollDirection ==
              ScrollDirection.reverse ||
          scrollController.position.userScrollDirection ==
              ScrollDirection.forward) {
        isUserScrolling = true;
      } else {
        isUserScrolling = false;
      }

      // 判断是否显示"滚动到底部"按钮
      setState(() {
        showScrollToBottom =
            scrollController.offset <
            scrollController.position.maxScrollExtent - 50;
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    inputFocusNode.dispose();
    inputController.dispose();
    scrollController.dispose();
    cancelResponse?.call();

    // 清理Markdown渲染缓存，释放内存
    CusMarkdownRenderer.instance.clearCache();

    super.dispose();
  }

  // 布局发生变化时（如键盘弹出/收起）
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    // 流式响应还未完成且不是用户手动滚动，滚动到底部
    if (isStreaming && !isUserScrolling) {
      resetContentHeight();
    }
  }

  /// 初始化方法(初始化模型列表、最新会话)
  Future<void> initialize() async {
    try {
      // 初始化消息体颜色
      await _loadColorConfig();

      // 初始化模型列表
      await initModels();

      // 初始化会话
      await _initSession();

      // 如果初始化时有角色，默认简洁显示
      // if (currentCharacter != null) {
      //   setState(() => isBriefDisplay = true);
      // }

      // 加载背景图片设置
      loadBackgroundSettings();
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadColorConfig() async {
    final config = await MyGetStorage().loadMessageColorConfig();

    setState(() {
      _colorConfig = config;
    });
  }

  Future<void> reapplyMessageColorConfig() async {
    // 重新加载颜色配置
    await _loadColorConfig();

    // 强制清除所有缓存
    setState(() {
      CusMarkdownRenderer.instance.clearCache();
    });

    // 再次设置状态强制重建整个页面
    setState(() {
      // 强制重新加载所有消息
      final tempMessages = List<BranchChatMessage>.from(displayMessages);
      displayMessages = [];

      // 延迟一帧再恢复消息列表，确保UI完全刷新
      Future.microtask(() {
        if (mounted) {
          setState(() {
            displayMessages = tempMessages;
          });
          // 恢复滚动位置
          resetContentHeight();
        }
      });
    });
  }

  initModels() async {
    // 获取可用模型列表
    final availableModels = await ModelManagerService.getAvailableModelByTypes([
      LLModelType.cc,
      LLModelType.vision,
      LLModelType.reasoner,
      LLModelType.vision_reasoner,
    ]);

    if (!mounted) return;
    setState(() {
      modelList = availableModels;
      selectedModel = availableModels.first;
      selectedType = selectedModel!.modelType;
    });
  }

  Future<void> _initStore() async {
    store = await BranchStore.create();

    // 初始化时加载会话列表
    loadSessions();
  }

  /// 过滤指定角色排序后的会话
  List<BranchChatSession> _filterCharacterSessions() {
    return store.sessionBox
        .getAll()
        .toList()
        .where((e) => e.characterId == currentCharacter!.characterId)
        .toList()
      ..sort((a, b) => b.updateTime.compareTo(a.updateTime));
  }

  /// 获取所有排序后的会话
  List<BranchChatSession> _getSortedSessions() {
    return store.sessionBox.getAll().toList()
      ..sort((a, b) => b.updateTime.compareTo(a.updateTime));
  }

  /// 处理模型选择和对话创建
  Future<void> _handleModelSelectionAndChatCreation(
    BranchChatSession? session,
  ) async {
    // 当前使用模型，如果有当前角色则使用角色模型；如果有当前会话则使用会话模型
    final cusLlmSpecId =
        currentCharacter?.preferredModel?.cusLlmSpecId ??
        session?.llmSpec.cusLlmSpecId;

    // 根据cusLlmSpecId获取模型
    selectedModel =
        modelList.where((m) => m.cusLlmSpecId == cusLlmSpecId).firstOrNull;

    // 如果模型不存在，则使用默认模型
    if (selectedModel == null) {
      ToastUtils.showInfo(
        '最新对话所用模型已被删除，将使用默认模型构建全新对话。',
        duration: const Duration(seconds: 5),
      );
      setState(() {
        selectedModel = modelList.first;
        selectedType = selectedModel!.modelType;
      });
      await createNewChat();
    } else {
      // 如果模型存在，则更新UI
      setState(() {
        selectedType = selectedModel!.modelType;
        isBranchNewChat = false;
        isLoading = false;
      });
      // 如果当前会话存在，则加载消息
      if (session != null) {
        await loadMessages();
      }
    }
  }

  /// 初始化会话
  Future<void> _initSession() async {
    // 根据是否有使用角色获取所有的会话记录
    var sessions =
        currentCharacter != null
            ? _filterCharacterSessions()
            : _getSortedSessions();

    // 如果没有任何对话记录，则标记创建新对话
    if (sessions.isEmpty) {
      setState(() {
        isBranchNewChat = true;
        isLoading = false;
      });

      // 2025-04-07 如果没有对话记录，但是有选择当前角色，直接创建新角色对话
      // 如果没有对话记录，也没有角色，上面设置了 isBranchNewChat 标记，直接返回即可
      if (currentCharacter != null) {
        await _handleModelSelectionAndChatCreation(null);
        // 不是新的分支对话(即新的角色对话)
        await createNewChat(isNewBranch: false);
        // 新建对话后要更新当前对话列表，以便后面逻辑继续
        sessions = _filterCharacterSessions();
      }
      return;
    }

    // 如果有会话记录，则获取是今天的最后一条对话记录
    // 如果有会话记录但今天没有对话记录，则获取最后一条对话记录
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    final todayLastSession = sessions.firstWhere(
      (session) => session.updateTime.isAfter(todayStart),
      orElse: () => sessions.first,
    );

    try {
      setState(() {
        // 设置当前会话ID
        currentSessionId = todayLastSession.id;

        // 如果当天最后一条是角色对话，则更新角色
        if (todayLastSession.character != null) {
          currentCharacter = todayLastSession.character;
        }
      });

      await _handleModelSelectionAndChatCreation(todayLastSession);
    } catch (e) {
      // 如果没有任何对话记录，或者今天没有对话记录(会报错抛到这里)，显示新对话界面
      setState(() {
        isBranchNewChat = true;
        isLoading = false;
      });
    }

    // 延迟执行滚动到底部，确保UI已完全渲染
    WidgetsBinding.instance.addPostFrameCallback((_) {
      resetContentHeight(times: 2000);
    });
  }

  /// 加载消息
  Future<void> loadMessages() async {
    if (currentSessionId == null) {
      setState(() => isBranchNewChat = true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final messages = store.getSessionMessages(currentSessionId!);
      if (messages.isEmpty) {
        setState(() {
          isBranchNewChat = true;
          isLoading = false;
          displayMessages.clear();
        });
        return;
      }

      final currentMessages = branchManager.getMessagesByBranchPath(
        messages,
        currentBranchPath,
      );

      setState(() {
        allMessages = messages;
        displayMessages = [
          ...currentMessages,
          if (isStreaming &&
              (streamingContent.isNotEmpty ||
                  streamingReasoningContent.isNotEmpty))
            BranchChatMessage(
              id: 0,
              messageId: 'streaming',
              role: CusRole.assistant.name,
              content: streamingContent,
              reasoningContent: streamingReasoningContent,
              createTime: DateTime.now(),
              branchPath: currentBranchPath,
              branchIndex:
                  currentMessages.isEmpty
                      ? 0
                      : currentMessages.last.branchIndex,
              depth: currentMessages.isEmpty ? 0 : currentMessages.last.depth,
            ),
        ];
        isLoading = false;
      });
    } catch (e) {
      pl.e('加载消息失败: $e');
      setState(() {
        isBranchNewChat = true;
        isLoading = false;
      });
    }

    resetContentHeight();
  }

  // 加载背景设置
  // 2025-04-18 暂时以下情况会调用到此函数
  //   0. 此页面初始化时
  //   1. 从切换背景页面返回时
  //   2. 切换对话记录时
  //   3.创建新对话时(不管是切换模型还是点击新开按钮)
  Future<void> loadBackgroundSettings() async {
    // 从角色加载背景设置（如果有角色）
    if (currentCharacter != null && currentCharacter!.background != null) {
      setState(() {
        backgroundImage = currentCharacter!.background;
        backgroundOpacity = currentCharacter!.backgroundOpacity ?? 0.35;
      });
    } else {
      // 从本地存储加载背景图片设置
      final background = await storage.getBranchChatBackground();
      final opacity = await storage.getBranchChatBackgroundOpacity();

      // 只有当值不同时才更新UI
      if (background != backgroundImage || opacity != backgroundOpacity) {
        setState(() {
          backgroundImage = background;
          backgroundOpacity = opacity ?? 0.2;
        });
      }
    }
  }

  ///******************************************* */
  ///
  /// 构建UI，从上往下放置相关内容
  ///
  ///******************************************* */
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 创建应用栏
    final customAppBar = AppBar(
      backgroundColor: Colors.transparent,
      title: SimpleMarqueeOrText(
        data:
            currentCharacter != null
                ? "${currentCharacter?.name}"
                : "${CP_NAME_MAP[selectedModel?.platform]} > ${selectedModel?.model}",
        velocity: 30,
        width: 0.6.sw,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
      actions: [
        if (ScreenHelper.isMobile()) buildPopupMenuButton(),

        IconButton(
          onPressed:
              !isStreaming
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

        // 测试：不同平台页面显示效果
        // IconButton(
        //   onPressed: () {
        //     Navigator.push(
        //       context,
        //       MaterialPageRoute(
        //         builder: (context) => ResponsiveLayoutExample(),
        //       ),
        //     );
        //   },
        //   icon: Icon(Icons.textsms_sharp),
        // ),

        //  2025-04-11 暂存，后续考虑页面之间跳转优化
        // 2025-04-28 功能暂不完善，先不启用
        // IconButton(
        //   icon: const Icon(Icons.grid_view),
        //   onPressed:
        //       isStreaming
        //           ? null
        //           : () {
        //             Navigator.push(
        //               context,
        //               MaterialPageRoute(builder: (context) => BriefAITools()),
        //             ).then((value) async {
        //               // 2025-04-08 嫌麻烦，从工具栏回来都重新初始化
        //               // 不只初始化模型是因为模型列表变化了，之前对话的模型不一定是当前加载后选中的模型
        //               await initialize();
        //             });
        //           },
        // ),
      ],
    );

    // 创建主体内容
    final mainBody = Stack(
      children: [
        Column(
          children: [
            /// 添加模型过滤器
            ModelFilter(
              models: modelList,
              selectedType: selectedType,
              onTypeChanged: isStreaming ? null : handleTypeChanged,
              onModelSelect: isStreaming ? null : showModelSelector,
              isStreaming: isStreaming,
              isCusChip: true,
            ),

            /// 聊天内容
            Expanded(
              child:
                  displayMessages.isEmpty
                      ? buildEmptyMessageHint(currentCharacter)
                      : buildMessageList(),
            ),

            /// 流式响应时显示进度条
            if (isStreaming) buildResponseLoading(),

            /// 输入框
            ChatInputBar(
              controller: inputController,
              focusNode: inputFocusNode,
              onSend: handleSendMessage,
              onCancel:
                  currentEditingMessage != null
                      ? handleCancelEditUserMessage
                      : null,
              isEditing: currentEditingMessage != null,
              isStreaming: isStreaming,
              onStop: handleStopStreaming,
              model: selectedModel,
              onHeightChanged: (height) {
                setState(() => inputHeight = height);
              },
            ),
          ],
        ),

        /// 悬浮按钮
        buildFloatingButton(),
      ],
    );

    // 使用自适应布局组件
    return AdaptiveChatLayout(
      key: ValueKey("$currentSessionId-${currentCharacter?.name}"),
      isLoading: isLoading,
      body: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
        ),
        child: mainBody,
      ),
      historyContent: buildChatHistoryContent(),
      rightSidebar:
          ScreenHelper.isDesktop() ? buildDesktopRightSidebarPanel() : null,
      appBar: customAppBar,
      title: customAppBar.title,
      actions: customAppBar.actions,
      isHistorySidebarVisible: isSidebarVisible,
      onHistorySidebarToggled: (isVisible) {
        setState(() => isSidebarVisible = isVisible);
      },
      background: buildBackground(),
      floatingAvatarButton: Stack(
        children: [
          // 角色头像预览
          // 有角色头像且抽屉未展开且桌面端侧边栏未展开
          if ((currentCharacter != null && currentCharacter!.avatar.isNotEmpty))
            DraggableCharacterAvatarPreview(
              key: ValueKey(currentCharacter!.avatar),
              character: currentCharacter!,
              left:
                  isSidebarVisible
                      ? (ScreenHelper.isMobile() ? 0.8.sw + 4 : 284)
                      : 4,
            ),
        ],
      ),
    );
  }

  ///******************************************* */
  ///
  /// AppBar 和 Drawer 相关的内容方法
  ///
  ///******************************************* */
  // 弹窗菜单按钮
  Widget buildPopupMenuButton() {
    return PopupMenuButton<String>(
      enabled: !isStreaming,
      icon: const Icon(Icons.more_horiz_sharp),
      // 调整弹出按钮的位置
      position: PopupMenuPosition.under,
      // 弹出按钮的偏移
      // offset: Offset(-25, 0),
      onSelected: (String value) async {
        // 处理选中的菜单项
        if (value == 'add') {
          createNewChat();
        } else if (value == 'options') {
          showAdvancedOptions();
        } else if (value == 'text_size') {
          adjustTextScale(context, textScaleFactor, (value) async {
            setState(() => textScaleFactor = value);
            await MyGetStorage().setChatMessageTextScale(value);

            if (!mounted) return;
            Navigator.of(context).pop();

            unfocusHandle();
          });
        } else if (value == 'tree') {
          showBranchTree();
        } else if (value == 'brief_mode') {
          showDisplayChangeDialog(context, isBriefDisplay, (value) {
            setState(() => isBriefDisplay = value);
            if (!mounted) return;
            Navigator.of(context).pop();

            unfocusHandle();
          });
        } else if (value == 'background') {
          changeBackground();
        } else if (value == 'add_model') {
          handleAddModel();
        } else if (value == 'export_import') {
          navigateToExportImportPage();
        }
        // else if (value == 'message_color') {
        //   Navigator.push(
        //     context,
        //     MaterialPageRoute(
        //       builder: (context) => const MessageColorSettingsPage(),
        //     ),
        //   ).then((value) async {
        //     // 重新加载颜色配置（因为对话列表缓存优化等原因，这里强制重新加载消息以便颜色生效）
        //     reapplyMessageColorConfig();
        //   });
        // }
      },
      itemBuilder:
          (BuildContext context) => <PopupMenuItem<String>>[
            buildCusPopupMenuItem(context, "add", "新加对话", Icons.add),
            buildCusPopupMenuItem(context, "options", "高级选项", Icons.tune),
            buildCusPopupMenuItem(
              context,
              "text_size",
              "文字大小",
              Icons.format_size_outlined,
            ),
            buildCusPopupMenuItem(
              context,
              "tree",
              "对话分支",
              Icons.account_tree_outlined,
            ),
            buildCusPopupMenuItem(
              context,
              "background",
              "切换背景",
              Icons.wallpaper,
            ),
            buildCusPopupMenuItem(
              context,
              "brief_mode",
              "简洁显示",
              Icons.view_agenda_outlined,
            ),
            buildCusPopupMenuItem(
              context,
              "add_model",
              "添加模型",
              Icons.add_box_outlined,
            ),
            buildCusPopupMenuItem(
              context,
              "export_import",
              "对话备份",
              Icons.import_export,
            ),
          ],
    );
  }

  /// 显示对话分支树
  void showBranchTree() {
    showDialog(
      context: context,
      builder:
          (context) => BranchTreeDialog(
            messages: allMessages,
            currentPath: currentBranchPath,
            onPathSelected: (path) {
              setState(() => currentBranchPath = path);
              // 重新加载选中分支的消息
              final currentMessages = branchManager.getMessagesByBranchPath(
                allMessages,
                path,
              );
              setState(() {
                displayMessages = currentMessages;
              });
              Navigator.pop(context);
            },
          ),
    );
  }

  // 调整对话列表中显示的文本大小
  void showDisplayChangeDialog(
    BuildContext context,
    bool isShow,
    Function(bool) onSwitchChanged,
  ) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('是否简洁显示', style: TextStyle(fontSize: 18)),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("简洁显示不显示消息体头像和下方的操作按钮"),
                  SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Switch(
                        value: isShow,
                        onChanged: (value) => setState(() => isShow = value),
                        // 缩小点击区域
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      Text(
                        isShow ? '简洁显示' : '常规显示',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('确定'),
              onPressed: () async {
                // 点击确定时，才把缩放比例存入缓存，并更新当前比例值
                onSwitchChanged(isShow);
              },
            ),
          ],
        );
      },
    );
  }

  // 显示高级选项弹窗
  Future<void> showAdvancedOptions() async {
    if (selectedModel == null) return;

    final result = await AdvancedOptionsUtils.showAdvancedOptions(
      context: context,
      platform: selectedModel!.platform,
      modelType: selectedModel!.modelType,
      currentEnabled: advancedEnabled,
      currentOptions: advancedOptions ?? {},
    );

    if (result != null) {
      setState(() {
        advancedEnabled = result.enabled;
        advancedOptions = result.enabled ? result.options : null;
      });

      // 保存到缓存
      await MyGetStorage().setAdvancedOptionsEnabled(
        selectedModel!,
        result.enabled,
      );
      await MyGetStorage().setAdvancedOptions(
        selectedModel!,
        result.enabled ? result.options : null,
      );
    }
  }

  void changeBackground() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChatBackgroundPickerPage(
              title: '切换对话背景',
              currentCharacter: currentCharacter,
            ),
      ),
    ).then((confirmed) {
      // 只有在用户点击了确定按钮时才重新加载背景设置
      if (confirmed == true) {
        loadBackgroundSettings();

        reapplyMessageColorConfig();
      }
    });
  }

  // 添加模型按钮点击处理
  Future<void> handleAddModel() async {
    final result = await Navigator.push<CusBriefLLMSpec>(
      context,
      MaterialPageRoute(builder: (context) => AddModelPage(isAddChat: true)),
    );

    // 1 从添加单个模型页面返回后，先重新初始化(加载之前的模型列表、会话内容等)
    await initialize();

    // 2 如果添加模型成功，则更新当前选中的模型和类型，并创建新对话
    if (result != null && mounted) {
      try {
        // 2.1 更新当前选中的模型和类型
        setState(() {
          selectedModel =
              modelList
                  .where((m) => m.cusLlmSpecId == result.cusLlmSpecId)
                  .firstOrNull;
          selectedType = result.modelType;
        });

        // 2.2. 创建新对话
        createNewChat();

        ToastUtils.showSuccess('添加模型成功');
      } catch (e) {
        if (mounted) {
          pl.e('添加模型失败: $e');
          commonExceptionDialog(context, '添加模型失败', e.toString());
        }
      }
    }
  }

  // 修改导入导出页面的跳转方法
  void navigateToExportImportPage() async {
    bool isGranted = await requestStoragePermission();

    if (!mounted) return;
    if (!isGranted) {
      commonExceptionDialog(context, "异常提示", "无存储访问授权");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatExportImportPage()),
    ).then((_) {
      // 返回后重新加载会话列表
      loadSessions();
    });
  }

  // 侧边栏内容构建方法
  Widget buildChatHistoryContent() {
    return BranchChatHistoryPanel(
      // 因为侧边栏主题色会根据对话背景色来适配，所以要加key
      key: ValueKey('${backgroundImage.hashCode}'),
      sessions: sessionList,
      currentSessionId: currentSessionId,
      onSessionSelected: (session) async {
        await switchSession(session.id);
      },
      onRefresh: ({session, action}) async {
        if (session != null && action == 'edit') {
          // 更新会话
          store.sessionBox.put(session);
        } else if (session != null && action == 'delete') {
          // 删除会话
          await store.deleteSession(session);
          // 如果删除的是当前会话，创建新会话
          if (session.id == currentSessionId) {
            createNewChat();
          }
        } else if (action == 'model-import') {
          initModels();
        }
        // 都要重新加载会话
        loadSessions();
      },
      // 桌面端在侧边栏中不需要关闭抽屉，移动端点击某条记录后要关闭抽屉
      needCloseDrawer: ScreenHelper.isDesktop() ? false : true,
    );
  }

  /// 加载历史对话列表并按更新时间排序
  List<BranchChatSession> loadSessions() {
    var list =
        store.sessionBox.getAll()
          ..sort((a, b) => b.updateTime.compareTo(a.updateTime));

    setState(() => sessionList = list);

    return list;
  }

  /// 切换历史对话(在抽屉中点选了不同的历史记录)
  Future<void> switchSession(int sessionId) async {
    // 有好几种情况是使用默认模型创建全新对话，所以提出来
    useDefaultModel(String hintKeyWord) {
      ToastUtils.showInfo(
        '该历史对话【$hintKeyWord】，将使用默认模型构建全新对话。',
        duration: const Duration(seconds: 3),
      );

      setState(() {
        selectedModel = modelList.first;
        selectedType = selectedModel!.modelType;
        isLoading = false;
      });

      createNewChat();
    }

    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    final session = store.sessionBox.get(sessionId);

    // 如果点击的会话不存在，则使用新的模型直接创建新对话
    if (session == null) {
      useDefaultModel('记录已不存在');
      return;
    }

    // 如果对话是角色对话，但角色已被删除，也使用默认模型创建新对话
    try {
      final store = await CharacterStore.create();
      if (session.character != null &&
          !(store.characters
              .map((c) => c.characterId)
              .toList()
              .contains(session.character?.characterId))) {
        useDefaultModel('所用角色已被删除');
        return;
      }
    } catch (e) {
      ToastUtils.showInfo('角色查询失败：$e', duration: const Duration(seconds: 3));
    }

    // 如果该对话使用的模型被删除，也使用默认模型创建新对话
    // 如果存在会话，但是会话使用的模型被删除了，也提示，并使用默认模型构建全新对话
    setState(() {
      selectedModel =
          modelList
              .where((m) => m.cusLlmSpecId == session.llmSpec.cusLlmSpecId)
              .firstOrNull;
    });

    if (selectedModel == null) {
      setState(() {
        currentSessionId = null;
      });

      useDefaultModel('所用模型已被删除');
      return;
    }

    // 到这里了就是正常有记录、有模型或者有角色的对话，正常处理
    setState(() {
      currentSessionId = sessionId;
      isBranchNewChat = false;
      currentBranchPath = "0";
      isStreaming = false;
      streamingContent = '';
      streamingReasoningContent = '';
      currentEditingMessage = null;
      inputController.clear();
    });

    // 更新当前选中的模型和类型
    setState(() {
      selectedType = selectedModel!.modelType;
      currentCharacter = session.character;
    });
    await loadMessages();

    loadBackgroundSettings();

    resetContentHeight();

    // 创建新对话等内部会有，所以这里就最后恢复加载状态即可
    setState(() {
      isLoading = false;
    });
  }

  ///******************************************* */
  ///
  /// 模型切换和选择区域的相关方法
  ///
  ///******************************************* */
  /// 切换模型类型
  void handleTypeChanged(LLModelType type) {
    setState(() {
      selectedType = type;

      // 如果当前选中的模型不是新类型的，则清空选择
      // 因为切换类型时，一定会触发模型选择器，在模型选择的地方有重新创建对话，所以这里不用重新创建
      if (selectedModel?.modelType != type) {
        selectedModel = null;
      }
    });
  }

  /// 显示模型选择弹窗
  Future<void> showModelSelector() async {
    // 获取可用的模型列表
    final filteredModels =
        modelList.where((m) => m.modelType == selectedType).toList();

    if (filteredModels.isEmpty && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前类型没有可用的模型')));
      return;
    }

    if (!mounted) return;

    // 使用自适应模型选择器，会根据平台选择最合适的显示方式
    final model = await AdaptiveModelSelector.show(
      context: context,
      models: filteredModels,
      selectedModel: selectedModel,
    );

    if (!mounted) return;
    if (model != null) {
      setState(() => selectedModel = model);
    } else {
      // 如果没有点击模型，则使用选定分类的第一个模型
      setState(() => selectedModel = filteredModels.first);
    }

    // 选择指定模型后，加载对应类型上次缓存的高级选项配置
    advancedEnabled = MyGetStorage().getAdvancedOptionsEnabled(selectedModel!);
    advancedOptions =
        advancedEnabled
            ? MyGetStorage().getAdvancedOptions(selectedModel!)
            : null;

    // 2025-03-03 切换模型后也直接重建对话好了？？？此时就不用重置内容高度了
    createNewChat();
  }

  ///******************************************* */
  ///
  /// 消息列表和消息相关的方法
  ///
  ///******************************************* */
  Widget buildMessageList() {
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScaleFactor)),
      child: ListView.builder(
        // 启用列表缓存
        cacheExtent: 1000.0, // 增加缓存范围
        addAutomaticKeepAlives: true,
        // 让ListView自动管理RepaintBoundary
        addRepaintBoundaries: true,
        // 使用itemCount限制构建数量
        itemCount: displayMessages.length,
        controller: scrollController,
        // 列表底部留一点高度，避免工具按钮和悬浮按钮重叠
        padding: EdgeInsets.only(bottom: 50),
        itemBuilder: (context, index) {
          final message = displayMessages[index];

          // 如果当前消息是流式消息，说明正在追加显示中，则不显示分支相关内容
          final isStreamingMessage = message.messageId == 'streaming';
          final hasMultipleBranches =
              !isStreamingMessage &&
              branchManager.getBranchCount(allMessages, message) > 1;

          // 使用RepaintBoundary包装每个列表项
          return Column(
            children: [
              // 渲染消息体比较复杂，使用RepaintBoundary包装
              RepaintBoundary(
                child: BranchMessageItem(
                  key: ValueKey(
                    '${message.messageId}_${_colorConfig.hashCode}',
                  ),
                  message: message,
                  onLongPress: isStreaming ? null : showMessageOptions,
                  // 有默认对话背景图、或者有角色自定义背景图，就是有使用背景图
                  isUseBgImage:
                      backgroundImage != null && backgroundImage!.isNotEmpty,
                  // 简洁模式不显示头像
                  isShowAvatar: !isBriefDisplay,
                  character: currentCharacter,
                  colorConfig: _colorConfig,
                ),
              ),
              // 为分支操作添加条件渲染，避免不必要的构建
              if (!isBriefDisplay &&
                  (!isStreamingMessage || hasMultipleBranches))
                // 操作组件渲染不复杂，不使用RepaintBoundary包装
                BranchMessageActions(
                  key: ValueKey('actions_${message.messageId}'),
                  message: message,
                  messages: allMessages,
                  onRegenerate: () => handleResponseRegenerate(message),
                  hasMultipleBranches: hasMultipleBranches,
                  isRegenerating: isStreaming,
                  currentBranchIndex:
                      isStreamingMessage
                          ? 0
                          : branchManager.getBranchIndex(allMessages, message),
                  totalBranches:
                      isStreamingMessage
                          ? 1
                          : branchManager.getBranchCount(allMessages, message),
                  onSwitchBranch: handleSwitchBranch,
                ),
            ],
          );
        },
      ),
    );
  }

  // 构建响应加载
  Widget buildResponseLoading() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text(
              '正在生成回复...',
              style: TextStyle(fontSize: 12, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  /// 长按消息，显示消息选项
  void showMessageOptions(BranchChatMessage message, Offset overlayPosition) {
    // 添加振动反馈
    HapticFeedback.mediumImpact();

    // 只有用户消息可以编辑
    final bool isUser = message.role == CusRole.user.name;
    // 只有AI消息可以重新生成
    final bool isAssistant = message.role == CusRole.assistant.name;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        overlayPosition.dx,
        overlayPosition.dy,
        overlayPosition.dx + 200,
        overlayPosition.dy + 100,
      ),
      items: [
        // 复制按钮
        PopupMenuItem<String>(
          value: 'copy',
          child: buildMenuItemWithIcon(icon: Icons.copy, text: '复制文本'),
        ),
        // 选择文本按钮
        PopupMenuItem<String>(
          value: 'select',
          child: buildMenuItemWithIcon(icon: Icons.text_fields, text: '选择文本'),
        ),
        if (isUser)
          PopupMenuItem<String>(
            value: 'edit',
            child: buildMenuItemWithIcon(icon: Icons.edit, text: '编辑消息'),
          ),
        if (isUser)
          PopupMenuItem<String>(
            value: 'resend',
            child: buildMenuItemWithIcon(icon: Icons.send, text: '重新发送'),
          ),
        if (isAssistant)
          PopupMenuItem<String>(
            value: 'regenerate',
            child: buildMenuItemWithIcon(icon: Icons.refresh, text: '重新生成'),
          ),
        if (isAssistant)
          PopupMenuItem<String>(
            value: 'update_message',
            child: buildMenuItemWithIcon(icon: Icons.edit, text: '修改消息'),
          ),
        PopupMenuItem<String>(
          value: 'delete',
          child: buildMenuItemWithIcon(
            icon: Icons.delete,
            text: '删除分支',
            color: Colors.red,
          ),
        ),
      ],
    ).then((value) async {
      if (value == 'copy') {
        Clipboard.setData(ClipboardData(text: message.content));
        ToastUtils.showToast('已复制到剪贴板');
      } else if (value == 'select') {
        if (!mounted) return;
        showDialog(
          context: context,
          builder:
              (context) => TextSelectionDialog(
                text:
                    message.reasoningContent != null &&
                            message.reasoningContent!.isNotEmpty
                        ? '【推理过程】\n${message.reasoningContent!}\n\n【AI响应】\n${message.content}'
                        : message.content,
              ),
        );
      } else if (value == 'update_message') {
        // 2025-04-22 有时候AI响应的内容不完整或者不对，导致格式化显示时不美观，提供手动修改。
        // 又或者对于AI响应的内容不满意，要手动修改后继续对话。
        // 和修改用户信息不同，这个AI响应的修改不会创建新分支(但感觉修改了AI的响应会不会不严谨了？？？)。
        if (!mounted) return;
        showDialog(
          context: context,
          builder:
              (context) => TextEditDialog(
                text: message.content,
                onSaved: (updatedText) async {
                  var msg = message;
                  msg.content = updatedText;
                  await store.updateMessage(msg);
                  await loadMessages();
                },
              ),
        );
      } else if (value == 'edit') {
        handleUserMessageEdit(message);
      } else if (value == 'resend') {
        handleUserMessageResend(message);
      } else if (value == 'regenerate') {
        handleResponseRegenerate(message);
      } else if (value == 'delete') {
        await handleDeleteBranch(message);
      }
    });
  }

  /// 编辑用户消息
  void handleUserMessageEdit(BranchChatMessage message) {
    setState(() {
      currentEditingMessage = message;
      inputController.text = message.content;
      // 显示键盘
      inputFocusNode.requestFocus();
    });
  }

  // 重新发送用户消息
  void handleUserMessageResend(BranchChatMessage message) {
    setState(() {
      currentEditingMessage = message;
    });
    handleSendMessage(
      MessageData(
        text: message.content,
        audio:
            message.contentVoicePath != null
                ? XFile(message.contentVoicePath!)
                : null,
        images: message.imagesUrl?.split(',').map((img) => XFile(img)).toList(),
      ),
    );
  }

  /// 重新生成AI响应内容
  Future<void> handleResponseRegenerate(BranchChatMessage message) async {
    if (isStreaming) return;

    setState(() {
      regeneratingMessageId = message.id;
      isStreaming = true;
    });

    try {
      final currentMessages = branchManager.getMessagesByBranchPath(
        allMessages,
        message.branchPath,
      );

      final messageIndex = currentMessages.indexOf(message);
      if (messageIndex == -1) return;

      final contextMessages = currentMessages.sublist(0, messageIndex);

      // 判断当前所处的分支路径是否是在修改用户消息后新创建的分支
      // 核心判断逻辑：当前分支路径与要重新生成的消息分支路径的关系
      bool isAfterUserEdit = false;

      // 获取当前分支路径的所有部分
      final List<String> currentPathParts = currentBranchPath.split('/');
      final List<String> messagePathParts = message.branchPath.split('/');

      // 情况1: 当前分支路径比消息路径长，且前缀相同，说明已经在新分支上
      if (currentPathParts.length > messagePathParts.length) {
        bool isPrefixSame = true;
        for (int i = 0; i < messagePathParts.length; i++) {
          if (messagePathParts[i] != currentPathParts[i]) {
            isPrefixSame = false;
            break;
          }
        }

        if (isPrefixSame) {
          // 检查是否是由于用户编辑创建的新分支
          final userMessages =
              allMessages
                  .where(
                    (m) =>
                        m.role == CusRole.user.name &&
                        m.branchPath == currentBranchPath,
                  )
                  .toList();

          isAfterUserEdit = userMessages.isNotEmpty;
        }
      }
      // 情况2: 分支路径不同，但共享相同父路径，检查是否已经切换到不同分支
      else if (!currentBranchPath.startsWith(message.branchPath) &&
          !message.branchPath.startsWith(currentBranchPath)) {
        // 找到最近的共同父路径
        int commonPrefixLength = 0;
        for (
          int i = 0;
          i < min(currentPathParts.length, messagePathParts.length);
          i++
        ) {
          if (currentPathParts[i] == messagePathParts[i]) {
            commonPrefixLength++;
          } else {
            break;
          }
        }

        if (commonPrefixLength > 0) {
          // 如果有共同父路径，判断当前路径是否包含用户消息
          final userMessagesOnCurrentPath =
              allMessages
                  .where(
                    (m) =>
                        m.role == CusRole.user.name &&
                        m.branchPath == currentBranchPath,
                  )
                  .toList();

          isAfterUserEdit = userMessagesOnCurrentPath.isNotEmpty;
        }
      }

      // 获取重新生成位置的同级分支
      final siblings = branchManager.getSiblingBranches(allMessages, message);
      final availableSiblings =
          siblings.where((m) => allMessages.contains(m)).toList()
            ..sort((a, b) => a.branchIndex.compareTo(b.branchIndex));

      // 计算新的分支索引
      int newBranchIndex;
      if (isAfterUserEdit) {
        // 如果是在用户编辑后新创建的分支上，AI响应索引应该从0开始
        newBranchIndex = 0;
      } else {
        // 常规情况下，使用当前同级分支的最大索引+1
        newBranchIndex =
            availableSiblings.isEmpty
                ? 0
                : availableSiblings.last.branchIndex + 1;
      }

      // 构建新的分支路径
      String newPath;
      if (message.parent.target == null) {
        newPath = newBranchIndex.toString();
      } else {
        final parentPath = message.branchPath.substring(
          0,
          message.branchPath.lastIndexOf('/'),
        );
        newPath = '$parentPath/$newBranchIndex';
      }

      await _generateAIResponseCommon(
        contextMessages: contextMessages,
        newBranchPath: newPath,
        newBranchIndex: newBranchIndex,
        depth: message.depth,
        parentMessage: message.parent.target,
      );
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, "异常提示", "重新生成失败: $e");
      setState(() {
        isStreaming = false;
      });
    } finally {
      if (mounted) {
        setState(() => regeneratingMessageId = null);
      }
    }
  }

  /// 添加一个通用的AI响应生成方法(重新生成、正常发送消息都用这个)
  Future<BranchChatMessage?> _generateAIResponseCommon({
    required List<BranchChatMessage> contextMessages,
    required String newBranchPath,
    required int newBranchIndex,
    required int depth,
    BranchChatMessage? parentMessage,
  }) async {
    // 初始化状态
    setState(() {
      isStreaming = true;
      streamingContent = '';
      streamingReasoningContent = '';
      // 创建临时的流式消息
      displayMessages = [
        ...contextMessages,
        BranchChatMessage(
          id: 0,
          messageId: 'streaming',
          role: CusRole.assistant.name,
          content: '',
          createTime: DateTime.now(),
          branchPath: newBranchPath,
          branchIndex: newBranchIndex,
          depth: depth,
        ),
      ];
    });

    String finalContent = '';
    String finalReasoningContent = '';
    var startTime = DateTime.now();
    DateTime? endTime;
    var thinkingDuration = 0;
    BranchChatMessage? aiMessage;
    // 2025-03-24 联网搜索参考内容
    List<Map<String, dynamic>>? references = [];

    try {
      final history = _prepareChatHistory(contextMessages);

      final (stream, cancelFunc) = await ChatService.sendCharacterMessage(
        selectedModel!,
        history,
        advancedOptions: advancedEnabled ? advancedOptions : null,
        stream: true,
      );

      cancelResponse = cancelFunc;

      // 处理流式响应的内容(包括正常完成、手动终止和错误响应)
      await for (final chunk in stream) {
        // 更新流式内容和状态
        setState(() {
          // 2025-03-24 联网搜索参考内容
          if (chunk.searchResults != null) {
            references.addAll(chunk.searchResults!);
          }

          // 1. 更新内容
          // 2025-05-06 实测openRouter的响应中，思考是使用reasoning字段，其他的都是reasoning_content
          // 注意，直接在content中用<think></think>包裹的思考内容没有特殊处理，都当做正文显示了
          streamingContent += chunk.cusText;
          streamingReasoningContent +=
              chunk.choices.isNotEmpty
                  ? (chunk.choices.first.delta?["reasoning_content"] ??
                      chunk.choices.first.delta?["reasoning"] ??
                      '')
                  : '';
          finalContent += chunk.cusText;
          finalReasoningContent +=
              chunk.choices.isNotEmpty
                  ? (chunk.choices.first.delta?["reasoning_content"] ??
                      chunk.choices.first.delta?["reasoning"] ??
                      '')
                  : '';

          // 计算思考时间(从发起调用开始，到当流式内容不为空时计算结束)
          if (endTime == null && streamingContent.isNotEmpty) {
            endTime = DateTime.now();
            thinkingDuration = endTime!.difference(startTime).inMilliseconds;
          }

          // 2. 更新显示消息列表
          displayMessages = [
            ...contextMessages,
            BranchChatMessage(
              id: 0,
              messageId: 'streaming',
              role: CusRole.assistant.name,
              content: streamingContent,
              reasoningContent: streamingReasoningContent,
              thinkingDuration: thinkingDuration,
              references: references,
              createTime: DateTime.now(),
              branchPath: newBranchPath,
              branchIndex: newBranchIndex,
              depth: depth,
            ),
          ];
        });

        // 如果手动停止了流式生成，提前退出循环
        if (!isStreaming) break;

        // 自动滚动逻辑
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final currentHeight = scrollController.position.maxScrollExtent;
          if (!isUserScrolling && currentHeight - lastContentHeight > 20) {
            // 高度增加超过 20 像素
            scrollController.jumpTo(currentHeight);
            lastContentHeight = currentHeight;
          }
        });
      }

      // 如果有内容则创建消息(包括正常完成、手动终止和错误响应[错误响应也是一个正常流消息])
      if (finalContent.isNotEmpty || finalReasoningContent.isNotEmpty) {
        aiMessage = await store.addMessage(
          session: store.sessionBox.get(currentSessionId!)!,
          content: finalContent,
          role: CusRole.assistant.name,
          parent: parentMessage,
          reasoningContent: finalReasoningContent,
          thinkingDuration: thinkingDuration,
          references: references,
          modelLabel: parentMessage?.modelLabel ?? selectedModel!.name,
          branchIndex: newBranchIndex,
          // 2025-04-08 AI响应添加角色信息，可为空
          // 对话记录有，这消息内就不要了，避免重复，数据变多
          // character: currentCharacter,
          // 目前流式响应没有媒体资源，如果有的话，需要在这里添加
        );

        // 更新当前分支路径(其他重置在 finally 块中)
        setState(() => currentBranchPath = aiMessage!.branchPath);
      }

      return aiMessage;
    } catch (e) {
      if (!mounted) return null;
      commonExceptionDialog(context, "异常提示", "AI响应生成失败: $e");

      // 创建错误消息（？？？这个添加消息应该不需要吧）
      final errorContent = """生成失败:\n\n错误信息: $e""";

      aiMessage = await store.addMessage(
        session: store.sessionBox.get(currentSessionId!)!,
        content: errorContent,
        role: CusRole.assistant.name,
        parent: parentMessage,
        thinkingDuration: thinkingDuration,
        modelLabel: parentMessage?.modelLabel ?? selectedModel!.name,
        branchIndex: newBranchIndex,
      );

      return aiMessage;
    } finally {
      if (mounted) {
        setState(() {
          isStreaming = false;
          streamingContent = '';
          streamingReasoningContent = '';
          cancelResponse = null;
        });
        // 在 finally 块中重新加载消息，确保无论是正常完成还是手动终止都会重新加载消息
        await loadMessages();
      }
    }
  }

  /// 删除当前对话消息分支
  Future<void> handleDeleteBranch(BranchChatMessage message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('删除分支'),
            content: const Text('确定要删除这个分支及其所有子分支吗？'),
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
      // 在删除前获取同级分支信息
      final siblings = branchManager.getSiblingBranches(allMessages, message);
      final currentIndex = siblings.indexOf(message);
      final parent = message.parent.target;
      String newPath = "0";

      // 确定删除后要切换到的分支路径
      if (siblings.length > 1) {
        // 如果有其他同级分支，切换到前一个或后一个分支
        final targetIndex = currentIndex > 0 ? currentIndex - 1 : 1;
        final targetMessage = siblings[targetIndex];
        newPath = targetMessage.branchPath;
      } else if (parent != null) {
        // 如果没有其他同级分支，切换到父分支
        newPath = parent.branchPath;
      }

      // 删除分支
      await store.deleteMessageWithBranches(message);

      // 更新当前分支路径并重新加载消息
      setState(() {
        currentBranchPath = newPath;
      });
      await loadMessages();
    }
  }

  /// 切换消息分支
  void handleSwitchBranch(BranchChatMessage message, int newBranchIndex) {
    final availableBranchIndex = branchManager.getNextAvailableBranchIndex(
      allMessages,
      message,
      newBranchIndex,
    );

    // 如果没有可用的分支，不执行切换
    if (availableBranchIndex == -1) return;

    String newPath;
    if (message.parent.target == null) {
      // 如果是根消息，直接使用新的索引作为路径
      newPath = availableBranchIndex.toString();
    } else {
      // 非根消息，计算完整的分支路径
      final parentPath = message.branchPath.substring(
        0,
        message.branchPath.lastIndexOf('/'),
      );
      newPath =
          parentPath.isEmpty
              ? availableBranchIndex.toString()
              : '$parentPath/$availableBranchIndex';
    }

    // 更新当前分支路径并重新加载消息
    setState(() {
      currentBranchPath = newPath;
    });

    // 重新计算当前分支的消息
    final currentMessages = branchManager.getMessagesByBranchPath(
      allMessages,
      newPath,
    );

    // 更新显示的消息列表
    setState(() {
      displayMessages = [
        ...currentMessages,
        if (isStreaming &&
            (streamingContent.isNotEmpty ||
                streamingReasoningContent.isNotEmpty))
          BranchChatMessage(
            id: 0,
            messageId: 'streaming',
            role: CusRole.assistant.name,
            content: streamingContent,
            reasoningContent: streamingReasoningContent,
            createTime: DateTime.now(),
            branchPath: newPath,
            branchIndex:
                currentMessages.isEmpty ? 0 : currentMessages.last.branchIndex,
            depth: currentMessages.isEmpty ? 0 : currentMessages.last.depth,
          ),
      ];
    });

    resetContentHeight();
  }

  ///******************************************* */
  ///
  /// 输入区域的相关方法
  ///
  ///******************************************* */
  // 修改发送消息处理方法
  Future<void> handleSendMessage(MessageData messageData) async {
    if (messageData.text.isEmpty &&
        messageData.images == null &&
        messageData.audio == null &&
        messageData.file == null &&
        messageData.fileContent == null) {
      return;
    }

    if (!mounted) return;
    if (selectedModel == null) {
      commonExceptionDialog(context, "异常提示", "请先选择一个模型");
      return;
    }

    // 准备用户消息内容
    String messageContent = messageData.text.trim();

    // 处理JSON格式响应
    if (advancedEnabled &&
        advancedOptions?["response_format"] == "json_object") {
      messageContent = "$messageContent(请严格按照json格式输出)";
    }

    // 2025-03-22 暂时不支持文档处理，也没有将解析后的文档内容作为参数传递
    // 后续有单独上传文档的需求再更新
    if (messageData.file != null ||
        (messageData.fileContent != null &&
            messageData.fileContent?.trim().isNotEmpty == true)) {
      commonExceptionDialog(context, "异常提示", "暂不支持上传文档，后续有需求再更新");
      return;
    }

    // 【要保留】处理文档内容，检查是否已经在对话中存在相同文档
    // 2025-04-17 目前这个处理只是把手动解析或者智谱开放平台解析后的内容作为消息的参数传递调用API
    // 感觉还是不够完善，所以暂时还是不加入消息
    // 后续有专门支持文件的多模态后，直接传文件再处理
    // if (messageData.fileContent != null &&
    //     messageData.fileContent!.isNotEmpty) {
    //   final fileName =
    //       messageData.cloudFileName != null &&
    //               messageData.cloudFileName!.isNotEmpty
    //           ? messageData.cloudFileName!
    //           : (messageData.file?.name ?? '未命名文档');

    //   // 生成文档内容的特殊标记
    //   final docStartMark = "${DocumentUtils.DOC_START_PREFIX}$fileName]]";

    //   // 检查对话列表中是否已存在此文档
    //   bool docAlreadyExists = false;

    //   // 遍历现有消息查找相同文档
    //   for (var message in displayMessages) {
    //     if (message.content.contains(docStartMark) &&
    //         message.content.contains(DocumentUtils.DOC_END)) {
    //       docAlreadyExists = true;
    //       break;
    //     }
    //   }

    //   // 如果文档不存在于对话中，则添加到当前消息
    //   if (!docAlreadyExists) {
    //     // 包装文档内容
    //     var wrappedContent = '';

    //     if (messageData.cloudFileName != null) {
    //       // 云端文件
    //       wrappedContent = DocumentUtils.wrapDocumentContent(
    //         messageData.fileContent!,
    //         messageData.cloudFileName!,
    //       );
    //     } else if (messageData.file != null) {
    //       // 本地文件
    //       wrappedContent = DocumentUtils.wrapDocumentContent(
    //         messageData.fileContent!,
    //         messageData.file!.name,
    //       );
    //     }

    //     // 如果用户消息非空，添加换行再附加文档内容
    //     if (messageContent.isNotEmpty) {
    //       messageContent = "$messageContent\n\n$wrappedContent";
    //     } else {
    //       messageContent = wrappedContent;
    //     }
    //   }
    // }

    // // 如果消息为空（没有文本且没有添加文档内容），则不处理
    // if (messageContent.isEmpty) {
    //   return;
    // }

    var content = messageContent;

    try {
      // 如果是新的分支对话，在用户发送消息时才创建记录；
      // 如果是角色对话新开对话，可能需要在点击新对话时就要创建记录，因为有可能预设首条消息
      if (isBranchNewChat) {
        final title = content.length > 20 ? content.substring(0, 20) : content;

        final session = await store.createSession(
          title,
          llmSpec: selectedModel!,
          modelType: selectedType,
        );
        setState(() {
          currentSessionId = session.id;
          isBranchNewChat = false;
        });
      }

      // 如果是编译用户输入过的消息，会和直接发送消息有一些区别
      if (currentEditingMessage != null) {
        await _processingUserMessage(currentEditingMessage!, messageData);
      } else {
        await store.addMessage(
          session: store.sessionBox.get(currentSessionId!)!,
          content: content,
          role: CusRole.user.name,
          parent: displayMessages.isEmpty ? null : displayMessages.last,
          // ???添加媒体文件的存储(有更多类型时就继续处理)
          contentVoicePath: messageData.audio?.path,
          imagesUrl:
              messageData.images?.isNotEmpty == true
                  ? messageData.images?.map((i) => i.path).toList().join(',')
                  : null,
          videosUrl:
              messageData.videos?.isNotEmpty == true
                  ? messageData.videos?.map((i) => i.path).toList().join(',')
                  : null,
        );
      }

      // 不管是重新编辑还是直接发送，都有这些步骤
      inputController.clear();
      await loadMessages();
      await _generateAIResponse();

      loadSessions();
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, "异常提示", "发送消息失败: $e");
    }
  }

  // 处理重新编辑的用户消息(在发送消息调用API前，还需要创建分支等其他操作)
  Future<void> _processingUserMessage(
    BranchChatMessage message,
    MessageData messageData,
  ) async {
    final content = messageData.text.trim();
    if (content.isEmpty) return;

    try {
      // 获取当前分支的所有消息
      final currentMessages = branchManager.getMessagesByBranchPath(
        allMessages,
        currentBranchPath,
      );

      // 找到要编辑的消息在当前分支中的位置
      final messageIndex = currentMessages.indexOf(message);
      if (messageIndex == -1) {
        debugPrint("警告：找不到要编辑的消息在当前分支中的位置");
        return;
      }

      // 获取同级分支
      final siblings = branchManager.getSiblingBranches(allMessages, message);

      // 创建新分支索引
      final newBranchIndex =
          siblings.isEmpty ? 0 : siblings.last.branchIndex + 1;

      // 构建新的分支路径
      String newPath;
      if (message.parent.target == null) {
        // 根消息
        newPath = newBranchIndex.toString();
      } else {
        // 子消息
        final parentPath = message.branchPath.substring(
          0,
          message.branchPath.lastIndexOf('/'),
        );
        newPath = '$parentPath/$newBranchIndex';
      }

      // 创建新的用户消息
      await store.addMessage(
        session: store.sessionBox.get(currentSessionId!)!,
        content: content,
        role: CusRole.user.name,
        parent: message.parent.target,
        branchIndex: newBranchIndex,
        // ???添加媒体文件的存储(有更多类型时就继续处理)
        contentVoicePath: message.contentVoicePath,
        imagesUrl: message.imagesUrl,
        videosUrl: message.videosUrl,
      );

      // 更新当前分支路径并将正在编辑的消息设置为null
      setState(() {
        currentBranchPath = newPath;
        currentEditingMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, "异常提示", "编辑消息失败: $e");
    }
  }

  // 修改 _generateAIResponse 方法
  Future<void> _generateAIResponse() async {
    final currentMessages = branchManager.getMessagesByBranchPath(
      allMessages,
      currentBranchPath,
    );

    if (currentMessages.isEmpty) {
      pl.e('当前分支路径没有消息: $currentBranchPath');
      return;
    }

    // 获取最后一条消息
    final lastMessage = currentMessages.last;

    // 判断分支状态：三种主要情况
    // 1. 全新对话中的第一个用户消息
    // 2. 常规对话中继续发消息
    // 3. 修改用户消息后创建的新分支

    bool isFirstMessage = currentMessages.length == 1;
    bool isUserEditedBranch = false;

    // 如果是用户消息，检查是否是由于编辑创建的新分支
    if (lastMessage.role == CusRole.user.name) {
      // 获取同级的其他用户消息分支
      final siblings = branchManager.getSiblingBranches(
        allMessages,
        lastMessage,
      );

      // 如果有多个同级用户消息，说明是编辑后创建的分支
      isUserEditedBranch = siblings.length > 1 || lastMessage.branchIndex > 0;
    }

    // 确定AI响应的分支索引
    int branchIndex;

    if (lastMessage.role == CusRole.user.name &&
        (isFirstMessage || isUserEditedBranch)) {
      // 如果是首条用户消息或编辑用户消息后创建的分支，AI响应索引应为0
      branchIndex = 0;
    } else {
      // 在常规对话中，使用最后一条消息的索引
      branchIndex = lastMessage.branchIndex;
    }

    await _generateAIResponseCommon(
      contextMessages: currentMessages,
      newBranchPath: currentBranchPath,
      newBranchIndex: branchIndex,
      depth: lastMessage.depth,
      parentMessage: lastMessage,
    );
  }

  // 取消编辑已发送的用户消息
  void handleCancelEditUserMessage() {
    setState(() {
      currentEditingMessage = null;
      inputController.clear();
      // 收起键盘
      inputFocusNode.unfocus();
    });
  }

  /// 停止流式生成(用户主动停止)
  void handleStopStreaming() {
    setState(() => isStreaming = false);
    cancelResponse?.call();
    cancelResponse = null;
  }

  ///******************************************* */
  ///
  /// 消息列表底部的新加对话和滚动到底部的悬浮按钮
  ///
  ///******************************************* */
  Widget buildFloatingButton() {
    return Positioned(
      left: 0,
      right: 0,
      // 悬浮按钮有设定上下间距，根据其他组件布局适当调整位置
      bottom: isStreaming ? inputHeight + 5 : inputHeight - 5,
      child: Container(
        // 新版本输入框为了更多输入内容，左右边距为0
        padding: EdgeInsets.symmetric(horizontal: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 图标按钮的默认尺寸是48*48,占位宽度默认48
            SizedBox(width: 48),
            if (displayMessages.isNotEmpty && !isStreaming)
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
                      // elevation: 0,
                      // 按钮的尺寸
                      // minimumSize: Size(52, 28),
                      // 按钮的圆角
                      // shape: RoundedRectangleBorder(
                      //   borderRadius: BorderRadius.circular(14),
                      // ),
                    ),
                    onPressed: () {
                      if (currentCharacter != null) {
                        // 不是新的分支对话(即新的角色对话)
                        createNewChat(isNewBranch: false);
                      } else {
                        createNewChat();
                      }
                    },
                    child: Text(
                      '开启新对话',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ),
              ),
            if (showScrollToBottom)
              // 按钮图标变小，但为了和下方的发送按钮对齐，所以补足占位宽度
              IconButton(
                iconSize: 24,
                icon: Icon(Icons.arrow_circle_down_outlined),
                onPressed: resetContentHeight,
              ),
            // 2025-04-11？？？这个桌面的不设小一点显示滚动到底部按钮后新开对话按钮位置会变化
            if (!showScrollToBottom)
              SizedBox(width: ScreenHelper.isDesktop() ? 40 : 48),
          ],
        ),
      ),
    );
  }

  // 构建背景
  Widget buildBackground() {
    if (backgroundImage == null || backgroundImage!.trim().isEmpty) {
      return Container(color: Colors.transparent);
    }

    return Positioned.fill(
      child: Opacity(
        opacity: backgroundOpacity,
        child: buildNetworkOrFileImage(backgroundImage!, fit: BoxFit.cover),
        // child: buildCusImage(bgImage, fit: BoxFit.cover),
      ),
    );
  }

  ///******************************************* */
  ///
  /// 其他相关方法
  ///
  ///******************************************* */
  // 重置对话列表内容高度(在点击了重新生成、切换了模型、点击了指定历史记录后都应该调用)
  void resetContentHeight({int? times}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollController.hasClients) return;

      lastContentHeight = scrollController.position.maxScrollExtent;
    });

    // 重置完了顺便滚动到底部
    _scrollToBottom(times: times);
  }

  // 滚动到底部
  Future<void> _scrollToBottom({int? times}) async {
    if (!mounted) return;

    await Future.delayed(Duration.zero);
    if (!mounted || !scrollController.hasClients) return;

    final position = scrollController.position;
    if (!position.hasContentDimensions ||
        position.maxScrollExtent <= position.minScrollExtent) {
      return;
    }

    await scrollController.animateTo(
      position.maxScrollExtent,
      duration: Duration(milliseconds: times ?? 500),
      curve: Curves.easeOut,
    );

    if (mounted) setState(() => isUserScrolling = false);
  }

  // 发送角色首次消息
  Future<void> _sendCharacterFirstMessage(BranchChatSession session) async {
    if (currentCharacter == null || currentCharacter!.firstMessage.isEmpty) {
      return;
    }

    try {
      final message = await store.addMessage(
        session: session,
        content: currentCharacter!.firstMessage,
        role: 'assistant',
        character: currentCharacter,
      );

      // 更新消息列表
      setState(() {
        allMessages = [message];
        displayMessages = [message];
      });

      // 滚动到底部
      resetContentHeight();
    } catch (e) {
      ToastUtils.showError('发送角色首次消息失败: $e');
    }
  }

  // 添加对角色使用的支持到现有方法中
  // 2025-04-07 默认如果有角色开启新对话也使用该角色的新对话，但如果是右上角点击新建对话，则是默认智能助手而非角色对话
  ///
  /// 2025-04-15 重新整理一下新建对话的逻辑：
  /// 除了当前有角色且点击底部的"开启新对话"按钮会对角色使用新对话，
  ///     初始化的时候：从角色列表点击进来的
  /// 其他切换了模型类型、右上角新开对话，都重置当前角色为空，进行默认的分支对话
  /// 其他点击历史记录时继续记录的角色或者分支对话；如果该记录的模型或者角色被删除，默认新增的也是分支对话
  ///
  /// 角色对话需要在用户发送消息前就创建session，更新显示消息列表(因为可能存在预设的首条消息)
  /// 而分支对话在用户发送后才创建session，才更新消息列表(没有首条消息，可以显示其他内容)
  Future<void> createNewChat({bool? isNewBranch = true}) async {
    // 无法选择模型时使用默认模型
    if (modelList.isEmpty || selectedModel == null) {
      ToastUtils.showError('请先配置模型');
      return;
    }

    setState(() {
      isLoading = true;
      isBranchNewChat = true;
      displayMessages = [];
      allMessages = [];
      currentBranchPath = "0";
      currentEditingMessage = null;
      isStreaming = false;
      streamingMessage = null;
      streamingContent = '';
      streamingReasoningContent = '';
    });

    // 清理缓存
    inputController.clear();
    CusMarkdownRenderer.instance.clearCache();

    // 如果是全新的分支对话，则不是角色对话，那么就是在用户发送时才构建对话记录，这里单纯设定新对话标记即可
    if (isNewBranch == true) {
      setState(() {
        currentCharacter = null;
        isLoading = false;
        // 开启新对话后，没有对话列表，所以不显示滚动到底部按钮
        showScrollToBottom = false;
      });

      loadBackgroundSettings();

      return;
    }

    // 如果是新的角色对话，则要在用户发送消息前就创建新会话
    // 2025-04-16 目前仅在角色对话过程中，点击下方"开启新对话"时才触发
    try {
      final sessionTitle =
          currentCharacter != null ? "与${currentCharacter!.name}的对话" : "新的角色对话";

      // 2025-04-07 避免用户一直创建新对话，导致存在大量每个对话只有1个角色预设消息的问题
      // 这里如果对话中指定角色的消息只有1条且角色为该消息角色为assistant，则删除这些对话
      final sessions =
          store.sessionBox
              .getAll()
              .where(
                (e) =>
                    e.characterId == currentCharacter?.characterId &&
                    e.messages.length <= 1 &&
                    (e.messages.isNotEmpty &&
                        e.messages.first.role == CusRole.assistant.name),
              )
              .toList();
      for (final s in sessions) {
        await store.deleteSession(s);
      }

      final session = await store.createSession(
        sessionTitle,
        llmSpec: currentCharacter?.preferredModel ?? selectedModel!,
        modelType: selectedType,
        character: currentCharacter, // 添加角色参数
      );

      // 如果是角色对话，且有首次消息，自动发送一条AI消息
      if (currentCharacter != null &&
          currentCharacter!.firstMessage.isNotEmpty) {
        // 创建AI的首次消息
        await _sendCharacterFirstMessage(session);
      }

      setState(() {
        currentSessionId = session.id;
        isLoading = false;
        isBranchNewChat = false;
      });

      // 开启新对话后，没有对话列表，所以不显示滚动到底部按钮
      showScrollToBottom = false;

      loadBackgroundSettings();

      // 创建新对话后，重置内容高度
      resetContentHeight();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ToastUtils.showError('创建会话失败: $e');
    }
  }

  /// 准备聊天历史(用于构建调用大模型API的请求参数)
  List<Map<String, dynamic>> _prepareChatHistory(
    List<BranchChatMessage> messages,
  ) {
    final history = <Map<String, dynamic>>[];

    // 添加系统提示词
    if (currentCharacter != null) {
      history.add({
        'role': CusRole.system.name,
        'content': currentCharacter?.generateSystemPrompt(),
      });
    }

    // 添加聊天历史
    for (var message in messages) {
      // 跳过空消息
      if (message.content.isEmpty &&
          message.imagesUrl == null &&
          message.contentVoicePath == null) {
        continue;
      }

      if (message.role == CusRole.user.name) {
        // 处理用户消息，可能包含多模态内容
        // if ((message.imagesUrl != null && message.imagesUrl!.isNotEmpty) ||
        //     (message.contentVoicePath != null &&
        //         message.contentVoicePath!.isNotEmpty)) {

        // 2025-03-18 语音消息暂时不使用
        if ((message.imagesUrl != null && message.imagesUrl!.isNotEmpty)) {
          // 多模态消息
          final contentList = <Map<String, dynamic>>[];

          // 添加文本内容
          if (message.content.isNotEmpty) {
            contentList.add({'type': 'text', 'text': message.content});
          }

          // 处理图片
          if (message.imagesUrl != null && message.imagesUrl!.isNotEmpty) {
            final imageUrls = message.imagesUrl!.split(',');
            for (final url in imageUrls) {
              try {
                final bytes = File(url.trim()).readAsBytesSync();
                final base64Image = base64Encode(bytes);
                contentList.add({
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
                });
              } catch (e) {
                commonExceptionDialog(context, '处理图片失败', '处理图片失败: $e');
              }
            }
          }

          // // 处理语音
          // 2025-03-18 语音消息暂时不使用
          // if (message.contentVoicePath != null &&
          //     message.contentVoicePath!.isNotEmpty) {
          //   try {
          //     final bytes = File(message.contentVoicePath!).readAsBytesSync();
          //     final base64Audio = base64Encode(bytes);
          //     contentList.add({
          //       'type': 'audio_url',
          //       'audio_url': {'url': 'data:audio/mp3;base64,$base64Audio'}
          //     });
          //   } catch (e) {
          //     print('处理音频失败: $e');
          //   }
          // }

          history.add({'role': CusRole.user.name, 'content': contentList});
        } else {
          // 纯文本消息
          history.add({'role': CusRole.user.name, 'content': message.content});
        }
      } else if (message.role == CusRole.assistant.name &&
          message.characterId == currentCharacter?.characterId) {
        // AI助手的回复通常是纯文本
        history.add({
          'role': CusRole.assistant.name,
          'content': message.content,
        });
      }
    }

    return history;
  }

  // 桌面端右侧功能按钮面板
  Widget buildDesktopRightSidebarPanel() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 新建对话
          buildIconWithTextButton(
            icon: Icons.add,
            label: '新建对话',
            onTap: !isStreaming ? createNewChat : null,
            context: context,
          ),
          // 高级选项
          buildIconWithTextButton(
            icon: Icons.settings_suggest,
            label: '高级选项',
            onTap: !isStreaming ? showAdvancedOptions : null,
            context: context,
          ),
          // 调整文本大小
          buildIconWithTextButton(
            icon: Icons.format_size,
            label: '字体大小',
            onTap:
                !isStreaming
                    ? () => adjustTextScale(context, textScaleFactor, (
                      value,
                    ) async {
                      setState(() => textScaleFactor = value);
                      await MyGetStorage().setChatMessageTextScale(value);
                      if (!mounted) return;
                      Navigator.of(context).pop();
                    })
                    : null,
            context: context,
          ),
          // 切换简洁模式
          buildIconWithTextButton(
            icon: isBriefDisplay ? Icons.details : Icons.visibility_outlined,
            label: isBriefDisplay ? '详细显示' : '简洁显示',
            onTap:
                !isStreaming
                    ? () => setState(() => isBriefDisplay = !isBriefDisplay)
                    : null,
            context: context,
          ),
          // 切换背景图片
          buildIconWithTextButton(
            icon: Icons.wallpaper,
            label: '更换背景',
            onTap: !isStreaming ? changeBackground : null,
            context: context,
          ),
          // 显示分支树
          buildIconWithTextButton(
            icon: Icons.account_tree,
            label: '对话分支',
            onTap: !isStreaming && !isBranchNewChat ? showBranchTree : null,
            context: context,
          ),
          // 添加模型
          buildIconWithTextButton(
            icon: Icons.add_box_outlined,
            label: '添加模型',
            onTap: !isStreaming ? handleAddModel : null,
            context: context,
          ),
          // 导入导出
          buildIconWithTextButton(
            icon: Icons.import_export,
            label: '导入导出',
            onTap: !isStreaming ? navigateToExportImportPage : null,
            context: context,
          ),
        ],
      ),
    );
  }
}
