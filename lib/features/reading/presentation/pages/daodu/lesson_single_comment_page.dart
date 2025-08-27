import 'package:flutter/material.dart';

import '../../../data/models/daodu_models.dart';
import '../../../data/datasources/reading_api_manager.dart';
import '../../widgets/daodu/comment_info_card.dart';
import '../../widgets/daodu/lesson_info_card.dart';

/// 单条评论详情页面
class LessonSingleCommentPage extends StatefulWidget {
  final DaoduComment comment;

  const LessonSingleCommentPage({super.key, required this.comment});

  @override
  State<LessonSingleCommentPage> createState() =>
      _LessonSingleCommentPageState();
}

class _LessonSingleCommentPageState extends State<LessonSingleCommentPage> {
  final ReadingApiManager _apiManager = ReadingApiManager();
  DaoduLesson? _lessonInfo; // 相关文章信息
  bool _isLoadingLesson = true;
  String? _lessonError;

  @override
  void initState() {
    super.initState();
    _loadLessonInfo();
  }

  /// 加载相关文章信息
  Future<void> _loadLessonInfo() async {
    if (widget.comment.lessonId == null) {
      setState(() {
        _isLoadingLesson = false;
        _lessonError = '无法获取文章信息';
      });
      return;
    }

    try {
      setState(() {
        _isLoadingLesson = true;
        _lessonError = null;
      });

      final lesson = await _apiManager.getDaoduLessonDetail(
        id: widget.comment.lessonId!,
        forceRefresh: false,
      );

      setState(() {
        _lessonInfo = lesson;
        _isLoadingLesson = false;
      });
    } catch (e) {
      setState(() {
        _lessonError = '加载文章信息失败: $e';
        _isLoadingLesson = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('评论详情')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 相关文章信息卡片
            LessonInfoCard(
              isLoading: _isLoadingLesson,
              errorMessage: _lessonError,
              lessonInfo: _lessonInfo,
            ),

            const SizedBox(height: 16),

            // 评论详情卡片
            CommentInfoCard(
              comment: widget.comment,
              cardTitle: '评论内容',
              isExpandable: false,
            ),
          ],
        ),
      ),
    );
  }
}
