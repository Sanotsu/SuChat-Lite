import 'package:flutter/material.dart';

import '../../../../shared/widgets/cus_content_width.dart';
import '../../data/models/mcp_models.dart';
import '../../data/services/mcp/mcp_server_config_service.dart';

/// 2026-09-14 P2-4 MCP server JSON 批量导入弹窗
/// 兼容 Claude Desktop 格式 `{"mcpServers": {...}}`：
/// 解析预览(名称规范化/类型/冲突标记) + 冲突处理(跳过/覆盖) + 批量保存
class McpImportDialog extends StatefulWidget {
  const McpImportDialog({super.key});

  @override
  State<McpImportDialog> createState() => _McpImportDialogState();
}

class _McpImportDialogState extends State<McpImportDialog> {
  final _jsonController = TextEditingController();
  final _configService = McpServerConfigService();

  /// 解析预览结果(null=尚未解析)
  List<McpImportItem>? _items;
  List<String> _errors = const [];

  /// 冲突处理：false=跳过已存在(默认，安全)，true=覆盖
  bool _overwrite = false;

  bool _importing = false;

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _parse() async {
    final raw = _jsonController.text.trim();
    if (raw.isEmpty) return;

    final result = await _configService.parseImportJson(raw);
    if (!mounted) return;
    setState(() {
      _items = result.items;
      _errors = result.errors;
    });
  }

  Future<void> _import() async {
    final items = _items;
    if (items == null || items.isEmpty) return;

    setState(() => _importing = true);

    var imported = 0;
    var skipped = 0;
    final failed = <String>[];

    for (final item in items) {
      try {
        // 冲突处理：与库内同名时按用户选择跳过或覆盖
        if (item.existsInDb && !_overwrite) {
          skipped++;
          continue;
        }

        var config = item.config;
        if (item.existsInDb) {
          // 覆盖：沿用已有条目的id与创建时间(会话开关/认证头按id存储不悬空)
          final existing = await _configService.getServerByName(
            item.config.name,
          );
          if (existing == null) {
            skipped++;
            continue;
          }
          config = config.copyWith(
            id: existing.id,
            createdAt: existing.createdAt,
          );
          await _configService.updateServer(config);
        } else {
          await _configService.saveServer(config);
        }

        // 认证头提取值存secure storage
        final auth = item.authHeader;
        if (auth != null && auth.isNotEmpty) {
          await _configService.setAuthHeader(config.id, auth);
        }
        imported++;
      } catch (e) {
        failed.add('${item.config.name}: $e');
      }
    }

    if (!mounted) return;

    final parts = <String>['导入 $imported 条'];
    if (skipped > 0) parts.add('跳过 $skipped 条');
    if (failed.isNotEmpty) parts.add('失败 ${failed.length} 条');
    String summary = parts.join('，');
    if (failed.isNotEmpty) summary += '\n${failed.take(3).join('\n')}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(summary),
        duration: Duration(seconds: failed.isEmpty ? 3 : 6),
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final hasConflicts = items?.any((i) => i.existsInDb) ?? false;

    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: CusContentWidth.dialogWidth,
        ),
        child: AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: const Text('导入 MCP 配置'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '粘贴 JSON 配置(兼容 Claude Desktop 格式)',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _jsonController,
                    maxLines: 8,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      hintText:
                          '{"mcpServers": {\n'
                          '  "filesystem": {\n'
                          '    "command": "npx",\n'
                          '    "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path"]\n'
                          '  },\n'
                          '  "deepwiki": {"url": "https://mcp.deepwiki.com/mcp"}\n'
                          '}}',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _importing ? null : _parse,
                      icon: const Icon(Icons.preview, size: 16),
                      label: const Text('解析预览'),
                    ),
                  ),
                  // 解析错误
                  if (_errors.isNotEmpty) ...[
                    for (final e in _errors)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '⚠ $e',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                  ],
                  // 预览列表
                  if (items != null) ...[
                    const SizedBox(height: 8),
                    if (items.isEmpty)
                      const Text('没有可导入的条目', style: TextStyle(fontSize: 13)),
                    for (final item in items)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: item.existsInDb
                              ? Colors.orange.withValues(alpha: 0.08)
                              : Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  item.config.transport == McpTransport.stdio
                                      ? Icons.terminal
                                      : Icons.public,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    item.config.displayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (item.existsInDb)
                                  const Text(
                                    '已存在',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.config.transport == McpTransport.stdio
                                  ? '${item.config.command ?? ""} '
                                        '${item.config.args ?? ""}'
                                  : (item.config.url ?? ''),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.renameNote != null)
                              Text(
                                '名称规范化 ${item.renameNote}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    // 冲突处理选择(存在同名条目时显示)
                    if (hasConflicts)
                      SwitchListTile(
                        title: const Text(
                          '覆盖同名 server',
                          style: TextStyle(fontSize: 14),
                        ),
                        subtitle: const Text(
                          '关闭=跳过已存在的条目；开启=用导入配置覆盖(认证头一并更新)',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _overwrite,
                        onChanged: (v) => setState(() => _overwrite = v),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _importing
                  ? null
                  : () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: (_importing || items == null || items.isEmpty)
                  ? null
                  : _import,
              child: _importing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('导入'),
            ),
          ],
        ),
      ),
    );
  }
}
