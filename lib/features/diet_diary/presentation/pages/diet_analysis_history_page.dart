import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/toast_utils.dart';
import '../../domain/entities/diet_analysis.dart';
import '../viewmodels/diet_diary_viewmodel.dart';

class DietAnalysisHistoryPage extends StatefulWidget {
  const DietAnalysisHistoryPage({super.key});

  @override
  State<DietAnalysisHistoryPage> createState() =>
      _DietAnalysisHistoryPageState();
}

class _DietAnalysisHistoryPageState extends State<DietAnalysisHistoryPage> {
  List<DietAnalysis> _analyses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalyses();
  }

  Future<void> _loadAnalyses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final viewModel = Provider.of<DietDiaryViewModel>(context, listen: false);
      final analyses = await viewModel.getAllDietAnalyses();

      setState(() {
        _analyses = analyses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ToastUtils.showError('加载分析历史失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('分析历史')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _analyses.isEmpty
              ? const Center(child: Text('暂无分析记录'))
              : ListView.builder(
                itemCount: _analyses.length,
                itemBuilder: (context, index) {
                  final analysis = _analyses[index];

                  final previewText =
                      analysis.content.length > 100
                          ? '${analysis.content.substring(0, 100)}...'
                          : analysis.content;

                  final viewModel = Provider.of<DietDiaryViewModel>(
                    context,
                    listen: false,
                  );

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: ListTile(
                      title: Text(
                        '${_formatDate(analysis.date)} 分析',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '分析时间: ${_formatDateTime(analysis.createdAt)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '使用模型: ${analysis.modelName}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Divider(),
                          Text(
                            previewText,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(height: 1),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        // 如果选中的饮食分析记录的日期不是当前需要分析的日期，则弹窗显示日期不匹配无法查看
                        if (_formatDate(analysis.date) ==
                            _formatDate(viewModel.selectedDate)) {
                          Navigator.pop(context, analysis);
                        } else {
                          ToastUtils.showError(
                            '日期不匹配无法查看\n当前分析日期是: ${_formatDate(viewModel.selectedDate)}\n您点击的日期是: ${_formatDate(analysis.date)}',
                            duration: const Duration(seconds: 5),
                          );
                        }
                      },
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                    ),
                  );
                },
              ),
    );
  }

  String _formatDate(DateTime date) {
    final viewModel = Provider.of<DietDiaryViewModel>(context, listen: false);
    return viewModel.getFormattedDate(date);
  }

  String _formatDateTime(DateTime dateTime) {
    final viewModel = Provider.of<DietDiaryViewModel>(context, listen: false);
    return viewModel.getFormattedDateTime(dateTime);
  }
}
