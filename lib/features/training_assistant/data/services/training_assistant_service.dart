import 'dart:convert';

import '../../../../core/entities/cus_llm_model.dart';
import '../../../../core/network/dio_client/cus_http_client.dart';
import '../../../../core/network/dio_client/cus_http_request.dart';
import '../../../../shared/constants/constant_llm_enum.dart';
import '../../../../shared/constants/constants.dart';
import '../../../branch_chat/data/repositories/chat_service.dart';
import '../../domain/entities/training_plan.dart';
import '../../domain/entities/training_plan_detail.dart';

class TrainingAssistantService {
  /// 根据用户信息生成训练计划
  Future<Map<String, dynamic>> generateTrainingPlan({
    required String userId,
    required String gender,
    required double height,
    required double weight,
    int? age,
    required String fitnessLevel,
    String? healthConditions,
    required String targetGoal,
    required List<String> targetMuscleGroups,
    required int duration,
    required String frequency,
    String? equipment,
    required CusLLMSpec model,
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
    final prompt = buildTrainingPlanPrompt(
      gender: gender,
      height: height,
      weight: weight,
      age: age,
      fitnessLevel: fitnessLevel,
      healthConditions: healthConditions,
      targetGoal: targetGoal,
      targetMuscleGroups: targetMuscleGroups,
      duration: duration,
      frequency: frequency,
      equipment: equipment,
    );

    // 基础请求体
    final Map<String, dynamic> requestBody = {
      'model': model.model,
      'messages': [
        {'role': 'system', 'content': '你是一位专业的健身教练。'},
        {'role': 'user', 'content': prompt},
      ],
      // 'temperature': 0.7,
    };

    // // ??? 注意，这里是非流式响应，很多模型无法正常配置和处理
    // if (model.model.toLowerCase().contains("qwen3")) {
    //   // requestBody['stream'] = false;
    //   // requestBody['enable_thinking '] = false;
    //   requestBody['parameters'] = {"enable_thinking": false};
    //   requestBody['response_format '] = {'type': 'json_object'};
    // }

    final response = await HttpUtils.post(
      path: baseUrl,
      headers: headers,
      data: requestBody,
      responseType: CusRespType.json,
      showLoading: false,
      showErrorMessage: false,
    );

    // 解析响应
    var content = response['choices'][0]['message']['content'];
    if (content is! String) {
      content = content.toString();
    }

    // 解析响应
    return _parseTrainingPlanResponse(
      content.trim(),
      userId,
      targetGoal,
      targetMuscleGroups.join(', '),
      duration,
      frequency,
      equipment,
    );
  }

  /// 使用自定义提示词生成训练计划
  Future<Map<String, dynamic>> generateTrainingPlanWithCustomPrompt({
    required String userId,
    required String targetGoal,
    required String targetMuscleGroups,
    required int duration,
    required String frequency,
    String? equipment,
    required String customPrompt,
    required CusLLMSpec model,
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

    // 基础请求体
    final Map<String, dynamic> requestBody = {
      'model': model.model,
      'messages': [
        {'role': 'system', 'content': '你是一位专业的健身教练。'},
        {'role': 'user', 'content': customPrompt},
      ],
    };

    final response = await HttpUtils.post(
      path: baseUrl,
      headers: headers,
      data: requestBody,
      responseType: CusRespType.json,
      showLoading: false,
      showErrorMessage: false,
    );

    // 解析响应
    var content = response['choices'][0]['message']['content'];
    if (content is! String) {
      content = content.toString();
    }

    // 解析响应
    return _parseTrainingPlanResponse(
      content.trim(),
      userId,
      targetGoal,
      targetMuscleGroups,
      duration,
      frequency,
      equipment,
    );
  }

  /// 构建训练计划提示词
  ///
  /// [gender] 用户性别（男/女）
  /// [height] 用户身高（厘米）
  /// [weight] 用户体重（公斤）
  /// [age] 用户年龄（可选）
  /// [fitnessLevel] 健身水平（初级/中级/高级）
  /// [healthConditions] 健康状况或限制（可选）
  /// [targetGoal] 训练目标（增肌/减脂/耐力等）
  /// [targetMuscleGroups] 目标肌群列表
  /// [duration] 每次训练时长（分钟）
  /// [frequency] 训练频率（如"每周3次"）
  /// [equipment] 可用设备（可选）
  ///
  /// 返回: 结构化的提示词字符串，用于生成JSON格式的训练计划
  String buildTrainingPlanPrompt({
    required String gender,
    required double height,
    required double weight,
    int? age,
    required String fitnessLevel,
    String? healthConditions,
    required String targetGoal,
    required List<String> targetMuscleGroups,
    required int duration,
    required String frequency,
    String? equipment,
  }) {
    final buffer = StringBuffer();

    // 构建提示词头部
    buffer.writeln('''
你是一位专业的健身教练，请根据以下用户信息制定一个科学、安全且个性化的训练计划。

要求:
1. 计划需符合用户的身体状况和健身水平
2. 动作选择需针对目标肌群
3. 训练强度需与用户目标匹配
4. 考虑训练时长限制
5. 如有健康限制，务必规避风险动作

用户档案:
- 基本指标:
  • 性别: $gender
  • 身高: ${height.toStringAsFixed(1)} cm
  • 体重: ${weight.toStringAsFixed(1)} kg ${age != null ? '\n  • 年龄: $age 岁' : ''}
- 健身水平: $fitnessLevel ${healthConditions != null && healthConditions.isNotEmpty ? '\n- 健康注意事项: $healthConditions' : ''}

训练需求:
- 主要目标: $targetGoal
- 重点肌群: ${targetMuscleGroups.join('、')}
- 单次时长: $duration 分钟
- 训练频率: $frequency ${equipment != null && equipment.isNotEmpty ? '\n- 可用器械: $equipment' : ''}
''');

    // 构建输出要求
    buffer.writeln('''
输出要求:
1. 提供完整的训练计划，包含以下字段:
   - planName: 计划名称(体现目标和特点)
   - description: 简短描述(50-100字)
   - difficulty: 难度级别(初级/中级/高级)
   - durationWeeks: 建议计划周期(4-12周)
   - schedule: 训练日程安排

2. 每个训练日包含:
   - day: 星期几(1=周一至7=周日)
   - focus: 当日训练重点
   - totalDuration: 预计总时长(分钟)
   - exercises: 训练动作列表

3. 每个训练动作包含:
   - name: 动作名称(中英文)
   - muscleGroup: 目标肌群
   - sets: 组数
   - reps: 次数(根据目标调整)
   - countdown: 预计完成时间(秒)
   - restTime: 组间休息(秒)
   - instructions: 动作说明(50字左右) ${equipment != null ? '\n   - equipmentRequired: 所需器械' : ''}

输出内容必须只有JSON数据。示例结构:
```json
{
  "planName": "上肢增肌4周计划",
  "description": "针对胸肩背的增肌训练...",
  "difficulty": "中级",
  "durationWeeks": 4,
  "schedule": [
    {
      "day": 1,
      "focus": "胸部+三头肌",
      "totalDuration": 30,
      "exercises": [
        {
          "name": "平板卧推(Bench Press)",
          "muscleGroup": "胸大肌",
          "sets": 4,
          "reps": "8-10",
          "countdown": 40,
          "restTime": 60,
          "instructions": [
            "仰卧平板凳，双脚踩实，握杠略宽于肩。",
            "下放至胸，肘部微收；胸部发力推起，不锁肘。",
            "保持肩胛稳定，控制呼吸。"
          ],
          "equipmentRequired": "杠铃"
        }
      ]
    }
  ]
}
```

注意事项:
1. 确保JSON格式完全正确
2. 不要包含任何非JSON内容
3. 组数、次数和休息时间需科学合理
4. 根据用户健身水平调整动作难度
5. 如有健康限制，务必规避风险动作
''');

    return buffer.toString();
  }

  /// 解析训练计划响应
  ///
  /// 注意，这里的解析比较简单，可能有些不那么智能的大模型无法正确返回json，导致解析也不对
  Map<String, dynamic> _parseTrainingPlanResponse(
    String response,
    String userId,
    String targetGoal,
    String targetMuscleGroups,
    int duration,
    String frequency,
    String? equipment,
  ) {
    try {
      // 尝试解析JSON响应
      // 直接取第一个 "{" 和最后一个 "}" 之间的内容解析，避免被 ```json { xxx }```包裹的无法解析
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      final jsonStr = response.substring(jsonStart, jsonEnd);

      final Map<String, dynamic> planData = json.decode(jsonStr);

      // 创建训练计划
      final plan = TrainingPlan(
        userId: userId,
        planName: planData['planName'] ?? '未命名训练计划',
        targetGoal: targetGoal,
        targetMuscleGroups: targetMuscleGroups,
        duration: duration,
        frequency: frequency,
        difficulty: planData['difficulty'] ?? '中级',
        description: planData['description'],
        isActive: true,
        equipment: equipment,
      );

      // 解析用户选择的训练日
      final List<int> selectedDays = _parseFrequencyToDays(frequency);

      // 创建训练计划详情
      final List<TrainingPlanDetail> details = [];

      if (planData['schedule'] != null) {
        // 将schedule中的day映射到用户选择的训练日
        final List<dynamic> schedule = planData['schedule'];

        // 确保schedule的长度不超过selectedDays的长度
        final int scheduleLength = schedule.length;
        final int selectedDaysLength = selectedDays.length;

        if (scheduleLength > 0) {
          for (int i = 0; i < scheduleLength; i++) {
            // 获取当前schedule项
            final daySchedule = schedule[i];

            // 确定对应的训练日
            final int mappedDay =
                i < selectedDaysLength
                    ? selectedDays[i] // 使用用户选择的训练日
                    : (i % 7) + 1; // 如果超出选择的训练日数量，则循环使用1-7

            if (daySchedule['exercises'] != null) {
              for (var exercise in daySchedule['exercises']) {
                details.add(
                  TrainingPlanDetail(
                    planId: plan.planId,
                    day: mappedDay,
                    exerciseName: exercise['name'] ?? '未命名动作',
                    muscleGroup: exercise['muscleGroup'] ?? '未指定肌群',
                    sets: exercise['sets'] ?? 3,
                    reps: exercise['reps'] ?? '8-12',
                    countdown: exercise['countdown'] ?? 60,
                    restTime: exercise['restTime'] ?? 30,
                    instructions:
                        exercise['instructions'] is List
                            ? (exercise['instructions'] as List)
                                .map((e) => e.toString())
                                .join('\n\n')
                            : exercise['instructions']?.toString() ?? '',
                  ),
                );
              }
            }
          }
        }
      }

      return {'plan': plan, 'details': details};
    } catch (e) {
      throw Exception('无法解析大模型响应的内容:\n\n $e \n\n请选择合适的大模型重新生成训练计划');
    }
  }

  /// 解析训练频率字符串为对应的星期几（1-7表示周一到周日）
  List<int> _parseFrequencyToDays(String frequency) {
    final List<int> days = [];

    // 分割频率字符串（注意和PlanGeneratorForm的_generatePlan()分隔符一致）
    final List<String> parts = frequency.split('、');

    // 将每个部分映射到对应的数字
    for (String part in parts) {
      final int? day = weekDayMapping[part.trim()];
      if (day != null) {
        days.add(day);
      }
    }

    // 如果没有解析出有效的天数，默认返回[1, 3, 5]（周一、周三、周五）
    if (days.isEmpty) {
      return [1, 3, 5];
    }

    // 按照星期几的顺序排序
    days.sort();

    return days;
  }
}
