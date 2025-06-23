class DietRecipe {
  final int? id;
  final DateTime date;
  final String content;
  final String modelName;
  final int days;
  final int mealsPerDay;
  final String? dietaryPreference;
  final int? analysisId;
  final DateTime gmtCreate;
  final DateTime gmtModified;

  DietRecipe({
    this.id,
    required this.date,
    required this.content,
    required this.modelName,
    required this.days,
    required this.mealsPerDay,
    this.dietaryPreference,
    this.analysisId,
    DateTime? gmtCreate,
    DateTime? gmtModified,
  }) : gmtCreate = gmtCreate ?? DateTime.now(),
       gmtModified = gmtModified ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T')[0], // 只保留日期部分
      'content': content,
      'modelName': modelName,
      'days': days,
      'mealsPerDay': mealsPerDay,
      'dietaryPreference': dietaryPreference,
      'analysisId': analysisId,
      'gmtCreate': gmtCreate.toIso8601String(),
      'gmtModified': gmtModified.toIso8601String(),
    };
  }

  factory DietRecipe.fromMap(Map<String, dynamic> map) {
    return DietRecipe(
      id: map['id'],
      date: DateTime.parse(map['date']),
      content: map['content'],
      modelName: map['modelName'],
      days: map['days'],
      mealsPerDay: map['mealsPerDay'],
      dietaryPreference: map['dietaryPreference'],
      analysisId: map['analysisId'],
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

  DietRecipe copyWith({
    int? id,
    DateTime? date,
    String? content,
    String? modelName,
    int? days,
    int? mealsPerDay,
    String? dietaryPreference,
    int? analysisId,
    DateTime? gmtCreate,
    DateTime? gmtModified,
  }) {
    return DietRecipe(
      id: id ?? this.id,
      date: date ?? this.date,
      content: content ?? this.content,
      modelName: modelName ?? this.modelName,
      days: days ?? this.days,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      dietaryPreference: dietaryPreference ?? this.dietaryPreference,
      analysisId: analysisId ?? this.analysisId,
      gmtCreate: gmtCreate ?? this.gmtCreate,
      gmtModified: gmtModified ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return '''DietRecipe{
      id: $id, date: $date, modelName: $modelName, days: $days, mealsPerDay: 
      $mealsPerDay, dietaryPreference: $dietaryPreference, analysisId: $analysisId
    }''';
  }
}
