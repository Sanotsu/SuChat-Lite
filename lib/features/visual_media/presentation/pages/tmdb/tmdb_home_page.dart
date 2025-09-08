import 'package:flutter/material.dart';
import 'package:tmdb_api/tmdb_api.dart';

import '../../../../../shared/widgets/simple_tool_widget.dart';
import '../../../../../shared/widgets/common_error_empty_widgets.dart';
import '../../../data/datasources/tmdb/tmdb_apis.dart';
import '../../../data/models/tmdb/tmdb_common.dart';
import '../../../data/models/tmdb/tmdb_result_resp.dart';
import '../../widgets/tmdb_widgets.dart';
import 'tmdb_detail_page.dart';
import 'tmdb_discover_page.dart';
import 'tmdb_search_page.dart';

/// TMDB 电影电视剧集主页
class TmdbHomePage extends StatefulWidget {
  const TmdbHomePage({super.key});

  @override
  State<TmdbHomePage> createState() => _TmdbHomePageState();
}

class _TmdbHomePageState extends State<TmdbHomePage>
    with SingleTickerProviderStateMixin {
  final TmdbApiManager _apiManager = TmdbApiManager();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 搜索相关 - 已移除，直接跳转到搜索页面

  // 数据状态
  bool _isLoading = false;
  String? _error;

  // 各模块数据
  TmdbResultResp? _trendingData;
  TmdbResultResp? _movieNowPlayingData;
  TmdbResultResp? _movieUpcomingData;
  TmdbResultResp? _moviePopularData;
  TmdbResultResp? _movieTopRatedData;
  TmdbResultResp? _tvAiringTodayData;
  TmdbResultResp? _tvOnTheAirData;
  TmdbResultResp? _tvPopularData;
  TmdbResultResp? _tvTopRatedData;
  TmdbResultResp? _personPopularData;

  // 当前选择的标签
  TimeWindow _selectedTimeWindow = TimeWindow.day;
  String _selectedMovieCategory = 'now_playing';
  String _selectedTvCategory = 'airing_today';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 加载初始数据
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final futures = await Future.wait([
        _apiManager.getTrending(timeWindow: _selectedTimeWindow),
        _apiManager.getMovieNowPlaying(),
        _apiManager.getTvAiringToday(),
        _apiManager.getPersonPopular(),
      ]);

      if (!mounted) return;
      setState(() {
        _trendingData = futures[0];
        _movieNowPlayingData = futures[1];
        _tvAiringTodayData = futures[2];
        _personPopularData = futures[3];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 搜索功能 - 跳转到搜索页面
  void _performSearch(String query) {
    unfocusHandle();

    if (query.trim().isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TmdbSearchPage(initialQuery: query),
      ),
    );

    // 清空搜索框
    _searchController.clear();
  }

  /// 切换趋势时间窗口
  Future<void> _changeTrendingTimeWindow(TimeWindow timeWindow) async {
    if (_selectedTimeWindow == timeWindow) return;

    setState(() {
      _selectedTimeWindow = timeWindow;
      _isLoading = true;
    });

    try {
      final data = await _apiManager.getTrending(timeWindow: timeWindow);
      if (!mounted) return;
      setState(() {
        _trendingData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 切换电影分类
  Future<void> _changeMovieCategory(String category) async {
    if (_selectedMovieCategory == category) return;

    setState(() {
      _selectedMovieCategory = category;
      _isLoading = true;
    });

    try {
      TmdbResultResp data;
      switch (category) {
        case 'now_playing':
          data = await _apiManager.getMovieNowPlaying();
          _movieNowPlayingData = data;
          break;
        case 'upcoming':
          data = await _apiManager.getMovieUpcoming();
          _movieUpcomingData = data;
          break;
        case 'popular':
          data = await _apiManager.getMoviePopular();
          _moviePopularData = data;
          break;
        case 'top_rated':
          data = await _apiManager.getMovieTopRated();
          _movieTopRatedData = data;
          break;
        default:
          data = await _apiManager.getMovieNowPlaying();
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 切换剧集分类
  Future<void> _changeTvCategory(String category) async {
    if (_selectedTvCategory == category) return;

    setState(() {
      _selectedTvCategory = category;
      _isLoading = true;
    });

    try {
      TmdbResultResp data;
      switch (category) {
        case 'airing_today':
          data = await _apiManager.getTvAiringToday();
          _tvAiringTodayData = data;
          break;
        case 'on_the_air':
          data = await _apiManager.getTvOnTheAir();
          _tvOnTheAirData = data;
          break;
        case 'popular':
          data = await _apiManager.getTvPopular();
          _tvPopularData = data;
          break;
        case 'top_rated':
          data = await _apiManager.getTvTopRated();
          _tvTopRatedData = data;
          break;
        default:
          data = await _apiManager.getTvAiringToday();
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 获取当前电影数据
  TmdbResultResp? _getCurrentMovieData() {
    switch (_selectedMovieCategory) {
      case 'now_playing':
        return _movieNowPlayingData;
      case 'upcoming':
        return _movieUpcomingData;
      case 'popular':
        return _moviePopularData;
      case 'top_rated':
        return _movieTopRatedData;
      default:
        return _movieNowPlayingData;
    }
  }

  /// 获取当前剧集数据
  TmdbResultResp? _getCurrentTvData() {
    switch (_selectedTvCategory) {
      case 'airing_today':
        return _tvAiringTodayData;
      case 'on_the_air':
        return _tvOnTheAirData;
      case 'popular':
        return _tvPopularData;
      case 'top_rated':
        return _tvTopRatedData;
      default:
        return _tvAiringTodayData;
    }
  }

  /// 导航到详情页
  /// 注意，查询趋势时时所有类型混在一起，item中有mediaType字段。
  /// 但单独查询电影、剧集、人员时，item中没有mediaType字段，
  ///     所以跳转详情页时需要手动指定mediaType
  void _navigateToDetail(TmdbResultItem item, {String? mediaType}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TmdbDetailPage(
          item: item,
          mediaType: mediaType ?? item.mediaType ?? 'movie',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TMDB'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'search':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TmdbSearchPage(initialQuery: _searchController.text),
                    ),
                  );
                  break;
                case 'discover_movies':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TmdbDiscoverPage(
                        mediaType: 'movie',
                        title: '电影筛选',
                      ),
                    ),
                  );
                  break;
                case 'discover_tv':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TmdbDiscoverPage(
                        mediaType: 'tv',
                        title: '剧集筛选',
                      ),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'search',
                child: ListTile(
                  leading: Icon(Icons.search),
                  title: Text('更多搜索'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'discover_movies',
                child: ListTile(
                  leading: Icon(Icons.movie),
                  title: Text('电影筛选'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'discover_tv',
                child: ListTile(
                  leading: Icon(Icons.tv),
                  title: Text('剧集筛选'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          buildInfoButtonOnAction(
            context,
            "数据来源: [tmdb](https://www.themoviedb.org/)\n\n国外的API，需要科学上网才能正常访问。",
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索区域
          _buildSearchArea(),
          // 内容区域
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? buildCommonErrorWidget(
                    error: _error,
                    onRetry: _loadInitialData,
                  )
                : _buildHomeContent(),
          ),
        ],
      ),
    );
  }

  /// 构建搜索区域
  Widget _buildSearchArea() {
    return Container(
      padding: EdgeInsets.only(left: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索电影、剧集、人员...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                // prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onSubmitted: _performSearch,
              onChanged: (value) {
                if (value.isEmpty) {
                  _performSearch('');
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => _performSearch(_searchController.text),
            icon: const Icon(Icons.search, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// 构建主页内容
  Widget _buildHomeContent() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // 趋势模块
          TmdbSectionWidget(
            title: '趋势',
            items: _trendingData?.results ?? [],
            onItemTap: _navigateToDetail,
            headerActions: [_buildTimeWindowChips()],
          ),
          const SizedBox(height: 24),
          // 电影模块
          TmdbSectionWidget(
            title: '电影',
            items: _getCurrentMovieData()?.results ?? [],
            onItemTap: (item) => _navigateToDetail(item, mediaType: 'movie'),
            headerActions: [_buildMovieCategoryChips()],
          ),
          const SizedBox(height: 24),
          // 剧集模块
          TmdbSectionWidget(
            title: '剧集',
            items: _getCurrentTvData()?.results ?? [],
            onItemTap: (item) => _navigateToDetail(item, mediaType: 'tv'),
            headerActions: [_buildTvCategoryChips()],
          ),
          const SizedBox(height: 24),
          // 人员模块
          TmdbSectionWidget(
            title: '人员',
            items: _personPopularData?.results ?? [],
            onItemTap: (item) => _navigateToDetail(item, mediaType: 'person'),
            headerActions: [_buildPersonCategoryChips()],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// 构建时间窗口选择器
  Widget _buildTimeWindowChips() {
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChip(
              label: '今日',
              isSelected: _selectedTimeWindow == TimeWindow.day,
              onTap: () => _changeTrendingTimeWindow(TimeWindow.day),
            ),
            const SizedBox(width: 8),
            _buildChip(
              label: '本周',
              isSelected: _selectedTimeWindow == TimeWindow.week,
              onTap: () => _changeTrendingTimeWindow(TimeWindow.week),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建电影分类选择器
  Widget _buildMovieCategoryChips() {
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChip(
              label: '正在上映',
              isSelected: _selectedMovieCategory == 'now_playing',
              onTap: () => _changeMovieCategory('now_playing'),
            ),
            const SizedBox(width: 8),
            _buildChip(
              label: '即将上映',
              isSelected: _selectedMovieCategory == 'upcoming',
              onTap: () => _changeMovieCategory('upcoming'),
            ),
            const SizedBox(width: 8),
            _buildChip(
              label: '热门',
              isSelected: _selectedMovieCategory == 'popular',
              onTap: () => _changeMovieCategory('popular'),
            ),
            const SizedBox(width: 8),
            _buildChip(
              label: '高分',
              isSelected: _selectedMovieCategory == 'top_rated',
              onTap: () => _changeMovieCategory('top_rated'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建剧集分类选择器
  Widget _buildTvCategoryChips() {
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChip(
              label: '正在热播',
              isSelected: _selectedTvCategory == 'airing_today',
              onTap: () => _changeTvCategory('airing_today'),
            ),
            const SizedBox(width: 8),
            _buildChip(
              label: '即将播出',
              isSelected: _selectedTvCategory == 'on_the_air',
              onTap: () => _changeTvCategory('on_the_air'),
            ),
            const SizedBox(width: 8),
            _buildChip(
              label: '热门',
              isSelected: _selectedTvCategory == 'popular',
              onTap: () => _changeTvCategory('popular'),
            ),
            const SizedBox(width: 8),
            _buildChip(
              label: '高分',
              isSelected: _selectedTvCategory == 'top_rated',
              onTap: () => _changeTvCategory('top_rated'),
            ),
          ],
        ),
      ),
    );
  }

  /// 人员只有一个热门，只显示标签，不用切换
  /// 构建剧集分类选择器
  Widget _buildPersonCategoryChips() {
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChip(label: '热门', isSelected: true, onTap: () => {}),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  /// 构建选择芯片
  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
