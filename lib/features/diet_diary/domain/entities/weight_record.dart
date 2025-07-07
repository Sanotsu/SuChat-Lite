class WeightRecord {
  final int? id;
  final String userId;
  final double weight;
  final DateTime date;
  final String? note;
  final DateTime gmtCreate;
  final DateTime gmtModified;

  WeightRecord({
    this.id,
    required this.userId,
    required this.weight,
    required this.date,
    this.note,
    DateTime? gmtCreate,
    DateTime? gmtModified,
  }) : gmtCreate = gmtCreate ?? DateTime.now(),
       gmtModified = gmtModified ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'weight': weight,
      'date': date.toIso8601String(),
      'note': note,
      'gmtCreate': gmtCreate.toIso8601String(),
      'gmtModified': gmtModified.toIso8601String(),
    };
  }

  factory WeightRecord.fromMap(Map<String, dynamic> map) {
    return WeightRecord(
      id: map['id'] as int?,
      userId: map['userId'] as String,
      weight: map['weight'] as double,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      gmtCreate:
          map['gmtCreate'] != null ? DateTime.parse(map['gmtCreate']) : null,
      gmtModified:
          map['gmtModified'] != null
              ? DateTime.parse(map['gmtModified'])
              : null,
    );
  }

  WeightRecord copyWith({
    int? id,
    String? userId,
    double? weight,
    DateTime? date,
    String? note,
    DateTime? gmtCreate,
    DateTime? gmtModified,
  }) {
    return WeightRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weight: weight ?? this.weight,
      date: date ?? this.date,
      note: note ?? this.note,
      gmtCreate: gmtCreate ?? this.gmtCreate,
      gmtModified: gmtModified ?? this.gmtModified,
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
        other.gmtCreate == gmtCreate &&
        other.gmtModified == gmtModified;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        weight.hashCode ^
        date.hashCode ^
        note.hashCode ^
        gmtCreate.hashCode ^
        gmtModified.hashCode;
  }
}
