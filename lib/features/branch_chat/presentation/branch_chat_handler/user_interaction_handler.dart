import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../shared/widgets/toast_utils.dart';
import '../../../../core/entities/cus_llm_model.dart';
import '../../../../core/utils/simple_tools.dart';
import '../../../../shared/constants/constant_llm_enum.dart';
import '../../../../shared/constants/constants.dart';
import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../domain/advanced_options_utils.dart';
import '../../domain/entities/branch_chat_message.dart';
import '../../domain/entities/input_message_data.dart';
import '../branch_chat_state/branch_chat_state.dart';
import '../pages/add_model_page.dart';
import '../pages/branch_chat_background_picker_page.dart';
import '../pages/branch_chat_export_import_page.dart';
import '../widgets/_small_tool_widgets.dart';
import '../widgets/model_selector.dart';
import '../widgets/branch_tree_dialog.dart';
import '../widgets/text_edit_dialog.dart';
import '../widgets/text_selection_dialog.dart';
import 'ai_response_handler.dart';
import 'branch_message_handler.dart';
import 'branch_session_handler.dart';
import 'init_handler.dart';
import 'scroll_handler.dart';

/// 用户交互处理器，处理用户与UI交互相关的逻辑
///
/// 1 切换模型类型
/// 2 显示可选模型列表
/// 3 编辑用户消息时取消编辑
/// 4 切换消息分支
/// 5 长按消息显示的功能选项
/// 6 移动端 右上角功能弹窗
/// 7 桌面端 右侧工具栏列表
///
class UserInteractionHandler {
  final BranchChatState state;
  final Function setState;
  final BuildContext context;

  UserInteractionHandler(this.state, this.setState, this.context);

  /// 切换模型类型
  void handleTypeChanged(LLModelType type) {
    setState(() {
      state.selectedType = type;

      // 如果当前选中的模型不是新类型的，则清空选择
      // 因为切换类型时，一定会触发模型选择器，在模型选择的地方有重新创建对话，所以这里不用重新创建
      if (state.selectedModel?.modelType != type) {
        state.selectedModel = null;
      }
    });
  }

  /// 显示模型选择器
  Future<void> showModelSelector() async {
    // 获取可用的模型列表
    final filteredModels =
        state.modelList
            .where((m) => m.modelType == state.selectedType)
            .toList();

    if (filteredModels.isEmpty) {
      ToastUtils.showError('当前类型没有可用的模型');
      return;
    }

    // 使用自适应模型选择器，会根据平台选择最合适的显示方式
    final model = await ModelSelector.show(
      context: context,
      models: filteredModels,
      selectedModel: state.selectedModel,
    );

    if (model != null) {
      setState(() => state.selectedModel = model);
    } else {
      // 如果没有点击模型，则使用选定分类的第一个模型
      setState(() => state.selectedModel = filteredModels.first);
    }

    // 选择指定模型后，加载对应类型上次缓存的高级选项配置
    state.advancedEnabled = state.storage.getAdvancedOptionsEnabled(
      state.selectedModel!,
    );
    state.advancedOptions =
        state.advancedEnabled
            ? state.storage.getAdvancedOptions(state.selectedModel!)
            : null;

    // 切换模型后直接重建对话
    BranchSessionHandler(state, setState).createNewChat();
  }

  /// 编辑用户消息时取消编辑
  void handleCancelEditUserMessage() {
    setState(() {
      state.currentEditingMessage = null;
      state.inputController.clear();
      // 收起键盘
      state.inputFocusNode.unfocus();
    });
  }

  /// 切换消息分支
  void handleSwitchBranch(BranchChatMessage message, int newBranchIndex) {
    final availableBranchIndex = state.branchManager
        .getNextAvailableBranchIndex(
          state.allMessages,
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
      state.currentBranchPath = newPath;
    });

    // 重新计算当前分支的消息
    final currentMessages = state.branchManager.getMessagesByBranchPath(
      state.allMessages,
      newPath,
    );

    // 更新显示的消息列表
    setState(() {
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
            branchPath: newPath,
            branchIndex:
                currentMessages.isEmpty ? 0 : currentMessages.last.branchIndex,
            depth: currentMessages.isEmpty ? 0 : currentMessages.last.depth,
          ),
      ];
    });

    // 重置内容高度和滚动位置
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (state.scrollController.hasClients) {
    //     state.lastContentHeight =
    //         state.scrollController.position.maxScrollExtent;
    //     state.scrollController.animateTo(
    //       state.scrollController.position.maxScrollExtent,
    //       duration: Duration(milliseconds: 500),
    //       curve: Curves.easeOut,
    //     );
    //   }
    // });
    ScrollHandler(state, setState).resetContentHeight();
  }

  ///=============================================
  /// 长按消息，显示消息选项
  ///=============================================
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
        _handleMessageSelect(message);
      } else if (value == 'update_message') {
        _handleAIResponseUpdate(message);
      } else if (value == 'edit') {
        _handleUserMessageEdit(message);
      } else if (value == 'resend') {
        _handleUserMessageResend(message);
      } else if (value == 'regenerate') {
        AIResponseHandler(state, setState).handleResponseRegenerate(message);
      } else if (value == 'delete') {
        await _handleDeleteBranch(message);
      }
    });
  }

  // 消息文本自由选择复制
  void _handleMessageSelect(BranchChatMessage message) {
    if (!context.mounted) return;
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
  }

  // 修改AI响应的消息
  void _handleAIResponseUpdate(BranchChatMessage message) {
    // 2025-04-22 有时候AI响应的内容不完整或者不对，导致格式化显示时不美观，提供手动修改。
    // 又或者对于AI响应的内容不满意，要手动修改后继续对话。
    // 和修改用户信息不同，这个AI响应的修改不会创建新分支(但感觉修改了AI的响应会不会不严谨了？？？)。
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder:
          (context) => TextEditDialog(
            text: message.content,
            onSaved: (updatedText) async {
              var msg = message;
              msg.content = updatedText;
              await state.store.updateMessage(msg);
              await BranchMessageHandler(state, setState).loadMessages();
            },
          ),
    );
  }

  /// 编辑用户消息
  void _handleUserMessageEdit(BranchChatMessage message) {
    setState(() {
      state.currentEditingMessage = message;
      state.inputController.text = message.content;
      // 显示键盘
      state.inputFocusNode.requestFocus();
    });
  }

  /// 重新发送用户消息
  void _handleUserMessageResend(BranchChatMessage message) {
    setState(() {
      state.currentEditingMessage = message;
    });
    BranchMessageHandler(state, setState).handleSendMessage(
      InputMessageData(
        text: message.content,
        sttAudio:
            message.contentVoicePath != null
                ? File(message.contentVoicePath!)
                : null,
        images: message.imagesUrl?.split(',').map((img) => File(img)).toList(),
        audios: message.audiosUrl?.split(',').map((a) => File(a)).toList(),
        omniAudioVoice: message.omniAudioVoice,
      ),
    );
  }

  /// 删除当前对话消息分支
  Future<void> _handleDeleteBranch(BranchChatMessage message) async {
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
      final siblings = state.branchManager.getSiblingBranches(
        state.allMessages,
        message,
      );
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
      await state.store.deleteMessageWithBranches(message);

      // 更新当前分支路径并重新加载消息
      setState(() {
        state.currentBranchPath = newPath;
      });
      await BranchMessageHandler(state, setState).loadMessages();
    }
  }

  ///=============================================
  /// 部分移动端右上角、桌面端右侧的功能按钮的逻辑
  ///=============================================
  /// 移动端右上角弹出菜单按钮
  Widget buildPopupMenuButton() {
    return PopupMenuButton<String>(
      enabled: !state.isStreaming,
      icon: const Icon(Icons.more_horiz_sharp),
      // 调整弹出按钮的位置
      position: PopupMenuPosition.under,
      onSelected: (String value) async {
        // 处理菜单选择
        switch (value) {
          case 'add':
            BranchSessionHandler(state, setState).createNewChat();
            break;
          case 'options':
            _showAdvancedOptions();
            break;
          case 'text_size':
            _handleAdjustTextScale();
            break;
          case 'tree':
            _showBranchTree();
            break;
          case 'brief_mode':
            _showDisplayChangeDialog();
            break;
          case 'background':
            _changeBackground();
            break;
          case 'add_model':
            _handleAddModel();
            break;
          case 'export_import':
            _navigateToExportImportPage();
            break;
        }
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

  /// 构建桌面端右侧功能按钮面板
  Widget buildDesktopRightSidebarPanel() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 新建对话
          buildIconWithTextButton(
            icon: Icons.add,
            label: '新建对话',
            onTap:
                !state.isStreaming
                    ? () =>
                        BranchSessionHandler(state, setState).createNewChat()
                    : null,
            context: context,
          ),
          // 高级选项
          buildIconWithTextButton(
            icon: Icons.settings_suggest,
            label: '高级选项',
            onTap: !state.isStreaming ? _showAdvancedOptions : null,
            context: context,
          ),
          // 调整文本大小
          buildIconWithTextButton(
            icon: Icons.format_size,
            label: '字体大小',
            onTap: !state.isStreaming ? _handleAdjustTextScale : null,
            context: context,
          ),
          // 切换简洁模式
          buildIconWithTextButton(
            icon:
                state.isBriefDisplay
                    ? Icons.details
                    : Icons.visibility_outlined,
            label: state.isBriefDisplay ? '详细显示' : '简洁显示',
            onTap:
                !state.isStreaming
                    ? () => setState(
                      () => state.isBriefDisplay = !state.isBriefDisplay,
                    )
                    : null,
            context: context,
          ),
          // 切换背景图片
          buildIconWithTextButton(
            icon: Icons.wallpaper,
            label: '更换背景',
            onTap: !state.isStreaming ? _changeBackground : null,
            context: context,
          ),
          // 显示分支树
          buildIconWithTextButton(
            icon: Icons.account_tree,
            label: '对话分支',
            onTap:
                !state.isStreaming && !state.isBranchNewChat
                    ? _showBranchTree
                    : null,
            context: context,
          ),
          // 添加模型
          buildIconWithTextButton(
            icon: Icons.add_box_outlined,
            label: '添加模型',
            onTap: !state.isStreaming ? _handleAddModel : null,
            context: context,
          ),
          // 导入导出
          buildIconWithTextButton(
            icon: Icons.import_export,
            label: '导入导出',
            onTap: !state.isStreaming ? _navigateToExportImportPage : null,
            context: context,
          ),
        ],
      ),
    );
  }

  /// 显示高级选项对话框
  Future<void> _showAdvancedOptions() async {
    if (state.selectedModel == null) return;

    final result = await AdvancedOptionsUtils.showAdvancedOptions(
      context: context,
      platform: state.selectedModel!.platform,
      modelType: state.selectedModel!.modelType,
      currentEnabled: state.advancedEnabled,
      currentOptions: state.advancedOptions ?? {},
    );

    if (result != null) {
      setState(() {
        state.advancedEnabled = result.enabled;
        state.advancedOptions = result.enabled ? result.options : null;
      });

      // 保存到缓存
      await state.storage.setAdvancedOptionsEnabled(
        state.selectedModel!,
        result.enabled,
      );
      await state.storage.setAdvancedOptions(
        state.selectedModel!,
        result.enabled ? result.options : null,
      );
    }
  }

  /// 调整文本缩放
  void _handleAdjustTextScale() {
    adjustTextScale(context, state.textScaleFactor, (value) async {
      setState(() => state.textScaleFactor = value);
      await state.storage.setChatMessageTextScale(value);

      if (!context.mounted) return;
      Navigator.of(context).pop();

      unfocusHandle();
    });
  }

  /// 显示分支树对话框
  void _showBranchTree() {
    showDialog(
      context: context,
      builder:
          (context) => BranchTreeDialog(
            messages: state.allMessages,
            currentPath: state.currentBranchPath,
            onPathSelected: (path) {
              setState(() => state.currentBranchPath = path);
              // 重新加载选中分支的消息
              final currentMessages = state.branchManager
                  .getMessagesByBranchPath(state.allMessages, path);
              setState(() {
                state.displayMessages = currentMessages;
              });
              Navigator.pop(context);
            },
          ),
    );
  }

  /// 切换背景
  void _changeBackground() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BranchChatBackgroundPickerPage(
              title: '切换对话背景',
              currentCharacter: state.currentCharacter,
            ),
      ),
    ).then((confirmed) {
      // 只有在用户点击了确定按钮时才重新加载背景设置
      if (confirmed == true) {
        InitHandler(state, setState).loadBackgroundSettings();
        InitHandler(state, setState).reapplyMessageColorConfig();
      }
    });
  }

  /// 显示简洁模式切换对话框（桌面不用弹窗，直接点击按钮就生效）
  void _showDisplayChangeDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        bool isShow = state.isBriefDisplay;
        return AlertDialog(
          title: Text('是否简洁显示', style: TextStyle(fontSize: 18)),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter dialogSetState) {
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
                        onChanged:
                            (value) => dialogSetState(() => isShow = value),
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
              onPressed: () {
                setState(() => state.isBriefDisplay = isShow);
                Navigator.of(context).pop();
                unfocusHandle();
              },
            ),
          ],
        );
      },
    );
  }

  /// 添加模型
  Future<void> _handleAddModel() async {
    final result = await Navigator.push<CusLLMSpec>(
      context,
      MaterialPageRoute(builder: (context) => AddModelPage(isAddChat: true)),
    );

    // 从添加单个模型页面返回后，先重新初始化
    await InitHandler(state, setState).initialize();

    // 如果添加模型成功，则更新当前选中的模型和类型，并创建新对话
    if (result != null && context.mounted) {
      try {
        // 更新当前选中的模型和类型
        setState(() {
          state.selectedModel =
              state.modelList
                  .where((m) => m.cusLlmSpecId == result.cusLlmSpecId)
                  .firstOrNull;
          state.selectedType = result.modelType;
        });

        // 创建新对话
        BranchSessionHandler(state, setState).createNewChat();
        ToastUtils.showSuccess('添加模型成功');
      } catch (e) {
        pl.e('添加模型失败: $e');
        if (context.mounted) {
          commonExceptionDialog(context, '添加模型失败', e.toString());
        }
      }
    }
  }

  /// 导航到导出导入页面
  void _navigateToExportImportPage() async {
    bool isGranted = await requestStoragePermission();

    if (!context.mounted) return;
    if (!isGranted) {
      commonExceptionDialog(context, "异常提示", "无存储访问授权");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BranchChatExportImportPage()),
    ).then((_) {
      // 返回后重新加载会话列表
      InitHandler(state, setState).loadSessions();
    });
  }
}
