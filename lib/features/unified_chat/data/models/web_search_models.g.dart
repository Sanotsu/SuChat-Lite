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
  SearchToolType.tavily: 'tavily',
  SearchToolType.serpapi: 'serpapi',
  SearchToolType.serper: 'serper',
};
