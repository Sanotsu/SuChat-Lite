import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../shared/widgets/common_error_empty_widgets.dart';
import '../../../data/datasources/tmdb/tmdb_apis.dart';
import '../../../data/models/tmdb/tmdb_all_image_resp.dart';
import '../../../data/models/tmdb/tmdb_common.dart';
import '../../../data/models/tmdb/tmdb_movie_detail_resp.dart';
import '../../../data/models/tmdb/tmdb_mt_credit_resp.dart';
import '../../../data/models/tmdb/tmdb_mt_review_resp.dart';
import '../../../data/models/tmdb/tmdb_person_credit_resp.dart';
import '../../../data/models/tmdb/tmdb_person_detail_resp.dart';
import '../../../data/models/tmdb/tmdb_result_resp.dart';
import '../../../data/models/tmdb/tmdb_tv_detail_resp.dart';
import '../../widgets/tmdb_widgets.dart';
import '../../widgets/tmdb_cast_crew_widget.dart';
import 'tmdb_full_review_page.dart';
import 'tmdb_gallery_page.dart';
import 'tmdb_cast_crew_page.dart';
import 'tmdb_reviews_page.dart';
import 'tmdb_similar_page.dart';

/// TMDB 详情页（电影/剧集/人物通用）
class TmdbDetailPage extends StatefulWidget {
  final TmdbResultItem item;
  final String mediaType; // movie, tv, person

  const TmdbDetailPage({
    super.key,
    required this.item,
    required this.mediaType,
  });

  @override
  State<TmdbDetailPage> createState() => _TmdbDetailPageState();
}

class _TmdbDetailPageState extends State<TmdbDetailPage> {
  final TmdbApiManager _apiManager = TmdbApiManager();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  String? _error;

  // 详情数据
  TmdbMovieDetailResp? _movieDetail;
  TmdbTvDetailResp? _tvDetail;
  TmdbPersonDetailResp? _personDetail;
  TmdbMTCreditResp? _credits;
  TmdbAllImageResp? _images;
  TmdbMTReviewResp? _reviews;
  TmdbResultResp? _similar;
  TmdbResultResp? _recommendations;
  TmdbPersonCreditResp? _personCredits;

  final currencyFormat = NumberFormat.currency(
    locale: 'zh_CN',
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();

    _loadDetailData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 加载详情数据
  Future<void> _loadDetailData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.mediaType == 'person') {
        await _loadPersonData();
      } else {
        await _loadMovieTvData();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      rethrow;
    }
  }

  /// 加载人物数据
  Future<void> _loadPersonData() async {
    final futures = await Future.wait([
      _apiManager.getPersonDetail(widget.item.id!),
      _apiManager.getPersonImages(widget.item.id!),
      _apiManager.getPersonCredit(widget.item.id!),
    ]);

    if (!mounted) return;
    setState(() {
      _personDetail = futures[0] as TmdbPersonDetailResp;
      _images = futures[1] as TmdbAllImageResp;
      _personCredits = futures[2] as TmdbPersonCreditResp;
      _isLoading = false;
    });
  }

  /// 加载电影/剧集数据
  Future<void> _loadMovieTvData() async {
    final List<Future> futures = [
      widget.mediaType == 'movie'
          ? _apiManager.getMovieDetail(widget.item.id!)
          : _apiManager.getTvDetail(widget.item.id!),
      widget.mediaType == 'movie'
          ? _apiManager.getMovieCredit(widget.item.id!)
          : _apiManager.getTvCredit(widget.item.id!),
      widget.mediaType == 'movie'
          ? _apiManager.getMovieImages(widget.item.id!)
          : _apiManager.getTvImages(widget.item.id!),
      widget.mediaType == 'movie'
          ? _apiManager.getMovieReviews(widget.item.id!)
          : _apiManager.getTvReviews(widget.item.id!),
      widget.mediaType == 'movie'
          ? _apiManager.getMovieSimilar(widget.item.id!)
          : _apiManager.getTvSimilar(widget.item.id!),
      widget.mediaType == 'movie'
          ? _apiManager.getMovieRecommendations(widget.item.id!)
          : _apiManager.getTvRecommendations(widget.item.id!),
    ];

    final results = await Future.wait(futures);

    if (!mounted) return;
    setState(() {
      if (widget.mediaType == 'movie') {
        _movieDetail = results[0] as TmdbMovieDetailResp;
      } else {
        _tvDetail = results[0] as TmdbTvDetailResp;
      }
      _credits = results[1] as TmdbMTCreditResp;
      _images = results[2] as TmdbAllImageResp;
      _reviews = results[3] as TmdbMTReviewResp;
      _similar = results[4] as TmdbResultResp;
      _recommendations = results[5] as TmdbResultResp;
      _isLoading = false;
    });
  }

  /// 获取标题
  String _getTitle() {
    if (widget.mediaType == 'person') {
      return _personDetail?.name ?? widget.item.name ?? '未知';
    }
    if (widget.mediaType == 'movie') {
      return _movieDetail?.title ?? widget.item.title ?? '未知';
    }
    return _tvDetail?.name ?? widget.item.name ?? '未知';
  }

  /// 获取海报路径
  String? _getPosterPath() {
    if (widget.mediaType == 'person') {
      return _personDetail?.profilePath ?? widget.item.profilePath;
    }
    if (widget.mediaType == 'movie') {
      return _movieDetail?.posterPath ?? widget.item.posterPath;
    }
    return _tvDetail?.posterPath ?? widget.item.posterPath;
  }

  /// 获取背景路径
  String? _getBackdropPath() {
    if (widget.mediaType == 'person') {
      // 人物没有背景图，用档案图代替
      return _personDetail?.profilePath ?? widget.item.profilePath;
    }
    if (widget.mediaType == 'movie') {
      return _movieDetail?.backdropPath ?? widget.item.backdropPath;
    }
    return _tvDetail?.backdropPath ?? widget.item.backdropPath;
  }

  /// 获取评分
  double _getRating() {
    if (widget.mediaType == 'person') {
      return 0.0; // 人物没有评分
    }
    if (widget.mediaType == 'movie') {
      return _movieDetail?.voteAverage ?? widget.item.voteAverage ?? 0.0;
    }
    return _tvDetail?.voteAverage ?? widget.item.voteAverage ?? 0.0;
  }

  /// 获取发布日期
  String _getReleaseDate() {
    if (widget.mediaType == 'person') {
      return _personDetail?.birthday ?? '未知';
    }
    if (widget.mediaType == 'movie') {
      return _movieDetail?.releaseDate ?? widget.item.releaseDate ?? '未知';
    }
    return _tvDetail?.firstAirDate ?? widget.item.firstAirDate ?? '未知';
  }

  /// 获取简介
  String _getOverview() {
    if (widget.mediaType == 'person') {
      return _personDetail?.biography ?? '暂无简介';
    }
    if (widget.mediaType == 'movie') {
      return _movieDetail?.overview ?? widget.item.overview ?? '暂无简介';
    }
    return _tvDetail?.overview ?? widget.item.overview ?? '暂无简介';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? buildCommonErrorWidget(
              error: _error,
              onRetry: _loadDetailData,
              showBack: true,
              context: context,
            )
          : _buildDetailContent(),
    );
  }

  /// 构建详情内容
  Widget _buildDetailContent() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // 顶部背景和基本信息
        _buildSliverAppBar(),
        // 详情内容
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 基本信息区域
              _buildBasicInfo(),
              // 更多信息
              _buildMoreInfo(),
              const SizedBox(height: 24),
              // 简介
              _buildOverviewSection(),
              const SizedBox(height: 24),
              // 根据类型显示不同内容
              if (widget.mediaType == 'person')
                ..._buildPersonSections()
              else
                ..._buildMovieTvSections(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建SliverAppBar
  Widget _buildSliverAppBar() {
    final backdropPath = _getBackdropPath();

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _getTitle(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(1, 1),
                blurRadius: 3,
                color: Colors.black54,
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (backdropPath != null)
              TmdbImageWidget(imagePath: backdropPath, fit: BoxFit.cover)
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).primaryColor.withValues(alpha: 0.8),
                      Theme.of(context).primaryColor,
                    ],
                  ),
                ),
              ),
            // 渐变遮罩
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建基本信息
  Widget _buildBasicInfo() {
    // 人物的基本信息组件列表(不手动加分割高度，构建时再处理)
    var personList = [
      // 生日
      if (_personDetail?.birthday != null)
        _buildInfoItem(_personDetail!.birthday!, icon: Icons.cake),

      // 性别
      if (_personDetail?.gender != null)
        _buildInfoItem(
          _personDetail!.gender == 0
              ? '未设置'
              : _personDetail!.gender == 1
              ? '女'
              : _personDetail!.gender == 2
              ? '男'
              : '非二元性别',
          icon: _personDetail!.gender == 1
              ? Icons.female
              : _personDetail!.gender == 2
              ? Icons.male
              : Icons.person,
        ),

      // 从事的行业
      if (_personDetail?.knownForDepartment != null)
        _buildInfoItem(_personDetail!.knownForDepartment!, icon: Icons.work),

      // 出生地
      if (_personDetail?.placeOfBirth != null)
        _buildInfoItem(_personDetail!.placeOfBirth!, icon: Icons.location_on),
    ];

    // 电影和剧集都有的基础信息
    var mtCommonList = [
      // 评分
      Row(
        children: [
          Icon(Icons.star, color: Colors.amber, size: 20),
          const SizedBox(width: 4),
          Text(
            _getRating().toStringAsFixed(1),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(
            '(${_movieDetail?.voteCount ?? widget.item.voteCount ?? 0})',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),

      // 上映/开播时间
      _buildInfoItem(_getReleaseDate(), icon: Icons.calendar_today),

      // 语言信息
      _buildInfoItem(
        _getLanguageName(_getOriginalLanguage() ?? ''),
        icon: Icons.language,
      ),

      // 题材
      _buildInfoItem(_getGenres(), icon: Icons.tag),
    ];

    // 电影的基础信息列表
    var movieList = [
      ...mtCommonList,

      // 电影时长
      if (_movieDetail?.runtime != null)
        _buildInfoItem('${_movieDetail!.runtime} 分钟', icon: Icons.access_time),

      // 原名
      if (_movieDetail?.originalTitle != null)
        _buildInfoItem(_movieDetail!.originalTitle!, icon: Icons.text_fields),
    ];

    // 电视剧的基础信息列表
    var tvList = [
      ...mtCommonList,

      // 原名
      if (_tvDetail?.originalName != null)
        _buildInfoItem(_tvDetail!.originalName!, icon: Icons.text_fields),

      // 季数信息
      if (_tvDetail?.numberOfSeasons != null)
        _buildInfoItem(
          '${_tvDetail!.numberOfSeasons} 季',
          icon: Icons.format_list_numbered,
        ),

      // 集数信息
      if (_tvDetail?.numberOfEpisodes != null)
        _buildInfoItem(
          '${_tvDetail!.numberOfEpisodes} 集',
          icon: Icons.format_list_numbered,
        ),

      // 状态信息
      if (_tvDetail?.status != null)
        _buildInfoItem(
          _getStatusName(_tvDetail!.status!),
          icon: Icons.info_outline,
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 海报
          Container(
            width: 120,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: TmdbImageWidget(
                imagePath: _getPosterPath(),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 基本信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text(
                //   _getTitle(),
                //   style: const TextStyle(
                //     fontSize: 20,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
                // const SizedBox(height: 8),
                if (widget.mediaType == 'person') ...[...personList],
                if (widget.mediaType == 'movie') ...[...movieList],
                if (widget.mediaType == 'tv') ...[...tvList],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建更多信息
  Widget _buildMoreInfo() {
    var personList = [
      // 别名
      if (_personDetail?.alsoKnownAs?.isNotEmpty ?? false)
        _buildInfoItem(_personDetail!.alsoKnownAs!.join(', '), label: '别名'),

      // 热度
      if (_personDetail?.popularity != null)
        _buildInfoItem(_personDetail!.popularity!.toString(), label: '热度'),

      // imdb编号
      if (_personDetail?.imdbId != null)
        _buildInfoItem(_personDetail!.imdbId!, label: 'IMDB编号'),
    ];

    var mtCommonList = [
      // 制作公司信息
      if (_getProductionCompanies().isNotEmpty)
        _buildInfoItem(_getProductionCompanies().join(', '), label: '制作公司'),

      // 制作国家/地区
      if (_getProductionCountries().isNotEmpty)
        _buildInfoItem(_getProductionCountries().join(', '), label: '国家/地区'),

      // 标语
      if (_getTagline().isNotEmpty) _buildInfoItem(_getTagline(), label: '标语'),

      // 状态
      _buildInfoItem(
        ((widget.mediaType == 'tv')
                ? _tvDetail?.status
                : _movieDetail?.status) ??
            '',
        label: '状态',
      ),
    ];

    var movieList = [
      ...mtCommonList,

      // 预算
      if (_movieDetail?.budget != null)
        _buildInfoItem(
          currencyFormat.format(_movieDetail!.budget!),
          label: '预算',
        ),

      // 票房
      if (_movieDetail?.revenue != null)
        _buildInfoItem(
          currencyFormat.format(_movieDetail!.revenue!),
          label: '票房',
        ),

      // 热度
      if (_movieDetail?.popularity != null)
        _buildInfoItem(_movieDetail!.popularity!.toString(), label: '热度'),

      // IMDB编号
      if (_movieDetail?.imdbId != null)
        _buildInfoItem(_movieDetail!.imdbId!, label: 'IMDB编号'),
    ];

    var tvList = [
      ...mtCommonList,

      // 创作者
      if (_tvDetail?.createdBy?.isNotEmpty ?? false)
        _buildInfoItem(
          _tvDetail!.createdBy!.map((c) => c.name).join(', '),
          label: '创作者',
        ),

      // 播出平台
      if (_tvDetail?.networks?.isNotEmpty ?? false)
        _buildInfoItem(
          _tvDetail!.networks!.map((n) => n.name).join(', '),
          label: '播出平台',
        ),

      // 首播日期
      if (_tvDetail?.firstAirDate != null)
        _buildInfoItem(_tvDetail!.firstAirDate ?? '', label: '首播日期'),

      // // 季数信息
      // if (_tvDetail?.numberOfSeasons != null)
      //   _buildInfoItem('${_tvDetail!.numberOfSeasons} 季', label: '季数'),

      // // 集数信息
      // if (_tvDetail?.numberOfEpisodes != null)
      //   _buildInfoItem('${_tvDetail!.numberOfEpisodes} 集', label: '集数'),

      // 上次播出时间
      if (_tvDetail?.lastAirDate != null)
        _buildInfoItem(_tvDetail!.lastAirDate!, label: '上次播出'),

      // 类型
      if (_tvDetail?.type != null)
        _buildInfoItem(_tvDetail!.type!, label: '类型'),

      // 热度
      if (_tvDetail?.popularity != null)
        _buildInfoItem(_tvDetail!.popularity!.toString(), label: '热度'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.mediaType == 'person') ...personList,
          if (widget.mediaType == 'movie') ...movieList,
          if (widget.mediaType == 'tv') ...tvList,
        ],
      ),
    );
  }

  Widget _buildInfoItem(String value, {IconData? icon, String? label}) {
    return Row(
      children: [
        if (icon != null) Icon(icon, size: 16, color: Colors.grey[600]),
        if (label != null)
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.black),
              textAlign: TextAlign.justify,
            ),
          ),

        const SizedBox(width: 4),
        Expanded(
          child: SelectableText(
            value,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  /// 构建简介部分
  Widget _buildOverviewSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '简介',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            _getOverview(),
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }

  /// 构建人物相关部分
  List<Widget> _buildPersonSections() {
    return [
      // 图片
      if (_images?.profiles?.isNotEmpty ?? false) ...[
        TmdbSectionWidget(
          title: '图片',
          items: [],
          onItemTap: (_) {},
          customChild: _buildImageGallery(),
          showMoreButton: true,
          onShowMore: () => _navigateToGallery(),
        ),
        const SizedBox(height: 24),
      ],
      // 参与演出(演员)
      if (_personCredits?.cast?.isNotEmpty ?? false) ...[
        TmdbSectionWidget(
          title: '参与演出',
          items: _personCredits!.cast!,
          onItemTap: _navigateToDetail,
        ),
        const SizedBox(height: 24),
      ],
      // 参与制作(工作人员)
      if (_personCredits?.crew?.isNotEmpty ?? false) ...[
        TmdbSectionWidget(
          title: '参与制作',
          items: _personCredits!.crew!,
          onItemTap: _navigateToDetail,
        ),
        const SizedBox(height: 24),
      ],
    ];
  }

  /// 构建电影/剧集相关部分
  List<Widget> _buildMovieTvSections() {
    return [
      // 演职表
      if (_credits?.cast?.isNotEmpty ?? false) ...[
        TmdbCastCrewWidget(
          title: '演职表',
          items: _credits!.cast!,
          onItemTap: (credit) => _navigateToPersonDetail(credit),
          showMoreButton: true,
          onShowMore: () => _navigateToCastCrew(),
        ),
        const SizedBox(height: 24),
      ],
      // 剧照
      if (_images?.backdrops?.isNotEmpty ?? false) ...[
        TmdbSectionWidget(
          title: '剧照',
          items: [],
          onItemTap: (_) {},
          customChild: _buildImageGallery(),
          showMoreButton: true,
          onShowMore: () => _navigateToGallery(),
        ),
        const SizedBox(height: 24),
      ],
      // 评论
      if (_reviews?.results?.isNotEmpty ?? false) ...[
        _buildReviewsSection(),
        const SizedBox(height: 24),
      ],
      // 相似内容
      if (_similar?.results?.isNotEmpty ?? false) ...[
        TmdbSectionWidget(
          title: '相似${widget.mediaType == 'movie' ? '电影' : '剧集'}',
          items: _similar!.results!,
          onItemTap: _navigateToDetail,
          showMoreButton: true,
          onShowMore: _navigateToSimilar,
        ),
        const SizedBox(height: 24),
      ],
      // 推荐内容
      if (_recommendations?.results?.isNotEmpty ?? false) ...[
        TmdbSectionWidget(
          title: '推荐${widget.mediaType == 'movie' ? '电影' : '剧集'}',
          items: _recommendations!.results!,
          onItemTap: _navigateToDetail,
          showMoreButton: true,
          onShowMore: _navigateToRecommendations,
        ),
        const SizedBox(height: 24),
      ],
    ];
  }

  /// 构建图片画廊
  Widget _buildImageGallery() {
    final images = widget.mediaType == 'person'
        ? _images?.profiles
        : _images?.backdrops;

    if (images?.isEmpty ?? true) return const SizedBox.shrink();

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: (images!.length > 10 ? 10 : images.length),
        itemBuilder: (context, index) {
          final image = images[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TmdbImageWidget(
                imagePath: image.filePath,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建评论部分
  Widget _buildReviewsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '评论',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              // if ((_reviews?.results?.length ?? 0) > 3)
              TextButton(
                onPressed: _navigateToReviews,
                child: const Text('查看全部'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 详情页只展示最多3条评论，每条评论最多3行，详细内容点击“查看全部”
          ...(_reviews?.results?.take(3) ?? []).map((review) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        child: Text(
                          review.author?.substring(0, 1).toUpperCase() ?? 'A',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          review.author ?? '匿名用户',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (review.authorDetails?.rating != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${review.authorDetails!.rating}/10',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 默认在详情页只显示3条评论，如果超过3条，则到评论列表页面去
                  InkWell(
                    onTap: () => _navigateToReview(review),
                    child: Text(
                      review.content ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(height: 1.4),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 导航到详情页
  void _navigateToDetail(TmdbResultItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TmdbDetailPage(item: item, mediaType: item.mediaType ?? 'movie'),
      ),
    );
  }

  void _navigateToPersonDetail(TmdbCredit credit) {
    // 将TmdbCredit转换为TmdbResultItem
    final item = TmdbResultItem(
      id: credit.id,
      name: credit.name,
      profilePath: credit.profilePath,
      mediaType: 'person',
    );
    _navigateToDetail(item);
  }

  /// 导航到图片画廊
  void _navigateToGallery() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TmdbGalleryPage(
          title: _getTitle(),
          images: _images!,
          mediaType: widget.mediaType,
        ),
      ),
    );
  }

  /// 导航到演职表页面
  void _navigateToCastCrew() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TmdbCastCrewPage(title: _getTitle(), credits: _credits!),
      ),
    );
  }

  // 导航到评论页面
  void _navigateToReviews() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TmdbReviewsPage(title: '评论列表', reviews: _reviews!.results!),
      ),
    );
  }

  void _navigateToSimilar() {
    if (widget.item.id == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TmdbSimilarPage(
          mediaId: widget.item.id!,
          mediaType: widget.mediaType,
          contentType: 'similar',
          title: "${_getTitle()} 相似",
        ),
      ),
    );
  }

  void _navigateToRecommendations() {
    if (widget.item.id == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TmdbSimilarPage(
          mediaId: widget.item.id!,
          mediaType: widget.mediaType,
          contentType: 'recommendations',
          title: "${_getTitle()} 推荐",
        ),
      ),
    );
  }

  void _navigateToReview(TmdbReviewItem review) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TmdbFullReviewPage(review: review),
      ),
    );
  }

  /// 获取语言名称
  String _getLanguageName(String languageCode) {
    final languageMap = {
      'en': '英语',
      'zh': '中文',
      'ja': '日语',
      'ko': '韩语',
      'fr': '法语',
      'de': '德语',
      'es': '西班牙语',
      'it': '意大利语',
      'ru': '俄语',
      'pt': '葡萄牙语',
      'ar': '阿拉伯语',
      'hi': '印地语',
      'th': '泰语',
      'vi': '越南语',
    };
    return languageMap[languageCode] ?? languageCode.toUpperCase();
  }

  /// 获取状态名称
  String _getStatusName(String status) {
    final statusMap = {
      'Returning Series': '连载中',
      'Ended': '已完结',
      'Canceled': '已取消',
      'In Production': '制作中',
      'Planned': '计划中',
      'Pilot': '试播集',
      'Released': '已上映',
      'Post Production': '后期制作',
      'Rumored': '传闻',
    };
    return statusMap[status] ?? status;
  }

  /// 获取制作公司列表
  List<String> _getProductionCompanies() {
    if (widget.mediaType == 'tv') {
      return _tvDetail?.productionCompanies
              ?.map((c) => c.name ?? '')
              .where((name) => name.isNotEmpty)
              .toList() ??
          [];
    } else {
      return _movieDetail?.productionCompanies
              ?.map((c) => c.name ?? '')
              .where((name) => name.isNotEmpty)
              .toList() ??
          [];
    }
  }

  /// 获取原始语言
  String? _getOriginalLanguage() {
    if (widget.mediaType == 'tv') {
      return _tvDetail?.originalLanguage;
    } else {
      return _movieDetail?.originalLanguage;
    }
  }

  /// 获取题材信息
  String _getGenres() {
    if (widget.mediaType == 'tv') {
      return _tvDetail?.genres?.map((g) => g.name).join(', ') ?? '';
    } else {
      return _movieDetail?.genres?.map((g) => g.name).join(', ') ?? '';
    }
  }

  /// 获取标语
  String _getTagline() {
    if (widget.mediaType == 'tv') {
      return _tvDetail?.tagline ?? '';
    } else {
      return _movieDetail?.tagline ?? '';
    }
  }

  /// 获取制作国家列表
  List<String> _getProductionCountries() {
    if (widget.mediaType == 'tv') {
      return _tvDetail?.productionCountries
              ?.map((c) => c.name ?? '')
              .where((name) => name.isNotEmpty)
              .toList() ??
          [];
    } else {
      return _movieDetail?.productionCountries
              ?.map((c) => c.name ?? '')
              .where((name) => name.isNotEmpty)
              .toList() ??
          [];
    }
  }
}
