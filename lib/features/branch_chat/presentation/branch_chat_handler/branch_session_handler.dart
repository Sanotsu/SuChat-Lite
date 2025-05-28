import '../../../../../shared/widgets/markdown_render/cus_markdown_renderer.dart';
import '../../../../../shared/widgets/toast_utils.dart';
import '../../../../shared/constants/constants.dart';
import '../../domain/entities/branch_chat_session.dart';
import '../branch_chat_state/branch_chat_state.dart';
import '../viewmodels/character_store.dart';
import 'init_handler.dart';
import 'branch_message_handler.dart';
import 'scroll_handler.dart';

/// 聊天会话相关的逻辑
///
/// 1 创建新对话
/// 2 切换对话分支
///
class BranchSessionHandler {
  final BranchChatState state;
  final Function setState;

  BranchSessionHandler(this.state, this.setState);

  /// 创建新聊天
  /// [isNewBranch] 是否是新的分支对话，如果是false则为角色对话
  /// 2025-04-15 重新整理一下新建对话的逻辑：
  /// 除了当前有角色且点击底部的"开启新对话"按钮会对角色使用新对话，
  ///     从角色列表点击进来的,除非全新角色，否则也会找该角色最后一条对话记录
  /// 其他切换了模型类型、右上角新开对话，都重置当前角色为空，进行默认的分支对话
  /// 其他点击历史记录时继续记录的角色或者分支对话；如果该记录的模型或者角色被删除，默认新增的也是分支对话
  ///
  /// 角色对话需要在用户发送消息前就创建session，更新显示消息列表(因为可能存在预设的首条消息)
  /// 而分支对话在用户发送后才创建session，才更新消息列表(没有首条消息，可以显示其他内容)
  Future<void> createNewChat({bool? isNewBranch = true}) async {
    // 无法选择模型时使用默认模型
    if (state.modelList.isEmpty || state.selectedModel == null) {
      ToastUtils.showError('请先配置模型');
      return;
    }

    setState(() {
      state.isLoading = true;
      state.isBranchNewChat = true;
      state.displayMessages = [];
      state.allMessages = [];
      state.currentBranchPath = "0";
      state.currentEditingMessage = null;
      state.isStreaming = false;
      state.streamingMessage = null;
      state.streamingContent = '';
      state.streamingReasoningContent = '';
    });

    // 清理缓存
    state.inputController.clear();
    CusMarkdownRenderer.instance.clearCache();

    // 如果是全新的分支对话，则不是角色对话，那么就是在用户发送时才构建对话记录，这里单纯设定新对话标记即可
    if (isNewBranch == true) {
      setState(() {
        state.currentCharacter = null;
        state.isLoading = false;
        // 开启新对话后，没有对话列表，所以不显示滚动到底部按钮
        state.showScrollToBottom = false;
      });

      InitHandler(state, setState).loadBackgroundSettings();

      return;
    }

    // 如果是新的角色对话，则要在用户发送消息前就创建新会话
    // 目前仅在角色对话过程中，点击下方"开启新对话"时才触发全新角色对话
    try {
      final sessionTitle =
          state.currentCharacter != null
              ? "与${state.currentCharacter!.name}的对话"
              : "新的角色对话";

      // 避免用户一直创建新对话，导致存在大量每个对话只有1个角色预设消息的问题
      // 这里如果对话中指定角色的消息只有1条且角色为该消息角色为assistant，则删除这些对话
      final sessions =
          state.store.sessionBox
              .getAll()
              .where(
                (e) =>
                    e.characterId == state.currentCharacter?.characterId &&
                    e.messages.length <= 1 &&
                    (e.messages.isNotEmpty &&
                        e.messages.first.role == CusRole.assistant.name),
              )
              .toList();
      for (final s in sessions) {
        await state.store.deleteSession(s);
      }

      final session = await state.store.createSession(
        sessionTitle,
        llmSpec: state.currentCharacter?.preferredModel ?? state.selectedModel!,
        modelType: state.selectedType,
        character: state.currentCharacter, // 添加角色参数
      );

      // 如果是角色对话，且有首次消息，自动发送一条AI消息
      if (state.currentCharacter != null &&
          state.currentCharacter!.firstMessage.isNotEmpty) {
        // 创建AI的首次消息
        await _sendCharacterFirstMessage(session);
      }

      setState(() {
        state.currentSessionId = session.id;
        state.isLoading = false;
        state.isBranchNewChat = false;
      });

      // 开启新对话后，没有对话列表，所以不显示滚动到底部按钮
      state.showScrollToBottom = false;

      InitHandler(state, setState).loadBackgroundSettings();

      // 创建新对话后，重置内容高度
      ScrollHandler(state, setState).resetContentHeight();
    } catch (e) {
      setState(() {
        state.isLoading = false;
      });
      ToastUtils.showError('创建会话失败: $e');
    }
  }

  // 发送角色首次消息
  Future<void> _sendCharacterFirstMessage(BranchChatSession session) async {
    if (state.currentCharacter == null ||
        state.currentCharacter!.firstMessage.isEmpty) {
      return;
    }

    try {
      final message = await state.store.addMessage(
        session: session,
        content: state.currentCharacter!.firstMessage,
        role: 'assistant',
        character: state.currentCharacter,
      );

      // 更新消息列表
      setState(() {
        state.allMessages = [message];
        state.displayMessages = [message];
      });

      // 滚动到底部
      ScrollHandler(state, setState).resetContentHeight();
    } catch (e) {
      ToastUtils.showError('发送角色首次消息失败: $e');
    }
  }

  /// 切换历史对话(在抽屉中点选了不同的历史记录)
  Future<void> switchSession(int sessionId) async {
    // 无法选择模型时使用默认模型
    void useDefaultModel(String hintKeyWord) {
      ToastUtils.showInfo(
        '该历史对话【$hintKeyWord】，将使用默认模型构建全新对话。',
        duration: const Duration(seconds: 3),
      );

      setState(() {
        state.selectedModel = state.modelList.first;
        state.selectedType = state.selectedModel!.modelType;
        state.isLoading = false;
      });

      createNewChat();
    }

    if (state.isLoading) return;

    setState(() {
      state.isLoading = true;
    });

    final session = state.store.sessionBox.get(sessionId);

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
      state.selectedModel =
          state.modelList
              .where((m) => m.cusLlmSpecId == session.llmSpec.cusLlmSpecId)
              .firstOrNull;
    });

    if (state.selectedModel == null) {
      setState(() {
        state.currentSessionId = null;
      });

      useDefaultModel('所用模型已被删除');
      return;
    }

    // 到这里了就是正常有记录、有模型或者有角色的对话，正常处理
    setState(() {
      state.currentSessionId = sessionId;
      state.isBranchNewChat = false;
      state.currentBranchPath = "0";
      state.isStreaming = false;
      state.streamingContent = '';
      state.streamingReasoningContent = '';
      state.currentEditingMessage = null;
      state.inputController.clear();
    });

    // 更新当前选中的模型和类型
    setState(() {
      state.selectedType = state.selectedModel!.modelType;
      state.currentCharacter = session.character;
    });
    await BranchMessageHandler(state, setState).loadMessages();

    InitHandler(state, setState).loadBackgroundSettings();

    ScrollHandler(state, setState).resetContentHeight();

    // 创建新对话等内部会有，所以这里就最后恢复加载状态即可
    setState(() {
      state.isLoading = false;
    });
  }
}
