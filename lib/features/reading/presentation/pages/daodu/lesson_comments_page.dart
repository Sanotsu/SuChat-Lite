import 'package:flutter/material.dart';

import '../../../../../shared/widgets/toast_utils.dart';
import '../../../data/models/daodu_models.dart';
import '../../../data/datasources/reading_api_manager.dart';
import '../../widgets/daodu/comment_card.dart';
import '../../widgets/daodu/lesson_info_card.dart';

/// 文章评论列表页面
class DaoduLessonCommentsPage extends StatefulWidget {
  final String lessonId;

  const DaoduLessonCommentsPage({super.key, required this.lessonId});

  @override
  State<DaoduLessonCommentsPage> createState() =>
      _DaoduLessonCommentsPageState();
}

class _DaoduLessonCommentsPageState extends State<DaoduLessonCommentsPage> {
  final ReadingApiManager _apiManager = ReadingApiManager();
  List<DaoduComment> _comments = [];
  DaoduLesson? _lessonInfo;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 加载数据（文章信息和评论列表）
  Future<void> _loadData() async {
    await Future.wait([_loadLessonInfo(), _loadComments()]);
  }

  /// 加载文章信息
  Future<void> _loadLessonInfo() async {
    try {
      final lesson = await _apiManager.getDaoduLessonDetail(
        id: widget.lessonId,
      );

      setState(() {
        _lessonInfo = lesson;
      });
    } catch (e) {
      // 文章信息加载失败不影响评论显示
      ToastUtils.showError('加载文章信息失败: $e');
    }
  }

  /// 加载评论列表
  Future<void> _loadComments() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // 获取文章统计信息
      final stats = await _apiManager.getDaoduLessonActivityStats(
        id: widget.lessonId,
      );

      // 一次性获取所有评论
      final comments = await _apiManager.getDaoduLessonCommentList(
        id: widget.lessonId,
        limit: stats.commentCount ?? 10,
        offset: 0,
      );

      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('评论 (${_comments.length})')),
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
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadComments, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.comment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '暂无评论',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadComments,
      child: Column(
        children: [
          // 文章信息卡片
          if (_lessonInfo != null)
            DaoduLessonInfoCard(
              isLoading: _isLoading,
              errorMessage: _error,
              lessonInfo: _lessonInfo,
            ),

          // 评论列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(4),
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                return DaoduCommentCard(
                  comment: _comments[index],
                  isExpandable: true,
                  maxLines: 3,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
