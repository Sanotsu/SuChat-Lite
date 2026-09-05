// ignore_for_file: avoid_print

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 0.1.5 存储架构（见 _doc/0.1.5改版存储与模块整合方案.md）
///
/// A 应用私有区（默认，零权限，随卸载清除）：
///   `<documents>/SuChatApp`/{DB, AI_GEN, NET_DL, VOICE_REC, FILE_PICK, BAKUP, LOG}
///
/// B 公共媒体区（卸载不清）：
///   - 桌面：目录函数直接指向 ~/Pictures|Movies|Music/SuChat/...（主存储）
///   - Android/iOS：主存储仍在私有区，由 MediaSaveService 异步双写副本
///     到 MediaStore/相册
///
/// legacy 旧根（仅供 0.1.4 → 0.1.5 升级迁移读取，平时不可达/不存在）：
///   - Android 外部：`/storage/emulated/0/SuChatFiles`（需授权）
///   - 应用文档目录下：SuChatFiles（未授权 Android / iOS / 旧桌面）

/// 确保目录存在并返回
Directory _ensureDir(Directory dir) {
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return dir;
}

/// 获取应用私有区目录（0.1.5 起所有核心数据的默认位置）
///
/// 返回 `<documents>/SuChatApp`[/subfolder]，不请求任何权限。
Future<Directory> getAppPrivateDir({String? subfolder}) async {
  final docs = await getApplicationDocumentsDirectory();
  var dir = Directory(p.join(docs.path, 'SuChatApp'));
  if (subfolder != null && subfolder.trim().isNotEmpty) {
    dir = Directory(p.join(dir.path, subfolder));
  }
  return _ensureDir(dir);
}

/// 0.1.4 旧数据的候选根列表（异步：移动端文档目录需异步取得）
///
/// Android：外部共享存储 + 应用文档目录两个候选（前者需授权才可读）；
/// 其他平台：应用文档目录下 SuChatFiles 单候选。
Future<List<Directory>> getLegacyHomeCandidatesAsync() async {
  final docs = await getApplicationDocumentsDirectory();
  final docsLegacy = Directory(p.join(docs.path, 'SuChatFiles'));
  if (Platform.isAndroid) {
    return [Directory('`/storage/emulated/0/SuChatFiles`'), docsLegacy];
  }
  // 旧桌面版数据在 用户文档/SuChatFiles，与应用文档目录一致（桌面二者同源）
  return [docsLegacy];
}

/// 桌面公共媒体目录：~/Pictures|Movies|Music/SuChat[/sub]
///
/// 仅 Windows/Linux/macOS 有效；移动端公共区由 MediaSaveService
/// 经 MediaStore/相册写入，不走文件路径。
Directory? getDesktopMediaDir(String kind, {String? subfolder}) {
  if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    return null;
  }
  final env = Platform.environment;
  final home = env['USERPROFILE'] ?? env['HOME'];
  if (home == null) return null;
  var dir = Directory(p.join(home, kind, 'SuChat'));
  if (subfolder != null && subfolder.isNotEmpty) {
    dir = Directory(p.join(dir.path, subfolder));
  }
  return _ensureDir(dir);
}

/// 桌面用户主目录（USERPROFILE / HOME）
String? getDesktopHomePath() {
  final env = Platform.environment;
  return env['USERPROFILE'] ?? env['HOME'];
}

/// 2026-09-04 get_storage 容器文件收纳目录
/// 历史版本所有 *.gs/*.bak 容器散落在文档目录根，
/// 现统一收进私有区 `<documents>/SuChatApp/GetStorage`
Future<Directory> getGetStorageDir() =>
    getAppPrivateDir(subfolder: 'GetStorage');
