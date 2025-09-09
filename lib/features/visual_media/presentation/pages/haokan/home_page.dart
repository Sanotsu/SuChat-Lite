import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../../../../../shared/services/network_service.dart';
import '../../../../../shared/widgets/image_preview_helper.dart';
import '../../../../../shared/widgets/simple_tool_widget.dart';
import '../../../data/datasources/haokan/haokan_api_manager.dart';
import '../../../data/models/haokan/haokan_models.dart';
import '../../../data/services/haokan_storage_service.dart';
import '../../widgets/haokan/comic_card.dart';
import 'search_page.dart';
import 'category_page.dart';
import 'ranking_page.dart';
import 'favorites_page.dart';
import 'detail_page.dart';

/// 好看漫画首页
class HaokanHomePage extends StatefulWidget {
  const HaokanHomePage({super.key});

  @override
  State<HaokanHomePage> createState() => _HaokanHomePageState();
}

class _HaokanHomePageState extends State<HaokanHomePage> {
  final HaokanApiManager _apiManager = HaokanApiManager();
  HaokanIndex? _indexData;
  bool _isLoading = true;
  String? _error;

  // 直接换一换的接口数据有问题，这里使用tab查询更多代替
  // 每点一次换一换，查询页面+1
  int _exchangeTabPage = 1;

  @override
  void initState() {
    super.initState();

    // 要初始化缓存，记录收藏和阅读进度
    HaokanStorageService.instance.init();

    _loadIndexData();
  }

  Future<void> _loadIndexData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // 检查网络状态
      bool isNetworkAvailable = await NetworkStatusService().isNetwork();
      if (!isNetworkAvailable) {
        setState(() {
          _error = "网络不可用，无法继续观看漫画。";
          _isLoading = false;
        });
        return;
      }

      final data = await _apiManager.getHaokanIndex();
      setState(() {
        _indexData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('好看漫画'),
        backgroundColor: Colors.pink[100],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadIndexData,
          ),
          buildInfoButtonOnAction(context, """数据源可能四五年没有更新了，将就看吧"""),
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
            ElevatedButton(onPressed: _loadIndexData, child: const Text('重试')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadIndexData,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // 顶部导航栏
            _buildTopNavigation(),
            // 推荐轮播图
            _buildRecommendCarousel(),
            // 分类内容
            _buildTabContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.pink[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            icon: Icons.favorite,
            title: '收藏',
            onTap: () => showNoNetworkOrGoTargetPage(
              context,
              const HaokanFavoritesPage(),
            ),
          ),
          _buildNavItem(
            icon: Icons.leaderboard,
            title: '榜单',
            onTap: () =>
                showNoNetworkOrGoTargetPage(context, const HaokanRankingPage()),
          ),
          _buildNavItem(
            icon: Icons.category,
            title: '分类',
            onTap: () => showNoNetworkOrGoTargetPage(
              context,
              const HaokanCategoryPage(),
            ),
          ),
          _buildNavItem(
            icon: Icons.search,
            title: '搜索',
            onTap: () =>
                showNoNetworkOrGoTargetPage(context, const HaokanSearchPage()),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.pink[300], size: 28),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.pink[400],
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendCarousel() {
    if (_indexData?.recommend == null || _indexData!.recommend!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '推荐漫画',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          CarouselSlider(
            options: CarouselOptions(
              height: 200,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              enlargeCenterPage: true,
              viewportFraction: 0.85,
            ),
            items: _indexData!.recommend!.map((recommend) {
              return Builder(
                builder: (BuildContext context) {
                  return GestureDetector(
                    onTap: () => _navigateToComicDetail(recommend.did ?? 0),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: buildNetworkOrFileImage(
                          recommend.pic ?? '',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    if (_indexData?.tab == null || _indexData!.tab!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: _indexData!.tab!.map((tab) {
        return _buildTabSection(tab);
      }).toList(),
    );
  }

  Widget _buildTabSection(HaokanTab tab) {
    if (tab.list == null || tab.list!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tab.name ?? '',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              GestureDetector(
                onTap: () => _exchangeTabContent(tab),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.pink[100],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    '换一换',
                    style: TextStyle(
                      color: Colors.pink[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        ComicGridView(comics: tab.list!, isMini: false, isScrollable: false),
      ],
    );
  }

  // 2025-08-29 实测换一换查询结果每次都一样，
  // 所以换一换实际是调用tab的查询更多，分页，所以这里要传入tab查询的当前页面，点一次换一换页码+1
  Future<void> _exchangeTabContent(HaokanTab tab) async {
    if (tab.id == null) return;

    try {
      // final newTab = await _apiManager.getHaokanTabExchange(
      //   tabId: int.parse(tab.id.toString()),
      // );

      final newTabList = await _apiManager.getHaokanTabMore(
        tabId: int.parse(tab.id.toString()),
        page: _exchangeTabPage,
        size: 6,
      );

      setState(() {
        _exchangeTabPage++;

        // 找到对应的tab并更新其内容
        final index = _indexData!.tab!.indexWhere((t) => t.id == tab.id);
        if (index != -1) {
          // _indexData!.tab![index] = newTab;
          // 是换一换，所以直接副值而不是addAll
          _indexData!.tab![index].list = newTabList;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('换一换失败: $e')));
      }
      rethrow;
    }
  }

  void _navigateToComicDetail(int comicId) {
    if (comicId > 0) {
      showNoNetworkOrGoTargetPage(context, HaokanDetailPage(comicId: comicId));
    }
  }
}
