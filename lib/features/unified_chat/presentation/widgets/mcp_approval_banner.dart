import 'package:flutter/material.dart';

import '../../data/models/mcp_models.dart';

/// 2026-09-14 P3-1 工具调用审批横幅(输入框上方)：
/// opencode式授权——开启审批的server/非只读命令每次调用前展示详情，
/// 用户允许/总是允许/拒绝后Agent循环继续；挂起期间生成中指示器仍在
/// 2026-09-14 P3-13 泛化：MCP工具(标题=server·tool，详情=参数JSON)
/// 与内置shell命令(标题=执行终端命令，详情=完整命令)统一走此横幅
class McpApprovalBanner extends StatelessWidget {
  final ToolApprovalRequest request;
  final VoidCallback onAllow;
  final VoidCallback onAllowAlways;
  final VoidCallback onDeny;

  const McpApprovalBanner({
    super.key,
    required this.request,
    required this.onAllow,
    required this.onAllowAlways,
    required this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBuiltin = request.serverName == null;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.85,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isBuiltin ? Icons.terminal : Icons.gavel,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '工具调用请求：${request.title}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 详情区(命令文本/参数JSON，限高滚动，超长不撑爆横幅)
          Container(
            constraints: const BoxConstraints(maxHeight: 120),
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: SingleChildScrollView(
              child: Text(
                request.displayDetail,
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.grey[700],
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onDeny,
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('拒绝'),
              ),
              TextButton(onPressed: onAllowAlways, child: const Text('总是允许')),
              ElevatedButton(onPressed: onAllow, child: const Text('允许')),
            ],
          ),
        ],
      ),
    );
  }
}
