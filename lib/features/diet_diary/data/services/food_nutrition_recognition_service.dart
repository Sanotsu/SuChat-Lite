import 'dart:convert';
import 'dart:io';

import '../../../../core/entities/cus_llm_model.dart';
import '../../../../core/network/dio_client/cus_http_client.dart';
import '../../../../core/network/dio_client/cus_http_request.dart';
import '../../../../shared/constants/constant_llm_enum.dart';
import '../../../branch_chat/data/repositories/chat_service.dart';
import '../../domain/entities/food_item.dart';

class FoodNutritionRecognitionService {
  /// 识别食品营养成分表图片
  Future<FoodItem?> recognizeNutritionLabel({
    required File imageFile,
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

    // 将图片转换为base64编码
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    // 构建提示词
    // 这个是专门兼容老数据格式: https://github.com/Sanotsu/china-food-composition-data
    // 和数据库表栏位不一样，导入时需要指定转换
    final prompt = buildNutritionLabelPrompt();

    // 基础请求体
    final Map<String, dynamic> requestBody = {
      'model': model.model,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              "type": "image_url",
              "image_url": {"url": 'data:image/jpeg;base64,$base64Image'},
            },
            {"type": "text", "text": prompt},
          ],
        },
      ],
      // 对于支持的模型，可以指定响应格式为JSON（视觉模型一般不支持？）
      // 'response_format': {'type': 'json_object'},
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

    if (content == null) {
      return null;
    }

    if (content is! String) {
      content = content.toString();
    }

    // 解析响应
    return _parseNutritionLabelResponse(content.trim(), imageFile.path);
  }

  /// 构建营养成分表识别提示词
  String buildNutritionLabelPrompt() {
    return '''
你是一位经过专业训练的营养成分表分析专家，任务是从食品包装图片中精确提取标准化营养数据。请严格按照以下要求执行：

## 任务说明
- 分析食品包装上的营养成分表图片
- 提取所有可见营养信息并转换为标准化格式
- 确保数据准确性和一致性

## 输入规范
- 输入为食品包装上的营养成分表图片
- 可能包含多种规格（如每100g/每份/每包装）
- 可能使用不同单位（kJ/kcal, g/mg/μg）

## 输出要求
1. 必须使用严格的JSON格式返回
2. 所有数值必须转换为每100克的标准单位
3. 缺失字段设为null
4. 不得包含任何解释性文字
5. 如果图中不存在营养成分表，请直接返回 {}

## 数据提取规范
### 必填字段（如存在）
- 食品名称（foodName，完整商品名）
- 参考规格（referenceSize，如"每100克"或"每100毫升"）
- 能量（energyKJ，单位：千焦，kJ）
- 蛋白质（protein，单位：克，g）
- 脂肪（fat，单位：克，g）
- 碳水化合物（CHO，单位：克，g）
- 钠（Na，单位：毫克，mg）

### 可选字段（如存在）
- 膳食纤维（克，g）
- 糖（克，g）
- 反式脂肪酸（克，g）
- 胆固醇（毫克，mg）
- 钙（毫克，mg）
- 铁（毫克，mg）
- 维生素A（微克，μg）
- 维生素C（毫克，mg）
- 维生素E（毫克，mg）
- 配料表（完整列表）

## 数据处理规则
1. 单位转换：
   - 1 kcal = 4.184 kJ
   - 1 g = 1000 mg
   - 1 mg = 1000 μg
2. 特殊值处理：
   - "Tr"/"微量" → 0
   - "<0.1g" → 0
   - "≈" → 取近似值
3. 多规格处理：
   - 优先选择"每100克"数据
   - 若无则按比例换算为100克
4. 数值范围处理：
   - "X-Y" → 取平均值
5. NRV%忽略不计

## 输出示例
```json
{
  "foodName": "全麦面包（如果有）",
  "foodCode": "食品编码（如果有）",
  "referenceSize": "每100克",
  "energyKJ": 1050.0,
  "energyKCal": 251.0,
  "protein": 8.5,
  "fat": 3.2,
  "CHO": 45.0,
  "Na": 380.0,
  "dietaryFiber": 1.0,
  "sugars": 6.2,
  "transFat": 0.0,
  "cholesterol": 0.0,
  "Ca": 50.0,
  "Fe": 1.0,
  "vitaminA": 100.0,
  "vitaminC": 10.0,
  "vitaminETotal": 1.0,
  "ingredients": "全麦粉、水、酵母、食用盐..."
}
```

## 质量保证
1. 交叉验证所有提取数值
2. 确保单位一致性
3. 验证数值合理性（如脂肪不超过100g）
4. 如果字段遇到模糊数据，则该字段的值取null，绝对不能使用任何猜测值

请严格按上述规范返回JSON数据，不要包含任何非JSON内容。
''';
  }

  /// 解析营养成分表响应
  FoodItem? _parseNutritionLabelResponse(String response, String imagePath) {
    // 如果响应为空，直接返回null
    var temp = response.toLowerCase().trim();
    if (temp.isEmpty || temp == 'null' || temp == '{}') {
      return null;
    }

    try {
      // 尝试解析JSON响应
      // 直接取第一个 "{" 和最后一个 "}" 之间的内容解析，避免被 ```json { xxx }```包裹的无法解析
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;

      if (jsonStart == -1 || jsonEnd <= jsonStart) {
        throw Exception('无法在响应中找到有效的JSON数据');
      }

      final jsonStr = response.substring(jsonStart, jsonEnd);

      // 如果响应是```{}```包裹的空，直接返回null
      var tempJsonStr = jsonStr.trim();
      if (tempJsonStr.isEmpty || tempJsonStr == 'null' || tempJsonStr == '{}') {
        return null;
      }

      final Map<String, dynamic> nutritionData = json.decode(jsonStr);

      // 提取配料表，并存入extraAttributes
      final extraAttributes = <String, dynamic>{};
      if (nutritionData.containsKey('ingredients') &&
          nutritionData['ingredients'] != null) {
        extraAttributes['ingredients'] = nutritionData['ingredients'];
      }

      if (nutritionData['energyKCal'] == null &&
          nutritionData['energyKJ'] != null) {
        // 添加能量，需要转换
        nutritionData['energyKCal'] =
            (double.parse(nutritionData['energyKJ'].toString()) * 0.239006)
                .toInt();
      }

      // 添加图片路径
      nutritionData['imageUrl'] = imagePath;

      // 创建FoodItem
      return FoodItem.fromCFCDJsonData(nutritionData);
    } catch (e) {
      throw Exception('无法解析大模型响应的内容:\n\n $e \n\n请选择合适的大模型重新识别');
    }
  }
}
