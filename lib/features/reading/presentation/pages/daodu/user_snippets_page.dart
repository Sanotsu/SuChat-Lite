import 'package:flutter/material.dart';

import '../../../data/models/daodu_models.dart';
import '../../../data/datasources/reading_api_manager.dart';
import '../../widgets/daodu/user_content_list_page.dart';
import '../../widgets/daodu/user_snippet_card.dart';

/// 用户摘要列表页面
class UserSnippetsPage extends StatelessWidget {
  final String userId;
  final String userName;

  const UserSnippetsPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final apiManager = ReadingApiManager();

    return UserContentListPage<DaoduUserSnippetsDetail>(
      userId: userId,
      userName: userName,
      title: '$userName 的摘要',
      emptyMessage: '暂无摘要',
      emptyIcon: Icons.note_outlined,
      loadDataFunction: apiManager.getDaoduUserSnippetList,
      itemBuilder: (snippet) => UserSnippetCard(snippet: snippet),
    );
  }
}
