// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../../core/entities/cus_llm_model.dart';
import '../../../../shared/constants/constant_llm_enum.dart';
import '../database/unified_chat_dao.dart';
import '../models/branch_chat_export_data.dart';
import '../models/character_card.dart';
import '../models/unified_chat_message.dart';
import '../models/unified_chat_partner.dart';
import '../models/unified_conversation.dart';
import '../models/unified_model_spec.dart';
import '../models/unified_platform_spec.dart';
import 'unified_secure_storage.dart';

/// 旧版 branch_chat 数据 -> 新版 unified_chat 的转换导入器
/// 2026-08-31 配合"合并恢复"使用：旧版全量备份中的分支会话历史json
/// 在恢复时直接转换导入新版统一聊天模块
/// 2026-09-01 0.1.5：仅保留json导入路径(ObjectBox依赖已整体移除)
class BranchChatImporter {
  final UnifiedChatDao _dao = UnifiedChatDao();

  /// 从备份json数据导入(幂等：已导入的会话自动跳过)
  Future<BranchChatImportResult> importFromJson(
    Map<String, dynamic> jsonData, {
    void Function(int done, int total, String title)? onProgress,
    bool Function()? cancelCheck,
  }) async {
    final importData = BranchChatExportData.fromJson(jsonData);
    return _importSessionExports(
      importData.sessions,
      onProgress: onProgress,
      cancelCheck: cancelCheck,
    );
  }

  /// 导入单个旧角色为搭档；返回false表示已存在(跳过)
  Future<bool> importCharacter(CharacterCard character) async {
    final partnerId = 'migrated_${character.characterId}';
    if (await _dao.getChatPartner(partnerId) != null) return false;
    await _ensurePartner(character);
    return true;
  }

  /// 会话转换导入核心(两个数据源共用)
  Future<BranchChatImportResult> _importSessionExports(
    List<BranchChatSessionExport> sessions, {
    void Function(int done, int total, String title)? onProgress,
    bool Function()? cancelCheck,
  }) async {
    int imported = 0, skipped = 0, failed = 0;
    final errors = <String>[];
    final total = sessions.length;
    var done = 0;

    for (final sessionExport in sessions) {
      if (cancelCheck?.call() == true) break;
      done++;
      onProgress?.call(done, total, sessionExport.title);

      // 幂等判重：会话id固定为 migrated_前缀+旧id，重复恢复直接跳过
      final convId = 'migrated_${sessionExport.id}';
      if (await _dao.existsConversation(convId)) {
        skipped++;
        continue;
      }

      try {
        await _importSingleSession(sessionExport, convId);
        imported++;
      } catch (e) {
        print('导入旧版会话[${sessionExport.title}]失败: $e');
        errors.add('${sessionExport.title}: $e');
        failed++;
      }
    }

    return BranchChatImportResult(
      importedCount: imported,
      skippedCount: skipped,
      failedCount: failed,
      errors: errors,
    );
  }

  Future<void> _importSingleSession(
    BranchChatSessionExport sessionExport,
    String convId,
  ) async {
    // 1. 平台映射：内置平台直接用同名id；旧平台(baidu/tencent/volcesBot/custom)建自定义平台行
    final platformId = await _ensurePlatform(sessionExport.llmSpec);

    // 2. 模型映射：优先匹配平台下已有的同名模型，没有则创建自定义模型行
    final modelId = await _ensureModel(platformId, sessionExport.llmSpec);

    // 3. 角色映射：0.1.5 起旧角色已先经"角色卡json恢复"转为搭档，
    //    此处按固定约定 migrated_<旧角色id> 直查；不存在则空提示词
    final spec = sessionExport.llmSpec;
    String? partnerId;
    String? systemPrompt;

    if (sessionExport.characterId != null) {
      try {
        final mappedId = 'migrated_${sessionExport.characterId}';
        final partner = await _dao.getChatPartner(mappedId);
        if (partner != null) {
          partnerId = mappedId;
          systemPrompt = partner.prompt;
        }
      } catch (e) {
        // 角色映射失败不影响导入
        print('映射旧版角色[${sessionExport.characterId}]失败: $e');
      }
    }

    // 4. 创建会话
    final now = DateTime.now();
    final conversation = UnifiedConversation(
      id: convId,
      title: sessionExport.title,
      modelId: modelId,
      platformId: platformId,
      partnerId: partnerId,
      systemPrompt: systemPrompt,
      // 旧版发送全量上下文，这里用较大值近似旧行为
      contextMessageLength: 100,
      extraParams: {
        'migratedFrom': 'branch_chat',
        'legacySessionId': sessionExport.id,
        'legacyModelType': sessionExport.modelType.name,
      },
      createdAt: sessionExport.createTime,
      updatedAt: sessionExport.updateTime,
    );
    await _dao.saveConversation(conversation);

    // 5. system消息(不入树)
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      final systemMessage = UnifiedChatMessage(
        id: 'sys_migrated_${sessionExport.id}',
        conversationId: convId,
        role: UnifiedMessageRole.system,
        content: systemPrompt,
        contentType: UnifiedContentType.text,
        modelNameUsed: spec.model,
        platformIdUsed: platformId,
        depth: -1,
        branchPath: '',
        createdAt: sessionExport.createTime,
        updatedAt: sessionExport.createTime,
      );
      await _dao.saveMessage(systemMessage);
    }

    // 6. 导入消息：按depth升序，分支字段原样迁移，messageId直接作为新id
    final sortedMessages = sessionExport.messages.toList()
      ..sort((a, b) => a.depth.compareTo(b.depth));

    for (final msg in sortedMessages) {
      final message = _convertMessage(msg, convId, platformId, spec);
      // 同id消息已存在则跳过(理论上新会话不会，防御性处理)
      if (await _dao.existsMessage(message.id)) continue;
      await _dao.saveMessage(message);
    }

    // 7. 更新会话统计
    await _updateStatsForMigratedConversation(convId, conversation, now);
  }

  /// 更新迁移会话的统计信息(按默认最新链统计，与新版展示逻辑一致)
  Future<void> _updateStatsForMigratedConversation(
    String convId,
    UnifiedConversation conversation,
    DateTime fallbackTime,
  ) async {
    // 会话没有消息时删除空会话
    final messages = await _dao.getMessagesByConversationId(convId);
    final nonSystem = messages.where((m) => !m.isSystem).toList();
    if (nonSystem.isEmpty) {
      await _dao.deleteConversation(convId);
      return;
    }

    await _dao.updateConversationStats(convId);
  }

  /// 转换单条消息
  UnifiedChatMessage _convertMessage(
    BranchChatMessageExport msg,
    String convId,
    String platformId,
    CusLLMSpec spec,
  ) {
    // 多模态附件：旧版逗号分隔路径字符串 -> UnifiedContentItem列表
    final multimodalContent = <UnifiedContentItem>[];
    _splitPaths(
      msg.imagesUrl,
    ).forEach((path) => multimodalContent.add(UnifiedContentItem.image(path)));
    _splitPaths(msg.videosUrl).forEach(
      (path) => multimodalContent.add(
        UnifiedContentItem.video(path, fileName: path.split('/').last),
      ),
    );
    _splitPaths(msg.audiosUrl).forEach(
      (path) => multimodalContent.add(
        UnifiedContentItem.audio(path, fileName: path.split('/').last),
      ),
    );

    // 联网搜索引用转换
    final searchReferences = msg.references
        ?.map((r) => SearchReference.fromSearchResultItem(r))
        .toList();

    final metadata = <String, dynamic>{
      if (msg.promptTokens != null) 'promptTokens': msg.promptTokens,
      if (msg.completionTokens != null)
        'completionTokens': msg.completionTokens,
      if (msg.modelLabel != null) 'modelLabel': msg.modelLabel,
      if (msg.contentVoicePath != null && msg.contentVoicePath!.isNotEmpty)
        'contentVoicePath': msg.contentVoicePath,
      if (msg.omniAudioVoice != null) 'omniAudioVoice': msg.omniAudioVoice,
      if (msg.characterId != null) 'legacyCharacterId': msg.characterId,
      'migratedFrom': 'branch_chat',
    };

    final role = switch (msg.role) {
      'user' => UnifiedMessageRole.user,
      'system' => UnifiedMessageRole.system,
      _ => UnifiedMessageRole.assistant,
    };

    return UnifiedChatMessage(
      id: msg.messageId,
      conversationId: convId,
      role: role,
      thinkingContent: msg.reasoningContent,
      thinkingTime: msg.thinkingDuration,
      content: msg.content,
      contentType: multimodalContent.isNotEmpty
          ? UnifiedContentType.multimodal
          : UnifiedContentType.text,
      multimodalContent: multimodalContent.isNotEmpty
          ? multimodalContent
          : null,
      tokenCount: msg.totalTokens ?? msg.completionTokens ?? 0,
      modelNameUsed: spec.model,
      platformIdUsed: platformId,
      searchReferences:
          (searchReferences != null && searchReferences.isNotEmpty)
          ? searchReferences
          : null,
      metadata: metadata,
      // 分支字段原样迁移
      parentId: msg.parentMessageId,
      branchIndex: msg.branchIndex,
      depth: msg.depth,
      branchPath: msg.branchPath,
      createdAt: msg.createTime,
      updatedAt: msg.createTime,
    );
  }

  /// 逗号分隔的路径字符串拆分
  List<String> _splitPaths(String? joined) {
    if (joined == null || joined.trim().isEmpty) return [];
    return joined
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// 平台映射：确保新版库中存在对应平台，返回平台id
  Future<String> _ensurePlatform(CusLLMSpec spec) async {
    final name = spec.platform.name;

    // 新版内置平台：id与旧版枚举名一致(siliconCloud驼峰也一致)
    // 2026-09-02 lingyiwanwu/infini已停服移除内置，旧数据迁移时走下方legacy补建分支
    const builtinIds = {
      'aliyun',
      'siliconCloud',
      'zhipu',
      'volcengine',
      'deepseek',
    };
    if (builtinIds.contains(name)) {
      var platform = await _dao.getPlatformSpec(name);
      if (platform == null) {
        // 理论不会发生，兜底重灌内置平台
        await _dao.reloadBuiltInPlatforms();
        platform = await _dao.getPlatformSpec(name);
      }
      if (platform != null) return platform.id;
    }

    // 旧平台 -> 自定义平台行(2026-08-31 这些平台新版未内置，迁移时补建)
    final legacyPlatforms = {
      'baidu': (
        displayName: '百度千帆(迁移)',
        hostUrl: 'https://qianfan.baidubce.com',
        ccPrefix: '/v2/chat/completions',
      ),
      'tencent': (
        displayName: '腾讯混元(迁移)',
        hostUrl: 'https://api.hunyuan.cloud.tencent.com',
        ccPrefix: '/v1/chat/completions',
      ),
      'volcesBot': (
        displayName: '火山Bot(迁移)',
        hostUrl: 'https://ark.cn-beijing.volces.com/api',
        ccPrefix: '/v3/bots/chat/completions',
      ),
    };

    if (legacyPlatforms.containsKey(name)) {
      final config = legacyPlatforms[name]!;
      final platformId = 'migrated_$name';
      var platform = await _dao.getPlatformSpec(platformId);
      if (platform == null) {
        final now = DateTime.now();
        platform = UnifiedPlatformSpec(
          id: platformId,
          displayName: config.displayName,
          hostUrl: config.hostUrl,
          ccPrefix: config.ccPrefix,
          isBuiltIn: false,
          isActive: false,
          description: '从旧版备份迁移的平台配置，请检查并配置API Key',
          createdAt: now,
          updatedAt: now,
        );
        await _dao.savePlatformSpec(platform);
      }
      return platformId;
    }

    // custom平台：用旧版的baseUrl拆分host和path
    final customId = 'migrated_custom';
    var platform = await _dao.getPlatformSpec(customId);
    if (platform == null) {
      final baseUrl = spec.baseUrl ?? '';
      String hostUrl = baseUrl;
      String ccPrefix = '/chat/completions';
      // 拆分比如 https://host.com/v1/chat/completions
      final idx = baseUrl.toLowerCase().indexOf('/chat/completions');
      if (idx > 0) {
        hostUrl = baseUrl.substring(0, idx);
        ccPrefix = baseUrl.substring(idx);
      } else if (baseUrl.isNotEmpty && !baseUrl.endsWith('/')) {
        hostUrl = baseUrl;
        ccPrefix = '/v1/chat/completions';
      }

      final now = DateTime.now();
      platform = UnifiedPlatformSpec(
        id: customId,
        displayName: '自定义平台(迁移)',
        hostUrl: hostUrl.isNotEmpty ? hostUrl : 'https://api.example.com',
        ccPrefix: ccPrefix,
        isBuiltIn: false,
        isActive: false,
        description: '从旧版备份迁移的自定义平台配置，请检查并配置API Key',
        createdAt: now,
        updatedAt: now,
      );
      await _dao.savePlatformSpec(platform);
    }

    // 旧版自定义平台的apiKey存入新版SecureStorage
    if (spec.apiKey != null && spec.apiKey!.isNotEmpty) {
      await UnifiedSecureStorage.storeApiKey(customId, spec.apiKey!);
    }

    return customId;
  }

  /// 模型映射：优先复用平台下已有的同名模型，否则创建自定义模型行
  Future<String> _ensureModel(String platformId, CusLLMSpec spec) async {
    final models = await _dao.getModelSpecsByPlatformId(platformId);
    final existing = models.where((m) => m.modelName == spec.model).firstOrNull;
    if (existing != null) return existing.id;

    // 旧模型类型 -> 新模型类型映射
    final (
      modelType,
      supportsThinking,
      supportsVision,
    ) = switch (spec.modelType) {
      LLModelType.cc => ('cc', false, false),
      LLModelType.reasoner => ('cc', true, false),
      LLModelType.vision => ('cc', false, true),
      LLModelType.vision_reasoner => ('cc', true, true),
      LLModelType.omni => ('cc', true, true),
      LLModelType.tti => ('tti', false, false),
      LLModelType.iti => ('iti', false, false),
      LLModelType.tts => ('tts', false, false),
      LLModelType.asr => ('asr', false, false),
      LLModelType.asr_realtime => ('asr', false, false),
      // 新版暂无对应类型，降级为cc并在extra_config保留原类型
      _ => ('cc', false, false),
    };

    final now = DateTime.now();
    final model = UnifiedModelSpec(
      id: const Uuid().v4(),
      platformId: platformId,
      modelName: spec.model,
      displayName: spec.name ?? spec.model,
      modelType: modelType,
      supportsThinking: supportsThinking,
      supportsVision: supportsVision,
      isActive: true,
      isBuiltIn: false,
      description: spec.description,
      extraConfig: {
        if (modelType != _directModelType(spec.modelType))
          'legacyModelType': spec.modelType.name,
        'migratedFrom': 'branch_chat',
      },
      createdAt: now,
      updatedAt: now,
    );
    await _dao.saveModelSpec(model);
    return model.id;
  }

  /// 判断旧模型类型是否有直接对应的新类型(用于extra_config标记)
  String _directModelType(LLModelType type) {
    return switch (type) {
      LLModelType.cc => 'cc',
      LLModelType.reasoner => 'cc',
      LLModelType.vision => 'cc',
      LLModelType.vision_reasoner => 'cc',
      LLModelType.omni => 'cc',
      LLModelType.tti => 'tti',
      LLModelType.iti => 'iti',
      LLModelType.tts => 'tts',
      LLModelType.asr => 'asr',
      LLModelType.asr_realtime => 'asr',
      _ => 'cc',
    };
  }

  /// 角色映射：旧版角色卡 -> 新版聊天搭档
  /// 2026-08-31 搭档系统合并角色卡：结构化人设/开场白/专属背景/偏好模型一并保留
  Future<String> _ensurePartner(CharacterCard character) async {
    final partnerId = 'migrated_${character.characterId}';
    final existing = await _dao.getChatPartner(partnerId);
    if (existing != null) return partnerId;

    // 偏好模型映射(旧CusLLMSpec -> 新模型行；失败忽略)
    String? preferredModelId;
    if (character.preferredModel != null) {
      try {
        final platformId = await _ensurePlatform(character.preferredModel!);
        preferredModelId = await _ensureModel(
          platformId,
          character.preferredModel!,
        );
      } catch (_) {
        preferredModelId = null;
      }
    }

    final now = DateTime.now();
    final partner = UnifiedChatPartner(
      id: partnerId,
      name: character.name,
      prompt: character.generateSystemPrompt(),
      avatarUrl: character.avatar,
      isBuiltIn: false,
      isActive: true,
      createdAt: now,
      updatedAt: now,
      description: character.description.trim().isEmpty
          ? null
          : character.description,
      personality: character.personality.trim().isEmpty
          ? null
          : character.personality,
      scenario: character.scenario.trim().isEmpty ? null : character.scenario,
      firstMessage: character.firstMessage.trim().isEmpty
          ? null
          : character.firstMessage,
      exampleDialogue: character.exampleDialogue.trim().isEmpty
          ? null
          : character.exampleDialogue,
      tags: character.tags.isEmpty ? null : jsonEncode(character.tags),
      preferredModelId: preferredModelId,
      background: character.background,
      backgroundOpacity: character.backgroundOpacity,
    );
    await _dao.saveChatPartner(partner);
    return partnerId;
  }
}

/// 导入结果(字段可变：适配器可在核心结果上追加角色导入计数)
class BranchChatImportResult {
  int importedCount;
  int skippedCount;
  int failedCount;
  final List<String> errors;

  BranchChatImportResult({
    this.importedCount = 0,
    this.skippedCount = 0,
    this.failedCount = 0,
    this.errors = const [],
  });
}
