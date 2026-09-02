// ignore_for_file: avoid_print

import 'dart:io';

import 'package:path/path.dart' as p;

import 'storage_paths.dart';

export 'storage_paths.dart'
    show
        getAppPrivateDir,
        getLegacyHomeCandidatesAsync,
        getDesktopMediaDir,
        getDesktopHomePath;

/// ========================================================================
/// 0.1.5 目录体系：核心数据全部位于应用私有区 `<documents>/SuChatApp`/，
/// 不请求任何存储权限；AI 生成媒体在桌面端直达公共目录（卸载不清），
/// 移动端主存储在私有区、由 MediaSaveService 异步双写公共副本。
/// 旧版 0.1.4 数据根（SuChatFiles）仅供升级迁移读取，见 storage_paths.dart。
/// ========================================================================

/// 清理文件名，移除非法字符
String sanitizeFileName(String fileName, {String replacement = '_'}) {
  // 移除或替换文件名中的非法字符
  final illegalChars = RegExp(r'[\\/:*?"<>|]');
  var cleanName = fileName.replaceAll(illegalChars, replacement);

  // 确保文件名不以点号开头或结尾（某些系统限制）
  cleanName = cleanName.replaceAll(RegExp(r'^\.+|\.+$'), '');

  // 移除连续的下划线
  cleanName = cleanName.replaceAll(RegExp('_+'), '_');

  // 确保文件名不为空
  if (cleanName.isEmpty) {
    cleanName = 'unnamed_file_${DateTime.now().millisecondsSinceEpoch}';
  }

  return cleanName;
}

/// 生成媒体目录的公共解析：
/// - 桌面：`~/<kind>/SuChat/<sub>`（公共区，主存储，卸载不清）
/// - 移动端：私有区 `AI_GEN/<sub>`（公共副本由 MediaSaveService 双写）
Future<Directory> _generatedMediaDir(String kind, String sub) async {
  final desktop = getDesktopMediaDir(kind, subfolder: sub);
  if (desktop != null) return desktop;
  return getAppPrivateDir(subfolder: 'AI_GEN/$sub');
}

/// 获取sqlite数据库文件保存的目录（私有区）
Future<Directory> getSqliteDbDir() async {
  return getAppPrivateDir(subfolder: "DB/sqlite_db");
}

/// 获取objectbox数据库文件保存的目录
///
/// 0.1.5：ObjectBox 仅剩旧聊天模块读取旧数据（P5 整体移除），
/// 固定指向 0.1.4 旧根，不再随新架构移动。
/// @Deprecated('0.1.5 移除旧聊天模块时删除')
Future<Directory?> getObjectBoxDir() async {
  final candidates = await getLegacyHomeCandidatesAsync();
  for (final dir in candidates) {
    final target = Directory(p.join(dir.path, 'DB/objectbox'));
    try {
      if (target.existsSync()) return target;
    } catch (_) {}
  }
  return null;
}

/// 语音输入时，录音文件保存的目录（私有区）
Future<Directory> getChatAudioDir() async {
  return getAppPrivateDir(subfolder: "VOICE_REC/chat_audio");
}

/// 用于声音复制、录音识别时录制的声音存放（私有区）
Future<Directory> getVoiceRecordingDir() async {
  return getAppPrivateDir(subfolder: "VOICE_REC/voice_recordings");
}

/// 图片生成时，图片文件保存的目录
Future<Directory> getImageGenDir() async {
  return _generatedMediaDir('Pictures', 'images');
}

/// 新版本统一对话时生成的媒体资源
Future<Directory> getUnifiedChatMediaDir() async {
  return _generatedMediaDir('Pictures', 'unified_chat_media');
}

/// 视频生成时，视频文件保存的目录
Future<Directory> getVideoGenDir() async {
  return _generatedMediaDir('Movies', 'videos');
}

/// 语音生成时，语音文件保存的目录
Future<Directory> getVoiceGenDir() async {
  return _generatedMediaDir('Music', 'voices');
}

// 翻译时语言合成单独一个文件夹
Future<Directory> getTranslatorVoiceGenDir() async {
  return _generatedMediaDir('Music', 'voices/translator');
}

// 单独的多模态语音合成时文件保存的目录
Future<Directory> getOmniChatVoiceGenDir() async {
  return _generatedMediaDir('Music', 'voices/omni_chat');
}

/// 使用file_picker选择文件时，保存文件的目录（私有区）
/// 所有文件选择都放在同一个位置，重复时直接返回已存在的内容
Future<Directory> getFilePickerSaveDir() async {
  return getAppPrivateDir(subfolder: "FILE_PICK/file_picker_files");
}

/// 使用image_picker选择文件时，保存文件的目录（私有区）
Future<Directory> getImagePickerSaveDir() async {
  return getAppPrivateDir(subfolder: "FILE_PICK/image_picker_files");
}

/// 获取角色背景图头像的目录（私有区）
Future<Directory> getCharacterDir() async {
  return getAppPrivateDir(subfolder: "FILE_PICK/character_images");
}

/// 使用dio下载文件时，保存文件的目录（私有区，浏览缓存性质，不双写公共区）
Future<Directory> getDioDownloadDir() async {
  return getAppPrivateDir(subfolder: "NET_DL/dio_download_files");
}

/// 日志与备份工作目录（私有区；最终备份 zip 由用户经系统保存器自选位置）
Future<Directory> getBackupDir() async {
  return getAppPrivateDir(subfolder: "BAKUP/backup_files");
}

// 统一对话的备份文件
Future<Directory> getUnifiedChatBackupDir() async {
  return getAppPrivateDir(subfolder: "BAKUP/backup_files/unified_chat");
}
