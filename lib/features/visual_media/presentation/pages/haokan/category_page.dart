import 'package:flutter/material.dart';

import '../../../../../shared/widgets/simple_tool_widget.dart';
import '../../../data/datasources/haokan/haokan_api_manager.dart';
import '../../../data/models/haokan/haokan_models.dart';
import '../../../data/models/haokan/haokan_enums.dart';
import '../../widgets/haokan/category_filter_bottom_sheet.dart';
import '../../widgets/haokan/comic_card.dart';
import 'search_page.dart';
import 'detail_page.dart';

/// 好看漫画分类页面
class HaokanCategoryPage extends StatefulWidget {
  const HaokanCategoryPage({super.key});

  @override
  State<HaokanCategoryPage> createState() => _HaokanCategoryPageState();
}

class _HaokanCategoryPageState extends State<HaokanCategoryPage> {
  final HaokanApiManager _apiManager = HaokanApiManager();
  final ScrollController _scrollController = ScrollController();

  List<HaokanComic> _comics = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  int _currentPage = 1;

  // 筛选条件
  ComicCategory _selectedCategory = ComicCategory.all;
  ComicEndStatus _selectedEndStatus = ComicEndStatus.all;
  ComicFreeStatus _selectedFreeStatus = ComicFreeStatus.all;
  ComicSortType _selectedSortType = ComicSortType.latest;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadComics(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadComics();
      }
    }
  }

  Future<void> _loadComics({bool refresh = false}) async {
    if (_isLoading) return;

    try {
      setState(() {
        _isLoading = true;
        if (refresh) {
          _currentPage = 1;
          _comics.clear();
          _hasMore = true;
          _error = null;
        }
      });

      final data = await _apiManager.getHaokanComicListByCategory(
        categoryId: _selectedCategory.id,
        comicEndStatus: _selectedEndStatus.id,
        comicFreeStatus: _selectedFreeStatus.id,
        comicSortType: _selectedSortType.id,
        page: _currentPage,
        size: 20,
      );

      setState(() {
        if (refresh) {
          _comics = data;
        } else {
          _comics.addAll(data);
        }
        _currentPage++;
        _hasMore = data.length >= 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryFilterBottomSheet(
        selectedCategory: _selectedCategory,
        selectedEndStatus: _selectedEndStatus,
        selectedFreeStatus: _selectedFreeStatus,
        selectedSortType: _selectedSortType,
        onCategoryChanged: (category) {
          setState(() {
            _selectedCategory = category;
          });
        },
        onEndStatusChanged: (status) {
          setState(() {
            _selectedEndStatus = status;
          });
        },
        onFreeStatusChanged: (status) {
          setState(() {
            _selectedFreeStatus = status;
          });
        },
        onSortTypeChanged: (sort) {
          setState(() {
            _selectedSortType = sort;
          });
        },
        onApply: () {
          Navigator.pop(context);
          _loadComics(refresh: true);
        },
        onReset: _resetFilters,
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = ComicCategory.urban;
      _selectedEndStatus = ComicEndStatus.all;
      _selectedFreeStatus = ComicFreeStatus.all;
      _selectedSortType = ComicSortType.latest;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('漫画分类'),
        backgroundColor: Colors.pink[100],
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () =>
                showNoNetworkOrGoTargetPage(context, HaokanSearchPage()),
          ),
          // IconButton(
          //   icon: const Icon(Icons.filter_list),
          //   onPressed: _showFilterDialog,
          // ),
        ],
      ),
      body: Column(
        children: [
          // 当前筛选条件显示
          _buildCurrentFilters(),
          // 漫画列表
          Expanded(child: _buildComicsList()),
        ],
      ),
    );
  }

  Widget _buildCurrentFilters() {
    return Container(
      padding: const EdgeInsets.only(left: 16),
      color: Colors.grey[50],
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildFilterChip(_selectedCategory.title, Colors.pink),
                _buildFilterChip(_selectedEndStatus.title, Colors.blue),
                _buildFilterChip(_selectedFreeStatus.title, Colors.green),
                _buildFilterChip(_selectedSortType.title, Colors.orange),
              ],
            ),
          ),
          Text(
            '共${_comics.length}部',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color[700],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildComicsList() {
    if (_isLoading && _comics.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _comics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('加载失败: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadComics(refresh: true),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_comics.isEmpty) {
      return const Center(child: Text('暂无漫画数据'));
    }

    return RefreshIndicator(
      onRefresh: () => _loadComics(refresh: true),
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1 / 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _comics.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _comics.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          return HaokanComicCard(
            comic: _comics[index],
            showAuthor: false,
            onTap: () => _navigateToComicDetail(_comics[index].id ?? 0),
          );
        },
      ),
    );
  }

  void _navigateToComicDetail(int comicId) {
    if (comicId > 0) {
      showNoNetworkOrGoTargetPage(context, HaokanDetailPage(comicId: comicId));
    }
  }
}
