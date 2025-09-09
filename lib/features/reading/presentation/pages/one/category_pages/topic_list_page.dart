import 'package:flutter/material.dart';

import '../../../../../../shared/widgets/common_error_empty_widgets.dart';
import '../../../../data/datasources/one_api_manager.dart';
import '../../../../data/models/one/one_category_list.dart';
import '../../../widgets/one/category_cards/topic_card.dart';
import 'topic_detail_page.dart';

/// 专题列表页面
class TopicListPage extends StatefulWidget {
  const TopicListPage({super.key});

  @override
  State<TopicListPage> createState() => _TopicListPageState();
}

class _TopicListPageState extends State<TopicListPage> {
  final OneApiManager _apiManager = OneApiManager();

  List<OneTopic> _topicList = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTopicList();
  }

  Future<void> _loadTopicList() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final topics = await _apiManager.getOneTopicList();
      if (mounted) {
        setState(() {
          _topicList = topics;
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
      return buildCommonErrorWidget(error: _error, onRetry: _loadTopicList);
    }

    if (_topicList.isEmpty) {
      return buildCommonEmptyWidget(
        icon: Icons.menu_book,
        message: '暂无内容',
        subMessage: '该榜单暂时没有内容',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTopicList,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _topicList.length,
        itemBuilder: (context, index) {
          final topic = _topicList[index];
          return OneTopicCard(
            topic: topic,
            onTap: () => _navigateToTopicDetail(topic),
          );
        },
      ),
    );
  }

  void _navigateToTopicDetail(OneTopic topic) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TopicDetailPage(topic: topic)),
    );
  }
}
