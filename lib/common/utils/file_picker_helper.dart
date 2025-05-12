import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'tools.dart';

///
/// 2025-05-08 文件选择器帮助类
/// 因为使用file_picker时默认将文件保存到应用缓存目录下，备份或时移除应用后文件会丢失
/// 所以需要将文件保存到指定目录，并提供清除指定目录的功能，这样备份恢复或者卸载重新安装后文件不会丢失
///
class FilePickerHelper {
  /// 选择单个文件并保存到指定目录
  /// [allowedExtensions] - 允许的文件扩展名列表，如 ['pdf', 'docx']
  /// [saveDir] - 指定保存目录路径，为null时使用通用文件保存目录
  /// [customFileName] - 自定义文件名，为null时使用原文件名
  /// [overwrite] - 是否覆盖同名文件
  static Future<File?> pickAndSaveFile({
    List<String>? allowedExtensions,
    String? saveDir,
    String? customFileName,
    CusFileType? fileType,
    bool overwrite = false,
  }) async {
    try {
      // 选择文件
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: fileType != null ? fileTypeValues[fileType] : FileType.any,
        allowedExtensions: allowedExtensions,
      );

      if (result == null || result.files.isEmpty) return null;

      PlatformFile platformFile = result.files.first;
      if (platformFile.path == null) return null;

      // 确定保存目录
      Directory targetDir = await _getTargetDirectory(saveDir);

      // 确定文件名
      String fileName = customFileName ?? platformFile.name;
      String filePath = path.join(targetDir.path, fileName);

      // 检查文件是否已存在
      if (await File(filePath).exists() && !overwrite) {
        // throw Exception('文件已存在: $filePath');
        return File(filePath);
      }

      // 复制文件到目标位置
      File originalFile = File(platformFile.path!);
      File savedFile = await originalFile.copy(filePath);

      return savedFile;
    } catch (e) {
      pl.e('文件选择保存错误: $e');
      rethrow;
    }
  }

  /// 选择多个文件并保存到指定目录
  static Future<List<File>> pickAndSaveMultipleFiles({
    List<String>? allowedExtensions,
    String? saveDir,
    CusFileType? fileType,
    bool overwrite = false,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: fileType != null ? fileTypeValues[fileType] : FileType.any,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return [];

      Directory targetDir = await _getTargetDirectory(saveDir);
      List<File> savedFiles = [];

      for (PlatformFile platformFile in result.files) {
        if (platformFile.path == null) continue;

        String filePath = path.join(targetDir.path, platformFile.name);

        if (await File(filePath).exists() && !overwrite) {
          continue;
        }

        File originalFile = File(platformFile.path!);
        File savedFile = await originalFile.copy(filePath);
        savedFiles.add(savedFile);
      }

      return savedFiles;
    } catch (e) {
      pl.e('多文件选择保存错误: $e');
      rethrow;
    }
  }

  /// 获取目标目录
  static Future<Directory> _getTargetDirectory(String? customPath) async {
    Directory targetDir;

    if (customPath != null) {
      targetDir = Directory(customPath);
    } else {
      try {
        // 默认使用预定好的通用文件选择目录
        targetDir = await getFilePickerSaveDir();
      } catch (e) {
        // 创建报错则使用应用文档目录下的'file_picker_files'子目录
        Directory appDocDir = await getApplicationDocumentsDirectory();
        targetDir = Directory(path.join(appDocDir.path, 'file_picker_files'));
      }
    }

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    return targetDir;
  }

  /// 清除指定目录中的文件
  /// 因为默认是统一文件选择的目录，各个功能放在同一个位置，所以尽量不调用清除
  static Future<void> clearDirectory({String? directoryPath}) async {
    try {
      Directory dir = await _getTargetDirectory(directoryPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create();
      }
    } catch (e) {
      pl.e('清除目录错误: $e');
    }
  }
}

/// 避免在使用的地方再次引入file_picker库，这里自定义封装一些类型
enum CusFileType { any, media, image, video, audio, custom }

const Map fileTypeValues = {
  CusFileType.any: FileType.any,
  CusFileType.media: FileType.media,
  CusFileType.image: FileType.image,
  CusFileType.video: FileType.video,
  CusFileType.audio: FileType.audio,
  CusFileType.custom: FileType.custom,
};
