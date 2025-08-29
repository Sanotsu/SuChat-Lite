import 'package:flutter/material.dart';

import '../../../../../shared/widgets/simple_tool_widget.dart';
import '../../../data/datasources/haokan/haokan_api_manager.dart';
import '../../../data/models/haokan/haokan_models.dart';
import '../../widgets/haokan/haokan_comic_card.dart';

/// 好看漫画搜索页面
class HaokanSearchPage extends StatefulWidget {
  const HaokanSearchPage({super.key});

  @override
  State<HaokanSearchPage> createState() => _HaokanSearchPageState();
}

class _HaokanSearchPageState extends State<HaokanSearchPage> {
  final HaokanApiManager _apiManager = HaokanApiManager();
  final TextEditingController _searchController = TextEditingController();

  List<HaokanComic> _hotComics = [];
  List<HaokanComic> _searchResults = [];
  bool _isLoadingHot = true;
  bool _isSearching = false;
  String? _hotError;
  String? _searchError;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadHotComics();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHotComics() async {
    try {
      setState(() {
        _isLoadingHot = true;
        _hotError = null;
      });

      final data = await _apiManager.getHaokanComicListByHotSearch(
        forceRefresh: true,
      );

      setState(() {
        _hotComics = data;
        _isLoadingHot = false;
      });
    } catch (e) {
      setState(() {
        _hotError = e.toString();
        _isLoadingHot = false;
      });
    }
  }

  Future<void> _performSearch(String keyword) async {
    unfocusHandle();

    if (keyword.trim().isEmpty) return;

    try {
      setState(() {
        _isSearching = true;
        _searchError = null;
        _hasSearched = true;
      });

      final data = await _apiManager.getHaokanComicListByKeyword(
        keyword: keyword.trim(),
      );
      setState(() {
        _searchResults = data;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchError = e.toString();
        _isSearching = false;
      });
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults.clear();
      _hasSearched = false;
      _searchError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('搜索漫画'),
        backgroundColor: Colors.pink[100],
      ),
      body: Column(
        children: [
          // 搜索框
          _buildSearchBar(),
          // 内容区域
          Expanded(
            child: _hasSearched ? _buildSearchResults() : _buildHotComics(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索漫画名称或作者',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _hasSearched
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: _performSearch,
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => _performSearch(_searchController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink[400],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }

  Widget _buildHotComics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.local_fire_department,
                color: Colors.orange[600],
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '热门搜索',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildHotComicsContent()),
      ],
    );
  }

  Widget _buildHotComicsContent() {
    if (_isLoadingHot) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hotError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('加载失败: $_hotError'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadHotComics, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_hotComics.isEmpty) {
      return const Center(child: Text('暂无热门搜索数据'));
    }

    return RefreshIndicator(
      onRefresh: _loadHotComics,
      child: ComicGridView(comics: _hotComics, isMini: true),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.search_outlined, color: Colors.blue, size: 24),
              const SizedBox(width: 8),
              Text(
                '搜索结果',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              if (_searchResults.isNotEmpty)
                Text(
                  '共${_searchResults.length}个结果',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
            ],
          ),
        ),
        Expanded(child: _buildSearchResultsContent()),
      ],
    );
  }

  Widget _buildSearchResultsContent() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('搜索失败: $_searchError'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _performSearch(_searchController.text),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('未找到相关漫画'),
            const SizedBox(height: 8),
            Text('试试其他关键词吧', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ComicGridView(comics: _searchResults, isMini: true);
  }
}
