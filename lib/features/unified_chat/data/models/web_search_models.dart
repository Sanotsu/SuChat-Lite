import 'package:json_annotation/json_annotation.dart';

part 'web_search_models.g.dart';

/// 搜索工具类型枚举
enum SearchToolType { tavily, serpapi, serper }

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
