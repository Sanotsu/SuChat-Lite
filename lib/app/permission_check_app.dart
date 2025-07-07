import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/storage/cus_get_storage.dart';
import '../core/utils/simple_tools.dart';
import 'app_catch_error.dart';

/// 权限检查应用
class PermissionCheckApp extends StatelessWidget {
  const PermissionCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PermissionCheckPage(),
      builder: (context, child) {
        child = BotToastInit()(context, child ?? Container());
        return child;
      },
      navigatorObservers: [BotToastNavigatorObserver()],
    );
  }
}

/// 权限检查页面
class PermissionCheckPage extends StatefulWidget {
  const PermissionCheckPage({super.key});

  @override
  State<PermissionCheckPage> createState() => _PermissionCheckPageState();
}

class _PermissionCheckPageState extends State<PermissionCheckPage> {
  bool _isChecking = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 确保权限检查只执行一次
    if (!_initialized) {
      _initialized = true;
      // 使用Future.microtask确保在当前帧完成后执行
      Future.microtask(() => _checkPermissions());
    }
  }

  Future<void> _checkPermissions() async {
    try {
      setState(() {
        _isChecking = true;
      });

      // 如果已经授权，则直接初始化应用
      if (CusGetStorage().isPermissionGranted()) {
        AppCatchError().initApp();
        return;
      }

      // 显示权限对话框
      bool hasPermission =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('所有文件访问权限'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SuChat 需要此权限才能正常工作: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Center(
                      child: RichText(
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '仅用于创建应用文件夹，避免下列资源遗失。',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                              ),
                            ),
                            TextSpan(
                              text: '不会修改任何其他的用户数据',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Text(
                      //   '仅用于创建应用文件夹，避免下列资源遗失，不会修改任何其他用户数据',
                      //   textAlign: TextAlign.center,
                      //   style: TextStyle(
                      //     fontSize: 13,
                      //     fontWeight: FontWeight.bold,
                      //   ),
                      // ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.chat, size: 20, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(child: Text('保存对话记录和角色卡片')),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.image, size: 20, color: Colors.green),
                        SizedBox(width: 8),
                        Expanded(child: Text('存储AI生成的图片和视频')),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.mic, size: 20, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(child: Text('保存语音输入和语音合成')),
                      ],
                    ),
                    SizedBox(height: 12),

                    Text(
                      '不授予权限将无法继续使用应用',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text(
                      '拒绝',
                      style: TextStyle(color: Colors.grey),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                    child: const Text(
                      '允许',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                  ),
                ],
                actionsPadding: const EdgeInsets.all(16),
              );
            },
          ) ??
          false;

      if (hasPermission) {
        // 用户点击了允许，实际请求权限
        hasPermission = await requestStoragePermission();

        // 如果用户选择了允许但实际没有授予权限，再次检查权限状态
        if (!hasPermission) {
          // 判断权限状态，看是永久拒绝还是临时拒绝
          PermissionStatus status;
          if (Platform.isAndroid) {
            final androidInfo = await DeviceInfoPlugin().androidInfo;
            int sdkInt = androidInfo.version.sdkInt;
            if (sdkInt <= 32) {
              status = await Permission.storage.status;
            } else {
              status = await Permission.manageExternalStorage.status;
            }
          } else if (Platform.isIOS) {
            status = await Permission.storage.status;
          } else {
            // 桌面平台直接返回true
            status = PermissionStatus.granted;
          }

          // 如果是永久拒绝，提示用户到设置中手动开启
          if (status == PermissionStatus.permanentlyDenied && mounted) {
            await showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('权限被永久拒绝'),
                  content: const Text('您已永久拒绝存储权限，请到设置中手动开启权限。'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('打开设置'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        openAppSettings();
                      },
                    ),
                    TextButton(
                      child: const Text('退出应用'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (Platform.isAndroid) {
                          SystemNavigator.pop();
                        } else {
                          exit(0);
                        }
                      },
                    ),
                  ],
                );
              },
            );
            // 无论用户是否打开设置，都退出应用
            if (Platform.isAndroid) {
              SystemNavigator.pop();
            } else {
              exit(0);
            }
            return;
          }
        }
      }

      // 确保组件仍然挂载
      if (mounted) {
        setState(() {
          _isChecking = false;
        });

        if (hasPermission) {
          // 进入这里后应该已经初始化getStorage并正确授权了，这里标记已授权
          await CusGetStorage().markPermissionGranted();

          // 权限已授予，初始化应用
          AppCatchError().initApp();
        } else {
          // 权限被拒绝，退出应用
          _showExitDialog();
        }
      }
    } catch (e, stack) {
      debugPrint("权限检查过程中出错: $e");
      debugPrint(stack.toString());
      // 确保组件仍然挂载
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
        // 显示错误对话框
        _showErrorDialog("权限检查过程中出错，请重启应用: $e");
      }
    }
  }

  void _showExitDialog() {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('无法继续'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(
                '无存储权限，应用无法正常运行',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                '请重新启动应用并授予所有文件访问权限',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton.icon(
              icon: const Icon(Icons.exit_to_app),
              label: const Text('退出应用'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (Platform.isAndroid) {
                  SystemNavigator.pop();
                } else {
                  exit(0);
                }
              },
            ),
          ],
          actionsPadding: const EdgeInsets.all(16),
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    if (mounted) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('发生错误'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            actions: <Widget>[
              ElevatedButton.icon(
                icon: const Icon(Icons.exit_to_app),
                label: const Text('退出应用'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (Platform.isAndroid) {
                    SystemNavigator.pop();
                  } else {
                    exit(0);
                  }
                },
              ),
            ],
            actionsPadding: const EdgeInsets.all(16),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo or icon
              const Icon(
                Icons.chat_bubble_outline,
                size: 80,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 20),
              const Text(
                'SuChat',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              _isChecking
                  ? Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      Text(
                        '检查权限中...',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  )
                  : const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }
}
