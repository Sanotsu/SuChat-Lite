import 'package:uuid/uuid.dart';

class TrainingPlanDetail {
  final String detailId;
  final String planId;
  final int day;
  final String exerciseName;
  final String muscleGroup;
  final int sets; // 组数
  final String reps; // 每组次数，可能是范围如"8-12"或具体数字
  final int countdown; // 完成该组动作预计需要的时长
  final int restTime; // 休息时间（秒）
  final String? instructions;
  final String? imageUrl;
  final DateTime gmtCreate;

  TrainingPlanDetail({
    String? detailId,
    required this.planId,
    required this.day,
    required this.exerciseName,
    required this.muscleGroup,
    required this.sets,
    required this.reps,
    required this.countdown,
    required this.restTime,
    this.instructions,
    this.imageUrl,
    DateTime? gmtCreate,
  }) : detailId = detailId ?? const Uuid().v4(),
       gmtCreate = gmtCreate ?? DateTime.now();

  // 从Map创建实例（用于数据库查询结果）
  factory TrainingPlanDetail.fromMap(Map<String, dynamic> map) {
    return TrainingPlanDetail(
      detailId: map['detailId'],
      planId: map['planId'],
      day: map['day'],
      exerciseName: map['exerciseName'],
      muscleGroup: map['muscleGroup'],
      sets: map['sets'],
      reps: map['reps'],
      countdown: map['countdown'],
      restTime: map['restTime'],
      instructions: map['instructions'],
      imageUrl: map['imageUrl'],
      gmtCreate:
          map['gmtCreate'] != null ? DateTime.parse(map['gmtCreate']) : null,
    );
  }

  // 转换为Map（用于数据库插入）
  Map<String, dynamic> toMap() {
    return {
      'detailId': detailId,
      'planId': planId,
      'day': day,
      'exerciseName': exerciseName,
      'muscleGroup': muscleGroup,
      'sets': sets,
      'reps': reps,
      'countdown': countdown,
      'restTime': restTime,
      'instructions': instructions,
      'imageUrl': imageUrl,
      'gmtCreate': gmtCreate.toIso8601String(),
    };
  }

  // 创建一个副本但更新某些字段
  TrainingPlanDetail copyWith({
    int? day,
    String? exerciseName,
    String? muscleGroup,
    int? sets,
    String? reps,
    int? countdown,
    int? restTime,
    String? instructions,
    String? imageUrl,
  }) {
    return TrainingPlanDetail(
      detailId: detailId,
      planId: planId,
      day: day ?? this.day,
      exerciseName: exerciseName ?? this.exerciseName,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      countdown: countdown ?? this.countdown,
      restTime: restTime ?? this.restTime,
      instructions: instructions ?? this.instructions,
      imageUrl: imageUrl ?? this.imageUrl,
      gmtCreate: gmtCreate,
    );
  }
}
