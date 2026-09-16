import '../../../../core/utils/simple_tools.dart';
import '../models/mcp_models.dart';
import '../models/openai_request.dart';
import '../models/web_search_models.dart';
import 'builtin_web_search_registry.dart';
import 'web_search_service.dart';
import 'unified_secure_storage.dart';

/// 联网搜索工具管理器
/// 负责管理搜索工具的注册、调用和结果处理
/// 2026-09-14 P3-9 适配ChatToolProvider成为第二个实现(收敛动作)：
/// 执行路由统一按canHandle分发，service中web_search硬编码分支移除；
/// searchReferences迁移到ToolResult.references(结构化引用泛化通道)
class WebSearchToolManager implements ChatToolProvider {
  static final WebSearchToolManager _instance =
      WebSearchToolManager._internal();
  factory WebSearchToolManager() => _instance;
  WebSearchToolManager._internal();

  final WebSearchService _searchService = WebSearchService();

  // 2026-09-09 初始化缓存：避免每次发消息都重复读取安全存储
  bool _initialized = false;

  @override
  String get namespace => '';

  /// 仅处理内置web_search工具
  @override
  bool canHandle(String toolName) => toolName == 'web_search';

  @override
  Future<void> ensureReady() => initialize();

  /// 初始化搜索工具
  /// [force]为true时强制重新读取存储(密钥变更后刷新缓存)
  Future<void> initialize({bool force = false}) async {
    if (_initialized && !force) return;

    // 从安全存储中加载API密钥
    final bochaKey = await UnifiedSecureStorage.getSearchApiKey('bocha');
    final baiduKey = await UnifiedSecureStorage.getSearchApiKey('baidu');
    final tavilyKey = await UnifiedSecureStorage.getSearchApiKey('tavily');
    final serpApiKey = await UnifiedSecureStorage.getSearchApiKey('serpapi');
    final serperKey = await UnifiedSecureStorage.getSearchApiKey('serper');

    if (bochaKey != null) {
      _searchService.setBochaApiKey(bochaKey);
    }
    if (baiduKey != null) {
      _searchService.setBaiduApiKey(baiduKey);
    }

    // 2026-09-09 百度搜索模式(纯检索/智能生成)，未设置默认纯检索
    final baiduMode = await UnifiedSecureStorage.getBaiduSearchMode();
    if (baiduMode != null) {
      _searchService.setBaiduUseIntelligent(baiduMode);
    }
    if (tavilyKey != null) {
      _searchService.setTavilyApiKey(tavilyKey);
    }
    if (serpApiKey != null) {
      _searchService.setSerpApiKey(serpApiKey);
    }
    if (serperKey != null) {
      _searchService.setSerperApiKey(serperKey);
    }

    _initialized = true;

    pl.i(
      '搜索工具初始化完成 - '
      '博查: ${_searchService.hasBochaApiKey}, '
      '百度: ${_searchService.hasBaiduApiKey}, '
      'Tavily: ${_searchService.hasTavilyApiKey}, '
      'SerpApi: ${_searchService.hasSerpApiKey}, '
      'Serper: ${_searchService.hasSerperApiKey}',
    );
  }

  /// 获取联网搜索工具定义
  List<OpenAITool> getSearchTools() => getTools();

  /// ChatToolProvider: 工具定义(有可用搜索Key时注入web_search)
  @override
  List<OpenAITool> getTools() {
    if (!hasAvailableTools()) return [];

    return [
      OpenAITool.function(
        OpenAIFunction(
          name: 'web_search',
          // 2026-09-09 描述中加入调用纪律，减少模型反复搜索的倾向
          description:
              '执行联网搜索，获取最新的网络信息。适用于需要实时信息、最新新闻、当前事件、具体数据查询等场景。'
              '请用精准、具体的关键词一次性搜索到位；获得搜索结果后直接整理答案回答用户，'
              '除非信息明显不足，否则不要再次搜索。',
          parameters: {
            'type': 'object',
            'properties': {
              'query': {
                'type': 'string',
                'description': '搜索查询关键词,应该是具体、明确的搜索词',
              },
              'search_type': {
                'type': 'string',
                'enum': ['general', 'news', 'recent'],
                'description': '搜索类型: general-通用搜索,news-新闻搜索,recent-最新信息搜索',
                'default': 'general',
              },
              'max_results': {
                'type': 'number',
                'minimum': 1,
                'maximum': 50,
                'description': '返回的最大结果数量',
                'default': 10,
              },
            },
            'required': ['query'],
          },
        ),
      ),
    ];
  }

  /// 处理联网搜索工具调用(ChatToolProvider: P3-9签名对齐，
  /// 引用走ToolResult.references)
  @override
  Future<ToolResult> handleToolCall(
    String toolName,
    Map<String, dynamic> arguments,
  ) async {
    if (!canHandle(toolName)) {
      return ToolResult(content: '不支持的工具调用: $toolName');
    }

    try {
      final query = arguments['query'] as String?;
      if (query == null || query.trim().isEmpty) {
        return ToolResult(content: '搜索查询不能为空');
      }

      final maxResults = arguments['max_results'] as int? ?? 10;
      // 收敛上限，避免过多结果撑爆上下文
      final safeMaxResults = maxResults.clamp(1, 20);

      // 2026-09-09 移除"search_type为news时强制用Tavily"的硬编码特判——
      // 它会无视用户配置的首选工具(如百度)，导致同一轮对话里搜索服务
      // 忽而Tavily忽而百度。现在无论什么搜索类型都严格遵循：
      // 用户首选工具 > 默认优先级(博查>百度>Tavily>Serper>SerpApi)

      final result = await _searchService.search(
        query: query.trim(),
        maxResults: safeMaxResults,
        includeAnswer: true,
      );

      // 提取搜索结果链接
      final searchReferences = result.results
          .map(
            (item) => {
              'title': item.title,
              'url': item.url,
              'description': item.content,
              'favicon': item.favicon,
              'publishedDate': item.publishedDate,
              'score': item.score,
            },
          )
          .toList();

      return ToolResult(
        // 2026-09-09 结果末尾附调用纪律提示，配合工具描述抑制模型
        // "让我再搜索"式的多轮重复调用
        content:
            '${result.toToolCallResult()}\n\n'
            '(提示：若以上搜索结果已足够回答用户问题，请直接整理答案作答，'
            '无需再次搜索)',
        // P3-9 引用迁移到泛化通道(消息引用区展示)
        references: searchReferences,
      );
    } catch (e) {
      // 2026-09-09 服务层不再弹Toast，错误随结果返回由模型与UI处理
      return ToolResult(content: '搜索失败: $e');
    }
  }

  /// 检查是否有可用的搜索工具
  bool hasAvailableTools() {
    return _searchService.hasBochaApiKey ||
        _searchService.hasBaiduApiKey ||
        _searchService.hasTavilyApiKey ||
        _searchService.hasSerpApiKey ||
        _searchService.hasSerperApiKey;
  }

  /// 获取工具状态
  Map<String, bool> getToolStatus() {
    final status = _searchService.getToolStatus();
    return {
      'bocha': status[SearchToolType.bocha] ?? false,
      'baidu': status[SearchToolType.baidu] ?? false,
      'tavily': status[SearchToolType.tavily] ?? false,
      'serpapi': status[SearchToolType.serpapi] ?? false,
      'serper': status[SearchToolType.serper] ?? false,
    };
  }

  /// 设置API密钥(同步更新缓存，无需强制重新初始化)
  Future<void> setApiKey(String toolType, String apiKey) async {
    switch (toolType.toLowerCase()) {
      case 'bocha':
        _searchService.setBochaApiKey(apiKey);
        await UnifiedSecureStorage.setSearchApiKey('bocha', apiKey);
        break;
      case 'baidu':
        _searchService.setBaiduApiKey(apiKey);
        await UnifiedSecureStorage.setSearchApiKey('baidu', apiKey);
        break;
      case 'tavily':
        _searchService.setTavilyApiKey(apiKey);
        await UnifiedSecureStorage.setSearchApiKey('tavily', apiKey);
        break;
      case 'serpapi':
        _searchService.setSerpApiKey(apiKey);
        await UnifiedSecureStorage.setSearchApiKey('serpapi', apiKey);
        break;
      case 'serper':
        _searchService.setSerperApiKey(apiKey);
        await UnifiedSecureStorage.setSearchApiKey('serper', apiKey);
        break;
      default:
        throw ArgumentError('不支持的搜索工具类型: $toolType');
    }
    _initialized = true;
  }

  /// 测试工具连接
  Future<bool> testToolConnection(String toolType) async {
    SearchToolType? type;
    switch (toolType.toLowerCase()) {
      case 'bocha':
        type = SearchToolType.bocha;
        break;
      case 'baidu':
        type = SearchToolType.baidu;
        break;
      case 'tavily':
        type = SearchToolType.tavily;
        break;
      case 'serpapi':
        type = SearchToolType.serpapi;
        break;
      case 'serper':
        type = SearchToolType.serper;
        break;
      default:
        return false;
    }

    return await _searchService.testConnection(type);
  }

  /// 2026-09-09 解析平台的自带联网搜索策略(未设置按auto处理)
  Future<BuiltinWebSearchMode> getPlatformSearchMode(String platformId) async {
    final stored = await UnifiedSecureStorage.getPlatformSearchMode(platformId);
    return BuiltinWebSearchMode.fromStorage(stored);
  }

  /// 保存平台的自带联网搜索策略
  Future<void> setPlatformSearchMode(String platformId, String mode) async {
    await UnifiedSecureStorage.setPlatformSearchMode(platformId, mode);
  }

  /// 2026-09-12 全局搜索渠道偏好(联网开关开启时用哪个渠道，见
  /// SearchChannelPreference；未设置按auto处理)
  Future<SearchChannelPreference> getSearchChannelPreference() async {
    final stored = await UnifiedSecureStorage.getSearchChannelPreference();
    return SearchChannelPreference.fromStorage(stored);
  }

  /// 保存全局搜索渠道偏好
  Future<void> setSearchChannelPreference(SearchChannelPreference pref) async {
    await UnifiedSecureStorage.setSearchChannelPreference(pref.toStorage());
  }

  /// 2026-09-09 设置百度搜索模式('retrieval'纯检索/'intelligent'智能生成)，
  /// 同步更新service缓存，无需强制重新初始化
  Future<void> setBaiduSearchMode(String mode) async {
    _searchService.setBaiduUseIntelligent(mode);
    await UnifiedSecureStorage.setBaiduSearchMode(mode);
  }

  /// 获取百度搜索模式(未设置按纯检索处理)
  Future<String> getBaiduSearchMode() async {
    return await UnifiedSecureStorage.getBaiduSearchMode() ?? 'retrieval';
  }

  /// 清理资源
  void dispose() {
    _searchService.dispose();
    _initialized = false;
  }
}
