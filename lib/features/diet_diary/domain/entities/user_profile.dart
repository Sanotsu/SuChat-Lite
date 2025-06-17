enum Gender { male, female }

enum Goal { loseWeight, maintainWeight, gainMuscle, stayHealthy }

String getGoalText(Goal goal) {
  switch (goal) {
    case Goal.loseWeight:
      return '减脂塑形';
    case Goal.maintainWeight:
      return '维持体重';
    case Goal.gainMuscle:
      return '增肌健身';
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

class UserProfile {
  final int? id;
  final String name;
  final int age;
  final Gender gender;
  final double height; // 单位：厘米
  final double weight; // 单位：千克
  final Goal goal;
  final double activityLevel; // 活动水平系数，1.2-1.9之间
  final double targetCalories; // 目标每日卡路里摄入量
  final double targetCarbs; // 目标碳水化合物摄入量（克）
  final double targetProtein; // 目标蛋白质摄入量（克）
  final double targetFat; // 目标脂肪摄入量（克）
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.goal,
    required this.activityLevel,
    required this.targetCalories,
    required this.targetCarbs,
    required this.targetProtein,
    required this.targetFat,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // 计算基础代谢率（BMR）
  double get bmr {
    if (gender == Gender.male) {
      return 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      return 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }
  }

  // 计算每日总能量消耗（TDEE）
  double get tdee {
    return bmr * activityLevel;
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender.index,
      'height': height,
      'weight': weight,
      'goal': goal.index,
      'activityLevel': activityLevel,
      'targetCalories': targetCalories,
      'targetCarbs': targetCarbs,
      'targetProtein': targetProtein,
      'targetFat': targetFat,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      name: map['name'],
      age: map['age'],
      gender: Gender.values[map['gender']],
      height: map['height'],
      weight: map['weight'],
      goal: Goal.values[map['goal']],
      activityLevel: map['activityLevel'],
      targetCalories: map['targetCalories'],
      targetCarbs: map['targetCarbs'],
      targetProtein: map['targetProtein'],
      targetFat: map['targetFat'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  UserProfile copyWith({
    int? id,
    String? name,
    int? age,
    Gender? gender,
    double? height,
    double? weight,
    Goal? goal,
    double? activityLevel,
    double? targetCalories,
    double? targetCarbs,
    double? targetProtein,
    double? targetFat,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      goal: goal ?? this.goal,
      activityLevel: activityLevel ?? this.activityLevel,
      targetCalories: targetCalories ?? this.targetCalories,
      targetCarbs: targetCarbs ?? this.targetCarbs,
      targetProtein: targetProtein ?? this.targetProtein,
      targetFat: targetFat ?? this.targetFat,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // 生成默认用户配置文件
  factory UserProfile.defaultProfile() {
    return UserProfile(
      name: '用户',
      age: 30,
      gender: Gender.male,
      height: 170,
      weight: 70,
      goal: Goal.maintainWeight,
      activityLevel: 1.4, // 轻度活动水平
      targetCalories: 2000,
      targetCarbs: 250, // 50%的卡路里来自碳水
      targetProtein: 100, // 20%的卡路里来自蛋白质
      targetFat: 67, // 30%的卡路里来自脂肪
    );
  }
}
