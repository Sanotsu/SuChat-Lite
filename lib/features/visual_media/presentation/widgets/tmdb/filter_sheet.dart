import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:tmdb_api/tmdb_api.dart';

import '../../../data/models/tmdb/tmdb_filter_params.dart';

/// TMDB 高级筛选组件
class TmdbFilterSheet extends StatefulWidget {
  final String mediaType;
  final MovieFilterParams movieParams;
  final TvFilterParams tvParams;
  final Function(MovieFilterParams, TvFilterParams) onApplyFilter;

  const TmdbFilterSheet({
    super.key,
    required this.mediaType,
    required this.movieParams,
    required this.tvParams,
    required this.onApplyFilter,
  });

  @override
  State<TmdbFilterSheet> createState() => _TmdbFilterSheetState();
}

class _TmdbFilterSheetState extends State<TmdbFilterSheet> {
  late MovieFilterParams _movieParams;
  late TvFilterParams _tvParams;
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    _movieParams = widget.movieParams;
    _tvParams = widget.tvParams;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _resetFilters() {
    // 重置参数对象为默认值
    _movieParams = MovieFilterParams();
    _tvParams = TvFilterParams();

    // 重置表单
    _formKey.currentState?.reset();

    // 强制清空所有字段，包括下拉框等
    _formKey.currentState?.fields.forEach((key, field) {
      field.didChange(null);
    });

    setState(() {});
  }

  void _applyFilters() {
    // 保存表单并获取当前值
    _formKey.currentState?.save();
    final formValues = _formKey.currentState?.value ?? {};

    // 根据媒体类型更新相应的参数
    if (widget.mediaType == 'movie') {
      // 重新创建参数对象，确保null值能正确覆盖
      _movieParams = MovieFilterParams(
        sortBy: formValues['movieSortBy'] ?? SortMoviesBy.popularityDesc,

        // 发布年份原接口没有，实际是发布日期。
        // 这里获取年份，构建为日期
        releaseDateGreaterThan:
            (int.tryParse(formValues['movieReleaseYearMin'] ?? '') != null)
            ? DateTime(
                int.parse(formValues['movieReleaseYearMin']?.toString() ?? ''),
                1,
                1,
              )
            : DateTime(2010, 1, 1),

        releaseDateLessThan:
            (int.tryParse(formValues['movieReleaseYearMax'] ?? '') != null)
            ? DateTime(
                int.parse(formValues['movieReleaseYearMax']?.toString() ?? ''),
                12,
                31,
              )
            : DateTime.now(),
        voteAverageGreaterThan: double.tryParse(
          formValues['movieRatingMin']?.toString() ?? '',
        ),
        voteAverageLessThan: double.tryParse(
          formValues['movieRatingMax']?.toString() ?? '',
        ),
        voteCountGreaterThan: int.tryParse(
          formValues['movieRatingCountMin']?.toString() ?? '',
        ),
        voteCountLessThan: int.tryParse(
          formValues['movieRatingCountMax']?.toString() ?? '',
        ),
        withRunTimeGreaterThan: int.tryParse(
          formValues['movieRuntimeMin']?.toString() ?? '',
        ),
        withRuntimeLessThan: int.tryParse(
          formValues['movieRuntimeMax']?.toString() ?? '',
        ),
        withGenres: formValues['movieGenres'] is List<int>
            ? formValues['movieGenres']
            : (formValues['movieGenres'] as List?)?.cast<int>(),
        withOriginalLanguage: formValues['movieLanguage'],
      );
    } else {
      // 重新创建参数对象，确保null值能正确覆盖
      _tvParams = TvFilterParams(
        sortBy: formValues['tvSortBy'] ?? SortTvShowsBy.popularityDesc,
        firstAirDateYear: int.tryParse(
          formValues['firstAirDateYear']?.toString() ?? '',
        ),
        voteAverageGte: double.tryParse(
          formValues['tvRatingMin']?.toString() ?? '',
        ),
        voteAverageLte: double.tryParse(
          formValues['tvRatingMax']?.toString() ?? '',
        ),
        voteCountGte: int.tryParse(
          formValues['tvRatingCountMin']?.toString() ?? '',
        ),
        voteCountLte: int.tryParse(
          formValues['tvRatingCountMax']?.toString() ?? '',
        ),
        withRuntimeGte: int.tryParse(
          formValues['tvRuntimeMin']?.toString() ?? '',
        ),
        withRuntimeLte: int.tryParse(
          formValues['tvRuntimeMax']?.toString() ?? '',
        ),
        withGenres: formValues['tvGenres'] is List<int>
            ? formValues['tvGenres']
            : (formValues['tvGenres'] as List?)?.cast<int>(),
        withStatus: formValues['tvStatus'],
        withOriginalLanguage: formValues['tvLanguage'],
      );
    }

    widget.onApplyFilter(_movieParams, _tvParams);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '高级筛选 - ${widget.mediaType == 'movie' ? '电影' : '剧集'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // 筛选内容
          Expanded(
            child: FormBuilder(
              key: _formKey,
              child: widget.mediaType == 'movie'
                  ? _buildMovieFilterContent()
                  : _buildTvFilterContent(),
            ),
          ),
          // 底部按钮
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetFilters,
                    child: const Text('重置'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    child: const Text('应用筛选'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieFilterContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 排序方式
          _buildSectionTitle('排序方式'),
          _buildMovieSortDropdown(),
          const SizedBox(height: 16),

          // 发布年份
          _buildSectionTitle('发布年份'),
          _buildMovieReleaseYearFilter(),
          const SizedBox(height: 16),

          // 评分范围
          _buildSectionTitle('评分范围'),
          _buildMovieRatingFilter(),
          const SizedBox(height: 16),

          // 评分人数
          _buildSectionTitle('评分人数'),
          _buildMovieRatingCountFilter(),
          const SizedBox(height: 16),

          // 时长范围
          _buildSectionTitle('时长范围（分钟）'),
          _buildMovieRuntimeFilter(),
          const SizedBox(height: 16),

          // 类型选择
          _buildSectionTitle('类型'),
          _buildMovieGenreFilter(),
          const SizedBox(height: 16),

          // 语言选择
          _buildSectionTitle('原始语言'),
          _buildMovieLanguageFilter(),
        ],
      ),
    );
  }

  Widget _buildTvFilterContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 排序方式
          _buildSectionTitle('排序方式'),
          _buildTvSortDropdown(),
          const SizedBox(height: 16),

          // 首播年份
          _buildSectionTitle('首播年份'),
          _buildTvFirstAirDateYearFilter(),
          const SizedBox(height: 16),

          // 评分范围
          _buildSectionTitle('评分范围'),
          _buildTvRatingFilter(),
          const SizedBox(height: 16),

          // 评分人数
          _buildSectionTitle('评分人数'),
          _buildTvRatingCountFilter(),
          const SizedBox(height: 16),

          // 单集时长范围
          _buildSectionTitle('单集时长范围（分钟）'),
          _buildTvRuntimeFilter(),
          const SizedBox(height: 16),

          // 类型选择
          _buildSectionTitle('类型'),
          _buildTvGenreFilter(),
          const SizedBox(height: 16),

          // 状态筛选
          _buildSectionTitle('播出状态'),
          _buildTvStatusFilter(),
          const SizedBox(height: 16),

          // 语言选择
          _buildSectionTitle('原始语言'),
          _buildTvLanguageFilter(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMovieSortDropdown() {
    return FormBuilderDropdown<SortMoviesBy>(
      name: 'movieSortBy',
      initialValue: _movieParams.sortBy,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: const [
        DropdownMenuItem(
          value: SortMoviesBy.popularityDesc,
          child: Text('受欢迎度 ↓'),
        ),
        DropdownMenuItem(
          value: SortMoviesBy.popularityAsc,
          child: Text('受欢迎度 ↑'),
        ),
        DropdownMenuItem(
          value: SortMoviesBy.primaryReleaseDateDesc,
          child: Text('发布日期 ↓'),
        ),
        DropdownMenuItem(
          value: SortMoviesBy.primaryReleaseDateAsc,
          child: Text('发布日期 ↑'),
        ),
        DropdownMenuItem(
          value: SortMoviesBy.voteAverageDesc,
          child: Text('评分 ↓'),
        ),
        DropdownMenuItem(
          value: SortMoviesBy.voteAverageAsc,
          child: Text('评分 ↑'),
        ),
        DropdownMenuItem(
          value: SortMoviesBy.voteCountDesc,
          child: Text('评分人数 ↓'),
        ),
        DropdownMenuItem(
          value: SortMoviesBy.voteCountAsc,
          child: Text('评分人数 ↑'),
        ),
        DropdownMenuItem(value: SortMoviesBy.revenueDesc, child: Text('票房 ↓')),
        DropdownMenuItem(value: SortMoviesBy.revenueAsc, child: Text('票房 ↑')),
      ],
    );
  }

  // 2025-08-18
  // 这里 SortTvShowsBy 和官方文档数据有差异，但为了省事没有自动补充完整
  Widget _buildTvSortDropdown() {
    return FormBuilderDropdown<SortTvShowsBy>(
      name: 'tvSortBy',
      initialValue: _tvParams.sortBy,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: const [
        DropdownMenuItem(
          value: SortTvShowsBy.popularityDesc,
          child: Text('受欢迎度 ↓'),
        ),
        DropdownMenuItem(
          value: SortTvShowsBy.popularityAsc,
          child: Text('受欢迎度 ↑'),
        ),
        DropdownMenuItem(
          value: SortTvShowsBy.firstAirDateDesc,
          child: Text('首播日期 ↓'),
        ),
        DropdownMenuItem(
          value: SortTvShowsBy.firstAirDateAsc,
          child: Text('首播日期 ↑'),
        ),
        DropdownMenuItem(
          value: SortTvShowsBy.voteAverageDesc,
          child: Text('评分 ↓'),
        ),
        DropdownMenuItem(
          value: SortTvShowsBy.voteAverageAsc,
          child: Text('评分 ↑'),
        ),
      ],
    );
  }

  Widget _buildMovieReleaseYearFilter() {
    return Row(
      children: [
        Expanded(
          child: FormBuilderTextField(
            name: 'movieReleaseYearMin',
            initialValue: _movieParams.releaseDateGreaterThan?.year.toString(),
            decoration: const InputDecoration(
              labelText: '最早年份',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FormBuilderTextField(
            name: 'movieReleaseYearMax',
            initialValue: _movieParams.releaseDateLessThan?.year.toString(),
            decoration: const InputDecoration(
              labelText: '最晚年份',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _buildTvFirstAirDateYearFilter() {
    return FormBuilderTextField(
      name: 'firstAirDateYear',
      initialValue: _tvParams.firstAirDateYear?.toString(),
      decoration: const InputDecoration(
        labelText: '首播年份',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildMovieRatingFilter() {
    return Row(
      children: [
        Expanded(
          child: FormBuilderTextField(
            name: 'movieRatingMin',
            initialValue: _movieParams.voteAverageGreaterThan?.toString(),
            decoration: const InputDecoration(
              labelText: '最低评分',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FormBuilderTextField(
            name: 'movieRatingMax',
            initialValue: _movieParams.voteAverageLessThan?.toString(),
            decoration: const InputDecoration(
              labelText: '最高评分',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  // 评分人数
  Widget _buildMovieRatingCountFilter() {
    return Row(
      children: [
        Expanded(
          child: FormBuilderTextField(
            name: 'movieRatingCountMin',
            initialValue: _movieParams.voteCountGreaterThan?.toString(),
            decoration: const InputDecoration(
              labelText: '最低评分人数',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FormBuilderTextField(
            name: 'movieRatingCountMax',
            initialValue: _movieParams.voteCountLessThan?.toString(),
            decoration: const InputDecoration(
              labelText: '最高评分人数',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _buildTvRatingFilter() {
    return Row(
      children: [
        Expanded(
          child: FormBuilderTextField(
            name: 'tvRatingMin',
            initialValue: _tvParams.voteAverageGte?.toString(),
            decoration: const InputDecoration(
              labelText: '最低评分',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FormBuilderTextField(
            name: 'tvRatingMax',
            initialValue: _tvParams.voteAverageLte?.toString(),
            decoration: const InputDecoration(
              labelText: '最高评分',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  // 评分人数
  Widget _buildTvRatingCountFilter() {
    return Row(
      children: [
        Expanded(
          child: FormBuilderTextField(
            name: 'tvRatingCountMin',
            initialValue: _tvParams.voteCountGte?.toString(),
            decoration: const InputDecoration(
              labelText: '最低评分人数',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FormBuilderTextField(
            name: 'tvRatingCountMax',
            initialValue: _tvParams.voteCountLte?.toString(),
            decoration: const InputDecoration(
              labelText: '最高评分人数',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _buildMovieRuntimeFilter() {
    return Row(
      children: [
        Expanded(
          child: FormBuilderTextField(
            name: 'movieRuntimeMin',
            initialValue: _movieParams.withRunTimeGreaterThan?.toString(),
            decoration: const InputDecoration(
              labelText: '最短时长',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FormBuilderTextField(
            name: 'movieRuntimeMax',
            initialValue: _movieParams.withRuntimeLessThan?.toString(),
            decoration: const InputDecoration(
              labelText: '最长时长',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _buildTvRuntimeFilter() {
    return Row(
      children: [
        Expanded(
          child: FormBuilderTextField(
            name: 'tvRuntimeMin',
            initialValue: _tvParams.withRuntimeGte?.toString(),
            decoration: const InputDecoration(
              labelText: '最短时长',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FormBuilderTextField(
            name: 'tvRuntimeMax',
            initialValue: _tvParams.withRuntimeLte?.toString(),
            decoration: const InputDecoration(
              labelText: '最长时长',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _buildMovieGenreFilter() {
    // 2025-08-18 查询时与接口中返回数据一致
    // https://developer.themoviedb.org/reference/genre-movie-list
    final movieGenres = [
      {'id': 28, 'name': '动作'},
      {'id': 12, 'name': '冒险'},
      {'id': 16, 'name': '动画'},
      {'id': 35, 'name': '喜剧'},
      {'id': 80, 'name': '犯罪'},
      {'id': 99, 'name': '纪录'},
      {'id': 18, 'name': '剧情'},
      {'id': 10751, 'name': '家庭'},
      {'id': 14, 'name': '奇幻'},
      {'id': 36, 'name': '历史'},
      {'id': 27, 'name': '恐怖'},
      {'id': 10402, 'name': '音乐'},
      {'id': 9648, 'name': '悬疑'},
      {'id': 10749, 'name': '爱情'},
      {'id': 878, 'name': '科幻'},
      {'id': 53, 'name': '惊悚'},
      {'id': 10752, 'name': '战争'},
      {'id': 37, 'name': '西部'},
      {'id': 10770, 'name': '电视电影'},
    ];

    return FormBuilderCheckboxGroup<int>(
      name: 'movieGenres',
      initialValue: _movieParams.withGenres,
      options: movieGenres
          .map(
            (genre) => FormBuilderFieldOption(
              value: genre['id'] as int,
              child: Text(genre['name'] as String),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTvGenreFilter() {
    // 2025-08-18 查询时与接口中返回数据一致
    // https://developer.themoviedb.org/reference/genre-tv-list
    final tvGenres = [
      {'id': 10759, 'name': '动作冒险'},
      {'id': 16, 'name': '动画'},
      {'id': 35, 'name': '喜剧'},
      {'id': 80, 'name': '犯罪'},
      {'id': 99, 'name': '纪录'},
      {'id': 18, 'name': '剧情'},
      {'id': 10751, 'name': '家庭'},
      {'id': 10762, 'name': '儿童'},
      {'id': 9648, 'name': '悬疑'},
      {'id': 10763, 'name': '新闻'},
      {'id': 10764, 'name': '真人秀'},
      {'id': 10765, 'name': '科幻奇幻'},
      {'id': 10766, 'name': '肥皂剧'},
      {'id': 10767, 'name': '脱口秀'},
      {'id': 10768, 'name': '战争政治'},
      {'id': 37, 'name': '西部'},
    ];
    // 经常在写代码或者其他技术方向遇到问题时能在linux do的佬们的讨论中得到一些启发或者经验，感觉能在这里学到不少东西，希望可以可大佬们多多交流，增长见识。
    return FormBuilderCheckboxGroup<int>(
      name: 'tvGenres',
      initialValue: _tvParams.withGenres,
      options: tvGenres
          .map(
            (genre) => FormBuilderFieldOption(
              value: genre['id'] as int,
              child: Text(genre['name'] as String),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTvStatusFilter() {
    return FormBuilderDropdown<FilterTvShowsByStatus?>(
      name: 'tvStatus',
      initialValue: _tvParams.withStatus,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        hintText: '选择播出状态',
      ),
      items: const [
        DropdownMenuItem(value: null, child: Text('全部状态')),
        DropdownMenuItem(
          value: FilterTvShowsByStatus.returningSeries,
          child: Text('连载中'),
        ),
        DropdownMenuItem(
          value: FilterTvShowsByStatus.ended,
          child: Text('已完结'),
        ),
        DropdownMenuItem(
          value: FilterTvShowsByStatus.cancelled,
          child: Text('已取消'),
        ),
        DropdownMenuItem(
          value: FilterTvShowsByStatus.inProduction,
          child: Text('制作中'),
        ),
        DropdownMenuItem(
          value: FilterTvShowsByStatus.planned,
          child: Text('计划中'),
        ),
        DropdownMenuItem(
          value: FilterTvShowsByStatus.pilot,
          child: Text('试播集'),
        ),
      ],
    );
  }

  Widget _buildMovieLanguageFilter() {
    return FormBuilderDropdown<String?>(
      name: 'movieLanguage',
      initialValue: _movieParams.withOriginalLanguage,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        hintText: '选择原始语言',
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('全部语言')),
        ...mtLanguages.map(
          (lang) =>
              DropdownMenuItem(value: lang['code'], child: Text(lang['name']!)),
        ),
      ],
    );
  }

  Widget _buildTvLanguageFilter() {
    return FormBuilderDropdown<String?>(
      name: 'tvLanguage',
      initialValue: _tvParams.withOriginalLanguage,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        hintText: '选择原始语言',
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('全部语言')),
        ...mtLanguages.map(
          (lang) =>
              DropdownMenuItem(value: lang['code'], child: Text(lang['name']!)),
        ),
      ],
    );
  }
}

// 供电影和剧集筛选的语言列表
final mtLanguages = [
  {'code': 'zh', 'name': '中文'},
  {'code': 'en', 'name': '英语'},
  {'code': 'ja', 'name': '日语'},
  {'code': 'ko', 'name': '韩语'},
  {'code': 'fr', 'name': '法语'},
  {'code': 'de', 'name': '德语'},
  {'code': 'es', 'name': '西班牙语'},
  {'code': 'it', 'name': '意大利语'},
  {'code': 'ru', 'name': '俄语'},
  {'code': 'pt', 'name': '葡萄牙语'},
];
