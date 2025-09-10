import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';

import '../../../../core/utils/wav_audio_handler.dart';
import '../../../../shared/constants/constants.dart';
import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../data/services/chat_service.dart';
import '../../domain/entities/branch_chat_message.dart';
import '../branch_chat_state/branch_chat_state.dart';
import 'branch_message_handler.dart';

/// AI响应处理器，专门处理AI响应生成相关的逻辑
///
/// 1 准备聊天记录(用户点击发送消息前构建请求的messages参数结构)
/// 2 AI响应的重新生成
/// 3 生成AI响应的通用方法
/// 4 流式响应时手动终止
///
class AIResponseHandler {
  final BranchChatState state;
  final Function setState;

  AIResponseHandler(this.state, this.setState);

  /// 准备聊天历史
  List<Map<String, dynamic>> prepareChatHistory(
    List<BranchChatMessage> messages,
  ) {
    final history = <Map<String, dynamic>>[];

    // 添加系统提示词
    if (state.currentCharacter != null) {
      history.add({
        'role': CusRole.system.name,
        'content': state.currentCharacter?.generateSystemPrompt(),
      });
    }

    // 添加聊天历史
    for (var message in messages) {
      // 跳过空消息
      if (message.content.isEmpty &&
          message.imagesUrl == null &&
          message.audiosUrl == null) {
        continue;
      }

      // 先取出消息内容
      var tmpAudiosUrl = message.audiosUrl;
      var tmpImagesUrl = message.imagesUrl;
      var tmpVideosUrl = message.videosUrl;

      // 处理用户消息，可能包含多模态内容
      if (message.role == CusRole.user.name) {
        // 如果只有纯文本，直接构建即可
        if (tmpAudiosUrl == null &&
            tmpImagesUrl == null &&
            tmpVideosUrl == null) {
          // 纯文本消息
          history.add({'role': CusRole.user.name, 'content': message.content});
        } else {
          // 多模态消息
          final contentList = <Map<String, dynamic>>[];

          // 如果用户消息包含图片
          if ((tmpImagesUrl != null && tmpImagesUrl.isNotEmpty)) {
            // 处理图片
            final imageUrls = tmpImagesUrl.split(',');
            for (final url in imageUrls) {
              try {
                final bytes = File(url.trim()).readAsBytesSync();
                final base64Image = base64Encode(bytes);
                contentList.add({
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
                });
              } catch (e) {
                _showErrorDialog('处理图片失败: $e');
              }
            }
          }

          // 如果用户消息包含音频
          if (tmpAudiosUrl != null && tmpAudiosUrl.isNotEmpty) {
            // 处理音频
            // 2025-05-30 omni只支持传单个音频，所以这里只取第一个
            final audioUrls = tmpAudiosUrl.split(',');
            if (audioUrls.isNotEmpty) {
              String audioUrl = audioUrls.first;
              try {
                final bytes = File(audioUrl).readAsBytesSync();
                final base64Audio = base64Encode(bytes);
                contentList.add({
                  'type': 'input_audio',
                  'input_audio': {
                    'data': 'data:;base64,$base64Audio',
                    "format": audioUrl.split('.').last,
                  },
                });
              } catch (e) {
                _showErrorDialog('处理音频失败: $e');
              }
            }
          }

          // // TODO 如果用户消息包含视频(没有云端存储，暂时不弄)
          // if (tmpVideosUrl != null && tmpVideosUrl.isNotEmpty) {
          //   try {
          //     final bytes = File(tmpVideosUrl).readAsBytesSync();
          //     final base64Audio = base64Encode(bytes);
          //     contentList.add({
          //       'type': 'video_url',
          //       'video_url': {'url': 'data:;base64,$base64Audio'},
          //     });
          //   } catch (e) {
          //     _showErrorDialog('处理视频频失败: $e');
          //   }
          // }

          // 都要先添加文本内容
          if (message.content.isNotEmpty) {
            contentList.add({'type': 'text', 'text': message.content});
          }

          // 再添加多模态数据
          history.add({'role': CusRole.user.name, 'content': contentList});
        }
      } else if (message.role == CusRole.assistant.name &&
          message.characterId == state.currentCharacter?.characterId) {
        // 构建AI助手的回复消息只有纯文本，即便AI响应有合成图片、音频，都不可以加入助手消息列表
        history.add({
          'role': CusRole.assistant.name,
          'content': message.content,
        });
      }
    }

    return history;
  }

  /// 重新生成AI响应内容
  Future<void> handleResponseRegenerate(BranchChatMessage message) async {
    if (state.isStreaming) return;

    setState(() {
      state.regeneratingMessageId = message.id;
      state.isStreaming = true;
    });

    try {
      final currentMessages = state.branchManager.getMessagesByBranchPath(
        state.allMessages,
        message.branchPath,
      );

      final messageIndex = currentMessages.indexOf(message);
      if (messageIndex == -1) return;

      final contextMessages = currentMessages.sublist(0, messageIndex);

      // 判断当前所处的分支路径是否是在修改用户消息后新创建的分支
      // 核心判断逻辑：当前分支路径与要重新生成的消息分支路径的关系
      bool isAfterUserEdit = false;

      // 获取当前分支路径的所有部分
      final List<String> currentPathParts = state.currentBranchPath.split('/');
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
          final userMessages = state.allMessages
              .where(
                (m) =>
                    m.role == CusRole.user.name &&
                    m.branchPath == state.currentBranchPath,
              )
              .toList();

          isAfterUserEdit = userMessages.isNotEmpty;
        }
      }
      // 情况2: 分支路径不同，但共享相同父路径，检查是否已经切换到不同分支
      else if (!state.currentBranchPath.startsWith(message.branchPath) &&
          !message.branchPath.startsWith(state.currentBranchPath)) {
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
          final userMessagesOnCurrentPath = state.allMessages
              .where(
                (m) =>
                    m.role == CusRole.user.name &&
                    m.branchPath == state.currentBranchPath,
              )
              .toList();

          isAfterUserEdit = userMessagesOnCurrentPath.isNotEmpty;
        }
      }

      // 获取重新生成位置的同级分支
      final siblings = state.branchManager.getSiblingBranches(
        state.allMessages,
        message,
      );
      final availableSiblings =
          siblings.where((m) => state.allMessages.contains(m)).toList()
            ..sort((a, b) => a.branchIndex.compareTo(b.branchIndex));

      // 计算新的分支索引
      int newBranchIndex;
      if (isAfterUserEdit) {
        // 如果是在用户编辑后新创建的分支上，AI响应索引应该从0开始
        newBranchIndex = 0;
      } else {
        // 常规情况下，使用当前同级分支的最大索引+1
        newBranchIndex = availableSiblings.isEmpty
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

      await generateAIResponseCommon(
        contextMessages: contextMessages,
        newBranchPath: newPath,
        newBranchIndex: newBranchIndex,
        depth: message.depth,
        parentMessage: message.parent.target,
      );
    } catch (e) {
      _showErrorDialog("重新生成失败: $e");
      setState(() {
        state.isStreaming = false;
      });
    } finally {
      setState(() => state.regeneratingMessageId = null);
    }
  }

  /// 生成AI响应的通用方法
  Future<BranchChatMessage?> generateAIResponseCommon({
    required List<BranchChatMessage> contextMessages,
    required String newBranchPath,
    required int newBranchIndex,
    required int depth,
    BranchChatMessage? parentMessage,
  }) async {
    // 初始化状态
    setState(() {
      state.isStreaming = true;
      state.streamingContent = '';
      state.streamingReasoningContent = '';
      // 创建临时的流式消息
      state.displayMessages = [
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
    // 2025-05-30 多模态千问omni可以合成语音，响应中有base64语音片段
    // 在流响应完成或者手动终止时，才把已经收集到的片段转为语音，再提供播放
    String finalAudioBase64 = "";
    var startTime = DateTime.now();
    DateTime? endTime;
    var thinkingDuration = 0;
    BranchChatMessage? aiMessage;
    // 联网搜索参考内容
    List<Map<String, dynamic>>? references = [];

    try {
      final history = prepareChatHistory(contextMessages);

      if (state.inputMessageData?.omniAudioVoice != null) {
        // 2025-05-30 如果开启了高级选项，则把千问omni的音色传入
        if (state.advancedEnabled && state.advancedOptions != null) {
          state.advancedOptions!['omni_audio_voice'] =
              state.inputMessageData?.omniAudioVoice;
        } else {
          // 如果没有开启高级选项，就把千问omni音色当做高级选项传入
          state.advancedOptions = {
            "omni_audio_voice": state.inputMessageData?.omniAudioVoice,
          };
        }
      }

      final (stream, cancelFunc) = await ChatService.sendMessage(
        state.selectedModel!,
        history,
        advancedOptions: state.advancedOptions,
        stream: true,
        enableWebSearch: state.inputMessageData?.enableWebSearch ?? false,
      );

      state.cancelResponse = cancelFunc;

      // 处理流式响应的内容(包括正常完成、手动终止和错误响应)
      await for (final chunk in stream) {
        // 更新流式内容和状态
        setState(() {
          // 联网搜索参考内容
          if (chunk.searchResults != null) {
            references.addAll(chunk.searchResults!);
          }

          // 1. 更新内容
          state.streamingContent += chunk.cusText;
          state.streamingReasoningContent += chunk.choices.isNotEmpty
              ? (chunk.choices.first.delta?["reasoning_content"] ??
                    chunk.choices.first.delta?["reasoning"] ??
                    '')
              : '';
          finalContent += chunk.cusText;
          finalReasoningContent += chunk.choices.isNotEmpty
              ? (chunk.choices.first.delta?["reasoning_content"] ??
                    chunk.choices.first.delta?["reasoning"] ??
                    '')
              : '';

          finalAudioBase64 += chunk.choices.isNotEmpty
              ? (chunk.choices.first.delta?["audio"]?['data'] ?? '')
              : '';

          // 计算思考时间(从发起调用开始，到当流式内容不为空时计算结束)
          if (endTime == null && state.streamingContent.isNotEmpty) {
            endTime = DateTime.now();
            thinkingDuration = endTime!.difference(startTime).inMilliseconds;
          }

          // 2. 更新显示消息列表
          state.displayMessages = [
            ...contextMessages,
            BranchChatMessage(
              id: 0,
              messageId: 'streaming',
              role: CusRole.assistant.name,
              content: state.streamingContent,
              reasoningContent: state.streamingReasoningContent,
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
        if (!state.isStreaming) break;

        // 自动滚动逻辑
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final currentHeight = state.scrollController.position.maxScrollExtent;
          if (!state.isUserScrolling &&
              currentHeight - state.lastContentHeight > 20) {
            // 高度增加超过 20 像素
            state.scrollController.jumpTo(currentHeight);
            state.lastContentHeight = currentHeight;
          }
        });
      }

      String voicePath = '';
      // 如果是多模态有响应音频base64数据，保存到固定的位置
      if (finalAudioBase64.isNotEmpty) {
        voicePath = await WavAudioHandler.saveBase64Wav(
          finalAudioBase64,
          model: state.selectedModel?.model,
        );
      }

      // 如果有内容则创建消息(包括正常完成、手动终止和错误响应[错误响应也是一个正常流消息])
      if (finalContent.isNotEmpty || finalReasoningContent.isNotEmpty) {
        aiMessage = await state.store.addMessage(
          session: state.store.sessionBox.get(state.currentSessionId!)!,
          content: finalContent,
          role: CusRole.assistant.name,
          parent: parentMessage,
          reasoningContent: finalReasoningContent,
          thinkingDuration: thinkingDuration,
          references: references,
          modelLabel: parentMessage?.modelLabel ?? state.selectedModel!.name,
          branchIndex: newBranchIndex,
          // 构建用户消息时，这个是用户选择的音频地址；构建AI响应消息时，这个大模型生成的语音保存后的地址
          audiosUrl: voicePath,
          omniAudioVoice: state.inputMessageData?.omniAudioVoice,
        );

        // 更新当前分支路径(其他重置在 finally 块中)
        setState(() => state.currentBranchPath = aiMessage!.branchPath);
      }

      return aiMessage;
    } catch (e) {
      _showErrorDialog("AI响应生成失败: $e");

      // 创建错误消息
      final errorContent = """生成失败:\n\n错误信息: $e""";

      aiMessage = await state.store.addMessage(
        session: state.store.sessionBox.get(state.currentSessionId!)!,
        content: errorContent,
        role: CusRole.assistant.name,
        parent: parentMessage,
        thinkingDuration: thinkingDuration,
        modelLabel: parentMessage?.modelLabel ?? state.selectedModel!.name,
        branchIndex: newBranchIndex,
      );

      return aiMessage;
    } finally {
      setState(() {
        state.isStreaming = false;
        state.streamingContent = '';
        state.streamingReasoningContent = '';
        state.cancelResponse = null;
      });
      // 在 finally 块中重新加载消息，确保无论是正常完成还是手动终止都会重新加载消息
      await BranchMessageHandler(state, setState).loadMessages();
    }
  }

  /// 停止流式生成(用户主动停止)
  void handleStopStreaming() {
    setState(() => state.isStreaming = false);
    state.cancelResponse?.call();
    state.cancelResponse = null;
  }

  /// 显示错误对话框
  void _showErrorDialog(String message) {
    if (navigatorKey.currentContext != null) {
      commonExceptionDialog(
        navigatorKey.currentContext!,
        "异常提示",
        "重新生成失败: $message",
      );
    } else {
      ToastUtils.showError(message);
    }
  }
}
