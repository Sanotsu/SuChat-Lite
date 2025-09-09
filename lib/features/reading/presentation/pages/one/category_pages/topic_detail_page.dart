import 'package:flutter/material.dart';

import '../../../../../../shared/widgets/common_error_empty_widgets.dart';
import '../../../../../../shared/widgets/image_preview_helper.dart';
import '../../../../data/datasources/one_api_manager.dart';
import '../../../../data/models/one/one_category_list.dart';
import '../../../../data/models/one/one_daily_recommend.dart';
import '../../../../data/models/one/one_detail_models.dart';
import '../../../../data/models/one/one_enums.dart';
import '../../../widgets/one/comment_widget.dart';
import '../../../widgets/one/recommend_card.dart';
import '../detail_page.dart';

// 专题详情页面
// 注意：其实topic详情中有个web_url 栏位，直接用 FullWebPage 渲染它也行的
// 但是这样就不脱离本应用了
class TopicDetailPage extends StatefulWidget {
  final OneTopic topic;

  const TopicDetailPage({super.key, required this.topic});

  @override
  State<TopicDetailPage> createState() => _TopicDetailPageState();
}

class _TopicDetailPageState extends State<TopicDetailPage> {
  final OneApiManager _apiManager = OneApiManager();

  OneContentDetail? _contentDetail;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTopicContent();
  }

  Future<void> _loadTopicContent() async {
    if (widget.topic.id == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final topicContent = await _apiManager.getOneContentDetail(
        category: "topic",
        contentId: int.parse(widget.topic.contentId!),
      );
      if (mounted) {
        setState(() {
          _contentDetail = topicContent;
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
        title: Text(widget.topic.title ?? '榜单详情'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return buildCommonErrorWidget(error: _error, onRetry: _loadTopicContent);
    }

    if (_contentDetail == null) {
      return buildCommonEmptyWidget(
        icon: Icons.menu_book,
        message: '暂无内容',
        subMessage: '该专题暂时没有内容',
      );
    }

    // return FullWebPage(url: _contentDetail!.webUrl!, showTitle: false);

    //  从上到下依次是背景图、专题标题、专题描述、内容列表、评论列表
    return _buildDetailContent();
  }

  /// 构建详情内容
  Widget _buildDetailContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部图片区域
          _buildHeaderImage(),

          // 标题和作者信息
          _buildTitleSection(),

          // 正文内容
          _buildListSection(),

          // 评论列表
          _buildCommentsSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 构建头部图片
  Widget _buildHeaderImage() {
    String? imageUrl;

    if (_contentDetail?.jsonContent?.special?.cover != null) {
      imageUrl = _contentDetail!.jsonContent!.special!.cover;
    }

    if (imageUrl == null) return const SizedBox.shrink();

    return SizedBox(
      height: 250,
      width: double.infinity,
      child: buildNetworkOrFileImage(imageUrl, fit: BoxFit.cover),
    );
  }

  /// 构建标题区域
  Widget _buildTitleSection() {
    String title = _contentDetail?.title ?? '';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ),

          if (title.contains("续杯"))
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text("好久不见，欢迎回家。咖啡凉了？换一杯热的吧。"),
            ),

          if (title.contains("时光"))
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text("读一篇好故事，不必离开房间，心灵已从远方旅行归来。"),
            ),

          if (title.contains("昨日"))
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text("十年了，还能遇见你，我想，我们都是幸运的。"),
            ),

          // 统计信息
          Row(
            children: [
              // 专题详情没有作者，暂定为one即可
              Expanded(
                child: Text(
                  'one',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),

              if (_contentDetail?.praisenum != null) ...[
                Icon(Icons.favorite, size: 16, color: Colors.red[300]),
                const SizedBox(width: 4),
                Text(
                  '${_contentDetail!.praisenum}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(width: 16),
              ],
              if (_contentDetail?.commentnum != null) ...[
                Icon(Icons.comment, size: 16, color: Colors.blue[300]),
                const SizedBox(width: 4),
                Text(
                  '${_contentDetail!.commentnum}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// 构建专题内容列表区域
  Widget _buildListSection() {
    List<OneRecommendContent>? contents;

    if (_contentDetail?.jsonContent?.oneDataArticles != null) {
      contents = _contentDetail!.jsonContent!.oneDataArticles;
    }

    if (contents == null) return const SizedBox.shrink();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: contents.length,
      itemBuilder: (context, index) {
        final content = contents![index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: OneRecommendCard(
            content: content,
            onTap: () => _navigateToDetail(content),
          ),
        );
      },
    );
  }

  /// 构建评论区域
  /// 实际只有编辑精选专题有评论，其他专题是没有的。
  /// 这里没有区分，其他分类查不到评论列表就只显示空的评论区而已
  Widget _buildCommentsSection() {
    return Column(
      children: [
        const Divider(),
        OneCommentListWidget(
          contentType: "topic",
          contentId: widget.topic.contentId!,
          initialCommentCount: _contentDetail?.commentnum,
        ),
      ],
    );
  }

  /// 导航到内容详情
  void _navigateToDetail(OneRecommendContent content) {
    // 使用枚举映射正确的分类
    final category = content.category ?? '1';
    final apiCategory = OneCategory.getApiName(category);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OneDetailPage(
          contentType: apiCategory,
          // 专题都是阅读，没有分类是图片hp，所以不用考虑
          contentId: content.itemId ?? content.contentId ?? '',
          title: content.title ?? '',
        ),
      ),
    );
  }
}
