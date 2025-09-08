import 'package:flutter/material.dart';

import '../../../../../../shared/widgets/common_error_empty_widgets.dart';
import '../../../../data/datasources/one_api_manager.dart';
import '../../../../data/models/one/one_category_list.dart';
import '../../../../data/models/one/one_enums.dart';
import '../../../widgets/one/content_card.dart';
import '../detail_page.dart';

/// 榜单详情页面
class RankDetailPage extends StatefulWidget {
  final OneRank rank;

  const RankDetailPage({super.key, required this.rank});

  @override
  State<RankDetailPage> createState() => _RankDetailPageState();
}

class _RankDetailPageState extends State<RankDetailPage> {
  final OneApiManager _apiManager = OneApiManager();

  List<OneContent> _contentList = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRankContent();
  }

  Future<void> _loadRankContent() async {
    if (widget.rank.id == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final contents = await _apiManager.getOneRankContentList(
        id: widget.rank.id!,
      );
      if (mounted) {
        setState(() {
          _contentList = contents;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.rank.title ?? '榜单详情'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return buildCommonErrorWidget(error: _error, onRetry: _loadRankContent);
    }

    if (_contentList.isEmpty) {
      return buildCommonEmptyWidget(
        icon: Icons.list,
        message: '暂无内容',
        subMessage: '该榜单暂时没有内容',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRankContent,
      child: ListView.builder(
        itemCount: _contentList.length,
        itemBuilder: (context, index) {
          final content = _contentList[index];
          return OneContentCard(
            content: content,
            miniList: true,
            onTap: () => _navigateToContentDetail(content),
          );
        },
      ),
    );
  }

  void _navigateToContentDetail(OneContent content) {
    final category = (content.category ?? 1).toString();
    final apiCategory = OneCategory.getApiName(category);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OneDetailPage(
          contentType: apiCategory,
          contentId: (content.id ?? content.contentId ?? '').toString(),
          title: content.title ?? '',
        ),
      ),
    );
  }
}
