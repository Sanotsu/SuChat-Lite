import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:mcp_dart/mcp_dart.dart';

import '../../../../../../core/storage/cus_get_storage.dart';
import '../../../../../../core/utils/simple_tools.dart';
import '../../models/mcp_models.dart';
import '../../models/openai_request.dart';
import 'mcp_desktop_oauth_provider.dart';
import 'mcp_runtime_checker.dart';
import 'mcp_server_config_service.dart';

/// MCP server连接会话(内部状态)
class _ServerSession {
  /// 2026-09-14 审批开关等配置变更需同步到此副本，故不可final
  McpServerConfig config;
  McpClient? client;
  bool connected = false;
  String? lastError;

  /// 工具列表缓存(连接成功后listTools结果)
  List<Tool> tools = [];

  /// 2026-09-15 P4-2 OAuth provider(桌面端远程server持有，断开时释放
  /// loopback回调server)
  McpDesktopOAuthProvider? oauthProvider;

  _ServerSession(this.config);
}

/// MCP工具管理器(ChatToolProvider第一个实现，方案4.5节)
///
/// 职责：
/// - 管理多个MCP server连接生命周期(懒连接/超时/重试)
/// - 聚合各server工具列表，注入模型时转换为 OpenAITool
/// - 工具名命名空间: `mcp__serverName__toolName`
/// - 执行路由：按命名空间解析回server并调用
///
/// 用法(unified_chat_service P1接入)：
///   final tools = McpServerManager().getTools();      // 注入request.tools
///   final result = await McpServerManager().handleToolCall(name, args);
class McpServerManager implements ChatToolProvider {
  // 单例
  static final McpServerManager _instance = McpServerManager._internal();
  factory McpServerManager() => _instance;
  static McpServerManager get instance => _instance;
  McpServerManager._internal();

  final McpServerConfigService _configService = McpServerConfigService();

  /// namespace前缀(实现ChatToolProvider)
  @override
  String get namespace => _namespacePrefix;

  /// 仅处理 mcp__ 前缀工具
  @override
  bool canHandle(String toolName) => toolName.startsWith(_namespacePrefix);

  /// 是否存在启用的搜索源server(2026-09-15 诊断提示用：搜索源工具
  /// 只走联网搜索渠道注入，MCP开关全量注入时会排除——若用户只开MCP
  /// 不开联网搜索，搜索源工具对模型完全不可见)
  bool get hasEnabledSearchSourceServers =>
      _sessions.values.any((s) => s.config.isSearchSource);

  static const String _namespacePrefix = 'mcp__';
  static const String _separator = '__';

  /// 连接超时(懒连接)
  static const Duration _connectTimeout = Duration(seconds: 8);

  /// 2026-09-14 P2-1 stdio连接超时：本地进程启动较慢，npx/uvx首次还可能
  /// 要下载依赖包，8s不够——放宽到30s
  static const Duration _stdioConnectTimeout = Duration(seconds: 30);

  /// 2026-09-14 P3-2 单工具执行超时：全局GetStorage配置(与service的
  /// toolCallTimeoutSec同key)，读时生效
  static Duration get callTimeout => Duration(
    seconds:
        CusGetStorage().box.read(_toolCallTimeoutKey) ?? _defaultTimeoutSec,
  );

  static const String _toolCallTimeoutKey = 'unified_chat_tool_timeout_sec';
  static const int _defaultTimeoutSec = 60;

  /// 当前版本号(MCP握手用)
  static const String _clientVersion = '0.1.5';

  /// 2026-09-15 P4-2 桌面端判断(OAuth loopback回调依赖dart:io与系统浏览器)
  static bool get _isDesktop =>
      !kIsWeb &&
      (io.Platform.isWindows || io.Platform.isMacOS || io.Platform.isLinux);

  /// serverId -> 会话
  final Map<String, _ServerSession> _sessions = {};

  /// 2026-09-14 P3-6 进行中的连接Future(按serverId)：并行工具调用可能
  /// 同时触发同一server懒连接，复用in-flight Future防双重连接泄漏进程
  final Map<String, Future<bool>> _connectingFutures = {};

  /// 2026-09-14 P3-1/P3-13 审批处理器(viewmodel注入，弹横幅等用户决定)。
  /// null=无UI接入直接放行(向后兼容)；决策流程见 handleToolCall
  ToolApprovalHandler? approvalHandler;

  /// 2026-09-15 P4-3 sampling处理器(service注入：server反向调用本机
  /// LLM补全)。null=声明能力但请求到达时返回methodNotFound错误。
  /// 实现见 unified_chat_service._handleMcpSampling
  Future<CreateMessageResult> Function(CreateMessageRequest params)?
  samplingHandler;

  /// 初始化标记：发消息前确保启用的server已加载配置
  bool _initialized = false;

  /// 工具集变化通知(设置页/工具列表刷新用)
  final ValueNotifier<int> toolsRevision = ValueNotifier<int>(0);

  /// 确保启用的server配置已加载(不主动连接，连接是懒式的)
  Future<void> initialize({bool force = false}) async {
    if (_initialized && !force) return;

    final enabledServers = await _configService.getEnabledServers();

    // 移除已禁用/已删除server的会话(断开连接)
    final enabledIds = enabledServers.map((s) => s.id).toSet();
    for (final id in List<String>.from(_sessions.keys)) {
      if (!enabledIds.contains(id)) {
        await _disconnect(id);
      }
    }

    // 新增启用的server建会话占位(未连接)；已存在的session同步最新
    // config——2026-09-14 实测修复：原putIfAbsent对已存在的session不
    // 更新config副本，导致审批开关/搜索源标记等改完依旧用旧值判断
    for (final server in enabledServers) {
      final existing = _sessions[server.id];
      if (existing == null) {
        _sessions[server.id] = _ServerSession(server);
      } else {
        existing.config = server;
      }
    }

    _initialized = true;
    pl.i(
      'MCP管理器初始化完成 - 启用server: '
      '${enabledServers.map((s) => s.name).join(', ')}',
    );
  }

  @override
  Future<void> ensureReady() async {
    await initialize();
  }

  /// 重新加载配置(设置页变更后调用)：断开已禁用/已删除server的会话，
  /// 仍启用server的现有连接保留
  Future<void> reinitialize() async {
    await initialize(force: true);
    _notifyToolsChanged();
  }

  /// 确保所有启用server已尝试连接(懒连接入口，发消息前调用)。
  /// 并行连接互不阻塞；失败的server本轮跳过(getTools不聚合其工具)，
  /// 不抛出——单server不可用不应阻断聊天
  Future<void> ensureAllConnected() async {
    await initialize();

    final ids = List<String>.from(_sessions.keys);
    if (ids.isEmpty) return;

    await Future.wait(ids.map(connectServer));
  }

  /// 当前是否有任何可用的MCP工具(已启用且至少一个server可用)
  /// P3-7：连接失败但存在离线缓存的server也计入
  bool hasAvailableTools() {
    return _sessions.values.any(
      (s) =>
          (s.connected && s.tools.isNotEmpty) || _cachedToolsOf(s).isNotEmpty,
    );
  }

  /// 指定server的连接状态(供UI展示)
  bool isConnected(String serverId) => _sessions[serverId]?.connected ?? false;

  String? lastErrorOf(String serverId) => _sessions[serverId]?.lastError;

  /// 获取server的工具列表：已连接用内存缓存；未连接回落DB离线缓存
  /// (P3-7，server不可达时降级可用)
  List<Tool> toolsOf(String serverId) {
    final session = _sessions[serverId];
    if (session != null) {
      if (session.connected && session.tools.isNotEmpty) return session.tools;
      return _cachedToolsOf(session);
    }
    return [];
  }

  /// P3-7 解析session.config.toolsCache(损坏JSON静默忽略)
  List<Tool> _cachedToolsOf(_ServerSession session) {
    final raw = session.config.toolsCache?.trim() ?? '';
    if (raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(Tool.fromJson)
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  // ---------------------------------------------------------------------------
  // ChatToolProvider: 工具注入
  // ---------------------------------------------------------------------------

  /// 聚合所有已连接server的工具，转换为带命名空间的 OpenAITool
  /// (注入 request.tools；与 web_search 工具互不影响)
  /// [excludeSearchSources] 2026-09-12：排除标记为"搜索源"的server——
  /// 搜索源server的工具只通过联网搜索渠道注入(全局渠道偏好控制)，
  /// 避免与第三方web_search/平台自带搜索重复注入
  @override
  List<OpenAITool> getTools({bool excludeSearchSources = false}) {
    final result = <OpenAITool>[];

    for (final session in _sessions.values) {
      if (excludeSearchSources && session.config.isSearchSource) continue;

      // P3-7：已连接用内存工具；未连接回落离线缓存(降级注入，
      // 调用失败会回填错误文本由模型解释)
      final tools = session.connected ? session.tools : _cachedToolsOf(session);
      for (final tool in tools) {
        result.add(_toOpenAITool(session.config, tool));
      }
    }
    return result;
  }

  /// 2026-09-12 聚合"搜索源"server的工具(联网渠道偏好选中MCP时注入用)。
  /// 未连接的搜索源server回落离线缓存(P3-7)
  List<OpenAITool> getSearchSourceTools() {
    final result = <OpenAITool>[];

    for (final session in _sessions.values) {
      if (!session.config.isSearchSource) continue;

      final tools = session.connected ? session.tools : _cachedToolsOf(session);
      for (final tool in tools) {
        result.add(_toOpenAITool(session.config, tool));
      }
    }
    return result;
  }

  /// 是否存在已连接的搜索源server(渠道可用性判断)
  /// P3-7：连接失败但有离线缓存的搜索源也计入
  bool hasConnectedSearchSource() {
    return _sessions.values.any(
      (s) =>
          s.config.isSearchSource &&
          ((s.connected && s.tools.isNotEmpty) || _cachedToolsOf(s).isNotEmpty),
    );
  }

  /// 单个MCP工具 -> OpenAI function 工具
  /// MCP inputSchema(JSON Schema) 直接透传给 OpenAIFunction.parameters
  OpenAITool _toOpenAITool(McpServerConfig config, Tool tool) {
    return OpenAITool.function(
      OpenAIFunction(
        name: namespacedToolName(config.name, tool.name),
        description: _buildToolDescription(config, tool),
        parameters: tool.inputSchema.toJson(),
      ),
    );
  }

  /// 描述前附server来源，帮助模型区分同名工具
  String _buildToolDescription(McpServerConfig config, Tool tool) {
    final desc = (tool.description ?? '').trim();
    final prefix = '[MCP:${config.displayName}] ';
    return desc.isEmpty ? prefix.trim() : '$prefix$desc';
  }

  // ---------------------------------------------------------------------------
  // 命名空间转换
  // ---------------------------------------------------------------------------

  /// 生成命名空间工具名: `mcp__serverName__toolName`
  static String namespacedToolName(String serverName, String toolName) {
    return '$_namespacePrefix$serverName$_separator$toolName';
  }

  /// 解析命名空间工具名；非MCP工具返回null
  static ({String serverName, String toolName})? parseNamespacedToolName(
    String namespacedName,
  ) {
    if (!namespacedName.startsWith(_namespacePrefix)) return null;
    final rest = namespacedName.substring(_namespacePrefix.length);
    final idx = rest.indexOf(_separator);
    if (idx <= 0 || idx == rest.length - _separator.length) return null;
    return (
      serverName: rest.substring(0, idx),
      toolName: rest.substring(idx + _separator.length),
    );
  }

  // ---------------------------------------------------------------------------
  // ChatToolProvider: 工具执行
  // ---------------------------------------------------------------------------

  @override
  Future<ToolResult> handleToolCall(
    String toolName,
    Map<String, dynamic> arguments,
  ) async {
    final parsed = parseNamespacedToolName(toolName);
    if (parsed == null) {
      throw FormatException('无法解析MCP工具名: $toolName');
    }

    final session = _sessions.values
        .where((s) => s.config.name == parsed.serverName)
        .firstOrNull;
    if (session == null) {
      throw StateError('MCP server未启用或不存在: ${parsed.serverName}');
    }

    // 2026-09-14 P3-1 审批确认：开启审批的server每次调用前询问用户，
    // 在懒连接之前执行——拒绝时不启动子进程(省资源)。
    // 拒绝是正常业务路径：文本回填给模型让其自行调整，非异常
    if (session.config.approvalRequired && approvalHandler != null) {
      final decision = await approvalHandler!(
        ToolApprovalRequest(
          serverName: session.config.name,
          title: '${session.config.displayName} · ${parsed.toolName}',
          displayDetail: arguments.isEmpty
              ? '(无参数)'
              : const JsonEncoder.withIndent('  ').convert(arguments),
          sessionAllowKey: session.config.name,
        ),
      );
      if (decision == ToolApprovalDecision.deny) {
        pl.i('用户拒绝MCP工具调用: ${session.config.name}.${parsed.toolName}');
        return ToolResult(
          content:
              '用户拒绝了本次工具调用(${parsed.toolName})。'
              '请尊重用户决定，不要重试相同调用，'
              '改为口头说明或询问用户希望如何处理。',
        );
      }
    }

    // 未连接则现场补连(懒连接)
    if (!session.connected) {
      await connectServer(session.config.id);
      if (!session.connected) {
        throw StateError(
          'MCP server连接失败(${parsed.serverName}): ${session.lastError}',
        );
      }
    }

    pl.i('调用MCP工具: ${session.config.name}.${parsed.toolName}');

    final client = session.client!;
    final result = await client
        .callTool(CallToolRequest(name: parsed.toolName, arguments: arguments))
        .timeout(
          callTimeout,
          onTimeout: () {
            throw TimeoutException(
              'MCP工具执行超时(${callTimeout.inSeconds}s): ${parsed.toolName}',
            );
          },
        );

    // isError 时把文本内容抛出或原样返回？
    // 沿用现有web_search模式：错误文本作为content回填让模型自行解释，
    // 但要加明显前缀
    final contentText = _extractContentText(result);
    if (result.isError) {
      return ToolResult(content: '工具执行出错: $contentText');
    }

    // 2026-09-14 P3-5 结构化引用：从结果文本提取URL进消息引用区
    // (复用web_search引用机制，由service层去重合并)
    return ToolResult(
      content: contentText,
      references: extractReferencesFromText(contentText),
    );
  }

  /// P3-5 URL提取：http(s)开头到空白/尖括号/圆括号/引号/CJK(markdown
  /// 链接语法的括号与闭合引号、URL后紧贴的中文与全角标点均不误捕——
  /// 工具文本/AI正文中的URL几乎都是ASCII编码形式，遇中文即边界)；
  /// 尾部半角标点在下方清理
  static final RegExp _urlPattern = RegExp(
    r'''https?://[^\s<>()"'\u3000-\u303f\u4e00-\u9fff\uff00-\uffef]+''',
  );

  /// P3-5 从工具结果文本提取URL引用(去重，域名做标题，最多10条)；
  /// 尾部标点误捕清理(半角+全角中文标点——2026-09-15补)：
  /// 句号/逗号/分号/冒号/闭合括号/引号/书名号/引号等
  static List<Map<String, dynamic>> extractReferencesFromText(String text) {
    final seen = <String>{};
    final refs = <Map<String, dynamic>>[];
    for (final match in _urlPattern.allMatches(text)) {
      final url = match
          .group(0)!
          .replaceAll(RegExp(r'''[.,;:!?)\]}>,+"'.。，；：！）】》”’、]+$'''), '');
      if (seen.contains(url)) continue;
      seen.add(url);
      var host = url;
      try {
        final u = Uri.parse(url);
        if (u.host.isNotEmpty) host = u.host;
      } catch (_) {}
      refs.add({'title': host, 'url': url, 'description': '来自工具返回结果'});
      if (refs.length >= 10) break;
    }
    return refs;
  }

  /// 拼接 CallToolResult.content 的文本部分
  String _extractContentText(CallToolResult result) {
    final buffer = StringBuffer();
    for (final item in result.content) {
      if (item is TextContent) {
        if (buffer.isNotEmpty) buffer.write('\n');
        buffer.write(item.text);
      } else if (item is ImageContent) {
        if (buffer.isNotEmpty) buffer.write('\n');
        buffer.write('[图片内容，类型: ${item.mimeType}]');
      } else if (item is AudioContent) {
        if (buffer.isNotEmpty) buffer.write('\n');
        buffer.write('[音频内容，类型: ${item.mimeType}]');
      } else {
        if (buffer.isNotEmpty) buffer.write('\n');
        buffer.write('[不支持的内容类型: ${item.runtimeType}]');
      }
    }
    final text = buffer.toString().trim();
    return text.isEmpty ? '(工具返回空结果)' : text;
  }

  // ---------------------------------------------------------------------------
  // P3-3/P3-4 资源与提示词模板(设置页浏览对话框用，均懒连接+超时保护)
  // ---------------------------------------------------------------------------

  /// 取可用client(懒连接)；server不存在/连接失败抛错由UI捕获展示。
  /// 2026-09-15 修复：懒连接下session占位只在initialize时为启用server
  /// 创建——禁用/已删除的server(工具缓存可能仍在列表里)进入提示词/
  /// 资源浏览时报"server未启用或不存在"这类含糊错误；现在分别给出
  /// 明确文案，启用但无占位的server补建并连接
  Future<McpClient> _requireClient(String serverId) async {
    await initialize();
    var session = _sessions[serverId];
    if (session == null) {
      final config = await _configService.getServerById(serverId);
      if (config == null) {
        throw StateError('该server不存在，可能已被删除');
      }
      if (!config.enabled) {
        throw StateError('server「${config.name}」已禁用，请先在设置中启用');
      }
      // 启用但无占位(理论少见)：补建后走正常连接
      session = _ServerSession(config);
      _sessions[serverId] = session;
    }
    if (!session.connected) {
      await connectServer(serverId);
      if (!session.connected) {
        throw StateError('连接失败: ${session.lastError}');
      }
    }
    return session.client!;
  }

  /// server是否声明了prompts能力(未声明时浏览入口直接显示"未提供"，
  /// 不发无效请求——多数工具型server无此能力)
  bool _supportsPrompts(McpClient client) =>
      client.getServerCapabilities()?.prompts != null;

  /// server是否声明了resources能力
  bool _supportsResources(McpClient client) =>
      client.getServerCapabilities()?.resources != null;

  /// 列出server资源(P3-3)。server未声明能力返回空列表(UI显示"未提供")；
  /// 声明了但方法不存在(-32601)同样降级为空——2026-09-15 修复用户实测
  /// "McpError -32601"直接炸在对话框上的问题
  Future<List<Resource>> listResourcesOf(String serverId) async {
    final client = await _requireClient(serverId);
    if (!_supportsResources(client)) return const [];
    try {
      final result = await client.listResources().timeout(callTimeout);
      return result.resources;
    } on McpError catch (e) {
      if (e.code == ErrorCode.methodNotFound.value) return const [];
      rethrow;
    }
  }

  /// 读取资源内容为文本(P3-3)：text直接返回；blob标注类型与大小省略
  Future<String> readResourceTextOf(String serverId, String uri) async {
    final client = await _requireClient(serverId);
    if (!_supportsResources(client)) {
      throw StateError('该server未提供资源读取能力');
    }
    final result = await client
        .readResource(ReadResourceRequest(uri: uri))
        .timeout(callTimeout);
    final buffer = StringBuffer();
    for (final c in result.contents) {
      if (buffer.isNotEmpty) buffer.write('\n\n');
      if (c is TextResourceContents) {
        buffer.write(c.text);
      } else if (c is BlobResourceContents) {
        buffer.write(
          '[二进制内容 ${c.mimeType ?? '未知类型'}，'
          '约${(c.blob.length * 3 ~/ 4)}字节，已省略]',
        );
      }
    }
    final text = buffer.toString().trim();
    return text.isEmpty ? '(资源内容为空)' : text;
  }

  /// 列出server提示词模板(P3-4)。能力预检与-32601降级同listResourcesOf
  Future<List<Prompt>> listPromptsOf(String serverId) async {
    final client = await _requireClient(serverId);
    if (!_supportsPrompts(client)) return const [];
    try {
      final result = await client.listPrompts().timeout(callTimeout);
      return result.prompts;
    } on McpError catch (e) {
      if (e.code == ErrorCode.methodNotFound.value) return const [];
      rethrow;
    }
  }

  /// 获取提示词模板渲染后的对话文本(P3-4，角色标注，供复制/填入输入框)
  Future<String> getPromptTextOf(
    String serverId,
    String name,
    Map<String, String> args,
  ) async {
    final client = await _requireClient(serverId);
    if (!_supportsPrompts(client)) {
      throw StateError('该server未提供提示词能力');
    }
    final result = await client
        .getPrompt(GetPromptRequest(name: name, arguments: args))
        .timeout(callTimeout);
    final buffer = StringBuffer();
    for (final m in result.messages) {
      final role = m.role == PromptMessageRole.assistant ? 'assistant' : 'user';
      final text = m.content is TextContent
          ? (m.content as TextContent).text
          : '[非文本内容: ${m.content.runtimeType}]';
      if (buffer.isNotEmpty) buffer.write('\n\n');
      buffer.write('【$role】\n$text');
    }
    return buffer.toString().trim();
  }

  // ---------------------------------------------------------------------------
  // 连接生命周期
  // ---------------------------------------------------------------------------

  /// 懒连接指定server(带超时+失败重试1次)；重复调用已连接的直接返回
  /// 返回是否连接成功；失败原因记录在 session.lastError
  /// 2026-09-14 P3-6 并发锁：同一server的并行连接请求复用同一Future
  Future<bool> connectServer(String serverId) async {
    await initialize();

    final inFlight = _connectingFutures[serverId];
    if (inFlight != null) return inFlight;

    final future = _connectServerInternal(serverId);
    _connectingFutures[serverId] = future;
    try {
      return await future;
    } finally {
      _connectingFutures.remove(serverId);
    }
  }

  Future<bool> _connectServerInternal(String serverId) async {
    var session = _sessions[serverId];
    if (session == null) {
      final config = await _configService.getServerById(serverId);
      if (config == null || !config.enabled) {
        pl.w('MCP server不存在或未启用: $serverId');
        return false;
      }
      session = _ServerSession(config);
      _sessions[serverId] = session;
    }

    if (session.connected) return true;

    // 失败重试1次
    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        session.lastError = null;
        await _connectOnce(session);
        _notifyToolsChanged();
        return true;
      } catch (e) {
        pl.w('MCP server连接失败(${session.config.name}) 第$attempt次: $e');
        session.lastError = e.toString();
        session.connected = false;
        session.client = null;
        if (attempt == 1) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }
    }
    return false;
  }

  Future<void> _connectOnce(_ServerSession session) async {
    final config = session.config;

    // 断开旧client(重试场景)
    final oldClient = session.client;
    if (oldClient != null) {
      try {
        await oldClient.close();
      } catch (_) {}
      session.client = null;
    }

    // 2026-09-15 P4-3 声明sampling能力并挂处理器(server可反向调用
    // 本机LLM；handler由service注入，未注入时请求返回methodNotFound)。
    // 注：onSamplingRequest是McpClient实例字段(非options构造参数)
    final client = McpClient(
      const Implementation(name: 'suchat_lite', version: _clientVersion),
      options: McpClientOptions(
        capabilities: ClientCapabilities(
          sampling: const ClientCapabilitiesSampling(),
        ),
      ),
    );
    client.onSamplingRequest = (params) async {
      final handler = samplingHandler;
      if (handler == null) {
        throw McpError(ErrorCode.methodNotFound.value, '客户端未启用sampling处理');
      }
      return handler(params);
    };

    McpDesktopOAuthProvider? oauthProvider;
    try {
      // 2026-09-14 P2-1 按传输类型构造transport
      final Transport transport;
      switch (config.transport) {
        case McpTransport.http:
          {
            if (config.url == null || config.url!.trim().isEmpty) {
              throw FormatException('MCP server ${config.name} 未配置URL');
            }
            final headers = await _configService.buildRequestHeaders(config);
            // 2026-09-15 P4-2 桌面端挂OAuth provider(401时自动触发
            // 浏览器授权；无OAuth需求时零影响)。
            // provider创建/赋值分两步，transport只赋值一次(final)
            StreamableHttpClientTransport httpTransport;
            if (_isDesktop) {
              McpDesktopOAuthProvider? provider;
              try {
                provider = await McpDesktopOAuthProvider.create(config);
                final t = StreamableHttpClientTransport(
                  Uri.parse(config.url!.trim()),
                  opts: StreamableHttpClientTransportOptions(
                    requestInit: headers.isEmpty ? null : {'headers': headers},
                    authProvider: provider,
                  ),
                );
                provider.transport = t;
                oauthProvider = provider;
                httpTransport = t;
              } catch (e) {
                // loopback端口绑定失败等——降级为无OAuth直连
                pl.w('OAuth provider创建失败(${config.name})，按无授权连接: $e');
                try {
                  await provider?.dispose();
                } catch (_) {}
                httpTransport = StreamableHttpClientTransport(
                  Uri.parse(config.url!.trim()),
                  opts: StreamableHttpClientTransportOptions(
                    requestInit: headers.isEmpty ? null : {'headers': headers},
                  ),
                );
              }
            } else {
              httpTransport = StreamableHttpClientTransport(
                Uri.parse(config.url!.trim()),
                opts: StreamableHttpClientTransportOptions(
                  requestInit: headers.isEmpty ? null : {'headers': headers},
                ),
              );
            }
            transport = httpTransport;
          }
        case McpTransport.stdio:
          {
            if (kIsWeb ||
                !(io.Platform.isWindows ||
                    io.Platform.isMacOS ||
                    io.Platform.isLinux)) {
              throw UnsupportedError('stdio本地进程仅桌面端(Windows/macOS/Linux)支持');
            }
            if (config.command == null || config.command!.trim().isEmpty) {
              throw FormatException('MCP server ${config.name} 未配置启动命令');
            }
            // 2026-09-14 P2-5 实测修复：裸命令名(如npx)解析为完整可执行
            // 路径——Windows的Process.start不按PATHEXT解析，直接报
            // "系统找不到指定的文件"
            final resolvedCommand = await McpRuntimeChecker.resolveCommandPath(
              config.command!,
            );
            if (resolvedCommand == null) {
              throw FormatException(
                '未找到命令 "${config.command!.trim()}"，'
                '请确认已安装且在PATH中(MCP设置页有运行时检测)',
              );
            }
            transport = StdioClientTransport(
              StdioServerParameters(
                command: resolvedCommand,
                args: _parseArgs(config),
                environment: _parseEnv(config),
                // stderr捕获为流而非inherit，避免server日志污染宿主控制台
                stderrMode: io.ProcessStartMode.normal,
              ),
            );
          }
        case McpTransport.sse:
          {
            // 2026-09-14 P3-8 legacy SSE兼容：旧规范(2024-11-05)分离端点
            // 传输，SDK已标记@Deprecated——仅用于只支持旧SSE的老server
            if (config.url == null || config.url!.trim().isEmpty) {
              throw FormatException('MCP server ${config.name} 未配置URL');
            }
            final headers = await _configService.buildRequestHeaders(config);
            // ignore: deprecated_member_use
            transport = SseClientTransport(
              Uri.parse(config.url!.trim()),
              // ignore: deprecated_member_use
              opts: SseClientTransportOptions(
                headers: headers.isEmpty ? const {} : headers,
              ),
            );
          }
      }

      // stdio握手更慢(进程启动+首次依赖下载)，用放宽的超时；
      // 2026-09-15 P4-2 OAuth首次授权场景：provider存在且无缓存令牌时
      // 需要等用户在浏览器完成授权(内部自带5分钟上限)，connect超时
      // 相应放宽——令牌已缓存/无provider的server仍用常规超时
      var timeout = config.transport == McpTransport.stdio
          ? _stdioConnectTimeout
          : _connectTimeout;
      final needsOAuthFirstGrant =
          oauthProvider != null && await oauthProvider.tokens() == null;
      if (needsOAuthFirstGrant) {
        timeout = const Duration(minutes: 6);
      }

      // 握手+初始化
      await client.connect(transport).timeout(timeout);

      // 连接成功立即拉取工具列表
      final toolsResult = await client.listTools().timeout(timeout);

      session.client = client;
      session.connected = true;
      session.tools = toolsResult.tools;
      session.oauthProvider = oauthProvider;
      oauthProvider = null; // 所有权移交session，失败路径不再释放

      // 2026-09-14 P3-7 工具列表写离线缓存(下次server不可达时降级可用)
      try {
        final cacheJson = jsonEncode(
          toolsResult.tools.map((t) => t.toJson()).toList(),
        );
        session.config = session.config.copyWith(toolsCache: cacheJson);
        await _configService.saveToolsCache(config.id, cacheJson);
      } catch (e) {
        pl.w('工具离线缓存写入失败(${config.name}): $e');
      }

      pl.i(
        'MCP server连接成功: ${config.name}(${config.transport.name})，'
        '工具数: ${session.tools.length} '
        '(${session.tools.map((t) => t.name).join(', ')})',
      );
    } catch (_) {
      // 失败时关闭client——stdio场景终止已启动的子进程，防止进程泄漏
      try {
        await client.close();
      } catch (_) {}
      // 释放未移交的OAuth provider(loopback回调server)
      try {
        await oauthProvider?.dispose();
      } catch (_) {}
      rethrow;
    }
  }

  /// stdio args JSON数组字符串 -> `List<String>`
  List<String> _parseArgs(McpServerConfig config) {
    final raw = config.args?.trim() ?? '';
    if (raw.isEmpty) return const [];
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (e) {
      throw FormatException('MCP server ${config.name} 的参数不是合法JSON: $e');
    }
    if (decoded is List) return decoded.map((e) => e.toString()).toList();
    throw FormatException(
      'MCP server ${config.name} 的参数必须是JSON数组，如 ["--port","8080"]',
    );
  }

  /// stdio env JSON对象字符串 -> `Map<String, String>`
  Map<String, String> _parseEnv(McpServerConfig config) {
    final raw = config.env?.trim() ?? '';
    if (raw.isEmpty) return const {};
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (e) {
      throw FormatException('MCP server ${config.name} 的环境变量不是合法JSON: $e');
    }
    if (decoded is Map) {
      return decoded.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    }
    throw FormatException(
      'MCP server ${config.name} 的环境变量必须是JSON对象，如 {"API_KEY":"xxx"}',
    );
  }

  /// 断开指定server
  Future<void> _disconnect(String serverId) async {
    final session = _sessions.remove(serverId);
    if (session == null) return;

    final client = session.client;
    if (client != null) {
      try {
        await client.close();
      } catch (e) {
        pl.w('MCP server断开异常(${session.config.name}): $e');
      }
    }
    // 2026-09-15 P4-2 释放OAuth provider的loopback回调server
    try {
      await session.oauthProvider?.dispose();
    } catch (_) {}
    pl.i('MCP server已断开: ${session.config.name}');
  }

  /// 断开全部(测试连接后刷新/应用退出等场景)
  Future<void> disconnectAll() async {
    for (final id in List<String>.from(_sessions.keys)) {
      await _disconnect(id);
    }
    _notifyToolsChanged();
  }

  /// 断开并重连(设置页手动刷新)
  Future<bool> reconnectServer(String serverId) async {
    await _disconnect(serverId);
    return connectServer(serverId);
  }

  void _notifyToolsChanged() {
    toolsRevision.value++;
  }

  // ---------------------------------------------------------------------------
  // 设置页：测试连接
  // ---------------------------------------------------------------------------

  /// 测试配置是否可连接并返回工具名列表(不改变正式会话状态)
  /// [authHeader] 测试时使用的认证头值(编辑弹窗中尚未保存的场景)
  /// 2026-09-14 P2-3 支持stdio：测试会真实启动本地子进程，结束后清理
  Future<({bool ok, List<String> tools, String? error})> testConnection(
    McpServerConfig config, {
    String? authHeader,
    Map<String, String>? extraHeaders,
  }) async {
    McpClient? testClient;
    Transport? transport;
    McpDesktopOAuthProvider? testOAuthProvider;
    try {
      if (config.transport == McpTransport.stdio) {
        if (config.command == null || config.command!.trim().isEmpty) {
          return (ok: false, tools: const <String>[], error: '未配置启动命令');
        }
        final resolvedCommand = await McpRuntimeChecker.resolveCommandPath(
          config.command!,
        );
        if (resolvedCommand == null) {
          return (
            ok: false,
            tools: const <String>[],
            error: '未找到命令 "${config.command!.trim()}"，请确认已安装且在PATH中',
          );
        }
        transport = StdioClientTransport(
          StdioServerParameters(
            command: resolvedCommand,
            args: _parseArgs(config),
            environment: _parseEnv(config),
            stderrMode: io.ProcessStartMode.normal,
          ),
        );
      } else {
        if (config.url == null || config.url!.trim().isEmpty) {
          return (ok: false, tools: const <String>[], error: '未配置URL');
        }
        final headers = await _configService.buildRequestHeaders(config);
        if (authHeader != null && authHeader.trim().isNotEmpty) {
          headers['Authorization'] = authHeader.trim();
        }
        if (extraHeaders != null) {
          headers.addAll(extraHeaders);
        }
        // 2026-09-14 P3-8 legacy SSE兼容(仅老server需要)
        if (config.transport == McpTransport.sse) {
          // ignore: deprecated_member_use
          transport = SseClientTransport(
            Uri.parse(config.url!.trim()),
            // ignore: deprecated_member_use
            opts: SseClientTransportOptions(
              headers: headers.isEmpty ? const {} : headers,
            ),
          );
        } else {
          // 2026-09-15 P4-2 测试连接同样支持OAuth(桌面端；401触发浏览器授权)
          if (_isDesktop) {
            try {
              testOAuthProvider = await McpDesktopOAuthProvider.create(config);
            } catch (_) {
              testOAuthProvider = null;
            }
          }
          transport = StreamableHttpClientTransport(
            Uri.parse(config.url!.trim()),
            opts: StreamableHttpClientTransportOptions(
              requestInit: headers.isEmpty ? null : {'headers': headers},
              authProvider: testOAuthProvider,
            ),
          );
          testOAuthProvider?.transport = transport;
        }
      }

      testClient = McpClient(
        const Implementation(name: 'suchat_lite_test', version: _clientVersion),
        options: const McpClientOptions(),
      );

      // OAuth首次授权需要浏览器交互，放宽超时(与正式连接同策略)
      var timeout = config.transport == McpTransport.stdio
          ? _stdioConnectTimeout
          : _connectTimeout;
      final needsOAuthFirstGrant =
          testOAuthProvider != null && await testOAuthProvider.tokens() == null;
      if (needsOAuthFirstGrant) {
        timeout = const Duration(minutes: 6);
      }

      await testClient.connect(transport).timeout(timeout);
      final tools = await testClient.listTools().timeout(timeout);

      return (
        ok: true,
        tools: tools.tools.map((t) => t.name).toList(),
        error: null,
      );
    } catch (e) {
      // 2026-09-15 P4-2 OAuth错误友好化
      final message = e.toString();
      if (e is UnauthorizedError ||
          message.contains('Authentication required') ||
          message.contains('Unauthorized')) {
        return (
          ok: false,
          tools: const <String>[],
          error:
              '需要OAuth授权：浏览器授权窗口可能已打开，'
              '完成登录后再次点击测试；或在编辑中配置OAuth客户端ID',
        );
      }
      return (ok: false, tools: const <String>[], error: message);
    } finally {
      try {
        await testClient?.close();
      } catch (_) {}
      // 测试连接不保留会话状态，释放provider
      try {
        await testOAuthProvider?.dispose();
      } catch (_) {}
    }
  }
}
