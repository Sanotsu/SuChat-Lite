//全局异常的捕捉
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:video_player_media_kit/video_player_media_kit.dart';

import '../core/storage/cus_get_storage.dart';
import '../core/utils/simple_tools.dart';
import '../features/branch_chat/presentation/viewmodels/branch_store.dart';
import '../shared/services/model_manager_service.dart';
import '../shared/services/network_service.dart';
import '../shared/widgets/toast_utils.dart';
import 'permission_check_app.dart';
import 'suchat_app.dart';

class AppCatchError {
  void run() {
    ///Flutter 框架异常
    FlutterError.onError = (FlutterErrorDetails details) async {
      ///线上环境 todo
      if (kReleaseMode) {
        Zone.current.handleUncaughtError(details.exception, details.stack!);
      } else {
        //开发期间 print
        FlutterError.dumpErrorToConsole(details);
      }
    };

    // 受保护的代码块
    runZonedGuarded(() async {
      // 确保已经初始化绑定
      WidgetsFlutterBinding.ensureInitialized();

      // 仅在移动端限制垂直方向
      if (Platform.isAndroid || Platform.isIOS) {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      }

      // 默认使用path_provider 的 getTemporaryDirectory()作为存储路径,且无法修改
      // 又因为检查设备存储权限等是否授权需要把标记存入缓存,避免每次都弹窗显示,所以要在检查前进行缓存初始化
      await GetStorage.init(CusGetStorage.storeName);

      // 启动初始检查权限的界面，而不是直接进入应用
      runApp(const PermissionCheckApp());
    }, (error, stack) => catchError(error, stack));
  }

  void initApp() async {
    // 只在首次启动时初始化内置模型
    if (CusGetStorage().isFirstLaunch()) {
      await ModelManagerService.initBuiltinModelsTest();
      await CusGetStorage().markLaunched();
    }

    // 初始化 ObjectBox
    final store = await BranchStore.create();

    // 在应用退出时关闭 Store
    WidgetsBinding.instance.addObserver(
      LifecycleEventHandler(
        detached: () async {
          store.store.close();
        },
      ),
    );

    NetworkStatusService().initialize();

    // 单行初始化后，您可以正常在多个平台使用 video_player
    VideoPlayerMediaKit.ensureInitialized(
      // default: false    -    dependency: media_kit_libs_android_video
      android: true,
      // default: false    -    dependency: media_kit_libs_ios_video
      iOS: true,
      // default: false    -    dependency: media_kit_libs_macos_video
      macOS: true,
      // default: false    -    dependency: media_kit_libs_windows_video
      windows: true,
      // default: false    -    dependency: media_kit_libs_linux
      // 需要在开发机安装依赖，比如Ubuntu下:sudo apt install libmpv-dev
      // 没安装在报错信息下会有提示
      linux: true,
    );

    // 上面的初始化完成后，再启动应用
    runApp(const SuChatApp());
  }

  ///对搜集的 异常进行处理  上报等等
  Future<void> catchError(Object error, StackTrace stack) async {
    //是否是 Release版本
    debugPrint("AppCatchError>>>>>>>>>> [ kReleaseMode ] $kReleaseMode");
    debugPrint('AppCatchError>>>>>>>>>> [ Message ] $error');
    pl.d(error);
    debugPrint('AppCatchError>>>>>>>>>> [ Stack ] \n$stack');

    // 判断是否可以显示Toast
    try {
      // 尝试显示错误提示
      ToastUtils.showError(
        error.toString(),
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      // Toast初始化可能还未完成，只记录错误
      debugPrint('无法显示Toast，可能是界面尚未准备好: $e');
    }

    // 判断返回数据中是否包含"token失效"的信息
    // 一些错误处理，比如token失效这里退出到登录页面之类的
    if (error.toString().contains("token无效") ||
        error.toString().contains("token已过期") ||
        error.toString().contains("登录出错") ||
        error.toString().toLowerCase().contains("invalid")) {
      debugPrint(error.toString());
    }
  }
}

/// 生命周期事件处理器
class LifecycleEventHandler extends WidgetsBindingObserver {
  final AsyncCallback? detached;

  LifecycleEventHandler({this.detached});

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.detached:
        if (detached != null) {
          await detached!();
        }
        break;
      default:
        break;
    }
  }
}
