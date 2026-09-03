import '../../core/entities/cus_llm_model.dart';
import '../constants/constant_llm_enum.dart';
import '../../features/unified_chat/data/database/unified_chat_dao.dart';
import '../../features/unified_chat/data/models/unified_model_spec.dart';
import '../../features/unified_chat/data/models/unified_platform_spec.dart';
import '../../features/unified_chat/data/services/unified_secure_storage.dart';

/// 统一模型库桥接工具
/// 2026-09-03 扩展功能(训练助手/饮食日记)接入平台管理统一模型库，
/// 取代旧ModelManagerService(内置免费模型+AKMap自建模型体系已废弃)
class UnifiedModelBridge {
  /// 加载统一配置的对话模型并桥接为CusLLMSpec
  /// [visionOnly] 为true时仅返回支持视觉(supports_vision)的模型(食物拍照识别等)
  /// 仅收录激活平台下已配置AK的模型；无可用模型时返回空列表
  /// (调用方应提示用户前往聊天页-平台管理配置对话模型，功能不可用)
  static Future<List<CusLLMSpec>> loadChatModels({
    bool visionOnly = false,
  }) async {
    final dao = UnifiedChatDao();
    final models = await dao.getModelSpecs();
    final platforms = await dao.getPlatformSpecs();
    final platformMap = {for (final p in platforms) p.id: p};

    final result = <CusLLMSpec>[];
    for (final m in models) {
      if (!m.isActive || m.modelType != UnifiedModelType.cc.name) continue;
      if (visionOnly && !m.supportsVision) continue;
      final p = platformMap[m.platformId];
      if (p == null || !p.isActive) continue;

      final apiKey = await UnifiedSecureStorage.getApiKey(p.id);
      if (apiKey == null || apiKey.isEmpty) continue;

      result.add(toCusSpec(m, p, apiKey));
    }
    return result;
  }

  /// 统一模型 -> CusLLMSpec
  /// platform为枚举占位，实际地址与密钥由baseUrl(完整chat端点)/apiKey提供，
  /// ChatService.getHeaders与各服务的baseUrl拼接均已支持模型自带值优先
  static CusLLMSpec toCusSpec(
    UnifiedModelSpec model,
    UnifiedPlatformSpec platform,
    String apiKey,
  ) => CusLLMSpec(
    ApiPlatform.aliyun,
    model.modelName,
    LLModelType.cc,
    name: model.displayName,
    baseUrl: platform.getChatCompletionsUrl(),
    apiKey: apiKey,
    cusLlmSpecId: 'unified_${platform.id}_${model.id}',
  );
}
