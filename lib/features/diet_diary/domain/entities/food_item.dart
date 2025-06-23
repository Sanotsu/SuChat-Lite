import '../../../../core/utils/simple_tools.dart';

class FoodItem {
  final int? id;
  final String name;
  final String? imageUrl;
  final String? foodCode; // 食品编码
  final double caloriesPer100g;
  final double carbsPer100g;
  final double proteinPer100g;
  final double fatPer100g;
  final double? fiberPer100g; // 膳食纤维
  final double? cholesterolPer100g; // 胆固醇
  final double? sodiumPer100g; // 钠
  final double? calciumPer100g; // 钙
  final double? ironPer100g; // 铁
  final double? vitaminAPer100g; // 维生素A
  final double? vitaminCPer100g; // 维生素C
  final double? vitaminEPer100g; // 维生素E
  final Map<String, dynamic> otherParams; // 额外属性
  final bool isFavorite;
  final DateTime gmtCreate;
  final DateTime gmtModified;

  FoodItem({
    this.id,
    required this.name,
    this.imageUrl,
    this.foodCode,
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
    Map<String, dynamic>? otherParams,
    this.isFavorite = false,
    DateTime? gmtCreate,
    DateTime? gmtModified,
  }) : otherParams = otherParams ?? {},
       gmtCreate = gmtCreate ?? DateTime.now(),
       gmtModified = gmtModified ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'foodCode': foodCode,
      'caloriesPer100g': caloriesPer100g,
      'carbsPer100g': carbsPer100g,
      'proteinPer100g': proteinPer100g,
      'fatPer100g': fatPer100g,
      'fiberPer100g': fiberPer100g,
      'cholesterolPer100g': cholesterolPer100g,
      'sodiumPer100g': sodiumPer100g,
      'calciumPer100g': calciumPer100g,
      'ironPer100g': ironPer100g,
      'vitaminAPer100g': vitaminAPer100g,
      'vitaminCPer100g': vitaminCPer100g,
      'vitaminEPer100g': vitaminEPer100g,
      'otherParams':
          otherParams.isNotEmpty ? _encodeOtherParams() : null,
      'isFavorite': isFavorite ? 1 : 0,
      'gmtCreate': gmtCreate.toIso8601String(),
      'gmtModified': gmtModified.toIso8601String(),
    };
  }

  // 将额外属性编码为JSON字符串
  String _encodeOtherParams() {
    return otherParams.isNotEmpty
        ? otherParams
            .map((key, value) => MapEntry(key, value.toString()))
            .toString()
        : '{}';
  }

  // 从JSON字符串解码额外属性
  static Map<String, dynamic> _decodeOtherParams(String? json) {
    if (json == null || json.isEmpty || json == '{}') {
      return {};
    }
    try {
      // 简单解析字符串形式的Map
      // 注意：这是一个简化的实现，实际应用中应使用json.decode
      final trimmed = json.trim().substring(1, json.length - 1);
      if (trimmed.isEmpty) return {};

      final pairs = trimmed.split(', ');
      final map = <String, dynamic>{};

      for (var pair in pairs) {
        final keyValue = pair.split(': ');
        if (keyValue.length == 2) {
          map[keyValue[0]] = keyValue[1];
        }
      }

      return map;
    } catch (e) {
      pl.e('解析额外属性失败: $e');
      return {};
    }
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'],
      name: map['name'],
      imageUrl: map['imageUrl'],
      foodCode: map['foodCode'] ?? identityHashCode(map['name']).toString(),
      caloriesPer100g: map['caloriesPer100g'] ?? 0.0,
      carbsPer100g: map['carbsPer100g'] ?? 0.0,
      proteinPer100g: map['proteinPer100g'] ?? 0.0,
      fatPer100g: map['fatPer100g'] ?? 0.0,
      fiberPer100g: map['fiberPer100g'],
      cholesterolPer100g: map['cholesterolPer100g'],
      sodiumPer100g: map['sodiumPer100g'],
      calciumPer100g: map['calciumPer100g'],
      ironPer100g: map['ironPer100g'],
      vitaminAPer100g: map['vitaminAPer100g'],
      vitaminCPer100g: map['vitaminCPer100g'],
      vitaminEPer100g: map['vitaminEPer100g'],
      otherParams:
          map['otherParams'] != null
              ? _decodeOtherParams(map['otherParams'])
              : {},
      isFavorite: map['isFavorite'] == 1,
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

  ///
  /// 这个是专用的导入方法
  /// 专门兼容老数据格式: https://github.com/Sanotsu/china-food-composition-data
  ///
  factory FoodItem.fromCFCDJsonData(Map<String, dynamic> json) {
    // 处理可能的不同字段名
    final otherParams = <String, dynamic>{};
    json.forEach((key, value) {
      if (![
        'foodCode',
        'foodName',
        'imageUrl',
        'energyKCal',
        'protein',
        'fat',
        'CHO',
        'dietaryFiber',
        'cholesterol',
        'Na',
        'Ca',
        'Fe',
        'vitaminA',
        'vitaminC',
        'vitaminETotal',
      ].contains(key)) {
        otherParams[key] = value;
      }
    });

    return FoodItem(
      name: json['foodName'] ?? '',
      imageUrl: json['imageUrl'],
      foodCode: json['foodCode'] ?? identityHashCode(json['name']).toString(),
      caloriesPer100g: _parseDouble(json['energyKCal']) ?? 0.0,
      proteinPer100g: _parseDouble(json['protein']) ?? 0.0,
      fatPer100g: _parseDouble(json['fat']) ?? 0.0,
      carbsPer100g: _parseDouble(json['CHO']) ?? 0.0,
      fiberPer100g: _parseDouble(json['dietaryFiber']),
      cholesterolPer100g: _parseDouble(json['cholesterol']),
      sodiumPer100g: _parseDouble(json['Na']),
      calciumPer100g: _parseDouble(json['Ca']),
      ironPer100g: _parseDouble(json['Fe']),
      vitaminAPer100g: _parseDouble(json['vitaminA']),
      vitaminCPer100g: _parseDouble(json['vitaminC']),
      vitaminEPer100g: _parseDouble(json['vitaminETotal']),
      otherParams: otherParams,
    );
  }

  // 解析字符串为double，处理可能的格式问题
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      if (value == 'Tr' || value.isEmpty) return 0.0;

      // 尝试从字符串中提取数字部分
      final numericString = _extractNumericPart(value);
      if (numericString != null) {
        try {
          return double.parse(numericString);
        } catch (e) {
          pl.e('无法解析为数字: $value (提取部分: $numericString)');
          return null;
        }
      }
      return null;
    }
    return null;
  }

  /// 从字符串中提取可能的数字部分
  static String? _extractNumericPart(String input) {
    // 可选的 +/- 号,后面跟着：
    //    一位或多位数字 + 可选的小数点和更多数字
    //    或者小数点 + 一位或多位数字
    final regex = RegExp(r'[-+]?(\d+\.?\d*|\.\d+)');
    final match = regex.firstMatch(input);
    if (match != null) {
      return match.group(0);
    }
    return null;
  }

  FoodItem copyWith({
    int? id,
    String? name,
    String? imageUrl,
    String? foodCode,
    double? caloriesPer100g,
    double? carbsPer100g,
    double? proteinPer100g,
    double? fatPer100g,
    double? fiberPer100g,
    double? cholesterolPer100g,
    double? sodiumPer100g,
    double? calciumPer100g,
    double? ironPer100g,
    double? vitaminAPer100g,
    double? vitaminCPer100g,
    double? vitaminEPer100g,
    Map<String, dynamic>? otherParams,
    bool? isFavorite,
    DateTime? gmtModified,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      foodCode: foodCode ?? this.foodCode,
      caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
      fiberPer100g: fiberPer100g ?? this.fiberPer100g,
      cholesterolPer100g: cholesterolPer100g ?? this.cholesterolPer100g,
      sodiumPer100g: sodiumPer100g ?? this.sodiumPer100g,
      calciumPer100g: calciumPer100g ?? this.calciumPer100g,
      ironPer100g: ironPer100g ?? this.ironPer100g,
      vitaminAPer100g: vitaminAPer100g ?? this.vitaminAPer100g,
      vitaminCPer100g: vitaminCPer100g ?? this.vitaminCPer100g,
      vitaminEPer100g: vitaminEPer100g ?? this.vitaminEPer100g,
      otherParams: otherParams ?? this.otherParams,
      isFavorite: isFavorite ?? this.isFavorite,
      gmtCreate: gmtCreate,
      gmtModified: gmtModified ?? DateTime.now(),
    );
  }
}
