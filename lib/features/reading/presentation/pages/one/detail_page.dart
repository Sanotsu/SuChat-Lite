import 'package:flutter/material.dart';

import '../../../../../shared/widgets/audio_player_widget.dart';
import '../../../../../shared/widgets/common_error_empty_widgets.dart';
import '../../../../../shared/widgets/image_preview_helper.dart';
import '../../../../../shared/widgets/simple_tool_widget.dart';
import '../../../data/datasources/one_api_manager.dart';
import '../../../data/models/one/one_base_models.dart';
import '../../../data/models/one/one_detail_models.dart';
import '../../../data/models/one/one_enums.dart';
import '../../../data/services/reading_settings_service.dart';
import '../../widgets/one/comment_widget.dart';
import '../../widgets/one/reading_settings.dart';
import 'category_pages/author_detail_page.dart';

/// One内容详情页面
class OneDetailPage extends StatefulWidget {
  // 内容类型：essay, question, music, movie, radio, topic, serialcontent, hp
  final String contentType;
  // 内容ID (hp图文小记类型的，需要在父组件替换为对应日期yyyy-MM-dd格式)
  final String contentId;
  // 标题
  final String title;

  const OneDetailPage({
    super.key,
    required this.contentType,
    required this.contentId,
    required this.title,
  });

  @override
  State<OneDetailPage> createState() => _OneDetailPageState();
}

class _OneDetailPageState extends State<OneDetailPage> {
  final OneApiManager _apiManager = OneApiManager();
  final ScrollController _scrollController = ScrollController();
  final ReadingSettingsService _settingsService = ReadingSettingsService();

  // 数据状态
  bool _isLoading = false;
  String? _error;
  OneContentDetail? _contentDetail;
  OneHpDetail? _hpDetail;
  // 使用枚举映射正确的API分类名称
  late String _apiCategory;

  // 阅读设置
  bool _isDarkMode = false;
  double _fontSize = 16.0;
  bool _showReadingProgress = true;
  double _readingProgress = 0.0;

  @override
  void initState() {
    super.initState();

    // 使用枚举映射正确的API分类名称
    _apiCategory = OneCategory.getApiName(widget.contentType);

    // 加载缓存的阅读设置
    _loadSettings();

    _loadDetailData();

    _setupScrollListener();
  }

  /// 加载缓存的阅读设置
  void _loadSettings() {
    setState(() {
      _fontSize = _settingsService.getFontSize();
      _isDarkMode = _settingsService.getIsDarkMode();
      _showReadingProgress = _settingsService.getShowReadingProgress();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 设置滚动监听器
  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_showReadingProgress) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;
        final progress = maxScroll > 0
            ? (currentScroll / maxScroll).clamp(0.0, 1.0)
            : 0.0;

        if ((progress - _readingProgress).abs() > 0.01) {
          setState(() {
            _readingProgress = progress;
          });
        }
      }
    });
  }

  /// 加载详情数据
  Future<void> _loadDetailData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_apiCategory == 'hp') {
        // 图文详情
        final detail = await _apiManager.getOneHpDetail(date: widget.contentId);
        if (mounted) {
          setState(() {
            _hpDetail = detail;
          });
        }
      } else {
        // 其他内容详情
        final detail = await _apiManager.getOneContentDetail(
          category: _apiCategory,
          contentId: int.parse(widget.contentId),
        );
        if (mounted) {
          setState(() {
            _contentDetail = detail;
          });
        }
      }

      if (mounted) {
        setState(() {
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
      rethrow;
    }
  }

  /// 导航到作者页面
  void _navigateToAuthorPage(OneAuthor author) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AuthorDetailPage(author: author)),
    );
  }

  /// 切换阅读设置
  void _showReadingSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: OneReadingSettings(
          isDarkMode: _isDarkMode,
          fontSize: _fontSize,
          showReadingProgress: _showReadingProgress,
          onDarkModeChanged: (value) async {
            setState(() {
              _isDarkMode = value;
            });
            await _settingsService.setIsDarkMode(value);
          },
          onFontSizeChanged: (value) async {
            setState(() {
              _fontSize = value;
            });
            await _settingsService.setFontSize(value);
          },
          onShowProgressChanged: (value) async {
            setState(() {
              _showReadingProgress = value;
            });
            await _settingsService.setShowReadingProgress(value);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
            style: TextStyle(fontSize: 20),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: _isDarkMode
              ? Colors.grey[900]
              : Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: _showReadingSettings,
            ),
          ],
        ),
        body: Column(
          children: [
            // 阅读进度条
            if (_showReadingProgress)
              LinearProgressIndicator(
                value: _readingProgress,
                backgroundColor: _isDarkMode ? Colors.grey : Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _isDarkMode ? Colors.white : Theme.of(context).primaryColor,
                ),
              ),
            // 内容区域
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? buildCommonErrorWidget(
                      error: _error,
                      onRetry: _loadDetailData,
                    )
                  : _buildDetailContent(),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建详情内容
  Widget _buildDetailContent() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和作者信息
          _buildTitleSection(),
          // 音频播放器（如果有音频）
          _buildAudioPlayer(),
          // 头部图片区域
          _buildHeaderImage(),
          // 正文内容
          _buildContentSection(),
          // 编辑信息
          _buildEditorSection(),
          // 作者信息
          _buildAuthorSection(),
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

    if (_contentDetail?.homeImage != null) {
      imageUrl = _contentDetail!.homeImage;
    } else if (_hpDetail?.imgUrl != null) {
      imageUrl = _hpDetail!.imgUrl;
    }

    if (imageUrl == null) return const SizedBox.shrink();

    return SizedBox(
      height: 250,
      width: double.infinity,
      child: buildNetworkOrFileImage(imageUrl, fit: BoxFit.cover),
      // 使用这个虽然可以点击缩放，但是默认显示有较大边距空白，上面那个没有
      // child: buildImageViewCarouselSlider([imageUrl]),
    );
  }

  /// 构建标题区域
  Widget _buildTitleSection() {
    final title = _contentDetail?.title ?? _hpDetail?.title ?? widget.title;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: _fontSize + 6,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // 统计信息
          // 图文(小记)的详情结构和其他完全不一样的，需要特殊处理
          if (_contentDetail?.jsonContent != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_contentDetail?.jsonContent?.simpleAuthor?.join(" ")}',
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

          if (_hpDetail != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    "${_hpDetail?.picInfo ?? ""} | ${_hpDetail?.volume ?? ""}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),

                // 图文小记的点赞数(没有评论栏位)
                if (_hpDetail?.likeCount != null) ...[
                  Icon(Icons.favorite, size: 16, color: Colors.blue[300]),
                  const SizedBox(width: 4),
                  Text(
                    '${_hpDetail!.likeCount}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  /// 构建音频播放器
  Widget _buildAudioPlayer() {
    String? audioUrl;

    if (_contentDetail?.audio != null) {
      audioUrl = _contentDetail!.audio;
    } else if (_contentDetail?.jsonContent?.audioUrl != null) {
      audioUrl = _contentDetail!.jsonContent!.audioUrl;
    } else if (_contentDetail?.jsonContent?.radioUrl != null) {
      audioUrl = _contentDetail!.jsonContent!.radioUrl;
    }

    if (audioUrl == null || audioUrl.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child:
          // 音频播放器
          // AudioPlayerWidget(
          //   audioUrl: audioUrl,
          //   sourceType: "network",
          //   // dense: true,
          // ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题和作者
              Row(
                children: [
                  Icon(
                    Icons.headphones,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _apiCategory == 'radio' ? "电台" : '有声阅读',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        if (_contentDetail?.anchor?.isNotEmpty == true)
                          Text(
                            '朗读者：${_contentDetail!.anchor}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // TODO 这个音频播放无法后台运行,在退出详情页面后就停止了
              // 但为了避免和其他地方会有音频播放的冲突，暂时就只在当前电台页面亮屏播放
              // 是否改造 OneAudioPlayer 并让其在后台播放呢,退出 one 模块就停止?
              AudioPlayerWidget(
                audioUrl: audioUrl,
                sourceType: "network",
                backgroundColor: Colors.transparent,
              ),
            ],
          ),
      // // 这个也行
      // OneAudioPlayer(
      //   audioUrl: audioUrl,
      //   title: widget.title,
      //   author: _getAuthorName(),
      // ),
    );
  }

  String filterHtmlTags(String htmlContent) {
    return htmlContent
        // 移除所有<p>开始标签
        .replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '')
        // </p>替换为双换行
        .replaceAll(RegExp(r'<\/p>', caseSensitive: false), '\n\n')
        // 处理&nbsp;换行
        .replaceAll(RegExp(r'&nbsp;', caseSensitive: false), '\n')
        // 移除所有剩余HTML标签
        .replaceAll(RegExp(r'<[^>]*>'), '')
        // 多个连续换行替换为双换行
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        // 移除首尾空白
        .trim();
  }

  /// 构建正文内容
  Widget _buildContentSection() {
    String? content;

    if (_contentDetail?.jsonContent?.content != null) {
      content = _contentDetail!.jsonContent!.content;
    } else if (_hpDetail?.forward != null) {
      content = _hpDetail!.forward;
    }

    if (content == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // const Divider(),
          const SizedBox(height: 16),
          SelectableText(
            filterHtmlTags(content),
            style: TextStyle(
              fontSize: _fontSize,
              height: 1.6,
              color: _isDarkMode ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  /// 构建编辑信息
  Widget _buildEditorSection() {
    final editor = _contentDetail?.jsonContent?.editor;
    final copyright = _contentDetail?.jsonContent?.copyright;

    if (editor == null && copyright == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          if (editor != null && editor.isNotEmpty)
            Text(
              editor,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),

          if (copyright != null && copyright.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              copyright,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建作者信息
  Widget _buildAuthorSection() {
    final authors = _contentDetail?.authorList ?? [];

    if (authors.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: _isDarkMode ? Colors.grey[700] : null),
          const SizedBox(height: 16),
          Text(
            '作者',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          ...authors.map(
            (author) => GestureDetector(
              onTap: () => _navigateToAuthorPage(author),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    buildUserCircleAvatar(author.webUrl, radius: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            author.userName ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          if (author.desc != null)
                            Text(
                              author.desc!,
                              style: TextStyle(
                                fontSize: 12,
                                color: _isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建评论区域
  Widget _buildCommentsSection() {
    // 如果不支持评论的内容类型，不显示评论区域
    // 虽然API中没写，但实测 topic 页可以查评论，尤其是一年一度编辑精选 /topic/166/0
    if (![
      'essay',
      'question',
      'music',
      'movie',
      'radio',
      'serialcontent',
    ].contains(widget.contentType)) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const Divider(),
        OneCommentListWidget(
          contentType: widget.contentType,
          contentId: widget.contentId,
          initialCommentCount: _contentDetail?.commentnum,
          isDarkMode: _isDarkMode,
        ),
      ],
    );
  }
}
