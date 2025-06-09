import 'package:flutter/material.dart';

import '../features/branch_chat/presentation/index.dart';
import '../features/training_assistant/presentation/index.dart';

class AppRoutes {
  static const String home = '/';
  static const String trainingAssistant = '/training-assistant';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case trainingAssistant:
        return MaterialPageRoute(builder: (_) => const TrainingAssistantPage());
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
