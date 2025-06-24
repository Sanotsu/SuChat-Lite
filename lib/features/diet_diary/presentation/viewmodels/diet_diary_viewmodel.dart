import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/dao/user_info_dao.dart';
import '../../../../core/entities/user_info.dart';
import '../../../../core/utils/simple_tools.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/meal_record.dart';
import '../../domain/entities/meal_food_record.dart';
import '../../domain/entities/meal_type.dart';
import '../../domain/entities/weight_record.dart';
import '../../domain/entities/meal_food_detail.dart';
import '../../domain/entities/diet_analysis.dart';
import '../../data/food_item_dao.dart';
import '../../data/meal_record_dao.dart';
import '../../data/meal_food_record_dao.dart';
import '../../data/weight_record_dao.dart';
import '../../data/diet_analysis_dao.dart';
import '../../data/diet_recipe_dao.dart';
import '../../domain/entities/diet_recipe.dart';

class DietDiaryViewModel extends ChangeNotifier {
  final FoodItemDao _foodItemDao = FoodItemDao();
  final MealRecordDao _mealRecordDao = MealRecordDao();
  final MealFoodRecordDao _mealFoodRecordDao = MealFoodRecordDao();
  final WeightRecordDao _weightRecordDao = WeightRecordDao();
  final DietAnalysisDao _dietAnalysisDao = DietAnalysisDao();
  final DietRecipeDao _dietRecipeDao = DietRecipeDao();

  // 当前选中的日期
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  // 当天的营养摄入量
  MacrosIntake? _dailyNutrition;
  MacrosIntake? get dailyNutrition => _dailyNutrition;

  // 当天的餐次记录
  List<MealRecord> _mealRecords = [];
  List<MealRecord> get mealRecords => _mealRecords;

  // 餐次食品记录
  Map<int, List<MealFoodDetail>> _mealFoodDetails = {};
  Map<int, List<MealFoodDetail>> get mealFoodDetails => _mealFoodDetails;

  // 餐次营养总量
  Map<int, Map<String, double>> _mealNutrition = {};
  Map<int, Map<String, double>> get mealNutrition => _mealNutrition;

  // 当前日期的饮食分析
  DietAnalysis? _currentDietAnalysis;
  DietAnalysis? get currentDietAnalysis => _currentDietAnalysis;

  // 当前日期的所有饮食分析
  List<DietAnalysis> _currentDateAnalyses = [];
  List<DietAnalysis> get currentDateAnalyses => _currentDateAnalyses;

  // 所有食品
  List<FoodItem> _foodItems = [];
  List<FoodItem> get foodItems => _foodItems;

  // 搜索结果
  List<FoodItem> _searchResults = [];
  List<FoodItem> get searchResults => _searchResults;

  // 加载状态
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 错误信息
  String? _error;
  String? get error => _error;

  // 错误上下文，用于标识错误发生的页面或操作
  String? _errorContext;
  String? get errorContext => _errorContext;

  // 当前日期的最新食谱
  DietRecipe? _currentDietRecipe;
  DietRecipe? get currentDietRecipe => _currentDietRecipe;

  // 当前日期的所有食谱
  List<DietRecipe> _currentDateRecipes = [];
  List<DietRecipe> get currentDateRecipes => _currentDateRecipes;

  // 初始化
  Future<void> initialize({required UserInfo userInfo}) async {
    try {
      _setLoading(true, skipNotify: true);
      await _loadFoodItems();
      await loadDailyData(_selectedDate, userInfo: userInfo, skipNotify: true);
      // 所有数据加载完成后统一通知
      notifyListeners();
    } catch (e) {
      _setError('初始化失败: $e', skipNotify: true, context: 'diet_diary_home');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // 加载食品列表
  Future<void> _loadFoodItems() async {
    try {
      // 设置一个较大的limit，确保能加载所有食品
      // 太多了也不好，滚动反看不方便，最好让用户先关键字过滤
      _foodItems = await _foodItemDao.getAll(limit: 200);
    } catch (e) {
      _setError('加载食品列表失败: $e', context: 'food_management');
    }
  }

  // 重新加载食品列表
  Future<void> reloadFoodItems() async {
    try {
      _setLoading(true);
      await _loadFoodItems();
      notifyListeners();
    } catch (e) {
      _setError('重新加载食品列表失败: $e', context: 'food_management');
    } finally {
      _setLoading(false);
    }
  }

  // 加载指定日期的数据
  Future<void> loadDailyData(
    DateTime date, {
    required UserInfo userInfo,
    MacrosIntake? dailyRecommendedIntake,
    bool skipNotify = false,
  }) async {
    try {
      _setLoading(true, skipNotify: true);
      _selectedDate = date;

      // 加载当天的餐次记录
      _mealRecords = await _mealRecordDao.getByDate(date);

      // 如果没有餐次记录，创建默认的
      if (_mealRecords.isEmpty) {
        await _createDefaultMealRecords(date);
        // 重新加载餐次记录，确保获取新创建的记录
        _mealRecords = await _mealRecordDao.getByDate(date);

        // 确认是否创建成功
        if (_mealRecords.isEmpty) {
          _setError(
            '创建默认餐次记录失败',
            skipNotify: skipNotify,
            context: 'diet_diary_home',
          );
          return;
        }
      }

      // 加载每个餐次的食品详情
      _mealFoodDetails = {};
      _mealNutrition = {};

      for (final mealRecord in _mealRecords) {
        if (mealRecord.id != null) {
          try {
            final details = await _mealFoodRecordDao.getMealFoodDetails(
              mealRecord.id!,
            );
            _mealFoodDetails[mealRecord.id!] = details;

            final nutrition = await _mealFoodRecordDao.calculateMealNutrition(
              mealRecord.id!,
            );
            _mealNutrition[mealRecord.id!] = nutrition;
          } catch (e) {
            pl.e('加载餐次详情失败: ${mealRecord.id} - $e');
            // 继续处理其他餐次，不中断整体流程
          }
        }
      }

      // 加载当天的营养总量
      _dailyNutrition = await _mealFoodRecordDao.calculateDailyNutrition(date);

      // 加载当天的饮食分析
      _currentDietAnalysis = await _dietAnalysisDao.getLatestByDate(date);
      _currentDateAnalyses = await _dietAnalysisDao.getAllByDate(date);

      // 加载当天的食谱
      _currentDietRecipe = await _dietRecipeDao.getLatestByDate(date);
      _currentDateRecipes = await _dietRecipeDao.getAllByDate(date);

      if (!skipNotify) {
        notifyListeners();
      }
    } catch (e) {
      _setError(
        '加载日期数据失败: $e',
        skipNotify: skipNotify,
        context: 'diet_diary_home',
      );
    } finally {
      _setLoading(false, skipNotify: skipNotify);
    }
  }

  // 创建默认的餐次记录
  Future<void> _createDefaultMealRecords(DateTime date) async {
    try {
      // 确保日期只包含年月日，不包含时分秒
      final dateOnly = DateTime(date.year, date.month, date.day);

      for (final mealType in MealType.values) {
        await _mealRecordDao.getOrCreateByDateAndType(dateOnly, mealType);
      }
    } catch (e) {
      pl.e('创建默认餐次记录失败: $e');
      rethrow; // 重新抛出异常，让调用者处理
    }
  }

  // 搜索食品
  Future<void> searchFood(String query) async {
    try {
      if (query.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = await _foodItemDao.search(query);
      }
      notifyListeners();
    } catch (e) {
      _setError('搜索食品失败: $e', context: 'food_management');
    }
  }

  // 添加食品到餐次
  Future<void> addFoodToMeal(
    int mealRecordId,
    int foodItemId,
    double quantity, [
    String? unit,
  ]) async {
    try {
      // 检查食品是否已存在于餐次中
      final existingRecord = await _mealFoodRecordDao.checkFoodExistsInMeal(
        mealRecordId,
        foodItemId,
      );

      if (existingRecord != null) {
        // 如果已存在，更新数量
        await _mealFoodRecordDao.updateFoodQuantity(
          existingRecord.id!,
          quantity,
          unit,
        );
      } else {
        // 如果不存在，添加新记录
        final mealFoodRecord = MealFoodRecord(
          mealRecordId: mealRecordId,
          foodItemId: foodItemId,
          quantity: quantity,
          unit: unit,
        );

        await _mealFoodRecordDao.insert(mealFoodRecord);
      }

      // 重新加载餐次数据
      if (_mealRecords.any((meal) => meal.id == mealRecordId)) {
        final details = await _mealFoodRecordDao.getMealFoodDetails(
          mealRecordId,
        );
        _mealFoodDetails[mealRecordId] = details;

        final nutrition = await _mealFoodRecordDao.calculateMealNutrition(
          mealRecordId,
        );
        _mealNutrition[mealRecordId] = nutrition;

        // 更新当天的营养总量
        _dailyNutrition = await _mealFoodRecordDao.calculateDailyNutrition(
          _selectedDate,
        );

        notifyListeners();
      }
    } catch (e) {
      _setError('添加食品失败: $e', context: 'meal_detail');
    }
  }

  // 从餐次中删除食品
  Future<void> removeFoodFromMeal(
    int mealFoodRecordId,
    int mealRecordId,
  ) async {
    try {
      await _mealFoodRecordDao.delete(mealFoodRecordId);

      // 重新加载餐次数据
      if (_mealRecords.any((meal) => meal.id == mealRecordId)) {
        final details = await _mealFoodRecordDao.getMealFoodDetails(
          mealRecordId,
        );
        _mealFoodDetails[mealRecordId] = details;

        final nutrition = await _mealFoodRecordDao.calculateMealNutrition(
          mealRecordId,
        );
        _mealNutrition[mealRecordId] = nutrition;

        // 更新当天的营养总量
        _dailyNutrition = await _mealFoodRecordDao.calculateDailyNutrition(
          _selectedDate,
        );

        notifyListeners();
      }
    } catch (e) {
      _setError('删除食品失败: $e', context: 'meal_detail');
    }
  }

  // 添加新食品
  Future<FoodItem?> addFood(FoodItem foodItem) async {
    try {
      // 检查名称是否已存在
      final exists = await _foodItemDao.isNameExists(foodItem.name);
      if (exists) {
        _setError('已存在同名食品', context: 'food_management');
        return null;
      }

      final id = await _foodItemDao.insert(foodItem);
      final newFood = foodItem.copyWith(id: id);

      // 更新食品列表
      _foodItems.add(newFood);
      _foodItems.sort((a, b) => a.name.compareTo(b.name));

      notifyListeners();
      return newFood;
    } catch (e) {
      _setError('添加食品失败: $e', context: 'food_management');
      return null;
    }
  }

  // 更新食品
  Future<bool> updateFood(FoodItem foodItem) async {
    try {
      // 检查名称是否已存在（排除自身）
      final exists = await _foodItemDao.isNameExists(
        foodItem.name,
        excludeId: foodItem.id,
      );
      if (exists) {
        _setError('已存在同名食品', context: 'food_management');
        return false;
      }

      await _foodItemDao.update(foodItem);

      // 更新食品列表
      final index = _foodItems.indexWhere((item) => item.id == foodItem.id);
      if (index != -1) {
        _foodItems[index] = foodItem;
        _foodItems.sort((a, b) => a.name.compareTo(b.name));
      }

      // 如果当前有加载的餐次食品记录，需要更新
      for (final mealId in _mealFoodDetails.keys) {
        final details = await _mealFoodRecordDao.getMealFoodDetails(mealId);
        _mealFoodDetails[mealId] = details;

        final nutrition = await _mealFoodRecordDao.calculateMealNutrition(
          mealId,
        );
        _mealNutrition[mealId] = nutrition;
      }

      // 更新当天的营养总量
      _dailyNutrition = await _mealFoodRecordDao.calculateDailyNutrition(
        _selectedDate,
      );

      notifyListeners();
      return true;
    } catch (e) {
      _setError('更新食品失败: $e', context: 'food_management');
      return false;
    }
  }

  // 删除食品
  Future<bool> deleteFood(int foodId) async {
    try {
      await _foodItemDao.delete(foodId);

      // 更新食品列表
      _foodItems.removeWhere((item) => item.id == foodId);

      notifyListeners();
      return true;
    } catch (e) {
      _setError('删除食品失败: $e', context: 'food_management');
      return false;
    }
  }

  // 清空食品列表
  Future<bool> clearAllFood() async {
    try {
      _setLoading(true);

      // 先删除所有未关联餐次的食品
      await _foodItemDao.clear();

      // 重新加载食品列表
      await _loadFoodItems();

      notifyListeners();
      return true;
    } catch (e) {
      _setError('清空食品列表失败: $e', context: 'food_management');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 获取指定日期范围的营养摄入数据
  Future<List<Map<String, dynamic>>> getNutritionDataByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _mealFoodRecordDao.getDailyNutritionByDateRange(
        startDate,
        endDate,
      );
    } catch (e) {
      _setError('获取营养数据失败: $e', context: 'diet_diary_home');
      return [];
    }
  }

  // 更新餐次记录
  Future<void> updateMealRecord(MealRecord mealRecord) async {
    try {
      await _mealRecordDao.update(mealRecord);

      // 更新本地餐次记录列表
      final index = _mealRecords.indexWhere(
        (record) => record.id == mealRecord.id,
      );
      if (index != -1) {
        _mealRecords[index] = mealRecord;
        notifyListeners();
      }
    } catch (e) {
      _setError('更新餐次记录失败: $e', context: 'meal_detail');
    }
  }

  // 获取用户体重记录
  Future<List<WeightRecord>> getWeightRecords(String userId) async {
    try {
      return await _weightRecordDao.getByUserId(userId);
    } catch (e) {
      _setError('获取体重记录失败: $e', context: 'weight_management');
      return [];
    }
  }

  // 添加体重记录
  Future<int?> addWeightRecord(WeightRecord weightRecord) async {
    try {
      final id = await _weightRecordDao.insert(weightRecord);
      return id;
    } catch (e) {
      _setError('添加体重记录失败: $e', context: 'weight_management');
      return null;
    }
  }

  // 更新体重记录
  Future<bool> updateWeightRecord(WeightRecord weightRecord) async {
    try {
      final result = await _weightRecordDao.update(weightRecord);
      return result > 0;
    } catch (e) {
      _setError('更新体重记录失败: $e', context: 'weight_management');
      return false;
    }
  }

  // 删除体重记录
  Future<bool> deleteWeightRecord(int id) async {
    try {
      final result = await _weightRecordDao.delete(id);
      return result > 0;
    } catch (e) {
      _setError('删除体重记录失败: $e', context: 'weight_management');
      return false;
    }
  }

  // 获取日期格式化字符串
  String getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return '今天 (${DateFormat('MM月dd日').format(date)})';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return '昨天 (${DateFormat('MM月dd日').format(date)})';
    } else if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return '明天 (${DateFormat('MM月dd日').format(date)})';
    } else {
      return DateFormat('yyyy年MM月dd日').format(date);
    }
  }

  // 获取格式化的日期时间
  String getFormattedDateTime(DateTime dateTime) {
    return DateFormat('yyyy年MM月dd日 HH:mm').format(dateTime);
  }

  // 设置加载状态
  void _setLoading(bool loading, {bool skipNotify = false}) {
    _isLoading = loading;
    if (!skipNotify) {
      notifyListeners();
    }
  }

  // 设置错误信息
  void _setError(String message, {bool skipNotify = false, String? context}) {
    _error = message;
    _errorContext = context;
    if (!skipNotify) {
      notifyListeners();
    }
  }

  // 清除错误信息
  void clearError() {
    _error = null;
    _errorContext = null;
    notifyListeners();
  }

  // 检查是否有特定上下文的错误
  bool hasErrorInContext(String context) {
    return _error != null && _errorContext == context;
  }

  // 获取餐次中的食品ID列表
  Future<List<int>> getMealFoodIds(int mealRecordId) async {
    try {
      final records = await _mealFoodRecordDao.getByMealRecordId(mealRecordId);
      return records.map((record) => record.foodItemId).toList();
    } catch (e) {
      _setError('获取餐次食品列表失败: $e', context: 'meal_detail');
      return [];
    }
  }

  // 获取餐次中指定食品的记录
  Future<MealFoodRecord?> getMealFoodRecord(
    int mealRecordId,
    int foodItemId,
  ) async {
    try {
      return await _mealFoodRecordDao.checkFoodExistsInMeal(
        mealRecordId,
        foodItemId,
      );
    } catch (e) {
      _setError('获取餐次食品记录失败: $e', context: 'meal_detail');
      return null;
    }
  }

  // 保存饮食分析结果
  Future<DietAnalysis> saveDietAnalysis(
    String content,
    String modelName,
  ) async {
    try {
      // 创建新的分析记录
      final newAnalysis = DietAnalysis(
        date: _selectedDate,
        content: content,
        modelName: modelName,
      );

      final id = await _dietAnalysisDao.insert(newAnalysis);
      final savedAnalysis = newAnalysis.copyWith(id: id);

      // 更新当前分析和分析列表
      _currentDietAnalysis = savedAnalysis;
      _currentDateAnalyses.insert(0, savedAnalysis); // 添加到列表开头

      notifyListeners();
      return savedAnalysis;
    } catch (e) {
      _setError('保存饮食分析失败: $e', context: 'diet_analysis');
      rethrow;
    }
  }

  // 获取指定日期的最新饮食分析
  Future<DietAnalysis?> getLatestDietAnalysis(DateTime date) async {
    try {
      return await _dietAnalysisDao.getLatestByDate(date);
    } catch (e) {
      _setError('获取饮食分析失败: $e', context: 'diet_analysis');
      return null;
    }
  }

  // 获取指定日期的所有饮食分析
  Future<List<DietAnalysis>> getDietAnalysesByDate(DateTime date) async {
    try {
      return await _dietAnalysisDao.getAllByDate(date);
    } catch (e) {
      _setError('获取饮食分析失败: $e', context: 'diet_analysis');
      return [];
    }
  }

  // 获取所有饮食分析
  Future<List<DietAnalysis>> getAllDietAnalyses() async {
    try {
      return await _dietAnalysisDao.getAll();
    } catch (e) {
      _setError('获取所有饮食分析失败: $e', context: 'diet_analysis');
      return [];
    }
  }

  // 删除饮食分析
  Future<void> deleteDietAnalysis(int id) async {
    try {
      await _dietAnalysisDao.delete(id);
      notifyListeners();
    } catch (e) {
      _setError('删除饮食分析失败: $e', context: 'diet_analysis');
    }
  }

  // 保存食谱
  Future<DietRecipe> saveDietRecipe({
    required String content,
    required String modelName,
    required int days,
    required int mealsPerDay,
    String? dietaryPreference,
    int? analysisId,
  }) async {
    try {
      // 创建新的食谱记录
      final newRecipe = DietRecipe(
        date: _selectedDate,
        content: content,
        modelName: modelName,
        days: days,
        mealsPerDay: mealsPerDay,
        dietaryPreference: dietaryPreference,
        analysisId: analysisId,
      );

      final id = await _dietRecipeDao.insert(newRecipe);
      final savedRecipe = newRecipe.copyWith(id: id);

      // 更新当前食谱和食谱列表
      _currentDietRecipe = savedRecipe;
      _currentDateRecipes.insert(0, savedRecipe); // 添加到列表开头

      notifyListeners();
      return savedRecipe;
    } catch (e) {
      _setError('保存食谱失败: $e', context: 'diet_recipe');
      rethrow;
    }
  }

  // 获取指定日期的最新食谱
  Future<DietRecipe?> getLatestDietRecipe(DateTime date) async {
    try {
      return await _dietRecipeDao.getLatestByDate(date);
    } catch (e) {
      _setError('获取食谱失败: $e', context: 'diet_recipe');
      return null;
    }
  }

  // 获取指定日期的所有食谱
  Future<List<DietRecipe>> getDietRecipesByDate(DateTime date) async {
    try {
      return await _dietRecipeDao.getAllByDate(date);
    } catch (e) {
      _setError('获取食谱失败: $e', context: 'diet_recipe');
      return [];
    }
  }

  // 获取与分析相关的食谱
  Future<List<DietRecipe>> getDietRecipesByAnalysisId(int analysisId) async {
    try {
      return await _dietRecipeDao.getByAnalysisId(analysisId);
    } catch (e) {
      _setError('获取相关食谱失败: $e', context: 'diet_recipe');
      return [];
    }
  }

  // 获取所有食谱
  Future<List<DietRecipe>> getAllDietRecipes() async {
    try {
      return await _dietRecipeDao.getAll();
    } catch (e) {
      _setError('获取所有食谱失败: $e', context: 'diet_recipe');
      return [];
    }
  }

  // 删除食谱
  Future<void> deleteDietRecipe(int id) async {
    try {
      await _dietRecipeDao.delete(id);
      notifyListeners();
    } catch (e) {
      _setError('删除食谱失败: $e', context: 'diet_recipe');
    }
  }
}
