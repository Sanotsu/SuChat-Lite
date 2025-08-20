import 'package:flutter/material.dart';
import 'package:suchat_lite/shared/widgets/simple_tool_widget.dart';
import '../../../../../shared/widgets/image_preview_helper.dart';
import '../../../../../shared/widgets/toast_utils.dart';
import '../../../data/datasources/douguo/douguo_api_manager.dart';
import '../../../data/models/douguo/douguo_recommended_resp.dart';
import 'recipe_detail_page.dart';

/// 食谱主页
/// 默认显示推荐菜谱，支持搜索功能
class RecipeHomePage extends StatefulWidget {
  const RecipeHomePage({super.key});

  @override
  State<RecipeHomePage> createState() => _RecipeHomePageState();
}

class _RecipeHomePageState extends State<RecipeHomePage>
    with SingleTickerProviderStateMixin {
  final DouguoApiManager _apiManager = DouguoApiManager();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _secondaryKeywordController =
      TextEditingController();

  // 数据状态
  List<DGRoughItem> _recipes = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  // 搜索状态
  bool _isSearchMode = false;
  String _currentKeyword = '';
  String _currentSecondaryKeyword = '';
  int _currentOrder = 0; // 0:综合排序 2:收藏最多 3:学做最多
  int _currentOffset = 0;

  // 动画控制器
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scrollController.addListener(_onScroll);
    _loadRecommendedRecipes();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _secondaryKeywordController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        if (_isSearchMode) {
          _loadMoreSearchResults();
        } else {
          _loadMoreRecommended();
        }
      }
    }
  }

  /// 加载推荐菜谱
  Future<void> _loadRecommendedRecipes() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiManager.getDouguoRecommendedList(
        offset: 0,
        limit: 20,
      );

      if (response.result?.list != null) {
        final items = response.result!.list!
            .where((item) => item.r != null)
            .map((item) => item.r!)
            .toList();

        setState(() {
          _recipes = items;
          _currentOffset = items.length;
          _isSearchMode = false;
        });

        _animationController.forward();
      }
    } catch (e) {
      setState(() {
        _error = '加载失败: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 加载更多推荐菜谱
  Future<void> _loadMoreRecommended() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiManager.getDouguoRecommendedList(
        offset: _currentOffset,
        limit: 20,
      );

      if (response.result?.list != null) {
        final items = response.result!.list!
            .where((item) => item.r != null)
            .map((item) => item.r!)
            .toList();

        setState(() {
          _recipes.addAll(items);
          _currentOffset += items.length;
          _hasMore = items.isNotEmpty;
        });
      }
    } catch (e) {
      ToastUtils.showError('加载更多推荐食谱失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 搜索菜谱
  Future<void> _searchRecipes() async {
    unfocusHandle();
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _currentKeyword = keyword;
      _currentSecondaryKeyword = _secondaryKeywordController.text.trim();
      _currentOffset = 0;
    });

    try {
      final response = await _apiManager.getDouguoSearchList(
        keyword: keyword,
        order: _currentOrder,
        secondaryKeyword: _currentSecondaryKeyword,
        offset: 0,
        limit: 20,
      );

      if (response.result?.list != null) {
        final items = response.result!.list!
            .where((item) => item.r != null)
            .map((item) => item.r!)
            .toList();

        setState(() {
          _recipes = items;
          _currentOffset = items.length;
          _isSearchMode = true;
          _hasMore = response.result!.end != 1;
        });

        _animationController.reset();
        _animationController.forward();
      }
    } catch (e) {
      setState(() {
        _error = '搜索失败: $e';
      });
      rethrow;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 加载更多搜索结果
  Future<void> _loadMoreSearchResults() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiManager.getDouguoSearchList(
        keyword: _currentKeyword,
        order: _currentOrder,
        secondaryKeyword: _currentSecondaryKeyword,
        offset: _currentOffset,
        limit: 20,
      );

      if (response.result?.list != null) {
        final items = response.result!.list!
            .where((item) => item.r != null)
            .map((item) => item.r!)
            .toList();

        setState(() {
          _recipes.addAll(items);
          _currentOffset += items.length;
          _hasMore = response.result!.end != 1;
        });
      }
    } catch (e) {
      ToastUtils.showError('加载更多搜索结果失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 清除搜索，返回推荐
  void _clearSearch() {
    _searchController.clear();
    _secondaryKeywordController.clear();
    setState(() {
      _currentOrder = 0;
    });
    _loadRecommendedRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 搜索区域
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: Colors.orange[400],
            foregroundColor: Colors.white,
            title: Text(
              _isSearchMode ? '搜索结果' : '推荐菜谱',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.orange[400]!, Colors.deepOrange[500]!],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 空出上面title的位置
                        const SizedBox(height: 48),

                        _buildSearchBar(),

                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "500万+美食菜谱",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "豆果美食，\t会做饭很酷！",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 搜索选项
          if (_isSearchMode) _buildSearchOptions(),

          // 菜谱列表
          if (_error != null)
            SliverToBoxAdapter(child: _buildErrorWidget())
          else if (_recipes.isEmpty && _isLoading)
            SliverToBoxAdapter(child: _buildLoadingWidget())
          else if (_recipes.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyWidget())
          else
            _buildRecipeGrid(),

          // 底部加载更多
          if (_isLoading && _recipes.isNotEmpty)
            SliverToBoxAdapter(child: _buildLoadingMore()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '搜索菜谱...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                hintStyle: TextStyle(color: Colors.grey),
              ),
              onSubmitted: (_) => _searchRecipes(),
            ),
          ),
          if (_isSearchMode)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: _clearSearch,
            ),
          IconButton(
            icon: Icon(Icons.search, color: Colors.orange[400]),
            onPressed: _searchRecipes,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchOptions() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 次级关键词
            TextField(
              controller: _secondaryKeywordController,
              decoration: InputDecoration(
                labelText: '次级关键词（可选）',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onSubmitted: (_) => _searchRecipes(),
            ),
            const SizedBox(height: 12),

            // 排序选项
            const Text('排序方式:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildSortChip('综合排序', 0),
                _buildSortChip('收藏最多', 2),
                _buildSortChip('学做最多', 3),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, int value) {
    final isSelected = _currentOrder == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _currentOrder = value;
          });
          if (_isSearchMode) {
            _searchRecipes();
          }
        }
      },
      selectedColor: Colors.orange[100],
      checkmarkColor: Colors.orange[600],
    );
  }

  Widget _buildRecipeGrid() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: _buildRecipeCard(_recipes[index]),
          );
        }, childCount: _recipes.length),
      ),
    );
  }

  Widget _buildRecipeCard(DGRoughItem recipe) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailPage(
                recipeId: recipe.id.toString(),
                recipeName: recipe.n ?? '未知菜谱',
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 菜谱图片
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: recipe.img != null
                      ? buildNetworkOrFileImage(recipe.img!, fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.restaurant_menu,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
            ),

            // 菜谱信息
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 菜谱名称
                    Text(
                      recipe.stdname ?? recipe.n ?? '未知菜谱',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),
                    // 作者信息
                    if (recipe.a?.n != null)
                      Text(
                        '作者: ${recipe.a!.n}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    // 底部信息
                    Row(
                      children: [
                        if (recipe.cookTime != null) ...[
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            recipe.cookTime!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (recipe.vc != null) ...[
                          Icon(
                            Icons.visibility,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            recipe.vc!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return SizedBox(
      height: 200,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
        ),
      ),
    );
  }

  Widget _buildLoadingMore() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSearchMode ? _searchRecipes : _loadRecommendedRecipes,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[400],
              foregroundColor: Colors.white,
            ),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _isSearchMode ? '没有找到相关菜谱' : '暂无推荐菜谱',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          if (_isSearchMode) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[400],
                foregroundColor: Colors.white,
              ),
              child: const Text('查看推荐菜谱'),
            ),
          ],
        ],
      ),
    );
  }
}
