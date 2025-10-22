import 'package:flutter/material.dart';

import '../../../../../shared/widgets/image_preview_helper.dart';
import '../../../../../shared/widgets/toast_utils.dart';
import '../../../data/datasources/haokan/haokan_api_manager.dart';
import '../../../data/models/haokan/haokan_models.dart';
import '../../../data/services/haokan_storage_service.dart';
import '../../widgets/haokan/comic_card.dart';
import '../../widgets/haokan/comment_item.dart';
import 'reading_page.dart';
import 'comment_page.dart';

/// 好看漫画详情页面
class HaokanDetailPage extends StatefulWidget {
  final int comicId;

  const HaokanDetailPage({super.key, required this.comicId});

  @override
  State<HaokanDetailPage> createState() => _HaokanDetailPageState();
}

class _HaokanDetailPageState extends State<HaokanDetailPage> {
  final HaokanApiManager _apiManager = HaokanApiManager();
  final ScrollController _scrollController = ScrollController();
  final HaokanStorageService _storageService = HaokanStorageService.instance;

  HaokanComic? _comic;
  List<HaokanChapter> _chapters = [];
  List<HaokanComment> _hotComments = [];
  List<HaokanComic> _recommendComics = [];
  bool _isFavorite = false;
  HaokanReadingProgress? _readingProgress;

  bool _isLoadingDetail = true;
  bool _isLoadingChapters = true;
  bool _isLoadingComments = true;
  bool _isLoadingRecommend = true;

  String? _detailError;
  String? _chaptersError;
  String? _commentsError;
  String? _recommendError;

  @override
  void initState() {
    super.initState();

    _loadAllData();
    _checkFavoriteStatus();
  }

  void _checkFavoriteStatus() {
    setState(() {
      _isFavorite = _storageService.isFavorite(widget.comicId);
      _readingProgress = _storageService.getReadingProgress(widget.comicId);
    });
  }

  Future<void> _toggleFavorite() async {
    if (_comic == null) return;

    try {
      if (_isFavorite) {
        await _storageService.removeFavorite(widget.comicId);

        ToastUtils.showInfo('已取消收藏');
      } else {
        await _storageService.addFavorite(_comic!);
        ToastUtils.showInfo('收藏成功');
      }

      setState(() {
        _isFavorite = !_isFavorite;
      });
    } catch (e) {
      ToastUtils.showError('操作失败: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadComicDetail(),
      _loadChapters(),
      _loadHotComments(),
      _loadRecommendComics(),
    ]);
  }

  Future<void> _loadComicDetail() async {
    try {
      setState(() {
        _isLoadingDetail = true;
        _detailError = null;
      });

      final comic = await _apiManager.getHaokanComicDetail(
        comicId: widget.comicId,
      );

      if (!mounted) return;
      setState(() {
        _comic = comic;
        _isLoadingDetail = false;
      });
    } catch (e) {
      setState(() {
        _detailError = e.toString();
        _isLoadingDetail = false;
      });
    }
  }

  Future<void> _loadChapters() async {
    try {
      setState(() {
        _isLoadingChapters = true;
        _chaptersError = null;
      });

      final chapters = await _apiManager.getHaokanComicChapterList(
        comicId: widget.comicId,
      );

      if (!mounted) return;
      setState(() {
        _chapters = chapters;
        _isLoadingChapters = false;
      });
    } catch (e) {
      setState(() {
        _chaptersError = e.toString();
        _isLoadingChapters = false;
      });
    }
  }

  Future<void> _loadHotComments() async {
    try {
      setState(() {
        _isLoadingComments = true;
        _commentsError = null;
      });

      final comments = await _apiManager.getHaokanComicHotCommentList(
        comicId: widget.comicId,
      );

      if (!mounted) return;
      setState(() {
        _hotComments = comments;
        _isLoadingComments = false;
      });
    } catch (e) {
      setState(() {
        _commentsError = e.toString();
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _loadRecommendComics() async {
    try {
      setState(() {
        _isLoadingRecommend = true;
        _recommendError = null;
      });

      final comics = await _apiManager.getHaokanComicRecommendList(
        comicId: widget.comicId,
      );

      if (!mounted) return;
      setState(() {
        _recommendComics = comics;
        _isLoadingRecommend = false;
      });
    } catch (e) {
      setState(() {
        _recommendError = e.toString();
        _isLoadingRecommend = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 主要内容
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 顶部封面区域
              if (_comic != null) _buildSliverAppBar(),
              // 内容区域
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // 漫画基本信息
                    _buildComicInfo(),
                    // 漫画简介
                    _buildComicDescription(),
                    // 章节列表
                    _buildChaptersList(),
                    // 热门评论
                    _buildHotComments(),
                    // 推荐漫画
                    _buildRecommendComics(),
                    // 底部间距（避免被底部固定按钮遮挡）
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),

          // 底部固定按钮
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    var comicInfo = Row(
      children: [
        // 封面图
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 80,
            height: 110,
            child: buildNetworkOrFileImage(
              _comic!.pic ?? '',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // 漫画信息
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _comic!.title ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '催更: ${_comic!.urgeNum ?? 0} 次',
                style: const TextStyle(color: Colors.yellow, fontSize: 14),
              ),

              Text(
                widget.comicId.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),

              const SizedBox(height: 16),
              if (_comic!.author != null)
                Text(
                  '作者: ${_comic!.author}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              const SizedBox(height: 4),
              if (_comic!.tag != null)
                Text(
                  _comic!.tag!,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
            ],
          ),
        ),
      ],
    );

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: Colors.pink[100],
      foregroundColor: Colors.black,
      flexibleSpace: FlexibleSpaceBar(
        title: LayoutBuilder(
          builder: (context, constraints) {
            return Opacity(
              // 因为进入详情页默认展开的背景中有漫画标题，所以只有滚动到这个阈值高度时才显示这个顶部标题
              opacity: constraints.maxHeight < 100 ? 1.0 : 0.0,
              child: Text(
                _comic!.title ?? '',
                style: const TextStyle(color: Colors.black, fontSize: 22),
              ),
            );
          },
        ),
        background: _comic != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  // 背景图片
                  buildNetworkOrFileImage(
                    _comic!.bigpic ?? _comic!.pic ?? '',
                    fit: BoxFit.cover,
                  ),

                  // 渐变遮罩
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  // 漫画信息
                  Positioned(bottom: 8, left: 16, right: 16, child: comicInfo),
                ],
              )
            : Container(color: Colors.grey[300]),
      ),
    );
  }

  Widget _buildComicInfo() {
    if (_isLoadingDetail) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_detailError != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('加载失败: $_detailError'),
      );
    }

    if (_comic == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem('收藏数', _formatNumber(_comic!.numFav ?? 0)),
          _buildInfoItem('点赞数', _formatNumber(_comic!.numLove ?? 0)),
          _buildInfoItem('人气数', _formatNumber(_comic!.numLook ?? 0)),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.pink[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildComicDescription() {
    if (_comic?.info == null || _comic!.info!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '漫画简介',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SelectableText(
            _comic!.info!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChaptersList() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '漫画全集',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (_chapters.isNotEmpty)
                GestureDetector(
                  onTap: _showAllChapters,
                  child: Row(
                    children: [
                      Text(
                        '目录',
                        style: TextStyle(color: Colors.pink[600], fontSize: 14),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.pink[600],
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildChaptersContent(),
        ],
      ),
    );
  }

  Widget _buildChaptersContent() {
    if (_isLoadingChapters) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_chaptersError != null) {
      return Text('加载失败: $_chaptersError');
    }

    if (_chapters.isEmpty) {
      return const Text('暂无章节');
    }

    // 显示前6个章节
    final displayChapters = _chapters.take(6).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: displayChapters.length,
      itemBuilder: (context, index) {
        final chapter = displayChapters[index];
        return GestureDetector(
          onTap: () => _navigateToReading(chapter.id ?? 0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.pink[50],
              borderRadius: BorderRadius.circular(8),
              // 加了边框在弹窗显示全部时会透出来，修改过没法解决也不知道原因，只有边框透出来了
              // border: Border.all(color: Colors.pink[200]!),
            ),
            child: Center(
              child: Text(
                chapter.name ?? '第${chapter.sort}话',
                style: TextStyle(
                  color: Colors.pink[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHotComments() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '热门评论',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: _navigateToComments,
                child: Row(
                  children: [
                    Text(
                      '全部精彩评论',
                      style: TextStyle(color: Colors.pink[600], fontSize: 14),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.pink[600],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildCommentsContent(),
        ],
      ),
    );
  }

  Widget _buildCommentsContent() {
    if (_isLoadingComments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_commentsError != null) {
      return Text('加载失败: $_commentsError');
    }

    if (_hotComments.isEmpty) {
      return const Text('暂无评论');
    }

    return Column(
      children: _hotComments
          .take(3)
          .map((comment) => HaokanCommentItem(comment: comment))
          .toList(),
    );
  }

  Widget _buildRecommendComics() {
    if (_isLoadingRecommend || _recommendComics.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_recommendError != null) {
      return Text('加载失败: $_recommendError');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '推荐漫画',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),

        ComicGridView(
          comics: _recommendComics.take(6).toList(),
          isMini: true,
          isScrollable: false,
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 收藏按钮
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _toggleFavorite,
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                ),
                label: Text(_isFavorite ? '已收藏' : '收藏漫画'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.pink[400]!),
                  foregroundColor: _isFavorite ? Colors.pink[400] : null,
                ),
              ),
            ),

            const SizedBox(width: 16),

            // 开始阅读按钮
            Expanded(
              child: ElevatedButton(
                onPressed: _startReading,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[400],
                  foregroundColor: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _readingProgress != null ? '继续阅读' : '开始阅读',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (_readingProgress != null)
                      Text(
                        '${_readingProgress!.chapterName} (${_readingProgress!.progressDescription})',
                        style: const TextStyle(fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  String _formatNumber(int number) {
    if (number >= 10000) {
      return '${(number / 10000).toStringAsFixed(1)}万';
    }
    return number.toString();
  }

  // 显示全部章节时，从最新的章节倒序显示
  void _showAllChapters() {
    var reversedChapters = _chapters.reversed.toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.pink[50],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '全部章节 (${reversedChapters.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: reversedChapters.length,
                itemBuilder: (context, index) {
                  final chapter = reversedChapters[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToReading(chapter.id ?? 0);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.pink[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.pink[200]!),
                      ),
                      child: Center(
                        child: Text(
                          chapter.name ?? '第${chapter.sort}话',
                          style: TextStyle(
                            color: Colors.pink[700],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startReading() {
    if (_chapters.isEmpty) {
      ToastUtils.showError('暂无可阅读的章节');
      return;
    }

    // 检查是否有阅读进度
    final progress = _storageService.getReadingProgress(widget.comicId);

    if (progress != null) {
      // 有阅读进度，从上次阅读的章节继续
      _navigateToReading(progress.chapterId);
    } else {
      // 没有阅读进度，从第一章开始
      _navigateToReading(_chapters.first.id ?? 0);
    }
  }

  void _navigateToReading(int chapterId) {
    if (chapterId > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HaokanReadingPage(chapterId: chapterId),
        ),
      ).then((_) {
        // 从阅读页面返回后，刷新收藏状态和阅读进度
        _checkFavoriteStatus();
      });
    }
  }

  void _navigateToComments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HaokanCommentPage(comicId: widget.comicId),
      ),
    );
  }
}
