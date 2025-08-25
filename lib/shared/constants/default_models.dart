import '../../core/entities/cus_llm_model.dart';
import 'constant_llm_enum.dart';
import 'default_image_generation_models.dart';
import 'default_video_generation_models.dart';

///
/// 内置模型的 API Keys (用户不可见和修改)
/// 2025-03-03 默认是有免费的模型，才可以简单提供内嵌的 API Keys
/// 最好都使用自己的 AK 进行替换，以获取最佳体验。
///
// class DefaultApiKeys {
//   static const baiduApiKey = 'xxx';
//   static const tencentApiKey = 'xxx';
//   static const zhipuAK = 'xxx.xxx';
//   static const siliconCloudAK = 'sk-xxx';

//   // 讯飞(语音转文字需要)
//   static const xfyunAppId = 'xxx';
//   static const xfyunApiKey = 'xxx';
//   static const xfyunApiSecret = 'xxx';

//   // NUTRITIONIX的应用编号和密钥
//   static const nutritionixAppId = 'xxx';
//   static const nutritionixAppKey = 'xxx';

//   // newsapi完整的api key
//   static const newsApiKey = 'xxx';

//   // twitch 开发者APP的编号和密钥
//    static const twitchClientId = "xxx";
//    static const twitchApiKey = "xxx";

//    // https://www.themoviedb.org/settings/api
//    static const tmdbApiKey = "xxx";
//    static const tmdbAccessToken = "xxx";

//    // 阿里云的 AK
//    static const aliyunApiKey = "sk-xxx";
// }

// 内置模型使用的密钥的命名如上即可，这里只是使用了作者的密钥
part '_self_build_in_ak.dart';

/// 内置的默认模型列表
/// 2025-02-17 内置模型的 cusLlmSpecId 需要手动创建好，
/// 在应用首次初始化时，会根据 cusLlmSpecId 来判断是否存在，不存在才加入数据库
/// 2025-03-03 至少保证每种类型都有一个免费的内置模型，方便测试使用(多了也不方便)
/// 更多的收费、免费的，用户自行导入
final defaultModels = [
  ...defaultImageGenerationModels,
  ...defaultVideoGenerationModels,
  CusLLMSpec(
    ApiPlatform.siliconCloud,
    'deepseek-ai/DeepSeek-R1-Distill-Qwen-7B',
    LLModelType.reasoner,
    name: 'DeepSeek-R1-Distill-Qwen-7B',
    isFree: true,
    cusLlmSpecId: 'siliconCloud_deepseek_r1_distill_qwen_7b_builtin',
    gmtCreate: DateTime.now(),
    isBuiltin: true,
  ),
  CusLLMSpec(
    ApiPlatform.siliconCloud,
    'THUDM/GLM-Z1-9B-0414',
    LLModelType.reasoner,
    name: 'GLM-Z1-9B-0414',
    isFree: true,
    cusLlmSpecId: 'siliconCloud_glm_z1_9b_0414_builtin',
    gmtCreate: DateTime.now(),
    isBuiltin: true,
  ),
  CusLLMSpec(
    ApiPlatform.siliconCloud,
    'Qwen/Qwen2.5-7B-Instruct',
    LLModelType.cc,
    name: 'Qwen2.5-7B-Instruct',
    isFree: true,
    cusLlmSpecId: 'siliconCloud_qwen2_5_7b_instruct_builtin',
    gmtCreate: DateTime.now(),
    isBuiltin: true,
  ),
  CusLLMSpec(
    ApiPlatform.siliconCloud,
    'THUDM/GLM-4-9B-0414',
    LLModelType.cc,
    name: 'GLM-4-9B-0414',
    isFree: true,
    cusLlmSpecId: 'siliconCloud_glm_4_9b_0414_builtin',
    gmtCreate: DateTime.now(),
    isBuiltin: true,
  ),
  CusLLMSpec(
    ApiPlatform.baidu,
    "ernie-speed-128k",
    LLModelType.cc,
    name: "ERNIE-Speed-128K",
    isFree: true,
    cusLlmSpecId: 'baidu_ernie_speed_128k_builtin',
    gmtCreate: DateTime.now(),
    isBuiltin: true,
  ),
  CusLLMSpec(
    ApiPlatform.tencent,
    "hunyuan-lite",
    LLModelType.cc,
    name: "hunyuan-lite",
    isFree: true,
    cusLlmSpecId: 'tencent_hunyuan_lite_builtin',
    gmtCreate: DateTime.now(),
    isBuiltin: true,
  ),
  CusLLMSpec(
    ApiPlatform.zhipu,
    "glm-4.5-flash",
    LLModelType.cc,
    name: "GLM-4.5-Flash",
    isFree: true,
    cusLlmSpecId: 'zhipu_glm_4_5_flash_builtin',
    gmtCreate: DateTime.now(),
    isBuiltin: true,
  ),
  CusLLMSpec(
    ApiPlatform.zhipu,
    "glm-4-flash",
    LLModelType.cc,
    name: "CGLM-4-Flash",
    isFree: true,
    cusLlmSpecId: 'zhipu_glm_4_flash_builtin',
    gmtCreate: DateTime.now(),
    isBuiltin: true,
  ),
  CusLLMSpec(
    ApiPlatform.zhipu,
    "glm-4-flash-250414",
    LLModelType.cc,
    name: "GLM-4-Flash-250414",
    isFree: true,
    cusLlmSpecId: 'zhipu_glm_4_flash_250414_builtin',
    gmtCreate: DateTime.now(),
    isBuiltin: true,
  ),
  CusLLMSpec(
    ApiPlatform.zhipu,
    "glm-4v-flash",
    LLModelType.vision,
    name: "GLM-4V-Flash",
    isFree: true,
    cusLlmSpecId: 'zhipu_glm_4v_flash_builtin',
    gmtCreate: DateTime.now(),
    isBuiltin: true,
  ),
  CusLLMSpec(
    ApiPlatform.zhipu,
    "glm-4.1v-thinking-flash",
    LLModelType.vision,
    name: "GLM-4.1V-Thinking-Flash",
    isFree: true,
    cusLlmSpecId: 'zhipu_glm_4_1v_thinking_flash_builtin',
    gmtCreate: DateTime.now(),
    isBuiltin: true,
  ),
  CusLLMSpec(
    ApiPlatform.zhipu,
    "glm-z1-flash",
    LLModelType.reasoner,
    name: "GLM-Z1-Flash",
    isFree: true,
    cusLlmSpecId: 'zhipu_glm_z1_flash_builtin',
    gmtCreate: DateTime.now(),
    isBuiltin: true,
  ),
];
