import 'package:uuid/uuid.dart';

class TrainingRecord {
  final String recordId;
  final String planId;
  final String userId;
  final DateTime date;
  final int duration; // 训练时长（分钟）
  final int? caloriesBurned; // 消耗卡路里
  final double completionRate; // 完成率（0.0-1.0）
  final String? feedback; // 用户反馈
  final DateTime gmtCreate;

  TrainingRecord({
    String? recordId,
    required this.planId,
    required this.userId,
    required this.date,
    required this.duration,
    this.caloriesBurned,
    required this.completionRate,
    this.feedback,
    DateTime? gmtCreate,
  }) : recordId = recordId ?? const Uuid().v4(),
       gmtCreate = gmtCreate ?? DateTime.now();

  // 从Map创建实例（用于数据库查询结果）
  factory TrainingRecord.fromMap(Map<String, dynamic> map) {
    return TrainingRecord(
      recordId: map['recordId'],
      planId: map['planId'],
      userId: map['userId'],
      date: DateTime.parse(map['date']),
      duration: map['duration'],
      caloriesBurned: map['caloriesBurned'],
      completionRate: map['completionRate'],
      feedback: map['feedback'],
      gmtCreate:
          map['gmtCreate'] != null ? DateTime.parse(map['gmtCreate']) : null,
    );
  }

  // 转换为Map（用于数据库插入）
  Map<String, dynamic> toMap() {
    return {
      'recordId': recordId,
      'planId': planId,
      'userId': userId,
      'date': date.toIso8601String(),
      'duration': duration,
      'caloriesBurned': caloriesBurned,
      'completionRate': completionRate,
      'feedback': feedback,
      'gmtCreate': gmtCreate.toIso8601String(),
    };
  }

  // 创建一个副本但更新某些字段
  TrainingRecord copyWith({
    DateTime? date,
    int? duration,
    int? caloriesBurned,
    double? completionRate,
    String? feedback,
  }) {
    return TrainingRecord(
      recordId: recordId,
      planId: planId,
      userId: userId,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      completionRate: completionRate ?? this.completionRate,
      feedback: feedback ?? this.feedback,
      gmtCreate: gmtCreate,
    );
  }
}
