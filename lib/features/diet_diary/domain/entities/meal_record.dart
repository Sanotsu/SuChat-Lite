import 'meal_type.dart';

class MealRecord {
  final int? id;
  final DateTime date;
  final MealType mealType;
  final List<String>? imageUrls; // 餐次多张图片URL列表
  final String? description; // 餐次说明
  final DateTime createdAt;
  final DateTime updatedAt;

  MealRecord({
    this.id,
    required this.date,
    required this.mealType,
    this.imageUrls,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T')[0], // 只保留日期部分
      'mealType': mealType.index,
      'imageUrls': imageUrls?.join(','),
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MealRecord.fromMap(Map<String, dynamic> map) {
    return MealRecord(
      id: map['id'],
      date: DateTime.parse(map['date']),
      mealType: MealType.values[map['mealType']],
      imageUrls: map['imageUrls']?.split(','),
      description: map['description'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  MealRecord copyWith({
    int? id,
    DateTime? date,
    MealType? mealType,
    List<String>? imageUrls,
    String? description,
    DateTime? updatedAt,
  }) {
    return MealRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      imageUrls: imageUrls ?? this.imageUrls,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
