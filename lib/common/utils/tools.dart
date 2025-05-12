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
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:proste_logger/proste_logger.dart';

import '../components/toast_utils.dart';
import '../constants/constants.dart';
import 'screen_helper.dart';

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
        Map<Permission, PermissionStatus> statuses =
            await [
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
      Map<Permission, PermissionStatus> statuses =
          await [Permission.mediaLibrary, Permission.storage].request();
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
      return (storageStatus.isGranted);
    }
  } else if (Platform.isIOS) {
    Map<Permission, PermissionStatus> statuses =
        await [Permission.mediaLibrary, Permission.storage].request();
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

String getTimePeriod() {
  DateTime now = DateTime.now();
  if (now.hour >= 0 && now.hour < 9) {
    return '早餐';
  } else if (now.hour >= 9 && now.hour < 11) {
    return '早茶';
  } else if (now.hour >= 11 && now.hour < 14) {
    return '午餐';
  } else if (now.hour >= 14 && now.hour < 16) {
    return '下午茶';
  } else if (now.hour >= 16 && now.hour < 20) {
    return '晚餐';
  } else {
    return '夜宵';
  }
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

/// 格式化Duration为 HH:MM:SS格式
formatDurationToString(Duration d) =>
    d.toString().split('.').first.padLeft(8, "0");

String formatDurationToString2(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
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

// 保存文生图的图片到本地
Future<String?> saveImageToLocal(
  String netImageUrl, {
  String? prefix,
  // 指定保存的名称，比如 xxx.png
  String? imageName,
  Directory? dlDir,
  // 是否显示保存提示
  bool showSaveHint = true,
}) async {
  // 首先获取设备外部存储管理权限
  if (!(await requestStoragePermission())) {
    ToastUtils.showError("未授权访问设备外部存储，无法保存图片");

    return null;
  }

  // print("原图片地址---$netImageUrl");

  // 2024-09-04 文生图片一般有一个随机的名称，就只使用它就好(可以避免同一个保存了多份)
  // 注意，像阿里云这种地址会带上过期日期token信息等参数内容，所以下载保存的文件名要过滤掉，只保留图片地址信息
  // 目前硅基流动、智谱等没有额外信息，问号分割后也不影响
  // 2024-11-04 如果有指定保存的图片名称，则不用从url获取
  imageName ??= netImageUrl.split("?").first.split('/').last;

  // print("新获取的图片地址---$imageName");

  dynamic closeToast;
  try {
    // 2024-09-14 支持自定义下载的文件夹
    var dir = dlDir ?? (await getImageGenDir());

    // 2024-08-17 直接保存文件到指定位置
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // 传入的前缀有强制带上下划线
    final file = File('${dir.path}/${prefix ?? ""}$imageName');

    if (showSaveHint) {
      closeToast = ToastUtils.showLoading('【图片保存中...】');
    }

    var response = await Dio().get(
      netImageUrl,
      options: Options(responseType: ResponseType.bytes),
    );

    await file.writeAsBytes(response.data);

    if (showSaveHint && closeToast != null) {
      closeToast();
      ToastUtils.showToast("图片已保存在手机下/${file.path.split("/0/").last}");
    }

    return file.path;
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
savevgVideoToLocal(String netVideoUrl, {String? prefix}) async {
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
  return "data:image/png;base64,$tempStr";
}

String formatTimeAgo(String timeString) {
  if (timeString.isEmpty) return "未知";

  DateTime dateTime = DateTime.parse(timeString);
  DateTime now = DateTime.now();
  Duration difference = now.difference(dateTime);

  if (difference.inDays > 365) {
    int years = (difference.inDays / 365).floor();
    return '$years年前';
  } else if (difference.inDays > 30) {
    int months = (difference.inDays / 30).floor();
    return '$months月前';
  } else if (difference.inDays > 0) {
    return '${difference.inDays}天前';
  } else if (difference.inHours > 0) {
    return '${difference.inHours}小时前';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes}分钟前';
  } else {
    return '${difference.inSeconds}秒前';
  }
}

// 英文显示有单数复数之分
String formatTimeAgoEn(String timeString) {
  DateTime dateTime = DateTime.parse(timeString);
  DateTime now = DateTime.now();
  Duration difference = now.difference(dateTime);

  if (difference.inDays > 365) {
    int years = (difference.inDays / 365).floor();
    return '$years year${years > 1 ? 's' : ''} ago';
  } else if (difference.inDays > 30) {
    int months = (difference.inDays / 30).floor();
    return '$months month${months > 1 ? 's' : ''} ago';
  } else if (difference.inDays > 0) {
    return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
  } else if (difference.inHours > 0) {
    return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
  } else {
    return '${difference.inSeconds} second${difference.inSeconds > 1 ? 's' : ''} ago';
  }
}

// 把各种时间字符串格式化指定格式的字符串
String formatDateTimeString(String timeString, {String? formatType}) {
  if (timeString.isEmpty) return "未知";

  return DateFormat(
    formatType ?? constDatetimeFormat,
  ).format(DateTime.tryParse(timeString) ?? DateTime.now());
}

// 10位的时间戳转字符串
String formatTimestampToString(String? timestamp, {String? format}) {
  if (timestamp == null || timestamp.isEmpty) {
    return "";
  }

  if (timestamp.trim().length == 10) {
    timestamp = "${timestamp}000";
  }

  if (timestamp.trim().length != 13) {
    return "输入的时间戳不是10位或者13位的整数";
  }

  return DateFormat(format ?? constDatetimeFormat).format(
    DateTime.fromMillisecondsSinceEpoch(
      // 如果传入的时间戳字符串转型不对，就使用 1970-01-01 23:59:59 的毫秒数
      int.tryParse(timestamp) ?? 57599000,
    ),
  );
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
    debugPrint('获取应用目录失败: $e');
    // 回退方案：使用临时目录
    final tempDir = await getTemporaryDirectory();
    return Directory(p.join(tempDir.path, 'SuChatFallback'));
  }
}

/// 获取不同平台的可访问目录
Future<Directory> getAppSubDir(String folderName) async {
  print("path_provider 获取到的各个目录地址(始)=======================");

  if (ScreenHelper.isDesktop() || ScreenHelper.isMobile()) {
    print('getTemporaryDirectory--> ${await getTemporaryDirectory()}');

    print(
      'getApplicationSupportDirectory--> ${await getApplicationSupportDirectory()}',
    );
    print(
      'getApplicationDocumentsDirectory--> ${await getApplicationDocumentsDirectory()}',
    );
    print(
      'getApplicationCacheDirectory--> ${await getApplicationCacheDirectory()}',
    );
    print('getDownloadsDirectory--> ${await getDownloadsDirectory()}');
  }

  if (Platform.isAndroid) {
    print(
      'getExternalStorageDirectory--> ${await getExternalStorageDirectory()}',
    );
    print(
      'getExternalCacheDirectories--> ${await getExternalCacheDirectories()}',
    );
    print(
      'getExternalStorageDirectories--> ${await getExternalStorageDirectories()}',
    );
  }

  if (Platform.isIOS || Platform.isMacOS) {
    print('getLibraryDirectory--> ${await getLibraryDirectory()}');
  }

  print("path_provider 获取到的各个目录地址(完)=======================");

  return getAppHomeDirectory(subfolder: folderName);
}

/// 获取sqlite数据库文件保存的目录
Future<Directory> getSqliteDbDir() async {
  return getAppHomeDirectory(subfolder: "sqlite_db");
}

/// 语音输入时，录音文件保存的目录
Future<Directory> getChatAudioDir() async {
  return getAppHomeDirectory(subfolder: "chat_audio");
}

/// 图片生成时，图片文件保存的目录
Future<Directory> getImageGenDir() async {
  return getAppHomeDirectory(subfolder: "image_generation");
}

/// 视频生成时，视频文件保存的目录
Future<Directory> getVideoGenDir() async {
  return getAppHomeDirectory(subfolder: "video_generation");
}

/// 语音生成时，语音文件保存的目录
Future<Directory> getVoiceGenDir() async {
  return getAppHomeDirectory(subfolder: "voice_generation");
}

// 用于声音复制时录制的声音存放
Future<Directory> getVoiceCloneRecordDir() async {
  return getAppHomeDirectory(subfolder: "voice_clone_recordings");
}

/// 获取语音识别录音保存目录
Future<Directory> getVoiceRecognitionRecordDir() async {
  return getAppHomeDirectory(subfolder: "voice_recognition_records");
}

/// 使用file_picker选择文件时，保存文件的目录
/// 所有文件选择都放在同一个位置，重复时直接返回已存在的内容
Future<Directory> getFilePickerSaveDir() async {
  return getAppHomeDirectory(subfolder: "file_picker_files");
}

/// 使用image_picker选择文件时，保存文件的目录
/// 所有文件选择都放在同一个位置，重复时直接返回已存在的内容
Future<Directory> getImagePickerSaveDir() async {
  return getAppHomeDirectory(subfolder: "image_picker_files");
}
