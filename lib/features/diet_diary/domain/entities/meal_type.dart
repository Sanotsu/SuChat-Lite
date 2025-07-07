enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeExtension on MealType {
  String get displayName {
    switch (this) {
      case MealType.breakfast:
        return '早餐';
      case MealType.lunch:
        return '午餐';
      case MealType.dinner:
        return '晚餐';
      case MealType.snack:
        return '加餐';
    }
  }

  String get iconPath {
    switch (this) {
      case MealType.breakfast:
        return 'assets/icons/breakfast.png';
      case MealType.lunch:
        return 'assets/icons/lunch.png';
      case MealType.dinner:
        return 'assets/icons/dinner.png';
      case MealType.snack:
        return 'assets/icons/snack.png';
    }
  }
}
