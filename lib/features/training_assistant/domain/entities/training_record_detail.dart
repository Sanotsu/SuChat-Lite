import 'package:uuid/uuid.dart';

class TrainingRecordDetail {
  final String detailRecordId;
  final String recordId;
  final String detailId;
  final String exerciseName;
  final bool completed;
  final int actualSets;
  final String actualReps;
  final String? notes;
  final DateTime gmtCreate;

  TrainingRecordDetail({
    String? detailRecordId,
    required this.recordId,
    required this.detailId,
    required this.exerciseName,
    required this.completed,
    required this.actualSets,
    required this.actualReps,
    this.notes,
    DateTime? gmtCreate,
  }) : detailRecordId = detailRecordId ?? const Uuid().v4(),
       gmtCreate = gmtCreate ?? DateTime.now();

  // 从Map创建实例（用于数据库查询结果）
  factory TrainingRecordDetail.fromMap(Map<String, dynamic> map) {
    return TrainingRecordDetail(
      detailRecordId: map['detailRecordId'],
      recordId: map['recordId'],
      detailId: map['detailId'],
      exerciseName: map['exerciseName'],
      completed: map['completed'] == 1,
      actualSets: map['actualSets'],
      actualReps: map['actualReps'],
      notes: map['notes'],
      gmtCreate:
          map['gmtCreate'] != null ? DateTime.parse(map['gmtCreate']) : null,
    );
  }

  // 转换为Map（用于数据库插入）
  Map<String, dynamic> toMap() {
    return {
      'detailRecordId': detailRecordId,
      'recordId': recordId,
      'detailId': detailId,
      'exerciseName': exerciseName,
      'completed': completed ? 1 : 0,
      'actualSets': actualSets,
      'actualReps': actualReps,
      'notes': notes,
      'gmtCreate': gmtCreate.toIso8601String(),
    };
  }

  // 创建当前对象的副本，并可选择性地更新某些字段
  TrainingRecordDetail copyWith({
    String? detailRecordId,
    String? recordId,
    String? detailId,
    String? exerciseName,
    bool? completed,
    int? actualSets,
    String? actualReps,
    String? notes,
    DateTime? gmtCreate,
  }) {
    return TrainingRecordDetail(
      detailRecordId: detailRecordId ?? this.detailRecordId,
      recordId: recordId ?? this.recordId,
      detailId: detailId ?? this.detailId,
      exerciseName: exerciseName ?? this.exerciseName,
      completed: completed ?? this.completed,
      actualSets: actualSets ?? this.actualSets,
      actualReps: actualReps ?? this.actualReps,
      notes: notes ?? this.notes,
      gmtCreate: gmtCreate ?? this.gmtCreate,
    );
  }
}
