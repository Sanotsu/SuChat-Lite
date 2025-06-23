class DietAnalysis {
  final int? id;
  final DateTime date;
  final String content;
  final String modelName;
  final DateTime gmtCreate;
  final DateTime gmtModified;

  DietAnalysis({
    this.id,
    required this.date,
    required this.content,
    required this.modelName,
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
      'gmtCreate': gmtCreate.toIso8601String(),
      'gmtModified': gmtModified.toIso8601String(),
    };
  }

  factory DietAnalysis.fromMap(Map<String, dynamic> map) {
    return DietAnalysis(
      id: map['id'],
      date: DateTime.parse(map['date']),
      content: map['content'],
      modelName: map['modelName'],
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

  DietAnalysis copyWith({
    int? id,
    DateTime? date,
    String? content,
    String? modelName,
    DateTime? gmtModified,
  }) {
    return DietAnalysis(
      id: id ?? this.id,
      date: date ?? this.date,
      content: content ?? this.content,
      modelName: modelName ?? this.modelName,
      gmtCreate: gmtCreate,
      gmtModified: gmtModified ?? DateTime.now(),
    );
  }
}
