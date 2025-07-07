import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/training_plan.dart';
import '../../domain/entities/training_plan_detail.dart';
import '../../domain/entities/training_record.dart';
import '../viewmodels/training_viewmodel.dart';
import '../widgets/training_calendar.dart';
import 'training_record_detail_page.dart';

class PlanCalendarPage extends StatefulWidget {
  final TrainingPlan plan;
  final List<TrainingPlanDetail> planDetails;

  const PlanCalendarPage({
    super.key,
    required this.plan,
    required this.planDetails,
  });

  @override
  State<PlanCalendarPage> createState() => _PlanCalendarPageState();
}

class _PlanCalendarPageState extends State<PlanCalendarPage> {
  List<TrainingRecord> _records = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 使用addPostFrameCallback延迟加载，避免在构建过程中触发状态更新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecords();
    });
  }

  Future<void> _loadRecords() async {
    if (!mounted) return;

    try {
      final viewModel = Provider.of<TrainingViewModel>(context, listen: false);

      setState(() {
        _isLoading = true;
        _error = null;
      });

      // 加载与当前计划相关的所有训练记录
      final records = await viewModel.getTrainingRecordsForPlan(
        widget.plan.planId,
      );

      if (!mounted) return;

      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = '加载训练记录失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            children: [
              TextSpan(
                text: '日历视图\n',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextSpan(
                text: widget.plan.planName,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : TrainingCalendar(
                plan: widget.plan,
                planDetails: widget.planDetails,
                records: _records,
                onDaySelected: (date) {
                  // 可以在这里处理日期选择事件
                },
                onRecordTap: (record) {
                  // 点击训练记录时导航到详情页
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => TrainingRecordDetailPage(
                            recordId: record.recordId,
                          ),
                    ),
                  );
                },
              ),
    );
  }
}
