import 'package:flutter/material.dart';

import '../../../data/models/daodu_models.dart';
import '../../../data/datasources/reading_api_manager.dart';
import '../../widgets/daodu/user_content_list_page.dart';
import '../../widgets/daodu/user_favourite_lesson_card.dart';

/// 用户喜欢文章列表页面
class DaoduUserFavouriteLessonsPage extends StatelessWidget {
  final String userId;
  final String userName;

  const DaoduUserFavouriteLessonsPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final apiManager = ReadingApiManager();

    return DaoduUserContentListPage<DaoduLesson>(
      userId: userId,
      userName: userName,
      title: '$userName 喜欢的文章',
      emptyMessage: '暂无喜欢的文章',
      emptyIcon: Icons.favorite_outline,
      loadDataFunction: apiManager.getDaoduUserFavouriteLessonList,
      itemBuilder: (lesson) => DaoduUserFavouriteLessonCard(lesson: lesson),
    );
  }
}
