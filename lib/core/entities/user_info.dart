import 'package:uuid/uuid.dart';

import '../../shared/constants/constants.dart';

enum Gender { male, female }

enum Goal { loseWeight, maintainWeight, gainMuscle, stayHealthy }

String getGoalText(Goal goal) {
  switch (goal) {
    case Goal.loseWeight:
      return '减脂';
    case Goal.maintainWeight:
      return '维持体重';
    case Goal.gainMuscle:
      return '增肌';
    case Goal.stayHealthy:
      return '保持健康';
  }
}

String getActivityLevelText(double level) {
  if (level <= 1.2) {
    return '久坐不动 (1.2)';
  } else if (level <= 1.375) {
    return '轻度活动 (1.375)';
  } else if (level <= 1.55) {
    return '中度活动 (1.55)';
  } else if (level <= 1.725) {
    return '高度活动 (1.725)';
  } else {
    return '极高活动 (1.9)';
  }
}

/// 2025-06-23 这个还没有用到
enum ActivityLevel { sedentary, light, moderate, high, veryHigh }

List<CusLabel> activityLevels = [
  CusLabel(enLabel: 'sedentary', cnLabel: '久坐不动 (1.2)', value: 1.2),
  CusLabel(enLabel: 'light', cnLabel: '轻度活动 (1.375)', value: 1.375),
  CusLabel(enLabel: 'moderate', cnLabel: '中度活动 (1.55)', value: 1.55),
  CusLabel(enLabel: 'high', cnLabel: '高度活动 (1.725)', value: 1.725),
  CusLabel(enLabel: 'veryHigh', cnLabel: '极高活动 (1.9)', value: 1.9),
];

List<double> activityLevelValues =
    activityLevels.map((e) => e.value as double).toList();

CusLabel getActivityLevel(ActivityLevel level) {
  return activityLevels.firstWhere((e) => e.value == level.name);
}

/// 统一用户信息实体类
/// 合并了训练助手和饮食日记的用户信息
class UserInfo {
  // 用户ID
  final String userId;
  // 用户名称
  String name;
  // 性别 (male/female/other)
  Gender gender;
  // 年龄
  int? age;
  // 身高(cm)
  double height;
  // 体重(kg)
  double weight;

  // 训练助手特有字段
  String? fitnessLevel; // 健身水平 (beginner/intermediate/advanced)
  String? healthConditions; // 健康状况，可以是多个条件的JSON字符串

  // 饮食日记特有字段
  Goal? goal; // 目标 (0:减重, 1:保持, 2:增肌)
  double? activityLevel; // 活动水平 (1.2-1.9)
  double? targetCalories; // 目标卡路里
  double? targetCarbs; // 目标碳水化合物(g)
  double? targetProtein; // 目标蛋白质(g)
  double? targetFat; // 目标脂肪(g)

  // 其他参数，json字符串(比如style、coverImageUrl等，不是所有平台和模型都有返回的)
  String? otherParams;

  // 时间字段
  DateTime gmtCreate;
  DateTime? gmtModified;

  UserInfo({
    required this.userId,
    required this.name,
    required this.gender,
    this.age,
    required this.height,
    required this.weight,
    this.fitnessLevel,
    this.healthConditions,
    this.goal,
    this.activityLevel,
    this.targetCalories,
    this.targetCarbs,
    this.targetProtein,
    this.targetFat,
    this.otherParams,
    DateTime? gmtCreate,
    this.gmtModified,
  }) : gmtCreate = gmtCreate ?? DateTime.now();

  // 计算基础代谢率（BMR）
  double get bmr {
    var age = this.age ?? 30;
    if (gender == Gender.male) {
      return 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      return 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }
  }

  // 计算每日总能量消耗（TDEE）
  double get tdee {
    return bmr * (activityLevel ?? 1.2);
  }

  // 计算身体质量指数（BMI）
  double get bmi {
    return weight / ((height / 100) * (height / 100));
  }

  // 计算BMI
  double calculateBMI() {
    // BMI = 体重(kg) / 身高(m)²
    final heightInMeter = height / 100;
    return weight / (heightInMeter * heightInMeter);
  }

  // 从Map创建实例（用于数据库查询结果）
  factory UserInfo.fromMap(Map<String, dynamic> map) {
    return UserInfo(
      userId: map['userId'] as String,
      name: map['name'] as String,
      gender: Gender.values[map['gender']],
      age: map['age'] as int?,
      height: map['height'] as double,
      weight: map['weight'] as double,
      fitnessLevel: map['fitnessLevel'] as String?,
      healthConditions: map['healthConditions'] as String?,
      goal: Goal.values[map['goal']],
      activityLevel: map['activityLevel'] as double?,
      targetCalories: map['targetCalories'] as double?,
      targetCarbs: map['targetCarbs'] as double?,
      targetProtein: map['targetProtein'] as double?,
      targetFat: map['targetFat'] as double?,
      otherParams: map['otherParams'] as String?,
      gmtCreate:
          map['gmtCreate'] != null ? DateTime.parse(map['gmtCreate']) : null,
      gmtModified:
          map['gmtModified'] != null
              ? DateTime.parse(map['gmtModified'])
              : null,
    );
  }

  // 转换为Map（用于数据库插入/更新）
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'gender': gender.index,
      'age': age,
      'height': height,
      'weight': weight,
      'fitnessLevel': fitnessLevel,
      'healthConditions': healthConditions,
      'goal': goal?.index,
      'activityLevel': activityLevel,
      'targetCalories': targetCalories,
      'targetCarbs': targetCarbs,
      'targetProtein': targetProtein,
      'targetFat': targetFat,
      'otherParams': otherParams,
      'gmtCreate': gmtCreate.toIso8601String(),
      'gmtModified': gmtModified?.toIso8601String(),
    };
  }

  // 复制并修改部分字段
  UserInfo copyWith({
    String? userId,
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
    String? otherParams,
    DateTime? gmtCreate,
    DateTime? gmtModified,
  }) {
    return UserInfo(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      healthConditions: healthConditions ?? this.healthConditions,
      goal: goal ?? this.goal,
      activityLevel: activityLevel ?? this.activityLevel,
      targetCalories: targetCalories ?? this.targetCalories,
      targetCarbs: targetCarbs ?? this.targetCarbs,
      targetProtein: targetProtein ?? this.targetProtein,
      targetFat: targetFat ?? this.targetFat,
      otherParams: otherParams ?? this.otherParams,
      gmtCreate: gmtCreate ?? this.gmtCreate,
      gmtModified: gmtModified ?? DateTime.now(),
    );
  }

  // 创建默认用户
  static UserInfo createDefault({String? userId}) {
    return UserInfo(
      userId: userId ?? const Uuid().v4(),
      name: '默认用户',
      gender: Gender.male,
      age: 30,
      height: 170.0,
      weight: 65.0,
      fitnessLevel: 'beginner',
      healthConditions: '',
      goal: Goal.maintainWeight, // 保持体重
      activityLevel: 1.5, // 中等活动水平
      targetCalories: 2000.0,
      targetCarbs: 250.0,
      targetProtein: 75.0,
      targetFat: 67.0,
      gmtCreate: DateTime.now(),
      gmtModified: DateTime.now(),
    );
  }
}
