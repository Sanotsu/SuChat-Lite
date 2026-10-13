// 旧版本数据迁移权限引导页(启动链早期挂载)
//
// 2026-10-12 权限交互重构：0.1.4 的全部数据在公共 SuChatFiles 目录
// (卸载不丢)，0.1.5 首启需"所有文件访问"权限才能扫描迁移。此前启动链
// 静默弹系统权限框且用户拒绝后误标完成——现改为：
//   1. main 检测 needsPermissionGate 后先 runApp 本引导页(不碰旧目录、
//      不请求权限)
//   2. 页面内直接呈现迁移说明(不用showDialog——此时无Material
//      Localizations/BotToast环境)，用户点击"去授权并迁移"才请求系统权限
//   3. 授权 → completer 完成 → main 继续正常初始化(runApp 真实App +
//      UpgradeMigrator 静默迁移)
//   4. 拒绝 → 记录标记(后续启动不再自动弹，设置页有手动迁移入口)，
//      同样放行正常初始化(本页被真实App树整体替换)
// 注意：本页树内不可使用 ToastUtils/dialog(MaterialApp 未含本地化、
// BotToast 未注册)，一切提示用页面内文案表达。
import 'dart:async';

import 'package:flutter/material.dart';

import '../core/services/upgrade_migrator.dart';

/// 权限引导门：需要引导时 runApp 本组件并等待 future 完成；
/// 无需引导直接 complete(false) 放行
class MigrationPermissionGate extends StatefulWidget {
  final Completer<bool> completer;

  const MigrationPermissionGate({super.key, required this.completer});

  @override
  State<MigrationPermissionGate> createState() =>
      _MigrationPermissionGateState();
}

class _MigrationPermissionGateState extends State<MigrationPermissionGate> {
  bool _requesting = false;
  bool _done = false;

  Future<void> _agree() async {
    if (_requesting || _done) return;
    setState(() => _requesting = true);

    final granted = await UpgradeMigrator.requestLegacyPermission();

    if (!mounted) return;

    if (!granted) {
      // 授权页被拒/未完成：记录标记，后续启动不再自动弹；放行启动
      await UpgradeMigrator.markPermissionDenied();
      if (!mounted) return;
      setState(() {
        _requesting = false;
        _done = true;
      });
      widget.completer.complete(false);
      return;
    }

    // 授权成功：放行正常初始化(迁移在启动链内静默执行)
    setState(() => _done = true);
    widget.completer.complete(true);
  }

  Future<void> _decline() async {
    if (_requesting || _done) return;
    await UpgradeMigrator.markPermissionDenied();
    if (!mounted) return;
    setState(() => _done = true);
    widget.completer.complete(false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _buildBody(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_requesting) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('等待授权结果...'),
        ],
      );
    }

    if (_done) {
      // 已放行：真实App树会整体替换本页，这里只给过渡文案
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
          SizedBox(height: 12),
          Text('正在启动...'),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.moving_outlined, size: 56),
        const SizedBox(height: 16),
        const Text(
          '检测到旧版本数据',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          '本机存在旧版本(SuChat)的数据目录，可将全部旧版数据迁移到'
          '新版本，包括：\n\n'
          '· 聊天记录(旧分支对话与统一聊天)\n'
          '· 角色卡与搭档\n'
          '· AI生成的图片/语音/视频\n'
          '· 下载文件与备份数据\n\n'
          '迁移需要授予"所有文件访问"权限(仅用于读取旧版数据目录，'
          '不会修改除迁移之外的任何内容)。\n\n是否立即迁移？',
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: _agree, child: const Text('去授权并迁移')),
        const SizedBox(height: 8),
        TextButton(onPressed: _decline, child: const Text('暂不迁移')),
        const SizedBox(height: 4),
        const Text(
          '选择"暂不迁移"可在稍后于 设置-旧版数据迁移 中手动完成',
          style: TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
