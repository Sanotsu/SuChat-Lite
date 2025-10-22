// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:proste_logger/proste_logger.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/widgets/toast_utils.dart';
import '../../shared/constants/constants.dart';
import 'get_dir.dart';

/// 全局单例，所有保留print但不想有提示或者使用debugPrint的，都用这个
final pl = ProsteLogger();

/// 请求各种权限
/// 目前存储类的权限要分安卓版本，所以单独处理
/// 查询安卓媒体存储权限和其他权限不能同时进行
Future<bool> requestPermission({
  bool isAndroidMedia = true,
  List<Permission>? list,
}) async {
  // 如果是请求媒体权限
  if (isAndroidMedia) {
    // 2024-01-12 Android13之后，没有storage权限了，取而代之的是：
    // Permission.photos, Permission.videos or Permission.audio等
    // 参看:https://github.com/Baseflow/flutter-permission-handler/issues/1247
    if (Platform.isAndroid) {
      // 获取设备sdk版本
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      int sdkInt = androidInfo.version.sdkInt;

      if (sdkInt <= 32) {
        PermissionStatus storageStatus = await Permission.storage.request();
        return storageStatus.isGranted;
      } else {
        Map<Permission, PermissionStatus> statuses = await [
          // Permission.audio,
          // Permission.photos,
          // Permission.videos,
          Permission.manageExternalStorage,
        ].request();

        return (
        // statuses[Permission.audio]!.isGranted &&
        // statuses[Permission.photos]!.isGranted &&
        // statuses[Permission.videos]!.isGranted &&
        statuses[Permission.manageExternalStorage]!.isGranted);
      }
    } else if (Platform.isIOS) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.mediaLibrary,
        Permission.storage,
      ].request();
      return (statuses[Permission.mediaLibrary]!.isGranted &&
          statuses[Permission.storage]!.isGranted);
    }
    // ??? 还差其他平台的
  }

  // 如果有其他权限需要访问，则一一处理(没有传需要请求的权限，就直接返回成功)
  list = list ?? [];
  if (list.isEmpty) {
    return true;
  }
  Map<Permission, PermissionStatus> statuses = await list.request();
  // 如果每一个都授权了，那就返回授权了
  return list.every((p) => statuses[p]!.isGranted);
}

// 只请求内部存储访问权限(菜品导入、备份还原)
Future<bool> requestStoragePermission() async {
  if (Platform.isAndroid) {
    // 获取设备sdk版本
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    int sdkInt = androidInfo.version.sdkInt;

    if (sdkInt <= 32) {
      var storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    } else {
      var storageStatus = await Permission.manageExternalStorage.request();
      return storageStatus.isGranted;
    }
  } else if (Platform.isIOS) {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.mediaLibrary,
      Permission.storage,
    ].request();
    return (statuses[Permission.mediaLibrary]!.isGranted &&
        statuses[Permission.storage]!.isGranted);
  } else if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    // 桌面应用根据系统权限来
    return true;
  } else {
    // 其他先不考虑
    return false;
  }
}

/// 请求麦克风权限
Future<bool> requestMicrophonePermission() async {
  final state = await Permission.microphone.request();

  return state == PermissionStatus.granted;
}

Future<PermissionStatus> getPermissionMicrophoneStatus() async {
  return await Permission.microphone.status;
}

// 根据数据库拼接的字符串值转回对应选项
List<CusLabel> genSelectedCusLabelOptions(
  String? optionsStr,
  List<CusLabel> cusLabelOptions,
) {
  // 如果为空或者空字符串，返回空列表
  if (optionsStr == null || optionsStr.isEmpty || optionsStr.trim().isEmpty) {
    return [];
  }

  List<String> selectedValues = optionsStr.split(',');
  List<CusLabel> selectedLabels = [];

  for (String selectedValue in selectedValues) {
    for (CusLabel option in cusLabelOptions) {
      if (option.value == selectedValue) {
        selectedLabels.add(option);
      }
    }
  }

  return selectedLabels;
}

// 指定范围内生成一个整数
int generateRandomInt(int min, int max) {
  if (min > max) {
    throw ArgumentError('最小值必须小于或等于最大值。');
  }

  var random = Random();
  // +1 因为 nextInt 包含 min 但不包含 max
  return min + random.nextInt(max - min + 1);
}

// 转换文件大小为字符串显示
String formatFileSize(int bytes, {int decimals = 2}) {
  if (bytes <= 0) return "0 B";
  const suffixes = ["B", "KB", "MB", "GB", "TB"];
  var i = (log(bytes) / log(1024)).floor();
  return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
}

// 将字符串中每个单词的首字母大写
String capitalizeWords(String input) {
  if (input.trim().isEmpty) {
    return input;
  }

  // 使用正则表达式匹配单词的首字母
  return input.replaceAllMapped(RegExp(r'(^|\s|_|-)\w'), (match) {
    // 将匹配到的首字母大写，同时保留前缀（如空格、下划线、中线等）
    return match.group(0)!.toUpperCase();
  });
}

/// 保存文本文件到外部存储(如果是pdf等还需要改造，传入保存方法等)
Future<void> saveTextFileToStorage(
  String text,
  Directory dir,
  String title, {
  String? extension = 'txt',
}) async {
  try {
    // 首先获取设备外部存储管理权限
    if (!(await requestStoragePermission())) {
      return ToastUtils.showError("未授权访问设备外部存储，无法保存文档");
    }

    // 翻译保存的文本，放到设备外部存储固定位置，不存在文件夹则先创建
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final file = File(
      '${dir.path}/$title-${DateTime.now().microsecondsSinceEpoch}.$extension',
    );

    await file.writeAsString(text);

    // 保存成功/失败弹窗提示
    ToastUtils.showSuccess(
      '文档已保存到 ${file.path}',
      duration: const Duration(seconds: 5),
    );
  } catch (e) {
    return ToastUtils.showError(
      "保存文档失败: ${e.toString()}",
      duration: const Duration(seconds: 5),
    );
  }
}

/// 打印长文本(不会截断)
void printWrapped(String text) {
  final pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
  pattern.allMatches(text).forEach((match) => print(match.group(0)));
}

/// 判断字符串是否为json字符串
bool isJsonString(String str) {
  // 去除字符串中的空白字符和注释
  final cleanedStr = str
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll(RegExp(r'//.*'), '');

  try {
    json.decode(cleanedStr);
    return true;
  } on FormatException {
    return false;
  }
}

// 文生图保存base64图片到本地(讯飞云返回的是base64,阿里云、sf返回的是云盘上的地址)
Future<File> saveTtiBase64ImageToLocal(
  String base64Image, {
  String? prefix, // 传前缀要全，比如带上底斜线_
}) async {
  final bytes = base64Decode(base64Image);

  final file = File(
    '${(await getImageGenDir()).path}/${prefix ?? ""}${DateFormat(constDatetimeSuffix).format(DateTime.now())}.png',
  );

  await file.writeAsBytes(bytes);

  return file;
}

// 保存网络图片到本地
Future<String?> saveImageToLocal(
  String netImageUrl, {
  String? prefix,
  String? imageName,
  Directory? dlDir,
  bool showSaveHint = true,
  bool overwriteExisting = false,
}) async {
  // 首先获取设备外部存储管理权限
  if (!(await requestStoragePermission())) {
    ToastUtils.showError("未授权访问设备外部存储，无法保存图片");
    return null;
  }

  // 2024-09-04 文生图片一般有一个随机的名称，就只使用它就好(可以避免同一个保存了多份)
  // 注意，像阿里云这种地址会带上过期日期token信息等参数内容，所以下载保存的文件名要过滤掉，只保留图片地址信息
  // 目前硅基流动、智谱等没有额外信息，问号分割后也不影响
  // 2024-11-04 如果有指定保存的图片名称，则不用从url获取
  imageName ??= netImageUrl.split("?").first.split('/').last;

  dynamic closeToast;
  try {
    // 获取下载目录
    var dir = dlDir ?? (await getImageGenDir());

    // 确保目录存在
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // 构建文件路径 , 传入的前缀有强制带上下划线
    final filePath = '${dir.path}/${prefix ?? ""}$imageName';
    final file = File(filePath);

    // 检查文件是否已存在
    final bool fileExists = await file.exists();

    if (fileExists && !overwriteExisting) {
      // 文件已存在且不覆盖，直接返回现有文件路径
      if (showSaveHint) {
        ToastUtils.showToast("图片已存在，无需重复下载");
      }
      return filePath;
    }

    if (showSaveHint) {
      closeToast = ToastUtils.showLoading('【图片保存中...】');
    }

    // 下载图片
    var response = await Dio().get(
      netImageUrl,
      options: Options(responseType: ResponseType.bytes),
    );

    // 写入文件
    await file.writeAsBytes(response.data);

    if (showSaveHint) {
      if (closeToast != null) {
        closeToast();
      }
      if (fileExists && overwriteExisting) {
        ToastUtils.showToast("图片已覆盖保存在手机下/${file.path.split("/0/").last}");
      } else {
        ToastUtils.showToast("图片已保存在手机下/${file.path.split("/0/").last}");
      }
    }

    return file.path;
  } catch (e) {
    // 异常处理
    if (showSaveHint && closeToast != null) {
      closeToast();
    }
    ToastUtils.showError("图片保存失败: ${e.toString()}");
    return null;
  } finally {
    if (showSaveHint && closeToast != null) {
      closeToast();
    }
  }
}

// 2025-10-09 实测图片、音频等都可以下载，可以混用
Future<String?> saveNetMediaToLocal(
  String netMediaUrl, {
  String? prefix,
  String? mediaName,
  Directory? dlDir,
  bool showSaveHint = true,
  bool overwriteExisting = false,
}) async {
  // 首先获取设备外部存储管理权限
  if (!(await requestStoragePermission())) {
    ToastUtils.showError("未授权访问设备外部存储，无法保存图片");
    return null;
  }

  // 如果有指定保存的图片名称，则不用从url获取;需要过滤地址带有过期日期token信息等额外内容
  mediaName ??= netMediaUrl.split("?").first.split('/').last;

  dynamic closeToast;

  // 使用直接的Dio实例下载音频内容并保存到文件
  final dio = Dio();
  try {
    // 获取下载目录
    var dir = dlDir ?? (await getDioDownloadDir());

    // 确保目录存在
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // 构建文件路径 , 传入的前缀有强制带上下划线
    final filePath = '${dir.path}/${prefix ?? ""}$mediaName';
    final file = File(filePath);

    // 检查文件是否已存在
    final bool fileExists = await file.exists();

    if (fileExists && !overwriteExisting) {
      // 文件已存在且不覆盖，直接返回现有文件路径
      if (showSaveHint) {
        ToastUtils.showToast("资源已存在，无需重复下载");
      }
      return filePath;
    }

    if (showSaveHint) {
      closeToast = ToastUtils.showLoading('【资源保存中...】');
    }

    // 下载资源
    final mediaResponse = await dio.get(
      netMediaUrl,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
        validateStatus: (status) => status != null && status < 500,
      ),
      onReceiveProgress: (received, total) {
        if (total != -1) {
          debugPrint('下载进度: ${(received / total * 100).toStringAsFixed(0)}%');
        }
      },
    );

    if (mediaResponse.statusCode != 200) {
      throw Exception('下载资源失败: ${mediaResponse.statusCode}');
    }

    // 写入文件
    await file.writeAsBytes(mediaResponse.data);

    if (showSaveHint) {
      if (closeToast != null) {
        closeToast();
      }
      if (fileExists && overwriteExisting) {
        ToastUtils.showToast("资源已覆盖保存在手机下/${file.path.split("/0/").last}");
      } else {
        ToastUtils.showToast("资源已保存在手机下/${file.path.split("/0/").last}");
      }
    }

    return file.path;
  } finally {
    dio.close();
  }
}

/// 保存多张图片到本地
Future<List<String?>> saveMultipleImagesToLocal(
  List<String> netImageUrls, {
  String? prefix,
  List<String>? imageNames,
  Directory? dlDir,
  bool showSaveHint = true,
  bool overwriteExisting = false,
  bool stopOnError = false, // 是否在遇到错误时停止
  Function(int, int)? onProgress, // 进度回调 (当前进度, 总数)
}) async {
  // 首先获取设备外部存储管理权限
  if (!(await requestStoragePermission())) {
    ToastUtils.showError("未授权访问设备外部存储，无法保存图片");
    return List.filled(netImageUrls.length, null);
  }

  final List<String?> results = [];
  int successCount = 0;
  int failCount = 0;

  dynamic closeToast;

  try {
    if (showSaveHint) {
      closeToast = ToastUtils.showLoading('准备保存${netImageUrls.length}张图片...');
    }

    // 获取下载目录
    var dir = dlDir ?? (await getImageGenDir());
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    for (int i = 0; i < netImageUrls.length; i++) {
      final String url = netImageUrls[i];
      final String? customName = imageNames != null && i < imageNames.length
          ? imageNames[i]
          : null;

      try {
        if (showSaveHint && closeToast != null) {
          closeToast();
          closeToast = ToastUtils.showLoading(
            '正在保存第${i + 1}/${netImageUrls.length}张图片...',
          );
        }

        // 调用单张图片保存函数
        final String? result = await saveImageToLocal(
          url,
          prefix: prefix,
          imageName: customName,
          dlDir: dir,
          showSaveHint: false, // 不在内部显示提示，由本函数统一处理
          overwriteExisting: overwriteExisting,
        );

        results.add(result);

        if (result != null) {
          successCount++;
        } else {
          failCount++;
          if (stopOnError) {
            break; // 遇到错误时停止
          }
        }

        // 进度回调
        onProgress?.call(i + 1, netImageUrls.length);
      } catch (e) {
        results.add(null);
        failCount++;
        if (stopOnError) {
          break; // 遇到错误时停止
        }
      }
    }

    // 显示最终结果
    if (showSaveHint) {
      if (closeToast != null) {
        closeToast();
      }

      if (successCount == netImageUrls.length) {
        ToastUtils.showToast("所有图片保存成功 ($successCount张)");
      } else if (successCount > 0) {
        ToastUtils.showToast("图片保存完成: 成功 $successCount张, 失败 $failCount张");
      } else {
        ToastUtils.showError("图片保存失败");
      }
    }

    return results;
  } catch (e) {
    if (showSaveHint && closeToast != null) {
      closeToast();
      ToastUtils.showError("批量保存失败: ${e.toString()}");
    }
    // 确保返回列表长度与输入一致
    while (results.length < netImageUrls.length) {
      results.add(null);
    }
    return results;
  } finally {
    if (showSaveHint && closeToast != null) {
      closeToast();
    }
  }
}

/// 批量保存图片的简化版本（不显示详细进度）
Future<List<String?>> saveImagesInBackground(
  List<String> netImageUrls, {
  String? prefix,
  Directory? dlDir,
  bool overwriteExisting = false,
}) async {
  return await saveMultipleImagesToLocal(
    netImageUrls,
    prefix: prefix,
    dlDir: dlDir,
    showSaveHint: false, // 不显示提示
    overwriteExisting: overwriteExisting,
    stopOnError: false,
  );
}

// 保存文生视频的视频到本地
Future<String?> saveVideoToLocal(
  String netVideoUrl, {
  String? prefix,
  // 指定保存的名称，比如 xxx.png
  String? videoName,
  Directory? dlDir,
  // 是否显示保存提示
  bool showSaveHint = true,
}) async {
  // 首先获取设备外部存储管理权限
  if (!(await requestStoragePermission())) {
    ToastUtils.showError("未授权访问设备外部存储，无法保存视频");
    return null;
  }

  videoName ??= netVideoUrl.split("?").first.split('/').last;

  dynamic closeToast;
  try {
    var dir = dlDir ?? (await getVideoGenDir());

    // 2024-08-17 直接保存文件到指定位置
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    // 2024-09-04 智谱文生视频有一个随机的名称，就只使用它就好(可以避免同一个视频保存了多个)
    final filePath = '${dir.path}/${prefix ?? ""}$videoName';

    if (showSaveHint) {
      closeToast = ToastUtils.showLoading('【视频保存中...】');
    }
    await Dio().download(netVideoUrl, filePath);

    // 保存的地址在 /storage/emulated/0/SuChatFiles/…… 前面一节就不显示了
    if (showSaveHint && closeToast != null) {
      closeToast();
      ToastUtils.showToast("视频已保存在手机下/${filePath.split("/0/").last}");
    }

    return filePath;
  } finally {
    if (showSaveHint && closeToast != null) {
      closeToast();
    }
  }

  // 用这个自定义的，阿里云地址会报403错误，原因不清楚
  // var respData = await HttpUtils.get(
  //   path: netImageUrl,
  //   showLoading: true,
  //   responseType: CusRespType.bytes,
  // );

  // await file.writeAsBytes(respData);
  // ToastUtils.showToast("图片已保存${file.path}");
}

/// 获取网络图片的base64字符串
Future<String> getBase64FromNetworkImage(String imageUrl) async {
  // 下载图片
  var response = await Dio().get(
    imageUrl,
    options: Options(responseType: ResponseType.bytes),
  );

  if (response.statusCode == 200) {
    // 获取应用的临时目录
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/temp_image.png';

    // 将图片保存为文件
    final file = File(filePath);
    await file.writeAsBytes(response.data);

    // 读取文件并转换为 Base64 字符串
    final bytes = await file.readAsBytes();
    final base64String = base64Encode(bytes);

    // 删除临时文件
    await file.delete();

    return base64String;
  } else {
    throw Exception('加载图片失败');
  }
}

// 保存文生视频的视频到本地
Future<void> savevgVideoToLocal(String netVideoUrl, {String? prefix}) async {
  // 首先获取设备外部存储管理权限
  if (!(await requestStoragePermission())) {
    return ToastUtils.showError("未授权访问设备外部存储，无法保存视频");
  }

  dynamic closeToast;
  try {
    // 2024-08-17 直接保存文件到指定位置
    // 2024-09-04 智谱文生视频有一个随机的名称，就只使用它就好(可以避免同一个视频保存了多个)
    final filePath =
        '${(await getVideoGenDir()).path}/${prefix ?? ""}_${netVideoUrl.split('/').last}';

    closeToast = ToastUtils.showLoading('【视频保存中...】');
    await Dio().download(netVideoUrl, filePath);

    closeToast();
    // 保存的地址在 /storage/emulated/0/SuChatFiles/…… 前面一节就不显示了
    ToastUtils.showToast("视频已保存在手机下/${filePath.split("/0/").last}");
  } finally {
    if (closeToast != null) {
      closeToast();
    }
  }

  // 用这个自定义的，阿里云地址会报403错误，原因不清楚
  // var respData = await HttpUtils.get(
  //   path: netImageUrl,
  //   showLoading: true,
  //   responseType: CusRespType.bytes,
  // );

  // await file.writeAsBytes(respData);
  // ToastUtils.showToast("图片已保存${file.path}");
}

/// 获取图片的base64编码
Future<String?> getImageBase64String(File? image) async {
  if (image == null) return null;
  var tempStr = base64Encode(await image.readAsBytes());
  return "data:${lookupMimeType(image.path)};base64,$tempStr";
}

///
/// 通用的查询任务状态的方法
/// 就是先提交了task，然后默认会查询task，这里就是等待查询结果的方法
/// 2024-09-02 目前阿里云的文生图、智谱的文生视频都会用到
Future<T?> timedTaskStatus<T>(
  String taskId,
  Function onTimeOut,
  Duration maxWaitDuration,
  Future<T> Function(String) queryTaskStatus,
  bool Function(T) isTaskComplete,
) async {
  bool isMaxWaitTimeExceeded = false;

  Timer timer = Timer(maxWaitDuration, () {
    onTimeOut();

    ToastUtils.showError("生成超时，请稍候重试！", duration: const Duration(seconds: 5));

    isMaxWaitTimeExceeded = true;
    debugPrint('任务处理耗时，状态查询终止。');
  });

  bool isRequestSuccessful = false;
  while (!isRequestSuccessful && !isMaxWaitTimeExceeded) {
    try {
      var result = await queryTaskStatus(taskId);

      if (isTaskComplete(result)) {
        isRequestSuccessful = true;
        debugPrint('任务处理完成!');
        timer.cancel();

        return result;
      } else {
        debugPrint('任务还在处理中，请稍候重试……');
        await Future.delayed(const Duration(seconds: 5));
      }
    } catch (e) {
      debugPrint('发生异常: $e');
      await Future.delayed(const Duration(seconds: 5));
    }
  }
  return null;
}

/// 是否是有效的网络图片地址
Future<bool> isValidImageUrl(String url) async {
  final dio = Dio(); // 创建 Dio 实例
  try {
    // 发送 HEAD 请求
    final response = await dio.head(url);
    // 检查响应头中的 content-type
    final contentType = response.headers['content-type']?.first;
    return contentType != null && contentType.startsWith('image/');
  } catch (e) {
    return false; // 如果发生异常，返回 false
  }
}

// 从assets中获取文件(好像不太对？？？)
Future<File> getImageFileFromAssets(String assetPath) async {
  try {
    // 1. 加载字节数据
    final byteData = await rootBundle.load(assetPath);

    // 2. 获取应用临时目录
    final tempDir = await getTemporaryDirectory();

    // 3. 创建目标文件
    final file = File('${tempDir.path}/${assetPath.split('/').last}');

    // 4. 将字节数据写入文件
    await file.writeAsBytes(
      byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      ),
    );

    return file;
  } catch (e) {
    print('Error getting file from assets: $e');
    throw Exception('Failed to get file from assets');
  }
}

// 调用外部浏览器打开url
Future<void> launchStringUrl(String url) async {
  if (!await launchUrl(
    Uri.parse(url),
    // mode: LaunchMode.externalApplication,
    // mode: LaunchMode.inAppBrowserView,
    // browserConfiguration: const BrowserConfiguration(showTitle: true),
  )) {
    throw Exception('无法访问 $url');
  }
}

void cusLaunchUrl(String url) async {
  try {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    ToastUtils.showError('无法打开链接: $url, 错误: $e');
  }
}

/// 根据文件路径获取MIME类型
String? getMimeTypeByFilePath(String filePath) {
  final extension = filePath.toLowerCase().split('.').last;
  switch (extension) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    case 'mp3':
      return 'audio/mpeg';
    case 'wav':
      return 'audio/wav';
    case 'mp4':
      return 'video/mp4';
    case 'avi':
      return 'video/avi';
    case 'pdf':
      return 'application/pdf';
    case 'txt':
      return 'text/plain';
    case 'doc':
    case 'docx':
      return 'application/msword';
    case 'xls':
    case 'xlsx':
      return 'application/vnd.ms-excel';
    case 'ppt':
    case 'pptx':
      return 'application/vnd.ms-powerpoint';
    default:
      return 'application/octet-stream';
  }
}

/// 获取文件大小
Future<int?> getFileSize(File file) async {
  try {
    if (await file.exists()) {
      return await file.length();
    }
  } catch (e) {
    print('获取文件大小失败: $e');
  }
  return null;
}

///
/// 将图片或视频转换为base64格式
///
String convertToBase64(String fileUrl, {String fileType = 'image'}) {
  // 如果已经是base64格式的，直接返回
  if (fileType == 'image' && fileUrl.startsWith('data:image/')) {
    return fileUrl;
  }
  if (fileType == 'video' && fileUrl.startsWith('data:video/')) {
    return fileUrl;
  }
  if (fileType == 'audio' && fileUrl.startsWith('data:audio/')) {
    return fileUrl;
  }

  // 如果是网络图片/视频，直接返回URL
  if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
    return fileUrl;
  }

  // 如果是本地文件，转换为base64
  try {
    final file = File(fileUrl);
    if (file.existsSync()) {
      final bytes = file.readAsBytesSync();
      final base64String = base64Encode(bytes);
      final mimeType = lookupMimeType(file.path);

      return 'data:$mimeType;base64,$base64String';
    }
  } catch (e) {
    print('转换图片到base64失败: $e');
  }

  // 如果转换失败，返回原始URL
  return fileUrl;
}
