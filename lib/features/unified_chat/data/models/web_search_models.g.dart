// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web_search_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchResultItem _$SearchResultItemFromJson(Map<String, dynamic> json) =>
    SearchResultItem(
      title: json['title'] as String?,
      url: json['url'] as String?,
      content: json['content'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      favicon: json['favicon'] as String?,
      publishedDate: json['publishedDate'] as String?,
    );

Map<String, dynamic> _$SearchResultItemToJson(SearchResultItem instance) =>
    <String, dynamic>{
      'title': instance.title,
      'url': instance.url,
      'content': instance.content,
      'score': instance.score,
      'favicon': instance.favicon,
      'publishedDate': instance.publishedDate,
    };

TavilySearchRequest _$TavilySearchRequestFromJson(Map<String, dynamic> json) =>
    TavilySearchRequest(
      query: json['query'] as String,
      searchDepth: json['search_depth'] as String? ?? 'basic',
      includeAnswer: json['include_answer'] as bool? ?? true,
      includeRawContent: json['include_raw_content'] as bool? ?? false,
      maxResults: (json['max_results'] as num?)?.toInt() ?? 20,
      topic: json['topic'] as String? ?? 'general',
      includeDomains: (json['include_domains'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      excludeDomains: (json['exclude_domains'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$TavilySearchRequestToJson(
  TavilySearchRequest instance,
) => <String, dynamic>{
  'query': instance.query,
  'search_depth': instance.searchDepth,
  'include_answer': instance.includeAnswer,
  'include_raw_content': instance.includeRawContent,
  'max_results': instance.maxResults,
  'topic': instance.topic,
  'include_domains': instance.includeDomains,
  'exclude_domains': instance.excludeDomains,
};

TavilySearchResponse _$TavilySearchResponseFromJson(
  Map<String, dynamic> json,
) => TavilySearchResponse(
  query: json['query'] as String?,
  answer: json['answer'] as String?,
  results: (json['results'] as List<dynamic>?)
      ?.map((e) => SearchResultItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  responseTime: (json['response_time'] as num?)?.toDouble(),
  images: (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
  autoParameters: json['auto_parameters'] as Map<String, dynamic>?,
  requestId: json['request_id'] as String?,
);

Map<String, dynamic> _$TavilySearchResponseToJson(
  TavilySearchResponse instance,
) => <String, dynamic>{
  'query': instance.query,
  'results': instance.results?.map((e) => e.toJson()).toList(),
  'answer': instance.answer,
  'response_time': instance.responseTime,
  'images': instance.images,
  'auto_parameters': instance.autoParameters,
  'request_id': instance.requestId,
};

SerpApiSearchRequest _$SerpApiSearchRequestFromJson(
  Map<String, dynamic> json,
) => SerpApiSearchRequest(
  q: json['q'] as String,
  gl: json['gl'] as String? ?? 'cn',
  location: json['location'] as String?,
  hl: json['hl'] as String? ?? 'zh-cn',
  engine: json['engine'] as String? ?? 'google',
  noCache: json['no_cache'] as bool? ?? false,
  output: json['output'] as String? ?? 'json',
  num: (json['num'] as num?)?.toInt() ?? 40,
  start: (json['start'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$SerpApiSearchRequestToJson(
  SerpApiSearchRequest instance,
) => <String, dynamic>{
  'q': instance.q,
  'gl': instance.gl,
  'location': instance.location,
  'hl': instance.hl,
  'engine': instance.engine,
  'no_cache': instance.noCache,
  'output': instance.output,
  'num': instance.num,
  'start': instance.start,
};

SerpApiSearchResponse _$SerpApiSearchResponseFromJson(
  Map<String, dynamic> json,
) => SerpApiSearchResponse(
  query: json['query'] as String?,
  results: (json['results'] as List<dynamic>?)
      ?.map((e) => SearchResultItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  searchMetadata: json['search_metadata'] as Map<String, dynamic>?,
  searchParameters: json['search_parameters'] as Map<String, dynamic>?,
  searchInformation: json['search_information'] as Map<String, dynamic>?,
  organicResults: (json['organic_results'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList(),
  topStories: json['top_stories'] as List<dynamic>?,
  pagination: json['pagination'] as Map<String, dynamic>?,
  serpapiPagination: json['serpapi_pagination'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$SerpApiSearchResponseToJson(
  SerpApiSearchResponse instance,
) => <String, dynamic>{
  'query': instance.query,
  'results': instance.results?.map((e) => e.toJson()).toList(),
  'search_metadata': instance.searchMetadata,
  'search_parameters': instance.searchParameters,
  'search_information': instance.searchInformation,
  'organic_results': instance.organicResults,
  'top_stories': instance.topStories,
  'pagination': instance.pagination,
  'serpapi_pagination': instance.serpapiPagination,
};

SerperSearchRequest _$SerperSearchRequestFromJson(Map<String, dynamic> json) =>
    SerperSearchRequest(
      q: json['q'] as String,
      gl: json['gl'] as String? ?? 'cn',
      location: json['location'] as String?,
      hl: json['hl'] as String? ?? 'zh-cn',
      num: (json['num'] as num?)?.toInt() ?? 10,
      page: (json['page'] as num?)?.toInt() ?? 1,
      type: json['type'] as String? ?? 'search',
    );

Map<String, dynamic> _$SerperSearchRequestToJson(
  SerperSearchRequest instance,
) => <String, dynamic>{
  'q': instance.q,
  'gl': instance.gl,
  'location': instance.location,
  'hl': instance.hl,
  'num': instance.num,
  'page': instance.page,
  'type': instance.type,
};

SerperSearchResponse _$SerperSearchResponseFromJson(
  Map<String, dynamic> json,
) => SerperSearchResponse(
  query: json['query'] as String?,
  results: (json['results'] as List<dynamic>?)
      ?.map((e) => SearchResultItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  searchParameters: json['searchParameters'] as Map<String, dynamic>?,
  organic: (json['organic'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList(),
  credits: (json['credits'] as num?)?.toInt(),
  searchInformation: json['searchInformation'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$SerperSearchResponseToJson(
  SerperSearchResponse instance,
) => <String, dynamic>{
  'query': instance.query,
  'results': instance.results?.map((e) => e.toJson()).toList(),
  'searchParameters': instance.searchParameters,
  'searchInformation': instance.searchInformation,
  'organic': instance.organic,
  'credits': instance.credits,
};

BochaSearchRequest _$BochaSearchRequestFromJson(Map<String, dynamic> json) =>
    BochaSearchRequest(
      query: json['query'] as String,
      freshness: json['freshness'] as String? ?? 'noLimit',
      summary: json['summary'] as bool? ?? true,
      count: (json['count'] as num?)?.toInt() ?? 10,
      page: (json['page'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$BochaSearchRequestToJson(BochaSearchRequest instance) =>
    <String, dynamic>{
      'query': instance.query,
      'freshness': instance.freshness,
      'summary': instance.summary,
      'count': instance.count,
      'page': instance.page,
    };

BochaSearchResponse _$BochaSearchResponseFromJson(Map<String, dynamic> json) =>
    BochaSearchResponse(
      query: json['query'] as String?,
      results: (json['results'] as List<dynamic>?)
          ?.map((e) => SearchResultItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      data: json['data'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$BochaSearchResponseToJson(
  BochaSearchResponse instance,
) => <String, dynamic>{
  'query': instance.query,
  'results': instance.results?.map((e) => e.toJson()).toList(),
  'data': instance.data,
};

BaiduSearchRequest _$BaiduSearchRequestFromJson(Map<String, dynamic> json) =>
    BaiduSearchRequest(
      messages: (json['messages'] as List<dynamic>)
          .map((e) => BaiduSearchMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      edition: json['edition'] as String? ?? 'standard',
      searchSource: json['search_source'] as String? ?? 'baidu_search_v2',
      resourceTypeFilter: (json['resource_type_filter'] as List<dynamic>)
          .map(
            (e) =>
                BaiduSearchResourceFilter.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      searchRecencyFilter: json['search_recency_filter'] as String?,
    );

Map<String, dynamic> _$BaiduSearchRequestToJson(BaiduSearchRequest instance) =>
    <String, dynamic>{
      'messages': instance.messages.map((e) => e.toJson()).toList(),
      'edition': instance.edition,
      'search_source': instance.searchSource,
      'resource_type_filter': instance.resourceTypeFilter
          .map((e) => e.toJson())
          .toList(),
      'search_recency_filter': instance.searchRecencyFilter,
    };

BaiduSearchMessage _$BaiduSearchMessageFromJson(Map<String, dynamic> json) =>
    BaiduSearchMessage(
      role: json['role'] as String,
      content: json['content'] as String,
    );

Map<String, dynamic> _$BaiduSearchMessageToJson(BaiduSearchMessage instance) =>
    <String, dynamic>{'role': instance.role, 'content': instance.content};

BaiduSearchResourceFilter _$BaiduSearchResourceFilterFromJson(
  Map<String, dynamic> json,
) => BaiduSearchResourceFilter(
  type: json['type'] as String,
  topK: (json['top_k'] as num).toInt(),
);

Map<String, dynamic> _$BaiduSearchResourceFilterToJson(
  BaiduSearchResourceFilter instance,
) => <String, dynamic>{'type': instance.type, 'top_k': instance.topK};

BaiduSearchResponse _$BaiduSearchResponseFromJson(Map<String, dynamic> json) =>
    BaiduSearchResponse(
      query: json['query'] as String?,
      results: (json['results'] as List<dynamic>?)
          ?.map((e) => SearchResultItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      answer: json['answer'] as String?,
      references: (json['references'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
    );

Map<String, dynamic> _$BaiduSearchResponseToJson(
  BaiduSearchResponse instance,
) => <String, dynamic>{
  'query': instance.query,
  'results': instance.results?.map((e) => e.toJson()).toList(),
  'answer': instance.answer,
  'references': instance.references,
};

UnifiedSearchResponse _$UnifiedSearchResponseFromJson(
  Map<String, dynamic> json,
) => UnifiedSearchResponse(
  query: json['query'] as String,
  toolType: $enumDecode(_$SearchToolTypeEnumMap, json['toolType']),
  results: (json['results'] as List<dynamic>)
      .map((e) => SearchResultItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  answer: json['answer'] as String?,
  responseTime: (json['responseTime'] as num).toDouble(),
  success: json['success'] as bool,
  error: json['error'] as String?,
  timestamp: DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$UnifiedSearchResponseToJson(
  UnifiedSearchResponse instance,
) => <String, dynamic>{
  'query': instance.query,
  'toolType': _$SearchToolTypeEnumMap[instance.toolType]!,
  'results': instance.results.map((e) => e.toJson()).toList(),
  'answer': instance.answer,
  'responseTime': instance.responseTime,
  'success': instance.success,
  'error': instance.error,
  'timestamp': instance.timestamp.toIso8601String(),
};

const _$SearchToolTypeEnumMap = {
  SearchToolType.bocha: 'bocha',
  SearchToolType.baidu: 'baidu',
  SearchToolType.tavily: 'tavily',
  SearchToolType.serpapi: 'serpapi',
  SearchToolType.serper: 'serper',
};
