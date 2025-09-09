import 'package:flutter/material.dart';
import 'package:tmdb_api/tmdb_api.dart';

import '../../../../../shared/widgets/simple_tool_widget.dart';
import '../../../data/datasources/tmdb/tmdb_apis.dart';
import '../../../data/models/tmdb/tmdb_common.dart';
import '../../../data/models/tmdb/tmdb_result_resp.dart';
import '../../widgets/tmdb/base_widgets.dart';
import 'detail_page.dart';

/// TMDB 搜索页面
class TmdbSearchPage extends StatefulWidget {
  final String? initialQuery;

  const TmdbSearchPage({super.key, this.initialQuery});

  @override
  State<TmdbSearchPage> createState() => _TmdbSearchPageState();
}

class _TmdbSearchPageState extends State<TmdbSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final List<TmdbResultItem> _searchResults = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String _currentQuery = '';
  String? _errorMessage;
  MediaType _currentMediaType = MediaType.all;

  // 查询结果响应（虽然初始查询、加载更多等情况会更新它，但总条数在每次分页查询时应该是一样的）
  TmdbResultResp? _queryResponse;

  // 搜索历史(TODO,目前是示例，有需要放到缓存中试试)
  final List<String> _searchHistory = [];

  // 热门搜索建议(TODO，也是示例，但可以把趋势的数据当作热门搜索放进来)
  final List<String> _popularSearches = [
    '肖申克的救赎',
    '教父',
    '星际穿越',
    '复仇者联盟',
    '生活大爆炸',
    '盗梦空间',
    '权力的游戏',
    '泰坦尼克号',
    '阿甘正传',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery ?? '';
    if (widget.initialQuery?.isNotEmpty ?? false) {
      _currentQuery = widget.initialQuery!;
      _performSearch();
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动监听
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  /// 执行搜索
  void _performSearch({bool isNewSearch = true, MediaType? mediaType}) async {
    unfocusHandle();

    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    if (isNewSearch) {
      setState(() {
        _currentQuery = query;
        _currentPage = 1;
        _searchResults.clear();
        _hasMore = true;
        _errorMessage = null;
        if (mediaType != null) {
          _currentMediaType = mediaType;
        }
      });

      // 添加到搜索历史
      if (!_searchHistory.contains(query)) {
        _searchHistory.insert(0, query);
        if (_searchHistory.length > 10) {
          _searchHistory.removeLast();
        }
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiManager = TmdbApiManager();
      final response = await apiManager.search(
        query,
        page: _currentPage,
        language: 'zh-CN',
        mediaType: _currentMediaType,
      );

      if (mounted) {
        setState(() {
          _queryResponse = response;

          _isLoading = false;
          if (response.results?.isNotEmpty ?? false) {
            _searchResults.addAll(response.results!);
            _hasMore = _currentPage < (response.totalPages ?? 0);
          } else {
            _hasMore = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '搜索失败: $e';
        });
      }
    }
  }

  /// 加载更多
  void _loadMore() {
    if (_isLoading || !_hasMore || _currentQuery.isEmpty) return;

    _currentPage++;
    _performSearch(isNewSearch: false);
  }

  /// 清除搜索
  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults.clear();
      _currentQuery = '';
      _errorMessage = null;
      _hasMore = true;
      _currentPage = 1;
      _currentMediaType = MediaType.all;
    });
  }

  /// 构建分类芯片
  Widget _buildCategoryChip(String label, MediaType mediaType) {
    final isSelected = _currentMediaType == mediaType;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.black.withValues(alpha: 0.9),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected && _currentQuery.isNotEmpty) {
          _performSearch(mediaType: mediaType);
        }
      },
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      selectedColor: Colors.white,
      checkmarkColor: Theme.of(context).primaryColor,
      side: BorderSide(
        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3),
        width: 1,
      ),
    );
  }

  /// 获取媒体类型标签
  String _getMediaTypeLabel(MediaType mediaType) {
    switch (mediaType) {
      case MediaType.movie:
        return '电影';
      case MediaType.tv:
        return '剧集';
      case MediaType.person:
        return '人物';
      case MediaType.all:
        return '全部';
    }
  }

  /// 选择搜索建议
  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    _performSearch();
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('TMDB 搜索'),
      //   backgroundColor: Theme.of(context).primaryColor,
      //   foregroundColor: Colors.white,
      //   elevation: 0,
      // ),
      body: Column(
        children: [
          // 搜索区域 - 与首页保持一致的风格
          _buildSearchArea(),

          // 放在外面不怎么好看，还是放在搜索中
          // if (_currentQuery.isNotEmpty) ...[
          //   const SizedBox(height: 16),
          //   _buildFilterArea(),
          // ],

          // 内容区域
          Expanded(
            child: _currentQuery.isEmpty
                ? _buildSuggestions()
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  /// 构建搜索区域 - 与首页保持一致，多了分类筛选
  Widget _buildSearchArea() {
    return Container(
      // 如果不要appbar的话，边框这样设置
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 8,
      ),

      /// 有appbar，则这样
      // padding: EdgeInsets.only(left: 16, right: 16, bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 有appbar则不需要单独的返回按钮，且需要单独的搜索按钮
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: '搜索电影、剧集、人员...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    // prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: _clearSearch,
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
                  onSubmitted: (value) => _performSearch(),
                  onChanged: (value) {
                    setState(() {}); // 更新清除按钮显示
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => _performSearch(),
                icon: const Icon(Icons.search, color: Colors.white, size: 28),
              ),
            ],
          ),

          // 分类筛选芯片
          if (_currentQuery.isNotEmpty) _buildFilterArea(),

          // if (_currentQuery.isNotEmpty) ...[
          // const SizedBox(height: 8),
          // SingleChildScrollView(
          //   scrollDirection: Axis.horizontal,
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       _buildCategoryChip('全部', MediaType.all),
          //       const SizedBox(width: 8),
          //       _buildCategoryChip('电影', MediaType.movie),
          //       const SizedBox(width: 8),
          //       _buildCategoryChip('剧集', MediaType.tv),
          //       const SizedBox(width: 8),
          //       _buildCategoryChip('人物', MediaType.person),
          //     ],
          //   ),
          // ),
          // ],
        ],
      ),
    );
  }

  Container _buildFilterArea() {
    return Container(
      padding: EdgeInsets.only(top: 8),
      width: double.infinity,
      decoration: BoxDecoration(color: Theme.of(context).primaryColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCategoryChip('全部', MediaType.all),
          const SizedBox(width: 8),
          _buildCategoryChip('电影', MediaType.movie),
          const SizedBox(width: 8),
          _buildCategoryChip('剧集', MediaType.tv),
          const SizedBox(width: 8),
          _buildCategoryChip('人物', MediaType.person),
        ],
      ),
    );
  }

  /// 构建搜索建议
  Widget _buildSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 搜索历史
          if (_searchHistory.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '本次搜索历史',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _searchHistory.clear();
                    });
                  },
                  child: const Text('清除'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _searchHistory.map((query) {
                return InputChip(
                  label: Text(query),
                  onPressed: () => _selectSuggestion(query),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _searchHistory.remove(query);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          // 热门搜索
          const Text(
            '热门搜索(伪)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularSearches.map((query) {
              return ActionChip(
                label: Text(query),
                onPressed: () => _selectSuggestion(query),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 构建搜索结果
  Widget _buildSearchResults() {
    if (_errorMessage != null) {
      return TmdbEmptyWidget(
        message: _errorMessage!,
        icon: Icons.error_outline,
        onRetry: () => _performSearch(),
      );
    }

    if (_isLoading && _searchResults.isEmpty) {
      return const TmdbLoadingWidget(message: '搜索中...');
    }

    if (_searchResults.isEmpty && !_isLoading) {
      return TmdbEmptyWidget(
        message: '未找到相关结果',
        icon: Icons.search_off,
        onRetry: () => _performSearch(),
      );
    }

    return Column(
      children: [
        // 结果统计
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                '当前 ${_searchResults.length} 个结果, 共 ${_queryResponse?.totalResults} 个',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const Spacer(),
              Text(
                '当前类型: ${_getMediaTypeLabel(_currentMediaType)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
        // 搜索结果列表
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _searchResults.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _searchResults.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final item = _searchResults[index];
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

  /// 导航到详情页
  void _navigateToDetail(TmdbResultItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TmdbDetailPage(
          item: item,
          mediaType: item.mediaType ?? _currentMediaType.name,
        ),
      ),
    );
  }
}
