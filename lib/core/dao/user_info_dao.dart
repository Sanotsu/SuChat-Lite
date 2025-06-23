import '../entities/user_info.dart';
import '../storage/db_helper.dart';

/// 用户信息数据访问对象
/// 提供对用户信息的增删改查操作
class UserInfoDao {
  final DBHelper _dbHelper = DBHelper();

  // 单例模式
  static final UserInfoDao _instance = UserInfoDao._internal();

  factory UserInfoDao() => _instance;

  UserInfoDao._internal();

  /// 获取用户信息，如果不存在则创建默认用户
  Future<UserInfo> getUserInfo({String? userId}) async {
    return await _dbHelper.getUserInfo(userId: userId);
  }

  /// 根据用户ID获取用户信息
  Future<UserInfo?> getUserInfoById(String userId) async {
    return await _dbHelper.getById(userId);
  }

  /// 获取所有用户
  Future<List<UserInfo>> getAllUsers() async {
    return await _dbHelper.getAllUsers();
  }

  /// 保存用户信息（新增或更新）
  Future<void> saveUserInfo(UserInfo userInfo) async {
    await _dbHelper.saveUserInfo(userInfo);
  }

  /// 批量保存用户信息
  Future<List<int>> batchSaveUserInfo(List<UserInfo> userInfos) async {
    return await _dbHelper.batchInsert(userInfos);
  }

  /// 删除用户
  Future<void> deleteUserInfo(String userId) async {
    await _dbHelper.deleteUserInfo(userId);
  }

  /// 更新用户信息
  Future<void> updateUserInfo(UserInfo userInfo) async {
    // 确保更新时间戳
    final updatedUser = userInfo.copyWith();
    await _dbHelper.saveUserInfo(updatedUser);
  }

  /// 获取或创建默认用户信息
  Future<UserInfo> getOrCreateDefault() async {
    final users = await getAllUsers();

    if (users.isNotEmpty) {
      return users.first;
    }

    // 创建默认用户配置文件
    final defaultUser = UserInfo.createDefault();
    await saveUserInfo(defaultUser);
    return defaultUser;
  }

  // 根据用户配置文件计算每日推荐摄入量
  Future<Map<String, double>> calculateDailyRecommendedIntake(
    String userId,
  ) async {
    final user = await getUserInfoById(userId);

    if (user == null) {
      throw Exception('用户配置文件不存在');
    }

    double targetCalories;

    // 根据目标调整卡路里
    var goal = user.goal ?? Goal.maintainWeight;
    switch (goal) {
      case Goal.loseWeight:
        targetCalories = user.tdee - 500; // 减脂：每日减少500卡路里
        break;
      case Goal.maintainWeight:
        targetCalories = user.tdee; // 维持体重：保持当前消耗
        break;
      case Goal.gainMuscle:
        targetCalories = user.tdee + 300; // 增肌：每日增加300卡路里
        break;
      case Goal.stayHealthy:
        targetCalories = user.tdee; // 保持健康：保持当前消耗
        break;
    }

    // 确保卡路里不低于基础代谢率的1.2倍
    targetCalories = targetCalories.clamp(user.bmr * 1.2, double.infinity);

    // 计算宏量营养素分配（蛋白质、碳水、脂肪）
    double targetProtein;
    double targetCarbs;
    double targetFat;

    switch (goal) {
      case Goal.loseWeight:
        // 减脂：高蛋白，适中脂肪，低碳水
        targetProtein = user.weight * 2.0; // 每公斤体重2克蛋白质
        targetFat = user.weight * 1.0; // 每公斤体重1克脂肪
        // 剩余卡路里来自碳水
        targetCarbs = (targetCalories - targetProtein * 4 - targetFat * 9) / 4;
        break;
      case Goal.maintainWeight:
        // 维持体重：平衡的宏量营养素
        targetProtein = user.weight * 1.6; // 每公斤体重1.6克蛋白质
        targetFat = user.weight * 1.0; // 每公斤体重1克脂肪
        targetCarbs = (targetCalories - targetProtein * 4 - targetFat * 9) / 4;
        break;
      case Goal.gainMuscle:
        // 增肌：高蛋白，高碳水，适中脂肪
        targetProtein = user.weight * 2.2; // 每公斤体重2.2克蛋白质
        targetFat = user.weight * 0.8; // 每公斤体重0.8克脂肪
        targetCarbs = (targetCalories - targetProtein * 4 - targetFat * 9) / 4;
        break;
      case Goal.stayHealthy:
        // 保持健康：平衡的宏量营养素
        targetProtein = user.weight * 1.5; // 每公斤体重1.5克蛋白质
        targetFat = user.weight * 1.0; // 每公斤体重1克脂肪
        targetCarbs = (targetCalories - targetProtein * 4 - targetFat * 9) / 4;
        break;
    }

    // 确保宏量营养素不为负
    targetCarbs = targetCarbs.clamp(0, double.infinity);

    return {
      'calories': targetCalories,
      'protein': targetProtein,
      'carbs': targetCarbs,
      'fat': targetFat,
    };
  }

  // 更新用户目标
  Future<UserInfo> updateUserGoal(String userId, Goal goal) async {
    final user = await getUserInfoById(userId);

    if (user == null) {
      throw Exception('用户配置文件不存在');
    }

    final updatedUser = user.copyWith(goal: goal, gmtModified: DateTime.now());

    await updateUserInfo(updatedUser);
    return updatedUser;
  }
}
