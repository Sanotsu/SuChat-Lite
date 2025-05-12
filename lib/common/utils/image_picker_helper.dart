import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'tools.dart';

///
/// 2025-05-08 文件选择器帮助类
/// 和使用file_picker类似，image_picker默认将文件保存到应用缓存目录下，备份或时移除应用后文件会丢失
/// 所以需要将文件保存到指定目录，并提供清除指定目录的功能，这样备份恢复或者卸载重新安装后文件不会丢失
///

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// 从相册选择单张图片并保存到指定目录
  /// [saveDir] - 指定保存目录路径，为null时使用通用图片保存目录
  /// [customFileName] - 自定义文件名，为null时使用原文件名
  /// [quality] - 图片质量(0-100)
  /// [maxWidth/maxHeight] - 图片最大宽高
  static Future<File?> pickSingleImage({
    String? saveDir,
    String? customFileName,
    int quality = 80,
    double? maxWidth,
    double? maxHeight,
    bool overwrite = false,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (image == null) return null;

      return await _saveXFileReturnFile(
        xfile: image,
        saveDir: saveDir,
        customFileName: customFileName,
        overwrite: overwrite,
      );
    } catch (e) {
      pl.e('从相册选择图片错误: $e');
      return null;
    }
  }

  /// 从相册选择多张图片并保存到指定目录
  /// 返回保存在目标位置的XFile列表
  static Future<List<File>> pickMultipleImages({
    String? saveDir,
    int quality = 80,
    double? maxWidth,
    double? maxHeight,
    bool requestFullMetadata = true,
    bool overwrite = false,
  }) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        requestFullMetadata: requestFullMetadata,
      );

      if (images.isEmpty) return [];

      Directory targetDir = await _getTargetDirectory(saveDir);
      List<File> savedFiles = [];

      for (XFile image in images) {
        final savedFile = await _saveXFileReturnFile(
          xfile: image,
          saveDir: targetDir.path,
          overwrite: overwrite,
        );
        if (savedFile != null) {
          savedFiles.add(savedFile);
        }
      }
      return savedFiles;
    } catch (e) {
      pl.e('选择多张图片错误: $e');
      return [];
    }
  }

  /// 拍照并保存到指定目录
  static Future<File?> takePhotoAndSave({
    String? saveDir,
    String? customFileName,
    int quality = 80,
    double? maxWidth,
    double? maxHeight,
    bool overwrite = false,
  }) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo == null) return null;

      return await _saveXFileReturnFile(
        xfile: photo,
        saveDir: saveDir,
        customFileName: customFileName,
        overwrite: overwrite,
      );
    } catch (e) {
      pl.e('拍照保存错误: $e');
      return null;
    }
  }

  /// 拍摄或选择视频
  static Future<File?> pickVideo({
    ImageSource source = ImageSource.gallery,
    String? saveDir,
    String? customFileName,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
    bool overwrite = false,
  }) async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: source,
        preferredCameraDevice: preferredCameraDevice,
        maxDuration: maxDuration,
      );

      if (video == null) return null;

      return await _saveXFileReturnFile(
        xfile: video,
        saveDir: saveDir,
        customFileName: customFileName,
        overwrite: overwrite,
      );
    } catch (e) {
      pl.e('选择视频错误: $e');
      return null;
    }
  }

  /// 保存XFile到指定位置返回File
  static Future<File?> _saveXFileReturnFile({
    required XFile xfile,
    String? saveDir,
    String? customFileName,
    bool overwrite = false,
  }) async {
    try {
      // 获取目标目录
      Directory targetDir = await _getTargetDirectory(saveDir);

      // 确定文件名
      String fileName = customFileName ?? xfile.name;
      String filePath = path.join(targetDir.path, fileName);

      // 检查文件是否已存在(如果存在且overwrite为false，则返回原文件)
      if (await File(filePath).exists() && !overwrite) {
        // throw Exception('文件已存在: $filePath');
        return File(filePath);
      }

      // 读取原始文件字节
      final data = await xfile.readAsBytes();

      // 写入到新位置
      File newFile = File(filePath);
      await newFile.writeAsBytes(data);

      return newFile;
    } catch (e) {
      pl.e('保存文件错误: $e');
      return null;
    }
  }

  /// 保存XFile到指定位置并返回新位置的XFile(暂统一风格返回File)
  static Future<XFile?> saveXFileReturnXFile({
    required XFile xfile,
    String? saveDir,
    String? customFileName,
    bool overwrite = false,
  }) async {
    try {
      Directory targetDir = await _getTargetDirectory(saveDir);

      String fileName = customFileName ?? xfile.name;
      String filePath = path.join(targetDir.path, fileName);

      // 检查文件是否已存在(如果存在且overwrite为false，则返回原文件)
      if (await File(filePath).exists() && !overwrite) {
        // throw Exception('文件已存在: $filePath');
        return XFile(filePath);
      }

      // 将文件保存到新位置
      File newFile = File(filePath);
      await newFile.writeAsBytes(await xfile.readAsBytes());

      // 返回新位置的XFile
      return XFile(newFile.path);
    } catch (e) {
      pl.e('保存文件错误: $e');
      return null;
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
        targetDir = await getImagePickerSaveDir();
      } catch (e) {
        // 默认使用应用文档目录下的'image_picker_files'子目录
        Directory appDocDir = await getApplicationDocumentsDirectory();
        targetDir = Directory(path.join(appDocDir.path, 'image_picker_files'));
      }
    }

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    return targetDir;
  }

  /// 清除图片目录
  static Future<void> clearImageDirectory({String? directoryPath}) async {
    try {
      Directory dir = await _getTargetDirectory(directoryPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create();
      }
    } catch (e) {
      pl.e('清除图片目录错误: $e');
    }
  }
}

/// 避免在使用的地方再次引入image_picker库，这里自定义封装一些类型
enum CusImageSource { camera, gallery }

const Map imageSourceValues = {
  CusImageSource.camera: ImageSource.camera,
  CusImageSource.gallery: ImageSource.gallery,
};
