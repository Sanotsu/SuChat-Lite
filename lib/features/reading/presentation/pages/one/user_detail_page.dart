import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../shared/constants/constants.dart';
import '../../../../../shared/widgets/common_error_empty_widgets.dart';
import '../../../../../shared/widgets/image_preview_helper.dart';
import '../../../../../shared/widgets/simple_tool_widget.dart';
import '../../../data/datasources/one_api_manager.dart';
import '../../../data/models/one/one_base_models.dart';
import '../../../data/models/one/one_category_list.dart';
import '../../../data/models/one/one_enums.dart';
import '../../../data/models/one/one_user_collection.dart';
import '../../widgets/one/category_cards/author_card.dart';
import '../../widgets/one/category_cards/diary_card.dart';
import '../../widgets/one/content_card.dart';
import 'category_pages/author_detail_page.dart';
import 'category_pages/diary_detail_page.dart';
import 'detail_page.dart';

/// ONE用户详情页面
class OneUserDetailPage extends StatefulWidget {
  final String userId;
  final String? userName;

  const OneUserDetailPage({super.key, required this.userId, this.userName});

  @override
  State<OneUserDetailPage> createState() => _OneUserDetailPageState();
}

class _OneUserDetailPageState extends State<OneUserDetailPage>
    with SingleTickerProviderStateMixin {
  final OneApiManager _apiManager = OneApiManager();
  late TabController _tabController;

  /// 数据状态
  bool _isLoading = false;
  String? _error;
  OneUser? _userDetail;
  List<OneAuthor> _followingAuthors = [];
  List<OneDiary> _userDiaries = [];

  /// 收藏数据
  final Map<String, List<dynamic>> _collections = {};
  final Map<String, bool> _collectionLoading = {};
  // 每个分类的最后一个contentId
  final Map<String, String> _collectionLastContentIds = {};
  // 每个分类是否还有更多数据
  final Map<String, bool> _collectionHasMore = {};
  // 当前选中的收藏分类
  String? _selectedCategoryId;

  /// 分页状态
  bool _followingHasMore = true;
  bool _followingLoading = false;
  String _lastFollowingId = '0';

  bool _diaryHasMore = true;
  bool _diaryLoading = false;
  String _lastDiaryId = '0';

  /// 收藏分类配置
  final List<Map<String, dynamic>> _collectionCategories = [
    {'id': '0', 'name': '图文', 'icon': Icons.image},
    {'id': '1', 'name': '阅读', 'icon': Icons.article},
    {'id': '2', 'name': '问答', 'icon': Icons.help},
    {'id': '4', 'name': '音乐', 'icon': Icons.audio_file},
    {'id': '5', 'name': '影视', 'icon': Icons.movie},
    {'id': '6', 'name': '连载', 'icon': Icons.book},
    {'id': '8', 'name': '电台', 'icon': Icons.radio},
    {'id': '9', 'name': '歌单', 'icon': Icons.audiotrack},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadUserData();
  }

  void _onTabChanged() {
    // 当切换到收藏tab时，默认选中图文分类
    if (_tabController.index == 1 && _selectedCategoryId == null) {
      _selectCategory('0');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 加载用户数据
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userDetail = await _apiManager.getOneUserDetail(
        userId: widget.userId,
      );

      if (mounted) {
        setState(() {
          _userDetail = userDetail;
          _isLoading = false;
        });

        // 并行加载关注和小记数据
        _loadFollowingData();
        _loadDiaryData();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// 加载关注数据
  Future<void> _loadFollowingData({bool loadMore = false}) async {
    if (_followingLoading) return;

    setState(() {
      _followingLoading = true;
    });

    try {
      final authors = await _apiManager.getOneUserFollowAuthorList(
        userId: widget.userId,
        lastId: loadMore ? _lastFollowingId : '0',
        type: '0',
      );

      if (mounted) {
        setState(() {
          if (loadMore) {
            _followingAuthors.addAll(authors);
          } else {
            _followingAuthors = authors;
          }

          _followingHasMore = authors.isNotEmpty;
          if (authors.isNotEmpty) {
            _lastFollowingId = authors.last.userId ?? '0';
          }
          _followingLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _followingLoading = false;
          _followingHasMore = false;
        });
      }
    }
  }

  /// 加载小记数据
  Future<void> _loadDiaryData({bool loadMore = false}) async {
    if (_diaryLoading) return;

    setState(() {
      _diaryLoading = true;
    });

    try {
      final diaries = await _apiManager.getOneUserDiaryList(
        userId: widget.userId,
        diaryId: loadMore ? _lastDiaryId : '0',
      );

      if (mounted) {
        setState(() {
          if (loadMore) {
            _userDiaries.addAll(diaries);
          } else {
            _userDiaries = diaries;
          }

          _diaryHasMore = diaries.isNotEmpty;
          if (diaries.isNotEmpty) {
            _lastDiaryId = diaries.last.id ?? '0';
          }
          _diaryLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _diaryLoading = false;
          _diaryHasMore = false;
        });
      }
    }
  }

  /// 加载收藏数据
  Future<void> _loadCollectionData(
    String category, {
    bool loadMore = false,
  }) async {
    if (_collectionLoading[category] == true) return;

    setState(() {
      _collectionLoading[category] = true;
    });

    try {
      final lastContentId = loadMore
          ? (_collectionLastContentIds[category] ?? '0')
          : '0';

      final response = await _apiManager.getOneUserCollectionList(
        userId: widget.userId,
        category: category,
        contentId: int.parse(lastContentId),
      );

      if (mounted && response.data != null) {
        final newData = response.data as List<dynamic>;

        setState(() {
          if (loadMore) {
            _collections[category] = [
              ...(_collections[category] ?? []),
              ...newData,
            ];
          } else {
            _collections[category] = newData;
          }

          // 更新最后一个contentId
          if (newData.isNotEmpty) {
            _collectionLastContentIds[category] = _getLastContentId(
              category,
              newData.last,
            );
          }
          _collectionHasMore[category] = newData.isNotEmpty;
          _collectionLoading[category] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _collectionLoading[category] = false;
          _collectionHasMore[category] = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载收藏失败: $e')));
      }
    }
  }

  /// 导航到详情页
  void _navigateToDetail({
    required String contentType,
    required String contentId,
    required String title,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OneDetailPage(
          contentType: contentType,
          contentId: contentId,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? buildCommonErrorWidget(error: _error, onRetry: _loadUserData)
          : _buildUserContent(),
    );
  }

  /// 构建用户内容
  Widget _buildUserContent() {
    return CustomScrollView(
      slivers: [
        // 用户信息头部
        _buildUserHeader(),
        // 标签页
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(
            TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: const [
                Tab(text: 'TA的关注'),
                Tab(text: 'TA的收藏'),
                Tab(text: 'TA的小记'),
              ],
            ),
          ),
        ),
        // 标签页内容
        SliverFillRemaining(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFollowingTab(),
              _buildCollectionTab(),
              _buildDiaryTab(),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建用户头部信息
  Widget _buildUserHeader() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Theme.of(context).primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // 背景图片
            if (_userDetail?.background != null)
              Positioned.fill(
                child: buildNetworkOrFileImage(
                  _userDetail!.background!,
                  fit: BoxFit.cover,
                ),
              ),
            // 渐变遮罩层，确保文字可读性
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).primaryColor.withValues(alpha: 0.7),
                    Theme.of(context).primaryColor.withValues(alpha: 0.5),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 头像
                      buildUserCircleAvatar(_userDetail?.webUrl, radius: 32),

                      // 强制宽度100%
                      const SizedBox(height: 10, width: double.infinity),

                      // 用户名
                      Text(
                        _userDetail?.userName ?? widget.userName ?? '未知用户',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),

                      Text(widget.userId),

                      // 用户描述
                      if (_userDetail?.desc != null)
                        Text(
                          _userDetail!.desc!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建关注标签页
  Widget _buildFollowingTab() {
    if (_followingAuthors.isEmpty && !_followingLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无关注的作者', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _followingAuthors.length + (_followingHasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _followingAuthors.length) {
          // 加载更多指示器
          if (_followingLoading) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          } else if (_followingHasMore) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => _loadFollowingData(loadMore: true),
                  child: const Text('加载更多'),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        final author = _followingAuthors[index];
        return _buildAuthorCard(author);
      },
    );
  }

  /// 构建作者卡片
  Widget _buildAuthorCard(OneAuthor author) {
    return OneAuthorCard(
      author: author,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AuthorDetailPage(author: author),
        ),
      ),
    );
  }

  /// 构建收藏标签页
  Widget _buildCollectionTab() {
    return Column(
      children: [
        // 收藏分类网格
        Container(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _collectionCategories.length,
            itemBuilder: (context, index) {
              final category = _collectionCategories[index];
              return _buildCollectionCategoryCard(category);
            },
          ),
        ),
        // 最近收藏列表
        Expanded(child: _buildRecentCollections()),
      ],
    );
  }

  /// 构建收藏分类卡片
  Widget _buildCollectionCategoryCard(Map<String, dynamic> category) {
    final categoryId = category['id']!.toString();
    final isLoading = _collectionLoading[categoryId] == true;
    final collections = _collections[categoryId] ?? [];

    return GestureDetector(
      onTap: () => _selectCategory(categoryId),
      child: Container(
        decoration: BoxDecoration(
          color: _selectedCategoryId == categoryId
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: _selectedCategoryId == categoryId
              ? Border.all(color: Theme.of(context).primaryColor, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                category['icon'] as IconData,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
            const SizedBox(height: 8),
            Text(
              category['name']! +
                  (collections.isNotEmpty ? ' (${collections.length})' : ''),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _selectedCategoryId == categoryId
                    ? Theme.of(context).primaryColor
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 选择收藏分类
  void _selectCategory(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _loadCollectionData(categoryId);
  }

  /// 根据分类获取最后一个contentId
  String _getLastContentId(String category, dynamic item) {
    switch (category) {
      case '0': // 图文
        final hpItem = item as OneUserHpCollection;
        return hpItem.hpcontentId ?? '0';
      case '1': // 阅读
        final readingItem = item as OneUserReadingCollection;
        return readingItem.contentId ?? '0';
      case '2': // 问答
        final questionItem = item as OneUserQuestionCollection;
        return questionItem.questionId ?? '0';
      case '4': // 音乐
        final musicItem = item as OneUserMusicCollection;
        return musicItem.id ?? '0';
      case '5': // 影视
        final movieItem = item as OneUserMovieCollection;
        return movieItem.id ?? '0';
      case '6': // 连载
        // 连载类型需要根据实际模型确定
        return '0';
      case '8': // 电台
        final radioItem = item as OneUserRadioCollection;
        return radioItem.contentId ?? '0';
      case '9': // 歌单
        final playlistItem = item as OneUserPlaylistCollection;
        return playlistItem.id ?? '0';
      default:
        return '0';
    }
  }

  /// 构建收藏列表
  Widget _buildRecentCollections() {
    // 如果没有选中分类，显示提示
    if (_selectedCategoryId == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('请选择收藏分类', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 8),
            Text(
              '点击上方分类查看收藏',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // 获取当前选中分类的收藏数据
    final selectedCollections = _collections[_selectedCategoryId] ?? [];
    final isLoading = _collectionLoading[_selectedCategoryId] == true;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (selectedCollections.isEmpty) {
      final categoryName = _collectionCategories.firstWhere(
        (c) => c['id'] == _selectedCategoryId,
      )['name']!;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '暂无$categoryName收藏',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // 构建选中分类的收藏列表
    final categoryName = _collectionCategories.firstWhere(
      (c) => c['id'] == _selectedCategoryId,
    )['name']!;

    final collectionsWithCategory = selectedCollections
        .map(
          (item) => {
            'category': categoryName,
            'categoryId': _selectedCategoryId!,
            'item': item,
          },
        )
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount:
          collectionsWithCategory.length +
          ((_collectionHasMore[_selectedCategoryId] ?? false) ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == collectionsWithCategory.length) {
          // 加载更多指示器
          final isLoading = _collectionLoading[_selectedCategoryId] == true;
          final hasMore = _collectionHasMore[_selectedCategoryId] ?? false;

          if (isLoading) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          } else if (hasMore) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () =>
                      _loadCollectionData(_selectedCategoryId!, loadMore: true),
                  child: const Text('加载更多'),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        final collection = collectionsWithCategory[index];
        return _buildCollectionItem(collection);
      },
    );
  }

  /// 构建收藏项
  Widget _buildCollectionItem(Map<String, dynamic> collection) {
    final categoryId = collection['categoryId'] as String;
    final item = collection['item'];

    // 将不同的收藏内容，转为统一的OneContent对象，然后放到通用的卡片组件中
    // 只用到了 cover title subtitle category maketime 栏位
    OneContent cusContent = OneContent(
      // 因为查询用户收藏的分类需要指定id，所以支持是参数id即可
      category: int.tryParse(categoryId) ?? 0,
    );

    // 根据不同类型解析数据
    switch (categoryId) {
      case '0': // 图文
        final hpItem = item as OneUserHpCollection;

        // 如果是图文，传入的是日期
        cusContent.contentId = DateFormat(
          formatToYMD,
        ).format(DateTime.parse(hpItem.hpMakettime ?? hpItem.maketime ?? ''));
        cusContent.cover = hpItem.hpImgUrl;
        cusContent.title = hpItem.hpTitle;
        cusContent.subtitle = hpItem.hpAuthor;
        cusContent.maketime = hpItem.hpMakettime ?? hpItem.maketime;

        break;
      case '1': // 阅读
        final readingItem = item as OneUserReadingCollection;

        cusContent.contentId = readingItem.contentId;
        cusContent.title = readingItem.hpTitle;
        // cusContent.subtitle = readingItem.guideWord;
        cusContent.subtitle = readingItem.author?.isNotEmpty == true
            ? readingItem.author!.first.userName
            : null;
        cusContent.maketime = readingItem.hpMakettime;

        break;
      case '2': // 问答
        final questionItem = item as OneUserQuestionCollection;

        // 没有图片
        cusContent.contentId = questionItem.questionId;
        cusContent.title = questionItem.questionTitle;
        cusContent.subtitle = questionItem.answerTitle;
        cusContent.maketime = questionItem.questionId;
        break;
      case '4': // 音乐
        final musicItem = item as OneUserMusicCollection;

        // 没有时间
        cusContent.contentId = musicItem.musicId;
        cusContent.cover = musicItem.cover;
        cusContent.title = musicItem.title;
        cusContent.subtitle = musicItem.author?.userName;

        break;
      case '5': // 影视
        final movieItem = item as OneUserMovieCollection;

        // 没有时间
        cusContent.contentId = movieItem.id;
        cusContent.cover = movieItem.cover;
        cusContent.title = movieItem.title;
        cusContent.subtitle = movieItem.subtitle;
        break;
      case '8': // 电台
        final radioItem = item as OneUserRadioCollection;

        // 没有时间
        cusContent.contentId = radioItem.contentId;
        cusContent.cover = radioItem.cover;
        cusContent.title = radioItem.title;
        cusContent.subtitle = radioItem.authorList?.isNotEmpty == true
            ? radioItem.authorList!.first.userName
            : null;

        break;
      case '9': // 歌单
        final playlistItem = item as OneUserPlaylistCollection;

        // 没有时间
        cusContent.contentId = playlistItem.contentId;
        cusContent.cover = playlistItem.cover;
        cusContent.title = playlistItem.title;
        cusContent.subtitle = playlistItem.subtitle;

        break;
    }

    return OneContentCard(
      content: cusContent,
      onTap: () => _navigateToDetail(
        /// 获取分类对应的内容类型
        contentType: OneCategory.getApiName(categoryId),
        contentId: cusContent.contentId,
        title: cusContent.title ?? '',
      ),
    );
  }

  /// 构建小记标签页
  Widget _buildDiaryTab() {
    if (_userDiaries.isEmpty && !_diaryLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无公开的小记', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _userDiaries.length + (_diaryHasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _userDiaries.length) {
          // 加载更多指示器
          if (_diaryLoading) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          } else if (_diaryHasMore) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => _loadDiaryData(loadMore: true),
                  child: const Text('加载更多'),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        final diary = _userDiaries[index];
        return _buildDiaryCard(diary);
      },
    );
  }

  /// 构建电台卡片
  Widget _buildDiaryCard(OneDiary diary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: OneDiaryCard(
        diary: diary,
        onTap: () {
          if (diary.id != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DiaryDetailPage(diary: diary),
              ),
            );
          }
        },
      ),
    );
  }
}

/// TabBar代理
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: tabBar);
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
