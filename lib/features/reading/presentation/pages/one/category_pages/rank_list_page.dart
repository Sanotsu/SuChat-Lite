import 'package:flutter/material.dart';

import '../../../../../../shared/widgets/common_error_empty_widgets.dart';
import '../../../../data/datasources/one_api_manager.dart';
import '../../../../data/models/one/one_category_list.dart';
import '../../../widgets/one/category_cards/rank_card.dart';
import 'rank_detail_page.dart';

/// 热榜列表页面
class RankListPage extends StatefulWidget {
  const RankListPage({super.key});

  @override
  State<RankListPage> createState() => _RankListPageState();
}

class _RankListPageState extends State<RankListPage> {
  final OneApiManager _apiManager = OneApiManager();

  List<OneRank> _rankList = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRankList();
  }

  Future<void> _loadRankList() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ranks = await _apiManager.getOneRankList();
      if (mounted) {
        setState(() {
          _rankList = ranks;
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
      return buildCommonErrorWidget(error: _error, onRetry: _loadRankList);
    }

    if (_rankList.isEmpty) {
      return buildCommonEmptyWidget(
        icon: Icons.whatshot,
        message: '暂无热榜内容',
        subMessage: '请稍后再试',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRankList,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rankList.length,
        itemBuilder: (context, index) {
          final rank = _rankList[index];
          return OneRankCard(
            rank: rank,
            onTap: () => _navigateToRankDetail(rank),
            onViewAll: () => _navigateToRankDetail(rank),
          );
        },
      ),
    );
  }

  void _navigateToRankDetail(OneRank rank) {
    if (rank.id != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RankDetailPage(rank: rank)),
      );
    }
  }
}
