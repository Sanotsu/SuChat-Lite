/// 餐次食品详情实体类，用于表示餐次中的食品详情信息
class MealFoodDetail {
  final int id; // 餐次食品记录ID
  final int mealRecordId; // 餐次记录ID
  final int foodItemId; // 食品ID
  final String foodName; // 食品名称
  final String? foodCode; // 食品编码
  final double quantity; // 食用量
  final String? unit; // 单位
  final double caloriesPer100g; // 每100克热量
  final double carbsPer100g; // 每100克碳水
  final double proteinPer100g; // 每100克蛋白质
  final double fatPer100g; // 每100克脂肪
  final double? fiberPer100g; // 每100克膳食纤维
  final double? cholesterolPer100g; // 每100克胆固醇
  final double? sodiumPer100g; // 每100克钠
  final double? calciumPer100g; // 每100克钙
  final double? ironPer100g; // 每100克铁
  final double? vitaminAPer100g; // 每100克维生素A
  final double? vitaminCPer100g; // 每100克维生素C
  final double? vitaminEPer100g; // 每100克维生素E
  final DateTime gmtCreate; // 创建时间
  final DateTime gmtModified; // 更新时间

  MealFoodDetail({
    required this.id,
    required this.mealRecordId,
    required this.foodItemId,
    required this.foodName,
    this.foodCode,
    required this.quantity,
    this.unit,
    required this.caloriesPer100g,
    required this.carbsPer100g,
    required this.proteinPer100g,
    required this.fatPer100g,
    this.fiberPer100g,
    this.cholesterolPer100g,
    this.sodiumPer100g,
    this.calciumPer100g,
    this.ironPer100g,
    this.vitaminAPer100g,
    this.vitaminCPer100g,
    this.vitaminEPer100g,
    required this.gmtCreate,
    required this.gmtModified,
  });

  /// 计算实际摄入的热量
  double get calories => caloriesPer100g * quantity / 100;

  /// 计算实际摄入的碳水化合物
  double get carbs => carbsPer100g * quantity / 100;

  /// 计算实际摄入的蛋白质
  double get protein => proteinPer100g * quantity / 100;

  /// 计算实际摄入的脂肪
  double get fat => fatPer100g * quantity / 100;

  /// 计算实际摄入的膳食纤维
  double? get fiber =>
      fiberPer100g != null ? fiberPer100g! * quantity / 100 : null;

  /// 计算实际摄入的胆固醇
  double? get cholesterol =>
      cholesterolPer100g != null ? cholesterolPer100g! * quantity / 100 : null;

  /// 计算实际摄入的钠
  double? get sodium =>
      sodiumPer100g != null ? sodiumPer100g! * quantity / 100 : null;

  /// 计算实际摄入的钙
  double? get calcium =>
      calciumPer100g != null ? calciumPer100g! * quantity / 100 : null;

  /// 计算实际摄入的铁
  double? get iron =>
      ironPer100g != null ? ironPer100g! * quantity / 100 : null;

  /// 计算实际摄入的维生素A
  double? get vitaminA =>
      vitaminAPer100g != null ? vitaminAPer100g! * quantity / 100 : null;

  /// 计算实际摄入的维生素C
  double? get vitaminC =>
      vitaminCPer100g != null ? vitaminCPer100g! * quantity / 100 : null;

  /// 计算实际摄入的维生素E
  double? get vitaminE =>
      vitaminEPer100g != null ? vitaminEPer100g! * quantity / 100 : null;

  /// 从数据库查询结果映射创建实例
  factory MealFoodDetail.fromMap(Map<String, dynamic> map) {
    return MealFoodDetail(
      id: map['id'] as int,
      mealRecordId: map['mealRecordId'] as int,
      foodItemId: map['foodItemId'] as int,
      foodName: map['name'] as String,
      foodCode: map['foodCode'] as String?,
      quantity: map['quantity'] as double,
      unit: map['unit'] as String?,
      caloriesPer100g: map['caloriesPer100g'] as double,
      carbsPer100g: map['carbsPer100g'] as double,
      proteinPer100g: map['proteinPer100g'] as double,
      fatPer100g: map['fatPer100g'] as double,
      fiberPer100g: map['fiberPer100g'] as double?,
      cholesterolPer100g: map['cholesterolPer100g'] as double?,
      sodiumPer100g: map['sodiumPer100g'] as double?,
      calciumPer100g: map['calciumPer100g'] as double?,
      ironPer100g: map['ironPer100g'] as double?,
      vitaminAPer100g: map['vitaminAPer100g'] as double?,
      vitaminCPer100g: map['vitaminCPer100g'] as double?,
      vitaminEPer100g: map['vitaminEPer100g'] as double?,
      gmtCreate:
          map['gmtCreate'] != null
              ? DateTime.parse(map['gmtCreate'])
              : DateTime.now(),
      gmtModified:
          map['gmtModified'] != null
              ? DateTime.parse(map['gmtModified'])
              : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealFoodDetail &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          mealRecordId == other.mealRecordId &&
          foodItemId == other.foodItemId;

  @override
  int get hashCode => id.hashCode ^ mealRecordId.hashCode ^ foodItemId.hashCode;

  @override
  String toString() {
    return 'MealFoodDetail{id: $id, foodName: $foodName, quantity: $quantity$unit}';
  }
}
