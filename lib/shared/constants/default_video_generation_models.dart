import '../../core/entities/cus_llm_model.dart';
import 'constant_llm_enum.dart';

final defaultVideoGenerationModels = [
  CusLLMSpec(
    ApiPlatform.zhipu,
    'cogvideox-flash',
    LLModelType.video,
    name: 'cogvideox-flash',
    isFree: true,
    cusLlmSpecId: 'zhipu_cogvideox_flash_builtin',
    gmtCreate: DateTime.now(),
    isBuiltin: true,
  ),
];
