import 'package:flutter/material.dart';

import '../../../../core/utils/simple_tools.dart';
import '../../../../shared/constants/constants.dart';
import '../../domain/entities/branch_chat_message.dart';
import '../../domain/entities/input_message_data.dart';
import '../branch_chat_state/branch_chat_state.dart';
import 'init_handler.dart';
import 'scroll_handler.dart';
import 'ai_response_handler.dart';

/// 消息处理器，用于处理消息相关的逻辑
/// 
/// 1 加载对话所有消息
/// 2 用户发送消息
/// 
class BranchMessageHandler {
  final BranchChatState state;
  final Function setState;

  BranchMessageHandler(this.state, this.setState);

  /// 加载消息
  Future<void> loadMessages() async {
    if (state.currentSessionId == null) {
      setState(() => state.isBranchNewChat = true);
      return;
    }

    setState(() => state.isLoading = true);

    try {
      final messages = state.store.getSessionMessages(state.currentSessionId!);
      if (messages.isEmpty) {
        setState(() {
          state.isBranchNewChat = true;
          state.isLoading = false;
          state.displayMessages.clear();
        });
        return;
      }

      final currentMessages = state.branchManager.getMessagesByBranchPath(
        messages,
        state.currentBranchPath,
      );

      setState(() {
        state.allMessages = messages;
        state.displayMessages = [
          ...currentMessages,
          if (state.isStreaming &&
              (state.streamingContent.isNotEmpty ||
                  state.streamingReasoningContent.isNotEmpty))
            BranchChatMessage(
              id: 0,
              messageId: 'streaming',
              role: CusRole.assistant.name,
              content: state.streamingContent,
              reasoningContent: state.streamingReasoningContent,
              createTime: DateTime.now(),
              branchPath: state.currentBranchPath,
              branchIndex:
                  currentMessages.isEmpty
                      ? 0
                      : currentMessages.last.branchIndex,
              depth: currentMessages.isEmpty ? 0 : currentMessages.last.depth,
            ),
        ];
        state.isLoading = false;
      });
    } catch (e) {
      pl.e('加载消息失败: $e');
      setState(() {
        state.isBranchNewChat = true;
        state.isLoading = false;
      });
    }

    ScrollHandler(state, setState).resetContentHeight();
  }

  /// 处理发送消息
  Future<void> handleSendMessage(InputMessageData messageData) async {
    if (messageData.text.isEmpty &&
        messageData.images == null &&
        messageData.audio == null &&
        messageData.file == null &&
        messageData.fileContent == null) {
      return;
    }

    if (state.selectedModel == null) {
      _showErrorDialog("请先选择一个模型");
      return;
    }

    // 准备用户消息内容
    String messageContent = messageData.text.trim();

    // 处理JSON格式响应
    if (state.advancedEnabled &&
        state.advancedOptions?["response_format"] == "json_object") {
      messageContent = "$messageContent(请严格按照json格式输出)";
    }

    // 文档处理暂不支持的提示
    // 2025-03-22 暂时不支持文档处理，也没有将解析后的文档内容作为参数传递
    if (messageData.file != null ||
        (messageData.fileContent != null &&
            messageData.fileContent?.trim().isNotEmpty == true)) {
      _showErrorDialog("暂不支持上传文档，后续有需求再更新");
      return;
    }

    // // 【要保留】处理文档内容，检查是否已经在对话中存在相同文档
    // // 2025-04-17 目前这个处理只是把手动解析或者智谱开放平台解析后的内容作为消息的参数传递调用API
    // // 感觉还是不够完善，所以暂时还是不加入消息
    // // 后续有专门支持文件的多模态后，直接传文件再处理
    // if (messageData.fileContent != null &&
    //     messageData.fileContent!.isNotEmpty) {
    //   final fileName =
    //       messageData.cloudFileName != null &&
    //               messageData.cloudFileName!.isNotEmpty
    //           ? messageData.cloudFileName!
    //           : (messageData.file?.path.split('/').last ?? '未命名文档');

    //   // 生成文档内容的特殊标记
    //   final docStartMark = "${DocumentUtils.DOC_START_PREFIX}$fileName]]";

    //   // 检查对话列表中是否已存在此文档
    //   bool docAlreadyExists = false;

    //   // 遍历现有消息查找相同文档
    //   for (var message in state.displayMessages) {
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
    //         messageData.file!.path.split('/').last,
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
      // 如果是新的分支对话，在用户发送消息时才创建记录
      if (state.isBranchNewChat) {
        final title = content.length > 20 ? content.substring(0, 20) : content;

        final session = await state.store.createSession(
          title,
          llmSpec: state.selectedModel!,
          modelType: state.selectedType,
        );
        setState(() {
          state.currentSessionId = session.id;
          state.isBranchNewChat = false;
        });
      }

      // 如果是编辑用户输入过的消息，会和直接发送消息有一些区别
      if (state.currentEditingMessage != null) {
        await _processingUserMessage(state.currentEditingMessage!, messageData);
      } else {
        await state.store.addMessage(
          session: state.store.sessionBox.get(state.currentSessionId!)!,
          content: content,
          role: CusRole.user.name,
          parent:
              state.displayMessages.isEmpty ? null : state.displayMessages.last,
          // 这个和语音转文字的那个冲突复用了，后续应该单独栏位放置，比如audiosUrl
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
      state.inputController.clear();
      await loadMessages();
      await _generateAIResponse();

      // 使用 InitHandler 刷新会话列表
      InitHandler(state, setState).loadSessions();
    } catch (e) {
      _showErrorDialog("发送消息失败: $e");
    }
  }

  /// 处理重新编辑的用户消息(在发送消息调用API前，还需要创建分支等其他操作)
  Future<void> _processingUserMessage(
    BranchChatMessage message,
    InputMessageData messageData,
  ) async {
    final content = messageData.text.trim();
    if (content.isEmpty) return;

    try {
      // 获取当前分支的所有消息
      final currentMessages = state.branchManager.getMessagesByBranchPath(
        state.allMessages,
        state.currentBranchPath,
      );

      // 找到要编辑的消息在当前分支中的位置
      final messageIndex = currentMessages.indexOf(message);
      if (messageIndex == -1) {
        pl.w("警告：找不到要编辑的消息在当前分支中的位置");
        return;
      }

      // 获取同级分支
      final siblings = state.branchManager.getSiblingBranches(
        state.allMessages,
        message,
      );

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
      await state.store.addMessage(
        session: state.store.sessionBox.get(state.currentSessionId!)!,
        content: content,
        role: CusRole.user.name,
        parent: message.parent.target,
        branchIndex: newBranchIndex,
        contentVoicePath: message.contentVoicePath,
        imagesUrl: message.imagesUrl,
        videosUrl: message.videosUrl,
      );

      // 更新当前分支路径并将正在编辑的消息设置为null
      setState(() {
        state.currentBranchPath = newPath;
        state.currentEditingMessage = null;
      });
    } catch (e) {
      _showErrorDialog("编辑消息失败: $e");
    }
  }

  /// 生成AI响应
  Future<void> _generateAIResponse() async {
    final currentMessages = state.branchManager.getMessagesByBranchPath(
      state.allMessages,
      state.currentBranchPath,
    );

    if (currentMessages.isEmpty) {
      pl.i('当前分支路径没有消息: ${state.currentBranchPath}');
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
      final siblings = state.branchManager.getSiblingBranches(
        state.allMessages,
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

    // 使用AIResponseHandler生成响应
    await AIResponseHandler(state, setState).generateAIResponseCommon(
      contextMessages: currentMessages,
      newBranchPath: state.currentBranchPath,
      newBranchIndex: branchIndex,
      depth: lastMessage.depth,
      parentMessage: lastMessage,
    );
  }

  /// 显示错误对话框
  void _showErrorDialog(String message) {
    showDialog(
      context: navigatorKey.currentContext!,
      builder:
          (context) => AlertDialog(
            title: Text("异常提示"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("确定"),
              ),
            ],
          ),
    );
  }
}

// 全局导航键，用于显示对话框等
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
