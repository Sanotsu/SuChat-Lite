import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../shared/constants/constants.dart';
import '../../../../../shared/widgets/common_error_empty_widgets.dart';
import '../../../../../shared/widgets/simple_tool_widget.dart';
import '../../../data/datasources/one_api_manager.dart';
import '../../../data/models/one/one_base_models.dart';
import '../../../data/models/one/one_category_list.dart';
import '../../../data/models/one/one_enums.dart';
import '../../widgets/one/content_card.dart';
import 'category_pages/author_detail_page.dart';
import 'detail_page.dart';

/// One搜索页面
class OneSearchPage extends StatefulWidget {
  final String? initialQuery;

  const OneSearchPage({super.key, this.initialQuery});

  @override
  State<OneSearchPage> createState() => _OneSearchPageState();
}

class _OneSearchPageState extends State<OneSearchPage> {
  final OneApiManager _apiManager = OneApiManager();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 数据状态
  bool _isLoading = false;
  String? _error;
  List<OneContent> _searchResults = [];

  // 搜索配置
  String _selectedCategory = 'reading'; // 默认阅读
  int _currentPage = 0;
  bool _hasMore = true;

  // 分类配置
  final List<Map<String, dynamic>> _searchCategories = [
    {'key': 'hp', 'name': '图文', 'icon': Icons.image},
    {'key': 'reading', 'name': '阅读', 'icon': Icons.book},
    {'key': 'music', 'name': '音乐', 'icon': Icons.music_note},
    {'key': 'movie', 'name': '影视', 'icon': Icons.movie},
    {'key': 'radio', 'name': '电台', 'icon': Icons.radio},
    {'key': 'author', 'name': '作者', 'icon': Icons.person},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _performSearch();
    }
    _setupScrollListener();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 设置滚动监听器
  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoading && _hasMore) {
          _loadMoreResults();
        }
      }
    });
  }

  /// 执行搜索
  Future<void> _performSearch() async {
    unfocusHandle();

    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _searchResults.clear();
      _currentPage = 0;
      _hasMore = true;
    });

    try {
      final results = await _apiManager.getOneSearchList(
        categoryName: _selectedCategory,
        keyword: _searchController.text.trim(),
        page: _currentPage,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          // 搜索结果没有固定分页，直接页码++查询下一页
          _hasMore = results.isNotEmpty;
          _currentPage++;
          _isLoading = false;
        });
      }

      // 搜索完成后检查是否需要加载更多
      // (处理当查询结果太少不足1屏时，加载圈一直存在。又因为不足一屏无法滚动加载更多导致无法消除的问题)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkIfNeedLoadMore();
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }

      rethrow;
    }
  }

  /// 加载更多结果
  Future<void> _loadMoreResults() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _apiManager.getOneSearchList(
        categoryName: _selectedCategory,
        keyword: _searchController.text.trim(),
        page: _currentPage,
      );

      if (mounted) {
        setState(() {
          _searchResults.addAll(results);
          _hasMore = results.isNotEmpty;
          _currentPage++;
          _isLoading = false;
        });
      }

      // 搜索完成后检查是否需要加载更多
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkIfNeedLoadMore();
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// 检查是否需要自动加载更多
  /// 有些搜索结果很少，不足一屏高度，无法滚动加载更多，导加载圈一直存在无法清楚
  /// 所以查询数据之后，当内容不足一屏时，自动加载更多，触发_hasMore=false逻辑，就不显示加载圈了
  void _checkIfNeedLoadMore() {
    if (!mounted || _isLoading || !_hasMore) return;

    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final viewportHeight = _scrollController.position.viewportDimension;

      // 如果内容高度小于视图高度，说明内容不足一屏
      if (maxScroll <= viewportHeight && _searchResults.isNotEmpty) {
        _loadMoreResults();
      }
    }
  }

  /// 切换搜索分类
  void _changeCategory(String category) {
    if (_selectedCategory == category) return;

    setState(() {
      _selectedCategory = category;
    });

    if (_searchController.text.trim().isNotEmpty) {
      _performSearch();
    }
  }

  /// 导航到详情页
  void _navigateToDetail(OneContent content) {
    final category = (content.category ?? '1').toString();
    final apiCategory = OneCategory.getApiName(category);

    // 这里查询结果中，内容编号只有content_id
    var contentId = (content.contentId ?? '').toString();
    // 如果分类是图片hp，内容需要按日期查询
    if (apiCategory == "hp") {
      contentId = DateFormat(
        formatToYMD,
      ).format(DateTime.parse(content.date ?? ''));
    }

    // 注意，如果查询的是作者，那这里应该跳转到作者详情页面
    // 又因为作者详情页面需要传入OneAuthor，所以要手动构建一个
    if (apiCategory == "author") {
      OneAuthor author = OneAuthor(
        userId: (content.contentId ?? '4809091').toString(),
        userName: content.title,
        webUrl: content.cover,
        desc: content.subtitle,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AuthorDetailPage(author: author),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OneDetailPage(
          contentType: apiCategory,
          contentId: contentId,
          title: content.title ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('搜索'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 搜索区域
          _buildSearchArea(),
          // 分类选择
          _buildCategorySelector(),
          // 搜索结果
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  /// 构建搜索区域
  Widget _buildSearchArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索内容、作者...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults.clear();
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _performSearch(),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: _performSearch,
            icon: const Icon(Icons.search, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// 构建分类选择器
  Widget _buildCategorySelector() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _searchCategories.length,
        itemBuilder: (context, index) {
          final category = _searchCategories[index];
          final isSelected = _selectedCategory == category['key'];

          return GestureDetector(
            onTap: () => _changeCategory(category['key']),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category['icon'],
                    size: 16,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category['name'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建搜索结果
  Widget _buildSearchResults() {
    if (_searchController.text.trim().isEmpty) {
      return _buildSearchSuggestions();
    }

    if (_isLoading && _searchResults.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return buildCommonErrorWidget(error: _error, onRetry: _performSearch);
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '没有找到相关内容',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      // itemCount: _searchResults.length + (_hasMore ? 1 : 0),
      itemCount: _searchResults.length + 1,
      itemBuilder: (context, index) {
        if (index == _searchResults.length) {
          if (_hasMore) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          } else {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text("没有更多内容了", style: TextStyle(color: Colors.grey)),
              ),
            );
          }
        }

        final content = _searchResults[index];
        return OneContentCard(
          content: content,
          onTap: () => _navigateToDetail(content),
        );
      },
    );
  }

  /// 构建搜索建议
  Widget _buildSearchSuggestions() {
    final suggestions = [
      '韩寒',
      '爱情',
      '生活',
      '青春',
      '梦想',
      '旅行',
      '音乐',
      '电影',
      '文学',
      '哲学',
      '心理',
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '热门搜索',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: suggestions
                .map(
                  (suggestion) => GestureDetector(
                    onTap: () {
                      _searchController.text = suggestion;
                      _performSearch();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        suggestion,
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 32),
          const Text(
            '搜索提示',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            '• 可以搜索文章标题、作者名称\n'
            '• 支持模糊搜索，输入关键词即可\n'
            '• 切换不同分类获得更精准的结果',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
