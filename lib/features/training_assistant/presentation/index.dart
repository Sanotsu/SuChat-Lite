import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/screen_helper.dart';
import '../../../core/viewmodels/user_info_viewmodel.dart';
import '../../../shared/widgets/simple_tool_widget.dart';
import '../../settings/pages/user_info_page.dart';
import 'viewmodels/training_viewmodel.dart';
import 'pages/plan_list_page.dart';
import 'pages/plan_detail_page.dart';
import 'pages/plan_generator_page.dart';
import 'pages/training_statistics_page.dart';

/// 训练助手主页面
/// 仍然使用顶部导航切换不同功能，但内部实现采用独立页面来管理状态
class TrainingAssistantPage extends StatefulWidget {
  const TrainingAssistantPage({super.key});

  @override
  State<TrainingAssistantPage> createState() => _TrainingAssistantPageState();
}

class _TrainingAssistantPageState extends State<TrainingAssistantPage> {
  // 当前选中的导航索引
  int _currentIndex = 0;

  // 视图模型
  late UserInfoViewModel _userInfoViewModel;
  late TrainingViewModel _trainingViewModel;

  // 用户信息是否已完成
  bool _isUserInfoCompleted = false;
  bool _isCheckingUserInfo = true;

  @override
  void initState() {
    super.initState();
    _userInfoViewModel = Provider.of<UserInfoViewModel>(context, listen: false);
    _trainingViewModel = Provider.of<TrainingViewModel>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserInfo();
    });
  }

  // 检查用户信息
  Future<void> _checkUserInfo() async {
    setState(() {
      _isCheckingUserInfo = true;
    });

    try {
      await _userInfoViewModel.initialize();

      if (_userInfoViewModel.currentUser != null) {
        setState(() {
          _isUserInfoCompleted = true;
          _currentIndex = 0; // 默认显示训练计划列表页面
        });
      }
    } catch (e) {
      if (mounted) {
        commonExceptionDialog(context, "用户信息异常", e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingUserInfo = false;
        });
      }
    }
  }

  // 导航到用户信息页面
  Future<void> _navigateToUserInfo() async {
    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChangeNotifierProvider.value(
              value: _userInfoViewModel,
              child: const UserInfoPage(),
            ),
      ),
    );

    // 如果返回结果不为null，表示用户信息已更新
    if (result != null && _userInfoViewModel.currentUser != null) {
      setState(() {
        _isUserInfoCompleted = true;
        _currentIndex = 0; // 切换到训练计划列表页面
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('训练助手'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: '个人信息',
            onPressed: _navigateToUserInfo,
          ),
        ],
        // 桌面端导航在页面左侧，移动端导航在顶部AppBar底部
        bottom:
            (_isUserInfoCompleted && ScreenHelper.isMobile())
                ? PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: _buildTopNavigation(),
                )
                : null,
      ),
      body:
          _isCheckingUserInfo
              ? const Center(child: CircularProgressIndicator())
              : !_isUserInfoCompleted
              ? _buildNoUserInfoView()
              : ScreenHelper.isDesktop()
              ? _buildDesktopLayout()
              : _buildCurrentPage(),
    );
  }

  // 顶部导航栏
  Widget _buildTopNavigation() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildNavButton(0, '训练计划', Icons.list),
          _buildNavButton(1, '新建计划', Icons.add),
          _buildNavButton(2, '训练统计', Icons.bar_chart),
        ],
      ),
    );
  }

  // 导航按钮
  Widget _buildNavButton(
    int index,
    String title,
    IconData icon, {
    Function()? onTap,
  }) {
    final isSelected = _currentIndex == index;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton.icon(
        onPressed: onTap ?? () => setState(() => _currentIndex = index),
        icon: Icon(icon, size: 18),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor:
              isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surface,
          foregroundColor:
              isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  // 没有用户信息时显示的提示视图
  Widget _buildNoUserInfoView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            '需要完善用户信息才能使用训练助手',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('请先创建或完善您的个人信息，以便生成适合您的训练计划', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToUserInfo,
            icon: const Icon(Icons.person_add),
            label: const Text('完善个人信息'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // 桌面布局
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧导航栏（保留为了桌面端的侧边导航）
        SizedBox(
          width: 250,
          child: Card(
            margin: const EdgeInsets.all(16),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.list),
                  title: const Text('训练计划'),
                  selected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('新建计划'),
                  selected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart),
                  title: const Text('训练统计'),
                  selected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
              ],
            ),
          ),
        ),

        // 右侧内容区
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildCurrentPage(),
          ),
        ),
      ],
    );
  }

  // 根据当前索引构建页面
  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return ChangeNotifierProvider.value(
          value: _trainingViewModel,
          child: PlanListPage(
            userId: _userInfoViewModel.currentUser?.userId ?? '',
            showAppBar: false,
            onPlanSelected: (planId) async {
              await _trainingViewModel.selectTrainingPlan(planId);
              if (!mounted) return;
              // 导航到计划详情页面
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ChangeNotifierProvider.value(
                        value: _trainingViewModel,
                        child: PlanDetailPage(
                          showAppBar: true,
                          onSwitchToStatistics: () {
                            setState(() {
                              _currentIndex = 2; // 切换到统计页面
                            });
                          },
                        ),
                      ),
                ),
              );
            },
          ),
        );
      case 1:
        return ChangeNotifierProvider.value(
          value: _trainingViewModel,
          child: PlanGeneratorPage(
            userInfo: _userInfoViewModel.currentUser,
            showAppBar: false,
            onPlanGenerated: (planId) async {
              await _trainingViewModel.selectTrainingPlan(planId);
              if (!mounted) return;
              // 导航到计划详情页面
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ChangeNotifierProvider.value(
                        value: _trainingViewModel,
                        child: PlanDetailPage(
                          showAppBar: true,
                          onSwitchToStatistics: () {
                            setState(() {
                              _currentIndex = 2; // 切换到统计页面
                            });
                          },
                        ),
                      ),
                ),
              );
            },
          ),
        );
      case 2:
        return ChangeNotifierProvider.value(
          value: _trainingViewModel,
          child: TrainingStatisticsPage(
            userId: _userInfoViewModel.currentUser?.userId ?? '',
            showAppBar: false,
          ),
        );

      default:
        return const Center(child: Text('未知页面'));
    }
  }
}
