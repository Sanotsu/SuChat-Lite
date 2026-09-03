import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/style/app_colors.dart';
import '../../../../shared/widgets/audio_player_widget.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../../unified_chat/data/database/translation_history_dao.dart';

/// 翻译历史页面(2026-09-03 快速翻译新增)
/// 存储于unified聊天库translation_history表，随DB备份链自动备份
/// 列表仅显示摘要，点击条目进入详情查看全文与合成音频
class TranslationHistoryPage extends StatefulWidget {
  const TranslationHistoryPage({super.key});

  @override
  State<TranslationHistoryPage> createState() => _TranslationHistoryPageState();
}

class _TranslationHistoryPageState extends State<TranslationHistoryPage> {
  final TranslationHistoryDao _dao = TranslationHistoryDao();
  List<TranslationHistoryEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    try {
      final entries = await _dao.query();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ToastUtils.showError('加载翻译历史失败: $e');
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空翻译历史'),
        content: const Text('将删除全部翻译历史记录，确定继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清空', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dao.clear();
      ToastUtils.showToast('已清空');
      _loadEntries();
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '今天 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.year}/${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('翻译历史'),
        elevation: 0,
        actions: [
          if (_entries.isNotEmpty)
            IconButton(
              onPressed: _clearAll,
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: '清空历史',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, color: Colors.grey[400], size: 56),
                  const SizedBox(height: 12),
                  Text('暂无翻译历史', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadEntries,
              child: ListView.separated(
                padding: EdgeInsets.all(12.w),
                itemCount: _entries.length,
                separatorBuilder: (_, _) => SizedBox(height: 8.h),
                itemBuilder: (context, index) {
                  final e = _entries[index];
                  final hasAudio =
                      e.audioPath != null && File(e.audioPath!).existsSync();
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    // 点击条目进入详情(长文本全文与音频在详情中查看)
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TranslationHistoryDetailPage(entry: e),
                          ),
                        );
                        _loadEntries();
                      },
                      child: Padding(
                        padding: EdgeInsets.all(12.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 元信息行
                            Row(
                              children: [
                                Text(
                                  '${e.sourceLang} → ${e.targetLang}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (hasAudio) ...[
                                  SizedBox(width: 6.w),
                                  Icon(
                                    Icons.volume_up,
                                    size: 14,
                                    color: AppColors.success,
                                  ),
                                ],
                                const Spacer(),
                                Text(
                                  _formatTime(e.createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6.h),
                            // 原文摘要
                            Text(
                              e.sourceText,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4.h),
                            // 译文摘要
                            Text(
                              e.translatedText,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

/// 翻译历史详情页(原文/译文全文展示，含合成音频播放)
class TranslationHistoryDetailPage extends StatelessWidget {
  final TranslationHistoryEntry entry;

  const TranslationHistoryDetailPage({super.key, required this.entry});

  Future<void> _delete(BuildContext context) async {
    if (entry.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定删除这条翻译历史？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await TranslationHistoryDao().delete(entry.id!);
      ToastUtils.showToast('已删除');
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  String _formatFullTime(DateTime dt) =>
      '${dt.year}/${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final hasAudio =
        entry.audioPath != null && File(entry.audioPath!).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: const Text('翻译详情'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _delete(context),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: '删除',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 元信息
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.sourceLang} → ${entry.targetLang}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _formatFullTime(entry.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  if (entry.modelName != null)
                    Text(
                      '模型: ${entry.modelName}${entry.platformName != null ? ' (${entry.platformName})' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                ],
              ),
            ),

            SizedBox(height: 12.h),

            // 原文(全量)
            _buildTextBlock(
              context,
              label: '原文',
              text: entry.sourceText,
              backgroundColor: Colors.grey[100]!,
              textColor: Colors.grey[700]!,
            ),

            SizedBox(height: 12.h),

            // 译文(全量)
            _buildTextBlock(
              context,
              label: '译文',
              text: entry.translatedText,
              backgroundColor: Colors.blue[50]!,
              textColor: Colors.black87,
            ),

            // 合成音频
            if (entry.audioPath != null) ...[
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: hasAudio
                    ? AudioPlayerWidget(audioUrl: entry.audioPath!, dense: true)
                    : Text(
                        '音频文件不存在或已被清理',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextBlock(
    BuildContext context, {
    required String label,
    required String text,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: text));
                  ToastUtils.showToast('已复制');
                },
                child: Icon(Icons.copy, size: 16, color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          SelectableText(
            text,
            style: TextStyle(fontSize: 14, height: 1.5, color: textColor),
          ),
        ],
      ),
    );
  }
}
