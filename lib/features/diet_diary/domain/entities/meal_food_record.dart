class MealFoodRecord {
  final int? id;
  final int mealRecordId;
  final int foodItemId;
  final double quantity; // 食用量，单位为克
  final String? unit; // 单位（如"克"、"份"、"个"等）
  final DateTime gmtCreate;
  final DateTime gmtModified;

  MealFoodRecord({
    this.id,
    required this.mealRecordId,
    required this.foodItemId,
    required this.quantity,
    this.unit = '克',
    DateTime? gmtCreate,
    DateTime? gmtModified,
  }) : gmtCreate = gmtCreate ?? DateTime.now(),
       gmtModified = gmtModified ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mealRecordId': mealRecordId,
      'foodItemId': foodItemId,
      'quantity': quantity,
      'unit': unit,
      'gmtCreate': gmtCreate.toIso8601String(),
      'gmtModified': gmtModified.toIso8601String(),
    };
  }

  factory MealFoodRecord.fromMap(Map<String, dynamic> map) {
    return MealFoodRecord(
      id: map['id'],
      mealRecordId: map['mealRecordId'],
      foodItemId: map['foodItemId'],
      quantity: map['quantity'],
      unit: map['unit'],
      gmtCreate:
          map['gmtCreate'] != null ? DateTime.parse(map['gmtCreate']) : null,
      gmtModified:
          map['gmtModified'] != null
              ? DateTime.parse(map['gmtModified'])
              : null,
    );
  }

  MealFoodRecord copyWith({
    int? id,
    int? mealRecordId,
    int? foodItemId,
    double? quantity,
    String? unit,
    DateTime? gmtModified,
  }) {
    return MealFoodRecord(
      id: id ?? this.id,
      mealRecordId: mealRecordId ?? this.mealRecordId,
      foodItemId: foodItemId ?? this.foodItemId,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      gmtCreate: gmtCreate,
      gmtModified: gmtModified ?? DateTime.now(),
    );
  }
}
