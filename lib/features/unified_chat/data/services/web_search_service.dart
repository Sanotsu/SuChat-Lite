import '../../../../core/network/dio_client/cus_http_client.dart';
import '../models/web_search_models.dart';
import 'unified_secure_storage.dart';

/// 联网搜索服务
class WebSearchService {
  static final WebSearchService _instance = WebSearchService._internal();
  factory WebSearchService() => _instance;
  WebSearchService._internal();

  // API密钥存储
  String? _bochaApiKey;
  String? _baiduApiKey;
  String? _tavilyApiKey;
  String? _serpApiKey;
  String? _serperApiKey;

  /// 设置博查API密钥
  void setBochaApiKey(String apiKey) {
    _bochaApiKey = apiKey;
  }

  /// 设置百度搜索API密钥(千帆AppBuilder APIKey)
  void setBaiduApiKey(String apiKey) {
    _baiduApiKey = apiKey;
  }

  // 2026-09-09 百度千帆AI搜索模式：
  //   false=纯检索(web_search，返回原始结果列表，模型自主整合)
  //   true=智能搜索生成(chat/completions，百度先整合一段答案+引用，
  //        工具结果更精炼，可减少模型多轮搜索的倾向；多一次百度侧生成耗时)
  bool _baiduUseIntelligent = false;

  /// 设置百度搜索模式('retrieval'=纯检索 / 'intelligent'=智能生成)
  void setBaiduUseIntelligent(String mode) {
    _baiduUseIntelligent = mode == 'intelligent';
  }

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

  /// 检查博查API密钥是否已配置
  bool get hasBochaApiKey => _bochaApiKey != null && _bochaApiKey!.isNotEmpty;

  /// 检查百度搜索API密钥是否已配置
  bool get hasBaiduApiKey => _baiduApiKey != null && _baiduApiKey!.isNotEmpty;

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
          case 'bocha':
            userPreferredTool = SearchToolType.bocha;
            break;
          case 'baidu':
            userPreferredTool = SearchToolType.baidu;
            break;
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
        // 否则按默认优先级选择可用的工具
        // 2026-09-09 调整为 博查 > 百度 > Tavily > Serper > SerpApi
        // (博查/百度为国内直连服务，大陆网络环境下可用性最好；
        //  百度每日有100次免费额度)
        if (hasBochaApiKey) {
          toolType = SearchToolType.bocha;
        } else if (hasBaiduApiKey) {
          toolType = SearchToolType.baidu;
        } else if (hasTavilyApiKey) {
          toolType = SearchToolType.tavily;
        } else if (hasSerperApiKey) {
          toolType = SearchToolType.serper;
        } else if (hasSerpApiKey) {
          toolType = SearchToolType.serpapi;
        } else {
          return UnifiedSearchResponse.error(
            query: query,
            toolType: SearchToolType.bocha,
            error: '未配置任何搜索API密钥',
          );
        }
      }
    }

    try {
      SearchResult result;
      switch (toolType) {
        case SearchToolType.bocha:
          if (!hasBochaApiKey) {
            return UnifiedSearchResponse.error(
              query: query,
              toolType: toolType,
              error: '博查API密钥未配置',
            );
          }
          result = await _searchWithBocha(query: query, maxResults: maxResults);
          break;
        case SearchToolType.baidu:
          if (!hasBaiduApiKey) {
            return UnifiedSearchResponse.error(
              query: query,
              toolType: toolType,
              error: '百度搜索API密钥未配置',
            );
          }
          // 2026-09-09 按用户配置的百度搜索模式分流
          result = _baiduUseIntelligent
              ? await _searchWithBaiduIntelligent(query: query)
              : await _searchWithBaidu(query: query, maxResults: maxResults);
          break;
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
      // 2026-09-09 错误不再在服务层弹Toast，随响应返回由调用方处理
      return UnifiedSearchResponse.error(
        query: query,
        toolType: toolType,
        error: e.toString(),
      );
    }
  }

  /// 使用博查进行搜索(国内直连，响应兼容Bing格式)
  Future<BochaSearchResponse> _searchWithBocha({
    required String query,
    int maxResults = 10,
    String freshness = 'noLimit',
  }) async {
    final request = BochaSearchRequest(
      query: query,
      count: maxResults,
      freshness: freshness,
      summary: true,
    );

    final headers = {
      'Authorization': 'Bearer $_bochaApiKey',
      'Content-Type': 'application/json',
    };

    final response = await HttpUtils.post(
      path: 'https://api.bochaai.com/v1/web-search',
      data: request.toJson(),
      headers: headers,
      showLoading: false,
      showErrorMessage: false,
    );

    return BochaSearchResponse.fromRawJson(response);
  }

  /// 使用百度搜索进行搜索(千帆AppBuilder纯检索模式，国内直连，每日100次免费)
  Future<BaiduSearchResponse> _searchWithBaidu({
    required String query,
    int maxResults = 10,
    String? recency, // week/month/semiyear/year，null=不限制
  }) async {
    final request = BaiduSearchRequest(
      messages: [BaiduSearchMessage(role: 'user', content: query)],
      resourceTypeFilter: [
        BaiduSearchResourceFilter(
          type: 'web',
          // 网页top_k最大50
          topK: maxResults.clamp(1, 50),
        ),
      ],
      searchRecencyFilter: recency,
    );

    // 文档接口定义表写Authorization，curl示例用X-Appbuilder-Authorization，
    // 两处不一致，两个头都带上以保兼容
    final headers = {
      'Authorization': 'Bearer $_baiduApiKey',
      'X-Appbuilder-Authorization': 'Bearer $_baiduApiKey',
      'Content-Type': 'application/json',
    };

    final response = await HttpUtils.post(
      path: 'https://qianfan.baidubce.com/v2/ai_search/web_search',
      data: request.toJson(),
      headers: headers,
      showLoading: false,
      showErrorMessage: false,
    );

    // 错误响应形状：{requestId, code, message}且无references
    if (response['code'] != null && (response['references'] as List?) == null) {
      throw Exception('百度搜索失败[${response['code']}]: ${response['message']}');
    }

    return BaiduSearchResponse.fromRawJson(response);
  }

  /// 2026-09-09 使用百度智能搜索生成(千帆AppBuilder /v2/ai_search/chat/completions)
  /// 与纯检索的区别：百度服务端先基于检索结果整合生成一段答案再返回，
  /// 引用列表形状与纯检索一致。注意此模式百度侧多一次生成，耗时更长；
  /// 资源过滤等参数未显式传(走百度默认web检索，避免参数形状差异导致报错)
  Future<BaiduSearchResponse> _searchWithBaiduIntelligent({
    required String query,
  }) async {
    final body = {
      'messages': [
        {'role': 'user', 'content': query},
      ],
    };

    // 文档接口定义表写Authorization，curl示例用X-Appbuilder-Authorization，
    // 两处不一致，两个头都带上以保兼容(与纯检索模式一致)
    final headers = {
      'Authorization': 'Bearer $_baiduApiKey',
      'X-Appbuilder-Authorization': 'Bearer $_baiduApiKey',
      'Content-Type': 'application/json',
    };

    final response = await HttpUtils.post(
      path: 'https://qianfan.baidubce.com/v2/ai_search/chat/completions',
      data: body,
      headers: headers,
      showLoading: false,
      showErrorMessage: false,
    );

    return BaiduSearchResponse.fromIntelligentRawJson(response);
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
        case SearchToolType.bocha:
          if (!hasBochaApiKey) return false;
          await _searchWithBocha(query: 'test', maxResults: 1);
          return true;
        case SearchToolType.baidu:
          if (!hasBaiduApiKey) return false;
          await _searchWithBaidu(query: 'test', maxResults: 1);
          return true;
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
      return false;
    }
  }

  /// 获取搜索工具状态
  Map<SearchToolType, bool> getToolStatus() {
    return {
      SearchToolType.bocha: hasBochaApiKey,
      SearchToolType.baidu: hasBaiduApiKey,
      SearchToolType.tavily: hasTavilyApiKey,
      SearchToolType.serpapi: hasSerpApiKey,
      SearchToolType.serper: hasSerperApiKey,
    };
  }

  /// 检查工具是否可用
  bool _isToolAvailable(SearchToolType toolType) {
    switch (toolType) {
      case SearchToolType.bocha:
        return hasBochaApiKey;
      case SearchToolType.baidu:
        return hasBaiduApiKey;
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
    _bochaApiKey = null;
    _baiduApiKey = null;
    _tavilyApiKey = null;
    _serpApiKey = null;
    _serperApiKey = null;
  }
}
