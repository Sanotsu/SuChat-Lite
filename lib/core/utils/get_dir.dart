// ignore_for_file: avoid_print

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../shared/widgets/toast_utils.dart';
import 'simple_tools.dart';

/// 获取应用主目录
/// [subfolder] 可选的子目录名称
///
/// 返回的目录结构：
/// - Android (有权限): /storage/emulated/0/SuChatFiles[/subfolder]
/// - Android (无权限): /data/data/《packageName》/app_flutter/SuChatFiles[/subfolder]
/// - iOS: ~/Documents/SuChatFiles[/subfolder]
/// - 其他平台: 文档目录/SuChatFiles[/subfolder]
Future<Directory> getAppHomeDirectory({String? subfolder}) async {
  try {
    Directory baseDir;

    if (Platform.isAndroid) {
      // 尝试获取外部存储权限
      final hasPermission = await requestStoragePermission();

      if (hasPermission) {
        // 注意：直接使用硬编码路径在Android 10+可能不可靠
        baseDir = Directory('/storage/emulated/0/SuChatFiles');
      } else {
        ToastUtils.showError("未授权访问设备外部存储，数据将保存到应用文档目录");

        baseDir = await getApplicationDocumentsDirectory();
        baseDir = Directory(p.join(baseDir.path, 'SuChatFiles'));
      }
    } else {
      // 其他平台使用文档目录
      baseDir = await getApplicationDocumentsDirectory();
      baseDir = Directory(p.join(baseDir.path, 'SuChatFiles'));
    }

    // 处理子目录
    if (subfolder != null && subfolder.trim().isNotEmpty) {
      baseDir = Directory(p.join(baseDir.path, subfolder));
    }

    // 确保目录存在
    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }

    print('getAppHomeDirectory 获取的目录: ${baseDir.path}');
    return baseDir;
  } catch (e) {
    print('获取应用目录失败: $e');
    // 回退方案：使用临时目录
    final tempDir = await getTemporaryDirectory();
    return Directory(p.join(tempDir.path, 'SuChatFallback'));
  }
}

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

/// 获取sqlite数据库文件保存的目录
Future<Directory> getSqliteDbDir() async {
  return getAppHomeDirectory(subfolder: "DB/sqlite_db");
}

/// 获取objectbox数据库文件保存的目录
Future<Directory> getObjectBoxDir() async {
  return getAppHomeDirectory(subfolder: "DB/objectbox");
}

/// 语音输入时，录音文件保存的目录
Future<Directory> getChatAudioDir() async {
  return getAppHomeDirectory(subfolder: "VOICE_REC/chat_audio");
}

/// 用于声音复制、录音识别时录制的声音存放
Future<Directory> getVoiceRecordingDir() async {
  return getAppHomeDirectory(subfolder: "VOICE_REC/voice_recordings");
}

/// 笔记语音录音文件保存的目录
Future<Directory> getNoteVoiceRecordingDir() async {
  return getAppHomeDirectory(subfolder: "VOICE_REC/note_voice_recordings");
}

/// 图片生成时，图片文件保存的目录
Future<Directory> getImageGenDir() async {
  return getAppHomeDirectory(subfolder: "AI_GEN/images");
}

/// 新版本统一对话时生成的媒体资源
Future<Directory> getUnifiedChatMediaDir() async {
  return getAppHomeDirectory(subfolder: "AI_GEN/unified_chat_media");
}

/// 视频生成时，视频文件保存的目录
Future<Directory> getVideoGenDir() async {
  return getAppHomeDirectory(subfolder: "AI_GEN/videos");
}

/// 语音生成时，语音文件保存的目录
Future<Directory> getVoiceGenDir() async {
  return getAppHomeDirectory(subfolder: "AI_GEN/voices");
}

// 翻译时语言合成单独一个文件夹
Future<Directory> getTranslatorVoiceGenDir() async {
  return getAppHomeDirectory(subfolder: "AI_GEN/voices/translator");
}

// 单独的多模态语音合成时文件保存的目录
Future<Directory> getOmniChatVoiceGenDir() async {
  return getAppHomeDirectory(subfolder: "AI_GEN/voices/omni_chat");
}

/// 使用file_picker选择文件时，保存文件的目录
/// 所有文件选择都放在同一个位置，重复时直接返回已存在的内容
Future<Directory> getFilePickerSaveDir() async {
  return getAppHomeDirectory(subfolder: "FILE_PICK/file_picker_files");
}

/// 使用image_picker选择文件时，保存文件的目录
/// 所有文件选择都放在同一个位置，重复时直接返回已存在的内容
Future<Directory> getImagePickerSaveDir() async {
  return getAppHomeDirectory(subfolder: "FILE_PICK/image_picker_files");
}

/// 获取角色背景图头像的目录
Future<Directory> getCharacterDir() async {
  return getAppHomeDirectory(subfolder: "FILE_PICK/character_images");
}

/// 使用dio下载文件时，保存文件的目录
Future<Directory> getDioDownloadDir() async {
  return getAppHomeDirectory(subfolder: "NET_DL/dio_download_files");
}

/// 语音输入时，录音文件保存的目录
Future<Directory> getBackupDir() async {
  return getAppHomeDirectory(subfolder: "BAKUP/backup_files");
}

// 统一对话的备份文件
Future<Directory> getUnifiedChatBackupDir() async {
  return getAppHomeDirectory(subfolder: "BAKUP/backup_files/unified_chat");
}
