import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../../../../core/storage/cus_get_storage.dart';
import '../../../../../shared/services/model_manager_service.dart';
import '../../../../../shared/widgets/markdown_render/cus_markdown_renderer.dart';
import '../../../../../shared/widgets/toast_utils.dart';
import '../../../../shared/constants/constant_llm_enum.dart';
import '../../domain/entities/branch_chat_message.dart';
import '../../domain/entities/branch_chat_session.dart';
import '../branch_chat_state/branch_chat_state.dart';
import '../viewmodels/branch_store.dart';
import 'branch_message_handler.dart';
import 'scroll_handler.dart';
import 'branch_session_handler.dart';

/// 初始化处理器，包含与初始化相关的方法
///
/// 1 初始化分支存储器
/// 2 加载对话历史
/// 3 监听对话消息滚动事件
/// 4 分支对话页面的整体初始化
/// 5 加载可用模型列表
/// 6 加载背景设置
/// 7 重新应用消息字体颜色配置
///
class InitHandler {
  final BranchChatState state;
  final Function setState;

  InitHandler(this.state, this.setState);

  /// 初始化分支存储器
  Future<void> initStore() async {
    state.store = await BranchStore.create();

    // 初始化时加载会话列表
    loadSessions();
  }

  /// 加载历史对话列表并按更新时间排序
  List<BranchChatSession> loadSessions() {
    var list = state.store.sessionBox.getAll()
      ..sort((a, b) => b.updateTime.compareTo(a.updateTime));

    setState(() => state.sessionList = list);

    return list;
  }

  /// 监听滚动事件
  void setupScrollListener() {
    state.scrollController.addListener(() {
      // 判断用户是否正在手动滚动
      if (state.scrollController.position.userScrollDirection ==
              ScrollDirection.reverse ||
          state.scrollController.position.userScrollDirection ==
              ScrollDirection.forward) {
        state.isUserScrolling = true;
      } else {
        state.isUserScrolling = false;
      }

      // 判断是否显示"滚动到底部"按钮
      setState(() {
        state.showScrollToBottom =
            state.scrollController.offset <
            state.scrollController.position.maxScrollExtent - 50;
      });
    });
  }

  /// 初始化方法(初始化模型列表、最新会话)
  Future<void> initialize() async {
    try {
      // 初始化消息体颜色
      await _loadColorConfig();

      // 初始化模型列表
      await initModels();

      // 初始化会话
      await initSession();

      // // 如果初始化时有角色，默认简洁显示
      // if (state.currentCharacter != null) {
      //   setState(() => state.isBriefDisplay = true);
      // }

      // 加载背景图片设置
      loadBackgroundSettings();
    } finally {
      setState(() => state.isLoading = false);
    }
  }

  Future<void> _loadColorConfig() async {
    final config = await CusGetStorage().loadMessageFontColor();

    setState(() {
      state.colorConfig = config;
    });
  }

  Future<void> initModels() async {
    // 获取可用模型列表
    final availableModels = await ModelManagerService.getAvailableModelByTypes([
      LLModelType.cc,
      LLModelType.vision,
      LLModelType.reasoner,
      LLModelType.vision_reasoner,
      LLModelType.omni,
    ]);

    setState(() {
      state.modelList = availableModels;
      state.selectedModel = availableModels.isNotEmpty
          ? availableModels.first
          : null;
      state.selectedType = state.selectedModel?.modelType ?? LLModelType.cc;
    });
  }

  /// 初始化会话
  Future<void> initSession() async {
    // 根据是否有使用角色获取所有的会话记录
    var sessions = state.currentCharacter != null
        ? _filterCharacterSessions()
        : _getSortedSessions();

    // 如果没有任何对话记录，则标记创建新对话
    if (sessions.isEmpty) {
      setState(() {
        state.isBranchNewChat = true;
        state.isLoading = false;
      });

      // 2025-04-07 如果没有对话记录，但是有选择当前角色，直接创建新角色对话
      // 如果没有对话记录，也没有角色，上面设置了 isBranchNewChat 标记，直接返回即可
      if (state.currentCharacter != null) {
        await _handleModelSelectionAndChatCreation(null);
        // 不是新的分支对话(即新的角色对话)
        await BranchSessionHandler(
          state,
          setState,
        ).createNewChat(isNewBranch: false);
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
        state.currentSessionId = todayLastSession.id;

        // 如果当天最后一条是角色对话，则更新角色
        if (todayLastSession.character != null) {
          state.currentCharacter = todayLastSession.character;
        }
      });

      await _handleModelSelectionAndChatCreation(todayLastSession);
    } catch (e) {
      // 如果没有任何对话记录，或者今天没有对话记录(会报错抛到这里)，显示新对话界面
      setState(() {
        state.isBranchNewChat = true;
        state.isLoading = false;
      });
    }

    // 延迟执行滚动到底部，确保UI已完全渲染
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScrollHandler(state, setState).resetContentHeight(times: 2000);
    });
  }

  /// 过滤指定角色排序后的会话
  List<BranchChatSession> _filterCharacterSessions() {
    return state.store.sessionBox
        .getAll()
        .toList()
        .where((e) => e.characterId == state.currentCharacter!.characterId)
        .toList()
      ..sort((a, b) => b.updateTime.compareTo(a.updateTime));
  }

  /// 获取所有排序后的会话
  List<BranchChatSession> _getSortedSessions() {
    return state.store.sessionBox.getAll().toList()
      ..sort((a, b) => b.updateTime.compareTo(a.updateTime));
  }

  /// 处理模型选择和对话创建
  Future<void> _handleModelSelectionAndChatCreation(
    BranchChatSession? session,
  ) async {
    // 当前使用模型，如果有当前角色则使用角色模型；如果有当前会话则使用会话模型
    final cusLlmSpecId =
        state.currentCharacter?.preferredModel?.cusLlmSpecId ??
        session?.llmSpec.cusLlmSpecId;

    // 根据cusLlmSpecId获取模型
    state.selectedModel = state.modelList
        .where((m) => m.cusLlmSpecId == cusLlmSpecId)
        .firstOrNull;

    // 如果模型不存在，则使用默认模型
    if (state.selectedModel == null) {
      ToastUtils.showInfo(
        '最新对话所用模型已被删除，将使用默认模型构建全新对话。',
        duration: const Duration(seconds: 5),
      );
      setState(() {
        state.selectedModel = state.modelList.isNotEmpty
            ? state.modelList.first
            : null;
        state.selectedType = state.selectedModel?.modelType ?? LLModelType.cc;
      });
      await BranchSessionHandler(state, setState).createNewChat();
    } else {
      // 如果模型存在，则更新UI
      setState(() {
        state.selectedType = state.selectedModel!.modelType;
        state.isBranchNewChat = false;
        state.isLoading = false;
      });
      // 如果当前会话存在，则加载消息
      if (session != null) {
        await BranchMessageHandler(state, setState).loadMessages();
      }
    }
  }

  /// 加载背景设置
  Future<void> loadBackgroundSettings() async {
    // 从角色加载背景设置（如果有角色）
    if (state.currentCharacter != null &&
        state.currentCharacter!.background != null) {
      setState(() {
        state.backgroundImage = state.currentCharacter!.background;
        state.backgroundOpacity =
            state.currentCharacter!.backgroundOpacity ?? 0.35;
      });
    } else {
      // 从本地存储加载背景图片设置
      final background = await state.storage.getBranchChatBackground();
      final opacity = await state.storage.getBranchChatBackgroundOpacity();

      // 只有当值不同时才更新UI
      if (background != state.backgroundImage ||
          opacity != state.backgroundOpacity) {
        setState(() {
          state.backgroundImage = background;
          state.backgroundOpacity = opacity ?? 0.2;
        });
      }
    }
  }

  /// 重新应用消息颜色配置
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
      final tempMessages = List<BranchChatMessage>.from(state.displayMessages);
      state.displayMessages = [];

      // 延迟一帧再恢复消息列表，确保UI完全刷新
      Future.microtask(() {
        setState(() {
          state.displayMessages = tempMessages;
        });
        // 恢复滚动位置
        ScrollHandler(state, setState).resetContentHeight();
      });
    });
  }
}
