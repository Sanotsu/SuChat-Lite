import 'package:flutter/material.dart';

import '../../../data/models/daodu_models.dart';
import '../../../data/datasources/reading_api_manager.dart';
import '../../widgets/daodu/user_content_list_page.dart';
import '../../widgets/daodu/user_snippet_card.dart';

/// 用户摘要列表页面
class DaoduUserSnippetsPage extends StatelessWidget {
  final String userId;
  final String userName;

  const DaoduUserSnippetsPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final apiManager = ReadingApiManager();

    return DaoduUserContentListPage<DaoduUserSnippetsDetail>(
      userId: userId,
      userName: userName,
      title: '$userName 的摘要',
      emptyMessage: '暂无摘要',
      emptyIcon: Icons.note_outlined,
      loadDataFunction: apiManager.getDaoduUserSnippetList,
      itemBuilder: (snippet) => DaoduUserSnippetCard(snippet: snippet),
    );
  }
}
