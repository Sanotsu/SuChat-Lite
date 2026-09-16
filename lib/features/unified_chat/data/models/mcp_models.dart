import 'openai_request.dart';

/// MCP server 传输类型
/// 2026-09-11 MCP集成 P0-2
enum McpTransport {
  /// Streamable HTTP 远程(全平台支持，P1主推)
  http,

  /// 本地子进程(桌面端，P2)
  stdio,

  /// legacy HTTP+SSE(兼容旧server，P3)
  sse,
}

McpTransport mcpTransportFromString(String? value) {
  switch (value) {
    case 'stdio':
      return McpTransport.stdio;
    case 'sse':
      return McpTransport.sse;
    case 'http':
    default:
      return McpTransport.http;
  }
}

/// MCP server 配置模型
/// 对应DB表 unified_mcp_server(v7)；认证头敏感值不入库，
/// 存 UnifiedSecureStorage(键 `mcp_auth_id`)
class McpServerConfig {
  final String id;

  /// 命名空间名(唯一)，仅 [a-zA-Z0-9_-]，用于工具名 `mcp__name__tool`
  final String name;

  /// UI显示名
  final String displayName;
  final McpTransport transport;

  /// http/sse: 端点地址
  final String? url;

  /// stdio: 可执行文件(P2)
  final String? command;

  /// stdio: 参数 JSON数组字符串(P2)
  final String? args;

  /// stdio: 环境变量 JSON对象字符串(P2)
  final String? env;

  /// http: 非敏感自定义头 JSON对象字符串(如 Accept)
  final String? headers;
  final bool enabled;

  /// 内置测试源(DeepWiki等)不允许删除仅允许停用
  final bool isBuiltIn;

  /// 2026-09-12 搜索源标记：标记为搜索源的server，其工具不随MCP开关
  /// 全量注入，只通过"联网搜索"渠道注入(全局搜索渠道偏好控制)，
  /// 避免与第三方web_search/平台自带搜索重复
  final bool isSearchSource;

  /// 2026-09-14 P3-1 审批确认：该server每次工具调用前需用户确认
  /// (opencode式授权；写文件/执行命令类server建议开启)
  final bool approvalRequired;

  /// 2026-09-14 P3-7 工具列表离线缓存(最近一次连接成功的listTools
  /// JSON)；server不可达时展示/注入此缓存，仅内部读写，编辑弹窗不管
  final String? toolsCache;

  /// 2026-09-15 P4-2 OAuth授权码流：预注册客户端ID(留空=SDK动态注册)
  final String? oauthClientId;

  /// 2026-09-15 P4-2 OAuth授权码流：请求的scope空格分隔(留空=按
  /// server challenge要求)
  final String? oauthScopes;
  final int createdAt;
  final int updatedAt;

  const McpServerConfig({
    required this.id,
    required this.name,
    required this.displayName,
    this.transport = McpTransport.http,
    this.url,
    this.command,
    this.args,
    this.env,
    this.headers,
    this.enabled = true,
    this.isBuiltIn = false,
    this.isSearchSource = false,
    this.approvalRequired = false,
    this.toolsCache,
    this.oauthClientId,
    this.oauthScopes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory McpServerConfig.fromMap(Map<String, dynamic> map) {
    return McpServerConfig(
      id: map['id'] as String,
      name: map['name'] as String,
      displayName: (map['display_name'] as String?) ?? map['name'] as String,
      transport: mcpTransportFromString(map['transport'] as String?),
      url: map['url'] as String?,
      command: map['command'] as String?,
      args: map['args'] as String?,
      env: map['env'] as String?,
      headers: map['headers'] as String?,
      enabled: (map['enabled'] as int? ?? 1) == 1,
      isBuiltIn: (map['is_built_in'] as int? ?? 0) == 1,
      isSearchSource: (map['is_search_source'] as int? ?? 0) == 1,
      approvalRequired: (map['approval_required'] as int? ?? 0) == 1,
      toolsCache: map['tools_cache'] as String?,
      oauthClientId: map['oauth_client_id'] as String?,
      oauthScopes: map['oauth_scopes'] as String?,
      createdAt: map['created_at'] as int? ?? 0,
      updatedAt: map['updated_at'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'display_name': displayName,
      'transport': transport == McpTransport.stdio
          ? 'stdio'
          : transport == McpTransport.sse
          ? 'sse'
          : 'http',
      'url': url,
      'command': command,
      'args': args,
      'env': env,
      'headers': headers,
      'enabled': enabled ? 1 : 0,
      'is_built_in': isBuiltIn ? 1 : 0,
      'is_search_source': isSearchSource ? 1 : 0,
      'approval_required': approvalRequired ? 1 : 0,
      'tools_cache': toolsCache,
      'oauth_client_id': oauthClientId,
      'oauth_scopes': oauthScopes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  McpServerConfig copyWith({
    String? id,
    String? name,
    String? displayName,
    McpTransport? transport,
    String? url,
    String? command,
    String? args,
    String? env,
    String? headers,
    bool? enabled,
    bool? isBuiltIn,
    bool? isSearchSource,
    bool? approvalRequired,
    String? toolsCache,
    String? oauthClientId,
    String? oauthScopes,
    int? createdAt,
    int? updatedAt,
  }) {
    return McpServerConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      transport: transport ?? this.transport,
      url: url ?? this.url,
      command: command ?? this.command,
      args: args ?? this.args,
      env: env ?? this.env,
      headers: headers ?? this.headers,
      enabled: enabled ?? this.enabled,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      isSearchSource: isSearchSource ?? this.isSearchSource,
      approvalRequired: approvalRequired ?? this.approvalRequired,
      toolsCache: toolsCache ?? this.toolsCache,
      oauthClientId: oauthClientId ?? this.oauthClientId,
      oauthScopes: oauthScopes ?? this.oauthScopes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 命名空间名校验(与DB UNIQUE一致)
  static bool isValidName(String name) {
    return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(name);
  }

  /// 2026-09-14 P2-4 导入名称规范化：Claude Desktop等来源的server名可能
  /// 含空格/中文/点号等非法字符——统一替换为下划线(保留原有可读部分)，
  /// displayName仍用原始名供UI展示
  static String sanitizeName(String raw) {
    final cleaned = raw.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return cleaned.length > 50 ? cleaned.substring(0, 50) : cleaned;
  }
}

/// 2026-09-14 P2-4 JSON批量导入的单条解析结果
class McpImportItem {
  final McpServerConfig config;

  /// 从headers.Authorization提取的认证头值(存secure storage不入库)
  final String? authHeader;

  /// name与库内已有server冲突(由UI决定跳过或覆盖)
  final bool existsInDb;

  /// 规范化说明(原始名->规范化名)，名称未变动时为null
  final String? renameNote;

  const McpImportItem({
    required this.config,
    this.authHeader,
    this.existsInDb = false,
    this.renameNote,
  });
}

/// 通用聊天工具提供者接口(方案4.5节)
/// P3-9收敛后有两个实现: McpServerManager、WebSearchToolManager——
/// 执行路由按注册顺序用canHandle分发，不再硬编码工具名分支
abstract class ChatToolProvider {
  /// 工具名命名空间前缀，''表示内置工具(如 web_search)。
  /// MCP实现返回 'mcp__'
  String get namespace;

  /// 是否能处理该工具名(P3-9 路由：按注册顺序第一个canHandle的分发)
  bool canHandle(String toolName);

  /// 懒初始化(连接server/读取密钥)。实现须内部吞错并记录状态，
  /// 不应让单个server失败中断整体流程
  Future<void> ensureReady();

  /// 当前可注入模型的工具定义(已带命名空间前缀)
  List<OpenAITool> getTools();

  /// 执行工具调用
  Future<ToolResult> handleToolCall(
    String toolName,
    Map<String, dynamic> arguments,
  );
}

/// 工具执行结果
/// [references] 为结果引用链接(搜索/文档来源)，走消息引用区展示；
/// P3-5起web_search与MCP工具均填充此字段(URL提取)，回收层统一去重合并
class ToolResult {
  final String content;
  final List<Map<String, dynamic>>? references;
  final Map<String, dynamic>? meta;

  const ToolResult({required this.content, this.references, this.meta});
}

/// 2026-09-14 P3-1 工具调用审批请求(P3-13泛化：MCP与内置工具统一)，
/// 推给UI横幅展示：标题+详情(命令文本/参数)
class ToolApprovalRequest {
  /// MCP server命名空间名；内置工具为null
  final String? serverName;

  /// 横幅标题(如 "csahre · write_file" / "执行终端命令")
  final String title;

  /// 展示详情(MCP=参数JSON缩进；内置shell=完整命令文本)
  final String displayDetail;

  /// 会话级"总是允许"的规则键(MCP=serverName；内置shell=builtin:命令首词)
  final String sessionAllowKey;

  const ToolApprovalRequest({
    this.serverName,
    required this.title,
    required this.displayDetail,
    required this.sessionAllowKey,
  });
}

/// 审批决策
enum ToolApprovalDecision { allow, deny }

/// 审批处理器签名(viewmodel注入，弹横幅等用户决定)
typedef ToolApprovalHandler =
    Future<ToolApprovalDecision> Function(ToolApprovalRequest request);
