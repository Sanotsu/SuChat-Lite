import 'package:flutter/material.dart';

import '../../../../../core/entities/cus_llm_model.dart';
import '../../../../../core/storage/cus_get_storage.dart';
import '../../../../../shared/constants/constant_llm_enum.dart';
import '../../domain/entities/branch_chat_message.dart';
import '../../domain/entities/branch_chat_session.dart';
import '../../domain/entities/character_card.dart';
import '../../domain/entities/input_message_data.dart';
import '../../domain/entities/message_font_color.dart';
import '../viewmodels/branch_manager.dart';
import '../viewmodels/branch_store.dart';

/// BranchChatPage的状态类，包含所有与状态管理相关的属性和方法
class BranchChatState {
  // 分支管理器
  final BranchManager branchManager = BranchManager();
  // 分支存储器
  late final BranchStore store;
  // 缓存存储器
  final CusGetStorage storage = CusGetStorage();

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
  List<CusLLMSpec> modelList = [];
  LLModelType selectedType = LLModelType.cc;
  CusLLMSpec? selectedModel;

  // 添加高级参数状态
  bool advancedEnabled = false;
  Map<String, dynamic>? advancedOptions;

  // 默认的页面主体的缩放比例(对话太小了就可以等比放大)
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

  // 消息字体颜色配置
  late MessageFontColor colorConfig;

  // 2025-05-30 对话输入组件点击发送之后回传带上的参数，设为全局，方便复用
  InputMessageData? inputMessageData;

  void dispose() {
    inputFocusNode.dispose();
    inputController.dispose();
    scrollController.dispose();
    cancelResponse?.call();
  }
}
