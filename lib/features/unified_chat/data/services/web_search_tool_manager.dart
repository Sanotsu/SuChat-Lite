import '../../../../core/utils/simple_tools.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../models/openai_request.dart';
import '../models/web_search_models.dart';
import 'web_search_service.dart';
import 'unified_secure_storage.dart';

/// 联网搜索工具管理器
/// 负责管理搜索工具的注册、调用和结果处理
class WebSearchToolManager {
  static final WebSearchToolManager _instance =
      WebSearchToolManager._internal();
  factory WebSearchToolManager() => _instance;
  WebSearchToolManager._internal();

  final WebSearchService _searchService = WebSearchService();

  /// 初始化搜索工具
  Future<void> initialize() async {
    // 从安全存储中加载API密钥
    final tavilyKey = await UnifiedSecureStorage.getSearchApiKey('tavily');
    final serpApiKey = await UnifiedSecureStorage.getSearchApiKey('serpapi');
    final serperKey = await UnifiedSecureStorage.getSearchApiKey('serper');

    if (tavilyKey != null) {
      _searchService.setTavilyApiKey(tavilyKey);
    }
    if (serpApiKey != null) {
      _searchService.setSerpApiKey(serpApiKey);
    }
    if (serperKey != null) {
      _searchService.setSerperApiKey(serperKey);
    }

    pl.i(
      '搜索工具初始化完成 - '
      'Tavily: ${_searchService.hasTavilyApiKey}, '
      'SerpApi: ${_searchService.hasSerpApiKey}, '
      'Serper: ${_searchService.hasSerperApiKey}',
    );
  }

  /// 获取联网搜索工具定义
  List<OpenAITool> getSearchTools() {
    if (!_searchService.hasTavilyApiKey &&
        !_searchService.hasSerpApiKey &&
        !_searchService.hasSerperApiKey) {
      return [];
    }

    return [
      OpenAITool.function(
        OpenAIFunction(
          name: 'web_search',
          description: '执行联网搜索，获取最新的网络信息。适用于需要实时信息、最新新闻、当前事件、具体数据查询等场景。',
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
      // OpenAITool.function(
      //   OpenAIFunction(
      //     name: "web_search",
      //     description: "联网搜索最新信息",
      //     parameters: {
      //       "type": "object",
      //       "properties": {
      //         "query": {"type": "string", "description": "搜索关键词"},
      //         'search_type': {'type': 'string', 'default': 'general'},
      //         "max_results": {"type": "number", "default": 10},
      //       },
      //       "required": ["query"],
      //     },
      //   ),
      // ),
    ];
  }

  /// 处理联网搜索工具调用
  Future<Map<String, dynamic>> handleToolCall({
    required String functionName,
    required Map<String, dynamic> arguments,
  }) async {
    if (functionName != 'web_search') {
      return {
        'content': '不支持的工具调用: $functionName',
        'searchReferences': <Map<String, dynamic>>[],
      };
    }

    try {
      final query = arguments['query'] as String?;
      if (query == null || query.trim().isEmpty) {
        return {
          'content': '搜索查询不能为空',
          'searchReferences': <Map<String, dynamic>>[],
        };
      }

      final searchType = arguments['search_type'] as String? ?? 'general';
      final maxResults = arguments['max_results'] as int? ?? 10;

      // 根据搜索类型选择合适的工具
      SearchToolType? preferredTool;
      if (searchType == 'news' && _searchService.hasTavilyApiKey) {
        preferredTool = SearchToolType.tavily; // Tavily对新闻搜索支持更好
      }

      final result = await _searchService.search(
        query: query.trim(),
        preferredTool: preferredTool,
        maxResults: maxResults,
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

      return {
        'content': result.toToolCallResult(),
        'searchReferences': searchReferences,
      };
    } catch (e) {
      ToastUtils.showError("工具调用处理失败: $e");
      return {
        'content': '搜索失败: $e',
        'searchReferences': <Map<String, dynamic>>[],
      };
    }
  }

  /// 检查是否有可用的搜索工具
  bool hasAvailableTools() {
    return _searchService.hasTavilyApiKey ||
        _searchService.hasSerpApiKey ||
        _searchService.hasSerperApiKey;
  }

  /// 获取工具状态
  Map<String, bool> getToolStatus() {
    final status = _searchService.getToolStatus();
    return {
      'tavily': status[SearchToolType.tavily] ?? false,
      'serpapi': status[SearchToolType.serpapi] ?? false,
      'serper': status[SearchToolType.serper] ?? false,
    };
  }

  /// 设置API密钥
  Future<void> setApiKey(String toolType, String apiKey) async {
    switch (toolType.toLowerCase()) {
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
  }

  /// 测试工具连接
  Future<bool> testToolConnection(String toolType) async {
    SearchToolType? type;
    switch (toolType.toLowerCase()) {
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

  /// 清理资源
  void dispose() {
    _searchService.dispose();
  }
}
