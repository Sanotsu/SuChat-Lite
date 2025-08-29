import 'package:flutter/material.dart';
import 'package:suchat_lite/core/utils/get_dir.dart';

import '../../../../../core/utils/simple_tools.dart';
import '../../../../../shared/widgets/image_preview_helper.dart';
import '../../../data/datasources/haokan/haokan_api_manager.dart';
import '../../../data/models/haokan/haokan_models.dart';
import '../../../data/services/haokan_storage_service.dart';

/// 好看漫画阅读页面 - 上下滚动模式
class HaokanReadingPage extends StatefulWidget {
  final int chapterId;

  const HaokanReadingPage({super.key, required this.chapterId});

  @override
  State<HaokanReadingPage> createState() => _HaokanReadingPageState();
}

class _HaokanReadingPageState extends State<HaokanReadingPage> {
  final HaokanApiManager _apiManager = HaokanApiManager();
  final ScrollController _scrollController = ScrollController();
  final HaokanStorageService _storageService = HaokanStorageService.instance;

  HaokanChapter? _chapter;
  bool _isLoading = true;
  String? _error;
  int _currentImageIndex = 0;
  bool _showControls = true;
  final List<GlobalKey> _imageKeys = [];

  @override
  void initState() {
    super.initState();
    _loadChapterDetail();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChapterDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final chapter = await _apiManager.getHaokanComicChapterDetail(
        chapterId: widget.chapterId,
      );

      setState(() {
        _chapter = chapter;
        _isLoading = false;
        // 为每张图片创建key
        _imageKeys.clear();
        for (int i = 0; i < (chapter.piclist?.length ?? 0); i++) {
          _imageKeys.add(GlobalKey());
        }
      });

      // 章节加载完成后，恢复阅读进度
      _restoreReadingProgress();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onScroll() {
    if (!mounted || _chapter?.piclist == null) return;

    // 计算当前显示的图片索引
    final viewportHeight = MediaQuery.of(context).size.height;

    for (int i = 0; i < _imageKeys.length; i++) {
      final key = _imageKeys[i];
      final context = key.currentContext;
      if (context != null) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final position = box.localToGlobal(Offset.zero);
          final imageTop = position.dy;
          final imageBottom = imageTop + box.size.height;

          // 如果图片在视窗中央区域，更新当前索引
          if (imageTop <= viewportHeight / 2 &&
              imageBottom >= viewportHeight / 2) {
            if (_currentImageIndex != i) {
              setState(() {
                _currentImageIndex = i;
              });
              // 记录阅读进度
              _saveReadingProgress();
            }
            break;
          }
        }
      }
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  /// 保存阅读进度
  void _saveReadingProgress() {
    if (_chapter == null || _chapter!.comicid == null) return;

    _storageService.updateReadingProgress(
      comicId: _chapter!.comicid!,
      chapterId: widget.chapterId,
      chapterName: _chapter!.name ?? '',
      imageIndex: _currentImageIndex,
      totalImages: _chapter!.piclist?.length ?? 0,
    );
  }

  /// 恢复阅读进度
  void _restoreReadingProgress() {
    if (_chapter == null || _chapter!.comicid == null) return;

    final progress = _storageService.getReadingProgress(_chapter!.comicid!);

    // 只有当前章节匹配时才恢复进度
    if (progress != null && progress.chapterId == widget.chapterId) {
      final targetIndex = progress.imageIndex.clamp(
        0,
        (_chapter!.piclist?.length ?? 1) - 1,
      );

      // 更新当前图片索引
      setState(() {
        _currentImageIndex = targetIndex;
      });

      // 延迟执行滚动，确保UI完全构建完成
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollToImageIndex(targetIndex);
      });
    }
  }

  /// 滚动到指定图片索引位置(实测可能会有几页的偏差，问题不大)
  void _scrollToImageIndex(int targetIndex) {
    if (!mounted || !_scrollController.hasClients || targetIndex < 0) return;

    final targetKey = _imageKeys[targetIndex];

    if (targetKey.currentContext != null) {
      // 如果目标图片已经渲染，使用精确位置滚动
      Scrollable.ensureVisible(
        targetKey.currentContext!,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        alignment: 0.1, // 滚动到屏幕顶部10%的位置
      );
    } else {
      // 如果目标图片还未渲染，使用估算位置滚动
      final screenHeight = MediaQuery.of(context).size.height;
      final estimatedImageHeight = screenHeight * 0.8;
      final targetOffset = targetIndex * estimatedImageHeight;

      _scrollController
          .animateTo(
            targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          )
          .then((_) {
            // 滚动完成后，再次尝试精确定位
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted && targetKey.currentContext != null) {
                Scrollable.ensureVisible(
                  targetKey.currentContext!,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  alignment: 0.1,
                );
              }
            });
          });
    }
  }

  void _navigateToChapter(bool isNext) {
    if (_chapter == null) return;

    final targetChapterId = isNext ? _chapter!.idNext : _chapter!.idLast;
    if (targetChapterId != null && targetChapterId > 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HaokanReadingPage(chapterId: targetChapterId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isNext ? '已经是最新章节了' : '已经是第一章节了'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black, body: _buildBody());
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              '加载失败: $_error',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadChapterDetail,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_chapter?.piclist == null || _chapter!.piclist!.isEmpty) {
      return const Center(
        child: Text('暂无图片内容', style: TextStyle(color: Colors.white)),
      );
    }

    return Stack(
      children: [
        // 主要内容区域 - 上下滚动的图片列表
        GestureDetector(
          onTap: _toggleControls,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return Container(
                    key: _imageKeys[index],
                    child: _buildImageItem(_chapter!.piclist![index], index),
                  );
                }, childCount: _chapter!.piclist!.length),
              ),
            ],
          ),
        ),
        // 顶部控制栏
        if (_showControls) _buildTopControls(),
        // 底部控制栏
        if (_showControls) _buildBottomControls(),
      ],
    );
  }

  Widget _buildImageItem(HaokanChapterPicture picture, int index) {
    return SizedBox(
      width: double.infinity,
      child: InteractiveViewer(
        minScale: 0.8,
        maxScale: 3.0,
        child: buildNetworkOrFileImage(picture.url ?? '', fit: BoxFit.fitWidth),
      ),
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Text(
                _chapter?.name ?? '章节阅读',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: _showMoreOptions,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    final totalPages = _chapter?.piclist?.length ?? 0;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          top: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 进度条
            Row(
              children: [
                Text(
                  '${_currentImageIndex + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                Expanded(
                  child: Slider(
                    value: _currentImageIndex.toDouble(),
                    min: 0,
                    max: (totalPages - 1).toDouble(),
                    divisions: totalPages > 1 ? totalPages - 1 : 1,
                    activeColor: Colors.pink[400],
                    inactiveColor: Colors.white30,
                    onChanged: (value) {
                      // 滚动到指定图片位置
                      final targetIndex = value.round();
                      if (targetIndex < _imageKeys.length) {
                        final key = _imageKeys[targetIndex];
                        final context = key.currentContext;
                        if (context != null) {
                          Scrollable.ensureVisible(
                            context,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      }
                    },
                  ),
                ),
                Text(
                  '$totalPages',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 章节导航按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavButton(
                  icon: Icons.skip_previous,
                  label: '上一章',
                  onPressed: _chapter?.idLast != null
                      ? () => _navigateToChapter(false)
                      : null,
                ),

                _buildNavButton(
                  icon: Icons.skip_next,
                  label: '下一章',
                  onPressed: _chapter?.idNext != null
                      ? () => _navigateToChapter(true)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: onPressed != null
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: onPressed != null ? Colors.white : Colors.white54,
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: onPressed != null ? Colors.white : Colors.white54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 主要留个记录，有必要可以扩展功能，比如阅读设置、分享等
  // 注意：这里虽然下载图片到本地了，但阅读时依旧使用的网络图片
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download, color: Colors.white),
              title: const Text('下载', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);

                if (_chapter!.piclist == null || _chapter!.piclist!.isEmpty) {
                  return;
                }

                // 批量下载所有图片
                List<String> imageUrls = [];
                List<String> imageNames = [];
                for (int i = 0; i < _chapter!.piclist!.length; i++) {
                  imageNames.add(
                    "${_chapter!.comicid}_${_chapter!.name}_${i + 1}.jpg",
                  );
                  imageUrls.add(_chapter!.piclist![i].url!);
                }

                var chapterName = "${_chapter!.comicid}/${_chapter!.name}";
                saveMultipleImagesToLocal(
                  imageUrls,
                  imageNames: imageNames,
                  dlDir: await getAppHomeDirectory(
                    subfolder: "NET_DL/haokan/$chapterName",
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
