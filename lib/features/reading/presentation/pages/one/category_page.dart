import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

import '../../../../../shared/constants/constants.dart';
import '../../../../../shared/widgets/common_error_empty_widgets.dart';
import '../../../data/models/one/one_category_list.dart';
import '../../../data/models/one/one_enums.dart';
import '../../../data/datasources/one_api_manager.dart';
import '../../widgets/one/content_card.dart';
import 'category_pages/diary_list_page.dart';
import 'category_pages/topic_list_page.dart';
import 'category_pages/author_list_page.dart';
import 'category_pages/rank_list_page.dart';
import 'category_pages/serial_list_page.dart';
import 'detail_page.dart';
import 'search_page.dart';

/// ONE分类页面
class OneCategoryPage extends StatefulWidget {
  const OneCategoryPage({super.key});

  @override
  State<OneCategoryPage> createState() => _OneCategoryPageState();
}

class _OneCategoryPageState extends State<OneCategoryPage>
    with SingleTickerProviderStateMixin {
  final OneApiManager _apiManager = OneApiManager();
  late TabController _tabController;

  // 数据状态
  bool _isLoading = false;
  String? _error;

  // 不同分类的数据存储
  List<OneContent> _hpList = [];
  List<OneContent> _essayList = [];
  List<OneContent> _questionList = [];
  List<OneContent> _movieList = [];
  List<OneContent> _musicList = [];

  // 当前选择的月份和年份
  DateTime _selectedMonth = DateTime.now();

  // 分类标签
  final List<Map<String, dynamic>> _categories = [
    // 不按照原版设计，把有二级菜单的统一放在后面
    {'name': '图文', 'key': 'hp', 'icon': Icons.image, 'category': 0},
    {'name': '阅读', 'key': 'essay', 'icon': Icons.article, 'category': 1},
    {'name': '问答', 'key': 'question', 'icon': Icons.help, 'category': 3},
    {'name': '书影', 'key': 'movie', 'icon': Icons.movie, 'category': 5},
    {'name': '音乐', 'key': 'music', 'icon': Icons.audio_file, 'category': 4},
    // 小记虽然没有二级菜单，但是没有按月查询而是分页查询(会类似二级菜单的处理)
    {'name': '小记', 'key': 'diary', 'icon': Icons.square, 'category': -1},
    // 有二级菜单
    {'name': '专题', 'key': 'topic', 'icon': Icons.topic, 'category': -1},
    {'name': '热榜', 'key': 'hot', 'icon': Icons.whatshot, 'category': -2},
    {'name': '长篇', 'key': 'serial', 'icon': Icons.book, 'category': -3},
    {'name': '作者', 'key': 'author', 'icon': Icons.person, 'category': -4},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        // 只有在索引变化稳定后才执行某些操作
        // print('Current index is: ${_tabController.index}');
        // 例如：根据 index 更新其他状态
        setState(() {
          // 更新依赖于当前 Tab Index 的状态
        });
      }
    });

    _loadCategoryContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 加载分类内容
  Future<void> _loadCategoryContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.wait([
        _loadHpContent(),
        _loadEssayContent(),
        _loadQuestionContent(),
        _loadMovieContent(),
        _loadMusicContent(),
      ]);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
      rethrow;
    }
  }

  /// 加载阅读内容
  Future<void> _loadEssayContent() async {
    try {
      final essays = await _apiManager.getOneContentListByMonth(
        category: 1,
        month: formatSelectedMonth(),
      );
      if (mounted) {
        setState(() {
          _essayList = essays;
        });
      }
    } catch (e) {
      debugPrint('加载阅读内容失败: $e');
      rethrow;
    }
  }

  /// 加载日签内容
  Future<void> _loadHpContent() async {
    try {
      final hps = await _apiManager.getOneContentListByMonth(
        category: 0,
        month: formatSelectedMonth(),
      );
      if (mounted) {
        setState(() {
          _hpList = hps;
        });
      }
    } catch (e) {
      debugPrint('加载日签内容失败: $e');
      rethrow;
    }
  }

  /// 加载问答内容
  Future<void> _loadQuestionContent() async {
    try {
      final questions = await _apiManager.getOneContentListByMonth(
        category: 3,
        month: formatSelectedMonth(),
      );
      if (mounted) {
        setState(() {
          _questionList = questions;
        });
      }
    } catch (e) {
      debugPrint('加载问答内容失败: $e');
      rethrow;
    }
  }

  /// 加载书影内容
  Future<void> _loadMovieContent() async {
    try {
      final movies = await _apiManager.getOneContentListByMonth(
        category: 5,
        month: formatSelectedMonth(),
      );
      if (mounted) {
        setState(() {
          _movieList = movies;
        });
      }
    } catch (e) {
      debugPrint('加载书影内容失败: $e');
      rethrow;
    }
  }

  /// 加载音乐内容
  Future<void> _loadMusicContent() async {
    try {
      final musics = await _apiManager.getOneContentListByMonth(
        category: 4,
        month: formatSelectedMonth(),
      );
      if (mounted) {
        setState(() {
          _musicList = musics;
        });
      }
    } catch (e) {
      debugPrint('加载音乐内容失败: $e');
      rethrow;
    }
  }

  // 月份弹窗回调函数
  Future<void> _selectMonth() async {
    final DateTime? picked = await showMonthPicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = picked;
      });

      await _loadCategoryContent();
    }
  }

  // 格式化选择的月份为字符串
  String formatSelectedMonth() => DateFormat(formatToYM).format(_selectedMonth);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分类'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OneSearchPage()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _categories
              .map((category) => Tab(text: category['name']))
              .toList(),
        ),
      ),
      body: Column(
        children: [
          // Text(_tabController.index.toString()),

          // 月份选择器
          // 根据顶部TabBar的index来判断是否显示月份选择器，小记及需要二级菜单的，不显示月份选择器
          if (_tabController.index <= 4) _buildMonthSelector(),

          // 分类内容
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((category) {
                switch (category['key']) {
                  case 'hp':
                    return _buildHpTab();
                  case 'essay':
                    return _buildEssayTab();
                  case 'question':
                    return _buildQuestionTab();
                  case 'movie':
                    return _buildMovieTab();
                  case 'music':
                    return _buildMusicTab();
                  case 'diary':
                    return DiaryListPage();
                  case 'topic':
                    return TopicListPage();
                  case 'hot':
                    return RankListPage();
                  case 'serial':
                    return SerialListPage();
                  case 'author':
                    return AuthorListPage();
                  default:
                    return _buildEmptyWidget(category['key']);
                }
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建月份选择器
  Widget _buildMonthSelector() {
    return Container(
      height: 48,
      // padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: GestureDetector(
        onTap: _selectMonth,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              formatSelectedMonth(),
              style: const TextStyle(
                fontSize: 18,
                color: Colors.lightBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.calendar_today, color: Colors.lightBlue, size: 16),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  /// 构建日签标签页
  Widget _buildHpTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return buildCommonErrorWidget(
        error: _error,
        onRetry: _loadCategoryContent,
      );
    }

    if (_hpList.isEmpty) {
      return _buildEmptyWidget('hp');
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _hpList.length,
      itemBuilder: (context, index) {
        final hp = _hpList[index];

        return OneContentCard(
          content: hp,
          onTap: () => _navigateToDetail(hp),
          displayType: 'grid',
          miniGrid: true,
        );
      },
    );
  }

  /// 构建阅读标签页
  Widget _buildEssayTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return buildCommonErrorWidget(
        error: _error,
        onRetry: _loadCategoryContent,
      );
    }

    if (_essayList.isEmpty) {
      return _buildEmptyWidget('essay');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _essayList.length,
      itemBuilder: (context, index) {
        final content = _essayList[index];
        return OneContentCard(
          content: content,
          onTap: () => _navigateToDetail(content),
        );
      },
    );
  }

  /// 构建问答标签页
  Widget _buildQuestionTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return buildCommonErrorWidget(
        error: _error,
        onRetry: _loadCategoryContent,
      );
    }

    if (_questionList.isEmpty) {
      return _buildEmptyWidget('question');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _questionList.length,
      itemBuilder: (context, index) {
        final content = _questionList[index];
        return OneContentCard(
          content: content,
          onTap: () => _navigateToDetail(content),
        );
      },
    );
  }

  /// 构建书影标签页
  Widget _buildMovieTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return buildCommonErrorWidget(
        error: _error,
        onRetry: _loadCategoryContent,
      );
    }

    if (_movieList.isEmpty) {
      return _buildEmptyWidget('movie');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _movieList.length,
      itemBuilder: (context, index) {
        final movie = _movieList[index];
        return OneContentCard(
          content: movie,
          onTap: () => _navigateToDetail(movie),
        );
      },
    );
  }

  /// 构建音乐标签页
  Widget _buildMusicTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return buildCommonErrorWidget(
        error: _error,
        onRetry: _loadCategoryContent,
      );
    }

    if (_musicList.isEmpty) {
      return _buildEmptyWidget('music');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _musicList.length,
      itemBuilder: (context, index) {
        final music = _musicList[index];
        return OneContentCard(
          content: music,
          onTap: () => _navigateToDetail(music),
        );
      },
    );
  }

  /// 导航到内容详情
  /// 在本页面查询的图文、阅读、问答、书影、音乐，返回都是OneContent
  /// 可以直接跳转到OneDetailPage详情页
  void _navigateToDetail(OneContent content) {
    // 使用枚举映射正确的分类
    final category = (content.category ?? '1').toString();
    final apiCategory = OneCategory.getApiName(category);

    final date =
        DateTime.tryParse(content.maketime ?? content.date ?? '') ??
        DateTime.now();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OneDetailPage(
          contentType: apiCategory,
          // 如果分类是图片hp，需要按日期查询
          contentId: apiCategory == "hp"
              ? DateFormat(formatToYMD).format(date)
              // 只有搜索结果的OneContent才使用contentId字段，其他都是用id
              : (content.id ?? content.contentId ?? '').toString(),
          title: content.title ?? '',
        ),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyWidget(String categoryKey) {
    final categoryName = _categories.firstWhere(
      (cat) => cat['key'] == categoryKey,
      orElse: () => {'name': '内容'},
    )['name'];

    return buildCommonEmptyWidget(
      icon: Icons.inbox,
      message: '暂无$categoryName内容',
      subMessage: '请选择其他月份或分类',
    );
  }
}
