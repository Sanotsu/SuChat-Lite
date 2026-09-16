import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/openai_request.dart';

/// 2026-09-14 P3-12 shell命令安全判定结果
enum ShellSafety {
  /// 只读命令白名单：免审批直接执行(降审批噪音，借鉴Claude Code)
  readOnly,

  /// 危险命令黑名单：直接拒绝执行，不询问(破坏性/系统级操作)
  dangerous,

  /// 普通命令：走审批横幅由用户决定
  normal,
}

/// 2026-09-14 P3-11 内置终端命令工具(桌面端)：
/// 模型可直接在用户桌面执行命令并回填stdout/stderr/退出码——
/// 对齐opencode/Claude Code的bash工具，让应用从"能查"升级为"能动手"。
/// 安全闸(P3-12)：只读白名单免审批 + 危险黑名单直接拒绝 + 其余走
/// 审批横幅；进程超时强杀 + 输出截断。默认关闭，设置页手动开启。
/// 说明：命令文本规则是尽力而为非安全边界(Claude Code官方明示)，
/// 本项目定位聊天客户端的可控授权，不做OS级沙箱。
class BuiltinShellTool {
  BuiltinShellTool._();

  static const String toolName = 'shell_execute';

  /// 仅桌面端支持(web/移动端无本地终端语义)
  static bool get isSupported =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// OpenAI function工具定义(注入request.tools)
  static OpenAITool buildTool() {
    return OpenAITool.function(
      const OpenAIFunction(
        name: toolName,
        description:
            '在用户的桌面电脑上执行终端命令并返回输出(stdout/stderr/退出码)。'
            '适用于查看文件目录、运行脚本、包管理、git操作、系统信息查询等。'
            '注意：破坏性命令会被安全策略直接拦截；非只读命令每次执行前'
            '需要用户确认，请勿重复发起被用户拒绝的命令。',
        parameters: <String, dynamic>{
          'type': 'object',
          'properties': <String, dynamic>{
            'command': <String, dynamic>{
              'type': 'string',
              'description':
                  '要执行的命令(Windows在PowerShell中执行，'
                  'macOS/Linux在sh中执行)',
            },
            'working_directory': <String, dynamic>{
              'type': 'string',
              'description': '工作目录(可选，默认为用户主目录)',
            },
            'timeout_seconds': <String, dynamic>{
              'type': 'integer',
              'description': '超时秒数(可选，默认30，最大120，超时进程被终止)',
            },
          },
          'required': <String>['command'],
        },
      ),
    );
  }

  /// 执行命令并组装结果文本(异常/超时均以文本返回，由模型解释)
  static Future<String> execute({
    required String command,
    String? workingDirectory,
    int timeoutSeconds = 30,
  }) async {
    if (!isSupported) {
      return '当前平台不支持终端命令执行(仅桌面端可用)';
    }

    final cmd = command.trim();
    if (cmd.isEmpty) return '命令为空，未执行';

    final timeout = Duration(seconds: timeoutSeconds.clamp(1, 120));

    // 工作目录校验(不存在时Process会抛异常，提前给出可读错误)
    String? cwd = workingDirectory?.trim();
    if (cwd != null && cwd.isEmpty) cwd = null;
    if (cwd != null && !Directory(cwd).existsSync()) {
      return '工作目录不存在: $cwd';
    }

    final encoding = Platform.isWindows ? systemEncoding : utf8;
    ProcessResult result;
    try {
      result = await Process.run(
        Platform.isWindows ? 'powershell' : '/bin/sh',
        Platform.isWindows
            ? ['-NoProfile', '-NonInteractive', '-Command', cmd]
            : ['-c', cmd],
        workingDirectory: cwd,
        stdoutEncoding: encoding,
        stderrEncoding: encoding,
      ).timeout(timeout);
    } on TimeoutException {
      return '命令执行超时(${timeout.inSeconds}s)已被终止: $cmd\n'
          '提示：长时间任务请在命令中使用后台方式或分段执行';
    } catch (e) {
      return '命令启动失败: $e';
    }

    // 输出粗截断(16KB)：防止超大输出撑爆上下文，service层还有统一截断
    String clip(String s) {
      s = s.trim();
      if (s.length <= 16 * 1024) return s;
      return '${s.substring(0, 16 * 1024)}\n...(输出过长已截断)';
    }

    final stdoutText = clip(result.stdout as String);
    final stderrText = clip(result.stderr as String);

    final buffer = StringBuffer('退出码: ${result.exitCode}');
    if (stdoutText.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('stdout:')
        ..write(stdoutText);
    }
    if (stderrText.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('stderr:')
        ..write(stderrText);
    }
    if (stdoutText.isEmpty && stderrText.isEmpty) {
      buffer.write('(无输出)');
    }
    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // P3-12 命令安全策略(借鉴Claude Code三态：deny黑名单 > 只读白名单 > 审批)
  // ---------------------------------------------------------------------------

  /// 只读命令首词白名单(Windows/Unix常见只读命令并集，大小写不敏感)。
  /// 命中则免审批直接执行——审批噪音控制的关键。
  /// 2026-09-15 审查移除 find(Unix语义可-delete/-exec删文件)与
  /// env(wrapper可执行任意程序)——免审批通道必须杜绝执行能力
  static const Set<String> _readOnlyFirstWords = {
    // 目录/文件查看
    'ls', 'dir', 'cat', 'type', 'head', 'tail',
    'tree', 'pwd', 'stat', 'du', 'df',
    'get-childitem', 'gci', 'get-content', 'gc', 'get-item', 'get-location',
    // 文本搜索
    'grep', 'findstr', 'select-string', 'sls', 'rg', 'ag',
    // 系统信息(注：env已移除——Unix的env是wrapper可"env 任意命令"执行)
    'whoami', 'hostname', 'uname', 'date', 'echo', 'printf', 'which', 'where',
    'get-date', 'get-process', 'ps', 'get-computerinfo', 'systeminfo',
    // 网络查看类(仅查看配置，不含发请求的curl等)
    'ipconfig', 'ifconfig', 'netstat', 'ping', 'get-netipconfiguration',
  };

  /// 危险命令黑名单(命中直接拒绝，不询问)。
  /// 保守小集合：宁可误拦不可漏拦，用户可在终端自行执行。
  /// 2026-09-15 审查补漏：PowerShell别名递归删除(del/erase/ri/rd
  /// 均是Remove-Item别名，支持-r/-recurse，原规则只匹配斜杠形式)、
  /// 卷影副本删除(勒索软件防恢复标配)/引导配置/剩余空间擦除
  static final List<RegExp> _dangerousPatterns = [
    // 递归/强制删除
    RegExp(r'\brm\b[^|;&]*\s(-[a-z]*r|--recursive)', caseSensitive: false),
    RegExp(r'\bdel\b\s+/[sq]', caseSensitive: false),
    RegExp(r'\brmdir\b\s+/s', caseSensitive: false),
    RegExp(r'remove-item\b[^|;&]*-recurse', caseSensitive: false),
    RegExp(r'\brd\b\s+/s', caseSensitive: false),
    RegExp(
      r'\b(del|erase|ri|rd)\b[^|;&]*\s(-[a-z]*r\b|-recurse\b)',
      caseSensitive: false,
    ),
    // 磁盘/系统级
    RegExp(r'\bformat\b\s+\w:', caseSensitive: false),
    RegExp(r'\bdiskpart\b', caseSensitive: false),
    RegExp(r'\bmkfs\b', caseSensitive: false),
    RegExp(r'\bdd\b\s+if=', caseSensitive: false),
    RegExp(r'\b(shutdown|reboot|halt|poweroff)\b', caseSensitive: false),
    RegExp(r'restart-computer', caseSensitive: false),
    RegExp(r'stop-computer', caseSensitive: false),
    RegExp(r'\bvssadmin\b[^|;&]*delete', caseSensitive: false),
    RegExp(r'\bbcdedit\b', caseSensitive: false),
    RegExp(r'\bcipher\b\s+/w', caseSensitive: false),
    // 注册表
    RegExp(r'\breg\s+(add|delete|import)\b', caseSensitive: false),
    RegExp(r'remove-itemproperty', caseSensitive: false),
    // 远程代码执行形态(下载即执行)
    RegExp(
      r'(curl|wget|invoke-webrequest|iwr)[^|;&]*\|\s*'
      r'(sh|bash|zsh|powershell|iex|invoke-expression)\b',
      caseSensitive: false,
    ),
    RegExp(r'\b(invoke-expression|iex)\b', caseSensitive: false),
    // 执行策略篡改
    RegExp(r'set-executionpolicy', caseSensitive: false),
  ];

  /// 提取命令首词(程序名)——会话级"总是允许"的规则粒度
  static String firstWord(String command) {
    final t = command.trim();
    final idx = t.indexOf(RegExp(r'\s'));
    return idx < 0 ? t.toLowerCase() : t.substring(0, idx).toLowerCase();
  }

  /// 会话级"总是允许"规则键(内置shell)
  static String sessionAllowKey(String command) =>
      'builtin:shell:${firstWord(command)}';

  /// 安全判定：黑名单(deny)优先 > 只读白名单(allow) > 审批(ask)
  static ShellSafety classify(String command) {
    final cmd = command.trim();

    for (final pattern in _dangerousPatterns) {
      if (pattern.hasMatch(cmd)) return ShellSafety.dangerous;
    }

    // 2026-09-15 审查加固：白名单免审批前提从"无重定向"扩为
    // "无任何执行逃逸形态"——出现以下任一即降级为需审批，防止
    // 借白名单首词绕过审批：
    // 重定向写文件(> >> n> out-file tee) |
    // 管道(| 输出喂给任意程序，如"cat x | sh") |
    // 命令分隔与后台(; && || &) |
    // 命令替换(反引号或$()先执行再回填，如"echo `rm -rf /`")
    final hasEscape = RegExp(
      r'[12]?>|\bout-file\b|\btee\b|[|;&]|`|\$\(',
      caseSensitive: false,
    ).hasMatch(cmd);
    if (!hasEscape && _readOnlyFirstWords.contains(firstWord(cmd))) {
      return ShellSafety.readOnly;
    }
    return ShellSafety.normal;
  }
}
