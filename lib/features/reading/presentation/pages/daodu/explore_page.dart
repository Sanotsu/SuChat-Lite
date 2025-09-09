import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/daodu_models.dart';
import '../../../data/datasources/reading_api_manager.dart';
import '../../widgets/daodu/swipeable_card_widget.dart';

/// 探索页面 - 显示推荐文章和日期筛选
class DaoduExplorePage extends StatefulWidget {
  const DaoduExplorePage({super.key});

  @override
  State<DaoduExplorePage> createState() => _DaoduExplorePageState();
}

class _DaoduExplorePageState extends State<DaoduExplorePage> {
  final ReadingApiManager _apiManager = ReadingApiManager();

  // 数据状态
  DaoduTodayRecommendsResp? _todayRecommends;
  List<DaoduLesson> _lessons = [];
  bool _isLoading = true;
  String? _error;

  // UI状态
  DateTime? _startDate; // 起始日期
  DateTime? _endDate; // 结束日期
  bool _isShowingRecommends = true; // 是否显示推荐列表
  // 如果点击了actions中的快速单个日期查询文章，这个就为true
  // 为true时不显示起止日期范围筛选。但和起止日期筛选共用清除时重置为false
  bool _isSingleMode = false;

  @override
  void initState() {
    super.initState();
    _loadTodayRecommends();
  }

  /// 加载今日推荐列表
  Future<void> _loadTodayRecommends() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _isShowingRecommends = true;
      });

      final recommends = await _apiManager.getDaoduTodayRecommendList();

      setState(() {
        _todayRecommends = recommends;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载推荐失败: $e';
        _isLoading = false;
      });
    }
  }

  /// 根据日期范围加载文章列表
  Future<void> _loadLessonsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _isShowingRecommends = false;
        _startDate = startDate;
        _endDate = endDate;
      });

      // from 和 to 要是yyyyMMdd 格式的int类型
      int from = int.parse(DateFormat("yyyyMMdd").format(startDate));
      int to = int.parse(DateFormat("yyyyMMdd").format(endDate));

      final lessons = await _apiManager.getDaoduLessonList(from: from, to: to);

      setState(() {
        _lessons = lessons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载文章失败: $e';
        _isLoading = false;
      });
    }
  }

  /// 快速选择单日文章
  Future<void> _loadSingleDayLessons(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1, milliseconds: -1));
    await _loadLessonsByDateRange(startOfDay, endOfDay);
  }

  /// 快速选择指定单日日期
  Future<void> _selectSingleDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
    );

    if (picked != null) {
      if (mounted) {
        setState(() {
          _isSingleMode = true;
        });
      }

      await _loadSingleDayLessons(picked);
    }
  }

  /// 选择起始日期
  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
    );

    if (picked != null) {
      if (mounted) {
        setState(() {
          _startDate = picked;
        });
      }
      // 如果已有结束日期，立即加载
      if (_endDate != null) {
        _loadLessonsByDateRange(_startDate!, _endDate!);
      }
    }
  }

  /// 选择结束日期
  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2015),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
    );

    if (picked != null) {
      if (mounted) {
        setState(() {
          _endDate = picked;
        });
      }
      // 如果已有起始日期，立即加载
      if (_startDate != null) {
        _loadLessonsByDateRange(_startDate!, _endDate!);
      }
    }
  }

  /// 清除日期筛选，回到推荐列表
  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _isShowingRecommends = true;
      _isSingleMode = false;
    });
    _loadTodayRecommends();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('探索'),
        actions: [
          // 快速选择今日
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selectSingleDate,
            tooltip: '今日文章',
          ),
        ],
      ),
      body: Column(
        children: [
          // 顶部控制区域
          _buildTopControls(),

          // 内容列表
          Expanded(child: _buildContentList()),
        ],
      ),
    );
  }

  Widget _buildTopControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 当前显示状态
          Row(
            children: [
              Icon(
                _isShowingRecommends ? Icons.recommend : Icons.date_range,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isShowingRecommends ? '今日推荐' : _formatDateRange(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // 清除筛选
              if (!_isShowingRecommends || _isSingleMode)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearDateFilter,
                  tooltip: '显示推荐',
                ),
            ],
          ),
          const SizedBox(height: 8),

          // 操作按钮
          if (!_isSingleMode)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectStartDate,
                    icon: const Icon(Icons.date_range, size: 16),
                    label: Text(
                      _startDate != null ? _formatDate(_startDate!) : '选择起始日期',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(80, 32),
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectEndDate,
                    icon: const Icon(Icons.date_range, size: 16),
                    label: Text(
                      _endDate != null ? _formatDate(_endDate!) : '选择结束日期',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(80, 32),
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildContentList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isShowingRecommends
                  ? _loadTodayRecommends
                  : () {
                      if (_startDate != null && _endDate != null) {
                        _loadLessonsByDateRange(_startDate!, _endDate!);
                      }
                    },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_isShowingRecommends) {
      return _buildRecommendsList();
    } else {
      return _buildLessonsList();
    }
  }

  Widget _buildRecommendsList() {
    if (_todayRecommends == null) {
      return const Center(child: Text('暂无推荐内容'));
    }

    final allItems = <dynamic>[];

    // 添加推荐文章
    if (_todayRecommends!.lessons?.isNotEmpty == true) {
      allItems.addAll(_todayRecommends!.lessons!);
    }

    // 添加热门评论
    if (_todayRecommends!.comments?.isNotEmpty == true) {
      allItems.addAll(_todayRecommends!.comments!);
    }

    if (allItems.isEmpty) {
      return const Center(child: Text('今日暂无推荐内容'));
    }

    return RefreshIndicator(
      onRefresh: _loadTodayRecommends,
      child: DaoduSwipeableCardWidget(
        items: allItems,
        onRefresh: _loadTodayRecommends,
      ),
    );
  }

  Widget _buildLessonsList() {
    if (_lessons.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('该日期暂无文章', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return DaoduSwipeableCardWidget(items: _lessons);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final selectedDay = DateTime(date.year, date.month, date.day);

    if (selectedDay == today) {
      return '今天';
    } else if (selectedDay == yesterday) {
      return '昨天';
    } else {
      return '${date.month}月${date.day}日';
    }
  }

  String _formatDateRange() {
    if (_startDate == null || _endDate == null) {
      return '请选择日期范围';
    }

    final startDay = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
    );
    final endDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);

    if (startDay == endDay) {
      return _formatDate(_startDate!);
    } else {
      return '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}';
    }
  }
}
