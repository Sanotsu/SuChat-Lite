import 'package:flutter/material.dart';

import '../../../../../../shared/widgets/image_preview_helper.dart';
import '../../../../../../shared/widgets/common_error_empty_widgets.dart';
import '../../../../data/datasources/one_api_manager.dart';
import '../../../../data/models/one/one_category_list.dart';
import '../detail_page.dart';

/// 连载章节页面
class SerialDetailPage extends StatefulWidget {
  final OneContent serial;

  const SerialDetailPage({super.key, required this.serial});

  @override
  State<SerialDetailPage> createState() => _SerialDetailPageState();
}

class _SerialDetailPageState extends State<SerialDetailPage> {
  final OneApiManager _apiManager = OneApiManager();

  List<OneContent> _chapterList = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChapterList();
  }

  Future<void> _loadChapterList() async {
    final serialId = int.tryParse(widget.serial.serialId?.toString() ?? '');
    if (serialId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final chapters = await _apiManager.getOneSerialListBySerialId(
        serialId: serialId,
      );
      if (mounted) {
        setState(() {
          _chapterList = chapters;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serial.title ?? '连载章节'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 连载信息头部
          _buildSerialHeader(),
          // 章节列表
          Expanded(child: _buildChapterList()),
        ],
      ),
    );
  }

  Widget _buildSerialHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 封面
          if (widget.serial.cover != null)
            Container(
              width: 80,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: buildNetworkOrFileImage(widget.serial.cover!),
              ),
            ),
          const SizedBox(width: 16),
          // 连载信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.serial.title ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (widget.serial.forward != null)
                  Text(
                    widget.serial.forward!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return buildCommonErrorWidget(error: _error, onRetry: _loadChapterList);
    }

    if (_chapterList.isEmpty) {
      return buildCommonEmptyWidget(
        icon: Icons.list,
        message: '暂无内容',
        subMessage: '该连载暂时没有内容',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChapterList,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _chapterList.length,
        itemBuilder: (context, index) {
          final chapter = _chapterList[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: _buildChapterCard(chapter, index + 1),
          );
        },
      ),
    );
  }

  Widget _buildChapterCard(OneContent chapter, int chapterNumber) {
    return GestureDetector(
      onTap: () => _navigateToChapterDetail(chapter),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 章节编号
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  '$chapterNumber',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // 章节信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.title ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (chapter.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      chapter.subtitle!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _navigateToChapterDetail(OneContent chapter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OneDetailPage(
          contentType: 'serialcontent',
          contentId: (chapter.id ?? chapter.contentId ?? '').toString(),
          title: chapter.title ?? '',
        ),
      ),
    );
  }
}
