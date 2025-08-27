import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../shared/widgets/simple_tool_widget.dart';
import '../../../data/models/daodu_models.dart';
import '../../../data/datasources/reading_api_manager.dart';
import 'lesson_detail_page.dart';

/// 今日文章卡片页面 - 支持左右滑动切换日期
class DailyCardPage extends StatefulWidget {
  const DailyCardPage({super.key});

  @override
  State<DailyCardPage> createState() => _DailyCardPageState();
}

class _DailyCardPageState extends State<DailyCardPage> {
  final ReadingApiManager _apiManager = ReadingApiManager();
  final PageController _pageController = PageController(initialPage: 1000);

  // 数据状态
  final Map<String, DaoduLesson?> _lessonsCache = {}; // 缓存不同日期的文章
  final Map<String, DaoduActivityStats?> _statsCache = {}; // 缓存文章统计
  bool _isLoading = false;
  String? _error;

  // 当前显示的日期索引（以今天为基准）
  int _currentDateOffset = 0; // 0=今天, -1=昨天, 1=明天

  @override
  void initState() {
    super.initState();
    _loadTodayLesson();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 获取指定偏移日期
  DateTime _getDateByOffset(int offset) {
    return DateTime.now().add(Duration(days: offset));
  }

  /// 获取日期的缓存key
  String _getDateKey(int offset) {
    final date = _getDateByOffset(offset);
    return DateFormat("yyyyMMdd").format(date);
  }

  /// 加载今日文章
  Future<void> _loadTodayLesson() async {
    await _loadLessonByOffset(0);
  }

  /// 根据日期偏移加载文章
  Future<void> _loadLessonByOffset(int offset) async {
    final dateKey = _getDateKey(offset);

    // 如果已有缓存，直接返回
    if (_lessonsCache.containsKey(dateKey)) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final lessons = await _apiManager.getDaoduLessonList(
        from: int.parse(dateKey),
        to: int.parse(dateKey),
        forceRefresh: false,
      );

      DaoduLesson? lesson;
      DaoduActivityStats? stats;

      if (lessons.isNotEmpty) {
        lesson = lessons.first;
        // 加载统计信息
        try {
          stats = await _apiManager.getDaoduLessonActivityStats(
            id: lesson.id!,
            forceRefresh: false,
          );
        } catch (e) {
          if (!mounted) return;
          commonExceptionDialog(context, '加载统计信息失败', e.toString());
        }
      }

      if (mounted) {
        setState(() {
          _lessonsCache[dateKey] = lesson;
          _statsCache[dateKey] = stats;
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

  /// 切换到指定日期偏移
  void _switchToOffset(int offset) {
    // 注意，虽然不能获取今日之后的文章，但日期显示可以滚动到未来
    setState(() {
      _currentDateOffset = offset;
    });

    // 限制不能获取今日之后的文章
    if (offset > 0) {
      return;
    }

    //  今日及其之前的文章可以加载
    _loadLessonByOffset(offset);
  }

  /// 构建倒计时卡片
  Widget _buildCountdownCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 等待图标
            Icon(Icons.schedule, size: 48, color: Colors.orange[300]),

            const SizedBox(height: 24),

            // 提示文字
            Text(
              '等待更新',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              '距明日更新还有',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),

            const SizedBox(height: 8),

            // 倒计时显示
            StreamBuilder<String>(
              stream: _countdownStream(),
              builder: (context, snapshot) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Text(
                    snapshot.data ?? '计算中...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange[700],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 倒计时流
  Stream<String> _countdownStream() async* {
    while (true) {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final duration = tomorrow.difference(now);

      if (duration.isNegative) {
        yield '已更新';
        break;
      }

      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      final seconds = duration.inSeconds % 60;

      yield '${hours.toString().padLeft(2, '0')} 时 ${minutes.toString().padLeft(2, '0')} 分 ${seconds.toString().padLeft(2, '0')} 秒';

      await Future.delayed(const Duration(seconds: 1));
    }
  }

  /// 进入阅读详情页面
  void _enterReadingDetail(DaoduLesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LessonDetailPage(lesson: lesson)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('岛读')),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部日期显示
            _buildDateHeader(),

            // 文章卡片区域
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: _CustomPageViewPhysics(),
                onPageChanged: (index) {
                  final offset = index - 1000;
                  _switchToOffset(offset);
                },
                itemBuilder: (context, index) {
                  final offset = index - 1000;
                  return _buildArticleCard(offset);
                },
              ),
            ),

            // 底部操作区域
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader() {
    final currentDate = _getDateByOffset(_currentDateOffset);
    final day = currentDate.day;
    final weekday = _getWeekdayName(currentDate.weekday);
    final monthDay = DateFormat('M月d日').format(currentDate);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            '$day',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w300,
              color: Colors.grey[600],
            ),
          ),
          Text(
            '$weekday\n$monthDay',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(int offset) {
    // 如果是未来日期，显示倒计时卡片
    if (offset > 0) {
      return _buildCountdownCard();
    }

    final dateKey = _getDateKey(offset);
    final lesson = _lessonsCache[dateKey];
    final stats = _statsCache[dateKey];

    if (_isLoading && offset == _currentDateOffset) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && offset == _currentDateOffset) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadLessonByOffset(offset),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (lesson == null) {
      // 预加载相邻日期的文章
      if (offset == _currentDateOffset - 1 ||
          offset == _currentDateOffset + 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadLessonByOffset(offset);
          }
        });
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '该日期暂无文章',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => _enterReadingDetail(lesson),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                if (lesson.title?.isNotEmpty == true)
                  Text(
                    lesson.title!,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 16),

                // 内容预览
                if (lesson.article?.isNotEmpty == true)
                  Expanded(
                    child: Text(
                      lesson.article!,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                      maxLines: 8,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                const SizedBox(height: 20),

                // 底部信息
                Row(
                  children: [
                    // 出处信息
                    if (lesson.provenance?.isNotEmpty == true)
                      Expanded(
                        child: Text(
                          '出自：《${lesson.provenance!}》',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),

                    // 统计信息
                    if (stats != null) ...[
                      Icon(Icons.favorite, size: 16, color: Colors.red[300]),
                      const SizedBox(width: 4),
                      Text(
                        '${stats.favouriteCount ?? 0}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.comment, size: 16, color: Colors.blue[300]),
                      const SizedBox(width: 4),
                      Text(
                        '${stats.commentCount ?? 0}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // 阅读按钮
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '阅读',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 上一天
          _buildActionButton(
            icon: Icons.chevron_left,
            onTap: () {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),

          // 今天
          _buildActionButton(
            icon: Icons.today,
            onTap: () {
              _pageController.animateToPage(
                1000,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),

          // 下一天（如果当前是今天，则禁用）
          _buildActionButton(
            icon: Icons.chevron_right,
            onTap: _currentDateOffset >= 0
                ? null
                : () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
            isDisabled: _currentDateOffset >= 0,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    VoidCallback? onTap,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey[200] : Colors.white,
          shape: BoxShape.circle,
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Icon(
          icon,
          color: isDisabled ? Colors.grey[400] : Colors.grey[600],
          size: 24,
        ),
      ),
    );
  }

  String _getWeekdayName(int weekday) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[weekday - 1];
  }
}

/// 自定义PageView物理属性，限制滚动范围
class _CustomPageViewPhysics extends ScrollPhysics {
  const _CustomPageViewPhysics({super.parent});

  @override
  _CustomPageViewPhysics applyTo(ScrollPhysics? ancestor) {
    return _CustomPageViewPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // 计算目标页面索引
    final targetPage = value / position.viewportDimension;

    // 限制最大页面为1001（即今天+1，offset=1）
    const maxPage = 1001.0;

    if (targetPage > maxPage) {
      // 如果试图滚动到超过最大页面，返回阻力
      return value - (maxPage * position.viewportDimension);
    }

    return super.applyBoundaryConditions(position, value);
  }
}
