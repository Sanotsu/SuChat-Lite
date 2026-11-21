import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:nativeapi/nativeapi.dart' show Rectangle;
import 'package:window_manager/window_manager.dart';

import '../storage/cus_get_storage.dart';

/// 桌面端窗口管理：最小尺寸约束、窗口大小/位置记忆。
/// 移动端为空实现，调用方无需平台判断。
///
/// 基于 window_manager 0.7 的原生 API(nativeapi)：
/// 0.5.x 的 ensureInitialized/waitUntilReadyToShow 已无对应物，
/// 拿到窗口对象后直接设置属性并 show 即可。
class DesktopWindowService {
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

    final Window? window = WindowManager.instance.getCurrent();
    if (window == null) {
      debugPrint('DesktopWindowService: 主窗口尚未就绪，跳过窗口初始化');
      return;
    }

    window.title = 'SuChat';
    window.minimumSize = _minSize.toNative();

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

    // 应用窗口大小与位置(替代旧 waitUntilReadyToShow 的 options)
    if (position != null) {
      window.bounds = Rectangle(
        x: position.dx,
        y: position.dy,
        width: size.width,
        height: size.height,
      );
    } else {
      window.bounds = Rectangle(
        x: 0,
        y: 0,
        width: size.width,
        height: size.height,
      );
      window.center();
    }
    window.show();
    window.focus();

    // 拦截关闭：先记录窗口边界再放行关闭
    // (不调用 request.cancel()，回调正常结束后窗口继续关闭，
    // 最后一个窗口关闭后由平台 runner 结束应用)
    window.addListener((event) async {
      if (event is WindowCloseRequestedEvent) {
        try {
          await _saveBounds(window).timeout(const Duration(milliseconds: 800));
        } catch (_) {}
      }
    });
  }

  Future<void> _saveBounds(Window window) async {
    if (!_initialized) return;
    try {
      final rect = window.bounds.toRect();
      await CusGetStorage().box.write(_windowBoundsKey, {
        'x': rect.left,
        'y': rect.top,
        'width': rect.width,
        'height': rect.height,
      });
    } catch (e) {
      debugPrint('DesktopWindowService 保存窗口记忆失败: $e');
    }
  }
}
