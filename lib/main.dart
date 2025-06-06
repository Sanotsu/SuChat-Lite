import 'dart:async';
import 'dart:io';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get_storage/get_storage.dart';
import 'package:video_player_media_kit/video_player_media_kit.dart';

import 'features/branch_chat/presentation/viewmodels/branch_store.dart';
import 'shared/widgets/toast_utils.dart';
import 'shared/widgets/min_size_layout.dart';
import 'core/utils/screen_helper.dart';
import 'core/utils/simple_tools.dart';
import 'core/storage/cus_get_storage.dart';
import 'shared/services/model_manager_service.dart';
import 'shared/services/network_service.dart';
import 'features/branch_chat/presentation/index.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  AppCatchError().run();
}

//全局异常的捕捉
class AppCatchError {
  run() {
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

    runZonedGuarded(() {
      //受保护的代码块
      WidgetsFlutterBinding.ensureInitialized();

      // 仅在移动端限制垂直方向
      if (Platform.isAndroid || Platform.isIOS) {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      }

      // 继续初始化...
      initApp();
    }, (error, stack) => catchError(error, stack));
  }

  void initApp() async {
    // 默认使用path_provider 的 getTemporaryDirectory()作为存储路径,且无法修改
    await GetStorage.init('SuChatGetStorage');

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
    runApp(const SuChatApp());
  }

  ///对搜集的 异常进行处理  上报等等
  catchError(Object error, StackTrace stack) async {
    //是否是 Release版本
    debugPrint("AppCatchError>>>>>>>>>> [ kReleaseMode ] $kReleaseMode");
    debugPrint('AppCatchError>>>>>>>>>> [ Message ] $error');
    pl.d(error);
    debugPrint('AppCatchError>>>>>>>>>> [ Stack ] \n$stack');

    // 弹窗提醒用户
    ToastUtils.showError(
      error.toString(),
      duration: const Duration(seconds: 5),
    );

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

class SuChatApp extends StatelessWidget {
  const SuChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 获取当前平台的设计尺寸
    final designSize = ScreenHelper.getDesignSize();

    return ScreenUtilInit(
      designSize: designSize,
      // minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, widget) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'SuChat',
          debugShowCheckedModeBanner: false,
          // 应用导航的观察者，导航有变化的时候可以做一些事？
          // navigatorObservers: [routeObserver],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            // form builder表单验证的多国语言
            FormBuilderLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('zh', 'CN'),
            Locale('en', 'US'),
            ...FormBuilderLocalizations.supportedLocales,
          ],
          // 初始化的locale
          locale: const Locale('zh', 'CN'),

          /// 默认的主题
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),

          home: const HomePage(),

          builder: (context, child) {
            // 根据平台调整字体缩放
            child = MediaQuery(
              ///设置文字大小不随系统设置改变
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(
                  ScreenHelper.isDesktop() ? 1.0 : 1.0,
                ),
              ),
              child: child!,
            );

            // 1 先初始化 bot_toast
            child = BotToastInit()(context, child);

            // 应用最小尺寸限制
            child = MinSizeLayout(minWidth: 640, minHeight: 360, child: child);

            // 针对桌面平台的背景处理
            if (ScreenHelper.isDesktop()) {
              child = myBuilder(context, child);
            }

            return child;
          },

          // 2. registered route observer
          navigatorObservers: [BotToastNavigatorObserver()],
        );
      },
    );
  }
}

// 2025-04-02 实测发现，如果不添加这个定义字widget默认背景色为白色
// 在使用了 bot_toast 后，分支对话和角色对话主页，背景会像是有一层遮罩一样黑的，实际就是没有背景
Widget myBuilder(BuildContext context, Widget? child) {
  return Container(color: Colors.white, child: child);
}
