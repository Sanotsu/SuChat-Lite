import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/entities/user_info.dart';
import '../../../core/viewmodels/user_info_viewmodel.dart';
import '../../../shared/constants/constants.dart';
import '../../../shared/widgets/goal_setting_dialog.dart';
import '../../../shared/widgets/simple_tool_widget.dart';
import '../../../shared/widgets/toast_utils.dart';
import '../../settings/pages/user_info_page.dart';
import '../domain/entities/meal_food_detail.dart';
import '../domain/entities/meal_type.dart';
import '../domain/entities/meal_record.dart';
import 'viewmodels/diet_diary_viewmodel.dart';
import 'widgets/nutrition_gauge.dart';
import 'widgets/meal_summary_card.dart';
import 'widgets/food_quantity_editor.dart';
import 'pages/meal_detail_page.dart';
import 'pages/food_search_page.dart';
import 'pages/statistics_page.dart';
import 'pages/diet_analysis_page.dart';
import 'pages/diet_recipe_page.dart';

class DietDiaryPage extends StatefulWidget {
  const DietDiaryPage({super.key});

  @override
  State<DietDiaryPage> createState() => _DietDiaryPageState();
}

class _DietDiaryPageState extends State<DietDiaryPage> {
  late DietDiaryViewModel _dietViewModel;
  late UserInfoViewModel _userViewModel;
  DateTime _selectedDate = DateTime.now();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _dietViewModel = Provider.of<DietDiaryViewModel>(context, listen: false);
    _userViewModel = Provider.of<UserInfoViewModel>(context, listen: false);
    // 使用postFrameCallback确保在构建完成后再初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    if (!_isInitialized) {
      await _userViewModel.initialize();
      if (_userViewModel.currentUser != null) {
        await _dietViewModel.initialize(userInfo: _userViewModel.currentUser!);
        _isInitialized = true;
      } else {
        // 如果没有用户信息，提示用户创建
        if (mounted) {
          ToastUtils.showInfo('请先创建用户信息');
          _navigateToUserInfo(context);
        }
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: kFirstDay,
      lastDate: kLastDay,
      locale: const Locale('zh', 'CN'),
    );
    if (picked != null &&
        picked != _selectedDate &&
        _userViewModel.currentUser != null) {
      setState(() {
        _selectedDate = picked;
      });
      await _dietViewModel.loadDailyData(
        picked,
        userInfo: _userViewModel.currentUser!,
        dailyRecommendedIntake: _userViewModel.dailyRecommendedIntake,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('饮食日记'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: '个人信息',
            onPressed: () => _navigateToUserInfo(context),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: '图表统计',
            onPressed: () => _navigateToStatistics(context),
          ),
          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            tooltip: '食品管理',
            onPressed: () => _navigateToFoodManagement(context),
          ),
        ],
      ),
      body: Consumer2<DietDiaryViewModel, UserInfoViewModel>(
        builder: (context, dietViewModel, userViewModel, child) {
          if (dietViewModel.isLoading || userViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (dietViewModel.error != null &&
              dietViewModel.errorContext == 'diet_diary_home') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              commonExceptionDialog(
                context,
                "餐次数据错误",
                dietViewModel.error.toString(),
              );
              dietViewModel.clearError();
            });
          }

          if (userViewModel.error != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              commonExceptionDialog(
                context,
                "用户信息错误",
                userViewModel.error.toString(),
              );
              userViewModel.clearError();
            });
          }

          if (userViewModel.currentUser == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_off_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '需要完善用户信息才能使用饮食日记',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '请先创建或完善您的个人信息，以便记录和分析您的饮食情况',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToUserInfo(context),
                    icon: const Icon(Icons.person_add),
                    label: const Text('完善个人信息'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return _buildBody(dietViewModel, userViewModel);
        },
      ),
    );
  }

  Widget _buildBody(
    DietDiaryViewModel dietViewModel,
    UserInfoViewModel userViewModel,
  ) {
    final dailyNutrition = dietViewModel.dailyNutrition;
    final dailyRecommended = userViewModel.dailyRecommendedIntake;
    final userInfo = userViewModel.currentUser;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          /// 日期选择器
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () async {
                    final previousDay = _selectedDate.subtract(
                      const Duration(days: 1),
                    );
                    setState(() {
                      _selectedDate = previousDay;
                    });
                    if (userViewModel.currentUser != null) {
                      await dietViewModel.loadDailyData(
                        previousDay,
                        userInfo: userViewModel.currentUser!,
                        dailyRecommendedIntake:
                            userViewModel.dailyRecommendedIntake,
                      );
                    }
                  },
                ),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: Text(
                    dietViewModel.getFormattedDate(_selectedDate),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () async {
                    final nextDay = _selectedDate.add(const Duration(days: 1));
                    // 不允许选择未来的日期
                    if (nextDay.isAfter(DateTime.now())) {
                      return;
                    }
                    setState(() {
                      _selectedDate = nextDay;
                    });
                    if (userViewModel.currentUser != null) {
                      await dietViewModel.loadDailyData(
                        nextDay,
                        userInfo: userViewModel.currentUser!,
                        dailyRecommendedIntake:
                            userViewModel.dailyRecommendedIntake,
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          /// 今日饮食分析标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text(
                  '今日饮食分析',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),

                // 定制食谱按钮
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DietRecipePage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.restaurant_menu, size: 16),
                  label: const Text('食谱'),
                ),

                const SizedBox(width: 8),

                // 跳转到饮食分析页面
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DietAnalysisPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.analytics, size: 16),
                  label: const Text('分析'),
                ),
              ],
            ),
          ),

          /// 营养摄入仪表盘
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    /// 当前用户目标
                    if (userInfo != null) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '目标 ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          Text(
                            getGoalText(userInfo.goal ?? Goal.maintainWeight),
                          ),
                          Tooltip(
                            message: '减脂推荐大约 500 千卡缺口\n增肌推荐额外 300 千卡摄入',
                            showDuration: const Duration(seconds: 5),
                            child: Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                          ),

                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              // 显示目标设置对话框

                              showDialog(
                                context: context,
                                builder:
                                    (context) => GoalSettingDialog(
                                      userInfo: userInfo,
                                      isDialog: true, // 以内嵌形式显示
                                      onSave: (goal, activityLevel) async {
                                        // 更新用户目标和活动水平
                                        final updatedProfile = userInfo
                                            .copyWith(
                                              goal: goal,
                                              activityLevel: activityLevel,
                                            );
                                        await userViewModel.saveUserInfo(
                                          updatedProfile,
                                        );

                                        ToastUtils.showInfo('目标设置已更新');
                                      },
                                    ),
                              );
                            },
                            child: const Text('目标设置'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),

                    /// 热量缺口仪表盘
                    NutritionGauge(
                      current: dailyNutrition?['calories'] ?? 0,
                      target: dailyRecommended?['calories'] ?? 2000,
                      label: '热量缺口',
                    ),
                    const SizedBox(height: 24),

                    /// 营养摄入信息
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNutritionInfo(
                          '总摄入',
                          '${dailyNutrition?['calories']?.toInt() ?? 0}',
                          '千卡',
                          Icons.local_fire_department,
                          Colors.orange,
                        ),
                        Row(
                          children: [
                            _buildNutritionInfo(
                              '推荐值',
                              '${dailyRecommended?['calories']?.toInt() ?? 0}',
                              '千卡',
                              Icons.fastfood,
                              Colors.green,
                            ),
                            // 添加BMR提示图标
                            // 显示基础代谢率+活动水平
                            if (userInfo != null)
                              Tooltip(
                                message:
                                    '基础代谢率${userInfo.bmr.toInt()} * 活动水平${userInfo.activityLevel} + ${getGoalText(userInfo.goal ?? Goal.maintainWeight)}',
                                showDuration: const Duration(seconds: 5),
                                child: Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),

                    /// 营养摄入进度
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNutrientProgress(
                          '碳水化合物',
                          dailyNutrition?['carbs'] ?? 0,
                          dailyRecommended?['carbs'] ?? 250,
                          '克',
                          '75%',
                          Colors.amber,
                        ),
                        _buildNutrientProgress(
                          '蛋白质',
                          dailyNutrition?['protein'] ?? 0,
                          dailyRecommended?['protein'] ?? 100,
                          '克',
                          '14%',
                          Colors.blue,
                        ),
                        _buildNutrientProgress(
                          '脂肪',
                          dailyNutrition?['fat'] ?? 0,
                          dailyRecommended?['fat'] ?? 67,
                          '克',
                          '11%',
                          Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          /// 饮食日记标题和餐次图标区域
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '饮食日记',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // TODO: 实现拍照识别功能（暂时不弄）
                        // 不好弄，没有后台服务，拍照识别的菜品无法和数据库中的菜品关联
                        // 想法是 1 识别菜品(如果不对就手动输入) 2 录入菜品食用数量 3 根据拍照时间存入对应餐次
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('拍照识别'),
                    ),
                  ],
                ),

                // 餐次图标区域
                const SizedBox(height: 16),
                _buildMealIconsSection(dietViewModel),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 餐次详情
          if (dietViewModel.mealRecords.isNotEmpty) ...[
            _buildMealSections(dietViewModel),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.restaurant, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      '正在加载餐次数据...',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // 餐次图标区域
  Widget _buildMealIconsSection(DietDiaryViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMealIconButton(
            viewModel,
            MealType.breakfast,
            Icons.breakfast_dining,
            '早餐',
            Colors.orange,
          ),
          _buildMealIconButton(
            viewModel,
            MealType.lunch,
            Icons.lunch_dining,
            '午餐',
            Colors.green,
          ),
          _buildMealIconButton(
            viewModel,
            MealType.dinner,
            Icons.dinner_dining,
            '晚餐',
            Colors.purple,
          ),
          _buildMealIconButton(
            viewModel,
            MealType.snack,
            Icons.icecream,
            '加餐',
            Colors.pink,
          ),
        ],
      ),
    );
  }

  Widget _buildMealIconButton(
    DietDiaryViewModel viewModel,
    MealType mealType,
    IconData icon,
    String label,
    Color color,
  ) {
    // 找到对应的餐次记录
    final mealRecord = viewModel.mealRecords.firstWhere(
      (meal) => meal.mealType.index == mealType.index,
      orElse:
          () => MealRecord(id: -1, date: DateTime.now(), mealType: mealType),
    );

    final mealId = mealRecord.id;
    final hasFoods =
        mealId != null &&
        mealId > 0 &&
        viewModel.mealFoodDetails.containsKey(mealId) &&
        (viewModel.mealFoodDetails[mealId]?.isNotEmpty ?? false);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // 图标背景
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: color),
            ),

            // 已记录标记
            if (hasFoods)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.check, size: 12, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () {
            if (mealId != null && mealId > 0) {
              _navigateToFoodSearch(context, mealId, mealType);
            }
          },
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: hasFoods ? Colors.green : Colors.blue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, size: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // 构建所有餐次详情
  Widget _buildMealSections(DietDiaryViewModel viewModel) {
    return Column(
      children: [
        _buildMealSection(viewModel, MealType.breakfast),
        _buildMealSection(viewModel, MealType.lunch),
        _buildMealSection(viewModel, MealType.dinner),
        _buildMealSection(viewModel, MealType.snack),
      ],
    );
  }

  Widget _buildMealSection(DietDiaryViewModel viewModel, MealType mealType) {
    // 使用枚举的index进行比较，而不是直接比较枚举实例
    final mealRecord = viewModel.mealRecords.firstWhere(
      (meal) => meal.mealType.index == mealType.index,
      orElse: () {
        // 如果没有找到对应的餐次记录，返回一个空的Widget而不是抛出异常
        return MealRecord(
          id: -1, // 使用一个无效的ID
          date: DateTime.now(),
          mealType: mealType,
        );
      },
    );

    final mealId = mealRecord.id;
    if (mealId == null || mealId < 0) {
      return const SizedBox.shrink();
    }

    final mealFoods = viewModel.mealFoodDetails[mealId] ?? [];
    final mealNutrition =
        viewModel.mealNutrition[mealId] ??
        {'calories': 0.0, 'carbs': 0.0, 'protein': 0.0, 'fat': 0.0};

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: MealSummaryCard(
        mealType: mealType,
        calories: mealNutrition['calories'] ?? 0,
        carbs: mealNutrition['carbs'] ?? 0,
        protein: mealNutrition['protein'] ?? 0,
        fat: mealNutrition['fat'] ?? 0,
        foodCount: mealFoods.length,
        foodDetails: mealFoods,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MealDetailPage(mealRecord: mealRecord),
            ),
          );
        },
        onFoodTap: (food) => _showFoodQuantityEditor(food, mealId),
        onFoodDismiss: (food) {
          viewModel.removeFoodFromMeal(food.id, mealId);
          ToastUtils.showInfo('已删除"${food.foodName}"');
        },
        // 我们上面有单独选择餐次并进行食品添加的功能，这里不需要了
        // onAddFood: () => _navigateToFoodSearch(context, mealId, mealType),
      ),
    );
  }

  Widget _buildNutritionInfo(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutrientProgress(
    String label,
    double current,
    double target,
    String unit,
    String percentage,
    Color color,
  ) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
        const SizedBox(height: 4),
        SizedBox(
          width: 80,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${current.toInt()} / ${target.toInt()} $unit',
          style: TextStyle(color: Colors.grey[700], fontSize: 12),
        ),
      ],
    );
  }

  void _showFoodQuantityEditor(MealFoodDetail food, int mealId) {
    showDialog(
      context: context,
      builder:
          (context) => FoodQuantityEditor(
            foodDetail: food,
            onQuantityChanged: (newQuantity) async {
              // 删除原记录
              await _dietViewModel.removeFoodFromMeal(food.id, mealId);
              // 添加新记录
              await _dietViewModel.addFoodToMeal(
                mealId,
                food.foodItemId,
                newQuantity,
                food.unit,
              );

              ToastUtils.showInfo('已更新"${food.foodName}"的数量');
            },
          ),
    );
  }

  void _navigateToFoodSearch(
    BuildContext context,
    int mealId,
    MealType mealType,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                FoodSearchPage(mealRecordId: mealId, mealType: mealType),
      ),
    );
  }

  void _navigateToFoodManagement(BuildContext context) {
    Navigator.pushNamed(context, '/food-management');
  }

  Future<void> _navigateToUserInfo(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChangeNotifierProvider.value(
              value: _userViewModel,
              child: const UserInfoPage(),
            ),
      ),
    );

    // 如果返回结果不为null，表示用户信息已更新
    if (result != null && _userViewModel.currentUser != null) {
      // 重新加载当天的数据
      await _dietViewModel.loadDailyData(
        _selectedDate,
        userInfo: _userViewModel.currentUser!,
        dailyRecommendedIntake: _userViewModel.dailyRecommendedIntake,
      );
    }
  }

  void _navigateToStatistics(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StatisticsPage()),
    );
  }
}
