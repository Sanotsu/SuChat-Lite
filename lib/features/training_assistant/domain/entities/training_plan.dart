import 'package:uuid/uuid.dart';

class TrainingPlan {
  final String planId;
  final String userId;
  final String planName;
  final String targetGoal; // 训练计划目标
  final String targetMuscleGroups; // 训练计划目标肌群
  final int duration; // 计划持续周数
  final String frequency; // 训练日（如 "1,3,5" 表示周一、周三、周五）
  final String difficulty; // 难度级别：初级、中级、高级
  final String? description; // 计划描述
  final String? equipment; // 训练器材
  final bool isActive;
  final DateTime gmtCreate;
  final DateTime? gmtModified;

  TrainingPlan({
    String? planId,
    required this.userId,
    required this.planName,
    required this.targetGoal,
    required this.targetMuscleGroups,
    required this.duration,
    required this.frequency,
    required this.difficulty,
    this.description,
    this.equipment,
    required this.isActive,
    DateTime? gmtCreate,
    this.gmtModified,
  }) : planId = planId ?? const Uuid().v4(),
       gmtCreate = gmtCreate ?? DateTime.now();

  // 从Map创建实例（用于数据库查询结果）
  factory TrainingPlan.fromMap(Map<String, dynamic> map) {
    return TrainingPlan(
      planId: map['planId'],
      userId: map['userId'],
      planName: map['planName'],
      targetGoal: map['targetGoal'],
      targetMuscleGroups: map['targetMuscleGroups'],
      duration: map['duration'],
      frequency:
          map['frequency'] is int
              ? map['frequency'].toString()
              : map['frequency'],
      difficulty: map['difficulty'],
      description: map['description'],
      equipment: map['equipment'],
      isActive: map['isActive'] == 1,
      gmtCreate:
          map['gmtCreate'] != null ? DateTime.parse(map['gmtCreate']) : null,
      gmtModified:
          map['gmtModified'] != null
              ? DateTime.parse(map['gmtModified'])
              : null,
    );
  }

  // 转换为Map（用于数据库插入）
  Map<String, dynamic> toMap() {
    return {
      'planId': planId,
      'userId': userId,
      'planName': planName,
      'targetGoal': targetGoal,
      'targetMuscleGroups': targetMuscleGroups,
      'duration': duration,
      'frequency': frequency,
      'difficulty': difficulty,
      'description': description,
      'equipment': equipment,
      'isActive': isActive ? 1 : 0,
      'gmtCreate': gmtCreate.toIso8601String(),
      'gmtModified': gmtModified?.toIso8601String(),
    };
  }

  // 创建一个副本但更新某些字段
  TrainingPlan copyWith({
    String? planName,
    String? targetGoal,
    String? targetMuscleGroups,
    int? duration,
    String? frequency,
    String? difficulty,
    String? description,
    String? equipment,
    bool? isActive,
  }) {
    return TrainingPlan(
      planId: planId,
      userId: userId,
      planName: planName ?? this.planName,
      targetGoal: targetGoal ?? this.targetGoal,
      targetMuscleGroups: targetMuscleGroups ?? this.targetMuscleGroups,
      duration: duration ?? this.duration,
      frequency: frequency ?? this.frequency,
      difficulty: difficulty ?? this.difficulty,
      description: description ?? this.description,
      equipment: equipment ?? this.equipment,
      isActive: isActive ?? this.isActive,
      gmtCreate: gmtCreate,
      gmtModified: DateTime.now(),
    );
  }
}
