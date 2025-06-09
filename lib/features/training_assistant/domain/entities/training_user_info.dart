import 'package:uuid/uuid.dart';

class TrainingUserInfo {
  final String userId;
  final String gender;
  final double height;
  final double weight;
  final int? age;
  final String? fitnessLevel;
  final String? healthConditions;
  final DateTime gmtCreate;
  final DateTime? gmtModified;

  TrainingUserInfo({
    String? userId,
    required this.gender,
    required this.height,
    required this.weight,
    this.age,
    this.fitnessLevel,
    this.healthConditions,
    DateTime? gmtCreate,
    this.gmtModified,
  }) : userId = userId ?? const Uuid().v4(),
       gmtCreate = gmtCreate ?? DateTime.now();

  // 从Map创建实例（用于数据库查询结果）
  factory TrainingUserInfo.fromMap(Map<String, dynamic> map) {
    return TrainingUserInfo(
      userId: map['userId'],
      gender: map['gender'],
      height: map['height'],
      weight: map['weight'],
      age: map['age'],
      fitnessLevel: map['fitnessLevel'],
      healthConditions: map['healthConditions'],
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
      'userId': userId,
      'gender': gender,
      'height': height,
      'weight': weight,
      'age': age,
      'fitnessLevel': fitnessLevel,
      'healthConditions': healthConditions,
      'gmtCreate': gmtCreate.toIso8601String(),
      'gmtModified': gmtModified?.toIso8601String(),
    };
  }

  // 创建一个副本但更新某些字段
  TrainingUserInfo copyWith({
    String? gender,
    double? height,
    double? weight,
    int? age,
    String? fitnessLevel,
    String? healthConditions,
  }) {
    return TrainingUserInfo(
      userId: userId,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      age: age ?? this.age,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      healthConditions: healthConditions ?? this.healthConditions,
      gmtCreate: gmtCreate,
      gmtModified: DateTime.now(),
    );
  }
}
