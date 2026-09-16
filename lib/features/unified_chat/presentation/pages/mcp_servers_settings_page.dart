import 'package:flutter/material.dart';

import '../../../../core/storage/cus_get_storage.dart';
import '../../../../core/utils/screen_helper.dart';
import '../../../../shared/widgets/cus_content_width.dart';
import '../../data/models/mcp_models.dart';
import '../../data/services/mcp/mcp_runtime_checker.dart';
import '../../data/services/mcp/mcp_server_config_service.dart';
import '../../data/services/mcp/mcp_server_manager.dart';
import 'mcp_browse_dialogs.dart';
import 'mcp_import_dialog.dart';
import 'mcp_server_edit_dialog.dart';

/// MCP server 管理页
/// 2026-09-11 MCP集成 P1-4：内置测试源快捷启用 + 用户自建server
/// 增删改查 + 测试连接 + 工具列表查看
class McpServersSettingsPage extends StatefulWidget {
  const McpServersSettingsPage({super.key});

  @override
  State<McpServersSettingsPage> createState() => _McpServersSettingsPageState();
}

class _McpServersSettingsPageState extends State<McpServersSettingsPage> {
  final _configService = McpServerConfigService();
  final _manager = McpServerManager();

  List<McpServerConfig> _servers = [];

  /// 2026-09-14 P2-2 本地运行时探测结果(桌面端才有值，null=检测中)
  List<McpRuntimeStatus>? _runtimes;

  /// 2026-09-14 P3-11 内置终端命令工具开关(与viewmodel同key读写，
  /// 发送时由viewmodel读取传给service)
  static const String _shellToolEnabledKey = 'unified_chat_shell_tool_enabled';
  late bool _shellToolEnabled =
      CusGetStorage().box.read(_shellToolEnabledKey) == true;

  /// 展开工具列表的server id
  String? _expandedId;

  /// 正在测试/连接的server id
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _loadServers();
    _detectRuntimes();
  }

  Future<void> _detectRuntimes() async {
    final runtimes = await McpRuntimeChecker.detectRuntimes();
    if (!mounted) return;
    setState(() => _runtimes = runtimes);
  }

  /// 2026-09-14 P2-4 JSON批量导入入口
  Future<void> _importServers() async {
    final imported = await showDialog<bool>(
      context: context,
      builder: (context) => const McpImportDialog(),
    );
    if (imported == true) {
      await _manager.reinitialize();
      _loadServers();
    }
  }

  Future<void> _loadServers() async {
    final servers = await _configService.getAllServers();
    if (!mounted) return;
    setState(() => _servers = servers);

    // 启用的server尝试懒连接(刷新状态显示；失败静默由卡片标记)
    for (final server in servers) {
      if (server.enabled) {
        // ignore: unawaited_futures
        _manager.connectServer(server.id).then((ok) {
          if (mounted && ok) setState(() {});
        });
      }
    }
  }

  Future<void> _toggleServer(McpServerConfig server, bool enabled) async {
    await _configService.setServerEnabled(server.id, enabled);

    if (enabled) {
      setState(() => _busyIds.add(server.id));
      final ok = await _manager.connectServer(server.id);
      if (mounted) setState(() => _busyIds.remove(server.id));

      // 2026-09-11 实测反馈打通UX断层：server启用≠聊天时生效，
      // 必须在对话设置中打开会话级"MCP 工具"开关
      if (mounted && ok && _manager.getTools().isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已连接。请在对话设置中打开"MCP 工具"开关后，聊天中才会调用这些工具'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } else {
      await _manager.reinitialize();
    }
    _loadServers();
  }

  Future<void> _testServer(McpServerConfig server) async {
    setState(() => _busyIds.add(server.id));
    final ok = await _manager.reconnectServer(server.id);
    if (!mounted) return;
    setState(() => _busyIds.remove(server.id));

    if (ok) {
      final tools = _manager.toolsOf(server.id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('连接成功，共 ${tools.length} 个工具')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('连接失败: ${_manager.lastErrorOf(server.id) ?? "未知错误"}'),
        ),
      );
    }
    setState(() {});
  }

  Future<void> _deleteServer(McpServerConfig server) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除确认'),
        content: Text('确定删除 MCP server「${server.displayName}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _configService.deleteServer(server.id);
    await _manager.reinitialize();
    _loadServers();
  }

  /// 2026-09-14 P3-1 审批开关快捷切换：改库后必须reinitialize刷新
  /// manager内session持有的config副本，否则拦截判断仍用旧值
  Future<void> _toggleApproval(McpServerConfig server) async {
    await _configService.setApprovalRequired(
      server.id,
      !server.approvalRequired,
    );
    await _manager.reinitialize();
    _loadServers();
  }

  Future<void> _addOrEditServer([McpServerConfig? existing]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => McpServerEditDialog(existing: existing),
    );
    if (saved == true) {
      await _manager.reinitialize();
      _loadServers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CusContentWidth.form(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MCP 工具'),
          actions: [
            // 2026-09-14 P2-4 JSON批量导入
            IconButton(
              tooltip: '导入配置(JSON)',
              icon: const Icon(Icons.upload_file),
              onPressed: _importServers,
            ),
            IconButton(
              tooltip: '添加 MCP Server',
              icon: const Icon(Icons.add),
              onPressed: () => _addOrEditServer(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _addOrEditServer(),
          icon: const Icon(Icons.add),
          label: const Text('添加 Server'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHintCard(),
            const SizedBox(height: 12),
            _buildRuntimeCard(),
            const SizedBox(height: 12),
            _buildBuiltinToolsCard(),
            const SizedBox(height: 12),
            _buildAgentSettingsCard(),
            const SizedBox(height: 12),
            for (final server in _servers) ...[
              _buildServerCard(server),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHintCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                const Text(
                  '什么是 MCP？',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'MCP(Model Context Protocol)是连接大模型与外部工具的标准协议。'
              '启用下方 server 后，在对话设置中打开"MCP 工具"开关，'
              '模型即可调用这些 server 提供的工具(查文档、搜代码等)。\n'
              '注意：需使用支持"工具调用"能力的模型；工具调用可能产生'
              '额外请求，请知悉。',
              style: TextStyle(fontSize: 12.5, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  /// 2026-09-14 P3-11 内置工具卡(仅桌面显示)：shell_execute 全局开关。
  /// 与viewmodel的isShellToolEnabled读同一GetStorage键(发送时由
  /// viewmodel读取传给service)。安全闸：只读命令免审批、危险命令
  /// 直接拦截、其余每次执行前弹审批横幅
  Widget _buildBuiltinToolsCard() {
    if (!ScreenHelper.isDesktop()) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.terminal,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                const Text(
                  '内置工具',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            SwitchListTile(
              title: const Text('终端命令执行', style: TextStyle(fontSize: 14)),
              subtitle: const Text(
                '开启后支持工具调用的模型可在桌面执行命令(如查看文件、运行脚本)。'
                '安全策略：只读命令直接执行，危险命令直接拦截，其余每次执行前需你确认。默认关闭。',
                style: TextStyle(fontSize: 12),
              ),
              value: _shellToolEnabled,
              onChanged: (v) async {
                await CusGetStorage().box.write(_shellToolEnabledKey, v);
                setState(() => _shellToolEnabled = v);
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  /// 2026-09-14 P3-2 Agent执行设置卡：工具调用续传最大轮数与单工具
  /// 超时(全局GetStorage，service/manager读时生效，改动即时生效)
  static const String _toolRoundsKey = 'unified_chat_tool_rounds';
  static const String _toolTimeoutKey = 'unified_chat_tool_timeout_sec';
  static const List<int> _roundsChoices = [3, 5, 10, 15, 20];
  static const List<int> _timeoutChoices = [30, 60, 120, 300];

  Widget _buildAgentSettingsCard() {
    final rounds = CusGetStorage().box.read(_toolRoundsKey) ?? 10;
    final timeoutSec = CusGetStorage().box.read(_toolTimeoutKey) ?? 60;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Agent 执行设置',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Expanded(
                  child: Text('工具调用最大轮数', style: TextStyle(fontSize: 13.5)),
                ),
                DropdownButton<int>(
                  value: _roundsChoices.contains(rounds)
                      ? rounds
                      : _defaultRounds,
                  items: _roundsChoices
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(
                            '$v 轮',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) async {
                    if (v == null) return;
                    await CusGetStorage().box.write(_toolRoundsKey, v);
                    setState(() {});
                  },
                ),
              ],
            ),
            Row(
              children: [
                const Expanded(
                  child: Text('单工具执行超时', style: TextStyle(fontSize: 13.5)),
                ),
                DropdownButton<int>(
                  value: _timeoutChoices.contains(timeoutSec)
                      ? timeoutSec
                      : _defaultTimeout,
                  items: _timeoutChoices
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(
                            v >= 60 ? '${v ~/ 60} 分钟' : '$v 秒',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) async {
                    if (v == null) return;
                    await CusGetStorage().box.write(_toolTimeoutKey, v);
                    setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  static const int _defaultRounds = 10;
  static const int _defaultTimeout = 60;

  /// 2026-09-14 P2-2 本地运行时检测卡：stdio server 依赖 node/npx/uvx 等
  /// 运行时，缺失时提前告知并给安装指引(仅桌面端显示，移动端返回空列表)
  Widget _buildRuntimeCard() {
    final runtimes = _runtimes;
    if (runtimes == null || runtimes.isEmpty) return const SizedBox.shrink();

    final allAvailable = runtimes.every((r) => r.available);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.memory,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                const Text(
                  '本地运行时检测(stdio 用)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                Icon(
                  allAvailable ? Icons.check_circle : Icons.warning_amber,
                  size: 16,
                  color: allAvailable ? Colors.green : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final r in runtimes)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      r.available ? Icons.check : Icons.close,
                      size: 14,
                      color: r.available ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      r.name,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r.available
                            ? '${r.version ?? "已安装"} — ${r.path}'
                            : '未安装 (${r.installHint})',
                        style: TextStyle(
                          fontSize: 12,
                          color: r.available
                              ? Colors.grey[600]
                              : Colors.red[300],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerCard(McpServerConfig server) {
    final busy = _busyIds.contains(server.id);
    final connected = _manager.isConnected(server.id);
    final tools = _manager.toolsOf(server.id);
    final expanded = _expandedId == server.id;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _expandedId = expanded ? null : server.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              Row(
                children: [
                  // 连接状态点
                  _statusDot(busy, server.enabled, connected),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          server.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          server.enabled
                              ? (busy
                                    ? '连接中...'
                                    : connected
                                    ? '${tools.length} 个工具可用'
                                    : tools.isNotEmpty
                                    ? '${tools.length} 个工具(离线缓存)'
                                    : '未连接(${_endpointSummary(server)})')
                              : '已停用',
                          style: TextStyle(
                            fontSize: 12,
                            color: tools.isNotEmpty && !connected
                                ? Colors.orange
                                : Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '测试连接',
                    icon: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.network_check, size: 20),
                    onPressed: busy ? null : () => _testServer(server),
                  ),
                  Switch(
                    value: server.enabled,
                    onChanged: (v) => _toggleServer(server, v),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (action) {
                      switch (action) {
                        case 'edit':
                          _addOrEditServer(server);
                          break;
                        case 'delete':
                          _deleteServer(server);
                          break;
                        case 'approval':
                          _toggleApproval(server);
                          break;
                        case 'prompts':
                          showDialog(
                            context: context,
                            builder: (_) => McpPromptsDialog(server: server),
                          );
                          break;
                        case 'resources':
                          showDialog(
                            context: context,
                            builder: (_) => McpResourcesDialog(server: server),
                          );
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'approval',
                        child: Row(
                          children: [
                            Icon(
                              server.approvalRequired
                                  ? Icons.gavel
                                  : Icons.gavel_outlined,
                              size: 18,
                              color: server.approvalRequired
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              server.approvalRequired ? '关闭调用确认' : '每次调用需确认',
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'prompts',
                        child: Row(
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 18),
                            SizedBox(width: 8),
                            Text('提示词模板'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'resources',
                        child: Row(
                          children: [
                            Icon(Icons.folder_open, size: 18),
                            SizedBox(width: 8),
                            Text('浏览资源'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('编辑'),
                          ],
                        ),
                      ),
                      if (!server.isBuiltIn)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18),
                              SizedBox(width: 8),
                              Text('删除'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              // 展开的工具列表
              if (expanded && tools.isNotEmpty) ...[
                const Divider(height: 1),
                ...tools.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(top: 6, left: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.build_circle_outlined, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${t.name}${t.description == null ? "" : " — ${t.description}"}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 2026-09-14 P2-1 卡片摘要：stdio显示command+参数，http/sse显示URL
  String _endpointSummary(McpServerConfig server) {
    if (server.transport == McpTransport.stdio) {
      final args = server.args?.replaceAll('\n', ' ').trim() ?? '';
      return '${server.command ?? "-"} $args'.trim();
    }
    return server.url ?? '-';
  }

  Widget _statusDot(bool busy, bool enabled, bool connected) {
    Color color;
    if (busy) {
      color = Colors.orange;
    } else if (!enabled) {
      color = Colors.grey;
    } else if (connected) {
      color = Colors.green;
    } else {
      color = Colors.red;
    }
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
