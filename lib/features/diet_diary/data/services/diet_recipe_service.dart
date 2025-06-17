import 'dart:async';
import 'dart:ui';

import '../../../../core/entities/cus_llm_model.dart';
import '../../../../shared/constants/constant_llm_enum.dart';
import '../../../branch_chat/data/datasources/openai_compatible_apis.dart';
import '../../../branch_chat/data/repositories/chat_service.dart';
import '../../domain/entities/user_profile.dart';

class DietRecipeService {
  /// 生成个性化食谱
  ///
  /// 参数:
  /// - model: 使用的大模型
  /// - userProfile: 用户信息
  /// - dailyNutrition: 一日营养摄入总量
  /// - dailyRecommended: 推荐的每日营养摄入量
  /// - preferences: 用户的饮食偏好（如喜欢/不喜欢的食物、饮食禁忌等）
  /// - mealCount: 需要生成的餐次数量（1-4）
  /// - days: 需要生成的天数（1-7）
  Future<(Stream<String>, VoidCallback)> generatePersonalizedRecipe({
    required CusLLMSpec model,
    required UserProfile userProfile,
    required Map<String, double> dailyNutrition,
    required Map<String, double> dailyRecommended,
    required String preferences,
    required int mealCount,
    required int days,
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
      dailyNutrition: dailyNutrition,
      dailyRecommended: dailyRecommended,
      preferences: preferences,
      mealCount: mealCount,
      days: days,
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
    required Map<String, double> dailyNutrition,
    required Map<String, double> dailyRecommended,
    required String preferences,
    required int mealCount,
    required int days,
  }) {
    // 系统提示词
    final systemPrompt = """
你是一位专业的营养师和健康饮食顾问，负责根据用户的个人信息、健康目标和饮食偏好，设计个性化的健康食谱。
请根据用户提供的信息，制定符合其营养需求和健康目标的详细食谱计划。

在设计食谱时，请考虑以下几个方面：
1. 总热量摄入应符合用户的目标（减脂/维持/增肌）
2. 三大营养素（碳水化合物、蛋白质、脂肪）的比例应合理
3. 食物多样性，确保提供全面的营养
4. 考虑用户的饮食偏好和禁忌
5. 食谱应当实用、易于准备，并尽可能使用常见食材

请为每一餐提供以下信息：
- 餐次名称（早餐/午餐/晚餐/加餐）
- 菜品名称
- 主要食材及用量
- 大致的制作方法
- 每餐的营养成分估算（热量、碳水、蛋白质、脂肪）

请以专业、友好的语气提供食谱，确保用户能够理解并轻松跟随。
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

    // 营养需求部分
    final nutritionNeeds = """
## 营养需求
- 推荐热量摄入: ${dailyRecommended['calories']?.toInt() ?? 0}千卡/天
- 推荐碳水化合物: ${dailyRecommended['carbs']?.toInt() ?? 0}克/天
- 推荐蛋白质: ${dailyRecommended['protein']?.toInt() ?? 0}克/天
- 推荐脂肪: ${dailyRecommended['fat']?.toInt() ?? 0}克/天

## 当前平均摄入
- 热量: ${dailyNutrition['calories']?.toInt() ?? 0}千卡/天
- 碳水化合物: ${dailyNutrition['carbs']?.toInt() ?? 0}克/天
- 蛋白质: ${dailyNutrition['protein']?.toInt() ?? 0}克/天
- 脂肪: ${dailyNutrition['fat']?.toInt() ?? 0}克/天
""";

    // 用户饮食偏好
    final userPreferences = """
## 饮食偏好和禁忌
$preferences
""";

    // 用户请求
    final userRequest = """
请根据以上信息，为我设计一份个性化的$days天食谱计划，每天包含$mealCount餐。
我希望这份食谱能够帮助我达成${getGoalText(userProfile.goal)}的目标，同时符合我的饮食偏好。
请确保食谱实用、易于准备，并提供详细的食材用量和简单的制作方法。
每餐请标注大致的营养成分（热量、碳水、蛋白质、脂肪）。
""";

    return [
      {"role": "system", "content": systemPrompt},
      {
        "role": "user",
        "content":
            "$userInfo\n\n$nutritionNeeds\n\n$userPreferences\n\n$userRequest",
      },
    ];
  }
}
