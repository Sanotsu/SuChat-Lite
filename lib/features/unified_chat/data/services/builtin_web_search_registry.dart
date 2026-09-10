import '../../../../core/utils/simple_tools.dart';
import '../models/unified_platform_spec.dart';

/// 2026-09-09 平台自带联网搜索策略
/// - auto: 自动(推荐)。已配置任一第三方搜索Key则走第三方工具调用(省平台自带搜索的
///   按次付费)，否则回落平台自带搜索
/// - builtinOnly: 始终使用平台自带搜索(按平台计费，如智谱0.01~0.05元/次)
/// - thirdPartyOnly: 优先第三方工具；仅当平台无自带搜索能力或模型不支持工具调用时
///   才可能回落自带搜索
enum BuiltinWebSearchMode {
  auto,
  builtinOnly,
  thirdPartyOnly;

  static BuiltinWebSearchMode fromStorage(String? value) =>
      BuiltinWebSearchMode.values.firstWhere(
        (m) => m.name == value,
        orElse: () => BuiltinWebSearchMode.auto,
      );

  String toStorage() => name;
}

/// 平台自带联网搜索适配器
/// 各大模型云平台的联网搜索是额外付费的私有配置(请求参数/计费各不相同)，
/// 通过适配器抹平差异；后续适配新平台时在此注册新适配器即可，主流程零改动。
/// 参考：
/// - 阿里百炼: https://help.aliyun.com/zh/model-studio/web-search
///   (OpenAI兼容Chat Completions: enable_search + search_options；不支持返回搜索来源)
/// - 智谱: https://docs.bigmodel.cn/cn/guide/tools/web-search
///   (Chat Completions: tools内type=web_search，2026-09参数名为enable；
///    可search_result返回引用，响应message的web_search字段)
abstract class BuiltinWebSearchAdapter {
  /// 该模型的对话请求是否支持自带联网搜索
  /// (部分平台仅特定模型支持，如阿里仅千问/DeepSeek部分系列)
  bool supportsModel(String modelName);

  /// 构建追加到请求体顶层的联网搜索配置；不支持时返回null
  Map<String, dynamic>? buildConfig(String modelName);

  /// 从响应(chunk json或完整json)中解析搜索引用列表，供UI展示来源；
  /// 平台不支持返回引用时返回null。
  /// 返回结构: [{title, url, description, favicon?, publishedDate?}, ...]
  List<Map<String, dynamic>>? parseReferences(Map<String, dynamic> chunkJson);

  /// 2026-09-09 平台使用前置条件提示(如需先在控制台开通服务)；
  /// null表示无特殊前置条件，设置页策略行展示
  String? get setupHint => null;
}

/// 阿里百炼适配器
/// 注意: OpenAI兼容-Chat Completions协议不支持返回搜索来源/角标标注，
/// 所以本适配器parseReferences恒为null(引用展示走第三方工具搜索)
class AliyunWebSearchAdapter extends BuiltinWebSearchAdapter {
  /// 2026-09-09 按官方"联网搜索-支持的模型"文档核对并全面重写。
  /// 官方口径: 2025年7月后发布的千问Max/Plus/Flash全系自动支持联网搜索；
  /// 直供第三方模型中DeepSeek-V4系列支持；GLM/Kimi仅Responses API支持；
  /// MiniMax-M3、MiMo官方未列入(不启用，避免请求报错，这类模型走第三方工具搜索)。
  /// 匹配规则: 精确相等 或 前缀+日期快照后缀(如 qwen3.8-max-0902)
  static const List<String> _supportedModelPrefixes = [
    // 千问商业版系列
    'qwen3.8-max',
    'qwen3.8-flash',
    'qwen3.7-plus',
    'qwen3.5-plus',
    'qwen3.5-flash',
    // 千问Omni(qwen3.5-omni系列搜索策略必须为agent)
    'qwen3.5-omni-plus',
    // 直供DeepSeek
    'deepseek-v4-pro',
    'deepseek-v4-flash',
  ];

  bool _supports(String modelName) => _supportedModelPrefixes.any(
    (prefix) => modelName == prefix || modelName.startsWith('$prefix-'),
  );

  @override
  bool supportsModel(String modelName) => _supports(modelName);

  @override
  Map<String, dynamic>? buildConfig(String modelName) {
    if (!_supports(modelName)) return null;

    // qwen3.5-omni系列官方要求搜索策略必须为agent(每次额外计费)
    final isOmni = modelName.startsWith('qwen3.5-omni');

    return {
      'enable_search': true,
      'search_options': {
        // 让模型自己判断是否需要搜索，避免无搜索需求时白白计费
        'forced_search': false,
        // turbo(默认,兼顾速度与效果) / max(多源更全面) / agent(多轮检索,额外计费)
        'search_strategy': isOmni ? 'agent' : 'turbo',
        // 开启垂域搜索
        'enable_search_extension': true,
      },
    };
  }

  @override
  List<Map<String, dynamic>>? parseReferences(Map<String, dynamic> chunkJson) =>
      null;
}

/// 智谱适配器
/// 2026-09-09 参数修正: 旧代码的search_enable已废弃，现文档参数名为enable；
/// 开启search_result让响应携带web_search引用(配合parseReferences展示来源)。
/// search_engine计费: search_std 0.01元/次、search_pro 0.03元/次、
/// search_pro_sogou/search_pro_quark 0.05元/次
class ZhipuWebSearchAdapter extends BuiltinWebSearchAdapter {
  @override
  bool supportsModel(String modelName) => true;

  @override
  Map<String, dynamic>? buildConfig(String modelName) {
    return {
      'tools': [
        {
          'type': 'web_search',
          'web_search': {
            // 是否启用搜索功能(旧参数名search_enable已废弃)
            'enable': true,
            // 基础版引擎性价比最高，需要更强召回可改search_pro等
            'search_engine': 'search_std',
            // 响应中返回搜索结果(引用来源)
            'search_result': true,
            // 返回结果条数(1-50)
            'count': 10,
          },
        },
      ],
      'tool_choice': 'auto',
    };
  }

  @override
  List<Map<String, dynamic>>? parseReferences(Map<String, dynamic> chunkJson) {
    try {
      final choices = chunkJson['choices'] as List?;
      if (choices == null || choices.isEmpty) return null;

      // 引用可能在message(非流式)或delta(流式)上
      final choice = choices.first as Map<String, dynamic>;
      final message = choice['message'] as Map<String, dynamic>?;
      final delta = choice['delta'] as Map<String, dynamic>?;
      dynamic refs = message?['web_search'] ?? delta?['web_search'];
      // 兼容readReferenceValue的历史键名
      refs ??= message?['references'] ?? delta?['references'];
      if (refs is! List || refs.isEmpty) return null;

      return refs
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => {
              'title': item['title'] ?? '',
              'url': item['link'] ?? item['url'] ?? '',
              'description': item['content'] ?? '',
              'favicon': item['icon'],
              'publishedDate': item['publish_date'],
            },
          )
          .toList();
    } catch (e) {
      pl.e('解析智谱联网搜索引用失败: $e');
      return null;
    }
  }
}

/// 火山方舟适配器
/// 2026-09-09 实测定性：方舟的Web Search(联网内容插件)**仅Responses API提供**
/// (https://www.volcengine.com/docs/82379/1756990，POST /api/v3/responses，
/// tools为{type: "web_search", max_keyword: ...}平铺形状)；
/// Chat Completions的tools只接受function类型，拼入web_search直接400
/// (MissingParameter: missing tools.function parameter，实测日志确认)。
/// 因此CC路径buildConfig恒为null——火山联网当前走第三方工具调用；
/// 自带搜索待Responses API协议支持后启用(适配器结构保留作为迭代基础，
/// parseReferences已备好references引用解析)。
/// 注意：使用前需在方舟控制台开通Web Search服务(按次计费)。
class VolcengineWebSearchAdapter extends BuiltinWebSearchAdapter {
  @override
  String? get setupHint => '自带搜索基于Responses API(开发规划中)，当前请配置第三方搜索Key使用联网';

  @override
  bool supportsModel(String modelName) => true;

  // Chat Completions不支持web_search服务端工具(400实测)，恒返回null；
  // Responses API支持落地后此处改为构造input+tools结构
  @override
  Map<String, dynamic>? buildConfig(String modelName) => null;

  /// Responses API的引用(annotations/web_search_call)或
  /// message/delta的references字段解析——当前CC路径不会命中，留作迭代基础
  @override
  List<Map<String, dynamic>>? parseReferences(Map<String, dynamic> chunkJson) {
    try {
      final choices = chunkJson['choices'] as List?;
      if (choices == null || choices.isEmpty) return null;

      // 引用可能在message(非流式)或delta(流式)上
      final choice = choices.first as Map<String, dynamic>;
      final message = choice['message'] as Map<String, dynamic>?;
      final delta = choice['delta'] as Map<String, dynamic>?;
      dynamic refs = message?['references'] ?? delta?['references'];
      if (refs is! List || refs.isEmpty) return null;

      return refs.whereType<Map<String, dynamic>>().map((item) {
        return {
          'title': item['title'] ?? '',
          'url': item['url'] ?? '',
          'description': item['content'] ?? '',
          'favicon': item['icon'],
          'publishedDate': item['publish_date'],
        };
      }).toList();
    } catch (e) {
      pl.e('解析火山方舟联网搜索引用失败: $e');
      return null;
    }
  }
}

/// 平台自带联网搜索注册表
/// 新平台接入: 实现 BuiltinWebSearchAdapter 后在 _adapters 中注册一行即可，
/// 策略设置UI会自动出现对应平台的配置项
class BuiltinWebSearchRegistry {
  BuiltinWebSearchRegistry._();

  /// 已注册平台(供设置页动态生成策略配置项)
  static final Map<String, String> registeredPlatforms = {
    UnifiedPlatformId.aliyun.name: '阿里百炼',
    UnifiedPlatformId.zhipu.name: '智谱',
    UnifiedPlatformId.volcengine.name: '火山方舟',
  };

  static final Map<String, BuiltinWebSearchAdapter> _adapters = {
    UnifiedPlatformId.aliyun.name: AliyunWebSearchAdapter(),
    UnifiedPlatformId.zhipu.name: ZhipuWebSearchAdapter(),
    UnifiedPlatformId.volcengine.name: VolcengineWebSearchAdapter(),
  };

  static BuiltinWebSearchAdapter? adapterFor(String platformId) =>
      _adapters[platformId];

  static bool supportsBuiltinSearch(String platformId) =>
      _adapters.containsKey(platformId);

  /// 2026-09-09 平台使用前置条件提示(如需先开通服务)，无则null
  static String? setupHintFor(String platformId) =>
      _adapters[platformId]?.setupHint;
}
