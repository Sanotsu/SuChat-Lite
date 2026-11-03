// ignore_for_file: avoid_print

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:photo_manager/photo_manager.dart';

/// AI 生成媒体的公共区双写服务(0.1.5)
///
/// 策略(见 _doc/0.1.5改版存储与模块整合方案.md 目标5)：
/// - 桌面：目录函数已直达公共区(~/Pictures|Movies|Music/SuChat)，无需副本
/// - Android：主存储在私有区(AI_GEN/...)，副本经 MediaStore 写入
///   公共媒体集合(Pictures/Music)，卸载不清
/// - iOS：副本保存到系统相册(需一次性授权，拒绝则仅私有区)
///
/// 双写只针对"AI 生成媒体"(AI_GEN 家族)；NET_DL 浏览缓存/VOICE_REC 录音
/// /FILE_PICK 附件不进公共区(避免污染相册)。
class MediaSaveService {
  /// 用户拒绝相册权限后，本次会话不再尝试写公共区
  static bool _sessionDisabled = false;

  static const Set<String> _imageExts = {
    '.png',
    '.jpg',
    '.jpeg',
    '.webp',
    '.gif',
    '.bmp',
  };
  static const Set<String> _videoExts = {
    '.mp4',
    '.mov',
    '.mkv',
    '.avi',
    '.webm',
  };

  /// 生成/下载媒体落盘后的钩子：路径位于 AI_GEN 家族时异步写公共区副本
  ///
  /// 非阻塞、失败静默(不影响主流程)；所有生成媒体写盘点在写完文件后调用。
  static void onFileSaved(String? path) {
    if (path == null || path.isEmpty) return;
    if (_sessionDisabled) return;
    if (!_isGeneratedMediaPath(path)) return;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) return;

    copyToPublicArea(path).then(
      (_) {},
      onError: (Object e) {
        print('[MediaSaveService] 公共区副本写入失败: $e');
      },
    );
  }

  /// 判断是否 AI 生成媒体路径(AI_GEN 家族)
  static bool _isGeneratedMediaPath(String path) {
    final norm = path.replaceAll('\\', '/');
    return norm.contains('/AI_GEN/');
  }

  /// 把已存在的文件写入公共媒体区(MediaStore/相册)，返回是否成功
  ///
  /// 注意：photo_manager 不支持音频保存，移动端音频副本暂不实现
  /// (由备份包的小媒体区兜底保全)；桌面音频目录函数已直达 ~/Music/SuChat。
  static Future<bool> copyToPublicArea(String path) async {
    try {
      if (_sessionDisabled) return false;
      final file = File(path);
      if (!file.existsSync()) return false;

      final ext = p.extension(path).toLowerCase();
      final name = p.basename(path);

      if (_imageExts.contains(ext)) {
        await PhotoManager.editor.saveImage(
          await file.readAsBytes(),
          filename: name,
          title: name,
        );
        return true;
      } else if (_videoExts.contains(ext)) {
        await PhotoManager.editor.saveVideo(file, title: name);
        return true;
      }
      // 音频：photo_manager 不支持 saveAudio，跳过
      return false;
    } catch (e) {
      // iOS 相册权限被拒等：本次会话停用，避免反复弹窗
      final msg = e.toString();
      if (msg.contains('denied') ||
          msg.contains('Denied') ||
          msg.contains('权限') ||
          msg.contains('permission')) {
        _sessionDisabled = true;
      }
      print('[MediaSaveService] 写入公共区异常: $e');
      return false;
    }
  }
}
