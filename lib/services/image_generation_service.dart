import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../common/constants/default_models.dart';
import '../common/llm_spec/cus_brief_llm_model.dart';
import '../common/llm_spec/constant_llm_enum.dart';
import '../common/utils/db_tools/db_brief_ai_tool_helper.dart';
import '../common/utils/dio_client/cus_http_client.dart';
import '../common/utils/tools.dart';
import '../models/brief_ai_tools/image_generation/image_generation_request.dart';
import '../models/brief_ai_tools/image_generation/image_generation_response.dart';
import 'cus_get_storage.dart';

/// 2025-02-17
/// 图片生成的API各个平台就算同样模型参数啥的也不太一样；
/// 同一个平台不同模型，API路径不一样，请求参数也不一样，所以可能需要单独处理
/// 暂时测试支持阿里云(先返回任务ID，然后轮询任务状态)、硅基流动(直接返回结果)、智谱(直接返回结果)
class ImageGenerationService {
  static String _getBaseUrl(ApiPlatform platform) {
    switch (platform) {
      case ApiPlatform.zhipu:
        return 'https://open.bigmodel.cn/api/paas/v4/images/generations';
      case ApiPlatform.siliconCloud:
        return 'https://api.siliconflow.cn/v1/images/generations';
      case ApiPlatform.aliyun:
        return 'https://dashscope.aliyuncs.com/api/v1/services/aigc/text2image/image-synthesis';

      default:
        throw Exception('不支持的平台');
    }
  }

  /// 分成taskid进行查询时，需要轮询任务状态的URL
  static String _getBaseTaskUrl(ApiPlatform platform) {
    switch (platform) {
      case ApiPlatform.aliyun:
        return 'https://dashscope.aliyuncs.com/api/v1/tasks';

      default:
        throw Exception('不支持的平台');
    }
  }

  static Future<String> _getApiKey(CusBriefLLMSpec model) async {
    if (model.cusLlmSpecId.endsWith('_builtin')) {
      // 使用内置的 API Key
      switch (model.platform) {
        case ApiPlatform.zhipu:
          return DefaultApiKeys.zhipuAK;
        default:
          throw Exception('不支持的平台');
      }
    } else {
      // 使用用户的 API Key
      final userKeys = MyGetStorage().getUserAKMap();
      String? apiKey;

      switch (model.platform) {
        case ApiPlatform.aliyun:
          apiKey = userKeys[ApiPlatformAKLabel.USER_ALIYUN_API_KEY.name];
          break;
        case ApiPlatform.zhipu:
          apiKey = userKeys[ApiPlatformAKLabel.USER_ZHIPU_API_KEY.name];
          break;
        case ApiPlatform.siliconCloud:
          apiKey = userKeys[ApiPlatformAKLabel.USER_SILICONCLOUD_API_KEY.name];
          break;

        default:
          throw Exception('不支持的平台');
      }

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('未配置该平台的 API Key');
      }
      return apiKey;
    }
  }

  static Future<Map<String, String>> _getHeaders(CusBriefLLMSpec model) async {
    final apiKey = await _getApiKey(model);

    switch (model.platform) {
      case ApiPlatform.siliconCloud || ApiPlatform.zhipu:
        return {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        };
      case ApiPlatform.aliyun:
        return {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'X-DashScope-Async': 'enable',
        };
      // ... 其他平台的 headers
      default:
        throw Exception('不支持的平台');
    }
  }

  static Future<CusUnifiedImageGenResp> generateImage(
    CusBriefLLMSpec model,
    String prompt, {
    int? n,
    String? size,
    File? refImage,
    required String requestId,
    Map<String, dynamic>? extraParams,
  }) async {
    final headers = await _getHeaders(model);
    final baseUrl = _getBaseUrl(model.platform);

    if (refImage != null) {
      extraParams ??= {};
      extraParams['ref_image'] = (await getImageBase64String(refImage));
    }

    final request = ImageGenerationRequest(
      model: model.model,
      prompt: prompt,
      n: n,
      size: size,
      refImage: extraParams?['ref_image'],
    );

    final requestBody = {
      ...request.toRequestBody(model.platform),
      ...?extraParams,
    };

    final response = await HttpUtils.post(
      path: baseUrl,
      headers: headers,
      data: requestBody,
      showLoading: false,
    );

    // 先解析响应
    var resp = CusUnifiedImageGenResp.fromJson(response);

    // 如果是阿里云平台的，需要轮询任务状态
    if (model.platform == ApiPlatform.aliyun) {
      if (resp.output != null) {
        var taskId = resp.output!.taskId;

        // 2025-05-08 这里保存任务ID到数据库，如果轮询得到了结果，在上一层调用的地方会更新数据库状态
        // 这里只是保证没正常得到图片时，还有任务ID可以获取
        final DBBriefAIToolHelper dbHelper = DBBriefAIToolHelper();
        await dbHelper.updateMediaGenerationHistoryByRequestId(requestId, {
          'taskId': taskId,
          'isSuccess': 0,
          'isProcessing': 1,
          'taskStatus': resp.output!.taskStatus,
        });

        return pollTaskStatus(requestId, model, taskId);
      } else {
        throw Exception('阿里云返回的任务ID为空');
      }
    } else {
      return resp;
    }
  }

  static Future<CusUnifiedImageGenResp> pollTaskStatus(
    String requestId,
    CusBriefLLMSpec model,
    String taskId,
  ) async {
    const maxAttempts = 60; // 最大轮询次数
    const interval = Duration(seconds: 5); // 轮询间隔

    for (var i = 0; i < maxAttempts; i++) {
      final response = await _queryTaskStatus(model, taskId);

      // 2025-05-09 既然这个service已经引入了db操作，那就简单点在每次任务检查时，顺便更新一下数据库
      final DBBriefAIToolHelper dbHelper = DBBriefAIToolHelper();

      var tempStatus = response.output.taskStatus;

      var imageUrls = response.output.results?.map((r) => r.url).toList();
      List<String> newUrls = [];
      for (final url in imageUrls ?? []) {
        var localPath = await saveImageToLocal(
          url,
          dlDir: await getImageGenDir(),
          showSaveHint: false,
        );

        if (localPath != null) {
          newUrls.add(localPath);
        }
      }

      // 创建一个包含识别结果的其他参数对象
      final otherParamsMap = {
        'request_id': response.requestId,
        'usage': response.usage,
        // 阿里万相的优化后的prompt也在这里面
        'output': response.output,
      };

      await dbHelper.updateMediaGenerationHistoryByRequestId(requestId, {
        'taskId': taskId,
        'isSuccess': tempStatus == 'SUCCEEDED' ? 1 : 0,
        'isFailed': tempStatus == 'FAILED' ? 1 : 0,
        'isProcessing':
            tempStatus == 'RUNNING' || tempStatus == 'PENDING' ? 1 : 0,
        'taskStatus': tempStatus,
        'imageUrls': newUrls.join(';'),
        "otherParams": jsonEncode(otherParamsMap),
      });

      // 2025-05-09 简单一点，不管成功失败，只要没在继续处理，都返回结果
      // 返回之后，在上一层调用的地方，只需要更新成功时的prompt和图片地址了
      if (response.output.taskStatus != 'PENDING' &&
          response.output.taskStatus != 'RUNNING') {
        return CusUnifiedImageGenResp(
          requestId: taskId,
          created: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          results: response.output.results,
          code: response.code,
          message: response.message,
          output: response.output,
        );
      }
      await Future.delayed(interval);
    }

    // 超时了任务编号也没有了？？？
    throw Exception('图片生成任务超时(5分钟)');
  }

  static Future<AliyunWanxV2Resp> _queryTaskStatus(
    CusBriefLLMSpec model,
    String taskId,
  ) async {
    final headers = await _getHeaders(model);
    final baseUrl = "${_getBaseTaskUrl(model.platform)}/$taskId";

    final response = await HttpUtils.get(
      path: baseUrl,
      headers: headers,
      showLoading: false,
    );

    return AliyunWanxV2Resp.fromJson(response);
  }
}
