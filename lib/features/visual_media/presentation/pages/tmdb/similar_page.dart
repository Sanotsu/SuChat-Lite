import 'package:flutter/material.dart';
import '../../../data/datasources/tmdb/tmdb_apis.dart';
import '../../../data/models/tmdb/tmdb_common.dart';
import '../../../data/models/tmdb/tmdb_result_resp.dart';
import '../../widgets/tmdb/base_widgets.dart';
import 'detail_page.dart';

/// 相似/推荐内容页面
class TmdbSimilarPage extends StatefulWidget {
  final int mediaId;
  final String mediaType; // 'movie' 或 'tv'
  final String contentType; // 'similar' 或 'recommendations'
  final String title;

  const TmdbSimilarPage({
    super.key,
    required this.mediaId,
    required this.mediaType,
    required this.contentType,
    required this.title,
  });

  @override
  State<TmdbSimilarPage> createState() => _TmdbSimilarPageState();
}

class _TmdbSimilarPageState extends State<TmdbSimilarPage> {
  final List<TmdbResultItem> _items = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      TmdbResultResp? response;

      if (widget.mediaType == 'movie') {
        if (widget.contentType == 'similar') {
          response = await TmdbApiManager().getMovieSimilar(widget.mediaId);
        } else {
          response = await TmdbApiManager().getMovieRecommendations(
            widget.mediaId,
          );
        }
      } else if (widget.mediaType == 'tv') {
        if (widget.contentType == 'similar') {
          response = await TmdbApiManager().getTvSimilar(widget.mediaId);
        } else {
          response = await TmdbApiManager().getTvRecommendations(
            widget.mediaId,
          );
        }
      }

      if (response != null && response.results != null) {
        if (!mounted) return;
        setState(() {
          _items.addAll(response!.results!);
          _currentPage++;
          _hasMore = _currentPage <= (response.totalPages ?? 1);
        });
      } else {
        if (!mounted) return;
        setState(() {
          _hasMore = false;
        });
      }
    } catch (e) {
      // print('加载数据失败: $e');
      if (!mounted) return;
      setState(() {
        _hasMore = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToDetail(TmdbResultItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TmdbDetailPage(
          item: item,
          mediaType: item.mediaType ?? widget.mediaType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _items.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: Text('暂无内容'))
          : GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _items.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _items.length) {
                  return _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : const SizedBox.shrink();
                }

                final item = _items[index];
                return TmdbItemCard(
                  item: item,
                  onTap: () => _navigateToDetail(item),
                  isHorizontal: true,
                );
              },
            ),
    );
  }
}
