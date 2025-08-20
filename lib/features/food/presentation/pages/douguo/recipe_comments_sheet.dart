import 'package:flutter/material.dart';
import '../../../data/datasources/douguo/douguo_api_manager.dart';
import '../../../data/models/douguo/douguo_recipe_comment_resp.dart';

class RecipeCommentsSheet extends StatefulWidget {
  final String recipeId;
  final int initialCommentCount;

  const RecipeCommentsSheet({
    super.key,
    required this.recipeId,
    required this.initialCommentCount,
  });

  @override
  State<RecipeCommentsSheet> createState() => _RecipeCommentsSheetState();
}

class _RecipeCommentsSheetState extends State<RecipeCommentsSheet> {
  final DouguoApiManager _apiManager = DouguoApiManager();
  final ScrollController _scrollController = ScrollController();

  final List<DGRecipeComment> _allComments = [];
  List<DGRecipeComment> _displayComments = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  // 当前页码(偏移量用页码*每页数量)
  int _page = 1;
  // 暂时默认每次加载的评论数量
  final int _limit = 10;
  // 总评论数=主评论数+子评论数
  int get _totalFetchedComments {
    return _allComments.length +
        _allComments.fold(
          0,
          (sum, comment) => sum + (comment.childComments?.length ?? 0),
        );
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadComments();
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
      _loadComments();
    }
  }

  Future<void> _loadComments() async {
    if (_isLoading || !_hasMore) {
      // 如果获取到的评论数已经大于等于总数量，则修改hasMore为false
      if (_totalFetchedComments >= widget.initialCommentCount) {
        setState(() {
          _hasMore = false;
        });
      }

      return;
    }

    setState(() {
      _isLoading = true;
      if (_page == 1) {
        _error = null;
      }
    });

    try {
      final response = await _apiManager.getRecipeCommentList(
        recipeId: widget.recipeId,
        offset: (_page - 1) * _limit,
        limit: _limit,
      );

      if (mounted) {
        setState(() {
          final newComments =
              response.result?.comments
                  ?.where((c) => c.content != null && c.content!.isNotEmpty)
                  .toList() ??
              [];

          // 防止重复添加评论，按ID去重
          for (final newComment in newComments) {
            if (!_allComments.any((existing) => existing.id == newComment.id)) {
              _allComments.add(newComment);
            }
          }
          // 查询完页码+1
          _page += 1;

          // 已经查询到的评论数 < 评论总数，则还有更多
          // 2025-08-13 很奇怪，API中存在菜谱评论+子评论的总数 不等于 评论总数的情况
          // 比如菜谱id=3317225, 一共14条评论，但主评论6+子评论3。
          // 此时 9<14，hasMore为true，但实际上已经没有更多评论了，此时虽然又调用了查询，但得到的评论列表应该为null
          _hasMore = (_page - 1) * _limit < widget.initialCommentCount;

          _buildCommentTree();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _buildCommentTree() {
    // 只显示主评论（replyId为null或0的评论）
    // API返回的数据中，子评论已经包含在父评论的childComments字段中
    final topLevelComments = _allComments
        .where((comment) => comment.replyId == null || comment.replyId == 0)
        .toList();

    setState(() {
      _displayComments = topLevelComments;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
        ],
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '评论 (${widget.initialCommentCount})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(height: 20),
          Expanded(child: _buildContent(_scrollController)),
        ],
      ),
    );
  }

  Widget _buildContent(ScrollController scrollController) {
    if (_isLoading && _displayComments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _displayComments.isEmpty) {
      return _buildErrorWidget();
    }

    if (_displayComments.isEmpty) {
      return _buildEmptyWidget();
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: _displayComments.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _displayComments.length) {
          return _buildLoadingMoreIndicator();
        }
        return _buildCommentItem(_displayComments[index]);
      },
    );
  }

  Widget _buildCommentItem(DGRecipeComment comment, {int depth = 0}) {
    // 城市信息，如果有ip地址且不为空，则使用ip地址；如果有城市且不为空，则使用城市；否则为空
    String? cityInfo;
    if (comment.ipAddressLocation != null &&
        comment.ipAddressLocation!.isNotEmpty) {
      cityInfo = comment.ipAddressLocation;
    } else if (comment.city != null && comment.city!.isNotEmpty) {
      cityInfo = comment.city;
    } else if (comment.at != null && comment.at!.isNotEmpty) {
      cityInfo = comment.at;
    }

    var likeRow = Row(
      children: [
        if (comment.likeCount != null && comment.likeCount! > 0) ...[
          Icon(Icons.thumb_up_alt_outlined, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            comment.likeCount.toString(),
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ],
    );

    var nameAndCityRow = Row(
      children: [
        Expanded(
          child: RichText(
            textAlign: TextAlign.left,
            text: TextSpan(
              children: [
                TextSpan(
                  text: comment.u?.n ?? '匿名用户',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                if (cityInfo != null)
                  WidgetSpan(
                    child: Transform.translate(
                      // 微调垂直位置: (14-12)/2，昵称和城市垂直中心对齐
                      offset: Offset(0, -1),
                      child: Text(
                        "\t\t$cityInfo",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        likeRow,
      ],
    );

    var contentRow = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (comment.replyUser != null && comment.at != null)
                _buildReplyHeader(comment),
              Text(
                comment.content?.map((c) => c.c ?? '').join() ?? '',
                style: const TextStyle(color: Colors.black87, fontSize: 14),
              ),
            ],
          ),
        ),
        // likeRow,
      ],
    );

    return Padding(
      // 评论最外层有左右边距，这里不需要
      padding: EdgeInsets.only(
        left: 0 + (depth * 16.0),
        right: 0,
        top: 8,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(comment.u?.p ?? ''),
                onBackgroundImageError: (_, _) {},
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 昵称和城市
                    nameAndCityRow,

                    // 评论内容(包括回复谁的@昵称)
                    const SizedBox(height: 4),
                    contentRow,
                    const SizedBox(height: 8),

                    // 评论被点赞数
                    // likeRow,
                  ],
                ),
              ),
            ],
          ),
          if (comment.childComments != null &&
              comment.childComments!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...comment.childComments!.map(
              (child) => _buildCommentItem(child, depth: depth + 1),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyHeader(DGRecipeComment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 13, color: Colors.grey[800]),
          children: [
            const TextSpan(text: '回复 '),
            TextSpan(
              text: '@${comment.replyUser?.n ?? '未知用户'}',
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 0),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyWidget() {
    return const Center(
      child: Text('暂无评论', style: TextStyle(color: Colors.grey)),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('加载失败', style: TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _page = 1;
                _allComments.clear();
                _displayComments.clear();
                _loadComments();
              });
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}
