import '../../../../core/entities/cus_llm_model.dart';
import '../../../../core/storage/db_helper.dart';
import '../../domain/entities/training_user_info.dart';
import '../../domain/entities/training_plan.dart';
import '../../domain/entities/training_plan_detail.dart';
import '../../domain/entities/training_record.dart';
import '../../domain/entities/training_record_detail.dart';
import '../services/training_assistant_service.dart';

class TrainingRepository {
  final DBHelper _dbHelper = DBHelper();
  final TrainingAssistantService _trainingService = TrainingAssistantService();

  // 用户信息相关操作
  Future<void> saveUserInfo(TrainingUserInfo userInfo) async {
    await _dbHelper.saveTrainingUsers([userInfo]);
  }

  Future<void> updateUserInfo(TrainingUserInfo userInfo) async {
    await _dbHelper.updateTrainingUserInfo(userInfo);
  }

  Future<TrainingUserInfo?> getUserInfo(String userId) async {
    return await _dbHelper.getTrainingUserInfo(userId);
  }

  Future<List<TrainingUserInfo>> getAllUsers() async {
    return await _dbHelper.getAllTrainingUserInfo();
  }

  Future<void> deleteUserInfo(String userId) async {
    await _dbHelper.deleteTrainingUserInfo(userId);
  }

  // 训练计划相关操作
  Future<Map<String, dynamic>> generateTrainingPlan({
    required String userId,
    required String gender,
    required double height,
    required double weight,
    int? age,
    required String fitnessLevel,
    String? healthConditions,
    required String targetGoal,
    required List<String> targetMuscleGroups,
    required int duration,
    required String frequency,
    String? equipment,
    required CusLLMSpec model,
  }) async {
    return await _trainingService.generateTrainingPlan(
      userId: userId,
      gender: gender,
      height: height,
      weight: weight,
      age: age,
      fitnessLevel: fitnessLevel,
      healthConditions: healthConditions,
      targetGoal: targetGoal,
      targetMuscleGroups: targetMuscleGroups,
      duration: duration,
      frequency: frequency,
      equipment: equipment,
      model: model,
    );
  }

  // 使用自定义提示词生成训练计划
  Future<Map<String, dynamic>> generateTrainingPlanWithCustomPrompt({
    required String userId,
    required String targetGoal,
    required String targetMuscleGroups,
    required int duration,
    required String frequency,
    String? equipment,
    required String customPrompt,
    required CusLLMSpec model,
  }) async {
    return await _trainingService.generateTrainingPlanWithCustomPrompt(
      userId: userId,
      targetGoal: targetGoal,
      targetMuscleGroups: targetMuscleGroups,
      duration: duration,
      frequency: frequency,
      equipment: equipment,
      customPrompt: customPrompt,
      model: model,
    );
  }

  Future<void> saveTrainingPlan(
    TrainingPlan plan,
    List<TrainingPlanDetail> details,
  ) async {
    await _dbHelper.saveTrainingPlans([plan]);
    await _dbHelper.saveTrainingPlanDetails(details);
  }

  Future<void> updateTrainingPlan(TrainingPlan plan) async {
    await _dbHelper.updateTrainingPlan(plan);
  }

  Future<TrainingPlan?> getTrainingPlan(String planId) async {
    return await _dbHelper.getTrainingPlan(planId);
  }

  Future<List<TrainingPlan>> getUserTrainingPlans(String userId) async {
    return await _dbHelper.getUserTrainingPlans(userId);
  }

  Future<List<TrainingPlan>> getUserActiveTrainingPlans(String userId) async {
    return await _dbHelper.getUserActiveTrainingPlans(userId);
  }

  Future<void> deleteTrainingPlan(String planId) async {
    await _dbHelper.deleteTrainingPlan(planId);
  }

  // 训练计划详情相关操作
  Future<List<TrainingPlanDetail>> getTrainingPlanDetails(String planId) async {
    return await _dbHelper.getTrainingPlanDetails(planId);
  }

  Future<List<TrainingPlanDetail>> getTrainingPlanDetailsForDay(
    String planId,
    int day,
  ) async {
    return await _dbHelper.getTrainingPlanDetailsForDay(planId, day);
  }

  // 保存训练计划详情
  Future<void> saveTrainingPlanDetails(List<TrainingPlanDetail> details) async {
    await _dbHelper.saveTrainingPlanDetails(details);
  }

  // 删除训练计划详情
  Future<void> deleteTrainingPlanDetails(String planId) async {
    await _dbHelper.deleteAllTrainingPlanDetails(planId);
  }

  // 训练记录相关操作
  Future<void> saveTrainingRecord(TrainingRecord record) async {
    await _dbHelper.saveTrainingRecords([record]);
  }

  // 保存训练记录详情
  Future<void> saveTrainingRecordDetails(
    List<TrainingRecordDetail> details,
  ) async {
    await _dbHelper.saveTrainingRecordDetails(details);
  }

  // 获取训练记录
  Future<TrainingRecord?> getTrainingRecord(String recordId) async {
    return await _dbHelper.getTrainingRecord(recordId);
  }

  // 获取训练记录详情
  Future<List<TrainingRecordDetail>> getTrainingRecordDetails(
    String recordId,
  ) async {
    return await _dbHelper.getTrainingRecordDetails(recordId);
  }

  Future<List<TrainingRecord>> getTrainingRecordsForPlan(String planId) async {
    return await _dbHelper.getTrainingRecordsForPlan(planId);
  }

  Future<List<TrainingRecord>> getUserTrainingRecords(String userId) async {
    return await _dbHelper.getUserTrainingRecords(userId);
  }

  Future<List<TrainingRecord>> getUserTrainingRecordsInDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _dbHelper.getUserTrainingRecordsInDateRange(
      userId,
      startDate,
      endDate,
    );
  }
}
