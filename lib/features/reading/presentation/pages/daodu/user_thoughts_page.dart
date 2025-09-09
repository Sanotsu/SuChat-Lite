import 'package:flutter/material.dart';

import '../../../data/models/daodu_models.dart';
import '../../../data/datasources/reading_api_manager.dart';
import '../../widgets/daodu/user_content_list_page.dart';
import '../../widgets/daodu/user_thought_card.dart';

/// 用户想法列表页面
class DaoduUserThoughtsPage extends StatelessWidget {
  final String userId;
  final String userName;

  const DaoduUserThoughtsPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final apiManager = ReadingApiManager();

    return DaoduUserContentListPage<DaoduUserThoughtsProfile>(
      userId: userId,
      userName: userName,
      title: '$userName 的想法',
      emptyMessage: '暂无想法',
      emptyIcon: Icons.lightbulb_outline,
      loadDataFunction: apiManager.getDaoduUserThoughtsProfileList,
      itemBuilder: (thought) => DaoduUserThoughtCard(thought: thought),
    );
  }
}
