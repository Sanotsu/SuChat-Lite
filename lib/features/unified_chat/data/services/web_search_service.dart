import '../../../../core/network/dio_client/cus_http_client.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../models/web_search_models.dart';
import 'unified_secure_storage.dart';

/// 联网搜索服务
class WebSearchService {
  static final WebSearchService _instance = WebSearchService._internal();
  factory WebSearchService() => _instance;
  WebSearchService._internal();

  // API密钥存储
  String? _tavilyApiKey;
  String? _serpApiKey;
  String? _serperApiKey;

  /// 设置Tavily API密钥
  void setTavilyApiKey(String apiKey) {
    _tavilyApiKey = apiKey;
  }

  /// 设置SerpApi API密钥
  void setSerpApiKey(String apiKey) {
    _serpApiKey = apiKey;
  }

  /// 设置Serper API密钥
  void setSerperApiKey(String apiKey) {
    _serperApiKey = apiKey;
  }

  /// 检查Tavily API密钥是否已配置
  bool get hasTavilyApiKey =>
      _tavilyApiKey != null && _tavilyApiKey!.isNotEmpty;

  /// 检查SerpApi API密钥是否已配置
  bool get hasSerpApiKey => _serpApiKey != null && _serpApiKey!.isNotEmpty;

  /// 检查Serper API密钥是否已配置
  bool get hasSerperApiKey =>
      _serperApiKey != null && _serperApiKey!.isNotEmpty;

  /// 统一搜索接口
  Future<UnifiedSearchResponse> search({
    required String query,
    SearchToolType? preferredTool,
    int maxResults = 10,
    bool includeAnswer = true,
  }) async {
    // 确定使用的搜索工具
    SearchToolType toolType;
    if (preferredTool != null) {
      toolType = preferredTool;
    } else {
      // 获取用户首选的搜索工具
      final preferredToolString =
          await UnifiedSecureStorage.getPreferredSearchTool();
      SearchToolType? userPreferredTool;

      if (preferredToolString != null) {
        switch (preferredToolString) {
          case 'tavily':
            userPreferredTool = SearchToolType.tavily;
            break;
          case 'serpapi':
            userPreferredTool = SearchToolType.serpapi;
            break;
          case 'serper':
            userPreferredTool = SearchToolType.serper;
            break;
        }
      }

      // 如果用户设置了首选工具且该工具可用，则使用用户首选的工具
      if (userPreferredTool != null && _isToolAvailable(userPreferredTool)) {
        toolType = userPreferredTool;
      } else {
        // 否则按默认优先级选择可用的工具：Tavily > Serper > SerpApi
        if (hasTavilyApiKey) {
          toolType = SearchToolType.tavily;
        } else if (hasSerperApiKey) {
          toolType = SearchToolType.serper;
        } else if (hasSerpApiKey) {
          toolType = SearchToolType.serpapi;
        } else {
          return UnifiedSearchResponse.error(
            query: query,
            toolType: SearchToolType.tavily,
            error: '未配置任何搜索API密钥',
          );
        }
      }
    }

    try {
      SearchResult result;
      switch (toolType) {
        case SearchToolType.tavily:
          if (!hasTavilyApiKey) {
            return UnifiedSearchResponse.error(
              query: query,
              toolType: toolType,
              error: 'Tavily API密钥未配置',
            );
          }
          result = await _searchWithTavily(
            query: query,
            maxResults: maxResults,
            includeAnswer: includeAnswer,
          );
          break;
        case SearchToolType.serpapi:
          if (!hasSerpApiKey) {
            return UnifiedSearchResponse.error(
              query: query,
              toolType: toolType,
              error: 'SerpApi API密钥未配置',
            );
          }
          result = await _searchWithSerpApi(
            query: query,
            maxResults: maxResults,
          );
          break;
        case SearchToolType.serper:
          if (!hasSerperApiKey) {
            return UnifiedSearchResponse.error(
              query: query,
              toolType: toolType,
              error: 'Serper API密钥未配置',
            );
          }
          result = await _searchWithSerper(
            query: query,
            maxResults: maxResults,
          );
          break;
      }

      return UnifiedSearchResponse.success(
        query: query,
        toolType: toolType,
        searchResult: result,
      );
    } catch (e) {
      ToastUtils.showError("WebSearchService 的 serach 方法报错: $e");
      return UnifiedSearchResponse.error(
        query: query,
        toolType: toolType,
        error: e.toString(),
      );
    }
  }

  /// 使用Tavily进行搜索
  Future<TavilySearchResponse> _searchWithTavily({
    required String query,
    int maxResults = 10,
    bool includeAnswer = true,
    String searchDepth = 'basic',
    String topic = 'general',
  }) async {
    final request = TavilySearchRequest(
      query: query,
      maxResults: maxResults,
      includeAnswer: includeAnswer,
      searchDepth: searchDepth,
      topic: topic,
    );

    final headers = {
      'Authorization': 'Bearer $_tavilyApiKey',
      'Content-Type': 'application/json',
    };

    final response = await HttpUtils.post(
      path: 'https://api.tavily.com/search',
      data: request.toJson(),
      headers: headers,
      showLoading: false,
      showErrorMessage: false,
    );

    return TavilySearchResponse.fromRawJson(response);
  }

  /// 使用SerpApi进行搜索
  Future<SerpApiSearchResponse> _searchWithSerpApi({
    required String query,
    int maxResults = 10,
    String? location,
    String? gl,
  }) async {
    final request = SerpApiSearchRequest(
      q: query,
      num: maxResults,
      location: location,
      gl: gl,
    );

    final queryParams = request.toJson();
    queryParams['api_key'] = _serpApiKey;

    final response = await HttpUtils.get(
      path: 'https://serpapi.com/search',
      queryParameters: queryParams,
      showLoading: false,
      showErrorMessage: false,
    );

    return SerpApiSearchResponse.fromRawJson(response);
  }

  /// 使用Serper进行搜索
  Future<SerperSearchResponse> _searchWithSerper({
    required String query,
    int maxResults = 10,
    String? gl,
  }) async {
    final request = SerperSearchRequest(q: query, num: maxResults, gl: gl);

    final headers = {
      'X-API-KEY': _serperApiKey!,
      'Content-Type': 'application/json',
    };

    final response = await HttpUtils.post(
      path: 'https://google.serper.dev/search',
      data: request.toJson(),
      headers: headers,
      showLoading: false,
      showErrorMessage: false,
    );

    return SerperSearchResponse.fromRawJson(response);
  }

  /// 测试API连接
  Future<bool> testConnection(SearchToolType toolType) async {
    try {
      switch (toolType) {
        case SearchToolType.tavily:
          if (!hasTavilyApiKey) return false;
          await _searchWithTavily(
            query: 'test',
            maxResults: 1,
            includeAnswer: false,
          );
          return true;
        case SearchToolType.serpapi:
          if (!hasSerpApiKey) return false;
          await _searchWithSerpApi(query: 'test', maxResults: 1);
          return true;
        case SearchToolType.serper:
          if (!hasSerperApiKey) return false;
          await _searchWithSerper(query: 'test', maxResults: 1);
          return true;
      }
    } catch (e) {
      ToastUtils.showError("测试连接失败: $e");
      return false;
    }
  }

  /// 获取搜索工具状态
  Map<SearchToolType, bool> getToolStatus() {
    return {
      SearchToolType.tavily: hasTavilyApiKey,
      SearchToolType.serpapi: hasSerpApiKey,
      SearchToolType.serper: hasSerperApiKey,
    };
  }

  /// 检查工具是否可用
  bool _isToolAvailable(SearchToolType toolType) {
    switch (toolType) {
      case SearchToolType.tavily:
        return hasTavilyApiKey;
      case SearchToolType.serpapi:
        return hasSerpApiKey;
      case SearchToolType.serper:
        return hasSerperApiKey;
    }
  }

  /// 清理资源
  void dispose() {
    _tavilyApiKey = null;
    _serpApiKey = null;
    _serperApiKey = null;
  }
}
