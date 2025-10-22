import 'package:flutter/material.dart';

import '../../../../../shared/widgets/toast_utils.dart';

/// 通用的用户内容列表页面组件
/// T: 数据类型 (DaoduUserSnippetsDetail, DaoduUserThoughtsProfile, DaoduLesson)
class DaoduUserContentListPage<T> extends StatefulWidget {
  final String userId;
  final String userName;
  final String title;
  final String emptyMessage;
  final IconData emptyIcon;

  /// 数据加载函数
  final Future<List<T>> Function({
    required String id,
    required int offset,
    required int limit,
    required bool forceRefresh,
  })
  loadDataFunction;

  /// 卡片构建函数
  final Widget Function(T item) itemBuilder;

  /// 每页加载数量
  final int limit;

  const DaoduUserContentListPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.title,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.loadDataFunction,
    required this.itemBuilder,
    this.limit = 20,
  });

  @override
  State<DaoduUserContentListPage<T>> createState() =>
      _DaoduUserContentListPageState<T>();
}

class _DaoduUserContentListPageState<T>
    extends State<DaoduUserContentListPage<T>> {
  final ScrollController _scrollController = ScrollController();

  List<T> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  int _currentOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadItems();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMoreItems();
      }
    }
  }

  Future<void> _loadItems() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await widget.loadDataFunction(
        id: widget.userId,
        offset: 0,
        limit: widget.limit,
        forceRefresh: false,
      );

      if (mounted) {
        setState(() {
          _items = items;
          _currentOffset = items.length;
          _hasMore = items.length >= widget.limit;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '加载失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreItems() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newItems = await widget.loadDataFunction(
        id: widget.userId,
        offset: _currentOffset,
        limit: widget.limit,
        forceRefresh: false,
      );

      if (mounted) {
        setState(() {
          _items.addAll(newItems);
          _currentOffset += newItems.length;
          _hasMore = newItems.length >= widget.limit;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ToastUtils.showError('加载更多失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _currentOffset = 0;
              _hasMore = true;
              _loadItems();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadItems, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.emptyIcon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              widget.emptyMessage,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _currentOffset = 0;
        _hasMore = true;
        await _loadItems();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return _buildLoadingIndicator();
          }
          return widget.itemBuilder(_items[index]);
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: _isLoading
          ? const CircularProgressIndicator()
          : const Text('没有更多内容了', style: TextStyle(color: Colors.grey)),
    );
  }
}
