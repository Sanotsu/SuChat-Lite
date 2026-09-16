// ignore_for_file: non_constant_identifier_names

/// 内置测试用 remote MCP server(免认证、知名开源项目相关)
/// 2026-09-11 P1-4: 方便用户开箱即测MCP全链路
List<Map<String, dynamic>> BUILD_IN_MCP_SERVERS = [
  {
    'name': 'deepwiki',
    'display_name': 'DeepWiki(GitHub开源仓库深度问答)',
    'transport': 'http',
    'url': 'https://mcp.deepwiki.com/mcp',
  },
  {
    'name': 'context7',
    'display_name': 'Context7(库/框架最新文档查询)',
    'transport': 'http',
    'url': 'https://mcp.context7.com/mcp',
  },
  {
    'name': 'mslearn',
    'display_name': 'Microsoft Learn(微软技术文档)',
    'transport': 'http',
    'url': 'https://learn.microsoft.com/api/mcp',
  },
  {
    'name': 'exa',
    'display_name': 'Exa Search(联网搜索)',
    'transport': 'http',
    'url': 'https://mcp.exa.ai/mcp',
  },
  {
    'name': 'wolfram',
    'display_name': 'Wolfram(数学计算/科学知识)',
    'transport': 'http',
    'url': 'https://agenttools.wolfram.com/mcp',
  },
  {
    'name': 'gitmcp',
    'display_name': 'GitMCP(任意GitHub仓库文档查询)',
    'transport': 'http',
    'url': 'https://gitmcp.io/docs',
  },
];
