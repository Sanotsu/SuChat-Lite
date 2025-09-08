import 'package:flutter/material.dart';

import '../../../../../core/utils/datetime_formatter.dart';
import '../../../../../shared/widgets/common_error_empty_widgets.dart';
import '../../../../../shared/widgets/expandable_text.dart';
import '../../../../../shared/widgets/simple_tool_widget.dart';
import '../../../data/datasources/one_api_manager.dart';
import '../../../data/models/one/one_detail_models.dart';
import '../../../data/models/one/one_enums.dart';
import '../../pages/one/user_detail_page.dart';

/// ONE评论组件
///
class OneCommentWidget extends StatefulWidget {
  final OneComment comment;

  const OneCommentWidget({super.key, required this.comment});

  @override
  State<OneCommentWidget> createState() => _OneCommentWidgetState();
}

class _OneCommentWidgetState extends State<OneCommentWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户信息行
          _buildUserInfo(),
          const SizedBox(height: 12),

          // 引用内容（如果有）
          if (widget.comment.quote?.isNotEmpty == true) _buildQuoteContent(),

          // 评论内容
          _buildCommentContent(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  /// 构建用户信息
  Widget _buildUserInfo() {
    return Row(
      children: [
        // 用户头像
        GestureDetector(
          onTap: () {
            if (widget.comment.user?.userId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      OneUserDetailPage(userId: widget.comment.user!.userId!),
                ),
              );
            }
          },
          child: buildUserCircleAvatar(widget.comment.user?.webUrl),
        ),
        const SizedBox(width: 12),

        // 用户名和时间
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.comment.user?.userName ?? '匿名用户',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "${formatDateTimeString(widget.comment.inputDate ?? '')}"
                " (${formatRelativeDate(widget.comment.inputDate ?? '')})",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        _buildActionBar(),
      ],
    );
  }

  /// 构建引用内容
  Widget _buildQuoteContent() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 被回复用户信息
          if (widget.comment.touser != null)
            Row(
              children: [
                Icon(Icons.reply, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '回复 ${widget.comment.touser!.userName ?? '匿名用户'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          if (widget.comment.touser != null) const SizedBox(height: 6),

          // 引用内容
          Text(
            widget.comment.quote!,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 构建评论内容
  Widget _buildCommentContent() {
    // return SelectableText(
    //   comment.content ?? '',
    //   style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4),
    // );

    return ExpandableText(
      text: widget.comment.content ?? '',
      maxLines: 5,
      style: const TextStyle(fontSize: 15, height: 1.5),
      buttonStyle: TextStyle(
        fontSize: 14,
        color: Colors.lightBlue,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// 构建操作栏(没有交互,只有显示)
  Widget _buildActionBar() {
    return
    // 点赞按钮
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.thumb_up_outlined, size: 14, color: Colors.grey[600]),
          if ((widget.comment.praisenum ?? 0) > 0) ...[
            const SizedBox(width: 4),
            Text(
              '${widget.comment.praisenum}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }
}

/// 评论列表组件
/// TODO 缺少深色模式
class OneCommentListWidget extends StatefulWidget {
  final String contentType;
  final String contentId;
  final int? initialCommentCount;
  final bool? isDarkMode;

  const OneCommentListWidget({
    super.key,
    required this.contentType,
    required this.contentId,
    this.initialCommentCount,
    this.isDarkMode = false,
  });

  @override
  State<OneCommentListWidget> createState() => _OneCommentListWidgetState();
}

class _OneCommentListWidgetState extends State<OneCommentListWidget> {
  final OneApiManager _apiManager = OneApiManager();

  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  List<OneComment> _comments = [];
  String _lastCommentId = '0';

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  /// 加载评论
  Future<void> _loadComments() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 使用枚举映射正确的API分类名称
      final apiCategory = OneCategory.getApiName(widget.contentType);

      // 注意这里API分类【连载】关键字的一个问题 ，
      // 查询详情时，关键字为serialcontent；但查询评论时为serial
      final commentData = await _apiManager.getOneCommentList(
        categoryName: widget.contentType == 'serialcontent'
            ? 'serial'
            : apiCategory,
        contentId: int.parse(widget.contentId),
        commentId: 0,
        forceRefresh: true,
      );

      if (!mounted) return;
      setState(() {
        _comments = commentData.data ?? [];
        _hasMore = _comments.length >= 20;
        _lastCommentId = _comments.isNotEmpty ? _comments.last.id ?? '0' : '0';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 加载更多评论
  Future<void> _loadMoreComments() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 使用枚举映射正确的API分类名称
      final apiCategory = OneCategory.getApiName(widget.contentType);

      final commentData = await _apiManager.getOneCommentList(
        categoryName: apiCategory,
        contentId: int.parse(widget.contentId),
        commentId: int.parse(_lastCommentId),
        forceRefresh: false,
      );

      if (!mounted) return;
      setState(() {
        final newComments = commentData.data ?? [];
        _comments.addAll(newComments);
        _hasMore = newComments.length >= 20;
        _lastCommentId = newComments.isNotEmpty
            ? newComments.last.id ?? _lastCommentId
            : _lastCommentId;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 评论标题
        _buildCommentHeader(),

        // 评论列表
        if (_error != null)
          buildCommonErrorWidget(error: _error, onRetry: _loadComments)
        else if (_comments.isEmpty && !_isLoading)
          buildCommonEmptyWidget(
            icon: Icons.comment,
            message: '暂无评论',
            subMessage: '该内容暂时没有评论',
          )
        else
          _buildCommentList(),
      ],
    );
  }

  /// 构建评论头部
  Widget _buildCommentHeader() {
    final commentCount = widget.initialCommentCount ?? _comments.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.comment_outlined, size: 20, color: Colors.black87),
          const SizedBox(width: 8),
          Text(
            '评论列表',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          if (commentCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$commentCount',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建评论列表
  Widget _buildCommentList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _comments.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _comments.length) {
          if (_isLoading) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return TextButton(
            onPressed: () {
              _loadMoreComments();
            },
            child: Text('加载更多'),
          );
        }

        final comment = _comments[index];
        return OneCommentWidget(comment: comment);
      },
    );
  }
}
