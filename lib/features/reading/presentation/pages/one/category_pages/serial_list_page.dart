import 'package:flutter/material.dart';

import '../../../../../../shared/widgets/common_error_empty_widgets.dart';
import '../../../../data/datasources/one_api_manager.dart';
import '../../../../data/models/one/one_category_list.dart';
import '../../../widgets/one/content_card.dart';
import 'serial_detail_page.dart';

/// 连载列表页面
class SerialListPage extends StatefulWidget {
  const SerialListPage({super.key});

  @override
  State<SerialListPage> createState() => _SerialListPageState();
}

class _SerialListPageState extends State<SerialListPage> {
  final OneApiManager _apiManager = OneApiManager();

  final List<OneContent> _allSerialList = [];
  final Map<int, List<OneContent>> _yearlySerialMap = {};
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentStartYear = DateTime.now().year;
  final List<int> _loadedYears = [];
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _loadInitialSerials();
  }

  Future<void> _loadInitialSerials() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _allSerialList.clear();
      _yearlySerialMap.clear();
      _loadedYears.clear();
    });

    try {
      int currentYear = DateTime.now().year;
      int totalCount = 0;

      // 从当前年份开始加载，直到满足10条数据或没有更多数据
      while (totalCount < 10 && currentYear >= 2010) {
        // 假设最早到2010年
        if (_loadedYears.contains(currentYear)) {
          currentYear--;
          continue;
        }

        final serials = await _apiManager.getOneSerialListByYear(
          year: currentYear,
        );

        if (serials.isNotEmpty) {
          _loadedYears.add(currentYear);
          _yearlySerialMap[currentYear] = serials;
          _allSerialList.addAll(serials);
          totalCount += serials.length;
        }

        // 如果当前年份数据足够，就停止加载
        if (totalCount >= 10) {
          break;
        }

        currentYear--;
      }

      if (mounted) {
        setState(() {
          _currentStartYear = _loadedYears.isNotEmpty
              ? _loadedYears.last
              : DateTime.now().year;
          _isLoading = false;
          // 检查是否还有更早的年份
          _hasMoreData = currentYear >= 2010;
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

  Future<void> _loadMoreSerials() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      int nextYear = _currentStartYear - 1;
      int loadedCount = 0;

      // 加载更多年份的数据，每次至少加载10条
      while (loadedCount < 10 && nextYear >= 2010) {
        if (_loadedYears.contains(nextYear)) {
          nextYear--;
          continue;
        }

        final serials = await _apiManager.getOneSerialListByYear(
          year: nextYear,
        );

        if (serials.isNotEmpty) {
          _loadedYears.add(nextYear);
          _yearlySerialMap[nextYear] = serials;
          _allSerialList.addAll(serials);
          loadedCount += serials.length;
        }

        nextYear--;
      }

      if (mounted) {
        setState(() {
          // 更新当前起始年份
          _currentStartYear = nextYear + 1;
          _isLoadingMore = false;
          // 检查是否还有更早的年份
          _hasMoreData = nextYear >= 2010;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
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
      return buildCommonErrorWidget(
        error: _error,
        onRetry: _loadInitialSerials,
      );
    }

    if (_allSerialList.isEmpty) {
      return buildCommonEmptyWidget(
        icon: Icons.menu_book,
        message: '暂无内容',
        subMessage: '该连载暂时没有内容',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInitialSerials,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo is ScrollEndNotification &&
              scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
              !_isLoadingMore &&
              _hasMoreData) {
            _loadMoreSerials();
          }
          return false;
        },
        child: ListView.builder(
          itemCount:
              _yearlySerialMap.length * 2 +
              (_isLoadingMore ? 1 : 0) +
              (_hasMoreData ? 0 : 1),
          itemBuilder: (context, index) {
            // 处理加载更多指示器
            if (_isLoadingMore && index == _yearlySerialMap.length * 2) {
              return _buildLoadingMoreWidget();
            }

            // 处理没有更多数据的提示
            if (!_hasMoreData && index == _yearlySerialMap.length * 2) {
              return _buildNoMoreDataWidget();
            }

            // 处理年份标题和内容
            if (index.isEven) {
              // 偶数索引是年份标题
              final yearIndex = index ~/ 2;
              final year = _loadedYears[yearIndex];
              return _buildYearHeader(year);
            } else {
              // 奇数索引是内容
              final yearIndex = (index - 1) ~/ 2;
              final year = _loadedYears[yearIndex];
              final serials = _yearlySerialMap[year] ?? [];
              return Column(
                children: serials.map((serial) {
                  return OneContentCard(
                    content: serial,
                    onTap: () => _navigateToSerialChapters(serial),
                  );
                }).toList(),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildYearHeader(int year) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        '$year年',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildLoadingMoreWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildNoMoreDataWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          '没有更多数据了',
          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
        ),
      ),
    );
  }

  void _navigateToSerialChapters(OneContent serial) {
    if (serial.id != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SerialDetailPage(serial: serial),
        ),
      );
    }
  }
}
