import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../core/utils/datetime_formatter.dart';
import '../../../../../core/utils/get_dir.dart';
import '../../../../../core/utils/simple_tools.dart';
import '../../../../../shared/widgets/toast_utils.dart';
import '../../../data/models/tmdb/tmdb_all_image_resp.dart';
import '../../../data/models/tmdb/tmdb_common.dart';
import '../../widgets/tmdb_widgets.dart';

/// TMDB 图片画廊页面
class TmdbGalleryPage extends StatefulWidget {
  final String title;
  final TmdbAllImageResp images;
  final String mediaType;

  const TmdbGalleryPage({
    super.key,
    required this.title,
    required this.images,
    required this.mediaType,
  });

  @override
  State<TmdbGalleryPage> createState() => _TmdbGalleryPageState();
}

class _TmdbGalleryPageState extends State<TmdbGalleryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final PageController _pageController;
  int _currentIndex = 0;

  // 当前显示的图片列表
  List<TmdbImageItem> _currentImages = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeTabs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// 初始化标签页
  void _initializeTabs() {
    List<String> tabs = [];

    if (widget.mediaType == 'person') {
      if (widget.images.profiles?.isNotEmpty ?? false) {
        tabs.add('人物照片');
      }
    } else {
      if (widget.images.backdrops?.isNotEmpty ?? false) {
        tabs.add('剧照');
      }
      if (widget.images.posters?.isNotEmpty ?? false) {
        tabs.add('海报');
      }
    }

    if (tabs.isEmpty) {
      tabs.add('图片');
    }

    _tabController = TabController(length: tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);

    // 设置初始图片
    _updateCurrentImages(0);
  }

  /// 标签页变化回调
  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _updateCurrentImages(_tabController.index);
    }
  }

  /// 更新当前显示的图片列表
  void _updateCurrentImages(int tabIndex) {
    setState(() {
      if (widget.mediaType == 'person') {
        _currentImages = widget.images.profiles ?? [];
      } else {
        if (tabIndex == 0) {
          _currentImages = widget.images.backdrops ?? [];
        } else {
          _currentImages = widget.images.posters ?? [];
        }
      }

      // 重置索引并跳转到第一页
      _currentIndex = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: _tabController.length > 1
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                tabs: _buildTabs(),
              )
            : null,
      ),
      body: Column(
        children: [
          // 图片计数器
          if (_currentImages.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${_currentIndex + 1} / ${_currentImages.length}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          // 图片查看器
          Expanded(
            child: _currentImages.isEmpty
                ? const Center(
                    child: Text(
                      '暂无图片',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  )
                : PhotoViewGallery.builder(
                    scrollPhysics: const BouncingScrollPhysics(),
                    builder: (BuildContext context, int index) {
                      final image = _currentImages[index];
                      return PhotoViewGalleryPageOptions(
                        imageProvider: NetworkImage(
                          'https://image.tmdb.org/t/p/original${image.filePath}',
                        ),
                        initialScale: PhotoViewComputedScale.contained,
                        minScale: PhotoViewComputedScale.contained * 0.8,
                        maxScale: PhotoViewComputedScale.covered * 2.0,
                        heroAttributes: PhotoViewHeroAttributes(
                          tag: 'image_${image.filePath}',
                        ),
                      );
                    },
                    itemCount: _currentImages.length,
                    loadingBuilder: (context, event) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.black,
                    ),
                    pageController: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                  ),
          ),
          // 缩略图列表
          if (_currentImages.length > 1)
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _currentImages.length,
                itemBuilder: (context, index) {
                  final image = _currentImages[index];
                  final isSelected = index == _currentIndex;

                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: TmdbImageWidget(
                          imagePath: image.filePath,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      // 底部操作栏
      bottomNavigationBar: _currentImages.isNotEmpty
          ? Container(
              color: Colors.black.withValues(alpha: 0.8),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 分享按钮
                  IconButton(
                    onPressed: () {
                      _shareImage(context);
                    },
                    icon: const Icon(Icons.share, color: Colors.white),
                  ),
                  // 下载按钮
                  IconButton(
                    onPressed: () async {
                      await _downloadImage();
                    },
                    icon: const Icon(Icons.download, color: Colors.white),
                  ),
                  // 信息按钮
                  IconButton(
                    onPressed: () {
                      _showImageInfo();
                    },
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  /// 构建标签页
  List<Widget> _buildTabs() {
    List<Widget> tabs = [];

    if (widget.mediaType == 'person') {
      if (widget.images.profiles?.isNotEmpty ?? false) {
        tabs.add(Tab(text: '人物照片 (${widget.images.profiles!.length})'));
      }
    } else {
      if (widget.images.backdrops?.isNotEmpty ?? false) {
        tabs.add(Tab(text: '剧照 (${widget.images.backdrops!.length})'));
      }
      if (widget.images.posters?.isNotEmpty ?? false) {
        tabs.add(Tab(text: '海报 (${widget.images.posters!.length})'));
      }
    }

    return tabs;
  }

  Future<void> _shareImage(BuildContext context) async {
    final image = _currentImages[_currentIndex];
    var imagePath = 'https://image.tmdb.org/t/p/original${image.filePath}';

    try {
      final result = await SharePlus.instance.share(
        ShareParams(uri: Uri.tryParse(imagePath)),
      );

      if (result.status == ShareResultStatus.success) {
        ToastUtils.showSuccess('分享成功!');
      }
    } catch (e) {
      ToastUtils.showError('分享失败: $e', duration: Duration(seconds: 5));
      rethrow;
    }
  }

  Future<void> _downloadImage() async {
    final image = _currentImages[_currentIndex];

    // 网络图片就保存都指定位置
    await saveImageToLocal(
      'https://image.tmdb.org/t/p/original${image.filePath}',
      imageName: "${widget.title}_${fileTs(DateTime.now())}.jpg",
      dlDir: await getDioDownloadDir(),
    );
  }

  /// 显示图片信息
  void _showImageInfo() {
    if (_currentImages.isEmpty) return;

    final image = _currentImages[_currentIndex];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '图片信息',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow('尺寸', '${image.width} × ${image.height}'),
              _buildInfoRow(
                '宽高比',
                image.aspectRatio?.toStringAsFixed(2) ?? '未知',
              ),
              _buildInfoRow(
                '评分',
                '${image.voteAverage?.toStringAsFixed(1) ?? '未知'} (${image.voteCount ?? 0} 票)',
              ),
              if (image.iso6391?.isNotEmpty ?? false)
                _buildInfoRow('语言', image.iso6391!),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: const Text('关闭'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
