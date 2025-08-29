import 'package:flutter/material.dart';

import '../../../../../shared/widgets/simple_tool_widget.dart';
import '../../../data/datasources/haokan/haokan_api_manager.dart';
import '../../../data/models/haokan/haokan_models.dart';
import '../../../data/models/haokan/haokan_enums.dart';
import '../../widgets/haokan/haokan_comic_card.dart';
import 'haokan_search_page.dart';
import 'haokan_detail_page.dart';

/// 好看漫画榜单页面
class HaokanRankingPage extends StatefulWidget {
  const HaokanRankingPage({super.key});

  @override
  State<HaokanRankingPage> createState() => _HaokanRankingPageState();
}

class _HaokanRankingPageState extends State<HaokanRankingPage>
    with SingleTickerProviderStateMixin {
  final HaokanApiManager _apiManager = HaokanApiManager();
  late TabController _tabController;

  final Map<ComicTop, List<HaokanComic>> _rankingData = {};
  final Map<ComicTop, bool> _loadingStates = {};
  final Map<ComicTop, String?> _errorStates = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: ComicTop.values.length, vsync: this);

    // 初始化状态
    for (var top in ComicTop.values) {
      _loadingStates[top] = false;
      _errorStates[top] = null;
      _rankingData[top] = [];
    }

    // 加载第一个榜单
    _loadRankingData(ComicTop.popular);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRankingData(ComicTop top) async {
    if (_loadingStates[top] == true) return;

    try {
      setState(() {
        _loadingStates[top] = true;
        _errorStates[top] = null;
      });

      final data = await _apiManager.getHaokanComicTopList(topId: top.id);

      setState(() {
        _rankingData[top] = data;
        _loadingStates[top] = false;
      });
    } catch (e) {
      setState(() {
        _errorStates[top] = e.toString();
        _loadingStates[top] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('漫画榜单'),
        backgroundColor: Colors.pink[100],
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () =>
                showNoNetworkOrGoTargetPage(context, HaokanSearchPage()),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.pink[400],
          labelColor: Colors.pink[600],
          unselectedLabelColor: Colors.grey[600],
          onTap: (index) {
            final top = ComicTop.values[index];
            if (_rankingData[top]?.isEmpty == true) {
              _loadRankingData(top);
            }
          },
          tabs: ComicTop.values.map((top) {
            return Tab(text: top.title, icon: _buildTabIcon(top));
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: ComicTop.values.map((top) {
          return _buildRankingList(top);
        }).toList(),
      ),
    );
  }

  Widget _buildTabIcon(ComicTop top) {
    switch (top) {
      case ComicTop.popular:
        return const Icon(Icons.trending_up, size: 20);
      case ComicTop.male:
        return const Icon(Icons.male, size: 20);
      case ComicTop.female:
        return const Icon(Icons.female, size: 20);
      case ComicTop.latest:
        return const Icon(Icons.new_releases, size: 20);
      case ComicTop.urged:
        return const Icon(Icons.update, size: 20);
    }
  }

  Widget _buildRankingList(ComicTop top) {
    final isLoading = _loadingStates[top] ?? false;
    final error = _errorStates[top];
    final comics = _rankingData[top] ?? [];

    if (isLoading && comics.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && comics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('加载失败: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadRankingData(top),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (comics.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    return RefreshIndicator(
      onRefresh: () => _loadRankingData(top),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: comics.length,
        itemBuilder: (context, index) {
          return HaokanRankingCard(
            comic: comics[index],
            ranking: index + 1,
            onTap: () => _navigateToComicDetail(comics[index].id ?? 0),
          );
        },
      ),
    );
  }

  void _navigateToComicDetail(int comicId) async {
    if (comicId <= 0) return;

    showNoNetworkOrGoTargetPage(context, HaokanDetailPage(comicId: comicId));
  }
}
