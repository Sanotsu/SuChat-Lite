// ignore_for_file: constant_identifier_names

import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../shared/widgets/toast_utils.dart';
import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../../../shared/constants/constants.dart';
import '../../../../core/utils/screen_helper.dart';
import '../../../../core/utils/get_dir.dart';

abstract class MimeMediaManagerBase extends StatefulWidget {
  const MimeMediaManagerBase({super.key});
}

abstract class MimeMediaManagerBaseState<T extends MimeMediaManagerBase>
    extends State<T> {
  // 媒体列表
  List<File> mediaList = [];
  // 选中的媒体
  final Set<File> selectedMedia = {};
  // 是否加载中
  bool isLoading = true;
  // 是否多选模式
  bool isMultiSelectMode = false;

  // 子类需要实现的方法
  String get title;
  CusMimeCls get mediaType;
  Widget buildPreviewPage(File file);

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  // 加载媒体文件
  Future<void> _loadMedia() async {
    setState(() => isLoading = true);

    try {
      final files = await classifyFilesByMimeType((await getAIMediaDirName()));

      // print('AI生成$mediaType数量: ${files[mediaType]!.length}');

      // for (var i = 0; i < files[mediaType]!.length; i++) {
      //   print('媒体文件[$i]: ${files[mediaType]![i].path}');
      // }

      if (mounted && files[mediaType]!.isNotEmpty) {
        setState(() => mediaList = files[mediaType]!);
      }
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, "解析AI生成目录失败", e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 添加刷新功能
  Future<void> refreshMediaList() async {
    await _loadMedia();
  }

  // 获取AI生成媒体目录名
  Future<String> getAIMediaDirName() async {
    switch (mediaType) {
      case CusMimeCls.IMAGE:
        return (await getImageGenDir()).path;
      case CusMimeCls.VIDEO:
        return (await getVideoGenDir()).path;
      case CusMimeCls.AUDIO:
        return (await getVoiceGenDir()).path;
    }
  }

  // 分享选中的媒体
  Future<void> _shareSelectedMedia() async {
    try {
      final xFiles = selectedMedia.map((f) => XFile(f.path)).toList();

      if (xFiles.isEmpty) return;

      final result = await SharePlus.instance.share(
        ShareParams(files: xFiles, text: 'SuChat'),
      );

      if (result.status == ShareResultStatus.success) {
        ToastUtils.showSuccess('分享成功!');
      }
    } catch (e) {
      ToastUtils.showError('分享失败: $e', duration: Duration(seconds: 5));
    }
  }

  // 删除选中的媒体
  Future<void> _deleteSelectedMedia() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('确认删除'),
            content: Text('确定要删除选中的${selectedMedia.length}个文件吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('删除'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      // 逐个删除选中的文件
      for (var file in selectedMedia) {
        // 检查文件是否存在
        if (await file.exists()) {
          // 物理删除文件
          await file.delete();
          // 更新状态，从列表中移除已删除的文件
          setState(() {
            mediaList.removeWhere((item) => item == file);
          });
        }
      }

      ToastUtils.showSuccess('删除成功!');
    } catch (e) {
      ToastUtils.showError('删除失败: $e', duration: Duration(seconds: 5));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          // 添加刷新按钮
          if (!isMultiSelectMode)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: refreshMediaList,
            ),
          if (isMultiSelectMode && ScreenHelper.isMobile()) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareSelectedMedia,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelectedMedia,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  isMultiSelectMode = false;
                  selectedMedia.clear();
                });
              },
            ),
          ],
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : buildMediaGrid(),
    );
  }

  // 构建媒体网格
  Widget buildMediaGrid() {
    if (mediaList.isEmpty) {
      return const Center(child: Text('暂无媒体文件'));
    }

    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ScreenHelper.isDesktop() ? 3 : 2,
        childAspectRatio: mediaType == CusMimeCls.AUDIO ? 16 / 9 : 1,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: mediaList.length,
      itemBuilder: (context, index) {
        final file = mediaList[index];
        final isSelected = selectedMedia.contains(file);

        return buildMediaGridItem(file, isSelected);
      },
    );
  }

  // 构建媒体网格项
  Widget buildMediaGridItem(File file, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (isMultiSelectMode) {
          setState(() {
            if (isSelected) {
              selectedMedia.remove(file);
              if (selectedMedia.isEmpty) {
                isMultiSelectMode = false;
              }
            } else {
              selectedMedia.add(file);
            }
          });
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => buildPreviewPage(file)),
          );
        }
      },
      onLongPress: () {
        if (!isMultiSelectMode) {
          setState(() {
            isMultiSelectMode = true;
            selectedMedia.add(file);
          });
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (mediaType == CusMimeCls.VIDEO)
            FutureBuilder<Image?>(
              future: generateThumbnail(file),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return snapshot.data!;
                }
                // return const SizedBox.shrink();
                // 桌面端取不到预览图，就显示个名字
                return Container(
                  color: Colors.grey.shade200,
                  padding: EdgeInsets.all(10),
                  child: Center(
                    child: Text(
                      file.path.split('/').last,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          if (mediaType == CusMimeCls.IMAGE)
            Image.file(file, fit: BoxFit.cover),
          if (isSelected)
            Container(
              color: Colors.blue.withValues(alpha: 0.3),
              alignment: Alignment.center,
              child: Icon(Icons.check_circle, color: Colors.white, size: 30),
            ),
        ],
      ),
    );
  }
}

// 获取指定目录下的所有文件
Future<List<FileSystemEntity>> getFilesFromDirectory(String folderPath) async {
  final directory = Directory(folderPath);

  if (await directory.exists()) {
    return directory.list().toList();
  } else {
    throw Exception("指定目录不存在");
  }
}

/// 获取指定文件下，根据根据mime类型分类的文件对象
Future<Map<CusMimeCls, List<File>>> classifyFilesByMimeType(
  String folderPath,
) async {
  final directory = Directory(folderPath);
  if (!await directory.exists()) {
    throw Exception("指定目录不存在");
  }

  // 获取指定目录下的所有文件
  final files =
      await directory
          .list()
          .where((entity) => entity is File)
          .map((entity) => entity as File)
          .toList();

  // 按照文件的创建时间排序
  files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

  // 根据mime类型分类文件
  final classifiedFiles = <CusMimeCls, List<File>>{
    CusMimeCls.IMAGE: [],
    CusMimeCls.VIDEO: [],
    CusMimeCls.AUDIO: [],
  };

  // 遍历文件，根据mime类型分类
  for (final file in files) {
    final mimeType = lookupMimeType(
      file.path,
      // 读取文件头部字节
      headerBytes: await file.openRead(0, 512).first,
    );

    // print('文件: ${file.path} 的mimeType: $mimeType');

    if (mimeType != null) {
      if (mimeType.startsWith('image/')) {
        classifiedFiles[CusMimeCls.IMAGE]!.add(file);
      } else if (mimeType.startsWith('video/')) {
        classifiedFiles[CusMimeCls.VIDEO]!.add(file);
      } else if (mimeType.startsWith('audio/')) {
        classifiedFiles[CusMimeCls.AUDIO]!.add(file);
      }
    }
  }

  return classifiedFiles;
}

/// 本地缓存视频缩略图
final Map<String, File> _thumbnailCache = {};
final cacheManager = DefaultCacheManager();

// 生成视频缩略图
Future<Image?> generateThumbnail(File videoFile) async {
  // 从缓存获取视频缩略图，key为视频文件路径
  final cacheKey = videoFile.path;
  if (_thumbnailCache.containsKey(cacheKey)) {
    // print('从缓存获取视频缩略图1: ${_thumbnailCache[cacheKey]!.path}');

    return kIsWeb
        ? Image.network(_thumbnailCache[cacheKey]!.path, fit: BoxFit.cover)
        : Image.file(_thumbnailCache[cacheKey]!, fit: BoxFit.cover);
  }

  final cachedFile = await cacheManager.getFileFromCache(cacheKey);
  if (cachedFile != null) {
    _thumbnailCache[cacheKey] = cachedFile.file;

    // print('从缓存获取视频缩略图2: ${cachedFile.file.path}');

    return kIsWeb
        ? Image.network(cachedFile.file.path, fit: BoxFit.cover)
        : Image.file(cachedFile.file, fit: BoxFit.cover);
  }

  // 如果没有缓存，则生成缩略图
  try {
    File thumbnail;

    // 2025-04-24 移动端生成缩略图，桌面端无法使用
    if (ScreenHelper.isMobile()) {
      XFile thumbnailFile = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        // 缓存到临时目录
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        quality: 50, // 图片质量
      );

      thumbnail = File(thumbnailFile.path);
    } else {
      thumbnail = File(placeholderImageUrl);
      return null;
    }

    // 缓存缩略图
    await cacheManager.putFile(cacheKey, thumbnail.readAsBytesSync());
    _thumbnailCache[cacheKey] = thumbnail;

    // print('生成视频缩略图: ${thumbnailFile.path}');

    return kIsWeb
        ? Image.network(thumbnail.path, fit: BoxFit.cover)
        : Image.file(thumbnail, fit: BoxFit.cover);
  } catch (e) {
    debugPrint("生成视频缩略图失败: $e");
    return null;
  }
}
