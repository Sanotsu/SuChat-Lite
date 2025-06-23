import 'package:flutter/foundation.dart';

import '../dao/user_info_dao.dart';
import '../entities/user_info.dart';
import '../utils/simple_tools.dart';

/// 用户信息视图模型
/// 管理用户信息的状态和业务逻辑
class UserInfoViewModel extends ChangeNotifier {
  final UserInfoDao _userInfoDao = UserInfoDao();

  // 当前用户信息
  UserInfo? _currentUser;
  // 是否正在加载
  bool _isLoading = false;
  // 错误信息
  String? _error;

  // 每日推荐摄入量
  Map<String, double>? _dailyRecommendedIntake;

  // Getters
  UserInfo? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, double>? get dailyRecommendedIntake => _dailyRecommendedIntake;

  // 初始化，加载用户信息
  Future<void> initialize() async {
    _setLoading(true);
    try {
      _currentUser = await _userInfoDao.getUserInfo();
      if (_currentUser != null) {
        await _calculateDailyRecommendedIntake();
      }
      _error = null;
    } catch (e) {
      _error = '加载用户信息失败 VM的initialize中: $e';
      pl.e(_error);
    } finally {
      _setLoading(false);
    }
  }

  // 加载指定用户信息
  Future<void> loadUserInfo(String userId) async {
    _setLoading(true);
    try {
      _currentUser = await _userInfoDao.getUserInfo(userId: userId);
      if (_currentUser != null) {
        await _calculateDailyRecommendedIntake();
      }
      _error = null;
    } catch (e) {
      _error = '加载用户信息失败: $e';
      pl.e(_error);
    } finally {
      _setLoading(false);
    }
  }

  // 保存用户信息
  Future<void> saveUserInfo(UserInfo userInfo) async {
    _setLoading(true);
    try {
      await _userInfoDao.saveUserInfo(userInfo);
      _currentUser = userInfo;
      await _calculateDailyRecommendedIntake();
      _error = null;
    } catch (e) {
      _error = '保存用户信息失败: $e';
      pl.e(_error);
    } finally {
      _setLoading(false);
    }
  }

  // 获取所有用户
  Future<List<UserInfo>> getAllUsers() async {
    try {
      return await _userInfoDao.getAllUsers();
    } catch (e) {
      _error = '获取用户列表失败: $e';
      notifyListeners();
      return [];
    }
  }

  // 计算每日推荐摄入量
  Future<void> _calculateDailyRecommendedIntake() async {
    if (_currentUser == null) return;

    try {
      _dailyRecommendedIntake = await _userInfoDao
          .calculateDailyRecommendedIntake(_currentUser!.userId);
    } catch (e) {
      _error = '计算每日推荐摄入量失败: $e';
      pl.e(_error);
    }
  }

  // 更新用户目标
  Future<void> updateUserGoal(Goal goal) async {
    if (_currentUser == null) {
      _error = '没有当前用户信息';
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      final updatedUser = await _userInfoDao.updateUserGoal(
        _currentUser!.userId,
        goal,
      );
      _currentUser = updatedUser;
      await _calculateDailyRecommendedIntake();
      _error = null;
    } catch (e) {
      _error = '更新用户目标失败: $e';
      pl.e(_error);
    } finally {
      _setLoading(false);
    }
  }

  // 更新用户信息
  Future<void> updateUserInfo({
    String? name,
    Gender? gender,
    int? age,
    double? height,
    double? weight,
    String? fitnessLevel,
    String? healthConditions,
    Goal? goal,
    double? activityLevel,
    double? targetCalories,
    double? targetCarbs,
    double? targetProtein,
    double? targetFat,
  }) async {
    if (_currentUser == null) {
      _error = '没有当前用户信息';
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      final updatedUser = _currentUser!.copyWith(
        name: name,
        gender: gender,
        age: age,
        height: height,
        weight: weight,
        fitnessLevel: fitnessLevel,
        healthConditions: healthConditions,
        goal: goal,
        activityLevel: activityLevel,
        targetCalories: targetCalories,
        targetCarbs: targetCarbs,
        targetProtein: targetProtein,
        targetFat: targetFat,
      );

      await _userInfoDao.saveUserInfo(updatedUser);
      _currentUser = updatedUser;
      await _calculateDailyRecommendedIntake();
      _error = null;
    } catch (e) {
      _error = '更新用户信息失败: $e';
      pl.e(_error);
    } finally {
      _setLoading(false);
    }
  }

  // 删除用户
  Future<void> deleteUserInfo(String userId) async {
    _setLoading(true);
    try {
      await _userInfoDao.deleteUserInfo(userId);
      if (_currentUser?.userId == userId) {
        _currentUser = null;
        _dailyRecommendedIntake = null;
      }
      _error = null;
    } catch (e) {
      _error = '删除用户信息失败: $e';
      pl.e(_error);
    } finally {
      _setLoading(false);
    }
  }

  // 设置加载状态并通知监听器
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 清除错误信息
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
