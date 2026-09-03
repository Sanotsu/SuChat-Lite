import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

import '../storage/cus_get_storage.dart';

/// 桌面端窗口管理：最小尺寸约束、窗口大小/位置记忆。
/// 移动端为空实现，调用方无需平台判断。
class DesktopWindowService with WindowListener {
  DesktopWindowService._();

  static final DesktopWindowService instance = DesktopWindowService._();

  static const _windowBoundsKey = 'desktop_window_bounds';
  static const Size _defaultSize = Size(1280, 800);
  static const Size _minSize = Size(800, 600);

  bool _initialized = false;

  Future<void> init() async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;
    if (_initialized) return;
    _initialized = true;

    await windowManager.ensureInitialized();
    windowManager.addListener(this);

    final box = CusGetStorage().box;
    final saved = box.read(_windowBoundsKey);

    Size size = _defaultSize;
    Offset? position;
    if (saved is Map) {
      try {
        final w = (saved['width'] as num?)?.toDouble() ?? _defaultSize.width;
        final h = (saved['height'] as num?)?.toDouble() ?? _defaultSize.height;
        // 上次异常拖拽导致过小，则回退默认
        size = Size(
          w.clamp(_minSize.width, 4096.0),
          h.clamp(_minSize.height, 2160.0),
        );
        final dx = (saved['x'] as num?)?.toDouble();
        final dy = (saved['y'] as num?)?.toDouble();
        if (dx != null && dy != null) position = Offset(dx, dy);
      } catch (e) {
        debugPrint('DesktopWindowService 读取窗口记忆失败: $e');
      }
    }

    await windowManager.waitUntilReadyToShow(
      WindowOptions(
        size: size,
        minimumSize: _minSize,
        center: position == null,
        title: 'SuChat',
        titleBarStyle: TitleBarStyle.normal,
      ),
      () async {
        if (position != null) {
          await windowManager.setPosition(position);
        }
        await windowManager.show();
        await windowManager.focus();
      },
    );

    // 拦截关闭：先记录窗口边界再真正关闭
    await windowManager.setPreventClose(true);
  }

  Future<void> _saveBounds() async {
    if (!_initialized) return;
    try {
      final bounds = await windowManager.getBounds();
      await CusGetStorage().box.write(_windowBoundsKey, {
        'x': bounds.left,
        'y': bounds.top,
        'width': bounds.width,
        'height': bounds.height,
      });
    } catch (e) {
      debugPrint('DesktopWindowService 保存窗口记忆失败: $e');
    }
  }

  @override
  void onWindowClose() async {
    // setPreventClose(true)下若此处异常/被阻塞(如media_kit native线程占用平台通道)，
    // destroy不执行会导致窗口白屏无响应，故各步均加超时并最终exit兜底
    try {
      await _saveBounds().timeout(const Duration(milliseconds: 800));
    } catch (_) {}
    try {
      await windowManager.destroy().timeout(const Duration(milliseconds: 800));
    } catch (_) {}
    exit(0);
  }
}
