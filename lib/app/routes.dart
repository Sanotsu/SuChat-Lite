import 'package:flutter/material.dart';

import 'home_page.dart';
import '../features/ai_tool_page.dart';
import '../features/training_assistant/presentation/index.dart';
import '../features/diet_diary/presentation/index.dart';
import '../features/diet_diary/presentation/pages/food_management_page.dart';
import '../features/diet_diary/presentation/pages/food_detail_page.dart';
import '../features/diet_diary/presentation/pages/food_edit_page.dart';
import '../features/diet_diary/presentation/pages/meal_detail_page.dart';
import '../features/diet_diary/domain/entities/food_item.dart';
import '../features/diet_diary/domain/entities/meal_record.dart';

class AppRoutes {
  static const String home = '/';
  static const String aiTool = '/ai-tool';
  static const String trainingAssistant = '/training-assistant';
  static const String dietDiary = '/diet-diary';
  static const String foodManagement = '/food-management';
  static const String foodDetail = '/food-detail';
  static const String foodEdit = '/food-edit';
  static const String mealDetail = '/meal-detail';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case aiTool:
        return MaterialPageRoute(builder: (_) => const AIToolPage());
      case trainingAssistant:
        return MaterialPageRoute(builder: (_) => const TrainingAssistantPage());
      case dietDiary:
        return MaterialPageRoute(builder: (_) => const DietDiaryPage());
      case foodManagement:
        return MaterialPageRoute(builder: (_) => const FoodManagementPage());
      case foodDetail:
        final FoodItem foodItem = settings.arguments as FoodItem;
        return MaterialPageRoute(
          builder: (_) => FoodDetailPage(foodItem: foodItem, isEditable: true),
        );
      case foodEdit:
        final Map<String, dynamic> args =
            settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder:
              (_) => FoodEditPage(
                foodItem: args['foodItem'],
                initialName: args['initialName'],
                onSave: args['onSave'],
              ),
        );
      case mealDetail:
        final MealRecord mealRecord = settings.arguments as MealRecord;
        return MaterialPageRoute(
          builder: (_) => MealDetailPage(mealRecord: mealRecord),
        );
      default:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(child: Text('没有找到路由: ${settings.name}')),
              ),
        );
    }
  }
}
