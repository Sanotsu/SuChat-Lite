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
import '../features/simple_accounting/presentation/pages/bill_list_page.dart';
import '../features/simple_accounting/presentation/pages/bill_add_page.dart';
import '../features/simple_accounting/presentation/pages/bill_detail_page.dart';
import '../features/simple_accounting/presentation/pages/bill_statistics_page.dart';

class AppRoutes {
  static const String home = '/';
  static const String aiTool = '/ai-tool';
  static const String trainingAssistant = '/training-assistant';
  static const String dietDiary = '/diet-diary';
  static const String foodManagement = '/food-management';
  static const String foodDetail = '/food-detail';
  static const String foodEdit = '/food-edit';
  static const String mealDetail = '/meal-detail';

  // 简易记账路由
  static const String billList = '/bill-list';
  static const String billAdd = '/bill-add';
  static const String billDetail = '/bill-detail';
  static const String billStatistics = '/bill-statistics';

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
          builder: (_) => FoodEditPage(
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

      // 简易记账路由
      case billList:
        return MaterialPageRoute(builder: (_) => const BillListPage());
      case billAdd:
        final Map<String, dynamic>? args =
            settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => BillAddPage(editItem: args?['editItem']),
        );
      case billDetail:
        final int billItemId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => BillDetailPage(billItemId: billItemId),
        );
      case billStatistics:
        return MaterialPageRoute(builder: (_) => const BillStatisticsPage());

      default:
        return MaterialPageRoute(
          builder: (_) =>
              Scaffold(body: Center(child: Text('没有找到路由: ${settings.name}'))),
        );
    }
  }
}
