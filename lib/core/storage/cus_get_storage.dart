import 'dart:convert';

import 'package:get_storage/get_storage.dart';

import '../entities/message_font_color.dart';

class CusGetStorage {
  static const String _firstLaunchKey = 'is_first_launch';
  static const String _permissionGrantedKey = 'permission_granted';

  // 存储名称常量
  static const String storeName = 'SuChatGetStorage';

  // 获取正确初始化的GetStorage实例
  GetStorage get box => GetStorage(storeName);

  // 检查是否首次启动
  bool isFirstLaunch() {
    return box.read(_firstLaunchKey) == null;
  }

  // 标记已启动
  Future<void> markLaunched() async {
    await box.write(_firstLaunchKey, false);
  }

  // 检查是否已授权
  bool isPermissionGranted() {
    return box.read(_permissionGrantedKey) == true;
  }

  // 标记已授权
  Future<void> markPermissionGranted() async {
    await box.write(_permissionGrantedKey, true);
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
  /// 用户自定义的第三方内容源密钥存储(TMDB/USDA/NewsAPI等，用户自定义优先)
  /// 2026-09-07 LLM旧体系退役：旧版同时在该Map存LLM平台Key
  /// (USER_ALIYUN_API_KEY等5个)，迁移器已将其转入 flutter_secure_storage，
  /// 本Map此后仅存内容源Key(见 get_app_key_helper.getStoredUserKey)
  ///
  static const String userAkMapKey = 'user_ak_map';
  Future<void> setUserAKMap(Map<String, String>? info) async {
    await box.write(userAkMapKey, info);
  }

  Map<String, String> getUserAKMap() =>
      Map<String, String>.from(box.read(userAkMapKey) ?? {});

  ///
  /// 统一聊天模块的简洁显示开关
  /// 2026-08-31 旧版branch_chat的简洁显示仅内存态(每次进页面重置)，新版持久化
  ///
  static const String _unifiedChatBriefDisplayKey =
      'unified_chat_brief_display';

  Future<void> setUnifiedChatBriefDisplay(bool value) async {
    await box.write(_unifiedChatBriefDisplayKey, value);
  }

  bool getUnifiedChatBriefDisplay() =>
      box.read(_unifiedChatBriefDisplayKey) ?? false;

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
  /// 2025-04-11 用户自行配置的消息体颜色
  ///
  static const messageFontColorKey = 'message_font_color';

  Future<void> saveMessageFontColor(MessageFontColor color) async {
    await box.write(messageFontColorKey, json.encode(color.toMap()));
  }

  Future<MessageFontColor> loadMessageFontColor() async {
    final configString = box.read(messageFontColorKey);

    if (configString != null) {
      try {
        return MessageFontColor.fromMap(json.decode(configString));
      } catch (e) {
        return MessageFontColor.defaultConfig();
      }
    }

    return MessageFontColor.defaultConfig();
  }

  ///
  /// GitHub存储配置相关
  ///
  static const String githubUsernameKey = 'github_username';
  static const String githubRepoKey = 'github_repo';
  static const String githubTokenKey = 'github_token';

  // 设置GitHub用户名
  Future<void> setGithubUsername(String? username) async {
    if (username == null || username.isEmpty) {
      await box.remove(githubUsernameKey);
    } else {
      await box.write(githubUsernameKey, username);
    }
  }

  // 获取GitHub用户名
  String getGithubUsername() => box.read(githubUsernameKey) ?? '';

  // 设置GitHub仓库名
  Future<void> setGithubRepo(String? repo) async {
    if (repo == null || repo.isEmpty) {
      await box.remove(githubRepoKey);
    } else {
      await box.write(githubRepoKey, repo);
    }
  }

  // 获取GitHub仓库名
  String getGithubRepo() => box.read(githubRepoKey) ?? '';

  // 设置GitHub访问令牌
  Future<void> setGithubToken(String? token) async {
    if (token == null || token.isEmpty) {
      await box.remove(githubTokenKey);
    } else {
      await box.write(githubTokenKey, token);
    }
  }

  // 获取GitHub访问令牌
  String getGithubToken() => box.read(githubTokenKey) ?? '';
}
