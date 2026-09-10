import 'package:json_annotation/json_annotation.dart';

part 'web_search_models.g.dart';

/// 搜索工具类型枚举
enum SearchToolType { bocha, baidu, tavily, serpapi, serper }

/// 搜索结果基类
abstract class SearchResult {
  final String? query;

  final List<SearchResultItem>? results;

  final String? answer;

  @JsonKey(name: 'response_time')
  final double? responseTime;

  const SearchResult({
    this.query,
    this.results,
    this.answer,
    this.responseTime,
  });

  Map<String, dynamic> toJson();
}

/// 搜索结果项
@JsonSerializable(explicitToJson: true)
class SearchResultItem {
  final String? title;
  final String? url;
  final String? content;
  final double? score;
  final String? favicon;
  final String? publishedDate;

  const SearchResultItem({
    this.title,
    this.url,
    this.content,
    this.score,
    this.favicon,
    this.publishedDate,
  });

  factory SearchResultItem.fromJson(Map<String, dynamic> json) =>
      _$SearchResultItemFromJson(json);

  Map<String, dynamic> toJson() => _$SearchResultItemToJson(this);
}

/// Tavily搜索请求
/// API文档: https://docs.tavily.com/documentation/api-reference/endpoint/search
/// 仅使用一些必填和常用参数
@JsonSerializable(explicitToJson: true)
class TavilySearchRequest {
  final String query;

  // 枚举值: basic (1个积分), advanced (2个积分)
  @JsonKey(name: 'search_depth')
  final String searchDepth;

  // 是否包含快速回答: basic 或者 true 返回快速回答, advanced 返回详细回答
  @JsonKey(name: 'include_answer')
  final bool includeAnswer;

  // 是否显示原始文档: false 不显示, true 和 markdown 显示md文档, text 显示文本文档
  @JsonKey(name: 'include_raw_content')
  final bool includeRawContent;

  // 最大结果数[0,20]
  @JsonKey(name: 'max_results')
  final int maxResults;

  // 搜索的主题，默认 general(通用),可选的有: general, news, finance
  final String? topic;

  @JsonKey(name: 'include_domains')
  final List<String>? includeDomains;

  @JsonKey(name: 'exclude_domains')
  final List<String>? excludeDomains;

  const TavilySearchRequest({
    required this.query,
    this.searchDepth = 'basic',
    this.includeAnswer = true,
    this.includeRawContent = false,
    // 最大搜索结果[0,20]
    this.maxResults = 20,
    this.topic = 'general',
    this.includeDomains,
    this.excludeDomains,
  });

  factory TavilySearchRequest.fromJson(Map<String, dynamic> json) =>
      _$TavilySearchRequestFromJson(json);

  Map<String, dynamic> toJson() => _$TavilySearchRequestToJson(this);
}

/// Tavily搜索响应
/// 也只保留几个简单的字段
@JsonSerializable(explicitToJson: true)
class TavilySearchResponse extends SearchResult {
  // answer、results、query、responseTime 字段在父类中已定义，这里不需要重复定义。
  final List<String>? images;

  @JsonKey(name: 'auto_parameters')
  final Map<String, dynamic>? autoParameters;

  @JsonKey(name: 'request_id')
  final String? requestId;

  // 在构造函数中，使用 super.xxx 这样的语法直接将参数传递给父类的构造函数
  const TavilySearchResponse({
    super.query,
    super.answer,
    super.results,
    super.responseTime,
    this.images,
    this.autoParameters,
    this.requestId,
  });

  factory TavilySearchResponse.fromJson(Map<String, dynamic> json) =>
      _$TavilySearchResponseFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$TavilySearchResponseToJson(this);

  factory TavilySearchResponse.fromRawJson(Map<String, dynamic> json) {
    final results =
        (json['results'] as List?)
            ?.map(
              (item) => SearchResultItem(
                title: item['title'] ?? '',
                url: item['url'] ?? '',
                content: item['content'] ?? '',
                score: item['score']?.toDouble(),
                favicon: item['favicon'],
              ),
            )
            .toList() ??
        [];

    return TavilySearchResponse(
      query: json['query'] ?? '',
      results: results,
      answer: json['answer'],
      responseTime: (json['response_time'] ?? 0).toDouble(),
      images: (json['images'] as List?)?.cast<String>(),
    );
  }
}

/// SerpApi搜索请求
/// https://serpapi.com/search-api
@JsonSerializable(explicitToJson: true)
class SerpApiSearchRequest {
  // 搜索关键字
  final String q;
  // 国家
  final String? gl;
  // 位置
  final String? location;
  // 语言
  final String? hl;
  // 搜索引擎
  final String engine;
  // 是否使用缓存(如果使用缓存，1小时内搜索结果会从缓存中获取，不增加积分消耗)
  @JsonKey(name: 'no_cache')
  final bool? noCache;
  // 输出格式(json, html)
  @JsonKey(name: 'output')
  final String? output;

  // 每页结果数
  final int? num;
  // 起始偏移量(1页10条的话，第一页start=0，第二页start=10，第三页start=20，以此类推)
  final int? start;

  // 尽量少的参数
  const SerpApiSearchRequest({
    required this.q,
    this.gl = 'cn',
    this.location,
    this.hl = 'zh-cn',
    this.engine = 'google',
    this.noCache = false,
    this.output = 'json',
    this.num = 40,
    this.start = 0,
  });

  factory SerpApiSearchRequest.fromJson(Map<String, dynamic> json) =>
      _$SerpApiSearchRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SerpApiSearchRequestToJson(this);
}

/// SerpApi搜索响应
/// https://serpapi.com/search-api
@JsonSerializable(explicitToJson: true)
class SerpApiSearchResponse extends SearchResult {
  @JsonKey(name: 'search_metadata')
  final Map<String, dynamic>? searchMetadata;
  @JsonKey(name: 'search_parameters')
  final Map<String, dynamic>? searchParameters;
  @JsonKey(name: 'search_information')
  final Map<String, dynamic>? searchInformation;

  // 不同分类结果不一样，只选择了几个典型的
  @JsonKey(name: 'organic_results')
  final List<Map<String, dynamic>>? organicResults;
  @JsonKey(name: 'top_stories')
  final List<dynamic>? topStories;

  @JsonKey(name: 'pagination')
  final Map<String, dynamic>? pagination;
  @JsonKey(name: 'serpapi_pagination')
  final Map<String, dynamic>? serpapiPagination;

  const SerpApiSearchResponse({
    super.query,
    super.results,
    this.searchMetadata,
    this.searchParameters,
    this.searchInformation,

    this.organicResults,
    this.topStories,

    this.pagination,
    this.serpapiPagination,
  });

  factory SerpApiSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$SerpApiSearchResponseFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SerpApiSearchResponseToJson(this);

  factory SerpApiSearchResponse.fromRawJson(Map<String, dynamic> json) {
    final organicResults = json['organic_results'] as List? ?? [];

    final results = organicResults
        .map(
          (item) => SearchResultItem(
            title: item['title'] ?? '',
            url: item['link'] ?? '',
            content: item['snippet'] ?? '',
            publishedDate: item['date'],
          ),
        )
        .toList();

    return SerpApiSearchResponse(
      query: json['search_parameters']?['q'] ?? '',
      results: results,
      searchMetadata: json['search_metadata'],
      searchParameters: json['search_parameters'],
      searchInformation: json['search_information'],
      topStories: json['top_stories'],
      pagination: json['pagination'],
      serpapiPagination: json['serpapi_pagination'],
    );
  }

  @override
  double get responseTime {
    return double.tryParse(
          searchMetadata?['total_time_taken']?.toString() ?? '0',
        ) ??
        0.0;
  }
}

/// Serper搜索请求
/// https://serper.dev/playground
/// 不同的分类结构不一样，这里默认是search的type，请求url为 https://google.serper.dev/search
@JsonSerializable(explicitToJson: true)
class SerperSearchRequest {
  // 搜索关键字
  final String q;
  // 国家
  final String? gl;
  // 位置
  final String? location;
  // 语言
  final String? hl;
  // 每页结果数
  final int? num;
  // 起始位置
  final int? page;
  // 搜索类型
  final String? type;

  const SerperSearchRequest({
    required this.q,
    this.gl = 'cn',
    this.location,
    this.hl = 'zh-cn',
    this.num = 10,
    this.page = 1,
    this.type = 'search',
  });

  factory SerperSearchRequest.fromJson(Map<String, dynamic> json) =>
      _$SerperSearchRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SerperSearchRequestToJson(this);
}

/// Serper搜索响应
/// https://serper.dev/playground
/// 结果的key是驼峰命名不是下划线格式
@JsonSerializable(explicitToJson: true)
class SerperSearchResponse extends SearchResult {
  @JsonKey(name: 'searchParameters')
  final Map<String, dynamic>? searchParameters;

  @JsonKey(name: 'searchInformation')
  final Map<String, dynamic>? searchInformation;

  // 查询的结果 (如果type是search，那么就是organic)
  // (如果type是news，这俄国关键字就是news; 如果type是images，那么就是images……以此类推）
  final List<Map<String, dynamic>>? organic;

  @JsonKey(name: 'credits')
  final int? credits;

  const SerperSearchResponse({
    super.query,
    super.results,
    this.searchParameters,
    this.organic,
    this.credits,
    this.searchInformation,
  });

  factory SerperSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$SerperSearchResponseFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SerperSearchResponseToJson(this);

  factory SerperSearchResponse.fromRawJson(Map<String, dynamic> json) {
    final organicResults =
        json['organic'] as List? ?? json['news'] as List? ?? [];
    final results = organicResults
        .map(
          (item) => SearchResultItem(
            title: item['title'] ?? '',
            url: item['link'] ?? '',
            content: item['snippet'] ?? '',
            publishedDate: item['date'],
          ),
        )
        .toList();

    return SerperSearchResponse(
      query: json['searchParameters']?['q'] ?? '',
      results: results,
      searchParameters: json['searchParameters'],
      searchInformation: json['searchInformation'],
      credits: json['credits'],
    );
  }

  @override
  double get responseTime {
    return 0.0; // Serper API不提供响应时间信息
  }
}

/// 博查搜索请求
/// https://open.bochaai.com (国内直连的AI搜索API，响应兼容Bing Search API格式)
/// POST https://api.bochaai.com/v1/web-search (Authorization: Bearer)
@JsonSerializable(explicitToJson: true)
class BochaSearchRequest {
  // 搜索关键词
  final String query;

  // 搜索时间范围: noLimit(默认)/oneDay/oneWeek/oneMonth/oneYear
  final String freshness;

  // 是否返回正文摘要(summary比snippet内容更全)
  final bool summary;

  // 返回结果条数(1-50，默认10)
  final int count;

  // 页码(从1开始)
  final int page;

  const BochaSearchRequest({
    required this.query,
    this.freshness = 'noLimit',
    this.summary = true,
    this.count = 10,
    this.page = 1,
  });

  factory BochaSearchRequest.fromJson(Map<String, dynamic> json) =>
      _$BochaSearchRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BochaSearchRequestToJson(this);
}

/// 博查搜索响应(Bing Search API兼容格式)
/// 结构: { code, log_id, data: { webPages: { value: [...] } } }
@JsonSerializable(explicitToJson: true)
class BochaSearchResponse extends SearchResult {
  final Map<String, dynamic>? data;

  const BochaSearchResponse({super.query, super.results, this.data});

  factory BochaSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$BochaSearchResponseFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$BochaSearchResponseToJson(this);

  factory BochaSearchResponse.fromRawJson(Map<String, dynamic> json) {
    final webPages = json['data']?['webPages'] as Map<String, dynamic>?;
    final value = webPages?['value'] as List? ?? [];

    final results = value
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => SearchResultItem(
            title: item['name'] ?? '',
            url: item['url'] ?? '',
            // summary是正文摘要，snippet是搜索片段，优先取更全的summary
            content: item['summary'] ?? item['snippet'] ?? '',
            favicon: item['favicon'],
            publishedDate: item['dateLastCrawled'],
          ),
        )
        .toList();

    return BochaSearchResponse(
      query: json['query'] ?? '',
      results: results,
      data: json['data'],
    );
  }
}

/// 百度搜索请求(千帆AppBuilder"百度搜索"组件，纯检索模式)
/// https://ai.baidu.com/ai-doc/AppBuilder/pmaxd1hvy
/// POST https://qianfan.baidubce.com/v2/ai_search/web_search
/// (X-Appbuilder-)Authorization: Bearer + AppBuilder API Key
/// 计费：每日免费100次，超额按量后付费
/// 注意：不接入"智能搜索生成"(/v2/ai_search/chat/completions，百度用自有模型
/// 总结回答)——我们的架构是把检索结果喂给对话中的大模型自己总结，避免双重生成
@JsonSerializable(explicitToJson: true)
class BaiduSearchRequest {
  // 搜索输入；该接口仅支持单轮，以最后一条user的content为查询词
  @JsonKey(name: 'messages')
  final List<BaiduSearchMessage> messages;

  // 搜索版本：standard完整版(默认) / lite简化版(时延更好效果略弱)
  final String edition;

  // 使用的搜索引擎版本，固定baidu_search_v2
  @JsonKey(name: 'search_source')
  final String searchSource;

  // 各模态最大返回数量，网页top_k最大50
  @JsonKey(name: 'resource_type_filter')
  final List<BaiduSearchResourceFilter> resourceTypeFilter;

  // 网页发布时间筛选：week/month/semiyear/year，null=不限制
  @JsonKey(name: 'search_recency_filter')
  final String? searchRecencyFilter;

  const BaiduSearchRequest({
    required this.messages,
    this.edition = 'standard',
    this.searchSource = 'baidu_search_v2',
    required this.resourceTypeFilter,
    this.searchRecencyFilter,
  });

  factory BaiduSearchRequest.fromJson(Map<String, dynamic> json) =>
      _$BaiduSearchRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BaiduSearchRequestToJson(this);
}

/// 百度搜索请求的消息对象
@JsonSerializable(explicitToJson: true)
class BaiduSearchMessage {
  final String role;
  final String content;

  const BaiduSearchMessage({required this.role, required this.content});

  factory BaiduSearchMessage.fromJson(Map<String, dynamic> json) =>
      _$BaiduSearchMessageFromJson(json);

  Map<String, dynamic> toJson() => _$BaiduSearchMessageToJson(this);
}

/// 百度搜索的资源类型过滤(web最大50)
@JsonSerializable(explicitToJson: true)
class BaiduSearchResourceFilter {
  // 搜索资源类型：web网页 / video视频 / image图片 / aladdin阿拉丁
  final String type;

  @JsonKey(name: 'top_k')
  final int topK;

  const BaiduSearchResourceFilter({required this.type, required this.topK});

  factory BaiduSearchResourceFilter.fromJson(Map<String, dynamic> json) =>
      _$BaiduSearchResourceFilterFromJson(json);

  Map<String, dynamic> toJson() => _$BaiduSearchResourceFilterToJson(this);
}

/// 百度搜索响应(纯检索模式，返回引用列表references)
@JsonSerializable(explicitToJson: true)
class BaiduSearchResponse extends SearchResult {
  @JsonKey(name: 'references')
  final List<Map<String, dynamic>>? references;

  const BaiduSearchResponse({
    super.query,
    super.results,
    super.answer,
    this.references,
  });

  factory BaiduSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$BaiduSearchResponseFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$BaiduSearchResponseToJson(this);

  factory BaiduSearchResponse.fromRawJson(Map<String, dynamic> json) {
    final refs = json['references'] as List? ?? [];

    final results = refs
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => SearchResultItem(
            title: item['title'] ?? '',
            url: item['url'] ?? '',
            // 网页内容原文片段(纯检索模式2000字以内，比智能生成模式的200字更全)
            content: item['content'] ?? '',
            favicon: item['icon'],
            publishedDate: item['date'],
            // 原文片段相关性评分[0,1]，仅web/video/image类型存在
            score: item['rerank_score']?.toDouble(),
          ),
        )
        .toList();

    return BaiduSearchResponse(
      query: json['query'] ?? '',
      results: results,
      references: refs.whereType<Map<String, dynamic>>().toList(),
    );
  }

  /// 2026-09-09 智能搜索生成模式响应
  /// (POST /v2/ai_search/chat/completions)：百度先整合生成一段答案放在
  /// choices的assistant消息里，references字段形状与纯检索模式一致，
  /// 复用同一套解析，答案文本进answer供toToolCallResult输出
  factory BaiduSearchResponse.fromIntelligentRawJson(
    Map<String, dynamic> json,
  ) {
    // 错误响应形状：{requestId, code, message}且无references
    if (json['code'] != null && (json['references'] as List?) == null) {
      throw Exception('百度智能搜索失败[${json['code']}]: ${json['message']}');
    }

    // 提取choices里的assistant整合答案
    String answer = '';
    final choices = json['choices'] as List? ?? [];
    for (final choice in choices.whereType<Map<String, dynamic>>()) {
      final messages = choice['messages'] as List? ?? [];
      for (final msg in messages.whereType<Map<String, dynamic>>()) {
        if (msg['role'] == 'assistant' && msg['content'] is String) {
          answer = msg['content'] as String;
        }
      }
    }

    final parsed = BaiduSearchResponse.fromRawJson(json);
    return BaiduSearchResponse(
      query: parsed.query,
      results: parsed.results,
      references: parsed.references,
      answer: answer.isNotEmpty ? answer : null,
    );
  }
}

/// 统一搜索工具响应
@JsonSerializable(explicitToJson: true)
class UnifiedSearchResponse {
  final String query;
  final SearchToolType toolType;
  final List<SearchResultItem> results;
  final String? answer;
  final double responseTime;
  final bool success;
  final String? error;
  final DateTime timestamp;

  const UnifiedSearchResponse({
    required this.query,
    required this.toolType,
    required this.results,
    this.answer,
    required this.responseTime,
    required this.success,
    this.error,
    required this.timestamp,
  });

  factory UnifiedSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$UnifiedSearchResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UnifiedSearchResponseToJson(this);

  factory UnifiedSearchResponse.success({
    required String query,
    required SearchToolType toolType,
    required SearchResult searchResult,
  }) {
    return UnifiedSearchResponse(
      query: query,
      toolType: toolType,
      results: searchResult.results ?? [],
      answer: searchResult.answer,
      responseTime: searchResult.responseTime ?? 0.0,
      success: true,
      timestamp: DateTime.now(),
    );
  }

  factory UnifiedSearchResponse.error({
    required String query,
    required SearchToolType toolType,
    required String error,
  }) {
    return UnifiedSearchResponse(
      query: query,
      toolType: toolType,
      results: [],
      responseTime: 0.0,
      success: false,
      error: error,
      timestamp: DateTime.now(),
    );
  }

  /// 转换为工具调用结果格式
  String toToolCallResult() {
    if (!success) {
      return '搜索失败: $error';
    }

    final buffer = StringBuffer();
    buffer.writeln('搜索查询: $query');
    buffer.writeln('搜索工具: ${toolType.name}');
    buffer.writeln('响应时间: ${responseTime.toStringAsFixed(2)}秒');

    if (answer != null && answer!.isNotEmpty) {
      buffer.writeln('\n直接答案:');
      buffer.writeln(answer);
    }

    buffer.writeln('\n搜索结果:');
    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      buffer.writeln('${i + 1}. ${result.title}');
      buffer.writeln('   链接: ${result.url}');
      buffer.writeln('   摘要: ${result.content}');
      if (result.publishedDate != null) {
        buffer.writeln('   发布时间: ${result.publishedDate}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}
