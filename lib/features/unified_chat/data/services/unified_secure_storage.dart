import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

/// 统一AI聊天安全存储工具类
class UnifiedSecureStorage {
  static const _storage = FlutterSecureStorage(
    // v10+ Android 已默认使用加密实现，EncryptedSharedPreferences 选项已移除
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(),
    lOptions: LinuxOptions(),
    wOptions: WindowsOptions(),
    mOptions: MacOsOptions(),
  );

  // API密钥相关
  static const String _apiKeyPrefix = 'unified_chat_api_key_';
  static const String _platformConfigPrefix = 'unified_chat_platform_config_';
  static const String _userPreferencesKey = 'unified_chat_user_preferences';
  static const String _conversationSettingsPrefix =
      'unified_chat_conversation_settings_';
  static const String _searchApiKeyPrefix = 'unified_chat_search_api_key_';

  // 2026-09-09 平台自带联网搜索策略
  static const String _searchModePrefix = 'unified_chat_search_mode_';
  static const String _preferredSearchToolKey =
      'unified_chat_preferred_search_tool';

  // 2026-09-09 百度千帆AI搜索模式(retrieval=纯检索/intelligent=智能搜索生成)
  static const String _baiduSearchModeKey = 'unified_chat_baidu_search_mode';

  /// 存储API密钥
  static Future<void> storeApiKey(String platformId, String apiKey) async {
    await _storage.write(key: '$_apiKeyPrefix$platformId', value: apiKey);
  }

  /// 获取API密钥
  static Future<String?> getApiKey(String platformId) async {
    return await _storage.read(key: '$_apiKeyPrefix$platformId');
  }

  /// 批量获取API密钥
  /// 传入平台ID列表，返回对应的API密钥列表
  static Future<Map<String, String?>> getApiKeys(
    List<String> platformIds,
  ) async {
    // 一次性读取所有存储的键值对
    final allKeys = await _storage.readAll();

    final result = <String, String?>{};

    for (final platformId in platformIds) {
      final key = '$_apiKeyPrefix$platformId';
      result[platformId] = allKeys[key];
    }

    return result;
  }

  /// 删除API密钥
  static Future<void> deleteApiKey(String platformId) async {
    await _storage.delete(key: '$_apiKeyPrefix$platformId');
  }

  /// 获取所有API密钥的平台ID列表
  static Future<List<String>> getAllApiKeyPlatforms() async {
    final allKeys = await _storage.readAll();
    return allKeys.keys
        .where((key) => key.startsWith(_apiKeyPrefix))
        .map((key) => key.substring(_apiKeyPrefix.length))
        .toList();
  }

  /// 存储平台配置
  static Future<void> storePlatformConfig(
    String platformId,
    Map<String, dynamic> config,
  ) async {
    final configJson = jsonEncode(config);
    await _storage.write(
      key: '$_platformConfigPrefix$platformId',
      value: configJson,
    );
  }

  /// 获取平台配置
  static Future<Map<String, dynamic>?> getPlatformConfig(
    String platformId,
  ) async {
    final configJson = await _storage.read(
      key: '$_platformConfigPrefix$platformId',
    );
    if (configJson != null) {
      try {
        return jsonDecode(configJson) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// 删除平台配置
  static Future<void> deletePlatformConfig(String platformId) async {
    await _storage.delete(key: '$_platformConfigPrefix$platformId');
  }

  /// 存储用户偏好设置
  static Future<void> storeUserPreferences(
    Map<String, dynamic> preferences,
  ) async {
    final preferencesJson = jsonEncode(preferences);
    await _storage.write(key: _userPreferencesKey, value: preferencesJson);
  }

  /// 获取用户偏好设置
  static Future<Map<String, dynamic>> getUserPreferences() async {
    final preferencesJson = await _storage.read(key: _userPreferencesKey);
    if (preferencesJson != null) {
      try {
        return jsonDecode(preferencesJson) as Map<String, dynamic>;
      } catch (e) {
        return _getDefaultUserPreferences();
      }
    }
    return _getDefaultUserPreferences();
  }

  /// 获取默认用户偏好设置
  static Map<String, dynamic> _getDefaultUserPreferences() {
    return {
      'theme_mode': 'system', // system, light, dark
      'default_model_id': 'gpt-4o-mini',
      'default_platform_id': 'openai',
      'auto_save_conversations': true,
      'show_token_count': true,
      'show_cost_estimation': true,
      'enable_streaming': true,
      'enable_markdown_rendering': true,
      'enable_code_highlighting': true,
      'enable_latex_rendering': true,
      'font_size': 14.0,
      'message_bubble_style': 'modern', // classic, modern, minimal
      'enable_sound_effects': false,
      'enable_haptic_feedback': true,
      'auto_scroll_to_bottom': true,
      'compress_images': true,
      'max_image_size_mb': 5.0,
      'default_temperature': 0.7,
      'default_max_tokens': null,
      'default_top_p': 1.0,
      'default_frequency_penalty': 0.0,
      'default_presence_penalty': 0.0,
      // 在新对话时显示搭档列表
      'show_partners_in_new_chat': true,
    };
  }

  /// 更新用户偏好设置中的单个值
  static Future<void> updateUserPreference(String key, dynamic value) async {
    final preferences = await getUserPreferences();
    preferences[key] = value;
    await storeUserPreferences(preferences);
  }

  /// 获取是否在新对话中显示搭档
  static Future<bool> getShowPartnersInNewChat() async {
    final preferences = await getUserPreferences();
    return preferences['show_partners_in_new_chat'] ?? true;
  }

  /// 设置是否在新对话中显示搭档
  static Future<void> setShowPartnersInNewChat(bool value) async {
    await updateUserPreference('show_partners_in_new_chat', value);
  }

  /// 存储对话设置
  static Future<void> storeConversationSettings(
    String conversationId,
    Map<String, dynamic> settings,
  ) async {
    final settingsJson = jsonEncode(settings);
    await _storage.write(
      key: '$_conversationSettingsPrefix$conversationId',
      value: settingsJson,
    );
  }

  /// 获取对话设置
  static Future<Map<String, dynamic>?> getConversationSettings(
    String conversationId,
  ) async {
    final settingsJson = await _storage.read(
      key: '$_conversationSettingsPrefix$conversationId',
    );
    if (settingsJson != null) {
      try {
        return jsonDecode(settingsJson) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// 删除对话设置
  static Future<void> deleteConversationSettings(String conversationId) async {
    await _storage.delete(key: '$_conversationSettingsPrefix$conversationId');
  }

  /// 验证API密钥格式
  static bool validateApiKeyFormat(String platformId, String apiKey) {
    switch (platformId) {
      case 'openai':
        return apiKey.startsWith('sk-') && apiKey.length > 20;
      case 'azure_openai':
        return apiKey.length >= 32;
      case 'deepseek':
        return apiKey.startsWith('sk-') && apiKey.length > 20;
      default:
        return apiKey.isNotEmpty;
    }
  }

  /// 清除所有存储的数据
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// 清除特定平台的所有数据
  static Future<void> clearPlatformData(String platformId) async {
    await deleteApiKey(platformId);
    await deletePlatformConfig(platformId);
  }

  /// 导出配置数据（不包含敏感信息）
  static Future<Map<String, dynamic>> exportConfig() async {
    final preferences = await getUserPreferences();
    final platforms = await getAllApiKeyPlatforms();

    return {
      'user_preferences': preferences,
      'configured_platforms': platforms,
      'export_timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// 导入配置数据
  static Future<void> importConfig(Map<String, dynamic> config) async {
    if (config.containsKey('user_preferences')) {
      await storeUserPreferences(
        config['user_preferences'] as Map<String, dynamic>,
      );
    }
  }

  /// 检查是否有有效的API密钥
  static Future<bool> hasValidApiKey(String platformId) async {
    final apiKey = await getApiKey(platformId);
    return apiKey != null && validateApiKeyFormat(platformId, apiKey);
  }

  /// 存储搜索API密钥
  static Future<void> setSearchApiKey(String toolType, String apiKey) async {
    await _storage.write(key: '$_searchApiKeyPrefix$toolType', value: apiKey);
  }

  /// 获取搜索API密钥
  static Future<String?> getSearchApiKey(String toolType) async {
    return await _storage.read(key: '$_searchApiKeyPrefix$toolType');
  }

  /// 删除搜索API密钥
  static Future<void> deleteSearchApiKey(String toolType) async {
    await _storage.delete(key: '$_searchApiKeyPrefix$toolType');
  }

  /// 设置首选搜索工具
  static Future<void> setPreferredSearchTool(String toolType) async {
    await _storage.write(key: _preferredSearchToolKey, value: toolType);
  }

  /// 获取首选搜索工具
  static Future<String?> getPreferredSearchTool() async {
    return await _storage.read(key: _preferredSearchToolKey);
  }

  /// 删除首选搜索工具设置
  static Future<void> deletePreferredSearchTool() async {
    await _storage.delete(key: _preferredSearchToolKey);
  }

  /// 2026-09-09 存储平台自带联网搜索策略(auto/builtinOnly/thirdPartyOnly)
  /// 按 platformId 通用化存储，任意平台都可设置(仅注册了自带搜索适配器的平台生效)
  static Future<void> setPlatformSearchMode(
    String platformId,
    String mode,
  ) async {
    await _storage.write(key: '$_searchModePrefix$platformId', value: mode);
  }

  /// 获取平台自带联网搜索策略(未设置返回null，调用方按auto处理)
  static Future<String?> getPlatformSearchMode(String platformId) async {
    return await _storage.read(key: '$_searchModePrefix$platformId');
  }

  /// 删除平台自带联网搜索策略(恢复auto)
  static Future<void> deletePlatformSearchMode(String platformId) async {
    await _storage.delete(key: '$_searchModePrefix$platformId');
  }

  /// 2026-09-11 MCP集成(P0-4)：存储MCP server认证头敏感值
  /// (如Authorization头值)，DB中仅存非敏感头；键规则 `mcp_auth_serverId`
  static Future<void> setMcpAuthHeader(String serverId, String value) async {
    await _storage.write(key: 'unified_chat_mcp_auth_$serverId', value: value);
  }

  /// 获取MCP server认证头敏感值(未设置返回null)
  static Future<String?> getMcpAuthHeader(String serverId) async {
    return await _storage.read(key: 'unified_chat_mcp_auth_$serverId');
  }

  /// 删除MCP server认证头敏感值(server删除时同步清理)
  static Future<void> deleteMcpAuthHeader(String serverId) async {
    await _storage.delete(key: 'unified_chat_mcp_auth_$serverId');
  }

  /// 2026-09-15 P4-2 OAuth：存储MCP server的OAuth令牌(敏感，JSON序列化)
  static Future<void> setMcpOAuthTokens(
    String serverId,
    String tokensJson,
  ) async {
    await _storage.write(
      key: 'unified_chat_mcp_oauth_$serverId',
      value: tokensJson,
    );
  }

  /// 获取MCP server的OAuth令牌JSON(未授权返回null)
  static Future<String?> getMcpOAuthTokens(String serverId) async {
    return await _storage.read(key: 'unified_chat_mcp_oauth_$serverId');
  }

  /// 删除MCP server的OAuth令牌(server删除时同步清理)
  static Future<void> deleteMcpOAuthTokens(String serverId) async {
    await _storage.delete(key: 'unified_chat_mcp_oauth_$serverId');
  }

  /// 2026-09-11 MCP集成(P1-3)：会话级MCP工具开关，键规则 `mcp_enabled_<id>`
  static Future<void> setConversationMcpEnabled(
    String conversationId,
    bool enabled,
  ) async {
    await _storage.write(
      key: 'unified_chat_mcp_enabled_$conversationId',
      value: enabled ? '1' : '0',
    );
  }

  /// 获取会话级MCP工具开关(未设置默认false——安全默认关)
  static Future<bool> getConversationMcpEnabled(String conversationId) async {
    final value = await _storage.read(
      key: 'unified_chat_mcp_enabled_$conversationId',
    );
    return value == '1';
  }

  /// 删除会话级MCP开关(会话删除时清理)
  static Future<void> deleteConversationMcpEnabled(
    String conversationId,
  ) async {
    await _storage.delete(key: 'unified_chat_mcp_enabled_$conversationId');
  }

  /// 2026-09-09 存储百度千帆AI搜索模式(retrieval/intelligent)
  static Future<void> setBaiduSearchMode(String mode) async {
    await _storage.write(key: _baiduSearchModeKey, value: mode);
  }

  /// 获取百度千帆AI搜索模式(未设置返回null，调用方按retrieval纯检索处理)
  static Future<String?> getBaiduSearchMode() async {
    return await _storage.read(key: _baiduSearchModeKey);
  }

  /// 2026-09-12 全局搜索渠道偏好(auto/platformOnly/thirdPartyOnly/mcpOnly)
  static const String _searchChannelPrefKey =
      'unified_chat_search_channel_pref';

  static Future<void> setSearchChannelPreference(String value) async {
    await _storage.write(key: _searchChannelPrefKey, value: value);
  }

  static Future<String?> getSearchChannelPreference() async {
    return await _storage.read(key: _searchChannelPrefKey);
  }

  /// 2026-09-16 MCP全局启用开关(设置页控制，与会话级开关并行的上层闸)：
  /// 开=所有会话强制携带MCP工具(输入框按钮隐藏，会话级开关被覆盖)；
  /// 关(默认)=回落会话级开关。存'1'/'0'，读不到视为关
  static const String _mcpGloballyEnabledKey =
      'unified_chat_mcp_globally_enabled';

  static Future<void> setMcpGloballyEnabled(bool value) async {
    await _storage.write(key: _mcpGloballyEnabledKey, value: value ? '1' : '0');
  }

  static Future<bool> getMcpGloballyEnabled() async {
    final v = await _storage.read(key: _mcpGloballyEnabledKey);
    return v == '1';
  }

  /// 获取存储统计信息
  static Future<Map<String, int>> getStorageStats() async {
    final allKeys = await _storage.readAll();

    int apiKeyCount = 0;
    int configCount = 0;
    int conversationSettingsCount = 0;
    int searchApiKeyCount = 0;

    for (final key in allKeys.keys) {
      if (key.startsWith(_apiKeyPrefix)) {
        apiKeyCount++;
      } else if (key.startsWith(_platformConfigPrefix)) {
        configCount++;
      } else if (key.startsWith(_conversationSettingsPrefix)) {
        conversationSettingsCount++;
      } else if (key.startsWith(_searchApiKeyPrefix)) {
        searchApiKeyCount++;
      }
    }

    return {
      'total_keys': allKeys.length,
      'api_keys': apiKeyCount,
      'platform_configs': configCount,
      'conversation_settings': conversationSettingsCount,
      'search_api_keys': searchApiKeyCount,
    };
  }
}
