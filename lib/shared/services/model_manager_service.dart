import '../constants/default_models.dart';
import '../../core/entities/cus_llm_model.dart';
import '../constants/constant_llm_enum.dart';
import '../../core/storage/db_helper.dart';
import '../../core/storage/cus_get_storage.dart';

class ModelManagerService {
  static final DBHelper _dbHelper = DBHelper();

  // 初始化内置模型
  static Future<void> initBuiltinModels({bool? isAppInit = false}) async {
    final exists = await _dbHelper.queryCusLLMSpecList(isBuiltin: true);

    // 如果是app初始化加载内置模型，则判断db中是否存在，如果存在内置模型，则不删除
    if (exists.isNotEmpty && isAppInit == true) {
      return;
    }

    // 如果是业务中手动初始化基础模型，则直接重置
    final models =
        defaultModels.map((model) {
          model.gmtCreate = DateTime.now();
          model.isBuiltin = true;
          return model;
        }).toList();

    // 删除全部内置模型
    for (final model in exists) {
      await _dbHelper.deleteCusLLMSpecById(model.cusLlmSpecId);
    }

    await _dbHelper.saveCusLLMSpecs(models);
  }

  // 获取可用的模型列表(有对应平台 AK 的模型)
  static Future<List<CusLLMSpec>> getAvailableModels() async {
    final allModels = await _dbHelper.queryCusLLMSpecList();
    final userKeys = CusGetStorage().getUserAKMap();

    return allModels.where((model) {
      if (model.cusLlmSpecId.endsWith('_builtin')) {
        // 内置模型总是可用
        return true;
      }

      // 检查用户是否配置了该平台的 AK
      switch (model.platform) {
        case ApiPlatform.aliyun:
          return userKeys[ApiPlatformAKLabel.USER_ALIYUN_API_KEY.name]
                  ?.isNotEmpty ??
              false;
        case ApiPlatform.baidu:
          return userKeys[ApiPlatformAKLabel.USER_BAIDU_API_KEY_V2.name]
                  ?.isNotEmpty ??
              false;
        case ApiPlatform.tencent:
          return userKeys[ApiPlatformAKLabel.USER_TENCENT_API_KEY.name]
                  ?.isNotEmpty ??
              false;

        case ApiPlatform.deepseek:
          return userKeys[ApiPlatformAKLabel.USER_DEEPSEEK_API_KEY.name]
                  ?.isNotEmpty ??
              false;
        case ApiPlatform.lingyiwanwu:
          return userKeys[ApiPlatformAKLabel.USER_LINGYIWANWU_API_KEY.name]
                  ?.isNotEmpty ??
              false;
        case ApiPlatform.zhipu:
          return userKeys[ApiPlatformAKLabel.USER_ZHIPU_API_KEY.name]
                  ?.isNotEmpty ??
              false;

        case ApiPlatform.siliconCloud:
          return userKeys[ApiPlatformAKLabel.USER_SILICONCLOUD_API_KEY.name]
                  ?.isNotEmpty ??
              false;
        case ApiPlatform.infini:
          return userKeys[ApiPlatformAKLabel
                      .USER_INFINI_GEN_STUDIO_API_KEY
                      .name]
                  ?.isNotEmpty ??
              false;
        case ApiPlatform.volcengine:
          return userKeys[ApiPlatformAKLabel.USER_VOLCENGINE_API_KEY.name]
                  ?.isNotEmpty ??
              false;
        case ApiPlatform.volcesBot:
          return userKeys[ApiPlatformAKLabel.USER_VOLCESBOT_API_KEY.name]
                  ?.isNotEmpty ??
              false;
        // 2025-04-11 默认就是自定义模型(云平台不在我预设中)，密钥和地址在模型规格中，直接返回true
        default:
          return true;
      }
    }).toList();
  }

  // 指定模型分类来获取可用的模型列表
  static Future<List<CusLLMSpec>> getAvailableModelByTypes(
    List<LLModelType> modelTypes,
  ) async {
    final allModels = await getAvailableModels();

    // 然后过滤出指定类型的模型
    List<CusLLMSpec> list =
        allModels
            .where((model) => modelTypes.contains(model.modelType))
            .toList();

    // 固定平台排序后模型名排序
    list.sort((a, b) {
      // 先比较 平台名称
      int compareA = a.platform.name.compareTo(b.platform.name);
      if (compareA != 0) {
        return compareA;
      }

      // 如果 平台名称 相同，再比较 模型名称
      return a.name?.compareTo(b.name ?? b.model) ?? 0;
    });

    return list;
  }

  // 验证用户导入的模型配置
  static bool validateModelConfig(Map<String, dynamic> json) {
    try {
      // 验证平台是否支持（这里找不到就会报错，在catch中会返回false）
      ApiPlatform.values.firstWhere(
        (e) => e.name == json['platform'],
        orElse: () => throw Exception('不支持的云平台'),
      );

      // 2025-03-07 字段验证简化一下，就平台、模型、模型类型即可
      if (json['platform'] == null ||
          (json['platform'] as String).trim().isEmpty ||
          json['model'] == null ||
          (json['model'] as String).trim().isEmpty ||
          json['modelType'] == null ||
          (json['modelType'] as String).trim().isEmpty) {
        return false;
      }

      // 2025-05-12 如果是自定义平台，还需要baseurl 和 apikey
      if (json['platform'] == ApiPlatform.custom.name) {
        if (json['baseUrl'] == null ||
            (json['baseUrl'] as String).trim().isEmpty ||
            json['apiKey'] == null ||
            (json['apiKey'] as String).trim().isEmpty) {
          return false;
        }
      }

      return true;
    } catch (e) {
      rethrow;
    }
  }

  // 删除用户导入的模型(内置模型不能删除)
  static Future<bool> deleteUserModel(String modelId) async {
    // 2025-04-15 如果有其他同类型的模型，可以删除内置的
    // if (modelId.endsWith('_builtin')) return false;

    await _dbHelper.deleteCusLLMSpecById(modelId);
    return true;
  }

  // 清空用户导入的模型(保留内置模型)
  static Future<void> clearUserModels() async {
    final models = await _dbHelper.queryCusLLMSpecList();
    for (final model in models) {
      if (!model.cusLlmSpecId.endsWith('_builtin')) {
        await _dbHelper.deleteCusLLMSpecById(model.cusLlmSpecId);
      }
    }
  }
}
