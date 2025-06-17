import 'dart:async';
import 'dart:ui';

import '../../../../core/entities/cus_llm_model.dart';
import '../../../../shared/constants/constant_llm_enum.dart';
import '../../../branch_chat/data/datasources/openai_compatible_apis.dart';
import '../../../branch_chat/data/repositories/chat_service.dart';
import '../../domain/entities/meal_food_detail.dart';
import '../../domain/entities/meal_type.dart';
import '../../domain/entities/user_profile.dart';

class DietAnalysisService {
  /// 分析用户一日饮食数据
  ///
  /// 参数:
  /// - model: 使用的大模型
  /// - userProfile: 用户信息
  /// - mealFoodDetails: 一日四餐的食品详情
  /// - dailyNutrition: 一日营养摄入总量
  /// - dailyRecommended: 推荐的每日营养摄入量
  Future<(Stream<String>, VoidCallback)> analyzeDailyDiet({
    required CusLLMSpec model,
    required UserProfile userProfile,
    required Map<int, List<MealFoodDetail>> mealFoodDetails,
    required Map<String, double> dailyNutrition,
    required Map<String, double> dailyRecommended,
    required List<int> mealRecordIds,
    required Map<int, MealType> mealTypes,
  }) async {
    // 如果是自定义平台模型，url、apikey等直接在模型规格中
    Map<String, String> headers;
    String baseUrl;
    if (model.platform == ApiPlatform.custom) {
      headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${model.apiKey}',
      };
      baseUrl = "${model.baseUrl}/chat/completions";
    } else {
      headers = await ChatService.getHeaders(model);
      baseUrl = "${ChatService.getBaseUrl(model.platform)}/chat/completions";
    }

    // 构建提示词
    final messages = _buildPromptMessages(
      userProfile: userProfile,
      mealFoodDetails: mealFoodDetails,
      dailyNutrition: dailyNutrition,
      dailyRecommended: dailyRecommended,
      mealRecordIds: mealRecordIds,
      mealTypes: mealTypes,
    );

    final requestBody = {
      "model": model.model,
      "messages": messages,
      "stream": true,
    };

    // 调用大模型API
    final (stream, cancel) = await getStreamOnlyStringResponse(
      baseUrl,
      headers,
      requestBody,
    );

    return (stream, cancel);
  }

  /// 构建提示词消息
  List<Map<String, dynamic>> _buildPromptMessages({
    required UserProfile userProfile,
    required Map<int, List<MealFoodDetail>> mealFoodDetails,
    required Map<String, double> dailyNutrition,
    required Map<String, double> dailyRecommended,
    required List<int> mealRecordIds,
    required Map<int, MealType> mealTypes,
  }) {
    // 系统提示词
    final systemPrompt = """
你是一位专业的营养师和健康顾问，负责分析用户的一日饮食情况并提供专业的建议。
请根据用户提供的个人信息、饮食记录和营养摄入数据，进行全面的分析并给出改进建议。

在分析中，请考虑以下几个方面：
1. 总热量摄入是否符合用户的目标（减脂/维持/增肌）
2. 三大营养素（碳水化合物、蛋白质、脂肪）的比例是否合理
3. 餐次安排是否合理，食物多样性如何
4. 针对用户的具体目标，提供个性化的改进建议
5. 如有明显的营养不足或过量，请指出并提供调整建议

请以专业、友好的语气进行分析，避免使用过于专业的术语，确保用户能够理解你的建议。
分析应当客观、实用，并考虑到用户的实际情况和目标。
""";

    // 用户信息部分
    final userInfo = """
## 用户信息
- 性别: ${userProfile.gender == Gender.male ? '男' : '女'}
- 年龄: ${userProfile.age}岁
- 身高: ${userProfile.height}厘米
- 体重: ${userProfile.weight}公斤
- BMI: ${userProfile.bmi.toStringAsFixed(1)}
- 基础代谢率(BMR): ${userProfile.bmr.toInt()}千卡
- 活动水平: ${getActivityLevelText(userProfile.activityLevel)}
- 每日总能量消耗(TDEE): ${userProfile.tdee.toInt()}千卡
- 健康目标: ${getGoalText(userProfile.goal)}
""";

    // 营养摄入总结
    final nutritionSummary = """
## 营养摄入总结
- 总热量: ${dailyNutrition['calories']?.toInt() ?? 0}千卡 / ${dailyRecommended['calories']?.toInt() ?? 0}千卡 (推荐)
- 碳水化合物: ${dailyNutrition['carbs']?.toInt() ?? 0}克 / ${dailyRecommended['carbs']?.toInt() ?? 0}克 (推荐)
- 蛋白质: ${dailyNutrition['protein']?.toInt() ?? 0}克 / ${dailyRecommended['protein']?.toInt() ?? 0}克 (推荐)
- 脂肪: ${dailyNutrition['fat']?.toInt() ?? 0}克 / ${dailyRecommended['fat']?.toInt() ?? 0}克 (推荐)
""";

    // 一日四餐详情
    final mealsDetail = StringBuffer();
    mealsDetail.writeln("## 一日四餐详情");

    for (final mealId in mealRecordIds) {
      final mealType = mealTypes[mealId];
      final foods = mealFoodDetails[mealId] ?? [];

      String mealTypeName;
      switch (mealType) {
        case MealType.breakfast:
          mealTypeName = "早餐";
          break;
        case MealType.lunch:
          mealTypeName = "午餐";
          break;
        case MealType.dinner:
          mealTypeName = "晚餐";
          break;
        case MealType.snack:
          mealTypeName = "零食";
          break;
        default:
          mealTypeName = "其他";
      }

      mealsDetail.writeln("### $mealTypeName");

      if (foods.isEmpty) {
        mealsDetail.writeln("- 未记录食品");
      } else {
        for (final food in foods) {
          mealsDetail.writeln(
            "- ${food.foodName}: ${food.quantity}${food.unit ?? '克'} (${food.calories.toInt()}千卡)",
          );
        }
      }

      mealsDetail.writeln();
    }

    // 用户请求
    final userRequest = """
请根据以上信息，分析我的一日饮食情况，并给出专业的建议。
请从以下几个方面进行分析：
1. 总体评价：我的饮食结构是否合理，热量摄入是否符合我的目标
2. 三大营养素分析：碳水化合物、蛋白质、脂肪的摄入比例是否合理
3. 餐次安排分析：我的一日四餐安排是否合理，有无需要调整的地方
4. 针对我的健康目标（${getGoalText(userProfile.goal)}），有哪些具体的改进建议
5. 如果有明显的营养不足或过量，请指出并提供调整建议

请给出详细、专业且易于理解的分析和建议，谢谢！
""";

    return [
      {"role": "system", "content": systemPrompt},
      {
        "role": "user",
        "content":
            "$userInfo\n\n$nutritionSummary\n\n$mealsDetail\n\n$userRequest",
      },
    ];
  }
}
