import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/storage/cus_get_storage.dart';
import '../../../../core/network/dio_client/interceptor_error.dart';
import '../../../../core/services/media_save_service.dart';
import '../../../../core/utils/get_dir.dart';
import '../../../../core/utils/simple_tools.dart';
import '../../../../core/utils/wav_audio_handler.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../../../shared/widgets/markdown_render/cus_markdown_renderer.dart';
import '../../../../core/entities/message_font_color.dart';
import '../../data/database/unified_chat_dao.dart';
import '../../data/models/openai_response.dart';
import '../../data/models/unified_chat_message.dart';
import '../../data/models/unified_chat_partner.dart';
import '../../data/models/unified_conversation.dart';
import '../../data/models/unified_model_spec.dart';
import '../../data/models/unified_platform_spec.dart';
import '../../data/services/unified_chat_service.dart';
import '../../data/services/unified_branch_utils.dart';
import '../../data/services/image_generation_service.dart';
import '../../data/models/image_generation_request.dart';
import '../../data/models/media_library_item.dart';
import '../../data/services/video_generation_service.dart';
import '../../data/services/speech_synthesis_service.dart';
import '../../data/models/speech_synthesis_request.dart';
import '../../data/services/speech_recognition_service.dart';
import '../../data/models/speech_recognition_request.dart';
import '../../data/services/unified_secure_storage.dart';
import '../../data/services/web_search_tool_manager.dart';
import '../../data/services/builtin_web_search_registry.dart';
import '../../data/models/mcp_models.dart';
import '../../data/services/mcp/mcp_server_manager.dart';

/// 统一聊天状态管理
class UnifiedChatViewModel extends ChangeNotifier {
  final UnifiedChatService _chatService = UnifiedChatService();
  final UnifiedChatDao _chatDao = UnifiedChatDao();
  final WebSearchToolManager _searchToolManager = WebSearchToolManager();

  /// 当前状态
  UnifiedConversation? _currentConversation;

  /// 当前分支视图的消息列表(对外暴露，UI和上下文构建都只消费它)
  List<UnifiedChatMessage> _messages = [];

  /// 会话的全部消息(包含所有分支)
  List<UnifiedChatMessage> _allMessages = [];

  /// 当前查看的分支路径；null表示默认最新链
  String? _currentBranchPath;

  /// 显示列表截断标记：非null时，显示列表截断到该消息(含)为止
  /// 用于"重新生成/编辑/重发"场景：视图回退到父消息，新回复作为新分支挂载
  String? _displayTruncateId;

  List<UnifiedModelSpec> _availableModels = [];
  List<UnifiedPlatformSpec> _availablePlatforms = [];
  UnifiedModelSpec? _currentModel;
  UnifiedPlatformSpec? _currentPlatform;
  UnifiedChatPartner? _currentPartner;

  /// 对话是否开启联网搜索
  bool _isWebSearchEnabled = false;

  /// 2026-09-09 用户是否手动切换过联网开关：
  /// 手动切过则永久尊重其选择(不再跟随能力自动开)；
  /// 未切过时启动/切模型/切会话会跟随联网能力自动开关
  bool _webSearchManuallyToggled = false;
  static const String _webSearchManuallyToggledKey =
      'unified_chat_web_search_manually_toggled';

  /// 2026-09-11 MCP集成(P1-3)：会话是否启用MCP工具(会话级持久化，
  /// secure storage按conversationId存取，安全默认关)
  bool _isMcpEnabled = false;

  /// 2026-09-14 P3-1 工具调用审批：待审批请求(非null时输入框上方
  /// 显示审批横幅，Agent循环挂起等待用户决定)
  /// P3-13泛化：MCP与内置工具统一走此通道
  ToolApprovalRequest? _pendingApproval;
  ToolApprovalRequest? get pendingApproval => _pendingApproval;

  /// 审批等待通道(横幅按钮完成它)
  Completer<ToolApprovalDecision>? _approvalCompleter;

  /// 本次会话"总是允许"的规则键(MCP=serverName；内置shell=builtin:首词)。
  /// 内存级：切会话/重启失效；持久信任应直接关闭server的审批开关
  final Set<String> _sessionAllowedKeys = {};

  /// dispose标记：审批finally中的notifyListeners防崩
  bool _disposed = false;

  /// 2026-09-14 P3-11 内置终端命令工具全局开关(桌面端生效，默认关)
  /// GetStorage持久化：安全默认，开启时设置页有安全提示
  bool get isShellToolEnabled =>
      CusGetStorage().box.read(_shellToolEnabledKey) == true;

  Future<void> setShellToolEnabled(bool enabled) async {
    await CusGetStorage().box.write(_shellToolEnabledKey, enabled);
    notifyListeners();
  }

  static const String _shellToolEnabledKey = 'unified_chat_shell_tool_enabled';

  /// 加载和流式状态
  bool _isLoading = false;
  bool _isStreaming = false;
  String? _error;
  StreamSubscription? _streamSubscription;

  /// 2026-09-09 用户手动中断标志：stopStreaming置位、新流监听开始时复位；
  /// 取消类错误到达onError时据此静默处理(不显示报错)
  bool _manualStopRequested = false;

  /// 2026-09-15 切换会话流式修复(用户实测)：正在流式的会话id。
  /// 原实现流式状态是纯全局bool——切换会话后其他会话的输入框也
  /// 显示STOP且点击会误停别的会话的流
  String? _streamingConversationId;

  /// 2026-09-15 切换会话流式修复：各会话进行中的流式消息对象(按会话id)。
  /// 发送后切走时流继续在该对象上累积(与当前视图列表无关)，切回会话
  /// 时挂回消息列表恢复实时刷新；完成/停止/出错时无条件落库——原实现
  /// 完成处理依赖"消息在当前_messages里"，切走后index==-1直接跳过，
  /// 导致整个AI回复永久丢失(切回只见空会话)
  final Map<String, UnifiedChatMessage> _activeStreamingMessages = {};

  /// 搭档显示状态
  bool _showPartnersInNewChat = true;
  bool _isPartnerSelected = false;

  /// 消息编辑状态
  UnifiedChatMessage? _editingUserMessage;
  bool _isUserEditingMode = false;

  /// 是否是键盘输入模式(2025-10-18 暂定不是键盘输入就是语音输入)
  bool _isKeyboardInput = true;

  // ============ 外观设置(2026-08-31 从旧版branch_chat移植) ============
  // 存储key与旧版共用(文字大小/背景/字体颜色)，新旧版外观设置互通

  /// 消息文字缩放比例(0.6~2.0)
  double _textScaleFactor = 1.0;

  /// 全局聊天背景图路径(assets/本地文件路径/网络URL)
  String? _globalBackgroundImage;

  /// 全局背景图不透明度(0.1~1.0)
  double _globalBackgroundOpacity = 0.2;

  /// 消息字体颜色配置(背景模式下生效)
  MessageFontColor _messageFontColor = MessageFontColor.defaultConfig();

  /// 简洁显示(隐藏头像/元信息/分支切换器，只保留正文)
  bool _isBriefDisplay = false;

  /// 上次加载的外观指纹(背景+字体颜色)，变化时需清Markdown渲染缓存
  String? _lastAppearanceSignature;

  /// Getters
  UnifiedConversation? get currentConversation => _currentConversation;
  List<UnifiedChatMessage> get messages => _messages;

  /// 会话全部消息(含所有分支，供分支树/兄弟查询用)
  List<UnifiedChatMessage> get allMessages => _allMessages;

  /// 当前分支路径
  String? get currentBranchPath => _currentBranchPath;

  List<UnifiedModelSpec> get availableModels => _availableModels;
  List<UnifiedPlatformSpec> get availablePlatforms => _availablePlatforms;
  UnifiedModelSpec? get currentModel => _currentModel;
  UnifiedPlatformSpec? get currentPlatform => _currentPlatform;
  UnifiedChatPartner? get currentPartner => _currentPartner;
  bool get isWebSearchEnabled => _isWebSearchEnabled;

  /// 2026-09-11 MCP集成(P1-3)：当前会话MCP工具开关状态
  bool get isMcpEnabled => _isMcpEnabled;

  /// 切换当前会话MCP工具开关并持久化(secure storage按会话id存取)
  Future<void> toggleMcpEnabled([bool? value]) async {
    _isMcpEnabled = value ?? !_isMcpEnabled;
    if (_currentConversation != null) {
      await UnifiedSecureStorage.setConversationMcpEnabled(
        _currentConversation!.id,
        _isMcpEnabled,
      );
    }
    notifyListeners();
  }

  double get textScaleFactor => _textScaleFactor;

  /// 背景优先级(对齐旧版角色背景)：搭档专属背景 > 全局聊天背景
  String? get backgroundImage {
    final partner = _currentPartner;
    if (partner != null && partner.hasBackground) {
      return partner.background;
    }
    return _globalBackgroundImage;
  }

  double get backgroundOpacity {
    final partner = _currentPartner;
    if (partner != null && partner.hasBackground) {
      return partner.backgroundOpacity ?? 0.35;
    }
    return _globalBackgroundOpacity;
  }

  MessageFontColor get messageFontColor => _messageFontColor;
  bool get isBriefDisplay => _isBriefDisplay;

  /// 是否启用了背景图(气泡透明化/字体颜色配置生效的开关)
  bool get hasBackgroundImage {
    final img = backgroundImage;
    return img != null && img.trim().isNotEmpty;
  }

  bool get isImageGenerationModel =>
      _currentModel?.type == UnifiedModelType.image;

  bool get isVideoGenerationModel =>
      _currentModel?.type == UnifiedModelType.video;

  bool get isSpeechSynthesisModel =>
      _currentModel?.type == UnifiedModelType.tts;

  bool get isSpeechRecognitionModel =>
      _currentModel?.type == UnifiedModelType.asr;

  // 是否可显示添加附件按钮(录音文件识别、图生图/图生视频的参考图、cc中支持视觉理解)
  bool get canShowAttachmentButton =>
      _currentModel?.type == UnifiedModelType.asr ||
      ((_currentModel?.type == UnifiedModelType.image ||
              _currentModel?.type == UnifiedModelType.video) &&
          _currentModel?.supportsImageInput == true) ||
      (_currentModel?.type == UnifiedModelType.cc &&
          _currentModel?.supportsVision == true);

  // 当前对话是否已归档（已归档则不显示输入框）
  bool get isConversationArchived => _currentConversation?.isArchived ?? false;

  // 状态getters
  bool get isLoading => _isLoading;
  bool get isStreaming => _isStreaming;

  /// 2026-09-15 切换会话流式修复：当前会话是否有进行中的流式——
  /// 输入框STOP按钮的显示条件(全局isStreaming会让其他会话也显示STOP)
  bool get isCurrentSessionStreaming =>
      _isStreaming && _streamingConversationId == _currentConversation?.id;

  String? get error => _error;
  bool get hasError => _error != null;

  /// 搭档/列表显示相关getter
  // 获取当前有效的搭档（如果没有选择搭档则返回默认搭档）
  UnifiedChatPartner get effectivePartner => _currentPartner ?? defaultPartner;
  // 是否在新对话中显示搭档（会在“我的搭档”页面进行设置）
  bool get showPartnersInNewChat => _showPartnersInNewChat;
  // 只有在新对话（消息列表为空）、且未选择搭档、且选中模型为cc类型时才显示搭档列表
  bool get shouldShowPartnersList =>
      _showPartnersInNewChat &&
      _messages.isEmpty &&
      !_isPartnerSelected &&
      _currentModel?.type == UnifiedModelType.cc;
  // 是否有搭档工具被选择（配合消息列表是否为空，来控制在对话主页面是否显示被选中的搭档工具）
  bool get isPartnerSelected => _isPartnerSelected;
  // 只有在新对话（消息列表为空）且有搭档工具被选择时才显示被选中的搭档工具
  bool get shouldShowSelectedPartner => _isPartnerSelected && _messages.isEmpty;

  /// 编辑状态相关getters
  UnifiedChatMessage? get editingUserMessage => _editingUserMessage;
  bool get isUserEditingMode => _isUserEditingMode;

  bool get isKeyboardInput => _isKeyboardInput;

  /// 初始化Provider
  Future<void> initialize() async {
    _setLoading(true);

    // 2026-09-14 清理孤儿流式状态：上次进程可能在生成中被杀，库中残留
    // is_streaming=1的消息重启后会一直显示"生成中…"——启动即复位，
    // 必须在加载最近对话之前执行
    try {
      await _chatDao.clearOrphanStreamingMessages();
    } catch (e) {
      pl.e('清理孤儿流式状态失败: $e');
    }

    // 2026-09-14 P3-1/P3-13 审批处理器注入：viewmodel作为UI代理，
    // 挂起Agent循环等用户在横幅上决定(MCP工具与内置工具统一通道)
    McpServerManager().approvalHandler = _requestToolApproval;
    _chatService.builtinToolApprovalHandler = _requestToolApproval;

    // 首先加载用户偏好设置
    await _loadUserPreferences();

    // 加载外观设置(文字大小/背景/字体颜色/简洁显示)
    await loadAppearanceSettings();

    // 加载可用的平台和模型
    await _loadAvailablePlatforms();
    await _loadAvailableModels();

    // 初始化搜索工具管理器
    await _searchToolManager.initialize();

    // 尝试加载最近的对话和模型设置
    await _loadRecentConversationOrCreateNew();

    // 如果上述所有初始化处理完还没有初始化的模型，使用第一个
    if (_availableModels.isNotEmpty && _currentModel == null) {
      await switchModel(_availableModels.first);
    }

    // 2026-09-09 联网开关默认值跟随能力：
    // 读取用户是否手动切换过的标记；未手动切过且当前具备联网能力
    // (平台自带搜索/第三方Key+工具调用)时默认开启，避免"提示词要求
    // 联网搜索却因开关未开导致结果不符预期"
    try {
      _webSearchManuallyToggled =
          CusGetStorage().box.read(_webSearchManuallyToggledKey) == true;
    } catch (_) {
      _webSearchManuallyToggled = false;
    }
    _syncWebSearchWithCapability();

    _setLoading(false);
  }

  /// ******************************************
  /// 2026-09-14 P3-1 工具调用审批确认流
  /// manager.handleToolCall拦截 → _requestToolApproval挂起 →
  /// UI横幅(输入框上方) → approve/deny完成等待 → 循环继续
  /// ******************************************

  /// 审批请求入口(manager/service回调)：会话级已信任的规则键直接放行，
  /// 否则挂起等用户决定(横幅按钮或180s超时自动拒绝)。
  /// 2026-09-14 P3-6 并行执行时多个审批同时到达：排队等待前序横幅
  /// 完成后串行弹出(轮询等待，审批是人工秒级操作开销可忽略)
  Future<ToolApprovalDecision> _requestToolApproval(
    ToolApprovalRequest request,
  ) async {
    if (_sessionAllowedKeys.contains(request.sessionAllowKey)) {
      return ToolApprovalDecision.allow;
    }

    // 排队：等待前一个审批完成(横幅一次只显示一个请求)
    while (_pendingApproval != null && !_disposed) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (_disposed) return ToolApprovalDecision.deny;

    final completer = Completer<ToolApprovalDecision>();
    _approvalCompleter = completer;
    _pendingApproval = request;
    notifyListeners();

    // 超时兜底：用户长时间不响应自动拒绝，避免Agent流挂死
    final timer = Timer(const Duration(seconds: 180), () {
      if (!completer.isCompleted) {
        completer.complete(ToolApprovalDecision.deny);
      }
    });

    try {
      return await completer.future;
    } finally {
      timer.cancel();
      _pendingApproval = null;
      _approvalCompleter = null;
      if (!_disposed) notifyListeners();
    }
  }

  /// 允许本次调用
  /// [alwaysForSession] 同时信任该规则键本次会话内的后续调用
  /// (MCP=整个server；内置shell=同首词命令族，如允许过npm test则npm *放行)
  void approveToolCall({bool alwaysForSession = false}) {
    final completer = _approvalCompleter;
    if (completer == null || completer.isCompleted) return;
    final request = _pendingApproval;
    if (alwaysForSession && request != null) {
      _sessionAllowedKeys.add(request.sessionAllowKey);
    }
    completer.complete(ToolApprovalDecision.allow);
  }

  /// 拒绝本次调用(回填拒绝文本给模型，由其自行调整)
  void denyToolCall() {
    final completer = _approvalCompleter;
    if (completer == null || completer.isCompleted) return;
    completer.complete(ToolApprovalDecision.deny);
  }

  /// ******************************************
  /// 外观设置(文字大小/背景/字体颜色/简洁显示)
  /// 从旧版branch_chat移植，存储key与旧版共用
  /// ******************************************

  /// 加载外观设置(GetStorage同步读，失败不影响主流程)
  Future<void> loadAppearanceSettings() async {
    try {
      final storage = CusGetStorage();
      _textScaleFactor = storage.getChatMessageTextScale();
      _globalBackgroundImage = await storage.getBranchChatBackground();
      _globalBackgroundOpacity =
          await storage.getBranchChatBackgroundOpacity() ?? 0.2;
      _messageFontColor = await storage.loadMessageFontColor();
      _isBriefDisplay = storage.getUnifiedChatBriefDisplay();
      _checkAppearanceCache();
      notifyListeners();
    } catch (e) {
      debugPrint('加载聊天外观设置失败: $e');
    }
  }

  /// 外观指纹变化检查(背景含搭档专属背景优先级/字体颜色)：
  /// Markdown渲染器按"文本内容"缓存Widget(不含颜色)，
  /// 生效背景或颜色变化后必须清缓存，否则仍渲染旧颜色的缓存Widget
  void _checkAppearanceCache() {
    final signature = '${backgroundImage ?? ''}|${_messageFontColor.hashCode}';
    if (_lastAppearanceSignature != null &&
        _lastAppearanceSignature != signature) {
      CusMarkdownRenderer.instance.clearCache();
    }
    _lastAppearanceSignature = signature;
  }

  /// 设置消息文字缩放比例并持久化
  Future<void> setTextScale(double value) async {
    _textScaleFactor = value;
    notifyListeners();
    await CusGetStorage().setChatMessageTextScale(value);
  }

  /// 切换简洁显示并持久化(旧版仅内存态不持久化，新版修复)
  Future<void> toggleBriefDisplay([bool? value]) async {
    _isBriefDisplay = value ?? !_isBriefDisplay;
    notifyListeners();
    await CusGetStorage().setUnifiedChatBriefDisplay(_isBriefDisplay);
  }

  /// 从背景选择页返回后重载背景与字体颜色配置
  Future<void> refreshBackgroundSettings() async {
    await loadAppearanceSettings();
  }

  /// ******************************************
  /// 对话管理
  /// ******************************************

  /// 加载最近对话或创建新对话
  Future<void> _loadRecentConversationOrCreateNew() async {
    try {
      // 获取最近的对话（只需要最后一条，加快查询速度）
      final conversations = await _chatDao.getConversations(
        pageSize: 1,
        pageNumber: 0,
      );

      if (conversations.isNotEmpty) {
        final lastConversation = conversations.first;
        final today = DateTime.now();
        final conversationDate = lastConversation.updatedAt;

        // 判断最后对话是否是今天的
        final isToday =
            conversationDate.year == today.year &&
            conversationDate.month == today.month &&
            conversationDate.day == today.day;

        if (isToday) {
          // 加载今天的最后对话
          await loadConversation(lastConversation.id);
          return;
        } else {
          // 如果不是今天的对话，加载最后使用的模型
          await _loadLastUsedModel(lastConversation.id);
        }
      }

      // 如果没有今天的对话，创建新对话
      createNewConversation();
    } catch (e) {
      ToastUtils.showError('加载最近对话失败: $e');
      await _setDefaultPlatformAndModel();
      createNewConversation();
    }
  }

  /// 加载最后使用的模型
  Future<void> _loadLastUsedModel(String conversationId) async {
    final messages = await _chatDao.getMessagesByConversationId(conversationId);
    if (messages.isNotEmpty) {
      // 从最后的消息中获取使用的模型
      final lastMessage = messages.last;

      if (lastMessage.modelNameUsed != null) {
        final lastUsedModel = _availableModels
            .cast<UnifiedModelSpec?>()
            .firstWhere(
              (model) => model?.id == lastMessage.modelNameUsed,
              orElse: () => null,
            );

        if (lastUsedModel != null) {
          _currentModel = lastUsedModel;
          final matchingPlatform = _availablePlatforms
              .cast<UnifiedPlatformSpec?>()
              .firstWhere(
                (platform) => platform?.id == lastUsedModel.platformId,
                orElse: () => null,
              );
          if (matchingPlatform != null) {
            _currentPlatform = matchingPlatform;
          }
        }
      }
    }
  }

  /// 设置默认平台和模型
  Future<void> _setDefaultPlatformAndModel() async {
    if (_availablePlatforms.isNotEmpty && _availableModels.isNotEmpty) {
      _currentPlatform = _availablePlatforms.first;
      _currentModel = _availableModels.first;
    }
  }

  /// 创建新对话（临时，不立即保存到数据库）
  void createNewConversation({String? title, String? systemPrompt}) {
    try {
      final conversationId = const Uuid().v4();
      _currentConversation = UnifiedConversation(
        id: conversationId,
        title: title ?? '新对话',
        modelId: _currentModel?.id ?? '',
        platformId: _currentPlatform?.id ?? '',
        // 如果没有指定系统提示词，使用默认搭档的提示词
        systemPrompt: systemPrompt ?? defaultPartner.prompt,
        // 2026-09-09 参数未显式设置时保持null(不传→平台API默认值)
        temperature: defaultPartner.temperature,
        topP: defaultPartner.topP,
        maxTokens: defaultPartner.maxTokens,
        contextMessageLength: defaultPartner.contextMessageLength,
        isStream: defaultPartner.isStream ?? true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 初始化空的消息列表，不添加任何消息
      _messages = [];
      _allMessages = [];
      _currentBranchPath = null;
      _displayTruncateId = null;
      // 重置搭档选择状态，以便在新对话时重新显示搭档工具组件
      _currentPartner = null;
      _isPartnerSelected = false;

      // 创建新对话了要清空搜索参考
      _chatService.clearLastSearchReferences();
      notifyListeners();
    } catch (e) {
      _setError('创建新对话失败: $e');
    }
  }

  ///初始化时（即在用户首次发送消息时）保存对话到数据库
  Future<void> _initSaveConversation(String userMessage) async {
    if (_currentConversation == null) return;

    try {
      // 检查对话是否已经存在于数据库中
      final existingConversation = await _chatDao.getConversation(
        _currentConversation!.id,
      );

      // 已存在，无需保存
      if (existingConversation != null) return;

      // 生成对话标题
      final conversationTitle = _generateConversationTitle(userMessage);

      // 更新对话标题并保存
      final updatedConversation = _currentConversation!.copyWith(
        title: conversationTitle,
      );
      await _chatDao.saveConversation(updatedConversation);
      _currentConversation = updatedConversation;

      // 保存系统消息（如果有）
      for (final message in _messages) {
        if (message.role == UnifiedMessageRole.system) {
          await _chatDao.saveMessage(message);
        }
      }
    } catch (e) {
      ToastUtils.showError('保存对话失败: $e');
    }
  }

  /// 生成对话标题
  String _generateConversationTitle(String userMessage) {
    // 如果选择了搭档，使用"搭档名称+用户消息"作为标题
    if (_currentPartner != null && _isPartnerSelected) {
      final userMessagePart = userMessage.length > 20
          ? userMessage.substring(0, 20)
          : userMessage;
      return '${_currentPartner!.name}: $userMessagePart';
    } else {
      // 使用默认助手时，直接使用用户消息作为标题
      return userMessage.length > 30
          ? userMessage.substring(0, 30)
          : userMessage;
    }
  }

  /// 加载现有对话
  Future<void> loadConversation(String conversationId) async {
    _setLoading(true);

    try {
      _currentConversation = await _chatDao.getConversation(conversationId);
      if (_currentConversation != null) {
        // 加载会话全部消息(含所有分支)
        _allMessages = await _chatDao.getMessagesByConversationId(
          _currentConversation!.id,
        );

        // 2026-09-15 切换会话流式修复：该会话若有进行中的流式消息
        // (发送后切走、流继续在闭包对象上累积)，用内存实时对象替换/
        // 追加进刚加载的列表——切回即可看到实时进度并继续刷新
        final active = _activeStreamingMessages[_currentConversation!.id];
        if (active != null) {
          final idx = _allMessages.indexWhere((m) => m.id == active.id);
          if (idx != -1) {
            _allMessages[idx] = active;
          } else {
            _allMessages.add(active);
          }
        }

        // 确定当前分支路径：优先使用会话保存的路径，无效则回退默认最新链
        _currentBranchPath = _currentConversation!.currentBranchPath;
        _displayTruncateId = null;
        _rebuildDisplayMessages();

        // 更新当前模型(没有可用模型时跳过，比如恢复数据后尚未配置AK，仍可只读查看历史)
        if (_availableModels.isNotEmpty) {
          final modelId = _currentConversation!.modelId;
          _currentModel = _availableModels.firstWhere(
            (m) => m.id == modelId,
            orElse: () => _availableModels.first,
          );
          if (_availablePlatforms.isNotEmpty) {
            _currentPlatform = _availablePlatforms.firstWhere(
              (p) => p.id == _currentModel!.platformId,
              orElse: () => _availablePlatforms.first,
            );
          }
        }

        // 恢复会话关联的搭档(2026-08-31 搭档专属背景/选中态；不存在则忽略)
        final partnerId = _currentConversation!.partnerId;
        if (partnerId != null && partnerId.isNotEmpty) {
          final partner = await _chatDao.getChatPartner(partnerId);
          _currentPartner = partner;
          _isPartnerSelected = partner != null;
        } else {
          _currentPartner = null;
          _isPartnerSelected = false;
        }

        // 搭档专属背景可能生效，检查外观缓存
        _checkAppearanceCache();

        // 恢复未完成的视频生成任务(任务态持久化在消息metadata，重进对话续查)
        _resumeUnfinishedVideoTasks();

        // 2026-09-09 未手动切换过联网开关时，跟随会话模型的能力自动开关
        _syncWebSearchWithCapability();

        // 2026-09-11 MCP集成(P1-3)：加载会话级MCP工具开关(无记录默认关)
        _isMcpEnabled = await UnifiedSecureStorage.getConversationMcpEnabled(
          _currentConversation!.id,
        );
      }
      _clearError();
    } catch (e) {
      _setError('加载对话失败: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 根据当前分支路径重建显示消息列表
  /// _messages = system消息置顶 + 当前分支视图
  void _rebuildDisplayMessages() {
    final systemMessages =
        _allMessages.where((m) => m.role == UnifiedMessageRole.system).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    var branchView = UnifiedBranchUtils.computeDisplayMessages(
      _allMessages,
      _currentBranchPath,
    );

    // 截断处理：重新生成/编辑场景下，视图只显示到指定消息为止
    if (_displayTruncateId != null) {
      final idx = branchView.indexWhere((m) => m.id == _displayTruncateId);
      if (idx != -1) {
        branchView = branchView.sublist(0, idx + 1);
      }
    }

    _messages = [...systemMessages, ...branchView];
  }

  /// ******************************************
  /// 分支管理
  /// ******************************************

  /// 切换分支(切到指定分支路径)
  Future<void> switchBranch(String targetPath) async {
    if (_currentConversation == null) return;
    if (_isStreaming) {
      ToastUtils.showToast('正在生成中，无法切换分支');
      return;
    }

    _currentBranchPath = targetPath;
    _displayTruncateId = null;
    _rebuildDisplayMessages();

    // 持久化当前分支路径，下次进入会话时恢复
    try {
      await _chatDao.updateConversationBranchPath(
        _currentConversation!.id,
        targetPath,
      );
    } catch (e) {
      // 持久化失败不影响本次切换
      debugPrint('保存当前分支路径失败: $e');
    }

    notifyListeners();
  }

  /// 获取指定消息的分支切换信息：兄弟列表 + 当前位置
  /// 供UI的分支切换器使用；返回null表示无分支信息
  ({List<UnifiedChatMessage> siblings, int currentIndex})? getBranchSwitchInfo(
    UnifiedChatMessage message,
  ) {
    final siblings = UnifiedBranchUtils.siblingsOf(_allMessages, message);
    final index = siblings.indexWhere((m) => m.id == message.id);
    if (index == -1 || siblings.length <= 1) return null;
    return (siblings: siblings, currentIndex: index);
  }

  /// 切换到指定消息的相邻分支(offset为-1或1)
  Future<void> switchToSiblingBranch(
    UnifiedChatMessage message,
    int offset,
  ) async {
    final info = getBranchSwitchInfo(message);
    if (info == null) return;

    final targetIndex = info.currentIndex + offset;
    if (targetIndex < 0 || targetIndex >= info.siblings.length) return;

    await switchBranch(info.siblings[targetIndex].branchPath);
  }

  /// 计算新子消息的分支信息
  /// [parent] 父消息(为null表示根级)；[role] 新消息角色
  /// 返回(branchIndex, depth, branchPath)
  ({int branchIndex, int depth, String branchPath}) _branchInfoForNewChild(
    UnifiedChatMessage? parent,
    UnifiedMessageRole role,
  ) {
    final parentId = parent?.id;
    final siblings = _allMessages
        .where((m) => !m.isSystem && m.parentId == parentId && m.role == role)
        .toList();
    final newIndex = siblings.isEmpty
        ? 0
        : siblings.map((m) => m.branchIndex).reduce((a, b) => a > b ? a : b) +
              1;

    final depth = parent == null ? 0 : parent.depth + 1;
    final path = parent == null
        ? '$newIndex'
        : '${parent.branchPath}/$newIndex';

    return (branchIndex: newIndex, depth: depth, branchPath: path);
  }

  /// 获取当前显示列表中最后一条非system消息(即当前分支的叶子，作为新消息的父节点)
  UnifiedChatMessage? get _lastNonSystemMessage {
    final list = _messages.where((m) => !m.isSystem).toList();
    return list.isEmpty ? null : list.last;
  }

  /// 清空对话
  Future<void> clearConversation() async {
    if (_currentConversation == null) return;

    try {
      // 直接删除该会话全部消息(分支化后一个会话可能有很多分支消息，逐条删除太慢)
      await _chatDao.deleteMessagesByConversationId(_currentConversation!.id);
      _allMessages = [];
      _currentBranchPath = null;
      _messages = [];
      await _updateConversationStats();
      notifyListeners();
    } catch (e) {
      _setError('清空对话失败: $e');
    }
  }

  /// 导出对话
  Future<String?> exportConversation() async {
    if (_currentConversation == null || _messages.isEmpty) return null;

    try {
      final directory = await getUnifiedChatBackupDir();

      final fileName =
          '${_currentConversation!.title}_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${directory.path}/${sanitizeFileName(fileName)}');

      final buffer = StringBuffer();
      buffer.writeln('对话标题: ${_currentConversation!.title}');
      buffer.writeln('创建时间: ${_currentConversation!.createdAt}');
      buffer.writeln('模型: ${_currentModel?.displayName ?? 'Unknown'}');
      buffer.writeln('消息数量: ${_messages.length}');
      buffer.writeln('总花费token: ${_currentConversation!.totalTokens}');
      buffer.writeln('=' * 50);
      buffer.writeln();

      for (final message in _messages) {
        buffer.writeln('${message.role.displayName} (${message.timestamp}):');
        buffer.writeln(
          message.thinkingContent != null
              ? '【思考内容】\n${message.thinkingContent}'
              : '',
        );
        buffer.writeln('【常规内容】\n${message.content}');
        buffer.writeln();
      }

      await file.writeAsString(buffer.toString());
      return file.path;
    } catch (e) {
      _setError('导出失败: $e');
      rethrow;
    }
  }

  /// 更新对话设置
  /// extraParams 类配置采用合并式更新：只覆盖传入的键(含显式传null清空)，
  /// 未传入的键保留原值，避免各设置弹窗互相覆盖丢失配置
  Future<void> updateConversationSettings(Map<String, dynamic> settings) async {
    if (_currentConversation == null) return;

    try {
      final oldSystemPrompt = _currentConversation!.systemPrompt;
      final newSystemPrompt = settings['systemPrompt'] as String?;

      final newExtraParams = Map<String, dynamic>.from(
        _currentConversation!.extraParams ?? {},
      );
      for (final key in const [
        'enableThinking',
        'omniParams',
        'imageGenerationParams',
        'videoGenerationParams',
        'speechSynthesisParams',
        'speechRecognitionParams',
        'customRequestParams',
      ]) {
        if (settings.containsKey(key)) {
          newExtraParams[key] = settings[key];
        }
      }

      var updated = _currentConversation!.copyWith(
        title: settings['title'] as String?,
        systemPrompt: newSystemPrompt,
        contextMessageLength: settings['contextMessageLength'] as int?,
        temperature: settings['temperature'] as double?,
        topP: settings['topP'] as double?,
        maxTokens: settings['maxTokens'] as int?,
        isStream: settings['isStream'] as bool?,
        frequencyPenalty: settings['frequencyPenalty'] as double?,
        presencePenalty: settings['presencePenalty'] as double?,
        extraParams: newExtraParams,
        updatedAt: DateTime.now(),
      );

      // 2026-09-09 "上下文消息数=不限制"为null：copyWith无法写null，
      // 显式传入该键时经Map绕行写入(含清空为null)
      if (settings.containsKey('contextMessageLength')) {
        final convMap = updated.toMap();
        convMap['context_message_length'] =
            settings['contextMessageLength'] as int?;
        updated = UnifiedConversation.fromMap(convMap);
      }

      _currentConversation = updated;

      // 如果系统提示词发生变化，更新对应的系统消息
      if (oldSystemPrompt != newSystemPrompt) {
        await _updateSystemMessage(newSystemPrompt);
      }

      await _chatDao.updateConversation(_currentConversation!);
      notifyListeners();
    } catch (e) {
      _setError('更新设置失败: $e');
      debugPrint(e.toString());
    }
  }

  /// 更新对话统计信息
  /// 更新会话统计(消息数/token/花费)
  /// 2026-09-15 切换会话流式修复：支持指定会话id并从DB重算——原实现
  /// 只按当前内存视图统计，发送后切走会话时统计被跳过或算错会话
  /// (列表页"0条消息"的成因之一)。默认统计当前会话，行为兼容旧调用
  Future<void> _updateConversationStats({String? conversationId}) async {
    final targetId = conversationId ?? _currentConversation?.id;
    if (targetId == null) return;

    // 从DB重算：不依赖当前内存视图(切走后视图是别的会话的)
    final msgs = await _chatDao.getMessagesByConversationId(targetId);
    final conv = await _chatDao.getConversation(targetId);
    if (conv == null) return;

    final updated = conv.copyWith(
      messageCount: msgs.length,
      totalTokens: msgs.fold<int>(0, (sum, msg) => sum + msg.tokens),
      totalCost: msgs.fold<double>(0, (sum, msg) => sum + msg.cost),
      updatedAt: DateTime.now(),
    );

    await _chatDao.updateConversation(updated);

    // 目标正是当前会话时同步内存引用
    if (targetId == _currentConversation?.id) {
      _currentConversation = updated;
    }
  }

  /// ******************************************
  /// 消息处理
  /// ******************************************

  /// 发送文本消息
  Future<void> sendMessage(String content, {bool isWebSearch = false}) async {
    if (content.trim().isEmpty || _currentConversation == null) return;
    if (_currentModel == null || _currentPlatform == null) {
      ToastUtils.showToast('没有可用的平台和模型，请先配置API Key');
      return;
    }

    try {
      // 如果是第一条用户消息，先创建并保存系统消息
      if (_messages.isEmpty) {
        await _initSaveConversation(content.trim());

        await _createAndSaveSystemMessageIfNeeded();
      }

      // 添加用户消息
      final userMessage = _createUserPlaceholder(content.trim());

      await _addAndSaveMessage(userMessage);
      notifyListeners();

      // 发送消息并处理响应回复
      await _sendMessageToAI(
        _messages.where((m) => !m.isStreaming).toList(),
        isWebSearch: isWebSearch,
      );
    } catch (e) {
      _setError('发送消息失败: $e');
    }
  }

  /// 发送多模态消息
  Future<void> sendMultimodalMessage(
    String text, {
    List<File>? images,
    File? audio,
    File? video,
    List<File>? files,
    bool isWebSearch = false,
  }) async {
    if (_currentConversation == null) return;
    if (_currentModel == null || _currentPlatform == null) {
      ToastUtils.showToast('没有可用的平台和模型，请先配置API Key');
      return;
    }

    // print("发送多模态消息");
    // print("文本: $text");
    // print("图片: ${images?.map((f) => f.path).join(', ')}");
    // print("音频: ${audio?.path}");
    // print("视频: ${video?.path}");
    // print("文件: ${files?.map((f) => f.path).join(', ')}");

    try {
      // 如果是第一条用户消息，先创建并保存系统消息
      if (_messages.isEmpty) {
        await _initSaveConversation(
          text.trim().isNotEmpty ? text.trim() : '多模态消息',
        );
        await _createAndSaveSystemMessageIfNeeded();
      }

      // 构建多模态内容列表
      final multimodalContent = await _buildMultimodalContent(
        text: text.trim(),
        images: images,
        audio: audio,
        video: video,
        files: files,
      );

      // 构建多模态的用户消息
      final userMessage = _createUserPlaceholder(
        text.trim().isNotEmpty ? text.trim() : '多模态消息',
        contentType: UnifiedContentType.multimodal,
        multimodalContent: multimodalContent,
        metadata: {
          'model': _currentModel,
          'platform': _currentPlatform,
          if (images != null && images.isNotEmpty)
            'images': images.map((f) => f.path).toList(),
          if (audio != null) 'audio': audio.path,
          if (video != null) 'video': video.path,
          if (files != null && files.isNotEmpty)
            'files': files.map((f) => f.path).toList(),
        },
      );

      _messages.add(userMessage);
      _allMessages.add(userMessage);
      await _chatDao.saveMessage(userMessage);
      notifyListeners();

      await _sendMessageToAI(
        _messages.where((m) => !m.isStreaming).toList(),
        isWebSearch: isWebSearch,
      );
    } catch (e) {
      _setError('发送多模态消息失败: $e');
      rethrow;
    }
  }

  /// 构建多模态内容
  Future<List<UnifiedContentItem>> _buildMultimodalContent({
    String? text,
    List<File>? images,
    File? audio,
    File? video,
    List<File>? files,
  }) async {
    final multimodalContent = <UnifiedContentItem>[];

    // 添加文本内容
    if (text?.isNotEmpty ?? false) {
      multimodalContent.add(UnifiedContentItem.text(text!));
    }

    // 添加图片内容
    if (images != null && images.isNotEmpty) {
      for (final image in images) {
        multimodalContent.add(
          UnifiedContentItem.image(image.path, detail: 'auto'),
        );
      }
    }

    // 添加音频内容
    if (audio != null) {
      multimodalContent.add(
        UnifiedContentItem.audio(
          audio.path,
          fileName: audio.path.split('/').last,
          fileSize: await getFileSize(audio),
        ),
      );
    }

    // 添加视频内容
    if (video != null) {
      multimodalContent.add(
        UnifiedContentItem.video(
          video.path,
          fileName: video.path.split('/').last,
          fileSize: await getFileSize(video),
        ),
      );
    }

    // 添加文件内容
    if (files != null && files.isNotEmpty) {
      for (final file in files) {
        multimodalContent.add(
          UnifiedContentItem.file(
            file.path,
            file.path.split('/').last,
            fileSize: await getFileSize(file),
            mimeType: getMimeTypeByFilePath(file.path),
          ),
        );
      }
    }

    return multimodalContent;
  }

  /// 发送消息到AI并处理回复
  Future<void> _sendMessageToAI(
    List<UnifiedChatMessage> messages, {
    bool isWebSearch = false,
  }) async {
    if (_currentConversation == null || _currentModel == null) return;

    // 发送请求前不应该保留之前的参考内容
    _chatService.clearLastSearchReferences();
    _setStreaming(true);
    // 2026-09-15 切换会话流式修复：登记流式会话与消息对象——
    // 切走后流继续在对象上累积，切回时挂回；完成时无条件落库
    _streamingConversationId = _currentConversation!.id;

    try {
      final messagesToSend = _prepareMessagesForSending(messages);
      final assistantMessage = _createAssistantPlaceholder();

      _allMessages.add(assistantMessage);
      _messages.add(assistantMessage);
      _activeStreamingMessages[assistantMessage.conversationId] =
          assistantMessage;
      // 占位已挂载到截断视图末端，之后恢复正常分支视图(不再截断)
      _displayTruncateId = null;
      notifyListeners();

      final stream = _chatService.sendMessage(
        conversationId: _currentConversation!.id,
        messages: messagesToSend,
        modelId: _currentModel!.id,
        platformId: _currentPlatform!.id,
        // 注意，用户在对话设置页面修改的对话设置，是保存到当前对话中的，所以发送时从此处获取
        stream:
            _currentConversation?.isStream ??
            (_currentPartner ?? defaultPartner).isStream ??
            true,
        isWebSearch: isWebSearch && _isWebSearchEnabled,
        // 2026-09-11 MCP集成(P1-3)：会话开关状态传给服务层
        isMcpEnabled: _isMcpEnabled,
        // 2026-09-14 P3-11 内置终端命令工具全局开关
        isShellToolEnabled: isShellToolEnabled,
      );

      await _handleStreamResponse(stream, assistantMessage, isWebSearch);
    } catch (e) {
      _handleMessageSendError(e);
    }
  }

  /// 准备发送的消息列表
  List<UnifiedChatMessage> _prepareMessagesForSending(
    List<UnifiedChatMessage> messages,
  ) {
    // 准备发送的消息列表，根据 contextMessageLength 限制消息数量
    List<UnifiedChatMessage> messagesToSend = List.from(messages);

    // 应用上下文消息列表长度限制
    // 2026-09-09 null=不限制(携带全部历史，避免记忆丢失)；
    // 0=仅携带最新一条消息("每次都是最新的")；正数=保留最近N条(含系统消息豁免)
    final contextMessageLength = _currentConversation!.contextMessageLength;
    if (contextMessageLength != null &&
        messagesToSend.length > contextMessageLength) {
      // 保留最近的 contextMessageLength 条消息，但保留系统消息
      final systemMessages = messagesToSend
          .where((m) => m.role == UnifiedMessageRole.system)
          .toList();
      final nonSystemMessages = messagesToSend
          .where((m) => m.role != UnifiedMessageRole.system)
          .toList();

      // 取最近的消息(配额至少为1，避免0配置时出现负数越界)
      final quota = contextMessageLength - systemMessages.length;
      if (quota <= 0) {
        // 上下文配额全被系统消息占用(或为0)：仅保留系统消息与最新一条消息
        messagesToSend = [...systemMessages, nonSystemMessages.last];
      } else if (nonSystemMessages.length > quota) {
        messagesToSend = [
          ...systemMessages,
          ...nonSystemMessages.sublist(nonSystemMessages.length - quota),
        ];
      }
    }

    // 验证并修复消息序列
    // 注意：不要在这里清除搭档选择状态，保持搭档信息在整个对话期间可用
    return _validateAndFixMessageSequence(messagesToSend);
  }

  /// 创建用户消息
  /// [parentIsExplicit] 2026-09-07 编辑消息场景：显式指定父节点(含根级)——
  /// 原(被编辑)消息为根级(parentId==null)时新消息也应挂根级成为新根分支，
  /// 不允许回退到当前分支叶子(fallback仅用于常规发送的追加场景)。
  /// 此前编辑根级用户消息时parent=null被误判为常规发送，新消息挂到
  /// 当前分支叶子之后，表现为"消息列表最后新加一轮对话"而非新建分支
  UnifiedChatMessage _createUserPlaceholder(
    String content, {
    UnifiedContentType? contentType,
    List<UnifiedContentItem>? multimodalContent,
    Map<String, dynamic>? metadata,
    UnifiedChatMessage? parent,
    bool parentIsExplicit = false,
  }) {
    // 计算分支信息：常规发送默认父节点为当前分支视图的最后一条非system消息
    final parentNode =
        parent ?? (parentIsExplicit ? null : _lastNonSystemMessage);
    final branch = _branchInfoForNewChild(parentNode, UnifiedMessageRole.user);

    return UnifiedChatMessage(
      // 2026-08-31 改用UUID，避免毫秒时间戳id可能出现的同毫秒冲突
      id: const Uuid().v4(),
      conversationId: _currentConversation!.id,
      role: UnifiedMessageRole.user,
      content: content.trim(),
      contentType: contentType ?? UnifiedContentType.text,
      multimodalContent: multimodalContent,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      modelNameUsed: _currentModel!.modelName,
      platformIdUsed: _currentPlatform!.id,
      metadata:
          metadata ?? {'model': _currentModel, 'platform': _currentPlatform},
      parentId: parentNode?.id,
      branchIndex: branch.branchIndex,
      depth: branch.depth,
      branchPath: branch.branchPath,
    );
  }

  /// 创建助手消息占位符
  UnifiedChatMessage _createAssistantPlaceholder({String? content}) {
    // 父节点为当前分支视图的最后一条非system消息(即刚发送的用户消息)
    final parentNode = _lastNonSystemMessage;
    final branch = _branchInfoForNewChild(
      parentNode,
      UnifiedMessageRole.assistant,
    );

    return UnifiedChatMessage(
      id: const Uuid().v4(),
      conversationId: _currentConversation!.id,
      role: UnifiedMessageRole.assistant,
      content: content,
      thinkingContent: '',
      contentType: UnifiedContentType.text,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isStreaming: true,
      modelNameUsed: _currentModel?.modelName,
      platformIdUsed: _currentPlatform?.id,
      metadata: {'model': _currentModel, 'platform': _currentPlatform},
      parentId: parentNode?.id,
      branchIndex: branch.branchIndex,
      depth: branch.depth,
      branchPath: branch.branchPath,
    );
  }

  /// 创建系统消息占位符(系统消息不入分支树)
  UnifiedChatMessage _createSystemPlaceholder(String content) {
    return UnifiedChatMessage(
      id: 'system_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: _currentConversation!.id,
      role: UnifiedMessageRole.system,
      content: content,
      contentType: UnifiedContentType.text,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      cost: 0.0,
      modelNameUsed: _currentModel?.modelName,
      platformIdUsed: _currentPlatform?.id,
      metadata: {'model': _currentModel, 'platform': _currentPlatform},
      depth: -1,
      branchPath: '',
    );
  }

  /// 添加消息到内存列表并保存到数据库
  /// 用户/助手消息同时加入全量列表，并刷新当前分支视图
  Future<void> _addAndSaveMessage(UnifiedChatMessage message) async {
    _allMessages.add(message);
    _rebuildDisplayMessages();
    await _chatDao.saveMessage(message);
  }

  /// 在内存两个列表中按id原位替换消息(流式更新/手动修改消息用)
  void _updateMessageInLists(UnifiedChatMessage message) {
    final idxMsg = _messages.indexWhere((m) => m.id == message.id);
    if (idxMsg != -1) _messages[idxMsg] = message;
    final idxAll = _allMessages.indexWhere((m) => m.id == message.id);
    if (idxAll != -1) _allMessages[idxAll] = message;
  }

  /// 处理流式响应
  /// 2026-09-12 P3-10 分段重构：多轮工具调用的一次完整响应包含多段
  /// "思考→正文→工具调用"交替，改用segments列表按序累积，气泡内
  /// 分段渲染(对齐opencode形态)；旧字段thinkingContent/content仍同步
  /// 写入作为未分段消费方的兜底
  Future<void> _handleStreamResponse(
    Stream<OpenAIChatCompletionResponse> stream,
    UnifiedChatMessage assistantMessage,
    bool isWebSearch,
  ) async {
    // 新流监听开始，复位手动停止标志(上一次停止的标记不应影响本次)
    _manualStopRequested = false;

    // 2026-09-15 切换会话流式修复：流式期间的"真实消息"是闭包持有的
    // streamMsg(每次更新产生新对象并回写活跃Map)。原实现所有更新都从
    // _messages按id反查——切换会话后_messages换成别的会话的列表，
    // 反查必然-1，chunk被整体丢弃、完成时也不落库，回复永久丢失。
    // 现在更新只依赖对象本身；是否刷UI由commitStream判断
    var streamMsg = assistantMessage;

    // 提交流式消息：同步回活跃Map(切回会话挂回的是最新对象)；
    // 仅当该消息还在当前会话视图里时才更新列表并通知刷新——
    // 用户已切到其他会话时只累积不刷UI。
    // 2026-09-15 手动停止竞态修复：点STOP时可能有chunk正挂在async点
    // (finishReason落库/工具哨兵处理中)，它恢复后会用旧streamMsg
    // (isStreaming仍为true)回写——把stopStreaming刚写入的[手动终止]
    // 状态覆盖掉，UI残留"生成中"。停止后禁止一切回写
    void commitStream() {
      if (_manualStopRequested) return;
      _activeStreamingMessages[streamMsg.conversationId] = streamMsg;
      if (streamMsg.conversationId == _currentConversation?.id &&
          _messages.any((m) => m.id == streamMsg.id)) {
        _updateMessageInLists(streamMsg);
        notifyListeners();
      }
    }

    // ===== 分段状态 =====
    final segments = <MessageSegment>[];
    // 最后一个正文段的真实累积(打字机追赶目标)
    String currentTextFull = '';
    // 最后一个正文段的打字机已显示值
    String currentTextDisplayed = '';
    // 轮结束(finishReason/工具哨兵)后强制下个chunk开新段
    var forceNewSegment = false;

    // 多模态内容列表
    final multimodalContent = <UnifiedContentItem>[];
    // 2025-10-16 多模态千问omni可以合成语音，响应中有base64语音片段
    // 在流响应完成或者手动终止时，才把已经收集到的片段转为语音，再提供播放
    String finalAudioBase64 = "";
    // 是否在思考中(content内嵌<think>标签的思考模式)
    bool isInThinking = false;
    // 开始思考时间
    var startTime = DateTime.now();
    // 结束思考时间
    DateTime? endTime;
    // 思考时长
    var thinkingTime = 0;

    // ===== 打字机平滑(只作用于最后一个正文段) =====
    Timer? typewriterTimer;
    void stopTypewriter() {
      typewriterTimer?.cancel();
      typewriterTimer = null;
    }

    void typewriterTick() {
      // 2026-09-15 手动停止后终止打字机：subscription已cancel，onDone/
      // onError不会到达来调stopTypewriter——timer会一直空转泄漏
      if (_manualStopRequested) {
        stopTypewriter();
        return;
      }
      if (currentTextDisplayed.length >= currentTextFull.length) {
        stopTypewriter();
        return;
      }
      // 每tick追加 max(2, 剩余的1/25)：长文追赶快、尾部平滑
      final remaining = currentTextFull.length - currentTextDisplayed.length;
      final step = remaining > 50 ? (remaining / 25).ceil() : 2;
      var end = currentTextDisplayed.length + step;
      if (end > currentTextFull.length) end = currentTextFull.length;
      // 2026-09-14 UTF-16代理对保护：substring按code unit切，截断点落在
      // emoji等代理对中间会产生孤立代理项，TextSpan渲染直接抛
      // "string is not well-formed UTF-16"(实测崩溃)。末尾若是未配对的
      // 高代理则回退一位，把完整代理对留给下一tick
      if (end > currentTextDisplayed.length && end < currentTextFull.length) {
        final lastUnit = currentTextFull.codeUnitAt(end - 1);
        if (lastUnit >= 0xD800 && lastUnit <= 0xDBFF) end--;
      }
      currentTextDisplayed = currentTextFull.substring(0, end);

      final lastIdx = segments.lastIndexWhere(
        (s) => s.type == MessageSegmentType.text,
      );
      if (lastIdx != -1) {
        segments[lastIdx] = MessageSegment.textSeg(currentTextDisplayed);
      }

      streamMsg = streamMsg.copyWith(
        segments: List.of(segments),
        content: currentTextDisplayed,
        updatedAt: DateTime.now(),
      );
      commitStream();
    }

    void ensureTypewriterRunning() {
      typewriterTimer ??= Timer.periodic(
        const Duration(milliseconds: 40),
        (_) => typewriterTick(),
      );
    }

    /// 固化最后一个思考段的用时(未固化过才写，取该段开始到现在的时长)
    void sealPreviousThinkingTime() {
      for (var i = segments.length - 1; i >= 0; i--) {
        if (segments[i].type == MessageSegmentType.thinking) {
          if (segments[i].thinkingTime == null) {
            final now = DateTime.now();
            segments[i] = MessageSegment.thinking(
              segments[i].text ?? '',
              thinkingTime: now.difference(startTime).inMilliseconds,
            );
          }
          return;
        }
      }
    }

    void appendThinking(String s) {
      final lastIdx = segments.isEmpty ? -1 : segments.length - 1;
      if (!forceNewSegment &&
          lastIdx >= 0 &&
          segments[lastIdx].type == MessageSegmentType.thinking) {
        segments[lastIdx] = MessageSegment.thinking(
          (segments[lastIdx].text ?? '') + s,
          thinkingTime: segments[lastIdx].thinkingTime,
        );
      } else {
        // 2026-09-13 思考段用时修复：开新思考段前固化上一段的用时并
        // 重置本轮计时——多轮工具调用的中间轮可能没有正文(直接tool_calls
        // 结束)，此前只在正文chunk时固化，导致前几轮思考用时全为0、
        // 且startTime跨轮未重置使最终轮记成总时长
        sealPreviousThinkingTime();
        startTime = DateTime.now();
        endTime = null;
        thinkingTime = 0;
        segments.add(MessageSegment.thinking(s));
        forceNewSegment = false;
      }
    }

    // 追加正文文本：最后一段是text且未封段则只更新full(显示由打字机
    // 推进，避免full/displayed交替闪烁)，否则开新正文段
    void appendText(String s) {
      final lastIdx = segments.isEmpty ? -1 : segments.length - 1;
      final isLastText =
          lastIdx >= 0 && segments[lastIdx].type == MessageSegmentType.text;
      if (!forceNewSegment && isLastText) {
        currentTextFull += s;
      } else {
        currentTextFull = s;
        currentTextDisplayed = '';
        segments.add(MessageSegment.textSeg(''));
        forceNewSegment = false;
      }
      ensureTypewriterRunning();
    }

    // 封当前正文段：显示值补齐到真实值(轮结束/工具哨兵时调用)
    void sealTextSegment() {
      final lastIdx = segments.lastIndexWhere(
        (s) => s.type == MessageSegmentType.text,
      );
      if (lastIdx != -1) {
        segments[lastIdx] = MessageSegment.textSeg(currentTextFull);
        currentTextDisplayed = currentTextFull;
      }
      stopTypewriter();
      forceNewSegment = true;
    }

    // 串行化+内联处理：pause/resume保证chunk顺序；直接读写闭包变量
    Future<void> handleChunk(OpenAIChatCompletionResponse response) async {
      // 工具调用哨兵(service在执行完工具后注入，携带结果与参数摘要)：
      // 封上一段+插入工具段(内嵌卡片可展开查看结果)
      if (response.toolInvoking != null) {
        sealTextSegment();
        // 哨兵前的思考段(无正文的中间轮)补固化用时
        sealPreviousThinkingTime();
        segments.add(
          MessageSegment.toolCallSeg(
            toolName: response.toolInvoking!,
            argsSummary: response.toolArgsSummary,
            result: response.toolResult,
            elapsedMs: response.toolElapsedMs,
          ),
        );

        streamMsg = streamMsg.copyWith(
          segments: List.of(segments),
          updatedAt: DateTime.now(),
        );
        commitStream();
        return;
      }

      // 2026-09-15 切换会话流式修复：原实现在此处按id反查_messages，
      // 切走后-1直接return丢弃chunk——现在更新基于streamMsg对象，
      // 无需反查(切走后commitStream只累积不刷UI)
      streamMsg = streamMsg.copyWith(updatedAt: DateTime.now());

      // 2026-09-14 usage统计帧：stream_options.include_usage开启时平台在
      // stop帧后发的choices:[]只带usage的chunk(此前被service终态防御误杀/
      // 此处也被choices.isNotEmpty跳过，双重丢弃导致消息不显示token消耗)——
      // 单独更新tokenCount/cost并落库(finishReason时已落库过，此处覆盖)
      if (response.choices.isEmpty && response.usage != null) {
        final usage = response.usage!;
        streamMsg = streamMsg.copyWith(
          tokenCount: usage.totalTokens,
          cost: _calculateCost(usage.totalTokens, _currentModel!),
          updatedAt: DateTime.now(),
        );
        // 手动停止后不再落库(防在途chunk把isStreaming=true中间态
        // 覆盖stopStreaming刚保存的[手动终止]终态)
        if (!_manualStopRequested) _chatDao.saveMessage(streamMsg);
        commitStream();
        return;
      }

      if (response.choices.isNotEmpty) {
        final choice = response.choices.first;
        // 如果非流式响应的内容放在message中，包装成一次流式响应。
        // delta和message结构一致，可以统一处理
        final delta = choice.delta ?? choice.message;

        // 处理单独推理内容
        if (delta != null &&
            delta.reasoningContent != null &&
            delta.reasoningContent!.isNotEmpty) {
          // 计时重置已移入appendThinking开新思考段时处理(每段独立计时)
          appendThinking(delta.reasoningContent!);
        }

        // 处理正常内容(含content内嵌<think>标签的思考模式)
        if (delta != null &&
            delta.content != null &&
            delta.content!.isNotEmpty) {
          final newContent = delta.content!;

          if (newContent.contains('<thinking>') ||
              newContent.contains('<think>')) {
            isInThinking = true;
            startTime = DateTime.now();
          }

          if (isInThinking) {
            appendThinking(newContent);
            if (newContent.contains('</thinking>') ||
                newContent.contains('</think>')) {
              isInThinking = false;
              // 清理思考段内的标记
              final lastIdx = segments.lastIndexWhere(
                (s) => s.type == MessageSegmentType.thinking,
              );
              if (lastIdx != -1) {
                final cleaned = (segments[lastIdx].text ?? '')
                    .replaceAll('<thinking>', '')
                    .replaceAll('</thinking>', '')
                    .replaceAll('<think>', '')
                    .replaceAll('</think>', '')
                    .trim();
                segments[lastIdx] = MessageSegment.thinking(
                  cleaned,
                  thinkingTime: segments[lastIdx].thinkingTime,
                );
              }
            }
          } else {
            // 思考结束后第一个正文chunk固化思考时长(消息级旧字段)
            if (endTime == null) {
              final now = DateTime.now();
              endTime = now;
              thinkingTime = now.difference(startTime).inMilliseconds;
              sealPreviousThinkingTime();
            }
            appendText(newContent);
          }
        }

        // omni等模型的流式音频片段累加
        finalAudioBase64 += delta?.audio?['data'] ?? '';

        // 检查是否完成(finishReason：封段+音频转文件+落库)
        if (choice.finishReason != null) {
          sealTextSegment();
          // 本轮思考段若未固化(无正文直接tool_calls结束)也补上用时
          sealPreviousThinkingTime();

          String voicePath = '';
          if (finalAudioBase64.isNotEmpty) {
            voicePath = await WavAudioHandler.saveBase64Wav(
              finalAudioBase64,
              model: _currentModel?.modelName,
            );
          }

          if (currentTextFull.trim().isNotEmpty) {
            multimodalContent.add(
              UnifiedContentItem.text(currentTextFull.trim()),
            );
          }

          if (voicePath.isNotEmpty) {
            multimodalContent.add(
              UnifiedContentItem.audio(
                voicePath,
                fileName: voicePath.split('/').last,
                fileSize: await getFileSize(File(voicePath)),
              ),
            );
          }

          final saveMessage = streamMsg.copyWith(
            segments: List.of(segments),
            // 旧字段兜底(未分段消费方)：content为各正文段拼接
            content: segments
                .where((s) => s.type == MessageSegmentType.text)
                .map((s) => s.text)
                .join('\n\n'),
            thinkingContent: segments
                .where((s) => s.type == MessageSegmentType.thinking)
                .map((s) => s.text)
                .where((t) => t != null && t.isNotEmpty)
                .join('\n\n'),
            thinkingTime: thinkingTime,
            contentType: multimodalContent.isNotEmpty
                ? UnifiedContentType.multimodal
                : UnifiedContentType.text,
            multimodalContent: multimodalContent.isNotEmpty
                ? multimodalContent
                : null,
            tokenCount: response.usage?.totalTokens ?? streamMsg.tokenCount,
            cost: response.usage?.totalTokens != null
                ? _calculateCost(response.usage!.totalTokens, _currentModel!)
                : streamMsg.cost,
            searchReferences: isWebSearch && _isWebSearchEnabled
                ? _getSearchReferencesFromService()
                : streamMsg.searchReferences,
            updatedAt: DateTime.now(),
          );

          streamMsg = saveMessage;
          commitStream();
          // finishReason中间落库：切走会话后DB也有完整中间态可加载
          // (手动停止后跳过——防覆盖[手动终止]终态，同usage帧)
          if (!_manualStopRequested) _chatDao.saveMessage(saveMessage);
        }

        // 实时追加更新助手消息(分段)
        final updatedStreaming = streamMsg.copyWith(
          segments: List.of(segments),
          content: currentTextDisplayed,
          thinkingContent: segments
              .where((s) => s.type == MessageSegmentType.thinking)
              .map((s) => s.text)
              .where((t) => t != null && t.isNotEmpty)
              .join('\n\n'),
          thinkingTime: thinkingTime,
          contentType: multimodalContent.isNotEmpty
              ? UnifiedContentType.multimodal
              : UnifiedContentType.text,
          multimodalContent: multimodalContent.isNotEmpty
              ? multimodalContent
              : null,
          tokenCount: response.usage?.totalTokens ?? streamMsg.tokenCount,
          cost: response.usage?.totalTokens != null
              ? _calculateCost(response.usage!.totalTokens, _currentModel!)
              : streamMsg.cost,
          searchReferences: isWebSearch && _isWebSearchEnabled
              ? _getSearchReferencesFromService()
              : streamMsg.searchReferences,
          updatedAt: DateTime.now(),
        );

        streamMsg = updatedStreaming;
        commitStream();
      }
    }

    _streamSubscription = stream.listen(
      (response) {
        // 串行化：上一chunk处理完才放行下一个(消除async回调竞态)
        _streamSubscription?.pause();
        handleChunk(response).whenComplete(() => _streamSubscription?.resume());
      },
      onDone: () async {
        stopTypewriter();
        // flush：最后正文段显示值补齐到真实值，旧字段同步拼接值
        // (2026-09-15 基于streamMsg而非反查_messages——切走会话后也能收尾)
        sealTextSegment();
        streamMsg = streamMsg.copyWith(
          segments: List.of(segments),
          content: segments
              .where((s) => s.type == MessageSegmentType.text)
              .map((s) => s.text)
              .join('\n\n'),
          thinkingContent: segments
              .where((s) => s.type == MessageSegmentType.thinking)
              .map((s) => s.text)
              .where((t) => t != null && t.isNotEmpty)
              .join('\n\n'),
        );
        await _handleStreamDone(streamMsg);
      },
      onError: (error) {
        stopTypewriter();
        _handleStreamError(error, streamMsg);
      },
    );
  }

  /// 处理流式完成
  /// 特别注意，在finishReason不为null时的结束处理，和这里没有关系
  /// 在finishReason保存音频文件等异步操作构建的多模态数据，这里是取不到的，所以在finishReason需要先保存
  /// 那么在这里，就不太清楚实际作用了
  Future<void> _handleStreamDone(UnifiedChatMessage assistantMessage) async {
    // 流式完成，保存最终消息(注意，有时候解析失败，会无法正确保存token使用量等内容)
    // 2026-09-15 切换会话流式修复：入参是流处理闭包回传的最新对象，
    // 完成时**无条件落库**——原实现先在_messages反查，切走会话后
    // index==-1整体跳过，AI回复永久丢失(切回只见空会话)
    var current = assistantMessage;

    // 2026-09-12 空回答兜底：平台对某些请求返回空流(实测白山中转对
    // 工具结果续传请求回零chunk空SSE)时消息无声结束——正文/多模态为空
    // 即提示(思考框有内容也算异常：模型思考完必有正文)，不再无声空白
    // 2026-09-14 分段渲染适配：渲染优先走segments，只写content字段
    // 气泡内不显示——需同时插入提示text段(实测内联降级失败后只有
    // 思考+工具卡，消息空白无任何提示)
    if ((current.content ?? '').trim().isEmpty &&
        (current.multimodalContent == null ||
            current.multimodalContent!.isEmpty)) {
      const hint = '（模型未返回内容，可能是服务平台对本次请求处理异常；请重试或更换模型/平台）';
      current = current.copyWith(
        content: hint,
        segments: current.segments == null
            ? null
            : [...current.segments!, MessageSegment.textSeg(hint)],
      );
    }

    final finalMessage = current.copyWith(
      isStreaming: false,
      updatedAt: DateTime.now(),
    );

    _updateMessageInLists(finalMessage);
    // 无条件落库(不在当前会话列表时update是no-op，落库保证切回能加载)
    await _chatDao.saveMessage(finalMessage);
    _activeStreamingMessages.remove(finalMessage.conversationId);

    // 更新对话统计, 对话处理完了要清空搜索参考
    // (2026-09-15 按流式会话id统计——切走会话后计数也能正确刷新)
    await _updateConversationStats(conversationId: finalMessage.conversationId);
    if (finalMessage.conversationId == _currentConversation?.id) {
      notifyListeners();
    }
    _chatService.clearLastSearchReferences();
    _setStreaming(false);
  }

  /// 处理流式错误
  void _handleStreamError(Object error, UnifiedChatMessage assistantMessage) {
    // 2026-09-09 用户手动中断是正常业务逻辑，不该显示报错：
    // 停止时token.cancel引发的取消错误若仍能到达监听(未先取消订阅等时序)，
    // 静默收尾即可——消息已由stopStreaming保存为[手动终止]状态
    if (_manualStopRequested && _isUserCancelError(error)) {
      pl.d('流式响应被用户手动取消，静默处理');
      _chatService.clearLastSearchReferences();
      _setStreaming(false);
      return;
    }

    // print('流式响应错误, 类型:${error.runtimeType} 内容:$error');

    // 2026-09-15 错误详情落日志+写入正文段(Ubuntu实测教训：有segments的
    // 消息只渲染segments，原实现错误文本只写content导致用户看不到详情，
    // 排障时只能靠"生成失败"四个字猜)
    pl.e('流式响应错误: $error');

    // 在对话中显示错误而不是统一错误页面
    // 2026-09-15 切换会话流式修复：基于闭包回传的最新对象构建错误
    // 消息并无条件落库——原实现反查_messages失败时错误也一并丢失
    final errorText = '生成失败: $error';
    final errorMessage = assistantMessage.copyWith(
      content: 'AI回复失败: $error',
      // 错误详情作为独立正文段追加(有segments时气泡只渲染segments)
      segments: [
        ...(assistantMessage.segments ?? const <MessageSegment>[]),
        MessageSegment.textSeg(errorText),
      ],
      isStreaming: false,
      isError: true,
      errorMessage: error.toString(),
      updatedAt: DateTime.now(),
    );
    _updateMessageInLists(errorMessage);
    _chatDao.saveMessage(errorMessage);
    _activeStreamingMessages.remove(errorMessage.conversationId);
    if (errorMessage.conversationId == _currentConversation?.id) {
      notifyListeners();
    }

    _chatService.clearLastSearchReferences();
    _setStreaming(false);
  }

  /// 判断是否用户主动取消类错误(dio cancel / CusHttpException -2)
  bool _isUserCancelError(Object error) {
    final text = error.toString();
    return (error is CusHttpException && error.cusCode == -2) ||
        text.contains('manually cancelled by the user') ||
        text.contains('请求被取消');
  }

  /// 处理发送请求异常
  Future<void> _handleMessageSendError(Object error) async {
    // 2026-09-15 切换会话流式修复：以发送时登记的会话为准——原实现
    // 按"当前会话"创建错误占位，发送后切走会话时错误消息会落到
    // 别的会话列表里
    final activeConvId = _streamingConversationId;
    final active = activeConvId == null
        ? null
        : _activeStreamingMessages[activeConvId];

    if (active != null) {
      final errorMessage = active.copyWith(
        content: '发送请求失败: $error',
        isError: true,
        errorMessage: error.toString(),
        isStreaming: false,
        updatedAt: DateTime.now(),
      );
      _updateMessageInLists(errorMessage);
      await _chatDao.saveMessage(errorMessage);
      _activeStreamingMessages.remove(activeConvId);
      if (errorMessage.conversationId == _currentConversation?.id) {
        notifyListeners();
      }
    } else {
      if (_currentConversation == null) {
        _setStreaming(false);
        return;
      }

      // 在对话中显示错误而不是统一错误页面
      final assistantMessage = _createAssistantPlaceholder(
        content: '发送请求失败: $error',
      );
      final errorMessage = assistantMessage.copyWith(
        isError: true,
        errorMessage: error.toString(),
        isStreaming: false,
      );

      // 如果已有助手消息占位符，替换它；否则添加新的错误消息
      final assistantIndex = _messages.lastIndexWhere(
        (m) => m.role == UnifiedMessageRole.assistant && m.isStreaming,
      );
      if (assistantIndex != -1) {
        _messages[assistantIndex] = errorMessage;
      } else {
        _messages.add(errorMessage);
        _allMessages.add(errorMessage);
      }

      // 保存发送错误消息
      await _chatDao.saveMessage(errorMessage);
    }

    _chatService.clearLastSearchReferences();
    _setStreaming(false);
  }

  /// 更新占位助手消息(包括cc\多模态正常响应,报错等情况)
  Future<void> _updateAssistantMessage(
    // 被更新的助手消息
    UnifiedChatMessage assistantMessage,
  ) async {
    _updateMessageInLists(assistantMessage);

    // 保存错误消息到数据库
    await _chatDao.saveMessage(assistantMessage);
  }

  /// 发送图片生成消息
  Future<void> sendImageGenerationMessage({
    required String prompt,
    List<File>? images,
    Map<String, dynamic>? settings,
  }) async {
    if (_currentConversation == null ||
        _currentModel == null ||
        _currentPlatform == null) {
      return;
    }

    // 初始化对话保存
    await _initSaveConversation(prompt.trim());

    // 构建多模态内容列表（图片生成，只处理图片内容）
    final multimodalContent = <UnifiedContentItem>[];

    // 添加文本内容
    if (prompt.trim().isNotEmpty) {
      multimodalContent.add(UnifiedContentItem.text(prompt.trim()));
    }

    // 添加图片内容
    if (images != null && images.isNotEmpty) {
      for (final image in images) {
        multimodalContent.add(
          UnifiedContentItem.image(image.path, detail: 'auto'),
        );
      }
    }

    // 创建用户消息
    final userMessage = _createUserPlaceholder(
      prompt,
      contentType: UnifiedContentType.multimodal,
      multimodalContent: multimodalContent,
      metadata: {
        'model': _currentModel,
        'platform': _currentPlatform,
        'sourceLanguage': settings?['sourceLanguage'],
        'targetLanguage': settings?['targetLanguage'],
      },
    );

    // 添加用户消息到列表
    _messages.add(userMessage);
    _allMessages.add(userMessage);
    notifyListeners();

    // 保存用户消息到数据库
    await _chatDao.saveMessage(userMessage);

    // 图片生成只使用本次输入的提示词(2026-09-02修正：旧版误将历史用户消息
    // 合并进prompt，导致"再生成一只狗"会拼接上之前的小猫咪描述)
    final combinedPrompt = prompt.trim();

    // 创建助手消息占位符
    final assistantMessage = _createAssistantPlaceholder(
      content: '正在生成图片，请勿退出...\n',
    );

    _messages.add(assistantMessage);
    _allMessages.add(assistantMessage);
    notifyListeners();

    try {
      // 准备参考图片地址（模型支持参考图输入且有选择的图片）
      List<String>? referenceImages;
      if (_currentModel!.supportsImageInput && images?.isNotEmpty == true) {
        referenceImages = images!.map((file) => file.path).toList();
      }

      // 创建图片生成请求
      final request = ImageGenerationRequest(
        model: _currentModel!.modelName,
        prompt: combinedPrompt,
        images: referenceImages,
        size: settings?['size'],
        quality: settings?['quality'],
        n: double.tryParse(settings?['n'].toString() ?? '1')?.toInt() ?? 1,
        seed: settings?['seed'],
        steps: settings?['steps'],
        guidanceScale: settings?['guidanceScale'],
        watermark: settings?['watermark'] ?? true,
        sourceLanguage: settings?['sourceLanguage'],
        targetLanguage: settings?['targetLanguage'],
      );

      // 调用图片生成服务
      final imageService = ImageGenerationService();
      final response = await imageService.generateImage(
        request: request,
        platform: _currentPlatform!,
        model: _currentModel!,
      );

      // 更新助手消息内容
      // 注意，大模型API生成的图片都是网络图片，有效期是24小时。
      // 所以需要先下载到本地，然后将本地的图片地址存入对话消息中，以避免失效后无法显示的问题
      var imageUrls = response.data.map((r) => r.url).toList();
      List<String> newUrls = [];
      for (final url in imageUrls) {
        if (url == null) {
          continue;
        }
        var localPath = await saveImageToLocal(
          url,
          dlDir: await getUnifiedChatMediaDir(),
          showSaveHint: false,
        );

        if (localPath != null) {
          newUrls.add(localPath);
        }
      }

      final updatedAssistantMessage = assistantMessage.copyWith(
        content: response.data.isNotEmpty
            ? '生成了 ${response.data.length} 张图片'
            : '图片生成完成',
        isStreaming: false,
        // 2026-09-09 genParams：本次生成的实际参数落库(媒体面板展示生成条件)
        metadata: {'images': newUrls, 'genParams': ?settings},
      );

      // 更新消息列表
      await _updateAssistantMessage(updatedAssistantMessage);

      // 更新对话统计
      await _updateConversationStats();
      notifyListeners();
    } catch (e) {
      // 更新助手消息为错误状态
      final errorMessage = assistantMessage.copyWith(
        content: '图片生成失败: $e',
        isStreaming: false,
      );

      _updateAssistantMessage(errorMessage);
    }

    notifyListeners();
  }

  /// ******************************************
  /// 视频生成(2026-09-02 媒体生成并入聊天新增)
  /// ******************************************

  /// 发送视频生成消息
  /// 三平台均为"提交任务+轮询任务"的异步模式，任务态持久化在助手消息
  /// metadata.videoTask 中——页面退出/应用重启后 loadConversation 会续查
  Future<void> sendVideoGenerationMessage({
    required String prompt,
    List<File>? images,
    Map<String, dynamic>? settings,
  }) async {
    if (_currentConversation == null ||
        _currentModel == null ||
        _currentPlatform == null) {
      return;
    }

    // 初始化对话保存
    await _initSaveConversation(prompt.trim());

    // 用户消息(提示词+可选首帧图)
    final multimodalContent = <UnifiedContentItem>[
      UnifiedContentItem.text(prompt.trim()),
      if (images != null)
        for (final image in images)
          UnifiedContentItem.image(image.path, detail: 'auto'),
    ];

    final userMessage = _createUserPlaceholder(
      prompt,
      contentType: UnifiedContentType.multimodal,
      multimodalContent: multimodalContent,
    );

    _messages.add(userMessage);
    _allMessages.add(userMessage);
    notifyListeners();
    await _chatDao.saveMessage(userMessage);

    // 助手占位消息(任务卡片，metadata记录任务态)
    // 2026-09-09 params：本次生成的分辨率/时长等参数落库(媒体面板展示生成条件)
    final videoTask = <String, dynamic>{
      'platformId': _currentPlatform!.id,
      'modelName': _currentModel!.modelName,
      'status': 'submitting',
      'params': ?settings,
    };
    final assistantMessage = _createAssistantPlaceholder(
      content: '正在提交视频生成任务...\n',
    ).copyWith(metadata: {'videoTask': videoTask});

    _messages.add(assistantMessage);
    _allMessages.add(assistantMessage);
    notifyListeners();
    await _chatDao.saveMessage(assistantMessage);

    try {
      final taskId = await VideoGenerationService().submitVideoTask(
        prompt: prompt.trim(),
        referenceImagePaths:
            _currentModel!.supportsImageInput && images?.isNotEmpty == true
            ? images!.map((file) => file.path).toList()
            : null,
        settings: settings,
        platform: _currentPlatform!,
        model: _currentModel!,
      );

      await _pollVideoTask(
        assistantMessage.copyWith(
          metadata: {
            'videoTask': {
              ...videoTask,
              'taskId': taskId,
              'status': 'processing',
            },
          },
        ),
      );
    } catch (e) {
      await _updateAssistantMessage(
        assistantMessage.copyWith(
          content: '视频生成失败: $e',
          isStreaming: false,
          metadata: {
            'videoTask': {...videoTask, 'status': 'failed', 'error': '$e'},
          },
        ),
      );
    }

    await _updateConversationStats();
    notifyListeners();
  }

  /// 轮询视频任务直到终态(每5秒一次，最长约5分钟)
  Future<void> _pollVideoTask(UnifiedChatMessage taskMessage) async {
    final task = taskMessage.metadata?['videoTask'] as Map<String, dynamic>?;
    final taskId = task?['taskId'] as String?;
    final platformId = task?['platformId'] as String? ?? '';
    if (taskId == null || taskId.isEmpty) return;

    UnifiedPlatformSpec? platform = _currentPlatform?.id == platformId
        ? _currentPlatform
        : null;
    platform ??= _availablePlatforms.isNotEmpty
        ? _availablePlatforms.firstWhere(
            (p) => p.id == platformId,
            orElse: () => _availablePlatforms.first,
          )
        : null;
    if (platform == null) {
      await _updateAssistantMessage(
        taskMessage.copyWith(
          content: '视频生成失败: 未找到任务所属平台',
          isStreaming: false,
          metadata: {
            'videoTask': {...?task, 'status': 'failed', 'error': '平台不可用'},
          },
        ),
      );
      return;
    }

    const maxAttempts = 60;
    const interval = Duration(seconds: 5);
    int networkErrors = 0;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      await Future.delayed(interval);

      final VideoTaskResult result;
      try {
        result = await VideoGenerationService().queryVideoTask(
          taskId: taskId,
          platform: platform,
        );
      } catch (_) {
        // 单次查询异常(网络抖动等)不终止任务，连续10次才放弃
        if (++networkErrors >= 10) break;
        continue;
      }
      networkErrors = 0;

      switch (result.status) {
        case VideoTaskStatus.succeeded:
          // 生成视频的网络地址有时效性，需下载到本地保存
          final localPaths = <String>[];
          for (final url in result.videoUrls) {
            final localPath = await saveVideoToLocal(
              url,
              dlDir: await getUnifiedChatMediaDir(),
              showSaveHint: false,
            );
            if (localPath != null) {
              localPaths.add(localPath);
            }
          }

          await _updateAssistantMessage(
            taskMessage.copyWith(
              content: localPaths.isNotEmpty ? '视频已生成' : '视频生成完成，但保存到本地失败',
              isStreaming: false,
              multimodalContent: localPaths
                  .map((path) => UnifiedContentItem.video(path))
                  .toList(),
              metadata: {
                ...?taskMessage.metadata,
                'videoTask': {...?task, 'status': 'succeeded'},
                'videos': localPaths,
              },
            ),
          );
          notifyListeners();
          return;

        case VideoTaskStatus.failed:
          await _updateAssistantMessage(
            taskMessage.copyWith(
              content: '视频生成失败: ${result.error ?? '未知错误'}',
              isStreaming: false,
              metadata: {
                ...?taskMessage.metadata,
                'videoTask': {
                  ...?task,
                  'status': 'failed',
                  'error': result.error,
                },
              },
            ),
          );
          notifyListeners();
          return;

        default:
          // processing：更新等待提示
          await _updateAssistantMessage(
            taskMessage.copyWith(
              content: '视频生成中，已等待 ${attempt * 5} 秒...\n',
              isStreaming: true,
            ),
          );
      }
    }

    // 轮询超时/连续网络异常
    // 标记为timeout而非failed：服务端任务可能仍在执行(DashScope结果保留24小时)，
    // 保留taskId，下次进入对话时_resumeUnfinishedVideoTasks会继续查询结果
    await _updateAssistantMessage(
      taskMessage.copyWith(
        content: '视频生成中，本轮等待超时，进入本对话时将自动继续查询...\n',
        isStreaming: false,
        metadata: {
          ...?taskMessage.metadata,
          'videoTask': {...?task, 'status': 'timeout', 'error': '本轮等待超时'},
        },
      ),
    );
    notifyListeners();
  }

  /// 恢复会话中未完成的视频生成任务(切换对话/重进对话/应用重启后触发)
  /// 覆盖processing(进行中)与timeout(上轮轮询超时，服务端可能已完成)两种状态
  void _resumeUnfinishedVideoTasks() {
    if (_allMessages.isEmpty) return;

    for (final message in List.of(_allMessages)) {
      final task = message.metadata?['videoTask'] as Map<String, dynamic>?;
      if (task == null) continue;
      final status = task['status'] as String?;
      if (status != 'processing' && status != 'timeout') continue;

      // 后台续查，不阻塞会话加载
      unawaited(_pollVideoTask(message));
    }
  }

  /// 发送语音合成消息
  Future<void> sendSpeechSynthesisMessage({
    required String text,
    Map<String, dynamic>? settings,
  }) async {
    if (_currentConversation == null ||
        _currentModel == null ||
        _currentPlatform == null) {
      return;
    }

    // 初始化对话保存
    await _initSaveConversation(text.trim());

    // 创建用户消息
    // 2026-09-09 补记model/platform：媒体面板可展示合成模型(与其他媒体生成一致)
    final userMessage = _createUserPlaceholder(
      text,
      metadata: {'model': _currentModel, 'platform': _currentPlatform},
    );

    // 添加用户消息到列表
    _messages.add(userMessage);
    _allMessages.add(userMessage);
    notifyListeners();

    // 保存用户消息到数据库
    await _chatDao.saveMessage(userMessage);

    // 创建助手消息占位符
    final assistantMessage = _createAssistantPlaceholder(
      content: '正在合成语音，请勿退出...\n',
    );

    _messages.add(assistantMessage);
    _allMessages.add(assistantMessage);
    notifyListeners();

    try {
      // 创建语音合成请求
      final request = SpeechSynthesisRequest(
        model: _currentModel!.modelName,
        input: text,
        voice: settings?['voice'],
        responseFormat: settings?['responseFormat'] ?? 'wav',
        speed: double.tryParse(settings?['speed'].toString() ?? '1.0'),
        volume: double.tryParse(settings?['volume'].toString() ?? '1.0'),

        // 下面这几个暂时不处理了
        // stream(默认为false，先不处理流式的)
        // languageType encodeFormat watermark gain
      );

      // 调用语音合成服务
      final speechService = SpeechSynthesisService();
      final response = await speechService.synthesizeSpeech(
        request: request,
        platform: _currentPlatform!,
        model: _currentModel!,
      );

      // 更新助手消息内容
      // 注意，大模型API生成的图片都是网络图片，有效期是24小时。
      // 所以需要先下载到本地，然后将本地的图片地址存入对话消息中，以避免失效后无法显示的问题
      var url = response.audioUrl;
      String? newUrl;

      if (url != null) {
        // 阿里百炼的是在线地址；硅基流动和智谱是二进制文件，已先保存到本地了
        var localPath = (url.startsWith('https') || url.startsWith('http'))
            ? await saveNetMediaToLocal(
                url,
                dlDir: await getUnifiedChatMediaDir(),
                showSaveHint: false,
              )
            : url;

        if (localPath != null) {
          newUrl = localPath;
          // AI生成语音：异步写公共区副本(MediaStore/相册)
          MediaSaveService.onFileSaved(localPath);
        }
      }

      // 更新助手消息内容
      final updatedAssistantMessage = assistantMessage.copyWith(
        content: response.hasAudio ? '语音合成完成' : '语音合成失败',
        contentType: response.hasAudio
            ? UnifiedContentType.audio
            : UnifiedContentType.text,
        isStreaming: false,
        metadata: {
          // 这个参数在消息组件会展示
          'audio': ?newUrl,
          'audio_url': response.audioUrl,
          'audio_base64': response.audioBase64,
          'audio_format': response.format ?? 'mp3',
          'duration': response.duration,
          'synthesis_settings': settings,
        },
      );

      // 更新消息列表
      await _updateAssistantMessage(updatedAssistantMessage);

      // 更新对话统计
      await _updateConversationStats();
      notifyListeners();
    } catch (e) {
      // 更新助手消息为错误状态
      final errorMessage = assistantMessage.copyWith(
        content: '语音合成失败: $e',
        isStreaming: false,
      );
      _updateAssistantMessage(errorMessage);
    }

    notifyListeners();
  }

  /// 发送语音识别消息
  Future<void> sendSpeechRecognitionMessage({
    required String audioPath,
    Map<String, dynamic>? settings,
  }) async {
    if (_currentConversation == null ||
        _currentModel == null ||
        _currentPlatform == null) {
      return;
    }

    // 初始化对话保存
    await _initSaveConversation('语音识别');

    // 创建用户消息（显示音频文件）
    final userMessage = _createUserPlaceholder(
      '',
      contentType: UnifiedContentType.audio,
      metadata: {
        'audio': audioPath,
        'model': _currentModel,
        'platform': _currentPlatform,
      },
    );

    // 添加用户消息到列表
    _messages.add(userMessage);
    _allMessages.add(userMessage);
    notifyListeners();

    // 保存用户消息到数据库
    await _chatDao.saveMessage(userMessage);

    // 创建助手消息占位符
    final assistantMessage = _createAssistantPlaceholder(
      content: '正在识别语音，请勿退出...\n',
    );

    _messages.add(assistantMessage);
    _allMessages.add(assistantMessage);
    notifyListeners();

    try {
      // 获取API Key
      final apiKey = await UnifiedSecureStorage.getApiKey(_currentPlatform!.id);
      if (apiKey == null) {
        throw Exception('未配置API Key');
      }

      // 创建语音识别请求(暂时只启用必要的)
      final request = SpeechRecognitionRequest(
        model: _currentModel!.modelName,
        audioPath: audioPath,
        language: settings?['language'],
        temperature: double.tryParse(
          settings?['temperature']?.toString() ?? '0.95',
        ),
        stream: settings?['stream'] ?? false,
        enableLid: settings?['enableLid'],
        enableItn: settings?['enableItn'],
        context: settings?['context'],
        requestId: settings?['requestId'],
        userId: settings?['userId'],
      );

      // 调用语音识别服务
      final response = await SpeechRecognitionService.recognizeSpeech(
        platform: _currentPlatform!,
        request: request,
        apiKey: apiKey,
      );

      // 更新助手消息内容
      final updatedAssistantMessage = assistantMessage.copyWith(
        content: response.text.isNotEmpty ? response.text : '语音识别失败',
        contentType: UnifiedContentType.text,
        isStreaming: false,
        metadata: {
          'recognition_result': response.text,
          'language': response.language,
          'segments': response.segments?.map((s) => s.toJson()).toList(),
          'recognition_settings': settings,
          'request_id': response.requestId,
          'task_id': response.taskId,
        },
      );

      // 更新消息列表
      await _updateAssistantMessage(updatedAssistantMessage);

      // 更新对话统计
      await _updateConversationStats();
      notifyListeners();
    } catch (e) {
      // 更新助手消息为错误状态
      final errorMessage = assistantMessage.copyWith(
        content: '语音识别失败: $e',
        isStreaming: false,
      );
      _updateAssistantMessage(errorMessage);
    }

    notifyListeners();
  }

  /// 2026-09-09 媒体面板：扫描消息记录构建AI生成媒体列表
  /// 产物取助手消息metadata(images/videos/audio)，生成条件(prompt/模型/
  /// 参数)取同轮用户消息与消息自身——资源与条件一并可见；
  /// 每次进入面板重扫(只遍历含产物的会话，个人应用量级可接受)，
  /// 避免维护缓存失效点
  Future<List<MediaLibraryItem>> loadMediaLibrary() async {
    final items = <MediaLibraryItem>[];

    final conversationIds = await _chatDao.getMediaConversationIds();
    if (conversationIds.isEmpty) return items;

    // 会话标题映射
    final conversations = await _chatDao.getConversations();
    final titleMap = {for (final c in conversations) c.id: c.title};

    for (final conversationId in conversationIds) {
      final messages = await _chatDao.getMessagesByConversationId(
        conversationId,
      );

      // 同轮用户消息的提示词/合成文本(prompt)；时间正序下取最近一条非空user消息
      String lastUserPrompt = '';
      for (final message in messages) {
        if (message.role == UnifiedMessageRole.user) {
          final content = message.content ?? '';
          if (content.trim().isNotEmpty) {
            lastUserPrompt = content.trim();
          }
          continue;
        }
        if (message.role != UnifiedMessageRole.assistant) continue;

        final metadata = message.metadata;
        if (metadata == null) continue;

        // 图片：metadata.images为本地路径列表，每张一个条目
        final images = metadata['images'];
        if (images is List && images.isNotEmpty) {
          for (final path in images.whereType<String>()) {
            items.add(
              _buildMediaItem(
                MediaLibraryType.image,
                path,
                message,
                lastUserPrompt,
                titleMap[conversationId],
                metadata['genParams'],
              ),
            );
          }
        }

        // 视频：metadata.videos，参数在videoTask.params
        final videos = metadata['videos'];
        if (videos is List && videos.isNotEmpty) {
          final task = metadata['videoTask'];
          final taskParams = task is Map<String, dynamic>
              ? task['params']
              : null;
          for (final path in videos.whereType<String>()) {
            items.add(
              _buildMediaItem(
                MediaLibraryType.video,
                path,
                message,
                lastUserPrompt,
                titleMap[conversationId],
                taskParams,
              ),
            );
          }
        }

        // 语音合成产物：metadata.audio为本地路径
        // (语音识别的录音在user消息且SQL已限定assistant，不会误纳入)
        final audio = metadata['audio'];
        if (audio is String && audio.isNotEmpty) {
          items.add(
            _buildMediaItem(
              MediaLibraryType.audio,
              audio,
              message,
              lastUserPrompt,
              titleMap[conversationId],
              metadata['synthesis_settings'],
            ),
          );
        }
      }
    }

    // 新生成的在前
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  MediaLibraryItem _buildMediaItem(
    MediaLibraryType type,
    String path,
    UnifiedChatMessage message,
    String prompt,
    String? conversationTitle,
    dynamic rawParams,
  ) {
    return MediaLibraryItem(
      type: type,
      filePath: path,
      prompt: prompt,
      modelName: message.modelNameUsed,
      platformId: message.platformIdUsed,
      conversationId: message.conversationId,
      conversationTitle: conversationTitle ?? '',
      createdAt: message.createdAt,
      genParams: rawParams is Map
          ? rawParams.cast<String, dynamic>()
          : const {},
    );
  }

  /// 重新生成响应消息
  /// 2026-08-31 分支化改造：不再删除原消息，而是创建同父节点的新兄弟分支，
  /// 原有内容保留，可随时通过分支切换器切回
  Future<void> regenerateMessage(
    UnifiedChatMessage message, {
    bool isWebSearch = false,
  }) async {
    if (_currentConversation == null ||
        message.role != UnifiedMessageRole.assistant) {
      return;
    }

    if (_isStreaming) {
      ToastUtils.showToast('正在生成中，请稍候');
      return;
    }

    if (_currentModel == null || _currentPlatform == null) {
      ToastUtils.showToast('没有可用的平台和模型，请先配置API Key');
      return;
    }

    try {
      // 从全量列表找原消息(用户可能在其他分支视图上操作)
      final source = _allMessages.firstWhere(
        (m) => m.id == message.id,
        orElse: () => message,
      );

      // 视图回退到父消息：切到父路径并截断到父消息
      if (source.parentId == null) {
        _currentBranchPath = null;
        _displayTruncateId = null;
        // 根级消息重新生成：直接以根路径视图截断到根消息
        _rebuildDisplayMessages();
        final rootIdx = _messages.indexWhere((m) => m.id == message.id);
        if (rootIdx == -1) return;
        _messages = _messages.sublist(0, rootIdx);
      } else {
        final parentPath = source.branchPath.substring(
          0,
          source.branchPath.lastIndexOf('/'),
        );
        _currentBranchPath = parentPath;
        _displayTruncateId = source.parentId;
        _rebuildDisplayMessages();
      }

      notifyListeners();

      // 重新发送请求：新的AI回复作为同父节点的新兄弟分支挂载(不删除原消息)
      await _sendMessageToAI(_messages, isWebSearch: isWebSearch);
    } catch (e) {
      _setError('重新生成失败: $e');
    }
  }

  /// 删除消息
  /// 分支化改造：删除该消息及其整个子树(所有后代分支)
  Future<void> deleteMessage(UnifiedChatMessage message) async {
    if (_currentConversation == null) return;

    try {
      // system消息单独删除
      if (message.isSystem) {
        await _chatDao.deleteMessage(message.id);
        _allMessages.removeWhere((m) => m.id == message.id);
        _rebuildDisplayMessages();
        await _updateConversationStats();
        notifyListeners();
        return;
      }

      // 删除整个子树
      await _chatDao.deleteBranchSubtree(
        _currentConversation!.id,
        message.branchPath,
      );

      // 从全量列表中移除子树消息(精确前缀匹配，避免'0/1'误删'0/10')
      _allMessages.removeWhere(
        (m) =>
            m.branchPath == message.branchPath ||
            m.branchPath.startsWith('${message.branchPath}/'),
      );

      // 如果当前分支路径在被删子树内，回退到父路径或默认最新链
      if (_currentBranchPath != null &&
          UnifiedBranchUtils.isOnBranch(
            _currentBranchPath!,
            message.branchPath,
          )) {
        _currentBranchPath = message.branchPath.contains('/')
            ? message.branchPath.substring(
                0,
                message.branchPath.lastIndexOf('/'),
              )
            : null;
      }

      _rebuildDisplayMessages();
      await _updateConversationStats();
      notifyListeners();
    } catch (e) {
      _setError('删除消息失败: $e');
    }
  }

  /// 更新消息
  Future<void> updateMessage(UnifiedChatMessage message) async {
    try {
      await _chatDao.updateMessage(message);
      // 2026-08-31 修复：原实现先移除再添加会导致消息挪到列表尾部，改为原位替换
      _updateMessageInLists(message);
      notifyListeners();
    } catch (e) {
      _setError('更新消息失败: $e');
    }
  }

  /// ******************************************
  /// 消息辅助方法
  /// ******************************************

  /// 创建并保存系统消息（如果需要）
  Future<void> _createAndSaveSystemMessageIfNeeded() async {
    final effectivePartner = _currentPartner ?? defaultPartner;
    final systemPrompt =
        _currentConversation?.systemPrompt ?? effectivePartner.prompt;

    if (systemPrompt.isNotEmpty) {
      final systemMessage = _createSystemPlaceholder(systemPrompt);

      _allMessages.insert(0, systemMessage);
      _messages.insert(0, systemMessage);
      await _chatDao.saveMessage(systemMessage);
    }
  }

  /// 验证并修复消息序列，确保符合API要求
  List<UnifiedChatMessage> _validateAndFixMessageSequence(
    List<UnifiedChatMessage> messages,
  ) {
    if (messages.isEmpty) return messages;

    final fixedMessages = <UnifiedChatMessage>[];
    UnifiedMessageRole? lastRole;

    for (final message in messages) {
      // 如果当前消息角色与上一条相同，需要处理
      if (lastRole == message.role &&
          message.role != UnifiedMessageRole.system) {
        if (message.role == UnifiedMessageRole.user) {
          // 连续用户消息：合并内容
          if (fixedMessages.isNotEmpty) {
            final lastMessage = fixedMessages.last;
            final mergedContent =
                '${lastMessage.content}\n\n${message.content}';
            fixedMessages[fixedMessages.length - 1] = lastMessage.copyWith(
              content: mergedContent,
              updatedAt: DateTime.now(),
            );
            continue;
          }
        } else if (message.role == UnifiedMessageRole.assistant) {
          // 连续助手消息：插入一个占位用户消息
          final userMessage = _createUserPlaceholder("继续");
          final placeholderMessage = userMessage.copyWith(
            id: 'placeholder_${DateTime.now().millisecondsSinceEpoch}',
            conversationId: message.conversationId,
          );

          fixedMessages.add(placeholderMessage);
        }
      }

      fixedMessages.add(message);
      lastRole = message.role;
    }

    return fixedMessages;
  }

  /// 更新系统消息
  Future<void> _updateSystemMessage(String? newSystemPrompt) async {
    if (_messages.isEmpty) return;

    // 查找第一条系统消息
    final systemMessageIndex = _messages.indexWhere(
      (msg) => msg.role == UnifiedMessageRole.system,
    );

    if (systemMessageIndex != -1) {
      // 如果新的系统提示词为空，删除系统消息
      if (newSystemPrompt == null || newSystemPrompt.isEmpty) {
        final systemMessage = _messages[systemMessageIndex];
        await _chatDao.deleteMessage(systemMessage.id);
        _allMessages.removeWhere((m) => m.id == systemMessage.id);
        _messages.removeAt(systemMessageIndex);
      } else {
        // 更新现有系统消息
        final oldSystemMessage = _messages[systemMessageIndex];
        final updatedSystemMessage = oldSystemMessage.copyWith(
          content: newSystemPrompt,
          updatedAt: DateTime.now(),
        );

        await _chatDao.updateMessage(updatedSystemMessage);
        _updateMessageInLists(updatedSystemMessage);
      }
    } else if (newSystemPrompt != null && newSystemPrompt.isNotEmpty) {
      // 如果没有系统消息但新提示词不为空，创建新的系统消息
      final systemMessage = _createSystemPlaceholder(newSystemPrompt);

      await _chatDao.saveMessage(systemMessage);
      _allMessages.insert(0, systemMessage);
      _messages.insert(0, systemMessage);
    }
  }

  /// 用户重新发送消息
  /// 2026-08-31 分支化改造：不再删除该消息之后的回复，
  /// 而是以该用户消息为终点重新请求，新AI回复作为其新的子分支
  Future<void> resendUserMessage(
    UnifiedChatMessage message, {
    bool isWebSearch = false,
  }) async {
    if (_currentConversation == null ||
        message.role != UnifiedMessageRole.user) {
      return;
    }

    if (_isStreaming) {
      ToastUtils.showToast('正在生成中，请稍候');
      return;
    }

    if (_currentModel == null || _currentPlatform == null) {
      ToastUtils.showToast('没有可用的平台和模型，请先配置API Key');
      return;
    }

    try {
      // 从全量列表找原消息
      final source = _allMessages.firstWhere(
        (m) => m.id == message.id,
        orElse: () => message,
      );

      // 视图切换到该用户消息所在分支并截断到该消息为止
      _currentBranchPath = source.branchPath;
      _displayTruncateId = source.id;
      _rebuildDisplayMessages();

      final messageIndex = _messages.indexWhere((m) => m.id == source.id);
      if (messageIndex == -1) return;

      notifyListeners();

      // 重新发送请求：新AI回复作为该用户消息的新子分支(不删除原有回复)
      await _sendMessageToAI(_messages, isWebSearch: isWebSearch);
    } catch (e) {
      _setError('重新发送失败: $e');
      rethrow;
    }
  }

  /// ******************************************
  /// 用户消息编辑相关
  /// ******************************************

  /// 开始编辑用户消息
  void startEditingUserMessage(UnifiedChatMessage message) {
    if (message.role != UnifiedMessageRole.user) return;

    _editingUserMessage = message;
    _isUserEditingMode = true;

    // 如果是在语音输入模式修改用户消息，则需要改为键盘输入模式
    if (!_isKeyboardInput) {
      _isKeyboardInput = true;
    }

    notifyListeners();
  }

  /// 取消编辑消息
  void cancelEditingUserMessage() {
    _editingUserMessage = null;
    _isUserEditingMode = false;
    notifyListeners();
  }

  /// 完成编辑消息并发送
  /// 2026-08-31 分支化改造：不再删除原消息及后续，
  /// 编辑后的内容作为原消息的兄弟分支(同一父节点)，原对话完整保留
  Future<void> finishEditingUserMessage(
    String newContent, {
    bool isWebSearch = false,
  }) async {
    if (_editingUserMessage == null || _currentConversation == null) return;
    if (_currentModel == null || _currentPlatform == null) {
      ToastUtils.showToast('没有可用的平台和模型，请先配置API Key');
      cancelEditingUserMessage();
      return;
    }

    try {
      // 从全量列表找原消息(确保分支信息最新)
      final source = _allMessages.firstWhere(
        (m) => m.id == _editingUserMessage!.id,
        orElse: () => _editingUserMessage!,
      );

      // 找到原消息的父消息
      final parentMsg = source.parentId == null
          ? null
          : _allMessages.where((m) => m.id == source.parentId).firstOrNull;

      UnifiedChatMessage newUserMessage;

      // 注意，如果之前发送的是多模态消息，编辑之后也应该发送多模态消息
      if (source.contentType == UnifiedContentType.multimodal) {
        var bultiCont = source.multimodalContent;

        // 从多模态消息中提取出文件，如果各个没有文件，则返回null
        final images = bultiCont
            ?.map((e) => e.getFileByType('image_url'))
            .whereType<File>()
            .toList();

        final audio = bultiCont
            ?.map((e) => e.getFileByType('audio'))
            .whereType<File>()
            .firstOrNull;
        final video = bultiCont
            ?.map((e) => e.getFileByType('video'))
            .whereType<File>()
            .firstOrNull;
        final files = bultiCont
            ?.map((e) => e.getFileByType('file'))
            .whereType<File>()
            .toList();

        // 复用多模态内容(文本部分替换为编辑后的内容)
        final multimodalContent = <UnifiedContentItem>[];
        if (newContent.trim().isNotEmpty) {
          multimodalContent.add(UnifiedContentItem.text(newContent.trim()));
        }
        multimodalContent.addAll(
          bultiCont?.where((e) => e.type != 'text').toList() ?? [],
        );

        newUserMessage = _createUserPlaceholder(
          newContent.trim().isNotEmpty ? newContent.trim() : '多模态消息',
          contentType: UnifiedContentType.multimodal,
          multimodalContent: multimodalContent,
          parent: parentMsg,
          parentIsExplicit: true,
          metadata: {
            'model': _currentModel,
            'platform': _currentPlatform,
            if (images != null && images.isNotEmpty)
              'images': images.map((f) => f.path).toList(),
            if (audio != null) 'audio': audio.path,
            if (video != null) 'video': video.path,
            if (files != null && files.isNotEmpty)
              'files': files.map((f) => f.path).toList(),
          },
        );
      } else {
        // 文本消息
        newUserMessage = _createUserPlaceholder(
          newContent,
          parent: parentMsg,
          parentIsExplicit: true,
        );
      }

      // 保存新用户消息并切换分支到新消息
      _allMessages.add(newUserMessage);
      _currentBranchPath = newUserMessage.branchPath;
      _displayTruncateId = null;
      _rebuildDisplayMessages();
      await _chatDao.saveMessage(newUserMessage);

      // 清除编辑状态
      _editingUserMessage = null;
      _isUserEditingMode = false;

      notifyListeners();

      // 请求AI回复(新回复作为新用户消息的子分支)
      await _sendMessageToAI(
        _messages.where((m) => !m.isStreaming).toList(),
        isWebSearch: isWebSearch,
      );
    } catch (e) {
      _setError('编辑消息失败: $e');
      cancelEditingUserMessage();
      rethrow;
    }
  }

  /// ******************************************
  /// 平台模型相关
  /// ******************************************

  /// 刷新平台和模型数据，供外部使用获取可用平台和模型
  Future<void> refreshPlatformsAndModels() async {
    await _loadAvailablePlatforms();
    await _loadAvailableModels();

    // 尝试加载最近的对话和模型设置
    await _loadRecentConversationOrCreateNew();
    notifyListeners();
  }

  /// 加载可用平台
  Future<void> _loadAvailablePlatforms() async {
    var tempPlats = await _chatDao.getPlatformSpecs(isActive: true);

    // 一次性查询多个平台的AK比一个个查询要快
    final apiKeysMap = await UnifiedSecureStorage.getApiKeys(
      tempPlats.map((p) => p.id).toList(),
    );

    _availablePlatforms = tempPlats.where((plat) {
      final apiKey = apiKeysMap[plat.id];
      return apiKey != null && apiKey.isNotEmpty;
    }).toList();

    notifyListeners();
  }

  /// 加载可用模型
  Future<void> _loadAvailableModels() async {
    // 简化一下，先得到有效AK的平台，直接查询这些平台的模型即可
    _availableModels = await _chatDao.getModelSpecs(
      platformIds: _availablePlatforms.map((p) => p.id).toList(),
    );

    notifyListeners();
  }

  /// 切换模型
  Future<void> switchModel(UnifiedModelSpec model) async {
    if (_currentModel?.id == model.id) return;

    _currentModel = model;
    _currentPlatform = _availablePlatforms.firstWhere(
      (p) => p.id == model.platformId,
      orElse: () => _availablePlatforms.first,
    );

    // 更新当前对话的模型
    if (_currentConversation != null) {
      _currentConversation = _currentConversation!.copyWith(
        modelId: model.id,
        platformId: _currentPlatform!.id,
      );
      await _chatDao.updateConversation(_currentConversation!);
    }

    // 清空多模态配置属性，以确保切换到不同平台模型后不会使用其他平台的配置
    await updateConversationSettings({
      'imageGenerationParams': null,
      'videoGenerationParams': null,
      'speechSynthesisParams': null,
      'speechRecognitionParams': null,
    });

    // 2026-09-09 未手动切换过联网开关时，跟随新模型/平台的能力自动开关
    _syncWebSearchWithCapability();

    notifyListeners();
  }

  /// ******************************************
  /// 状态设置相关
  /// ******************************************

  /// 停止流式生成
  void stopStreaming() async {
    // 2026-09-09 先置手动停止标志，取消错误到达onError时据此静默处理
    _manualStopRequested = true;

    _streamSubscription?.cancel();
    _streamSubscription = null;
    _chatService.cancelStreaming();

    // 标记流式消息为完成并保存到数据库
    // 2026-09-15 切换会话流式修复：优先从活跃Map取流式消息(切走会话
    // 后消息不在当前_messages里，原遍历找不到→停止后消息悬空无落库)
    final activeConvId = _streamingConversationId;
    final active = activeConvId == null
        ? null
        : _activeStreamingMessages[activeConvId];
    if (active != null) {
      final stoppedMessage = active.copyWith(
        isStreaming: false,
        content: '${active.content ?? ''} [手动终止]',
        // 2026-09-15 分段渲染适配：有segments时气泡只渲染segments，
        // 后缀只写content用户看不到(同错误详情落段的教训)——
        // 追加独立终止段
        segments: [
          ...(active.segments ?? const <MessageSegment>[]),
          MessageSegment.textSeg('[手动终止]'),
        ],
        updatedAt: DateTime.now(),
      );
      _updateMessageInLists(stoppedMessage);
      await _chatDao.saveMessage(stoppedMessage);
      _activeStreamingMessages.remove(activeConvId);
      if (stoppedMessage.conversationId == _currentConversation?.id) {
        notifyListeners();
      }
    } else {
      for (int i = 0; i < _messages.length; i++) {
        if (_messages[i].isStreaming) {
          final stoppedMessage = _messages[i].copyWith(
            isStreaming: false,
            content: '${_messages[i].content} [手动终止]',
            segments: [
              ...(_messages[i].segments ?? const <MessageSegment>[]),
              MessageSegment.textSeg('[手动终止]'),
            ],
            updatedAt: DateTime.now(),
          );
          _updateMessageInLists(stoppedMessage);
          // 保存被停止的消息
          await _chatDao.saveMessage(stoppedMessage);
        }
      }
    }

    // 更新对话统计(2026-09-15 按流式会话id统计)
    await _updateConversationStats(conversationId: activeConvId);
    _setStreaming(false);
  }

  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 设置流式状态
  void _setStreaming(bool streaming) {
    _isStreaming = streaming;
    // 2026-09-15 流结束清空流式会话标记(单流模型，无并发流)
    if (!streaming) _streamingConversationId = null;
    notifyListeners();
  }

  /// 设置错误
  void _setError(String error) {
    // _error = error;

    // 有了这一个，上面复制可以不要了
    ToastUtils.showError(error);
    _isLoading = false;
    _isStreaming = false;
    _streamingConversationId = null;
    notifyListeners();
  }

  /// 清除错误
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// 计算消息成本(只显示token数量,不计算花费)
  double _calculateCost(int tokens, UnifiedModelSpec model) {
    return tokens * 1.0;
  }

  /// 切换输入模式(键盘/语音)
  void toggleInputMode() {
    _isKeyboardInput = !_isKeyboardInput;
    notifyListeners();
  }

  /// ******************************************
  /// 搭档设置相关
  /// ******************************************

  /// 选择搭档
  Future<void> selectPartner(UnifiedChatPartner partner) async {
    // 换搭档场景：若对话尚无用户消息，先移除旧搭档的开场白(换搭档=换开场白)
    await _removeFirstMessagesIfNoUser();

    _currentPartner = partner;
    _isPartnerSelected = true;

    // 如果当前对话为空，应用搭档的配置到对话设置
    if (_currentConversation != null && _messages.isEmpty) {
      _currentConversation = _currentConversation!.copyWith(
        partnerId: partner.id,
        systemPrompt: partner.prompt,
        temperature: partner.temperature,
        topP: partner.topP,
        maxTokens: partner.maxTokens,
        contextMessageLength: partner.contextMessageLength,
        isStream: partner.isStream,
        updatedAt: DateTime.now(),
      );

      // 保存对话配置更新
      await _chatDao.updateConversation(_currentConversation!);
    }

    // 偏好模型：搭档配置了偏好模型且当前可用时自动切换(2026-08-31 从旧版角色卡合并)
    final preferredModelId = partner.preferredModelId;
    if (preferredModelId != null && _availableModels.isNotEmpty) {
      UnifiedModelSpec? preferred;
      for (final m in _availableModels) {
        if (m.id == preferredModelId) {
          preferred = m;
          break;
        }
      }
      if (preferred != null && preferred.id != _currentModel?.id) {
        await switchModel(preferred);
      }
    }

    // 开场白：有开场白且对话尚无用户消息时，以assistant身份落一条本地消息(不调用模型)
    await _addFirstMessageIfApplicable(partner);

    // 搭档专属背景可能生效，检查外观缓存
    _checkAppearanceCache();

    notifyListeners();
  }

  /// 清除搭档选择，切换到默认搭档
  Future<void> clearPartnerSelection() async {
    // 若对话尚无用户消息，移除开场白并清除搭档关联
    await _removeFirstMessagesIfNoUser();

    _currentPartner = null;
    _isPartnerSelected = false;

    // 如果对话为空，应用默认搭档的配置
    if (_currentConversation != null && _messages.isEmpty) {
      var updated = _currentConversation!.copyWith(
        systemPrompt: defaultPartner.prompt,
        // 2026-09-09 默认搭档未设置参数时copyWith保持会话当前值，不再回填预设
        temperature: defaultPartner.temperature,
        topP: defaultPartner.topP,
        maxTokens: defaultPartner.maxTokens,
        contextMessageLength: defaultPartner.contextMessageLength,
        isStream: defaultPartner.isStream ?? true,
        updatedAt: DateTime.now(),
      );

      // copyWith无法把partnerId置null，通过Map方式清除搭档关联
      final convMap = updated.toMap();
      convMap['partner_id'] = null;
      _currentConversation = UnifiedConversation.fromMap(convMap);

      // 保存对话配置更新
      await _chatDao.updateConversation(_currentConversation!);
    }

    // 搭档专属背景失效，检查外观缓存
    _checkAppearanceCache();

    notifyListeners();
  }

  /// 添加搭档开场白(2026-08-31 从旧版角色卡合并)：
  /// 搭档配置了开场白，且当前会话尚无任何用户/助手树消息时，
  /// 以assistant身份写入一条本地消息(不调用模型)，作为分支树根节点
  Future<void> _addFirstMessageIfApplicable(UnifiedChatPartner partner) async {
    if (_currentConversation == null || !partner.hasFirstMessage) return;
    // 已有树消息(用户或助手)则不插入，避免重复
    final hasTreeMessages = _allMessages.any(
      (m) => m.role != UnifiedMessageRole.system,
    );
    if (hasTreeMessages) return;

    final now = DateTime.now();
    final openingMessage = UnifiedChatMessage(
      id: const Uuid().v4(),
      conversationId: _currentConversation!.id,
      role: UnifiedMessageRole.assistant,
      content: partner.firstMessage!.trim(),
      contentType: UnifiedContentType.text,
      createdAt: now,
      updatedAt: now,
      // 会话首条树消息：根节点
      parentId: null,
      branchIndex: 0,
      depth: 0,
      branchPath: '0',
    );
    await _addAndSaveMessage(openingMessage);
  }

  /// 对话尚无用户消息时，移除全部开场白性质的assistant本地消息
  /// (换搭档/取消搭档时清理，恢复"空对话"语义)
  Future<void> _removeFirstMessagesIfNoUser() async {
    if (_currentConversation == null) return;
    final hasUser = _allMessages.any((m) => m.role == UnifiedMessageRole.user);
    if (hasUser) return;

    final openers = _allMessages
        .where((m) => m.role == UnifiedMessageRole.assistant)
        .toList();
    if (openers.isEmpty) return;

    for (final m in openers) {
      await _chatDao.deleteMessage(m.id);
    }
    _allMessages.removeWhere((m) => m.role == UnifiedMessageRole.assistant);
    _messages.removeWhere((m) => m.role == UnifiedMessageRole.assistant);
  }

  /// 更新搭档显示设置
  Future<void> updateShowPartnersInNewChat(bool show) async {
    _showPartnersInNewChat = show;
    await UnifiedSecureStorage.setShowPartnersInNewChat(show);

    notifyListeners();
  }

  /// ******************************************
  /// 用户设置相关
  /// ******************************************

  /// 加载用户偏好设置
  Future<void> _loadUserPreferences() async {
    try {
      _showPartnersInNewChat =
          await UnifiedSecureStorage.getShowPartnersInNewChat();
    } catch (e) {
      _showPartnersInNewChat = true;
    }
    notifyListeners();
  }

  /// 刷新用户偏好设置
  Future<void> refreshUserPreferences() async {
    await _loadUserPreferences();
    notifyListeners();
  }

  /// ******************************************
  /// 联网搜索及工具管理相关
  /// ******************************************

  /// 切换联网搜索状态
  /// [manual] 用户手动切换(true)时记录标记，此后不再跟随能力自动开关；
  /// 程序自动关(如切到无联网能力的模型，见chat_input_widget)传false
  void toggleWebSearch({bool manual = true}) {
    _isWebSearchEnabled = !_isWebSearchEnabled;
    if (manual) {
      _webSearchManuallyToggled = true;
      CusGetStorage().box.write(_webSearchManuallyToggledKey, true);
    }
    notifyListeners();
  }

  /// 2026-09-09 当前环境是否具备联网搜索能力
  /// (与chat_input_widget原_canToggleWebSearch判定一致，逻辑收口到viewmodel)：
  /// 1 平台注册了自带联网搜索适配器(智谱/阿里/火山等，见builtin_web_search_registry)
  /// 2 或 模型支持工具调用且已配置至少一个第三方搜索Key
  bool hasWebSearchCapability() {
    final hasBuiltin = BuiltinWebSearchRegistry.supportsBuiltinSearch(
      _currentPlatform?.id ?? '',
    );
    if (hasBuiltin) return true;
    return hasAvailableSearchTools() &&
        (_currentModel?.supportsToolCalling ?? false);
  }

  /// 联网开关跟随能力同步(仅在用户从未手动切换时生效)：
  /// 具备能力自动开、失去能力自动关；手动切过则完全尊重用户选择
  void _syncWebSearchWithCapability() {
    if (_webSearchManuallyToggled) return;
    final capable = hasWebSearchCapability();
    if (capable && !_isWebSearchEnabled) {
      _isWebSearchEnabled = true;
      notifyListeners();
    } else if (!capable && _isWebSearchEnabled) {
      _isWebSearchEnabled = false;
      notifyListeners();
    }
  }

  /// 获取搜索工具状态
  Map<String, bool> getSearchToolStatus() {
    return _searchToolManager.getToolStatus();
  }

  /// 检查是否有可用的搜索工具
  bool hasAvailableSearchTools() {
    return _searchToolManager.hasAvailableTools();
  }

  /// 设置搜索API密钥
  Future<void> setSearchApiKey(String toolType, String apiKey) async {
    try {
      await _searchToolManager.setApiKey(toolType, apiKey);
      notifyListeners();
    } catch (e) {
      _setError('设置搜索API密钥失败: $e');
    }
  }

  /// 测试搜索工具连接
  Future<bool> testSearchToolConnection(String toolType) async {
    try {
      return await _searchToolManager.testToolConnection(toolType);
    } catch (e) {
      ToastUtils.showError('测试搜索工具连接失败: $e');
      return false;
    }
  }

  /// 获取首选搜索工具
  Future<String?> getPreferredSearchTool() async {
    return await UnifiedSecureStorage.getPreferredSearchTool();
  }

  /// 设置首选搜索工具
  Future<void> setPreferredSearchTool(String toolType) async {
    await UnifiedSecureStorage.setPreferredSearchTool(toolType);
    notifyListeners();
  }

  /// 清除首选搜索工具设置
  Future<void> clearPreferredSearchTool() async {
    await UnifiedSecureStorage.deletePreferredSearchTool();
    notifyListeners();
  }

  /// 2026-09-09 已注册自带联网搜索能力的平台(供设置页动态生成策略配置项)
  Map<String, String> get builtinSearchPlatforms =>
      BuiltinWebSearchRegistry.registeredPlatforms;

  /// 2026-09-09 获取平台自带联网搜索策略(未设置时默认auto)
  Future<BuiltinWebSearchMode> getPlatformSearchMode(String platformId) async {
    return await _searchToolManager.getPlatformSearchMode(platformId);
  }

  /// 保存平台自带联网搜索策略
  Future<void> setPlatformSearchMode(
    String platformId,
    BuiltinWebSearchMode mode,
  ) async {
    await _searchToolManager.setPlatformSearchMode(
      platformId,
      mode.toStorage(),
    );
    notifyListeners();
  }

  /// 2026-09-09 获取百度搜索模式('retrieval'纯检索/'intelligent'智能生成)
  Future<String> getBaiduSearchMode() async {
    return await _searchToolManager.getBaiduSearchMode();
  }

  /// 保存百度搜索模式
  Future<void> setBaiduSearchMode(String mode) async {
    await _searchToolManager.setBaiduSearchMode(mode);
    notifyListeners();
  }

  /// 2026-09-12 全局搜索渠道偏好(联网开关开启时用哪个渠道搜索)
  Future<SearchChannelPreference> getSearchChannelPreference() async {
    return await _searchToolManager.getSearchChannelPreference();
  }

  /// 保存全局搜索渠道偏好
  Future<void> setSearchChannelPreference(SearchChannelPreference pref) async {
    await _searchToolManager.setSearchChannelPreference(pref);
    notifyListeners();
  }

  /// 从服务中获取搜索结果链接
  List<SearchReference>? _getSearchReferencesFromService() {
    final searchReferences = _chatService.getLastSearchReferences();
    if (searchReferences != null && searchReferences.isNotEmpty) {
      return searchReferences
          .map((ref) => SearchReference.fromSearchResultItem(ref))
          .toList();
    }
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    // 审批挂起中销毁：完成等待防止Agent协程永久挂起
    if (_approvalCompleter != null && !_approvalCompleter!.isCompleted) {
      _approvalCompleter!.complete(ToolApprovalDecision.deny);
    }
    _streamSubscription?.cancel();
    super.dispose();
  }
}
