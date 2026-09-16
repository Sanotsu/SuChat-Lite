import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// 本地运行时探测结果
class McpRuntimeStatus {
  final String name;

  /// 可执行文件路径(null=未安装)
  final String? path;

  /// 版本号(探测失败时为null)
  final String? version;
  final String installHint;

  const McpRuntimeStatus({
    required this.name,
    this.path,
    this.version,
    required this.installHint,
  });

  bool get available => path != null;
}

/// 2026-09-14 P2-2 stdio server 运行时探测
/// node/npx/uvx 可用性检测(设置页提示缺失时给安装指引)；
/// 仅桌面端有意义，web/移动端直接返回空列表
class McpRuntimeChecker {
  /// 待探测的运行时及安装提示
  static const _targets = [
    (
      name: 'node',
      versionArgs: <String>['--version'],
      hint: 'https://nodejs.org',
    ),
    (
      name: 'npx',
      versionArgs: <String>['--version'],
      hint: '随 Node.js 一起安装 (https://nodejs.org)',
    ),
    (
      name: 'uvx',
      versionArgs: <String>['--version'],
      hint: 'https://docs.astral.sh/uv/',
    ),
  ];

  /// 探测全部运行时(并行)。非桌面端返回空列表
  static Future<List<McpRuntimeStatus>> detectRuntimes() async {
    if (kIsWeb ||
        !(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      return const [];
    }
    return Future.wait(_targets.map(_detectOne));
  }

  /// 2026-09-14 P2-5 实测修复：把裸命令名解析为可执行的完整路径。
  ///
  /// Windows上 Process.start 不像shell那样按PATHEXT解析扩展名——`npx`
  /// 实际是 npx.cmd 批处理，直接 Process.start("npx") 报"系统找不到指定
  /// 的文件"；且 `where npx` 会同时列出无扩展名的sh脚本与npx.cmd，
  /// 必须挑可执行扩展。非Windows(含macOS/Linux)which结果可直接用。
  ///
  /// 用户已给完整路径或带可执行扩展名时原样返回(交给CreateProcess处理)；
  /// 找不到返回null(调用方转成友好错误)
  static Future<String?> resolveCommandPath(String command) async {
    if (kIsWeb) return command;
    final cmd = command.trim();

    // 含路径分隔符(用户给了完整/相对路径)或已带可执行扩展名：原样返回
    if (cmd.contains(RegExp(r'[\\/]'))) return cmd;
    if (!Platform.isWindows &&
        RegExp(r'\.(exe|cmd|bat|com)$', caseSensitive: false).hasMatch(cmd)) {
      return cmd;
    }

    try {
      final whichCmd = Platform.isWindows ? 'where' : 'which';
      final found = await Process.run(
        whichCmd,
        [cmd],
        runInShell: Platform.isWindows,
        stdoutEncoding: utf8,
      );
      if (found.exitCode != 0) return null;

      final lines = (found.stdout as String)
          .trim()
          .split(RegExp(r'\r?\n'))
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      if (lines.isEmpty) return null;
      if (!Platform.isWindows) return lines.first;

      // Windows: 按PATHEXT常见顺序挑可执行扩展(无扩展名的是sh脚本，
      // CreateProcess无法执行)
      for (final ext in const ['.exe', '.cmd', '.bat', '.com']) {
        for (final line in lines) {
          if (line.toLowerCase().endsWith(ext)) return line;
        }
      }
      return lines.first;
    } catch (_) {
      return null;
    }
  }

  static Future<McpRuntimeStatus> _detectOne(
    ({String name, List<String> versionArgs, String hint}) target,
  ) async {
    try {
      final whichCmd = Platform.isWindows ? 'where' : 'which';
      final found = await Process.run(
        whichCmd,
        [target.name],
        runInShell: Platform.isWindows,
        stdoutEncoding: utf8,
      );
      if (found.exitCode != 0) {
        return McpRuntimeStatus(name: target.name, installHint: target.hint);
      }

      final path = (found.stdout as String)
          .trim()
          .split(Platform.isWindows ? '\r\n' : '\n')
          .first
          .trim();

      // 版本探测失败不影响可用性(个别包装脚本不支持--version)
      String? version;
      try {
        final ver = await Process.run(
          path,
          target.versionArgs,
          stdoutEncoding: utf8,
        );
        if (ver.exitCode == 0) {
          version = (ver.stdout as String).trim().split('\n').first.trim();
          if (version.isEmpty) version = null;
        }
      } catch (_) {}

      return McpRuntimeStatus(
        name: target.name,
        path: path,
        version: version,
        installHint: target.hint,
      );
    } catch (_) {
      return McpRuntimeStatus(name: target.name, installHint: target.hint);
    }
  }
}
