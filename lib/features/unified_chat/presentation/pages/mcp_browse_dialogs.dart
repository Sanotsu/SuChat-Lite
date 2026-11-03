import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mcp_dart/mcp_dart.dart';

import '../../../../shared/widgets/toast_utils.dart';
import '../../data/models/mcp_models.dart';
import '../../data/services/mcp/mcp_server_manager.dart';

/// MCP能力浏览对话框(P3-3/P3-4)：server的资源列表与提示词模板查看。
/// 入口在MCP设置页server卡菜单——需要server已启用(懒连接自动拉取)，
/// 内容预览后可复制使用(提示词渲染文本可粘贴到对话输入框)
///
/// 2026-09-14 P3-4 提示词模板：列表→(模板参数表单)→渲染预览→复制
class McpPromptsDialog extends StatefulWidget {
  const McpPromptsDialog({super.key, required this.server});

  final McpServerConfig server;

  @override
  State<McpPromptsDialog> createState() => _McpPromptsDialogState();
}

class _McpPromptsDialogState extends State<McpPromptsDialog> {
  final _manager = McpServerManager();

  List<Prompt> _prompts = [];
  String? _error;
  bool _loading = true;

  /// 选中模板后的渲染态
  Prompt? _selected;
  String? _renderedText;
  bool _rendering = false;
  String? _renderError;
  late final Map<String, TextEditingController> _argControllers = {};

  @override
  void initState() {
    super.initState();
    _loadPrompts();
  }

  @override
  void dispose() {
    for (final c in _argControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPrompts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prompts = await _manager.listPromptsOf(widget.server.id);
      if (!mounted) return;
      setState(() {
        _prompts = prompts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // StateError.toString()自带"Bad state:"前缀，展示层剥掉
        _error = e.toString().replaceFirst('Bad state: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _renderPrompt(Prompt prompt) async {
    setState(() {
      _selected = prompt;
      _rendering = true;
      _renderError = null;
      _renderedText = null;
      _argControllers.clear();
      for (final a in prompt.arguments ?? const <PromptArgument>[]) {
        _argControllers[a.name] = TextEditingController();
      }
    });
    // 有参数模板：先让用户填写，点"生成"再渲染；无参模板直接渲染
    if (_argControllers.isNotEmpty) {
      setState(() => _rendering = false);
      return;
    }
    await _fetchPrompt();
  }

  Future<void> _fetchPrompt() async {
    final prompt = _selected;
    if (prompt == null) return;
    setState(() {
      _rendering = true;
      _renderError = null;
    });
    try {
      final text = await _manager.getPromptTextOf(
        widget.server.id,
        prompt.name,
        _argControllers.map((k, v) => MapEntry(k, v.text)),
      );
      if (!mounted) return;
      setState(() {
        _renderedText = text;
        _rendering = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _renderError = e.toString().replaceFirst('Bad state: ', '');
        _rendering = false;
      });
    }
  }

  Future<void> _copyRendered() async {
    if (_renderedText == null) return;
    await Clipboard.setData(ClipboardData(text: _renderedText!));
    if (mounted) ToastUtils.showSuccess('已复制，可粘贴到对话输入框使用');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.server.displayName} · 提示词模板'),
      content: SizedBox(width: 440, height: 420, child: _buildBody()),
      actions: [
        if (_selected != null)
          TextButton(
            onPressed: () => setState(() {
              _selected = null;
              _renderedText = null;
              _renderError = null;
            }),
            child: const Text('返回列表'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 36, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text('加载失败', style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(child: SelectableText(_error!)),
            ),
            TextButton(onPressed: _loadPrompts, child: const Text('重试')),
          ],
        ),
      );
    }
    if (_selected != null) return _buildRenderView();
    if (_prompts.isEmpty) {
      return Center(
        child: Text(
          '此server未提供提示词模板',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }
    return ListView.builder(
      itemCount: _prompts.length,
      itemBuilder: (context, i) {
        final p = _prompts[i];
        return ListTile(
          dense: true,
          title: Text(
            p.title ?? p.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: (p.description ?? '').isEmpty
              ? null
              : Text(
                  p.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
          trailing: (p.arguments?.isNotEmpty ?? false)
              ? const Icon(Icons.tune, size: 16)
              : const Icon(Icons.chevron_right, size: 18),
          onTap: () => _renderPrompt(p),
        );
      },
    );
  }

  /// 模板渲染视图：参数表单(若有)或渲染结果预览
  Widget _buildRenderView() {
    final prompt = _selected!;

    // 渲染结果态
    if (_renderedText != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            prompt.title ?? prompt.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _renderedText!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.tonalIcon(
                onPressed: _copyRendered,
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('复制全文'),
              ),
            ],
          ),
        ],
      );
    }

    // 渲染中/失败态
    if (_rendering) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          prompt.title ?? prompt.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if ((prompt.description ?? '').isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            prompt.description!,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
        const SizedBox(height: 12),
        if (_argControllers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('无参数模板', style: TextStyle(color: Colors.grey[600])),
          )
        else
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final entry in _argControllers.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: entry.value,
                      decoration: InputDecoration(
                        labelText: entry.key,
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (_renderError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _renderError!,
              style: TextStyle(fontSize: 12, color: Colors.red[400]),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        FilledButton.icon(
          onPressed: _fetchPrompt,
          icon: const Icon(Icons.play_arrow, size: 16),
          label: Text(_argControllers.isEmpty ? '获取模板' : '生成预览'),
        ),
      ],
    );
  }
}

/// 2026-09-14 P3-3 资源浏览：列表→读取内容预览→复制
class McpResourcesDialog extends StatefulWidget {
  const McpResourcesDialog({super.key, required this.server});

  final McpServerConfig server;

  @override
  State<McpResourcesDialog> createState() => _McpResourcesDialogState();
}

class _McpResourcesDialogState extends State<McpResourcesDialog> {
  final _manager = McpServerManager();

  List<Resource> _resources = [];
  String? _error;
  bool _loading = true;

  Resource? _selected;
  String? _contentText;
  bool _reading = false;
  String? _readError;

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resources = await _manager.listResourcesOf(widget.server.id);
      if (!mounted) return;
      setState(() {
        _resources = resources;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Bad state: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _readResource(Resource resource) async {
    setState(() {
      _selected = resource;
      _reading = true;
      _readError = null;
      _contentText = null;
    });
    try {
      final text = await _manager.readResourceTextOf(
        widget.server.id,
        resource.uri,
      );
      if (!mounted) return;
      setState(() {
        _contentText = text;
        _reading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _readError = e.toString().replaceFirst('Bad state: ', '');
        _reading = false;
      });
    }
  }

  Future<void> _copyContent() async {
    if (_contentText == null) return;
    await Clipboard.setData(ClipboardData(text: _contentText!));
    if (mounted) ToastUtils.showSuccess('资源内容已复制');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.server.displayName} · 资源浏览'),
      content: SizedBox(width: 480, height: 440, child: _buildBody()),
      actions: [
        if (_selected != null)
          TextButton(
            onPressed: () => setState(() {
              _selected = null;
              _contentText = null;
              _readError = null;
            }),
            child: const Text('返回列表'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 36, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text('加载失败', style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 8),
            Expanded(child: SingleChildScrollView(child: Text(_error!))),
            TextButton(onPressed: _loadResources, child: const Text('重试')),
          ],
        ),
      );
    }
    if (_selected != null) return _buildContentView();
    if (_resources.isEmpty) {
      return Center(
        child: Text('此server未提供资源', style: TextStyle(color: Colors.grey[600])),
      );
    }
    return ListView.builder(
      itemCount: _resources.length,
      itemBuilder: (context, i) {
        final r = _resources[i];
        return ListTile(
          dense: true,
          title: Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            r.uri,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
          trailing: r.mimeType == null
              ? const Icon(Icons.chevron_right, size: 18)
              : Text(
                  r.mimeType!,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
          onTap: () => _readResource(r),
        );
      },
    );
  }

  Widget _buildContentView() {
    final resource = _selected!;
    if (_reading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_readError != null) {
      return Column(
        children: [
          Icon(Icons.error_outline, size: 32, color: Colors.red[300]),
          const SizedBox(height: 8),
          Expanded(child: SingleChildScrollView(child: Text(_readError!))),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          resource.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(
          resource.uri,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                _contentText ?? '',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton.tonalIcon(
              onPressed: _copyContent,
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('复制内容'),
            ),
          ],
        ),
      ],
    );
  }
}
