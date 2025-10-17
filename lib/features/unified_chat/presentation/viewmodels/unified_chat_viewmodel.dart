// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/get_dir.dart';
import '../../../../core/utils/simple_tools.dart';
import '../../../../core/utils/wav_audio_handler.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../data/database/unified_chat_dao.dart';
import '../../data/models/openai_response.dart';
import '../../data/models/unified_chat_message.dart';
import '../../data/models/unified_chat_partner.dart';
import '../../data/models/unified_conversation.dart';
import '../../data/models/unified_model_spec.dart';
import '../../data/models/unified_platform_spec.dart';
import '../../data/services/unified_chat_service.dart';
import '../../data/services/image_generation_service.dart';
import '../../data/models/image_generation_request.dart';
import '../../data/services/speech_synthesis_service.dart';
import '../../data/models/speech_synthesis_request.dart';
import '../../data/services/speech_recognition_service.dart';
import '../../data/models/speech_recognition_request.dart';
import '../../data/services/unified_secure_storage.dart';
import '../../data/services/web_search_tool_manager.dart';

/// 统一聊天状态管理
class UnifiedChatViewModel extends ChangeNotifier {
  final UnifiedChatService _chatService = UnifiedChatService();
  final UnifiedChatDao _chatDao = UnifiedChatDao();
  final WebSearchToolManager _searchToolManager = WebSearchToolManager();

  /// 当前状态
  UnifiedConversation? _currentConversation;
  List<UnifiedChatMessage> _messages = [];
  List<UnifiedModelSpec> _availableModels = [];
  List<UnifiedPlatformSpec> _availablePlatforms = [];
  UnifiedModelSpec? _currentModel;
  UnifiedPlatformSpec? _currentPlatform;
  UnifiedChatPartner? _currentPartner;

  /// 对话是否开启联网搜索
  bool _isWebSearchEnabled = false;

  /// 加载和流式状态
  bool _isLoading = false;
  bool _isStreaming = false;
  String? _error;
  StreamSubscription? _streamSubscription;

  /// 搭档显示状态
  bool _showPartnersInNewChat = true;
  bool _isPartnerSelected = false;

  /// 消息编辑状态
  UnifiedChatMessage? _editingUserMessage;
  bool _isUserEditingMode = false;

  /// Getters
  UnifiedConversation? get currentConversation => _currentConversation;
  List<UnifiedChatMessage> get messages => _messages;
  List<UnifiedModelSpec> get availableModels => _availableModels;
  List<UnifiedPlatformSpec> get availablePlatforms => _availablePlatforms;
  UnifiedModelSpec? get currentModel => _currentModel;
  UnifiedPlatformSpec? get currentPlatform => _currentPlatform;
  UnifiedChatPartner? get currentPartner => _currentPartner;
  bool get isWebSearchEnabled => _isWebSearchEnabled;

  bool get isImageGenerationModel =>
      _currentModel?.type == UnifiedModelType.tti ||
      _currentModel?.type == UnifiedModelType.iti;

  bool get isSpeechSynthesisModel =>
      _currentModel?.type == UnifiedModelType.tts;

  bool get isSpeechRecognitionModel =>
      _currentModel?.type == UnifiedModelType.asr;

  // 状态getters
  bool get isLoading => _isLoading;
  bool get isStreaming => _isStreaming;
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

  /// 初始化Provider
  Future<void> initialize() async {
    _setLoading(true);

    // 首先加载用户偏好设置
    await _loadUserPreferences();

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

    _setLoading(false);
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
      await createNewConversation();
    } catch (e) {
      print('加载最近对话失败: $e');
      await _setDefaultPlatformAndModel();
      await createNewConversation();
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
  Future<void> createNewConversation({
    String? title,
    String? systemPrompt,
  }) async {
    try {
      final conversationId = const Uuid().v4();
      _currentConversation = UnifiedConversation(
        id: conversationId,
        title: title ?? '新对话',
        modelId: _currentModel?.id ?? '',
        platformId: _currentPlatform?.id ?? '',
        // 如果没有指定系统提示词，使用默认搭档的提示词
        systemPrompt: systemPrompt ?? defaultPartner.prompt,
        temperature: defaultPartner.temperature ?? 0.7,
        topP: defaultPartner.topP ?? 1.0,
        maxTokens: defaultPartner.maxTokens ?? 4096,
        contextMessageLength: defaultPartner.contextMessageLength,
        isStream: defaultPartner.isStream ?? true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 初始化空的消息列表，不添加任何消息
      _messages = [];
      // 重置搭档选择状态，以便在新对话时重新显示搭档工具组件
      _currentPartner = null;
      _isPartnerSelected = false;

      print('创建新对话: ${_currentConversation!.id}');

      // 创建新对话了要清空搜索参考
      _chatService.clearLastSearchReferences();
      notifyListeners();
    } catch (e) {
      _setError('创建新对话失败: $e');
    }
  }

  ///初始化时（即在用户首次发送消息时）保存对话到数据库
  Future<void> _initSaveConversation(String userMessage) async {
    print("_initSaveConversation中的对话 $userMessage $_currentConversation");

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
      print('保存对话失败: $e');
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
      // 如果没有可用的平台和模型，则忽略该对话
      if (_availablePlatforms.isEmpty || _availableModels.isEmpty) {
        _setLoading(false);
        ToastUtils.showToast("该对话没有可用的平台和模型，无法加载");
        return;
      }

      _currentConversation = await _chatDao.getConversation(conversationId);
      if (_currentConversation != null) {
        _messages = await _chatDao.getMessagesByConversationId(
          _currentConversation!.id,
        );

        // 确保系统消息始终在第一位
        _messages.sort((a, b) {
          if (a.role == UnifiedMessageRole.system &&
              b.role != UnifiedMessageRole.system) {
            return -1;
          } else if (a.role != UnifiedMessageRole.system &&
              b.role == UnifiedMessageRole.system) {
            return 1;
          } else {
            return a.createdAt.compareTo(b.createdAt);
          }
        });

        // 更新当前模型
        final modelId = _currentConversation!.modelId;
        _currentModel = _availableModels.firstWhere(
          (m) => m.id == modelId,
          orElse: () => _availableModels.first,
        );
        _currentPlatform = _availablePlatforms.firstWhere(
          (p) => p.id == _currentModel!.platformId,
          orElse: () => _availablePlatforms.first,
        );

        print("当前的平台和模型 $_currentPlatform $_currentModel");
      }
      _clearError();
    } catch (e) {
      _setError('加载对话失败: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 清空对话
  Future<void> clearConversation() async {
    if (_currentConversation == null) return;

    try {
      for (final message in _messages) {
        await _chatDao.deleteMessage(message.id);
      }
      _messages.clear();
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
      final directory = await getAppHomeDirectory(
        subfolder: "BAKUP/backup_files/unified_chat",
      );

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
  Future<void> updateConversationSettings(Map<String, dynamic> settings) async {
    if (_currentConversation == null) return;

    try {
      final oldSystemPrompt = _currentConversation!.systemPrompt;
      final newSystemPrompt = settings['systemPrompt'] as String?;

      _currentConversation = _currentConversation!.copyWith(
        title: settings['title'] as String?,
        systemPrompt: newSystemPrompt,
        contextMessageLength: settings['contextMessageLength'] as int?,
        temperature: settings['temperature'] as double?,
        topP: settings['topP'] as double?,
        maxTokens: settings['maxTokens'] as int?,
        isStream: settings['isStream'] as bool?,
        frequencyPenalty: settings['frequencyPenalty'] as double?,
        presencePenalty: settings['presencePenalty'] as double?,
        extraParams: {
          'enableThinking': settings['enableThinking'] as bool?,
          'omniParams': settings['omniParams'] as Map<String, dynamic>?,
          'imageGenerationParams':
              settings['imageGenerationParams'] as Map<String, dynamic>?,
          'speechSynthesisParams':
              settings['speechSynthesisParams'] as Map<String, dynamic>?,
          'speechRecognitionParams':
              settings['speechRecognitionParams'] as Map<String, dynamic>?,
        },
        updatedAt: DateTime.now(),
      );

      // 如果系统提示词发生变化，更新对应的系统消息
      if (oldSystemPrompt != newSystemPrompt) {
        await _updateSystemMessage(newSystemPrompt);
      }

      await _chatDao.updateConversation(_currentConversation!);
      notifyListeners();
    } catch (e) {
      _setError('更新设置失败: $e');
    }
  }

  /// 更新对话统计信息
  Future<void> _updateConversationStats() async {
    if (_currentConversation == null) return;

    final totalTokens = _messages.fold<int>(0, (sum, msg) => sum + msg.tokens);
    final totalCost = _messages.fold<double>(0, (sum, msg) => sum + msg.cost);

    _currentConversation = _currentConversation!.copyWith(
      messageCount: _messages.length,
      totalTokens: totalTokens,
      totalCost: totalCost,
      updatedAt: DateTime.now(),
    );

    await _chatDao.updateConversation(_currentConversation!);
  }

  /// ******************************************
  /// 消息处理
  /// ******************************************

  /// 发送文本消息
  Future<void> sendMessage(String content, {bool isWebSearch = false}) async {
    print(
      "sendmessage中的消息和对话 $_currentModel $_currentPlatform\n $content $_currentConversation",
    );

    if (content.trim().isEmpty || _currentConversation == null) return;

    try {
      // 如果是第一条用户消息，先创建并保存系统消息
      if (_messages.isEmpty) {
        await _initSaveConversation(content.trim());

        await _createAndSaveSystemMessageIfNeeded();
      }

      // 添加用户消息
      final userMessage = _createUserPlaceholder(content.trim());

      _messages.add(userMessage);
      await _chatDao.saveMessage(userMessage);
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

    print("发送多模态消息");
    print("文本: $text");
    print("图片: ${images?.map((f) => f.path).join(', ')}");
    print("音频: ${audio?.path}");
    print("视频: ${video?.path}");
    print("文件: ${files?.map((f) => f.path).join(', ')}");

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
      await _chatDao.saveMessage(userMessage);
      notifyListeners();

      print(
        'sendMultimodalMessage------发送请求前的消息内容: ${_messages.where((m) => !m.isStreaming).map((m) => m.toRawJson()).join('\n')}',
      );

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
    print(
      "_sendMessageToAI中的对话 ${messages.length} $_currentConversation $_currentModel",
    );

    if (_currentConversation == null || _currentModel == null) return;

    // 发送请求前不应该保留之前的参考内容
    _chatService.clearLastSearchReferences();
    _setStreaming(true);

    try {
      final messagesToSend = _prepareMessagesForSending(messages);
      final assistantMessage = _createAssistantPlaceholder();

      _messages.add(assistantMessage);
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
    final contextMessageLength = _currentConversation!.contextMessageLength;
    if (messagesToSend.length > contextMessageLength) {
      // 保留最近的 contextMessageLength 条消息，但保留系统消息
      final systemMessages = messagesToSend
          .where((m) => m.role == UnifiedMessageRole.system)
          .toList();
      final nonSystemMessages = messagesToSend
          .where((m) => m.role != UnifiedMessageRole.system)
          .toList();

      // 取最近的消息
      final recentMessages =
          nonSystemMessages.length >
              (contextMessageLength - systemMessages.length)
          ? nonSystemMessages.sublist(
              nonSystemMessages.length -
                  (contextMessageLength - systemMessages.length),
            )
          : nonSystemMessages;

      messagesToSend = [...systemMessages, ...recentMessages];
    }

    print("----------------${messagesToSend.length}");
    // 验证并修复消息序列
    // 注意：不要在这里清除搭档选择状态，保持搭档信息在整个对话期间可用
    return _validateAndFixMessageSequence(messagesToSend);
  }

  /// 创建用户消息
  UnifiedChatMessage _createUserPlaceholder(
    String content, {
    UnifiedContentType? contentType,
    List<UnifiedContentItem>? multimodalContent,
    Map<String, dynamic>? metadata,
  }) {
    return UnifiedChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
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
    );
  }

  /// 创建助手消息占位符
  UnifiedChatMessage _createAssistantPlaceholder({String? content}) {
    return UnifiedChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
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
    );
  }

  /// 创建系统消息占位符
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
    );
  }

  /// 处理流式响应
  Future<void> _handleStreamResponse(
    Stream<OpenAIChatCompletionResponse> stream,
    UnifiedChatMessage assistantMessage,
    bool isWebSearch,
  ) async {
    // 流式响应累加的文本内容
    String accumulatedContent = '';
    // 流式响应累加的思考内容
    String accumulatedThinking = '';
    // 构建多模态内容列表
    final multimodalContent = <UnifiedContentItem>[];
    // 2025-10-16 多模态千问omni可以合成语音，响应中有base64语音片段
    // 在流响应完成或者手动终止时，才把已经收集到的片段转为语音，再提供播放
    String finalAudioBase64 = "";
    // 是否在思考中
    bool isInThinking = false;
    // 开始思考时间
    var startTime = DateTime.now();
    // 结束思考时间
    DateTime? endTime;
    // 思考时长
    var thinkingTime = 0;

    _streamSubscription = stream.listen(
      (response) async {
        // // 第一种：直接在这里更新消息内容
        // final index = _messages.indexWhere((m) => m.id == assistantMessage.id);

        // if (index == -1) {
        //   return;
        // }

        // // 处理流式内容
        // if (response.choices.isNotEmpty) {
        //   final choice = response.choices.first;
        //   // 如果非流式响应的内容放在message中，包装成一次流式响应。delta和message结构一致，可以统一处理
        //   final delta = choice.delta ?? choice.message;

        //   // print('收到流式响应delta数据: ${delta?.toRawJson()} ');

        //   // 如果reasoning_content非空，也是推理过程
        //   if (delta != null &&
        //       delta.reasoningContent != null &&
        //       delta.reasoningContent!.isNotEmpty) {
        //     final newThinking = delta.reasoningContent!;
        //     // print('新推理片段: "$newThinking"');
        //     accumulatedThinking += newThinking;

        //     // 计算思考时间(从发起调用开始，到当流式内容不为空时计算结束)
        //     if (endTime == null &&
        //         delta.content != null &&
        //         delta.content!.isNotEmpty) {
        //       endTime = DateTime.now();
        //       thinkingTime = endTime!.difference(startTime).inMilliseconds;
        //     }
        //   }

        //   // print('Delta内容: role=${delta?.role}, content=${delta?.content}');

        //   if (delta != null &&
        //       delta.content != null &&
        //       delta.content!.isNotEmpty) {
        //     final newContent = delta.content!;
        //     // print('新内容片段: "$newContent"');

        //     // 检测思考内容的开始和结束标记
        //     if (newContent.contains('<thinking>') ||
        //         newContent.contains('<think>')) {
        //       isInThinking = true;
        //       startTime = DateTime.now();
        //       print('开始思考模式');
        //     }

        //     if (isInThinking) {
        //       accumulatedThinking += newContent;
        //       if (newContent.contains('</thinking>') ||
        //           newContent.contains('</think>')) {
        //         isInThinking = false;
        //         print('结束思考模式');
        //         // 清理思考内容的标记
        //         accumulatedThinking = accumulatedThinking
        //             .replaceAll('<thinking>', '')
        //             .replaceAll('</thinking>', '')
        //             .replaceAll('<think>', '')
        //             .replaceAll('</think>', '')
        //             .trim();
        //       }
        //     } else {
        //       if (endTime == null) {
        //         endTime = DateTime.now();
        //         thinkingTime = endTime!.difference(startTime).inMilliseconds;
        //       }

        //       accumulatedContent += newContent;
        //       // print('累积内容长度: ${accumulatedContent.length}');
        //     }
        //   }

        //   // print("音频数据内容 ${delta?.audio?['data']}");

        //   finalAudioBase64 += delta?.audio?['data'] ?? '';

        //   // 检查是否完成
        //   // 模型停止生成 token 的原因。
        //   // stop：模型自然停止生成，或遇到 stop 序列中列出的字符串。
        //   // length ：输出长度达到了模型上下文长度限制，或达到了 max_tokens 的限制。
        //   // content_filter：输出内容因触发过滤策略而被过滤。
        //   // insufficient_system_resource：系统推理资源不足，生成被打断。
        //   if (choice.finishReason != null) {
        //     print('流式完成，原因: ${choice.finishReason}');
        //     // print(
        //     //   'Delta内容: role=${json.encode(choice.toJson())}, content=${choice.delta?.content}',
        //     // );

        //     String voicePath = '';
        //     // 如果是多模态有响应音频base64数据，保存到固定的位置
        //     if (finalAudioBase64.isNotEmpty) {
        //       voicePath = await WavAudioHandler.saveBase64Wav(
        //         finalAudioBase64,
        //         model: _currentModel?.modelName,
        //       );
        //     }

        //     // 添加文本内容（如果存在）
        //     if (accumulatedContent.trim().isNotEmpty) {
        //       multimodalContent.add(
        //         UnifiedContentItem.text(accumulatedContent.trim()),
        //       );
        //     }

        //     // 添加音频内容
        //     if (voicePath.isNotEmpty) {
        //       multimodalContent.add(
        //         UnifiedContentItem.audio(
        //           voicePath,
        //           fileName: voicePath.split('/').last,
        //           fileSize: await getFileSize(File(voicePath)),
        //         ),
        //       );
        //     }
        //   }
        // }

        // _messages[index] = _messages[index].copyWith(
        //   content: accumulatedContent,
        //   thinkingContent: accumulatedThinking.isNotEmpty
        //       ? accumulatedThinking
        //       : null,
        //   thinkingTime: thinkingTime,
        //   multimodalContent: multimodalContent,
        //   tokenCount:
        //       response.usage?.totalTokens ?? _messages[index].tokenCount,
        //   cost: response.usage?.totalTokens != null
        //       ? _calculateCost(response.usage!.totalTokens, _currentModel!)
        //       : _messages[index].cost,
        //   // 如果是搜索相关的响应，添加搜索结果链接
        //   searchReferences: isWebSearch && _isWebSearchEnabled
        //       ? _getSearchReferencesFromService()
        //       : _messages[index].searchReferences,
        //   updatedAt: DateTime.now(),
        // );

        // // print('更新消息内容: "${_messages[index].content}"');
        // notifyListeners();

        // 第二种：使用单独处理方法，通过返回值更新累加变量（嫌麻烦但已经写了就留个备份）
        final chunkResult = await _processStreamChunk(
          response,
          assistantMessage,
          isWebSearch,
          accumulatedContent,
          accumulatedThinking,
          multimodalContent,
          finalAudioBase64,
          isInThinking,
          startTime,
          endTime,
          thinkingTime,
        );

        // 更新累加变量
        accumulatedContent = chunkResult.accumulatedContent;
        accumulatedThinking = chunkResult.accumulatedThinking;
        finalAudioBase64 = chunkResult.finalAudioBase64;
        isInThinking = chunkResult.isInThinking;
        endTime = chunkResult.endTime;
        thinkingTime = chunkResult.thinkingTime;

        notifyListeners();
      },
      onDone: () async {
        await _handleStreamDone(assistantMessage);
      },
      onError: (error) {
        _handleStreamError(error, assistantMessage);
      },
    );
  }

  /// 处理流式数据块
  Future<_StreamChunkResult> _processStreamChunk(
    OpenAIChatCompletionResponse response,
    UnifiedChatMessage assistantMessage,
    bool isWebSearch,
    String accumulatedContent,
    String accumulatedThinking,
    List<UnifiedContentItem> multimodalContent,
    String finalAudioBase64,
    bool isInThinking,
    DateTime startTime,
    DateTime? endTime,
    int thinkingTime,
  ) async {
    // 更新消息内容
    final index = _messages.indexWhere((m) => m.id == assistantMessage.id);
    // 如果没有助手消则无法更新AI响应,直接返回原始值
    if (index == -1) {
      return _StreamChunkResult(
        accumulatedContent: accumulatedContent,
        accumulatedThinking: accumulatedThinking,
        finalAudioBase64: finalAudioBase64,
        isInThinking: isInThinking,
        endTime: endTime,
        thinkingTime: thinkingTime,
        multimodalContent: multimodalContent,
      );
    }

    // 有助手消息,处理流式内容
    if (response.choices.isNotEmpty) {
      final choice = response.choices.first;
      // 如果非流式响应的内容放在message中，包装成一次流式响应。
      // delta和message结构一致，可以统一处理
      final delta = choice.delta ?? choice.message;

      // print('收到流式响应xxx: ${delta?.toRawJson()} ');

      // 处理单独推理内容
      if (delta != null &&
          delta.reasoningContent != null &&
          delta.reasoningContent!.isNotEmpty) {
        accumulatedThinking += delta.reasoningContent!;
      }

      // 处理正常内容中思考模式
      if (delta != null && delta.content != null && delta.content!.isNotEmpty) {
        final newContent = delta.content!;

        // 检测思考内容的开始和结束标记
        if (newContent.contains('<thinking>') ||
            newContent.contains('<think>')) {
          isInThinking = true;
          startTime = DateTime.now();
          print('开始思考模式');
        }

        // 处理正常内容中的思考内容
        if (isInThinking) {
          accumulatedThinking += newContent;
          if (newContent.contains('</thinking>') ||
              newContent.contains('</think>')) {
            isInThinking = false;
            print('结束思考模式');
            // 清理思考内容的标记
            accumulatedThinking = accumulatedThinking
                .replaceAll('<thinking>', '')
                .replaceAll('</thinking>', '')
                .replaceAll('<think>', '')
                .replaceAll('</think>', '')
                .trim();
          }
        } else {
          // 思考标签结束后,计算思考时长
          if (endTime == null) {
            endTime = DateTime.now();
            thinkingTime = endTime.difference(startTime).inMilliseconds;
          }

          // 处理正常内容的正常响应
          accumulatedContent += newContent;
        }
      }

      // print("正常累加内容$accumulatedContent");

      // 处理语音(omni等模型可能有流式追加的音频二进制数据需要累加起来)
      finalAudioBase64 += delta?.audio?['data'] ?? '';

      print("xxxxxxxxxxxxxxx$multimodalContent");

      // 检查是否完成
      // 模型停止生成 token 的原因。
      // stop：模型自然停止生成，或遇到 stop 序列中列出的字符串。
      // length ：输出长度达到了模型上下文长度限制，或达到了 max_tokens 的限制。
      // content_filter：输出内容因触发过滤策略而被过滤。
      // insufficient_system_resource：系统推理资源不足，生成被打断。
      if (choice.finishReason != null) {
        print('流式完成，原因: ${choice.finishReason}');
        // 正常停止时,需要把累加的音频数据转为音频文件,并把文本和音频文件等放到消息多模态栏位

        print("文本内容 $accumulatedContent 音频内容 $finalAudioBase64 ");

        String voicePath = '';
        // 如果是多模态有响应音频base64数据，保存到固定的位置
        if (finalAudioBase64.isNotEmpty) {
          voicePath = await WavAudioHandler.saveBase64Wav(
            finalAudioBase64,
            model: _currentModel?.modelName,
          );
        }

        // 添加文本内容（如果存在）
        if (accumulatedContent.trim().isNotEmpty) {
          multimodalContent.add(
            UnifiedContentItem.text(accumulatedContent.trim()),
          );
        }

        print("voicePath: $voicePath");

        // 添加音频内容
        if (voicePath.isNotEmpty) {
          print("xxxxxxxxvoicePath: $voicePath");

          multimodalContent.add(
            UnifiedContentItem.audio(
              voicePath,
              fileName: voicePath.split('/').last,
              fileSize: await getFileSize(File(voicePath)),
            ),
          );
        }

        // 有多模态异步处理数据，在此处保存到数据库，否则在流结束时保存时是null的
        final saveMessage = _messages[index].copyWith(
          content: accumulatedContent,
          thinkingContent: accumulatedThinking.isNotEmpty
              ? accumulatedThinking
              : null,
          thinkingTime: thinkingTime,
          contentType: multimodalContent.isNotEmpty
              ? UnifiedContentType.multimodal
              : UnifiedContentType.text,
          multimodalContent: multimodalContent.isNotEmpty
              ? multimodalContent
              : null,
          tokenCount:
              response.usage?.totalTokens ?? _messages[index].tokenCount,
          cost: response.usage?.totalTokens != null
              ? _calculateCost(response.usage!.totalTokens, _currentModel!)
              : _messages[index].cost,
          // 如果是搜索相关的响应，添加搜索结果链接
          searchReferences: isWebSearch && _isWebSearchEnabled
              ? _getSearchReferencesFromService()
              : _messages[index].searchReferences,
          updatedAt: DateTime.now(),
        );

        _chatDao.saveMessage(saveMessage);
      }

      /// 实时追加更新助手消息
      _messages[index] = _messages[index].copyWith(
        content: accumulatedContent,
        thinkingContent: accumulatedThinking.isNotEmpty
            ? accumulatedThinking
            : null,
        thinkingTime: thinkingTime,
        contentType: multimodalContent.isNotEmpty
            ? UnifiedContentType.multimodal
            : UnifiedContentType.text,
        multimodalContent: multimodalContent.isNotEmpty
            ? multimodalContent
            : null,
        tokenCount: response.usage?.totalTokens ?? _messages[index].tokenCount,
        cost: response.usage?.totalTokens != null
            ? _calculateCost(response.usage!.totalTokens, _currentModel!)
            : _messages[index].cost,
        // 如果是搜索相关的响应，添加搜索结果链接
        searchReferences: isWebSearch && _isWebSearchEnabled
            ? _getSearchReferencesFromService()
            : _messages[index].searchReferences,
        updatedAt: DateTime.now(),
      );
      // print('更新消息内容: "${_messages[index].content}"');
      notifyListeners();
    }

    // 返回更新后的累加变量
    return _StreamChunkResult(
      accumulatedContent: accumulatedContent,
      accumulatedThinking: accumulatedThinking,
      finalAudioBase64: finalAudioBase64,
      isInThinking: isInThinking,
      endTime: endTime,
      thinkingTime: thinkingTime,
      multimodalContent: multimodalContent,
    );
  }

  /// 处理流式完成
  /// 特别注意，在finishReason不为null时的结束处理，和这里没有关系
  /// 在finishReason保存音频文件等异步操作构建的多模态数据，这里是取不到的，所以在finishReason需要先保存
  /// 那么在这里，就不太清楚实际作用了
  Future<void> _handleStreamDone(UnifiedChatMessage assistantMessage) async {
    print('流式响应完成');

    // 流式完成，保存最终消息(注意，有时候解析失败，会无法正确保存token使用量等内容)
    final index = _messages.indexWhere((m) => m.id == assistantMessage.id);

    print(_messages[index]);

    if (index != -1) {
      final finalMessage = _messages[index].copyWith(
        isStreaming: false,
        updatedAt: DateTime.now(),
      );
      print(
        '[流式完成]保存最终消息: "${finalMessage.content}"\n${finalMessage.multimodalContent}',
      );

      _updateAssistantMessage(finalMessage);

      // 更新对话统计, 对话处理完了要清空搜索参考
      await _updateConversationStats();
      _chatService.clearLastSearchReferences();
    }

    _setStreaming(false);
  }

  /// 处理流式错误
  void _handleStreamError(Object error, UnifiedChatMessage assistantMessage) {
    print('流式响应错误, 类型:${error.runtimeType} 内容:$error');

    // 在对话中显示错误而不是统一错误页面
    final index = _messages.indexWhere((m) => m.id == assistantMessage.id);
    if (index != -1) {
      final errorMessage = _messages[index].copyWith(
        content: 'AI回复失败: $error',
        isStreaming: false,
        isError: true,
        errorMessage: error.toString(),
        updatedAt: DateTime.now(),
      );
      _messages[index] = errorMessage;
      _chatDao.saveMessage(errorMessage);
      notifyListeners();
    }

    _chatService.clearLastSearchReferences();
    _setStreaming(false);
  }

  /// 处理发送请求异常
  Future<void> _handleMessageSendError(Object error) async {
    print('发送请求异常: $error');
    if (_currentConversation == null) return;

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
    }

    // 保存发送错误消息并清空搜索参考
    await _chatDao.saveMessage(errorMessage);
    _chatService.clearLastSearchReferences();
    _setStreaming(false);
  }

  /// 更新占位助手消息(包括cc\多模态正常响应,报错等情况)
  Future<void> _updateAssistantMessage(
    // 被更新的助手消息
    UnifiedChatMessage assistantMessage,
  ) async {
    final index = _messages.indexWhere((m) => m.id == assistantMessage.id);
    if (index != -1) {
      _messages[index] = assistantMessage;
    }

    // 保存错误消息到数据库
    await _chatDao.saveMessage(assistantMessage);
  }

  /// 发送图片生成消息
  Future<void> sendImageGenerationMessage({
    required String prompt,
    List<File>? images,
    Map<String, dynamic>? settings,
  }) async {
    print(
      "-------------发送图片生成消息 ${_currentConversation?.id} $_currentModel $_currentPlatform",
    );
    print(prompt);

    if (_currentConversation == null ||
        _currentModel == null ||
        _currentPlatform == null) {
      return;
    }

    // 初始化对话保存
    await _initSaveConversation(prompt.trim());

    // 构建多模态内容列表（图片生成，只处理图片内容）
    final multimodalContent = <UnifiedContentItem>[];

    print("图片生成---开始添加图片 $images ${images != null} ${images?.isNotEmpty}");

    // 添加文本内容（如果存在）
    if (prompt.trim().isNotEmpty) {
      multimodalContent.add(UnifiedContentItem.text(prompt.trim()));
    }

    // 添加图片内容
    if (images != null && images.isNotEmpty) {
      for (final image in images) {
        print("添加图片: ${image.path}");

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
    notifyListeners();

    // 保存用户消息到数据库
    await _chatDao.saveMessage(userMessage);

    // 构建完整的图片生成提示词（包含历史用户消息）
    final allUserMessages = _messages
        .where((m) => m.role == UnifiedMessageRole.user)
        .map((m) => m.content ?? '')
        .where((content) => content.isNotEmpty)
        .toList();

    final combinedPrompt = allUserMessages.join('\n\n');

    // 创建助手消息占位符
    final assistantMessage = _createAssistantPlaceholder(
      content: '正在生成图片，请勿退出...\n',
    );

    _messages.add(assistantMessage);
    notifyListeners();

    try {
      // 准备参考图片地址（如果是图生图模型且有选择的图片）
      List<String>? referenceImages;
      if (_currentModel!.type == UnifiedModelType.iti &&
          images?.isNotEmpty == true) {
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
        metadata: {'images': newUrls},
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
    final userMessage = _createUserPlaceholder(text);

    // 添加用户消息到列表
    _messages.add(userMessage);
    notifyListeners();

    // 保存用户消息到数据库
    await _chatDao.saveMessage(userMessage);

    // 创建助手消息占位符
    final assistantMessage = _createAssistantPlaceholder(
      content: '正在合成语音，请勿退出...\n',
    );

    _messages.add(assistantMessage);
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
          if (newUrl != null) 'audio': newUrl,
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
    notifyListeners();

    // 保存用户消息到数据库
    await _chatDao.saveMessage(userMessage);

    // 创建助手消息占位符
    final assistantMessage = _createAssistantPlaceholder(
      content: '正在识别语音，请勿退出...\n',
    );

    _messages.add(assistantMessage);
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

  /// 重新生成响应消息
  Future<void> regenerateMessage(
    UnifiedChatMessage message, {
    bool isWebSearch = false,
  }) async {
    print("点击了重新生成消息 ${message.role} $_currentConversation");

    if (_currentConversation == null ||
        message.role != UnifiedMessageRole.assistant) {
      return;
    }

    try {
      // 移除当前消息及其后的所有消息
      final messageIndex = _messages.indexWhere((m) => m.id == message.id);

      print("删除了11111 $messageIndex 条消息-------------------------------");
      if (messageIndex != -1) {
        // 从数据库中删除该条及其之后的消息(注意，如果后续有实现分支对话逻辑，这里就不是删除而是创建新分支了)
        await _chatDao.deleteMessageAndAfter(
          _currentConversation!.id,
          _messages[messageIndex],
        );

        _messages.removeRange(messageIndex, _messages.length);

        notifyListeners();

        // 重新发送请求
        await _sendMessageToAI(_messages, isWebSearch: isWebSearch);
      }
    } catch (e) {
      _setError('重新生成失败: $e');
    }
  }

  /// 删除消息
  Future<void> deleteMessage(UnifiedChatMessage message) async {
    try {
      await _chatDao.deleteMessage(message.id);
      _messages.removeWhere((m) => m.id == message.id);
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
      _messages.removeWhere((m) => m.id == message.id);
      _messages.add(message);
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
        _messages.removeAt(systemMessageIndex);
      } else {
        // 更新现有系统消息
        final oldSystemMessage = _messages[systemMessageIndex];
        final updatedSystemMessage = oldSystemMessage.copyWith(
          content: newSystemPrompt,
          updatedAt: DateTime.now(),
        );

        await _chatDao.updateMessage(updatedSystemMessage);
        _messages[systemMessageIndex] = updatedSystemMessage;
      }
    } else if (newSystemPrompt != null && newSystemPrompt.isNotEmpty) {
      // 如果没有系统消息但新提示词不为空，创建新的系统消息
      final systemMessage = _createSystemPlaceholder(newSystemPrompt);

      await _chatDao.saveMessage(systemMessage);
      _messages.insert(0, systemMessage);
    }
  }

  /// 用户重新发送消息
  Future<void> resendUserMessage(
    UnifiedChatMessage message, {
    bool isWebSearch = false,
  }) async {
    if (_currentConversation == null ||
        message.role != UnifiedMessageRole.user) {
      return;
    }

    try {
      // 移除当前用户消息之后的所有消息(但保留当前用户消息)
      final messageIndex = _messages.indexWhere((m) => m.id == message.id);
      if (messageIndex != -1) {
        // 注意，如果删除的是重新生成消息后面的所有消息，让重新发送的这一条为最大索引的消息，那么就不能删除了
        if (messageIndex + 1 < _messages.length) {
          // 移除当前用户消息之后的所有消息(但保留当前用户消息)
          await _chatDao.deleteMessageAndAfter(
            _currentConversation!.id,
            _messages[messageIndex + 1],
          );

          _messages.removeRange(messageIndex + 1, _messages.length);
        }

        notifyListeners();
        // 重新发送请求
        await _sendMessageToAI(_messages, isWebSearch: isWebSearch);
      }
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
    notifyListeners();
  }

  /// 取消编辑消息
  void cancelEditingUserMessage() {
    _editingUserMessage = null;
    _isUserEditingMode = false;
    notifyListeners();
  }

  /// 完成编辑消息并发送
  Future<void> finishEditingUserMessage(
    String newContent, {
    bool isWebSearch = false,
  }) async {
    if (_editingUserMessage == null || _currentConversation == null) return;

    try {
      // 找到要编辑的消息在列表中的位置
      final editingIndex = _messages.indexWhere(
        (m) => m.id == _editingUserMessage!.id,
      );
      if (editingIndex == -1) return;

      // 删除该消息及之后的所有消息
      final messagesToDelete = _messages.sublist(editingIndex);
      for (final msg in messagesToDelete) {
        await _chatDao.deleteMessage(msg.id);
      }
      _messages.removeRange(editingIndex, _messages.length);

      // 注意，如果之前发送的是多模态消息，编辑用户消息之后，也应该发送多模态消息
      if (_editingUserMessage!.contentType == UnifiedContentType.multimodal) {
        var bultiCont = _editingUserMessage!.multimodalContent;

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

        await sendMultimodalMessage(
          newContent,
          images: images,
          audio: audio,
          video: video,
          files: files,
          isWebSearch: isWebSearch,
        );
        return;
      }

      // 清除编辑状态
      _editingUserMessage = null;
      _isUserEditingMode = false;

      notifyListeners();

      // 发送新的用户消息
      await sendMessage(newContent, isWebSearch: isWebSearch);
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
    print("执行了切换模型 ${model.id}");

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
      'speechSynthesisParams': null,
      'speechRecognitionParams': null,
    });

    notifyListeners();
  }

  /// ******************************************
  /// 状态设置相关
  /// ******************************************

  /// 停止流式生成
  void stopStreaming() async {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _chatService.cancelStreaming();

    // 标记流式消息为完成并保存到数据库
    for (int i = 0; i < _messages.length; i++) {
      if (_messages[i].isStreaming) {
        final stoppedMessage = _messages[i].copyWith(
          isStreaming: false,
          content: '${_messages[i].content} [手动终止]',
          updatedAt: DateTime.now(),
        );
        _messages[i] = stoppedMessage;
        // 保存被停止的消息
        await _chatDao.saveMessage(stoppedMessage);
      }
    }

    // 更新对话统计
    await _updateConversationStats();
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
    notifyListeners();
  }

  /// 设置错误
  void _setError(String error) {
    _error = error;
    _isLoading = false;
    _isStreaming = false;
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

  /// ******************************************
  /// 搭档设置相关
  /// ******************************************

  /// 选择搭档
  Future<void> selectPartner(UnifiedChatPartner partner) async {
    _currentPartner = partner;
    _isPartnerSelected = true;

    // 如果当前对话为空，应用搭档的配置到对话设置
    if (_currentConversation != null && _messages.isEmpty) {
      _currentConversation = _currentConversation!.copyWith(
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

    print(
      'DEBUG: 选择搭档 ${partner.name}, _isPartnerSelected: $_isPartnerSelected',
    );
    print('DEBUG: shouldShowSelectedPartner: $shouldShowSelectedPartner');

    notifyListeners();
  }

  /// 清除搭档选择，切换到默认搭档
  Future<void> clearPartnerSelection() async {
    _currentPartner = null;
    _isPartnerSelected = false;

    // 如果对话为空，应用默认搭档的配置
    if (_currentConversation != null && _messages.isEmpty) {
      _currentConversation = _currentConversation!.copyWith(
        systemPrompt: defaultPartner.prompt,
        temperature: defaultPartner.temperature ?? 0.7,
        topP: defaultPartner.topP ?? 1.0,
        maxTokens: defaultPartner.maxTokens ?? 4096,
        contextMessageLength: defaultPartner.contextMessageLength,
        isStream: defaultPartner.isStream ?? true,
        updatedAt: DateTime.now(),
      );

      // 保存对话配置更新
      await _chatDao.updateConversation(_currentConversation!);
    }

    notifyListeners();
  }

  /// 更新搭档显示设置
  Future<void> updateShowPartnersInNewChat(bool show) async {
    _showPartnersInNewChat = show;
    await UnifiedSecureStorage.setShowPartnersInNewChat(show);
    print("更新搭档显示设置: $show $showPartnersInNewChat");
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
      print("加载用户偏好设置: $_showPartnersInNewChat");
    } catch (e) {
      print('加载用户偏好设置失败: $e');
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
  void toggleWebSearch() {
    _isWebSearchEnabled = !_isWebSearchEnabled;
    print('联网搜索状态切换为: $_isWebSearchEnabled');
    notifyListeners();
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
      print('测试搜索工具连接失败: $e');
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
    _streamSubscription?.cancel();
    super.dispose();
  }
}

/// 流式处理结果
class _StreamChunkResult {
  final String accumulatedContent;
  final String accumulatedThinking;
  final String finalAudioBase64;
  final bool isInThinking;
  final DateTime? endTime;
  final int thinkingTime;
  final List<UnifiedContentItem> multimodalContent;

  _StreamChunkResult({
    required this.accumulatedContent,
    required this.accumulatedThinking,
    required this.finalAudioBase64,
    required this.isInThinking,
    required this.endTime,
    required this.thinkingTime,
    required this.multimodalContent,
  });
}
