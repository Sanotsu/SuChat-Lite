import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/training_record.dart';
import '../viewmodels/training_viewmodel.dart';
import '../widgets/training_statistics.dart';
import '../pages/training_record_detail_page.dart';

/// 训练统计页面
/// 展示用户的训练记录统计数据
class TrainingStatisticsPage extends StatefulWidget {
  final String userId;
  final bool showAppBar;

  const TrainingStatisticsPage({
    super.key,
    required this.userId,
    this.showAppBar = true,
  });

  @override
  State<TrainingStatisticsPage> createState() => _TrainingStatisticsPageState();
}

class _TrainingStatisticsPageState extends State<TrainingStatisticsPage> {
  bool _isLoading = false;
  String? _error;

  // 记录的时间范围
  late DateTime _startDate;
  late DateTime _endDate;

  // 记录列表
  final List<TrainingRecord> _records = [];

  @override
  void initState() {
    super.initState();
    // 默认加载最近30天的记录
    _endDate = DateTime.now();
    _startDate = _endDate.subtract(const Duration(days: 30));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTrainingRecords();
    });
  }

  // 加载训练记录
  Future<void> _loadTrainingRecords() async {
    if (widget.userId.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final viewModel = Provider.of<TrainingViewModel>(context, listen: false);
      final records = await viewModel.getUserTrainingRecordsInDateRange(
        _startDate,
        _endDate,
      );

      setState(() {
        _records.clear();
        _records.addAll(records);
      });
    } catch (e) {
      setState(() {
        _error = '加载训练记录失败: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 更改日期范围
  void _changeDateRange(DateTime start, DateTime end) {
    setState(() {
      _startDate = start;
      _endDate = end;
    });
    _loadTrainingRecords();
  }

  @override
  Widget build(BuildContext context) {
    final actions = [
      IconButton(
        icon: const Icon(Icons.date_range),
        onPressed: () async {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
          );

          if (picked != null) {
            _changeDateRange(picked.start, picked.end);
          }
        },
      ),
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: _loadTrainingRecords,
      ),
    ];

    final content =
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '错误: $_error',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadTrainingRecords,
                    child: const Text('重试'),
                  ),
                ],
              ),
            )
            : _records.isEmpty
            ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_score, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '暂无训练记录',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('完成训练后，这里会显示您的训练统计数据', textAlign: TextAlign.center),
                ],
              ),
            )
            : TrainingStatistics(
              records: _records,
              startDate: _startDate,
              endDate: _endDate,
              onRecordTap: (record) {
                // 导航到训练记录详情页面
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            TrainingRecordDetailPage(recordId: record.recordId),
                  ),
                );
              },
            );

    // 根据是否显示AppBar返回不同的布局
    return widget.showAppBar
        ? Scaffold(
          appBar: AppBar(title: const Text('训练统计'), actions: actions),
          body: content,
        )
        : Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const SizedBox.shrink(),
            actions: actions,
          ),
          body: content,
        );
  }
}
