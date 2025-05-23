import 'dart:convert';

import 'package:get_storage/get_storage.dart';

import '../common/llm_spec/constant_llm_enum.dart';
import '../common/llm_spec/cus_brief_llm_model.dart';
import '../views/brief_ai_assistant/branch_chat/components/message_color_config.dart';

final box = GetStorage();

class MyGetStorage {
  static const String _firstLaunchKey = 'is_first_launch';

  // 检查是否首次启动
  bool isFirstLaunch() {
    return box.read(_firstLaunchKey) == null;
  }

  // 标记已启动
  Future<void> markLaunched() async {
    await box.write(_firstLaunchKey, false);
  }

  ///
  /// 文本对话的对话列表的缩放比例
  ///
  static const String chatMessageTextScaleKey = 'chat_list_area_scale';
  Future<void> setChatMessageTextScale(double? flag) async {
    await box.write(chatMessageTextScaleKey, flag);
  }

  double getChatMessageTextScale() => box.read(chatMessageTextScaleKey) ?? 1.0;

  ///
  /// 如果用户有输入自己的API KEY的话，就存入缓存中
  ///
  static const String userAkMapKey = 'user_ak_map';
  Future<void> setUserAKMap(Map<String, String>? info) async {
    await box.write(userAkMapKey, info);
  }

  Map<String, String> getUserAKMap() =>
      Map<String, String>.from(box.read(userAkMapKey) ?? {});

  // 清空用户的 API Keys
  Future<void> clearUserAKMap() async {
    await box.remove(userAkMapKey); // 直接删除整个 map
  }

  // 删除单个 API Key
  Future<void> removeUserAK(String key) async {
    if (key.startsWith('USER_')) {
      await box.remove(key);
    }
  }

  ///
  /// 大模型高级选项的启用状态(不同模型分开存储)
  ///
  Future<void> setAdvancedOptionsEnabled(
    CusBriefLLMSpec model,
    bool enabled,
  ) async {
    await box.write(
      "advanced_options_enabled_${model.platform.name}_${model.modelType.name}",
      enabled,
    );
  }

  bool getAdvancedOptionsEnabled(CusBriefLLMSpec model) =>
      box.read(
        "advanced_options_enabled_${model.platform.name}_${model.modelType.name}",
      ) ??
      false;

  ///
  /// 高级选项的参数值(不同模型分开存储)
  ///
  Future<void> setAdvancedOptions(
    CusBriefLLMSpec model,
    Map<String, dynamic>? options,
  ) async {
    final key =
        "advanced_options_${model.platform.name}_${model.modelType.name}";
    if (options != null) {
      await box.write(key, options);
    } else {
      await box.remove(key);
    }
  }

  Map<String, dynamic>? getAdvancedOptions(CusBriefLLMSpec model) {
    final data = box.read(
      "advanced_options_${model.platform.name}_${model.modelType.name}",
    );
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  ///
  /// 分支对话背景相关方法
  ///
  static const String _branchChatBackgroundKey = 'chat_background';
  static const String _branchChatBackgroundOpacityKey =
      'chat_background_opacity';
  static const String _branchChatHistoryPanelBgColorKey =
      'branch_chat_history_panel_bg_color_key';

  Future<String?> getBranchChatBackground() async {
    return box.read(_branchChatBackgroundKey);
  }

  Future<void> saveBranchChatBackground(String? path) async {
    if (path == null || path.isEmpty) {
      await box.remove(_branchChatBackgroundKey);
    } else {
      await box.write(_branchChatBackgroundKey, path);
    }
  }

  Future<double?> getBranchChatBackgroundOpacity() async {
    return box.read(_branchChatBackgroundOpacityKey);
  }

  Future<void> saveBranchChatBackgroundOpacity(double opacity) async {
    await box.write(_branchChatBackgroundOpacityKey, opacity);
  }

  // 2025-04-14 对话侧边栏背景色(根据对话主页面背景图变化，但如果图片没变还是会每次显示都重复加载，所以缓存)
  // 缓存时xxx为Color.toARGB32(), 获取后Color(xxx)
  Future<int?> getBranchChatHistoryPanelBgColor() async {
    return box.read(_branchChatHistoryPanelBgColorKey);
  }

  Future<void> saveBranchChatHistoryPanelBgColor(int? color) async {
    if (color == null || color.isNaN) {
      await box.remove(_branchChatHistoryPanelBgColorKey);
    } else {
      await box.write(_branchChatHistoryPanelBgColorKey, color);
    }
  }

  ///
  /// 更新指定平台的 API Key
  ///
  Future<void> updatePlatformApiKey(
    ApiPlatformAKLabel label,
    String apiKey,
  ) async {
    final userKeys = getUserAKMap();
    userKeys[label.name] = apiKey;
    await setUserAKMap(userKeys);
  }

  ///
  /// 2025-04-11 用户自行配置的消息体颜色
  ///
  static const messageColorConfigKey = 'message_color_config';

  Future<void> saveMessageColorConfig(MessageColorConfig config) async {
    await box.write(messageColorConfigKey, json.encode(config.toMap()));
  }

  Future<MessageColorConfig> loadMessageColorConfig() async {
    final configString = box.read(messageColorConfigKey);

    if (configString != null) {
      try {
        return MessageColorConfig.fromMap(json.decode(configString));
      } catch (e) {
        return MessageColorConfig.defaultConfig();
      }
    }

    return MessageColorConfig.defaultConfig();
  }

  ///
  /// 2025-04-16 把文件上传到智谱开发平台的文件管理中去
  /// 那么只能使用用户自己的API KEY，所以需要缓存
  ///
  static const String bigmodelApiKey = 'bigmodel_api_key';
  Future<void> setBigmodelApiKey(String? key) async {
    await box.write(bigmodelApiKey, key);
  }

  String? getBigmodelApiKey() => box.read(bigmodelApiKey);
}
