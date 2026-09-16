import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../shared/widgets/cus_content_width.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../data/models/mcp_models.dart';
import '../../data/services/mcp/mcp_server_config_service.dart';
import '../../data/services/mcp/mcp_server_manager.dart';

/// MCP server 添加/编辑弹窗
/// 2026-09-11 MCP集成 P1-4：名称/URL/认证头 + 测试连接
/// 2026-09-14 P2-3：传输类型切换(Streamable HTTP / stdio 本地进程)，
/// stdio表单为command/args/env；测试连接stdio会真实启动本地子进程
class McpServerEditDialog extends StatefulWidget {
  final McpServerConfig? existing;

  const McpServerEditDialog({super.key, this.existing});

  @override
  State<McpServerEditDialog> createState() => _McpServerEditDialogState();
}

class _McpServerEditDialogState extends State<McpServerEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _urlController = TextEditingController();
  final _authController = TextEditingController();

  /// 2026-09-15 P4-2 OAuth授权码流配置
  final _oauthClientIdController = TextEditingController();
  final _oauthScopesController = TextEditingController();
  final _commandController = TextEditingController();
  final _argsController = TextEditingController();
  final _envController = TextEditingController();

  /// 当前传输类型(sse为P3兼容项，表单不提供)
  McpTransport _transport = McpTransport.http;

  bool _testing = false;
  bool? _testOk;
  List<String> _testTools = const [];

  /// 2026-09-12 搜索源标记：勾选后此server的工具不随MCP开关全量注入，
  /// 只通过"联网搜索"渠道注入(全局搜索渠道偏好控制)
  bool _isSearchSource = false;

  /// 2026-09-14 P3-1 审批确认：每次工具调用前需用户确认(横幅展示
  /// 工具名+参数)，写文件/执行命令类server建议开启
  bool _approvalRequired = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameController.text = e.name;
      _displayNameController.text = e.displayName;
      _urlController.text = e.url ?? '';
      _commandController.text = e.command ?? '';
      _argsController.text = _prettyJson(e.args);
      _envController.text = _prettyJson(e.env);
      // 传输类型回显：stdio/http/sse全保留(sse按远程URL表单编辑)
      _transport = e.transport;
      _isSearchSource = e.isSearchSource;
      _approvalRequired = e.approvalRequired;
      _oauthClientIdController.text = e.oauthClientId ?? '';
      _oauthScopesController.text = e.oauthScopes ?? '';
      // 认证头敏感值异步回填
      McpServerConfigService().getAuthHeader(e.id).then((v) {
        if (mounted && v != null) {
          setState(() => _authController.text = v);
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    _urlController.dispose();
    _authController.dispose();
    _oauthClientIdController.dispose();
    _oauthScopesController.dispose();
    _commandController.dispose();
    _argsController.dispose();
    _envController.dispose();
    super.dispose();
  }

  /// DB中紧凑JSON美化展示(空值返回空串)
  String _prettyJson(String? raw) {
    final rawTrim = raw?.trim() ?? '';
    if (rawTrim.isEmpty) return '';
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(rawTrim));
    } catch (_) {
      return rawTrim;
    }
  }

  /// args 文本 -> JSON数组字符串；空返回null；非法抛FormatException
  String? _normalizeArgs() {
    final raw = _argsController.text.trim();
    if (raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('参数必须是JSON数组，如 ["--port","8080"]');
    }
    return jsonEncode(decoded.map((e) => e.toString()).toList());
  }

  /// env 文本 -> JSON对象字符串；空返回null；非法抛FormatException
  String? _normalizeEnv() {
    final raw = _envController.text.trim();
    if (raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('环境变量必须是JSON对象，如 {"API_KEY":"xxx"}');
    }
    return jsonEncode(
      decoded.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
    );
  }

  McpServerConfig _buildConfig() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final e = widget.existing;
    final isStdio = _transport == McpTransport.stdio;

    // 切换传输类型时只保留对应字段，避免脏数据残留
    String? url;
    String? command;
    String? args;
    String? env;
    if (isStdio) {
      command = _commandController.text.trim();
      args = _normalizeArgs();
      env = _normalizeEnv();
    } else {
      url = _urlController.text.trim();
    }

    return McpServerConfig(
      id: e?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      displayName: _displayNameController.text.trim().isEmpty
          ? _nameController.text.trim()
          : _displayNameController.text.trim(),
      transport: _transport,
      url: url,
      command: command,
      args: args,
      env: env,
      headers: isStdio ? null : e?.headers,
      enabled: e?.enabled ?? false,
      isBuiltIn: e?.isBuiltIn ?? false,
      isSearchSource: _isSearchSource,
      approvalRequired: _approvalRequired,
      // P3-7 工具离线缓存与编辑无关，透传保留
      toolsCache: e?.toolsCache,
      // P4-2 OAuth配置(http传输；stdio时置空防脏数据)
      oauthClientId: isStdio ? null : _oauthClientIdController.text.trim(),
      oauthScopes: isStdio ? null : _oauthScopesController.text.trim(),
      createdAt: e?.createdAt ?? now,
      updatedAt: now,
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    final McpServerConfig config;
    try {
      config = _buildConfig();
    } on FormatException catch (e) {
      ToastUtils.showError(e.message);
      return;
    } catch (_) {
      ToastUtils.showError('JSON格式不正确');
      return;
    }

    setState(() {
      _testing = true;
      _testOk = null;
      _testTools = const [];
    });

    final result = await McpServerManager().testConnection(
      config,
      authHeader: _authController.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _testing = false;
      _testOk = result.ok;
      _testTools = result.tools;
    });

    if (!result.ok) {
      // print(result.error); // 2026-09-14 用户调试输出(与下行toast重复)，注释以保持analyze干净
      ToastUtils.showError('连接失败: ${result.error}');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final McpServerConfig config;
    try {
      config = _buildConfig();
    } on FormatException catch (e) {
      ToastUtils.showError(e.message);
      return;
    } catch (_) {
      ToastUtils.showError('JSON格式不正确');
      return;
    }

    // name唯一性检查(编辑时排除自身)
    try {
      if (widget.existing == null) {
        await McpServerConfigService().saveServer(config);
      } else {
        await McpServerConfigService().updateServer(config);
      }
    } on FormatException catch (e) {
      ToastUtils.showError(e.message);
      return;
    } catch (e) {
      if (e.toString().contains('UNIQUE')) {
        ToastUtils.showError('服务名称已被使用: ${config.name}');
      } else {
        ToastUtils.showError('保存失败: $e');
      }
      return;
    }

    // 认证头敏感值存secure storage(留空且为新建则不写；仅http场景)
    final auth = _authController.text.trim();
    if (auth.isNotEmpty && config.transport != McpTransport.stdio) {
      await McpServerConfigService().setAuthHeader(config.id, auth);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final isStdio = _transport == McpTransport.stdio;

    // 2026-09-11 弹窗宽度统一模式：Align先转loose再限宽(tight下CB失效)
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: CusContentWidth.dialogWidth,
        ),
        child: AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(isEdit ? '编辑 MCP Server' : '添加 MCP Server'),
          content: SizedBox(
            width: double.maxFinite,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '服务名称(标识，仅字母数字_-)',
                        hintText: '如: myserver',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final name = v?.trim() ?? '';
                        if (name.isEmpty) return '请输入服务名称';
                        if (!McpServerConfig.isValidName(name)) {
                          return '仅支持字母、数字、下划线和短横线';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(
                        labelText: '显示名称(可选)',
                        hintText: '列表中展示的名字',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 2026-09-14 P2-3 传输类型选择(P3-8 加回legacy SSE)
                    SegmentedButton<McpTransport>(
                      segments: const [
                        ButtonSegment(
                          value: McpTransport.http,
                          icon: Icon(Icons.public, size: 16),
                          label: Text(
                            '远程 HTTP',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        ButtonSegment(
                          value: McpTransport.stdio,
                          icon: Icon(Icons.terminal, size: 16),
                          label: Text('本地进程', style: TextStyle(fontSize: 13)),
                        ),
                        ButtonSegment(
                          value: McpTransport.sse,
                          icon: Icon(Icons.history, size: 16),
                          label: Text('旧版SSE', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                      selected: {_transport},
                      onSelectionChanged: (selection) =>
                          setState(() => _transport = selection.first),
                      showSelectedIcon: false,
                    ),
                    const SizedBox(height: 12),
                    if (!isStdio) ...[
                      TextFormField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          labelText: _transport == McpTransport.sse
                              ? 'Server URL (HTTP+SSE)'
                              : 'Server URL (Streamable HTTP)',
                          hintText: 'https://example.com/mcp',
                          helperText: _transport == McpTransport.sse
                              ? '仅旧版server需要(2024-11-05规范)，新版请用Streamable HTTP'
                              : null,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final url = v?.trim() ?? '';
                          if (url.isEmpty) return '请输入Server URL';
                          final uri = Uri.tryParse(url);
                          if (uri == null ||
                              !uri.hasScheme ||
                              (uri.scheme != 'http' && uri.scheme != 'https')) {
                            return 'URL格式不正确(需http/https)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _authController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: '认证头 Authorization(可选)',
                          hintText: '如: Bearer sk-xxx',
                          border: OutlineInputBorder(),
                          helperText: '值加密存储，不落数据库',
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 2026-09-15 P4-2 OAuth授权码流配置(桌面端远程server；
                      // server返回401时自动打开浏览器完成授权)
                      Text(
                        'OAuth 授权(可选)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _oauthClientIdController,
                        decoration: const InputDecoration(
                          labelText: 'OAuth Client ID(可选)',
                          hintText: '预注册客户端ID；留空则自动动态注册',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _oauthScopesController,
                        decoration: const InputDecoration(
                          labelText: 'OAuth Scopes(可选)',
                          hintText: '空格分隔，如: read write',
                          border: OutlineInputBorder(),
                          isDense: true,
                          helperText: '连接遇401时自动发起授权流程',
                        ),
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _commandController,
                        decoration: const InputDecoration(
                          labelText: '启动命令(必填)',
                          hintText: '如: npx / uvx / node',
                          border: OutlineInputBorder(),
                          helperText: '需本机已安装对应运行时(Node.js/uv等)',
                        ),
                        validator: (v) =>
                            (v?.trim() ?? '').isEmpty ? '请输入启动命令' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _argsController,
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          labelText: '命令参数(可选，JSON数组)',
                          hintText:
                              '["-y", "@modelcontextprotocol/server-filesystem", "D:/data"]',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final raw = v?.trim() ?? '';
                          if (raw.isEmpty) return null;
                          try {
                            final d = jsonDecode(raw);
                            if (d is! List) return '必须是JSON数组';
                          } catch (_) {
                            return 'JSON格式不正确';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _envController,
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          labelText: '环境变量(可选，JSON对象)',
                          hintText: '{"API_KEY": "xxx"}',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final raw = v?.trim() ?? '';
                          if (raw.isEmpty) return null;
                          try {
                            final d = jsonDecode(raw);
                            if (d is! Map) return '必须是JSON对象';
                          } catch (_) {
                            return 'JSON格式不正确';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    // 2026-09-14 P3-1 审批确认开关
                    SwitchListTile(
                      title: const Text(
                        '每次调用需确认',
                        style: TextStyle(fontSize: 14),
                      ),
                      subtitle: const Text(
                        '开启后该server每次工具调用前会弹出确认横幅(展示工具名与参数)，由你决定是否执行。适用于文件读写、命令执行等有实际影响的server。',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _approvalRequired,
                      onChanged: (v) => setState(() => _approvalRequired = v),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                    // 2026-09-12 搜索源标记
                    SwitchListTile(
                      title: const Text(
                        '作为搜索源',
                        style: TextStyle(fontSize: 14),
                      ),
                      subtitle: const Text(
                        '勾选后此server的工具不随MCP开关注入，只通过"联网搜索"开关+搜索渠道偏好注入(此时无需开MCP开关)；不勾则作为普通工具由MCP开关注入。适用于bing搜索/Exa等纯搜索server。',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _isSearchSource,
                      onChanged: (v) => setState(() => _isSearchSource = v),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                    const SizedBox(height: 4),
                    // 测试连接结果区
                    if (_testOk == true && _testTools.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '连接成功，工具: ${_testTools.join(", ")}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _testing ? null : _testConnection,
              child: _testing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isStdio ? '测试启动' : '测试连接'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: _testing ? null : _save,
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
