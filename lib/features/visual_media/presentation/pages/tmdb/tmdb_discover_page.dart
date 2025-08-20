import 'package:flutter/material.dart';

import '../../../data/datasources/tmdb/tmdb_apis.dart';
import '../../../data/models/tmdb/tmdb_common.dart';
import '../../../data/models/tmdb/tmdb_filter_params.dart';
import '../../../data/models/tmdb/tmdb_result_resp.dart';
import '../../widgets/tmdb_widgets.dart';
import 'tmdb_detail_page.dart';
import 'tmdb_filter_sheet.dart';

/// TMDB 发现页面（高级筛选）
class TmdbDiscoverPage extends StatefulWidget {
  final String mediaType; // 'movie' 或 'tv'
  final String title;

  const TmdbDiscoverPage({
    super.key,
    required this.mediaType,
    required this.title,
  });

  @override
  State<TmdbDiscoverPage> createState() => _TmdbDiscoverPageState();
}

class _TmdbDiscoverPageState extends State<TmdbDiscoverPage> {
  final TmdbApiManager _apiManager = TmdbApiManager();
  final ScrollController _scrollController = ScrollController();

  // 数据状态
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  TmdbResultResp? _resultData;
  List<TmdbResultItem> _allResults = [];
  int _currentPage = 1;
  bool _hasMoreData = true;

  // 筛选参数
  late MovieFilterParams _movieParams;
  late TvFilterParams _tvParams;

  @override
  void initState() {
    super.initState();
    _initializeParams();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeParams() {
    _movieParams = MovieFilterParams();
    _tvParams = TvFilterParams();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreData();
    }
  }

  Future<void> _loadData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      _allResults.clear();
    });

    try {
      TmdbResultResp result;
      if (widget.mediaType == 'movie') {
        result = await _callMovieDiscoverApi(_movieParams.copyWith(page: 1));
      } else {
        result = await _callTvDiscoverApi(_tvParams.copyWith(page: 1));
      }

      if (!mounted) return;
      setState(() {
        _resultData = result;
        _allResults = result.results ?? [];
        _hasMoreData = (_currentPage < (result.totalPages ?? 1));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      rethrow;
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      TmdbResultResp result;

      if (widget.mediaType == 'movie') {
        result = await _callMovieDiscoverApi(
          _movieParams.copyWith(page: nextPage),
        );
      } else {
        result = await _callTvDiscoverApi(_tvParams.copyWith(page: nextPage));
      }
      if (!mounted) return;

      setState(() {
        _allResults.addAll(result.results ?? []);
        _currentPage = nextPage;
        _hasMoreData = (_currentPage < (result.totalPages ?? 1));
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载更多失败: ${e.toString()}')));
      }
    }
  }

  Future<TmdbResultResp> _callMovieDiscoverApi(MovieFilterParams params) async {
    final apiParams = params.toApiParams();

    return await _apiManager.getDiscoverMovie(
      language: apiParams['language'],
      sortBy: apiParams['sortBy'],
      page: apiParams['page'],
      includeAdult: apiParams['includeAdult'],
      includeVideo: apiParams['includeVideo'],
      region: apiParams['region'],
      certificationCountry: apiParams['certificationCountry'],
      certification: apiParams['certification'],
      certificationLessThan: apiParams['certificationLessThan'],
      certificationGreaterThan: apiParams['certificationGreaterThan'],
      primaryReleaseYear: apiParams['primaryReleaseYear'],
      primaryReleaseDateGreaterThan: apiParams['primaryReleaseDateGreaterThan'],
      primaryReleaseDateLessThan: apiParams['primaryReleaseDateLessThan'],
      releaseDateGreaterThan: apiParams['releaseDateGreaterThan'],
      releaseDateLessThan: apiParams['releaseDateLessThan'],
      withReleaseType: apiParams['withReleaseType'],
      year: apiParams['year'],
      voteCountGreaterThan: apiParams['voteCountGreaterThan'],
      voteCountLessThan: apiParams['voteCountLessThan'],
      voteAverageGreaterThan: apiParams['voteAverageGreaterThan'],
      voteAverageLessThan: apiParams['voteAverageLessThan'],
      withCast: apiParams['withCast'],
      withCrew: apiParams['withCrew'],
      withPeople: apiParams['withPeople'],
      withCompanies: apiParams['withCompanies'],
      withGenres: apiParams['withGenres'],
      withoutGenres: apiParams['withoutGenres'],
      withKeywords: apiParams['withKeywords'],
      withoutKeywords: apiParams['withoutKeywords'],
      withRunTimeGreaterThan: apiParams['withRunTimeGreaterThan'],
      withRuntimeLessThan: apiParams['withRuntimeLessThan'],
      withOrginalLanguage: apiParams['withOrginalLanguage'],
      withOriginCountry: apiParams['withOriginCountry'],
      withWatchProviders: apiParams['withWatchProviders'],
      withoutWatchProviders: apiParams['withoutWatchProviders'],
      watchRegion: apiParams['watchRegion'],
      withWatchMonetizationTypes: apiParams['withWatchMonetizationTypes'],
      withoutCompanies: apiParams['withoutCompanies'],
    );
  }

  Future<TmdbResultResp> _callTvDiscoverApi(TvFilterParams params) async {
    final apiParams = params.toApiParams();

    return await _apiManager.getDiscoverTv(
      language: apiParams['language'],
      sortBy: apiParams['sortBy'],
      page: apiParams['page'],
      includeAdult: apiParams['includeAdult'],
      includeNullFirstAirDates: apiParams['includeNullFirstAirDates'],
      airDateGte: apiParams['airDateGte'],
      airDateLte: apiParams['airDateLte'],
      firstAirDateGte: apiParams['firstAirDateGte'],
      firstAirDateLte: apiParams['firstAirDateLte'],
      firstAirDateYear: apiParams['firstAirDateYear'],
      timezone: apiParams['timezone'],
      voteAverageGte: apiParams['voteAverageGte'],
      voteAverageLte: apiParams['voteAverageLte'],
      voteCountGte: apiParams['voteCountGte'],
      voteCountLte: apiParams['voteCountLte'],
      withGenres: apiParams['withGenres'],
      withoutGenres: apiParams['withoutGenres'],
      withNetworks: apiParams['withNetworks'],
      withRuntimeGte: apiParams['withRuntimeGte'],
      withRuntimeLte: apiParams['withRuntimeLte'],
      withOrginalLanguage: apiParams['withOrginalLanguage'],
      withOriginCountry: apiParams['withOriginCountry'],
      withKeywords: apiParams['withKeywords'],
      withoutKeywords: apiParams['withoutKeywords'],
      screenedTheatrically: apiParams['screenedTheatrically'],
      withCompanies: apiParams['withCompanies'],
      withWatchProviders: apiParams['withWatchProviders'],
      withoutWatchProviders: apiParams['withoutWatchProviders'],
      watchRegion: apiParams['watchRegion'],
      withWatchMonetizationTypes: apiParams['withWatchMonetizationTypes'],
      withoutCompanies: apiParams['withoutCompanies'],
      withStatus: apiParams['withStatus'],
      withType: apiParams['withType'],
    );
  }

  void _navigateToDetail(TmdbResultItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TmdbDetailPage(
          item: item,
          mediaType: item.mediaType ?? widget.mediaType,
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TmdbFilterSheet(
        mediaType: widget.mediaType,
        movieParams: _movieParams,
        tvParams: _tvParams,
        onApplyFilter: (movieParams, tvParams) {
          setState(() {
            _movieParams = movieParams;
            _tvParams = tvParams;
            _currentPage = 1;
            _allResults.clear();
          });
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFilterSheet,
            tooltip: '高级筛选',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('加载失败: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_allResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('暂无${widget.mediaType == 'movie' ? '电影' : '剧集'}数据'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('刷新')),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 结果统计
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '已加载 ${_allResults.length} 个, 共找到 ${_resultData?.totalResults ?? 0} 个结果',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _showFilterSheet,
                icon: const Icon(Icons.tune, size: 16),
                label: const Text('筛选'),
              ),
            ],
          ),
        ),
        // 结果列表
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _allResults.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _allResults.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final item = _allResults[index];
              return TmdbItemCard(
                item: item,
                onTap: () => _navigateToDetail(item),
              );
            },
          ),
        ),
      ],
    );
  }
}
