import 'package:flutter/material.dart';

import '../../../data/datasources/haokan/haokan_api_manager.dart';
import '../../../data/models/haokan/haokan_models.dart';
import '../../widgets/haokan/haokan_comment_item.dart';

/// 好看漫画评论页面
class HaokanCommentPage extends StatefulWidget {
  final int comicId;

  const HaokanCommentPage({super.key, required this.comicId});

  @override
  State<HaokanCommentPage> createState() => _HaokanCommentPageState();
}

class _HaokanCommentPageState extends State<HaokanCommentPage> {
  final HaokanApiManager _apiManager = HaokanApiManager();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();

  List<HaokanComment> _comments = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  int _currentPage = 1;
  int _totalComments = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadComments(refresh: true);
    _loadCommentCount();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadComments();
      }
    }
  }

  Future<void> _loadComments({bool refresh = false}) async {
    if (_isLoading) return;

    try {
      setState(() {
        _isLoading = true;
        if (refresh) {
          _currentPage = 1;
          _comments.clear();
          _hasMore = true;
          _error = null;
        }
      });

      final data = await _apiManager.getHaokanComicCommentList(
        comicId: widget.comicId,
        page: _currentPage,
        size: 20,
      );

      setState(() {
        if (refresh) {
          _comments = data;
        } else {
          _comments.addAll(data);
        }
        _currentPage++;
        _hasMore = data.length >= 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCommentCount() async {
    try {
      final count = await _apiManager.getHaokanComicCommentCount(
        comicId: widget.comicId,
      );

      setState(() {
        _totalComments = count;
      });
    } catch (e) {
      // 忽略错误，不影响主要功能
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('评论 ${_totalComments > 0 ? '($_totalComments)' : ''}'),
        backgroundColor: Colors.pink[100],
      ),
      body: Column(
        children: [
          // 评论列表
          Expanded(child: _buildCommentsList()),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    if (_isLoading && _comments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('加载失败: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadComments(refresh: true),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('暂无评论'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadComments(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _comments.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _comments.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          return HaokanCommentItem(comment: _comments[index]);
        },
      ),
    );
  }
}
