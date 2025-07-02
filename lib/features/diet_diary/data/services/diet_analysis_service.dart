import 'dart:async';
import 'dart:ui';

import '../../../../core/dao/user_info_dao.dart';
import '../../../../core/entities/cus_llm_model.dart';
import '../../../../core/entities/user_info.dart';
import '../../../../shared/constants/constant_llm_enum.dart';
import '../../../branch_chat/data/datasources/openai_compatible_apis.dart';
import '../../../branch_chat/data/services/chat_service.dart';
import '../../domain/entities/meal_food_detail.dart';
import '../../domain/entities/meal_type.dart';

class DietAnalysisService {
  /// 分析用户一日饮食数据
  ///
  /// 参数:
  /// - model: 使用的大模型
  /// - userInfo: 用户信息
  /// - mealFoodDetails: 一日四餐的食品详情
  /// - dailyNutrition: 一日营养摄入总量
  /// - dailyRecommended: 推荐的每日营养摄入量
  Future<(Stream<String>, VoidCallback)> analyzeDailyDiet({
    required CusLLMSpec model,
    required UserInfo userInfo,
    required Map<int, List<MealFoodDetail>> mealFoodDetails,
    MacrosIntake? dailyNutrition,
    MacrosIntake? dailyRecommended,
    required List<int> mealRecordIds,
    required Map<int, MealType> mealTypes,
    String? customPrompt,
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
    String prompt;
    // 如果用户有自定义提示词，则使用自定义提示词
    if (customPrompt != null && customPrompt.trim().isNotEmpty) {
      prompt = customPrompt;
    } else {
      prompt = buildDietAnalysisPrompt(
        userInfo: userInfo,
        mealFoodDetails: mealFoodDetails,
        dailyNutrition: dailyNutrition,
        dailyRecommended: dailyRecommended,
        mealRecordIds: mealRecordIds,
        mealTypes: mealTypes,
      );
    }

    // 基础请求体
    final Map<String, dynamic> requestBody = {
      'model': model.model,
      'messages': [
        {'role': 'system', 'content': '你是一位专业的营养师和健康顾问，负责分析用户的一日饮食情况并提供专业的建议。'},
        {'role': 'user', 'content': prompt},
      ],
      "stream": true,
      // 'temperature': 0.7,
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
  String buildDietAnalysisPrompt({
    required UserInfo userInfo,
    required Map<int, List<MealFoodDetail>> mealFoodDetails,
    MacrosIntake? dailyNutrition,
    MacrosIntake? dailyRecommended,
    required List<int> mealRecordIds,
    required Map<int, MealType> mealTypes,
  }) {
    // 系统提示词
    final systemPrompt = """
你是一位专业的营养师和健康顾问，负责分析用户的一日饮食情况并提供专业的建议。
请根据用户提供的个人信息、饮食记录和营养摄入数据，进行全面的分析并给出改进建议。

在分析中，请考虑以下几个方面：
1. 总热量摄入是否符合用户的目标（减脂/维持体重/增肌/保持健康）
2. 三大营养素（碳水化合物、蛋白质、脂肪）的比例是否合理
3. 餐次安排是否合理，食物多样性如何
4. 针对用户的具体目标，提供个性化的改进建议
5. 如有明显的营养不足或过量，请指出并提供调整建议

请以专业、友好的语气进行分析，避免使用过于专业的术语，确保用户能够理解你的建议。
分析应当客观、实用，并考虑到用户的实际情况和目标。
""";

    // 用户信息部分
    final userBaseInfo = """
## 用户信息
- 性别: ${userInfo.gender == Gender.male ? '男' : '女'}
- 年龄: ${userInfo.age}岁
- 身高: ${userInfo.height}厘米
- 体重: ${userInfo.weight}公斤
- BMI: ${userInfo.bmi.toStringAsFixed(1)}
- 基础代谢率(BMR): ${userInfo.bmr.toInt()}千卡
- 活动水平: ${getActivityLevelText(userInfo.activityLevel ?? 1.2)}
- 每日总能量消耗(TDEE): ${userInfo.tdee.toInt()}千卡
- 健康目标: ${getGoalText(userInfo.goal ?? Goal.maintainWeight)}
""";

    // 营养摄入总结
    final nutritionSummary =
        dailyNutrition != null && dailyRecommended != null
            ? """
## 营养摄入总结
- 总热量: ${dailyNutrition.calories.toInt()}千卡 / ${dailyRecommended.calories.toInt()}千卡 (推荐)
- 碳水化合物: ${dailyNutrition.carbs.toInt()}克 / ${dailyRecommended.carbs.toInt()}克 (推荐)
- 蛋白质: ${dailyNutrition.protein.toInt()}克 / ${dailyRecommended.protein.toInt()}克 (推荐)
- 脂肪: ${dailyNutrition.fat.toInt()}克 / ${dailyRecommended.fat.toInt()}克 (推荐)
"""
            : '';

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
4. 针对我的健康目标（${getGoalText(userInfo.goal ?? Goal.maintainWeight)}），有哪些具体的改进建议
5. 如果有明显的营养不足或过量，请指出并提供调整建议

请给出详细、专业且易于理解的分析和建议，谢谢！
""";

    return "$systemPrompt\n\n$userBaseInfo\n\n$nutritionSummary\n\n$mealsDetail\n\n$userRequest";
  }
}
