import 'package:flutter/material.dart';

import '../../../../../../shared/widgets/common_error_empty_widgets.dart';
import '../../../../data/datasources/one_api_manager.dart';
import '../../../../data/models/one/one_base_models.dart';
import '../../../widgets/one/category_cards/author_card.dart';
import 'author_detail_page.dart';

/// 作者列表页面
class AuthorListPage extends StatefulWidget {
  const AuthorListPage({super.key});

  @override
  State<AuthorListPage> createState() => _AuthorListPageState();
}

class _AuthorListPageState extends State<AuthorListPage> {
  final OneApiManager _apiManager = OneApiManager();

  List<OneAuthor> _authorList = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAuthorList();
  }

  Future<void> _loadAuthorList() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authors = await _apiManager.getOneHotAuthorList();
      if (mounted) {
        setState(() {
          _authorList = authors;
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
      return buildCommonErrorWidget(error: _error, onRetry: _loadAuthorList);
    }

    if (_authorList.isEmpty) {
      return buildCommonEmptyWidget(
        icon: Icons.person,
        message: '暂无作者内容',
        subMessage: '请稍后再试',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAuthorList,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _authorList.length,
        itemBuilder: (context, index) {
          final author = _authorList[index];
          return OneAuthorCard(
            author: author,
            onTap: () => _navigateToAuthorDetail(author),
          );
        },
      ),
    );
  }

  void _navigateToAuthorDetail(OneAuthor author) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AuthorDetailPage(author: author)),
    );
  }
}
