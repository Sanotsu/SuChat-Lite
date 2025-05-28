import '../../core/entities/cus_llm_model.dart';
import 'constant_llm_enum.dart';

/// 内置的默认模型列表
final defaultImageGenerationModels = [
  /// 智谱AI
  CusLLMSpec(
    ApiPlatform.zhipu,
    'cogview-3-flash',
    LLModelType.tti,
    name: 'CogView-3-Flash',
    isFree: true,
    cusLlmSpecId: 'zhipu_cogview_3_flash_builtin',
    gmtCreate: DateTime.now(),
    isBuiltin: true,
  ),
];
