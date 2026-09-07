import '../../features/unified_chat/data/services/unified_secure_storage.dart';
import '../storage/cus_get_storage.dart';

/// 旧 LLM 体系数据一次性迁移器（2026-09-07 旧体系退役配套）
///
/// 背景：0.1.5 早期版本中，扩展功能的 LLM 调用走旧体系
/// （ApiPlatform 枚举 + GetStorage user_ak_map 存平台 AK）。
/// 旧体系删除后，用户在旧版配置过的 5 家内置平台 AK 需要转入
/// flutter_secure_storage（新体系统一密钥存储），升级后扩展功能
/// 与聊天即可无缝使用此前配置的密钥，无需重新填写。
///
/// user_ak_map 中其余 Key（USER_TMDB_API_KEY 等内容源 Key）保持原地不动，
/// 仍由 get_app_key_helper.getStoredUserKey 消费。
///
/// 幂等：完成打标后不再执行；迁移失败不打标（下次启动重试）。
class LegacyLLMMigrator {
  LegacyLLMMigrator._();

  static const String _migratedFlagKey = 'legacy_llm_migrated_2026_09_07';

  /// 旧 ApiPlatformAKLabel 枚举名 -> 新统一平台 id
  /// (内置平台 id 与旧枚举名一致的部分才迁移；baidu/tencent/volcesBot
  /// 新版无内置平台，其 Key 与旧模型一并放弃——旧模型表读路径早已不可达)
  static const Map<String, String> _llmKeyToPlatformId = {
    'USER_ALIYUN_API_KEY': 'aliyun',
    'USER_SILICONCLOUD_API_KEY': 'siliconCloud',
    'USER_ZHIPU_API_KEY': 'zhipu',
    'USER_VOLCENGINE_API_KEY': 'volcengine',
    'USER_DEEPSEEK_API_KEY': 'deepseek',
  };

  static Future<void> runIfNeeded() async {
    final cusStorage = CusGetStorage();
    if (cusStorage.box.read(_migratedFlagKey) == true) return;

    final userKeys = cusStorage.getUserAKMap();
    var migratedCount = 0;

    for (final entry in _llmKeyToPlatformId.entries) {
      final legacyKey = entry.key;
      final platformId = entry.value;
      final apiKey = userKeys[legacyKey];

      if (apiKey != null && apiKey.isNotEmpty) {
        // 新体系已有同平台 Key 时保留新值，避免覆盖用户在新版重新配置的内容
        final existing = await UnifiedSecureStorage.getApiKey(platformId);
        if (existing == null || existing.isEmpty) {
          await UnifiedSecureStorage.storeApiKey(platformId, apiKey);
        }
        migratedCount++;
      }
    }

    // 从 user_ak_map 移除已迁移的 LLM Key(内容源Key保留)
    if (migratedCount > 0) {
      userKeys.removeWhere((k, _) => _llmKeyToPlatformId.containsKey(k));
      await cusStorage.setUserAKMap(userKeys);
    }

    await cusStorage.box.write(_migratedFlagKey, true);
  }
}
