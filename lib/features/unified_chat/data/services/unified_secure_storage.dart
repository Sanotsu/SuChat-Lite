import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

/// 统一AI聊天安全存储工具类
class UnifiedSecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
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
  static const String _preferredSearchToolKey =
      'unified_chat_preferred_search_tool';

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
