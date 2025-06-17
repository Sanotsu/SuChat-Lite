import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/localization/l10n.dart';
import 'package:provider/provider.dart';

import '../core/utils/screen_helper.dart';
import '../features/training_assistant/presentation/viewmodels/training_viewmodel.dart';
import '../features/diet_diary/presentation/viewmodels/diet_diary_viewmodel.dart';
import '../shared/widgets/min_size_layout.dart';
import 'routes.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class SuChatApp extends StatelessWidget {
  const SuChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 获取当前平台的设计尺寸
    final designSize = ScreenHelper.getDesignSize();

    var providerChild = ScreenUtilInit(
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

          // 使用路由生成器
          initialRoute: AppRoutes.home,
          onGenerateRoute: AppRoutes.generateRoute,

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

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TrainingViewModel()),
        ChangeNotifierProvider(create: (_) => DietDiaryViewModel()),
      ],
      child: providerChild,
    );
  }
}

// 2025-04-02 实测发现，如果不添加这个定义字widget默认背景色为白色
// 在使用了 bot_toast 后，分支对话和角色对话主页，背景会像是有一层遮罩一样黑的，实际就是没有背景
Widget myBuilder(BuildContext context, Widget? child) {
  return Container(color: Colors.white, child: child);
}
