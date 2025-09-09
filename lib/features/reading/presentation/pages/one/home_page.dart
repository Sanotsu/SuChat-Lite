import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../shared/constants/constants.dart';
import '../../../../../shared/widgets/common_error_empty_widgets.dart';
import '../../../../../shared/widgets/simple_tool_widget.dart';
import '../../../data/datasources/one_api_manager.dart';
import '../../../data/models/one/one_daily_recommend.dart';
import '../../../data/models/one/one_enums.dart';
import '../../../data/models/one/one_base_models.dart';
import '../../widgets/one/recommend_card.dart';
import 'detail_page.dart';

/// One阅读功能模块首页 - 每日推荐（支持左右滑动切换日期）
class OneHomePage extends StatefulWidget {
  const OneHomePage({super.key});

  @override
  State<OneHomePage> createState() => _OneHomePageState();
}

class _OneHomePageState extends State<OneHomePage>
    with SingleTickerProviderStateMixin {
  final OneApiManager _apiManager = OneApiManager();

  // 数据状态
  bool _isLoading = false;
  String? _error;
  OneRecommend? _currentRecommend;

  // 当前选择的日期
  DateTime _selectedDate = DateTime.now();
  final int _maxDaysBack = 365; // 最多可以查看过去365天的内容

  @override
  void initState() {
    super.initState();
    _loadRecommendData();
  }

  /// 加载推荐内容
  Future<void> _loadRecommendData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dateStr = DateFormat(formatToYMD).format(_selectedDate);
      final recommend = await _apiManager.getOneRecommend(date: dateStr);

      if (mounted) {
        setState(() {
          _currentRecommend = recommend;
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
      rethrow;
    }
  }

  /// 切换到前一天
  void _goToPreviousDay() {
    final previousDay = _selectedDate.subtract(const Duration(days: 1));
    final today = DateTime.now();
    final earliestDate = today.subtract(Duration(days: _maxDaysBack));

    // 检查是否超过最早日期
    if (previousDay.isBefore(earliestDate)) {
      return;
    }

    setState(() {
      _selectedDate = previousDay;
    });
    _loadRecommendData();
  }

  /// 切换到后一天
  void _goToNextDay() {
    final nextDay = _selectedDate.add(const Duration(days: 1));

    // 检查是否超过今天
    if (nextDay.isAfter(DateTime.now())) {
      return;
    }

    setState(() {
      _selectedDate = nextDay;
    });
    _loadRecommendData();
  }

  /// 切换到指定日期
  void _selectDate(DateTime date) {
    // 不能选择未来的日期
    final today = DateTime.now();
    if (date.isAfter(DateTime(today.year, today.month, today.day))) {
      return;
    }

    // 限制不能选择太久以前的日期
    final earliestDate = today.subtract(Duration(days: _maxDaysBack));
    if (date.isBefore(earliestDate)) {
      return;
    }

    setState(() {
      _selectedDate = date;
    });

    _loadRecommendData();
  }

  /// 导航到内容详情
  void _navigateToDetail(OneRecommendContent content) {
    // 使用枚举映射正确的分类
    final category = content.category ?? '1';
    final apiCategory = OneCategory.getApiName(category);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OneDetailPage(
          contentType: apiCategory,
          // 如果分类是图片hp，需要按日期查询
          contentId: apiCategory == "hp"
              ? DateFormat(formatToYMD).format(_selectedDate)
              : content.itemId ?? content.contentId ?? '',
          title: content.title ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ONE·一个'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          buildInfoButtonOnAction(
            context,
            "数据来源: 第三方 [ONE·一个](https://one-api.netstart.cn) API\n\n复杂生活的简单享受，为你提供每日精选的文字、图片和音乐。",
          ),
        ],
      ),
      body: Column(
        children: [
          // 顶部日期显示
          _buildTopDateHeader(),

          // 内容区域 - 支持左右滑动切换日期
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? buildCommonErrorWidget(
                    error: _error,
                    onRetry: _loadRecommendData,
                  )
                : _buildSwipeableContent(),
          ),
        ],
      ),
    );
  }

  /// 构建顶部日期头部
  Widget _buildTopDateHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _showDatePicker,
            child: Row(
              children: [
                Text(
                  DateFormat('MM月dd日').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.calendar_today, size: 16),
              ],
            ),
          ),
          if (_currentRecommend?.menu?.vol != null)
            Text(
              'VOL.${_currentRecommend!.menu!.vol}',
              style: const TextStyle(fontSize: 14),
            ),
        ],
      ),
    );
  }

  /// 显示日期选择器
  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2012, 10, 1), // ONE·一个的开始时间
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
    );
    if (picked != null) {
      _selectDate(picked);
    }
  }

  /// 构建可滑动的内容区域
  Widget _buildSwipeableContent() {
    if (_currentRecommend == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // 滑动速度阈值，避免轻微滑动触发
        if (details.primaryVelocity!.abs() < 500) return;

        if (details.primaryVelocity! > 0) {
          // 右滑，查看后一天
          _goToNextDay();
        } else {
          // 左滑，查看前一天
          _goToPreviousDay();
        }
      },
      child: _buildRecommendContent(_currentRecommend!),
    );
  }

  /// 构建天气信息卡片
  Widget _buildSimpleWeatherInfo(OneWeather weather) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            weather.cityName ?? '未知城市',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${weather.temperature ?? ''}°C ${weather.climate ?? ''}',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// 构建推荐内容（垂直布局）
  Widget _buildRecommendContent(OneRecommend recommend) {
    if (recommend.contentList?.isEmpty ?? true) {
      if (recommend.weather != null) {
        return _buildSimpleWeatherInfo(recommend.weather!);
      }
      return const Center(
        child: Text(
          '当日暂无内容',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // 按照图片显示的顺序：小记、阅读、问答、电台
    final contentList = recommend.contentList!;
    final sortedContent = <OneRecommendContent>[];

    // 按分类排序
    final categoryOrder = ['hp', 'essay', 'question', 'radio'];
    for (final categoryName in categoryOrder) {
      final items = contentList.where((item) {
        final category =
            item.displayCategory?.toString() ?? item.category ?? '1';
        final apiCategory = OneCategory.getApiName(category);
        return apiCategory == categoryName;
      }).toList();
      sortedContent.addAll(items);
    }

    // 添加剩余的内容
    for (final item in contentList) {
      if (!sortedContent.contains(item)) {
        sortedContent.add(item);
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedContent.length,
      itemBuilder: (context, index) {
        final content = sortedContent[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: OneRecommendCard(
            content: content,
            onTap: () => _navigateToDetail(content),
          ),
        );
      },
    );
  }
}
