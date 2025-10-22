// ignore_for_file: non_constant_identifier_names

import 'buildin_aliyun_models.dart';
import 'buildin_deepseek_models.dart';
import 'buildin_infini_models.dart';
import 'buildin_lingyiwanwu_models.dart';
import 'buildin_siliconflow_models.dart';
import 'buildin_volcengine_models.dart';
import 'buildin_zhipu_models.dart';

List<Map<String, dynamic>> BUILD_IN_MODELS = [
  ...aliyunModels,
  ...siliconflowModels,
  ...zhipuModels,
  ...volcengineModels,
  ...deepseekModels,
  ...infiniModels,
  ...lingyiwanwuModels,
];
