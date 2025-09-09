import 'package:flutter/material.dart';

import '../../../../../../shared/widgets/common_error_empty_widgets.dart';
import '../../../../data/datasources/one_api_manager.dart';
import '../../../../data/models/one/one_category_list.dart';
import '../../../widgets/one/category_cards/diary_card.dart';
import 'diary_detail_page.dart';

/// 小记列表页面
class DiaryListPage extends StatefulWidget {
  const DiaryListPage({super.key});

  @override
  State<DiaryListPage> createState() => _DiaryListPageState();
}

class _DiaryListPageState extends State<DiaryListPage> {
  final OneApiManager _apiManager = OneApiManager();

  final List<OneDiary> _allDiaryList = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _loadInitialDiaryList();
  }

  Future<void> _loadInitialDiaryList() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _allDiaryList.clear();
    });

    try {
      final diaryList = await _apiManager.getOneDiaryList(diaryId: 0);

      if (mounted) {
        setState(() {
          _allDiaryList.addAll(diaryList);
          _isLoading = false;
          _hasMoreData = diaryList.isNotEmpty;
        });
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

  Future<void> _loadMoreDiaryList() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final diaryList = await _apiManager.getOneDiaryList(
        diaryId: int.tryParse(_allDiaryList.last.id ?? '0') ?? 0,
      );

      if (mounted) {
        setState(() {
          _allDiaryList.addAll(diaryList);
          _isLoadingMore = false;
          _hasMoreData = diaryList.isNotEmpty;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return buildCommonErrorWidget(
        error: _error,
        onRetry: _loadInitialDiaryList,
      );
    }

    if (_allDiaryList.isEmpty) {
      return buildCommonEmptyWidget(
        icon: Icons.book,
        message: '暂无连载内容',
        subMessage: '请稍后重试',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInitialDiaryList,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo is ScrollEndNotification &&
              scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
              !_isLoadingMore &&
              _hasMoreData) {
            _loadMoreDiaryList();
          }
          return false;
        },
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3 / 5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _allDiaryList.length + (_hasMoreData ? 1 : 0),
          itemBuilder: (context, index) {
            // 处理加载更多指示器
            if (index == _allDiaryList.length) {
              return _buildLoadingMoreWidget();
            }
            // 处理没有更多数据的提示
            if (!_hasMoreData && index == _allDiaryList.length) {
              return _buildNoMoreDataWidget();
            }
            // 类型是 OneDiary，且没有小记详情，查询小记列表就包含所有内容了
            final diary = _allDiaryList[index];
            return OneDiaryCard(
              diary: diary,
              onTap: () => _navigateToDiaryDetail(diary),
            );
          },
        ),
        // child:  ListView.builder(
        //   itemCount: _allDiaryList.length + (_hasMoreData ? 1 : 0),
        //   itemBuilder: (context, index) {
        //     // 处理加载更多指示器
        //     if (index == _allDiaryList.length) {
        //       return _buildLoadingMoreWidget();
        //     }

        //     // 处理没有更多数据的提示
        //     if (!_hasMoreData && index == _allDiaryList.length) {
        //       return _buildNoMoreDataWidget();
        //     }

        //     // 类型是 OneDiary，且没有小记详情，查询小记列表就包含所有内容了
        //     final diary = _allDiaryList[index];

        //     return DiaryCard(
        //       diary: diary,
        //       onTap: () => _navigateToDiaryDetail(diary),
        //     );
        //   },
        // ),
      ),
    );
  }

  Widget _buildLoadingMoreWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildNoMoreDataWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          '没有更多数据了',
          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
        ),
      ),
    );
  }

  // 注意，小记没有详情，所以需要一个单独的小记详情页面
  void _navigateToDiaryDetail(OneDiary diary) {
    if (diary.id != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DiaryDetailPage(diary: diary)),
      );
    }
  }
}
