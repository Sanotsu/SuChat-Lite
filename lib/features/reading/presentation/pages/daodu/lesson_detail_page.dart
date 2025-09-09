import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../shared/widgets/toast_utils.dart';
import '../../../data/models/daodu_models.dart';
import '../../../data/datasources/reading_api_manager.dart';
import '../../../data/services/reading_settings_service.dart';
import 'lesson_comments_page.dart';

/// 文章内容详情页面
class DaoduLessonDetailPage extends StatefulWidget {
  final DaoduLesson? lesson;

  const DaoduLessonDetailPage({super.key, this.lesson});

  @override
  State<DaoduLessonDetailPage> createState() => _DaoduLessonDetailPageState();
}

class _DaoduLessonDetailPageState extends State<DaoduLessonDetailPage> {
  final ReadingApiManager _apiManager = ReadingApiManager();
  final ReadingSettingsService _settingsService = ReadingSettingsService();
  DaoduLesson? _currentLesson;
  DaoduActivityStats? _activityStats;
  bool _isLoading = false;
  String? _error;

  // 阅读设置
  double _fontSize = 16.0;
  bool _isDarkMode = false;

  // 非深色模式时的背景色(米色)
  final _lightBgColor = Color(0xFFF5F5DC);

  @override
  void initState() {
    super.initState();
    _loadSettings();

    // 如果 lesson 不为空，直接使用 lesson，否则加载今日文章
    // 从列表页面或者其他指定页面跳转到详情页面时，会传递 lesson 参数
    if (widget.lesson != null) {
      _currentLesson = widget.lesson;
      _loadLessonActivityStats(widget.lesson!);
      _isLoading = false;
    } else {
      _loadTodayLesson();
    }
  }

  /// 加载设置
  void _loadSettings() {
    setState(() {
      _fontSize = _settingsService.getFontSize();
      _isDarkMode = _settingsService.getIsDarkMode();
    });
    _updateSystemUI();
  }

  /// 更新系统UI
  void _updateSystemUI() {
    if (_isDarkMode) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF121212),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );
    } else {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
    }
  }

  /// 加载今日文章
  Future<void> _loadTodayLesson() async {
    if (_isLoading == true) return;

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final todayStr = DateFormat("yyyyMMdd").format(DateTime.now());

      // 获取今日文章列表(起止同一天)
      final lessons = await _apiManager.getDaoduLessonList(
        from: int.parse(todayStr),
        to: int.parse(todayStr),
      );

      if (lessons.isNotEmpty && mounted) {
        final lesson = lessons.first;
        setState(() {
          _currentLesson = lesson;
        });
        // 获取文章统计信息
        await _loadLessonActivityStats(lesson);
      } else {
        setState(() {
          _error = '今日暂无文章';
        });
      }
    } catch (e) {
      setState(() {
        _error = '加载失败: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 获取文章统计信息
  Future<void> _loadLessonActivityStats(DaoduLesson lesson) async {
    final stats = await _apiManager.getDaoduLessonActivityStats(id: lesson.id!);

    if (!mounted) return;
    setState(() {
      _activityStats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: _isDarkMode ? Colors.black : Colors.white,
      backgroundColor: _isDarkMode ? Colors.black : _lightBgColor,
      appBar: AppBar(
        title: Text(_currentLesson?.title ?? '岛读文章详情'),
        backgroundColor: _isDarkMode ? Colors.grey[900] : _lightBgColor,
        foregroundColor: _isDarkMode ? Colors.white : null,
        actions: [
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
              _settingsService.setIsDarkMode(_isDarkMode);
            },
          ),
          IconButton(
            icon: Icon(Icons.text_fields),
            onPressed: _showFontSizeDialog,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTodayLesson,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_currentLesson == null) {
      return const Center(child: Text('暂无内容'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          if (_currentLesson!.title?.isNotEmpty == true)
            Text(
              _currentLesson!.title!,
              style: TextStyle(
                fontSize: _fontSize + 4,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.black87,
                height: 1.4,
              ),
            ),

          const SizedBox(height: 16),

          // 作者信息
          if (_currentLesson!.author != null) _buildAuthorInfo(),

          const SizedBox(height: 24),

          // 文章内容
          if (_currentLesson!.article?.isNotEmpty == true)
            SelectableText(
              _currentLesson!.article!,
              style: TextStyle(
                fontSize: _fontSize,
                height: 1.8,
                color: _isDarkMode ? Colors.grey[300] : Colors.black87,
              ),
            ),

          const SizedBox(height: 32),

          // 底部操作区域
          _buildBottomActions(),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAuthorInfo() {
    final author = _currentLesson!.author!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[800] : _lightBgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 20, child: Icon(Icons.person)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  author.name ?? '未知作者',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  '出自：《${_currentLesson?.provenance}》',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.favorite_border,
          label: '${_activityStats?.favouriteCount ?? 0}',
          // 没有登陆接口，这里就不做点赞功能
        ),
        _buildActionButton(
          icon: Icons.comment_outlined,
          label: '${_activityStats?.commentCount ?? 0}',
          onTap: () {
            if (_currentLesson!.id != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DaoduLessonCommentsPage(lessonId: _currentLesson!.id!),
                ),
              );
            }
          },
        ),
        _buildActionButton(
          icon: Icons.share_outlined,
          label: '分享',
          onTap: () async {
            // 简单把文章内容分享出去
            try {
              final result = await SharePlus.instance.share(
                ShareParams(text: _currentLesson?.article ?? ''),
              );

              if (result.status == ShareResultStatus.success) {
                ToastUtils.showSuccess('分享成功!');
              }
            } catch (e) {
              ToastUtils.showError('分享失败: $e', duration: Duration(seconds: 5));
            }
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Icon(
              icon,
              color: onTap == null
                  ? Colors.grey
                  : (_isDarkMode ? Colors.blue[400] : Colors.blue[600]),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: onTap == null
                    ? Colors.grey
                    : (_isDarkMode ? Colors.blue[400] : Colors.blue[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('阅读设置'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 字体大小设置
              Row(
                children: [
                  const Text('字体大小: '),
                  Expanded(
                    child: Slider(
                      value: _fontSize,
                      min: 12.0,
                      max: 24.0,
                      divisions: 12,
                      label: _fontSize.round().toString(),
                      onChanged: (value) {
                        setState(() {
                          _fontSize = value;
                        });
                        _settingsService.setFontSize(value);
                        setDialogState(() {});
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '莫听穿林打叶声，何妨吟啸且徐行。竹杖芒鞋轻胜马，谁怕？一蓑烟雨任平生。',
                style: TextStyle(fontSize: _fontSize),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
