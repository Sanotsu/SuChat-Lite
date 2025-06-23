import 'package:flutter/material.dart';

import '../../../../core/entities/cus_llm_model.dart';
import '../../../../core/entities/user_info.dart';
import '../../data/services/training_assistant_service.dart';
import '../../data/training_dao.dart';
import '../../domain/entities/training_plan.dart';
import '../../domain/entities/training_plan_detail.dart';
import '../../domain/entities/training_record.dart';
import '../../domain/entities/training_record_detail.dart';

class TrainingViewModel extends ChangeNotifier {
  final TrainingDao _trainingDao = TrainingDao();
  final TrainingAssistantService _trainingService = TrainingAssistantService();

  // 当前选中的训练计划
  TrainingPlan? _selectedPlan;
  TrainingPlan? get selectedPlan => _selectedPlan;

  // 当前计划的详情
  List<TrainingPlanDetail> _planDetails = [];
  List<TrainingPlanDetail> get planDetails => _planDetails;

  // 当前用户的所有训练计划
  List<TrainingPlan> _userPlans = [];
  List<TrainingPlan> get userPlans => _userPlans;

  // 当前用户的活跃训练计划
  List<TrainingPlan> _activePlans = [];
  List<TrainingPlan> get activePlans => _activePlans;

  // 当前计划的训练记录
  List<TrainingRecord> _planRecords = [];
  List<TrainingRecord> get planRecords => _planRecords;

  // 状态管理
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // 生成训练计划
  Future<void> generateTrainingPlan({
    required UserInfo userInfo,
    required String targetGoal,
    required List<String> targetMuscleGroups,
    required int duration,
    required String frequency,
    String? equipment,
    required CusLLMSpec model,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _trainingService.generateTrainingPlan(
        userId: userInfo.userId,
        gender: userInfo.gender.name,
        height: userInfo.height,
        weight: userInfo.weight,
        age: userInfo.age ?? 30,
        fitnessLevel: userInfo.fitnessLevel ?? '初级',
        healthConditions: userInfo.healthConditions,
        targetGoal: targetGoal,
        targetMuscleGroups: targetMuscleGroups,
        duration: duration,
        frequency: frequency,
        equipment: equipment,
        model: model,
      );

      _selectedPlan = result['plan'] as TrainingPlan;
      _planDetails = result['details'] as List<TrainingPlanDetail>;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = '生成训练计划失败: $e';
      notifyListeners();
    }
  }

  // 使用自定义提示词生成训练计划
  Future<void> generateTrainingPlanWithCustomPrompt({
    required UserInfo userInfo,
    required String targetGoal,
    required List<String> targetMuscleGroups,
    required int duration,
    required String frequency,
    String? equipment,
    required String customPrompt,
    required CusLLMSpec model,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _trainingService
          .generateTrainingPlanWithCustomPrompt(
            userId: userInfo.userId,
            targetGoal: targetGoal,
            targetMuscleGroups: targetMuscleGroups.join(', '),
            duration: duration,
            frequency: frequency,
            equipment: equipment,
            customPrompt: customPrompt,
            model: model,
          );

      _selectedPlan = result['plan'] as TrainingPlan;
      _planDetails = result['details'] as List<TrainingPlanDetail>;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = '使用自定义提示词生成训练计划失败: $e';
      notifyListeners();
    }
  }

  // 保存训练计划
  Future<void> saveTrainingPlan(String userId) async {
    try {
      if (_selectedPlan == null || _planDetails.isEmpty) {
        _error = '没有可保存的训练计划';
        notifyListeners();
        return;
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      await _trainingDao.insertTrainingPlans([_selectedPlan!]);
      await _trainingDao.insertTrainingPlanDetails(_planDetails);

      // 重新加载用户的训练计划
      await loadUserTrainingPlans(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = '保存训练计划失败: $e';
      notifyListeners();
    }
  }

  // 加载用户的所有训练计划
  Future<void> loadUserTrainingPlans(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _userPlans = await _trainingDao.getUserTrainingPlans(userId);
      _activePlans = await _trainingDao.getUserActiveTrainingPlans(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = '加载训练计划失败: $e';
      notifyListeners();
    }
  }

  // 选择训练计划并加载详情
  Future<void> selectTrainingPlan(String planId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _selectedPlan = await _trainingDao.getTrainingPlan(planId);
      if (_selectedPlan != null) {
        _planDetails = await _trainingDao.getTrainingPlanDetails(planId);
        _planRecords = await _trainingDao.getTrainingRecordsForPlan(planId);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = '加载训练计划详情失败: $e';
      notifyListeners();
    }
  }

  // 更新训练计划
  Future<void> updateTrainingPlan({
    required String planName,
    required String difficulty,
    String? description,
    bool? isActive,
  }) async {
    try {
      if (_selectedPlan == null) {
        _error = '没有选中的训练计划';
        notifyListeners();
        return;
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedPlan = _selectedPlan!.copyWith(
        planName: planName,
        difficulty: difficulty,
        description: description,
        isActive: isActive,
      );

      await _trainingDao.updateTrainingPlan(updatedPlan);
      _selectedPlan = updatedPlan;

      // 重新加载用户的训练计划
      await loadUserTrainingPlans(_selectedPlan!.userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = '更新训练计划失败: $e';
      notifyListeners();
    }
  }

  // 删除训练计划
  Future<bool> deleteTrainingPlan(String planId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // 检查是否有关联的训练记录
      final records = await _trainingDao.getTrainingRecordsForPlan(planId);
      if (records.isNotEmpty) {
        _isLoading = false;
        _error = '该训练计划已有关联的训练记录，无法删除';
        notifyListeners();
        return false;
      }

      await _trainingDao.deleteTrainingPlan(planId);

      // 如果删除的是当前选中的计划，清空选中状态
      if (_selectedPlan?.planId == planId) {
        _selectedPlan = null;
        _planDetails = [];
        _planRecords = [];
      }

      // 重新加载用户的训练计划
      await loadUserTrainingPlans(_selectedPlan!.userId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = '删除训练计划失败: $e';
      notifyListeners();
      return false;
    }
  }

  // 记录训练完成情况
  Future<void> recordTraining({
    required int duration,
    required double completionRate,
    int? caloriesBurned,
    String? feedback,
    required List<TrainingRecordDetail> recordDetails,
  }) async {
    try {
      if (_selectedPlan == null) {
        _error = '没有选中的训练计划';
        notifyListeners();
        return;
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      final record = TrainingRecord(
        planId: _selectedPlan!.planId,
        userId: _selectedPlan!.userId,
        date: DateTime.now(),
        duration: duration,
        completionRate: completionRate,
        caloriesBurned: caloriesBurned,
        feedback: feedback,
      );

      await _trainingDao.insertTrainingRecords([record]);

      // 保存训练记录详情
      final detailsWithRecordId =
          recordDetails.map((detail) {
            return TrainingRecordDetail(
              recordId: record.recordId,
              detailId: detail.detailId,
              exerciseName: detail.exerciseName,
              completed: detail.completed,
              actualSets: detail.actualSets,
              actualReps: detail.actualReps,
              notes: detail.notes,
            );
          }).toList();

      await _trainingDao.insertTrainingRecordDetails(detailsWithRecordId);

      // 重新加载训练记录
      _planRecords = await _trainingDao.getTrainingRecordsForPlan(
        _selectedPlan!.planId,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = '记录训练失败: $e';
      notifyListeners();
    }
  }

  // 获取用户在特定日期范围内的训练记录
  Future<List<TrainingRecord>> getUserTrainingRecordsInDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      if (_selectedPlan == null) {
        _error = '没有选中的训练计划';
        notifyListeners();
        return [];
      }

      return await _trainingDao.getUserTrainingRecordsInDateRange(
        _selectedPlan!.userId,
        startDate,
        endDate,
      );
    } catch (e) {
      _error = '获取训练记录失败: $e';
      notifyListeners();
      return [];
    }
  }

  // 获取特定训练计划的所有训练记录
  Future<List<TrainingRecord>> getTrainingRecordsForPlan(String planId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final records = await _trainingDao.getTrainingRecordsForPlan(planId);

      _isLoading = false;
      notifyListeners();
      return records;
    } catch (e) {
      _isLoading = false;
      _error = '获取训练记录失败: $e';
      notifyListeners();
      return [];
    }
  }

  // 获取训练记录的详细信息
  Future<Map<String, dynamic>> getTrainingRecordDetails(String recordId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // 获取训练记录
      final record = await _trainingDao.getTrainingRecord(recordId);
      if (record == null) {
        _isLoading = false;
        _error = '找不到训练记录';
        notifyListeners();
        return {};
      }

      // 获取训练计划
      final plan = await _trainingDao.getTrainingPlan(record.planId);
      if (plan == null) {
        _isLoading = false;
        _error = '找不到训练计划';
        notifyListeners();
        return {'record': record};
      }

      // 获取训练计划详情
      final planDetails = await _trainingDao.getTrainingPlanDetails(
        record.planId,
      );

      // 获取训练记录详情
      final recordDetails = await _trainingDao.getTrainingRecordDetails(
        recordId,
      );

      // 确定训练记录对应的训练日
      int trainingDay = 0;
      if (recordDetails.isNotEmpty) {
        // 通过记录详情中的第一个detailId，查找对应的训练计划详情
        final firstRecordDetail = recordDetails.first;
        final matchedPlanDetail = planDetails.firstWhere(
          (detail) => detail.detailId == firstRecordDetail.detailId,
          orElse: () => planDetails.first,
        );
        trainingDay = matchedPlanDetail.day;
      }

      // 获取当天的训练计划详情
      final todayPlanDetails =
          trainingDay > 0
              ? planDetails
                  .where((detail) => detail.day == trainingDay)
                  .toList()
              : planDetails;

      _isLoading = false;
      notifyListeners();

      return {
        'record': record,
        'plan': plan,
        'planDetails': planDetails,
        'todayPlanDetails': todayPlanDetails,
        'recordDetails': recordDetails,
        'trainingDay': trainingDay,
      };
    } catch (e) {
      _isLoading = false;
      _error = '获取训练记录详情失败: $e';
      notifyListeners();
      return {};
    }
  }

  // 更新训练计划详情
  Future<void> updatePlanDetails(
    String planId,
    List<TrainingPlanDetail> details,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // 删除原有的训练计划详情
      await _trainingDao.deleteAllTrainingPlanDetails(planId);

      // 保存新的训练计划详情
      await _trainingDao.insertTrainingPlanDetails(details);

      // 更新本地缓存
      if (_selectedPlan?.planId == planId) {
        _planDetails = details;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = '更新训练计划详情失败: $e';
      notifyListeners();
    }
  }

  // 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
