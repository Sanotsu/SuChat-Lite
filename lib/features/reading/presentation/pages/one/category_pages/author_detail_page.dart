import 'package:flutter/material.dart';

import '../../../../../../shared/widgets/common_error_empty_widgets.dart';
import '../../../../../../shared/widgets/simple_tool_widget.dart';
import '../../../../data/datasources/one_api_manager.dart';
import '../../../../data/models/one/one_base_models.dart';
import '../../../../data/models/one/one_daily_recommend.dart';
import '../../../../data/models/one/one_enums.dart';
import '../../../widgets/one/recommend_card.dart';
import '../detail_page.dart';

/// 作者作品页面
class AuthorDetailPage extends StatefulWidget {
  final OneAuthor author;

  const AuthorDetailPage({super.key, required this.author});

  @override
  State<AuthorDetailPage> createState() => _AuthorDetailPageState();
}

class _AuthorDetailPageState extends State<AuthorDetailPage> {
  final OneApiManager _apiManager = OneApiManager();

  List<OneRecommendContent> _worksList = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadAuthorWorks();
  }

  Future<void> _loadAuthorWorks() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 0;
      _hasMore = true;
    });

    try {
      final works = await _apiManager.getOneAuthorContentList(
        authorId: int.tryParse(widget.author.userId?.toString() ?? '') ?? 0,
        pageNum: _currentPage,
        forceRefresh: true,
      );

      if (mounted) {
        setState(() {
          _worksList = works;
          _hasMore = works.isNotEmpty;
          _currentPage++;
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

  Future<void> _loadMoreAuthorWorks() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final works = await _apiManager.getOneAuthorContentList(
        authorId: int.tryParse(widget.author.userId?.toString() ?? '') ?? 0,
        pageNum: _currentPage,
      );

      if (mounted) {
        setState(() {
          _worksList.addAll(works);
          _hasMore = works.isNotEmpty;
          _currentPage++;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.author.userName ?? '作者作品'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // 因为作者信息比较长，如果固定上方，可滚动的列表区域就很少了
      // body: Column(
      //   children: [
      //     // 作者信息头部
      //     _buildAuthorHeader(),
      //     // 作品列表
      //     Expanded(child: _buildWorksList()),
      //   ],
      // ),
      body: _buildWorksList(),
    );
  }

  Widget _buildAuthorHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像
          Center(
            child: buildUserCircleAvatar(widget.author.webUrl, radius: 32),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              widget.author.userName ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          if (widget.author.desc != null)
            Text(
              widget.author.desc!,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }

  Widget _buildWorksList() {
    if (_isLoading && _worksList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _worksList.isEmpty) {
      return buildCommonErrorWidget(error: _error, onRetry: _loadAuthorWorks);
    }

    if (_worksList.isEmpty) {
      return buildCommonEmptyWidget(
        icon: Icons.article,
        message: '暂无作品',
        subMessage: '该作者还没有发布作品',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAuthorWorks,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo is ScrollEndNotification &&
              scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
              !_isLoadingMore &&
              _hasMore) {
            _loadMoreAuthorWorks();
          }
          return false;
        },
        child: ListView.builder(
          // shrinkWrap: true,
          // physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          // 中间的+1是作者信息区域，最后一个+1是加载更多
          itemCount: _worksList.length + 1 + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            // 第一个默认是用户信息
            if (index == 0) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: _buildAuthorHeader(),
              );
            }

            // 最后一个默认是加载更多
            if (index == _worksList.length + 1) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // 中间的才是正常的响应结果(因为第一个被作者信息占据，所以需要-1)
            final work = _worksList[index - 1];

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: OneRecommendCard(
                content: work,
                onTap: () => _navigateToWorkDetail(work),
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigateToWorkDetail(OneRecommendContent work) {
    // 使用枚举映射正确的分类
    final category = work.category ?? '1';
    final apiCategory = OneCategory.getApiName(category);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OneDetailPage(
          contentType: apiCategory,
          // 作者应该没有hp分类，不用考传日期
          contentId: work.itemId ?? work.contentId ?? '',
          title: work.title ?? '',
        ),
      ),
    );
  }
}
