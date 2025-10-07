import 'package:flutter/material.dart';

import '../../../../../core/utils/datetime_formatter.dart';
import '../../../../../shared/widgets/image_preview_helper.dart';
import '../../../../../shared/widgets/simple_tool_widget.dart';
import '../../../../../shared/widgets/toast_utils.dart';
import '../../../data/services/haokan_storage_service.dart';
import 'detail_page.dart';

/// 好看漫画收藏列表页面
class HaokanFavoritesPage extends StatefulWidget {
  const HaokanFavoritesPage({super.key});

  @override
  State<HaokanFavoritesPage> createState() => _HaokanFavoritesPageState();
}

class _HaokanFavoritesPageState extends State<HaokanFavoritesPage> {
  final HaokanStorageService _storageService = HaokanStorageService.instance;

  List<HaokanFavoriteComic> _favorites = [];
  Map<int, HaokanReadingProgress?> _progressMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    setState(() {
      _isLoading = true;
    });

    try {
      final favorites = _storageService.getFavoriteComics();
      final progressMap = <int, HaokanReadingProgress?>{};

      // 获取每个收藏漫画的阅读进度
      for (final favorite in favorites) {
        progressMap[favorite.comicId] = _storageService.getReadingProgress(
          favorite.comicId,
        );
      }

      setState(() {
        _favorites = favorites;
        _progressMap = progressMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavorite(HaokanFavoriteComic favorite) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要取消收藏《${favorite.title}》吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.removeFavorite(favorite.comicId);
      _loadFavorites();

      ToastUtils.showSuccess('已取消收藏');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
        backgroundColor: Colors.pink[100],
        actions: [
          if (_favorites.isNotEmpty)
            TextButton(onPressed: _showClearAllDialog, child: const Text('清空')),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              '还没有收藏任何漫画',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              '去发现一些好看的漫画吧！',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadFavorites(),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final favorite = _favorites[index];
          final progress = _progressMap[favorite.comicId];

          return _buildFavoriteItem(favorite, progress);
        },
      ),
    );
  }

  Widget _buildFavoriteItem(
    HaokanFavoriteComic favorite,
    HaokanReadingProgress? progress,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: () => showNoNetworkOrGoTargetPage(
          context,
          HaokanDetailPage(comicId: favorite.comicId),
          thenFunc: (value) {
            // 从详情页返回后刷新收藏状态
            _loadFavorites();
          },
        ),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 封面图片
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 60,
                  height: 80,
                  child: buildNetworkOrFileImage(
                    favorite.pic,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 漫画信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      favorite.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (favorite.author.isNotEmpty)
                      Text(
                        favorite.author,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    const SizedBox(height: 4),
                    if (favorite.lastChapter.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '最新: ${favorite.lastChapter}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    // 阅读进度
                    if (progress != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '读到: ${progress.chapterName} (${progress.progressDescription})',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '上次阅读: ${formatRelativeDate(progress.lastReadTime)}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ] else
                      Text(
                        '收藏时间: ${formatRelativeDate(favorite.favoriteTime)}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                  ],
                ),
              ),
              // 操作按钮
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'remove') {
                    _removeFavorite(favorite);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18),
                        SizedBox(width: 8),
                        Text('取消收藏'),
                      ],
                    ),
                  ),
                ],
                child: const Icon(Icons.more_vert),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空收藏'),
        content: const Text('确定要清空所有收藏吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // 清空所有收藏
              for (final favorite in _favorites) {
                await _storageService.removeFavorite(favorite.comicId);
              }

              _loadFavorites();

              ToastUtils.showSuccess('已清空所有收藏');
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
