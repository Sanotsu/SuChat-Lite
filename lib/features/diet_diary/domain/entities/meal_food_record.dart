class MealFoodRecord {
  final int? id;
  final int mealRecordId;
  final int foodItemId;
  final double quantity; // 食用量，单位为克
  final String? unit; // 单位（如"克"、"份"、"个"等）
  final DateTime createdAt;
  final DateTime updatedAt;

  MealFoodRecord({
    this.id,
    required this.mealRecordId,
    required this.foodItemId,
    required this.quantity,
    this.unit = '克',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mealRecordId': mealRecordId,
      'foodItemId': foodItemId,
      'quantity': quantity,
      'unit': unit,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MealFoodRecord.fromMap(Map<String, dynamic> map) {
    return MealFoodRecord(
      id: map['id'],
      mealRecordId: map['mealRecordId'],
      foodItemId: map['foodItemId'],
      quantity: map['quantity'],
      unit: map['unit'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  MealFoodRecord copyWith({
    int? id,
    int? mealRecordId,
    int? foodItemId,
    double? quantity,
    String? unit,
    DateTime? updatedAt,
  }) {
    return MealFoodRecord(
      id: id ?? this.id,
      mealRecordId: mealRecordId ?? this.mealRecordId,
      foodItemId: foodItemId ?? this.foodItemId,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
