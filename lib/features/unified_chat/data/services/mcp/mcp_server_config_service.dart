import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/utils/simple_tools.dart';
import '../../database/unified_chat_db_init.dart';
import '../../database/unified_chat_ddl.dart';
import '../../models/mcp_models.dart';
import '../unified_secure_storage.dart';

/// MCP server 配置CRUD服务
/// 2026-09-11 MCP集成 P0-4
class McpServerConfigService {
  // 单例
  static final McpServerConfigService _instance =
      McpServerConfigService._internal();
  factory McpServerConfigService() => _instance;
  McpServerConfigService._internal();

  final _dbInit = UnifiedChatDBInit();

  /// 查询全部server(按内置优先、创建时间排序)
  Future<List<McpServerConfig>> getAllServers() async {
    final db = await _dbInit.database;
    final maps = await db.query(
      UnifiedChatDdl.tableUnifiedMcpServer,
      orderBy: 'is_built_in DESC, created_at ASC',
    );
    return maps.map(McpServerConfig.fromMap).toList();
  }

  /// 查询启用的server
  Future<List<McpServerConfig>> getEnabledServers() async {
    final all = await getAllServers();
    return all.where((s) => s.enabled).toList();
  }

  Future<McpServerConfig?> getServerById(String id) async {
    final db = await _dbInit.database;
    final maps = await db.query(
      UnifiedChatDdl.tableUnifiedMcpServer,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isEmpty ? null : McpServerConfig.fromMap(maps.first);
  }

  /// 2026-09-14 P2-4 按名称查询(导入覆盖场景：沿用已有条目的id，
  /// 保证会话开关/认证头等按id存储的数据不悬空)
  Future<McpServerConfig?> getServerByName(String name) async {
    final db = await _dbInit.database;
    final maps = await db.query(
      UnifiedChatDdl.tableUnifiedMcpServer,
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    return maps.isEmpty ? null : McpServerConfig.fromMap(maps.first);
  }

  /// 新增/更新。name唯一冲突时抛出异常由UI提示
  Future<void> saveServer(McpServerConfig config) async {
    if (!McpServerConfig.isValidName(config.name)) {
      throw FormatException('服务名称仅支持字母、数字、下划线和短横线: ${config.name}');
    }
    final db = await _dbInit.database;
    await db.insert(
      UnifiedChatDdl.tableUnifiedMcpServer,
      config.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  /// 更新已有server(保留创建时间)
  Future<void> updateServer(McpServerConfig config) async {
    if (!McpServerConfig.isValidName(config.name)) {
      throw FormatException('服务名称仅支持字母、数字、下划线和短横线: ${config.name}');
    }
    final db = await _dbInit.database;
    await db.update(
      UnifiedChatDdl.tableUnifiedMcpServer,
      config.toMap(),
      where: 'id = ?',
      whereArgs: [config.id],
    );
  }

  /// 更新启用状态
  Future<void> setServerEnabled(String id, bool enabled) async {
    final db = await _dbInit.database;
    await db.update(
      UnifiedChatDdl.tableUnifiedMcpServer,
      {'enabled': enabled ? 1 : 0, 'updated_at': _now()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 2026-09-14 P3-1 更新审批确认开关(每次工具调用前需用户确认)
  Future<void> setApprovalRequired(String id, bool required) async {
    final db = await _dbInit.database;
    await db.update(
      UnifiedChatDdl.tableUnifiedMcpServer,
      {'approval_required': required ? 1 : 0, 'updated_at': _now()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 2026-09-14 P3-7 保存工具列表离线缓存(连接成功listTools后调用，
  /// 局部列更新不动其他配置)
  Future<void> saveToolsCache(String id, String toolsJson) async {
    final db = await _dbInit.database;
    await db.update(
      UnifiedChatDdl.tableUnifiedMcpServer,
      {'tools_cache': toolsJson},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除server(内置server不允许删除，调用方先行判断；同步清理认证头)
  Future<void> deleteServer(String id) async {
    final db = await _dbInit.database;
    await db.delete(
      UnifiedChatDdl.tableUnifiedMcpServer,
      where: 'id = ? AND is_built_in = 0',
      whereArgs: [id],
    );
    await UnifiedSecureStorage.deleteMcpAuthHeader(id);
  }

  /// 认证头值(敏感)读写——DB仅存非敏感headers JSON
  Future<void> setAuthHeader(String serverId, String value) async {
    await UnifiedSecureStorage.setMcpAuthHeader(serverId, value);
  }

  Future<String?> getAuthHeader(String serverId) async {
    return UnifiedSecureStorage.getMcpAuthHeader(serverId);
  }

  /// 合并认证头到请求头Map：DB的headers JSON(非敏感) + secure storage认证头
  /// [authHeaderKey] 默认 Authorization，认证头值写入该键
  Future<Map<String, String>> buildRequestHeaders(
    McpServerConfig config, {
    String authHeaderKey = 'Authorization',
  }) async {
    final result = <String, String>{};

    final headersJson = config.headers?.trim() ?? '';
    if (headersJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(headersJson);
        if (decoded is Map) {
          decoded.forEach((k, v) {
            if (k is String && v != null) result[k] = v.toString();
          });
        }
      } catch (e) {
        pl.w('MCP server ${config.name} headers JSON解析失败: $e');
      }
    }

    final authValue = await getAuthHeader(config.id);
    if (authValue != null && authValue.trim().isNotEmpty) {
      result[authHeaderKey] = authValue.trim();
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // 2026-09-14 P2-4 Claude Desktop 格式 JSON 批量导入
  // ---------------------------------------------------------------------------

  /// 解析导入JSON。兼容两种形态：
  /// 1. Claude Desktop 标准格式 `{"mcpServers": {name: {...}}}`
  /// 2. 直接传 `{name: {...}}` 顶层Map(宽松兼容)
  /// server 定义支持 stdio(command/args/env) 与远程(url/headers，
  /// type字段为http/sse，缺省http)。
  /// 返回解析成功的条目与逐条错误(互不中断)。
  Future<({List<McpImportItem> items, List<String> errors})> parseImportJson(
    String raw,
  ) async {
    final items = <McpImportItem>[];
    final errors = <String>[];

    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (e) {
      return (items: items, errors: <String>['JSON格式不合法: $e']);
    }
    if (decoded is! Map) {
      return (items: items, errors: const ['顶层必须是JSON对象']);
    }

    dynamic serversMap = decoded['mcpServers'];
    serversMap ??= decoded; // 宽松：直接顶层
    if (serversMap is! Map || serversMap.isEmpty) {
      return (items: items, errors: const ['未找到 mcpServers 配置或其为空']);
    }

    final existingNames = (await getAllServers()).map((s) => s.name).toSet();
    final usedNames = <String>{}; // 本批次内去重

    serversMap.forEach((rawKey, rawDef) {
      final originalName = rawKey.toString().trim();
      if (originalName.isEmpty) {
        errors.add('存在未命名的server条目，已跳过');
        return;
      }
      if (rawDef is! Map) {
        errors.add('「$originalName」的定义必须是对象，已跳过');
        return;
      }

      // 名称规范化(工具名 mcp__name__tool 的安全要求)
      final name = McpServerConfig.sanitizeName(originalName);
      if (name.isEmpty || RegExp(r'^_+$').hasMatch(name)) {
        errors.add('「$originalName」名称规范化后为空，已跳过');
        return;
      }

      // stdio: 有command；远程: 有url；否则跳过
      // 2026-09-15 mcp-remote桥接智能识别：npx mcp-remote <url> 形态
      // 转换为远程直连(免本地node依赖、少一层桥接进程)
      final command = rawDef['command']?.toString().trim();
      String? url = rawDef['url']?.toString().trim();
      final String transport;
      String? argsJson;
      String? envJson;
      String? headersJson;
      String? authHeader;
      String? effectiveCommand = command;

      if (command != null && command.isNotEmpty) {
        final bridged = _tryExtractMcpRemoteBridge(command, rawDef['args']);
        if (bridged != null) {
          transport = bridged.transport;
          url = bridged.url;
          headersJson = bridged.headersJson;
          authHeader = bridged.authHeader;
          effectiveCommand = null;
        } else {
          transport = 'stdio';
          final rawArgs = rawDef['args'];
          if (rawArgs is List) {
            argsJson = jsonEncode(rawArgs.map((e) => e.toString()).toList());
          } else if (rawArgs is String && rawArgs.trim().isNotEmpty) {
            // 宽松：空格分隔的字符串转数组
            argsJson = jsonEncode(rawArgs.trim().split(RegExp(r'\s+')));
          }
          final rawEnv = rawDef['env'];
          if (rawEnv is Map) {
            envJson = jsonEncode(
              rawEnv.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
            );
          }
        }
      } else if (url != null && url.isNotEmpty) {
        transport = rawDef['type']?.toString().toLowerCase() == 'sse'
            ? 'sse'
            : 'http';
        final rawHeaders = rawDef['headers'];
        if (rawHeaders is Map) {
          final rest = <String, String>{};
          rawHeaders.forEach((k, v) {
            if (k.toString().toLowerCase() == 'authorization') {
              authHeader = v?.toString();
            } else {
              rest[k.toString()] = v?.toString() ?? '';
            }
          });
          if (rest.isNotEmpty) headersJson = jsonEncode(rest);
        }
      } else {
        errors.add('「$originalName」缺少 command 或 url，已跳过');
        return;
      }

      // 规范化名冲突：本批次内加序号后缀
      var finalName = name;
      var suffix = 2;
      while (usedNames.contains(finalName)) {
        finalName = '${name}_$suffix';
        suffix++;
      }
      usedNames.add(finalName);

      final now = DateTime.now().millisecondsSinceEpoch;
      final config = McpServerConfig(
        id: const Uuid().v4(),
        name: finalName,
        displayName: originalName,
        transport: mcpTransportFromString(transport),
        url: url,
        command: effectiveCommand,
        args: argsJson,
        env: envJson,
        headers: headersJson,
        // 安全默认：导入后不自动启用，由用户确认后手动开启
        enabled: false,
        createdAt: now,
        updatedAt: now,
      );

      items.add(
        McpImportItem(
          config: config,
          authHeader: (authHeader != null && authHeader!.trim().isNotEmpty)
              ? authHeader!.trim()
              : null,
          existsInDb: existingNames.contains(finalName),
          renameNote: finalName == originalName
              ? null
              : '「$originalName」->「$finalName」',
        ),
      );
    });

    return (items: items, errors: errors);
  }

  /// 2026-09-15 mcp-remote桥接配置识别：
  /// `npx [-y] mcp-remote[@ver] <url> [--transport sse-only|http-only|...]`
  /// 与 `--header "K: V"` → 转换为远程直连server(transport按参数，缺省http)。
  /// 命中返回转换结果；非此形态返回null按普通stdio导入。
  /// mcp-remote是给不支持远程直连的客户端用的桥(本地进程内转SSE/HTTP)，
  /// 我们客户端本身支持直连——转换后免本地node依赖且少一层进程
  ({String transport, String url, String? headersJson, String? authHeader})?
  _tryExtractMcpRemoteBridge(String command, dynamic rawArgs) {
    // 命令名归一(去路径与.cmd后缀)：npx/bunx/node/pnpm 才可能桥接
    final cmd = command.toLowerCase().split(RegExp(r'[\\/]')).last;
    const launchers = {'npx', 'npx.cmd', 'bunx', 'bunx.cmd', 'node', 'pnpm'};
    if (!launchers.contains(cmd)) return null;

    List<String> args;
    if (rawArgs is List) {
      args = rawArgs.map((e) => e.toString()).toList();
    } else if (rawArgs is String && rawArgs.trim().isNotEmpty) {
      args = rawArgs.trim().split(RegExp(r'\s+'));
    } else {
      return null;
    }

    // 跳过 -y/-g/--yes 等安装标志定位包名
    var i = 0;
    while (i < args.length && args[i].startsWith('-')) {
      i++;
    }
    if (i >= args.length) return null;
    // 包名兼容 mcp-remote / mcp-remote@0.x.y
    if (args[i].split('@').first != 'mcp-remote') return null;
    i++;

    // 紧随包名的第一个参数必须是http(s) URL
    if (i >= args.length) return null;
    final url = args[i];
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.isEmpty) {
      return null;
    }
    i++;

    // 解析剩余参数：--transport <mode>；--header "K: V"；其余忽略
    var transportMode = '';
    final headers = <String, String>{};
    String? authHeader;
    while (i < args.length) {
      final a = args[i];
      if ((a == '--transport' || a == '-t') && i + 1 < args.length) {
        transportMode = args[i + 1].toLowerCase();
        i += 2;
      } else if (a == '--header' && i + 1 < args.length) {
        final h = args[i + 1];
        final idx = h.indexOf(':');
        if (idx > 0) {
          final k = h.substring(0, idx).trim();
          final v = h.substring(idx + 1).trim();
          if (k.toLowerCase() == 'authorization') {
            authHeader = v;
          } else if (k.isNotEmpty) {
            headers[k] = v;
          }
        }
        i += 2;
      } else {
        i++;
      }
    }
    // mcp-remote的transport策略：sse-only/sse-first走SSE；
    // http-only/http-first及缺省(http-first默认)走Streamable HTTP
    final transport = transportMode.startsWith('sse') ? 'sse' : 'http';

    return (
      transport: transport,
      url: url,
      headersJson: headers.isEmpty ? null : jsonEncode(headers),
      authHeader: (authHeader != null && authHeader.trim().isNotEmpty)
          ? authHeader.trim()
          : null,
    );
  }

  int _now() => DateTime.now().millisecondsSinceEpoch;
}
