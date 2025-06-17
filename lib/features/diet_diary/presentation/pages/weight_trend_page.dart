import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

import '../../../../shared/constants/constants.dart';
import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../domain/entities/weight_record.dart';
import '../../domain/entities/user_profile.dart';
import '../viewmodels/diet_diary_viewmodel.dart';
import '../widgets/scrollable_chart.dart';
import '../widgets/bmi_indicator.dart';

class WeightTrendPage extends StatefulWidget {
  const WeightTrendPage({super.key});

  @override
  State<WeightTrendPage> createState() => _WeightTrendPageState();
}

class _WeightTrendPageState extends State<WeightTrendPage> {
  List<WeightRecord> _weightRecords = [];
  bool _isLoading = false;
  String? _error;

  // 用于添加新记录的控制器
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final viewModel = Provider.of<DietDiaryViewModel>(context, listen: false);
      final userProfile = viewModel.userProfile;

      if (userProfile != null && userProfile.id != null) {
        final records = await viewModel.getWeightRecords(userProfile.id!);
        setState(() {
          _weightRecords = records;
          _isLoading = false;
        });

        // 如果有体重记录，并且最新记录与用户资料中的体重不同，则更新用户资料
        if (records.isNotEmpty) {
          final latestRecord = records.first; // 已按日期降序排序
          if (latestRecord.weight != userProfile.weight) {
            final updatedProfile = userProfile.copyWith(
              weight: latestRecord.weight,
            );
            await viewModel.updateUserProfile(updatedProfile);
          }
        }
      } else {
        setState(() {
          _error = '无法获取用户信息';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '加载体重记录失败: $e';
        _isLoading = false;
      });
    }
  }

  void _showAddWeightDialog() {
    final viewModel = Provider.of<DietDiaryViewModel>(context, listen: false);
    final userProfile = viewModel.userProfile;

    // 重置控制器
    _weightController.text = '';
    _notesController.text = '';

    // 如果有最近的体重记录，预填充当前体重
    if (_weightRecords.isNotEmpty) {
      _weightController.text = _weightRecords.first.weight.toString();
    } else if (userProfile != null) {
      _weightController.text = userProfile.weight.toString();
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('记录体重'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _weightController,
                    decoration: const InputDecoration(labelText: '体重 (公斤)'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: '备注 (可选)'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  _addWeightRecord();
                  Navigator.pop(context);
                },
                child: const Text('保存'),
              ),
            ],
          ),
    );
  }

  Future<void> _addWeightRecord() async {
    if (_weightController.text.isEmpty) {
      ToastUtils.showError('请输入体重');
      return;
    }

    try {
      final weight = double.parse(_weightController.text);
      final notes = _notesController.text;
      final viewModel = Provider.of<DietDiaryViewModel>(context, listen: false);
      final userProfile = viewModel.userProfile;

      if (userProfile != null && userProfile.id != null) {
        final weightRecord = WeightRecord(
          userId: userProfile.id!,
          date: DateTime.now(),
          weight: weight,
          note: notes.isNotEmpty ? notes : null,
        );

        await viewModel.addWeightRecord(weightRecord);

        // 更新用户资料中的体重
        final updatedProfile = userProfile.copyWith(weight: weight);
        await viewModel.updateUserProfile(updatedProfile);

        await _loadData(); // 重新加载数据

        ToastUtils.showInfo('体重记录已保存');
      }
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, '保存失败', e.toString());
    }
  }

  Future<void> _deleteWeightRecord(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('确认删除'),
            content: const Text('确定要删除这个记录吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('删除'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      if (!mounted) return;
      final viewModel = Provider.of<DietDiaryViewModel>(context, listen: false);

      // 如果只剩一条记录，不允许删除
      if (_weightRecords.length <= 1) {
        ToastUtils.showWarning('至少需要保留一条体重记录');
        return;
      }

      // 找到要删除的记录
      await viewModel.deleteWeightRecord(id);

      // 如果删除的是最新记录，需要更新用户资料为次新记录的体重
      if (_weightRecords.isNotEmpty && _weightRecords.first.id == id) {
        // 找到次新记录
        final nextLatestRecord = _weightRecords.where((r) => r.id != id).first;
        final userProfile = viewModel.userProfile;
        if (userProfile != null) {
          final updatedProfile = userProfile.copyWith(
            weight: nextLatestRecord.weight,
          );
          await viewModel.updateUserProfile(updatedProfile);
        }
      }

      await _loadData(); // 重新加载数据

      ToastUtils.showInfo('记录已删除');
    } catch (e) {
      if (mounted) {
        commonExceptionDialog(context, '删除失败', e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DietDiaryViewModel>(context);
    final userProfile = viewModel.userProfile;

    return Scaffold(
      appBar: AppBar(title: const Text('体重趋势')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                child: Column(
                  children: [
                    // BMI 卡片
                    if (userProfile != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                        child: _buildBmiCard(userProfile),
                      ),

                    // 体重趋势图
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                      child: _buildWeightChart(),
                    ),

                    // 体重记录列表
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                      child: _buildWeightRecordsList(),
                    ),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddWeightDialog,
        tooltip: '记录体重',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBmiCard(UserProfile userProfile) {
    // 使用最新体重记录的体重计算BMI，如果没有记录则使用用户资料中的体重
    final weight =
        _weightRecords.isNotEmpty
            ? _weightRecords.first.weight
            : userProfile.weight;

    final height = userProfile.height / 100; // 转换为米
    final bmi = weight / (height * height);

    String bmiCategory;
    Color bmiColor;

    if (bmi < 18.5) {
      bmiCategory = '偏瘦';
      bmiColor = Colors.blue;
    } else if (bmi < 24) {
      bmiCategory = '正常';
      bmiColor = Colors.green;
    } else if (bmi < 28) {
      bmiCategory = '超重';
      bmiColor = Colors.orange;
    } else {
      bmiCategory = '肥胖';
      bmiColor = Colors.red;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              '当前 BMI',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  bmi.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: bmiColor,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bmiCategory,
                      style: TextStyle(
                        fontSize: 20,
                        color: bmiColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '身高: ${userProfile.height} cm',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      '体重: $weight kg',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 使用新的BMI指示器组件
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: BmiIndicator(bmi: bmi),
            ),

            const SizedBox(height: 16),
            const Text(
              'BMI < 18.5: 偏瘦\nBMI 18.5-23.9: 正常\nBMI 24-27.9: 超重\nBMI ≥ 28: 肥胖',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightChart() {
    if (_weightRecords.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('暂无体重记录，点击右下角按钮添加')),
      );
    }

    // 按日期排序
    final sortedRecords = List<WeightRecord>.from(_weightRecords)
      ..sort((a, b) => a.date.compareTo(b.date));

    // 获取最小和最大体重，设置图表范围
    double minWeight = sortedRecords
        .map((e) => e.weight)
        .reduce((a, b) => a < b ? a : b);
    double maxWeight = sortedRecords
        .map((e) => e.weight)
        .reduce((a, b) => a > b ? a : b);

    // 设置y轴范围，增加一些边距
    final yPadding = (maxWeight - minWeight) * 0.2;
    final double minY =
        (minWeight - yPadding) > 0 ? (minWeight - yPadding) : 0.0;
    final double maxY = maxWeight + yPadding;

    return ScrollableChart(
      title: '体重趋势',
      height: 300,
      series: [
        LineSeries<WeightRecord, DateTime>(
          dataSource: sortedRecords,
          xValueMapper: (WeightRecord record, _) => record.date,
          yValueMapper: (WeightRecord record, _) => record.weight,
          name: '体重',
          markerSettings: const MarkerSettings(isVisible: true),
          dataLabelSettings: const DataLabelSettings(isVisible: true),
        ),
      ],
      xAxis: DateTimeAxis(
        dateFormat: DateFormat('MM-dd'),
        intervalType: DateTimeIntervalType.auto,
      ),
      yAxis: NumericAxis(
        title: AxisTitle(text: '体重 (kg)'),
        minimum: minY,
        maximum: maxY,
        // 不显示y轴标签，让表格有更多空间
        isVisible: false,
      ),
    );
  }

  Widget _buildWeightRecordsList() {
    if (_weightRecords.isEmpty) {
      return const SizedBox.shrink();
    }

    // 按日期降序排序
    final sortedRecords = List<WeightRecord>.from(_weightRecords)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '体重记录',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedRecords.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final record = sortedRecords[index];
                return ListTile(
                  // dense: true,
                  title: Text(
                    '${record.weight} kg',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat(constDatetimeFormat).format(record.date)),
                      if (record.note != null && record.note!.isNotEmpty)
                        Text(record.note!),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteWeightRecord(record.id!),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
