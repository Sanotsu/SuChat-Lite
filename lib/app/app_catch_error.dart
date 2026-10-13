//全局异常的捕捉
import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:video_player_media_kit/video_player_media_kit.dart';

import '../core/network/dio_client/interceptor_error.dart';
import '../core/services/desktop_window_service.dart';
import '../core/services/legacy_llm_migrator.dart';
import '../core/services/upgrade_migrator.dart';
import '../core/storage/cus_get_storage.dart';
import '../core/utils/simple_tools.dart';
import '../core/utils/storage_paths.dart';
import '../shared/services/network_service.dart';
import '../shared/widgets/toast_utils.dart';
import 'migration_permission_gate.dart';
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
      // 2026-09-18 Marionette MCP 测试基建(FIX_LOG 九十)：debug 模式替换
      // 为 MarionetteBinding——AI agent 经 MCP 驱动真实运行的应用
      // (控件树/tap/输入/截图)；kDebugMode 是编译期常量，release 的
      // 死代码摇除会移除该分支，生产构建零影响。本文件是全应用唯一
      // binding 初始化入口
      if (kDebugMode) {
        MarionetteBinding.ensureInitialized();
      } else {
        WidgetsFlutterBinding.ensureInitialized();
      }

      // 仅在移动端限制垂直方向
      if (Platform.isAndroid || Platform.isIOS) {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      }

      // 2026-09-04 容器文件收纳进私有区(直接以带path的工厂实例化并
      // 初始化，init()静态方法不支持path参数)
      final gsPath = (await getGetStorageDir()).path;
      await GetStorage(CusGetStorage.storeName, gsPath).initStorage;

      // 2026-10-12 权限引导门：Android 未授权时先挂引导页(说明框取得
      // 用户同意后才请求系统权限)，授权/拒绝后再继续正常初始化。
      // 未授权绝不静默弹权限、不探测旧目录、不标记完成
      if (await UpgradeMigrator.needsPermissionGate()) {
        final gateCompleter = Completer<bool>();
        runApp(MigrationPermissionGate(completer: gateCompleter));
        await gateCompleter.future;
      }

      // 0.1.5 起零存储权限启动：核心数据在应用私有区，直接初始化应用
      await initApp();
    }, (error, stack) => catchError(error, stack));
  }

  Future<void> initApp() async {
    // 0.1.4 → 0.1.5 升级迁移：sqlite 库文件复制必须先于任何数据库打开；
    // 媒体移动/路径重写/旧分支聊天转换在后台续跑。
    // Android 未授权时这里只返回 needsPermission(引导页负责授权交互)，
    // 授权后正常启动会走完整迁移
    await UpgradeMigrator.runIfNeeded(quickOnly: true);

    /// 只在首次启动时初始化内置模型
    /// 2025-07-04 理论上要加上这个if判断，
    /// 这里注释掉是担心直接删除了应用下DB文件夹后，再打开APP时会没有默认模型

    // if (CusGetStorage().isFirstLaunch()) {
    // await CusGetStorage().markLaunched();
    // }

    // 2026-09-07 LLM旧体系退役：旧版user_ak_map中的平台AK转入secure storage
    // (幂等，仅在未打标时执行；须先于任何扩展功能LLM调用)
    await LegacyLLMMigrator.runIfNeeded();

    NetworkStatusService().initialize();

    // 桌面端窗口管理：最小尺寸约束 + 窗口大小/位置记忆
    // （必须在 runApp 前完成 waitUntilReadyToShow，否则首帧会闪默认窗口）
    await DesktopWindowService.instance.init();

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

    // 2026-09-09 用户主动中断是正常业务逻辑，不该按错误提示：
    // 流式请求被手动取消时，dio错误在生成器已取消状态下抛出无人接收，
    // 逃逸到Zone进入本方法；静默记录即可，不弹错误toast
    final errorText = error.toString();
    final isUserCancelled =
        (error is DioException && error.type == DioExceptionType.cancel) ||
        (error is CusHttpException && error.cusCode == -2) ||
        errorText.contains('manually cancelled by the user') ||
        errorText.contains('请求被取消');
    if (isUserCancelled) {
      debugPrint('AppCatchError>>>>>>>>>> 用户主动取消，静默处理不提示');
      return;
    }

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
    if (error.toString().contains("登录出错")) {
      if (kDebugMode) {
        print(error);
      }
    }
  }
}
