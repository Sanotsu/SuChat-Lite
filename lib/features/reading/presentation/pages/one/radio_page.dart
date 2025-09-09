import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../shared/constants/constants.dart';
import '../../../../../shared/widgets/common_error_empty_widgets.dart';
import '../../../data/datasources/one_api_manager.dart';
import '../../../data/models/one/one_category_list.dart';
import '../../widgets/one/content_card.dart';
import 'detail_page.dart';

/// One收音机页面
class OneRadioPage extends StatefulWidget {
  const OneRadioPage({super.key});

  @override
  State<OneRadioPage> createState() => _OneRadioPageState();
}

class _OneRadioPageState extends State<OneRadioPage> {
  final OneApiManager _apiManager = OneApiManager();
  final ScrollController _scrollController = ScrollController();

  // 数据状态
  bool _isLoading = false;
  String? _error;
  List<OneContent> _radioContents = [];

  // 分页参数
  final DateTime _currentDate = DateTime.now();
  int _loadedMonth = 0;
  // 每次加载2个月的数据
  final int _monthSize = 2;

  @override
  void initState() {
    super.initState();
    _loadRadioContents();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 设置滚动监听
  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreRadioContents();
      }
    });
  }

  /// 加载收音机内容
  Future<void> _loadRadioContents() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final contents = <OneContent>[];

      // 加载最近几个月的推荐内容，筛选出收音机内容
      for (int i = 0; i < _monthSize; i++) {
        final date = _currentDate.subtract(Duration(days: i * 30));
        final dateStr = DateFormat(formatToYM).format(date);

        try {
          final radioItems = await _apiManager.getOneContentListByMonth(
            category: 8,
            month: dateStr,
          );
          contents.addAll(radioItems);
        } catch (e) {
          // 某一天的数据加载失败不影响其他天
          debugPrint('无法加载 $dateStr 的电台内容: $e');
        }
      }

      if (mounted) {
        setState(() {
          _radioContents = contents;
          _loadedMonth = _monthSize;
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

  /// 加载更多收音机内容
  Future<void> _loadMoreRadioContents() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final contents = <OneContent>[];

      // 加载更早的日期
      for (int i = _loadedMonth; i < _loadedMonth + _monthSize; i++) {
        final date = _currentDate.subtract(Duration(days: i * 30));
        final dateStr = DateFormat(formatToYM).format(date);

        try {
          final radioItems = await _apiManager.getOneContentListByMonth(
            category: 8,
            month: dateStr,
          );

          contents.addAll(radioItems);
        } catch (e) {
          debugPrint('无法加载 $dateStr 的电台内容: $e');
        }
      }

      if (mounted) {
        setState(() {
          _radioContents.addAll(contents);
          _loadedMonth += _monthSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 导航到详情页面
  void _navigateToDetail(OneContent content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OneDetailPage(
          contentType: 'radio',
          contentId: (content.id ?? content.contentId ?? '').toString(),
          title: content.title ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('收音机'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading && _radioContents.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _radioContents.isEmpty
          ? buildCommonErrorWidget(error: _error, onRetry: _loadRadioContents)
          : _buildRadioList(),
    );
  }

  /// 构建收音机列表
  Widget _buildRadioList() {
    if (_radioContents.isEmpty) {
      return const Center(
        child: Text('暂无收音机内容', style: TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadedMonth = 0;
        await _loadRadioContents();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _radioContents.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _radioContents.length) {
            // 加载更多指示器
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final content = _radioContents[index];
          return Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: OneContentCard(
              content: content,
              onTap: () => _navigateToDetail(content),
              displayType: 'grid',
            ),
          );

          // return Container(
          //   margin: const EdgeInsets.only(bottom: 16),
          //   child: _buildRadioCard(content),
          // );
        },
      ),
    );
  }
}
