class WeightRecord {
  final int? id;
  final int userId;
  final double weight;
  final DateTime date;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  WeightRecord({
    this.id,
    required this.userId,
    required this.weight,
    required this.date,
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'weight': weight,
      'date': date.toIso8601String(),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory WeightRecord.fromMap(Map<String, dynamic> map) {
    return WeightRecord(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      weight: map['weight'] as double,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  WeightRecord copyWith({
    int? id,
    int? userId,
    double? weight,
    DateTime? date,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WeightRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weight: weight ?? this.weight,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WeightRecord &&
        other.id == id &&
        other.userId == userId &&
        other.weight == weight &&
        other.date == date &&
        other.note == note &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        weight.hashCode ^
        date.hashCode ^
        note.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
