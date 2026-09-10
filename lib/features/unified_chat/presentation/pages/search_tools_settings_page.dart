import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/screen_helper.dart';
import '../../../../shared/widgets/cus_content_width.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../data/services/builtin_web_search_registry.dart';
import '../../data/services/unified_secure_storage.dart';
import '../viewmodels/unified_chat_viewmodel.dart';

/// 2026-09-09 页面分区(Chatbox风格左列表+右详情)
enum _Section {
  usage,
  bocha,
  baidu,
  tavily,
  serper,
  serpapi,
  priority,
  platformMode,
}

extension _SectionX on _Section {
  String get label => switch (this) {
    _Section.usage => '使用说明',
    _Section.bocha => '博查 BochaAI',
    _Section.baidu => '百度搜索',
    _Section.tavily => 'Tavily',
    _Section.serper => 'Serper',
    _Section.serpapi => 'SerpApi',
    _Section.priority => '搜索优先级',
    _Section.platformMode => '平台搜索策略',
  };

  IconData get icon => switch (this) {
    _Section.usage => Icons.info_outline,
    _Section.bocha => Icons.public,
    _Section.baidu => Icons.travel_explore,
    _Section.tavily => Icons.manage_search,
    _Section.serper => Icons.bolt,
    _Section.serpapi => Icons.data_object,
    _Section.priority => Icons.low_priority,
    _Section.platformMode => Icons.cloud_sync,
  };

  /// 五个第三方搜索服务(菜单显示已配置状态徽标)
  bool get isService => switch (this) {
    _Section.bocha ||
    _Section.baidu ||
    _Section.tavily ||
    _Section.serper ||
    _Section.serpapi => true,
    _ => false,
  };
}

/// 搜索工具设置页面
/// 2026-09-09 重构：Chatbox风格分区切换——宽屏左侧菜单+右侧详情同屏分栏；
/// 窄屏(移动端)为页面内两态切换(列表→点选进详情→返回列表)，不再单页长滚动
class SearchToolsSettingsPage extends StatefulWidget {
  const SearchToolsSettingsPage({super.key});

  @override
  State<SearchToolsSettingsPage> createState() =>
      _SearchToolsSettingsPageState();
}

class _SearchToolsSettingsPageState extends State<SearchToolsSettingsPage> {
  // 宽屏分栏断点：左菜单240+右侧详情约440起可正常排版
  static const double _wideBreakpoint = 680;
  static const double _menuWidth = 240;

  final _bochaController = TextEditingController();
  final _baiduController = TextEditingController();
  final _tavilyController = TextEditingController();
  final _serpApiController = TextEditingController();
  final _serperController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _bochaTesting = false;
  bool _baiduTesting = false;
  bool _tavilyTesting = false;
  bool _serpApiTesting = false;
  bool _serperTesting = false;
  bool? _bochaTestResult;
  bool? _baiduTestResult;
  bool? _tavilyTestResult;
  bool? _serpApiTestResult;
  bool? _serperTestResult;

  // 添加一个控制API Key是否显示的标志
  bool _obscureApiKey = true;

  // 2026-09-09 百度搜索模式：false=纯检索 / true=智能搜索生成
  bool _baiduUseIntelligent = false;

  // 当前选中分区(默认博查，推荐的首选服务)
  _Section _selected = _Section.bocha;

  // 窄屏(移动端)两态切换：false=分区列表 / true=当前分区详情
  bool _showDetail = false;

  @override
  void dispose() {
    _bochaController.dispose();
    _baiduController.dispose();
    _tavilyController.dispose();
    _serpApiController.dispose();
    _serperController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    getApikeys();
  }

  Future<void> getApikeys() async {
    final bochaApiKey = await UnifiedSecureStorage.getSearchApiKey('bocha');
    final baiduApiKey = await UnifiedSecureStorage.getSearchApiKey('baidu');
    final tavilyApiKey = await UnifiedSecureStorage.getSearchApiKey('tavily');
    final serpApiKey = await UnifiedSecureStorage.getSearchApiKey('serpapi');
    final serperApiKey = await UnifiedSecureStorage.getSearchApiKey('serper');
    final baiduMode = await UnifiedSecureStorage.getBaiduSearchMode();

    if (!mounted) return;
    setState(() {
      _bochaController.text = bochaApiKey ?? '';
      _baiduController.text = baiduApiKey ?? '';
      _tavilyController.text = tavilyApiKey ?? '';
      _serpApiController.text = serpApiKey ?? '';
      _serperController.text = serperApiKey ?? '';
      _baiduUseIntelligent = baiduMode == 'intelligent';
    });
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= _wideBreakpoint;

    return CusContentWidth.form(
      // 2026-09-09 分栏布局限宽归一到表单档(设置/表单类页面720)
      // 移动端适配：窄屏详情态时系统返回键/手势先回分区列表，再按才退出页面
      child: PopScope(
        canPop: wide || !_showDetail,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) setState(() => _showDetail = false);
        },
        child: Scaffold(
          appBar: AppBar(
            // 窄屏详情态标题跟随分区，列表态/宽屏为页面名
            title: Text((!wide && _showDetail) ? _selected.label : '搜索工具设置'),
            // 窄屏详情态：leading改为返回分区列表(非路由返回)
            leading: (!wide && _showDetail)
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: '返回列表',
                    onPressed: () => setState(() => _showDetail = false),
                  )
                : null,
            actions: [
              // API Key显隐开关(全局生效，从说明卡移至AppBar)
              // 2026-09-09 仅在正在展示API Key输入的场景显示：
              // 宽屏常驻详情=当前为搜索服务分区；窄屏=已进入搜索服务详情态。
              // 分区列表页(窄屏进入时的第一页)没有AK输入，显示会误导用户
              if ((wide || _showDetail) && _selected.isService)
                IconButton(
                  icon: Icon(
                    _obscureApiKey ? Icons.visibility_off : Icons.visibility,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureApiKey = !_obscureApiKey;
                    });
                  },
                  tooltip: _obscureApiKey ? '显示 API Key' : '隐藏 API Key',
                ),
            ],
          ),
          body: Consumer<UnifiedChatViewModel>(
            builder: (context, viewModel, child) {
              final toolStatus = viewModel.getSearchToolStatus();

              // 宽屏：左菜单+右详情分栏；窄屏：列表/详情两态互斥
              if (wide) {
                return Row(
                  children: [
                    SizedBox(
                      width: _menuWidth,
                      child: _buildSectionMenu(context, toolStatus),
                    ),
                    const VerticalDivider(width: 1, thickness: 1),
                    Expanded(
                      child: _buildSectionDetail(
                        context,
                        viewModel,
                        toolStatus,
                      ),
                    ),
                  ],
                );
              }

              return _showDetail
                  ? _buildSectionDetail(context, viewModel, toolStatus)
                  : _buildSectionMenu(context, toolStatus);
            },
          ),
        ),
      ),
    );
  }

  /// 左侧分区菜单(宽屏常驻 / 窄屏为列表页)
  Widget _buildSectionMenu(BuildContext context, Map<String, bool> toolStatus) {
    final theme = Theme.of(context);

    Widget menuItem(_Section section) {
      final isSelected = wide() ? section == _selected : false;

      return ListTile(
        leading: Icon(
          section.icon,
          size: 22,
          color: isSelected ? theme.primaryColor : null,
        ),
        title: Text(
          section.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : null,
            color: isSelected ? theme.primaryColor : null,
          ),
        ),
        // 服务分区右侧显示配置状态小徽标，便于不进详情即可见配置情况
        trailing: section.isService
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (toolStatus[toolKeyOf(section)] ?? false)
                      ? Colors.green
                      : Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  (toolStatus[toolKeyOf(section)] ?? false) ? '已配置' : '未配置',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              )
            : null,
        selected: isSelected,
        selectedTileColor: theme.primaryColor.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        onTap: () => _selectSection(section),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      children: [
        menuItem(_Section.usage),
        const SizedBox(height: 8),
        // 分组小标题：搜索服务
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
          child: Text(
            '搜索服务',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        menuItem(_Section.bocha),
        menuItem(_Section.baidu),
        menuItem(_Section.tavily),
        menuItem(_Section.serper),
        menuItem(_Section.serpapi),
        const SizedBox(height: 8),
        // 分组小标题：通用设置
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
          child: Text(
            '通用设置',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        menuItem(_Section.priority),
        menuItem(_Section.platformMode),
      ],
    );
  }

  /// 分区对应的搜索工具状态Key(与storage/tool_manager的toolType一致)
  String toolKeyOf(_Section section) => switch (section) {
    _Section.bocha => 'bocha',
    _Section.baidu => 'baidu',
    _Section.tavily => 'tavily',
    _Section.serper => 'serper',
    _Section.serpapi => 'serpapi',
    _ => '',
  };

  void _selectSection(_Section section) {
    setState(() {
      _selected = section;
      // 窄屏点选后进入详情态(宽屏常驻详情无此态)
      _showDetail = true;
    });
  }

  /// build中判断是否宽屏(ListTile选中高亮等仅分栏态需要)
  bool wide() => MediaQuery.of(context).size.width >= _wideBreakpoint;

  /// 右侧详情面板(宽屏常驻 / 窄屏替换列表页)
  Widget _buildSectionDetail(
    BuildContext context,
    UnifiedChatViewModel viewModel,
    Map<String, bool> toolStatus,
  ) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(ScreenHelper.isMobile() ? 0 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _detailChildren(context, viewModel, toolStatus),
        ),
      ),
    );
  }

  List<Widget> _detailChildren(
    BuildContext context,
    UnifiedChatViewModel viewModel,
    Map<String, bool> toolStatus,
  ) {
    switch (_selected) {
      case _Section.usage:
        return _buildUsageSection(context);

      case _Section.bocha:
        return [
          _buildToolSection(
            context,
            title: '博查 BochaAI (国内直连)',
            description:
                '国内可直连的AI搜索API，中文质量优秀，响应兼容Bing格式。0.036元/次，需预充值。 open.bochaai.com',
            controller: _bochaController,
            hintText: '输入博查API密钥',
            isConfigured: toolStatus['bocha'] ?? false,
            isTesting: _bochaTesting,
            testResult: _bochaTestResult,
            onTest: () => _testConnection('bocha'),
            onSave: () => _saveApiKey('bocha', _bochaController.text),
            validator: (value) {
              if (value == null || value.isEmpty) return null;
              if (value.length < 16) {
                return '博查API密钥长度应至少16位';
              }
              return null;
            },
          ),
        ];

      case _Section.baidu:
        return [
          _buildToolSection(
            context,
            title: '百度搜索 (千帆AI搜索)',
            description:
                '国内直连的百度搜索引擎API，中文质量优秀。每日100次免费额度，超额按量后付费。需在千帆AppBuilder控制台创建APIKey。',
            controller: _baiduController,
            hintText: '输入AppBuilder API密钥 (bce-v3/...)',
            isConfigured: toolStatus['baidu'] ?? false,
            isTesting: _baiduTesting,
            testResult: _baiduTestResult,
            onTest: () => _testConnection('baidu'),
            onSave: () => _saveApiKey('baidu', _baiduController.text),
            validator: (value) {
              if (value == null || value.isEmpty) return null;
              if (value.length < 16) {
                return '百度AppBuilder API密钥长度应至少16位';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          // 2026-09-09 百度搜索模式切换(纯检索/智能搜索生成)
          Card(
            child: SwitchListTile(
              title: const Text('智能搜索生成模式'),
              subtitle: const Text(
                '开启后使用千帆AI搜索的chat/completions接口：百度先基于检索结果整合生成一段答案再交给大模型，工具结果更精炼、可减少模型反复搜索；关闭则使用纯检索(web_search)，返回原始结果列表由大模型自主整合。智能模式百度侧多一次生成，耗时略长。',
                style: TextStyle(fontSize: 12),
              ),
              value: _baiduUseIntelligent,
              onChanged: (value) => _setBaiduMode(value),
            ),
          ),
        ];

      case _Section.tavily:
        return [
          _buildToolSection(
            context,
            title: 'Tavily Search API',
            description: 'Connect Your Agent to the Web',
            controller: _tavilyController,
            hintText: '输入Tavily API密钥 (tvly-...)',
            isConfigured: toolStatus['tavily'] ?? false,
            isTesting: _tavilyTesting,
            testResult: _tavilyTestResult,
            onTest: () => _testConnection('tavily'),
            onSave: () => _saveApiKey('tavily', _tavilyController.text),
            validator: (value) {
              if (value == null || value.isEmpty) return null;
              if (!value.startsWith('tvly-')) {
                return 'Tavily API密钥应以 tvly- 开头';
              }
              return null;
            },
          ),
        ];

      case _Section.serper:
        return [
          _buildToolSection(
            context,
            title: 'Serper API',
            description: "The World's Fastest & Cheapest Google Search API",
            controller: _serperController,
            hintText: '输入Serper API密钥',
            isConfigured: toolStatus['serper'] ?? false,
            isTesting: _serperTesting,
            testResult: _serperTestResult,
            onTest: () => _testConnection('serper'),
            onSave: () => _saveApiKey('serper', _serperController.text),
            validator: (value) {
              if (value == null || value.isEmpty) return null;
              if (value.length < 32) {
                return 'Serper API密钥长度应至少32位';
              }
              return null;
            },
          ),
        ];

      case _Section.serpapi:
        return [
          _buildToolSection(
            context,
            title: 'SerpApi',
            description:
                'Scrape Google and other search engines from our fast, easy, and complete API.',
            controller: _serpApiController,
            hintText: '输入SerpApi API密钥',
            isConfigured: toolStatus['serpapi'] ?? false,
            isTesting: _serpApiTesting,
            testResult: _serpApiTestResult,
            onTest: () => _testConnection('serpapi'),
            onSave: () => _saveApiKey('serpapi', _serpApiController.text),
            validator: (value) {
              if (value == null || value.isEmpty) return null;
              if (value.length < 32) {
                return 'SerpApi密钥长度应至少32位';
              }
              return null;
            },
          ),
        ];

      case _Section.priority:
        return [
          if (viewModel.hasAvailableSearchTools())
            _buildPriorityCard(context, viewModel)
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '尚未配置任何搜索服务，请先在左侧选择一个搜索服务并配置API密钥。',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ];

      case _Section.platformMode:
        return [
          // 平台自带联网搜索策略(2026-09-09)
          _buildSearchModeCard(context, viewModel),
        ];
    }
  }

  /// 使用说明分区(原"功能说明"+"使用说明"两卡合并为一页)
  List<Widget> _buildUsageSection(BuildContext context) {
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '联网搜索功能',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '配置搜索API密钥后，大模型将能够通过工具调用进行实时联网搜索，获取最新信息。支持博查(国内直连)、百度搜索(千帆AI搜索)、Tavily、Serper和SerpApi五种搜索服务。',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '使用说明',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('1. 至少配置一个搜索API密钥'),
              const SizedBox(height: 4),
              const Text('2. 在对话中开启"联网搜索"功能'),
              const SizedBox(height: 4),
              const Text('3. 如果有多个搜索工具，可指定使用哪一个'),
              const SizedBox(height: 4),
              const Text('4. 阿里百炼/智谱可配置自带搜索或第三方工具的优先策略'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.link,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'API密钥获取：博查 (open.bochaai.com) | 百度搜索 (cloud.baidu.com 千帆AppBuilder) | Tavily (tavily.com) | SerpApi (serpapi.com) | Serper (serper.dev)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ];
  }

  /// 搜索优先级卡片(从长页抽为独立分区)
  Widget _buildPriorityCard(
    BuildContext context,
    UnifiedChatViewModel viewModel,
  ) {
    final toolStatus = viewModel.getSearchToolStatus();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '搜索工具优先级',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '选择优先使用的搜索工具。如果未选择，系统将按默认优先级自动选择可用工具。',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            FutureBuilder<String?>(
              future: viewModel.getPreferredSearchTool(),
              builder: (context, snapshot) {
                final preferredTool = snapshot.data;
                return Column(
                  children: [
                    _buildToolPriorityOption(
                      context,
                      toolType: 'bocha',
                      title: '博查 BochaAI',
                      description: '国内直连，中文搜索质量优秀(推荐)',
                      isSelected: preferredTool == 'bocha',
                      isAvailable: toolStatus['bocha'] ?? false,
                      onSelected: () => _setPreferredTool('bocha'),
                    ),
                    _buildToolPriorityOption(
                      context,
                      toolType: 'baidu',
                      title: '百度搜索 (千帆AI搜索)',
                      description: '国内直连，每日100次免费额度',
                      isSelected: preferredTool == 'baidu',
                      isAvailable: toolStatus['baidu'] ?? false,
                      onSelected: () => _setPreferredTool('baidu'),
                    ),
                    _buildToolPriorityOption(
                      context,
                      toolType: 'tavily',
                      title: 'Tavily Search',
                      description: '专为AI设计的搜索API，响应快速',
                      isSelected: preferredTool == 'tavily',
                      isAvailable: toolStatus['tavily'] ?? false,
                      onSelected: () => _setPreferredTool('tavily'),
                    ),
                    _buildToolPriorityOption(
                      context,
                      toolType: 'serper',
                      title: 'Serper API',
                      description: '经济实惠的Google搜索API',
                      isSelected: preferredTool == 'serper',
                      isAvailable: toolStatus['serper'] ?? false,
                      onSelected: () => _setPreferredTool('serper'),
                    ),
                    _buildToolPriorityOption(
                      context,
                      toolType: 'serpapi',
                      title: 'SerpApi',
                      description: '功能丰富的搜索结果API',
                      isSelected: preferredTool == 'serpapi',
                      isAvailable: toolStatus['serpapi'] ?? false,
                      onSelected: () => _setPreferredTool('serpapi'),
                    ),
                    const SizedBox(height: 8),
                    if (preferredTool != null)
                      TextButton(
                        onPressed: () => _clearPreferredTool(),
                        child: const Text('清除优先级设置'),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolSection(
    BuildContext context, {
    required String title,
    required String description,
    required TextEditingController controller,
    required String hintText,
    required bool isConfigured,
    required bool isTesting,
    required bool? testResult,
    required VoidCallback onTest,
    required VoidCallback onSave,
    required String? Function(String?) validator,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和状态
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // 配置状态指示器
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isConfigured ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isConfigured ? '已配置' : '未配置',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // API密钥输入
            TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                border: const OutlineInputBorder(),
              ),
              validator: validator,
              obscureText: _obscureApiKey,
              onChanged: (value) {
                setState(() {
                  // 清除测试结果
                  if (controller == _bochaController) {
                    _bochaTestResult = null;
                  } else if (controller == _baiduController) {
                    _baiduTestResult = null;
                  } else if (controller == _tavilyController) {
                    _tavilyTestResult = null;
                  } else if (controller == _serpApiController) {
                    _serpApiTestResult = null;
                  } else if (controller == _serperController) {
                    _serperTestResult = null;
                  }
                });
              },
            ),

            const SizedBox(height: 12),

            // 测试与保存按钮
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 测试结果指示器
                      if (testResult != null)
                        Icon(
                          testResult ? Icons.check_circle : Icons.error,
                          color: testResult ? Colors.green : Colors.red,
                          size: 20,
                        ),
                      const SizedBox(width: 8),
                      // 测试按钮
                      if (controller.text.isNotEmpty)
                        IconButton(
                          onPressed: isTesting ? null : onTest,
                          icon: isTesting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.wifi_protected_setup),
                          tooltip: '测试连接',
                        ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: controller.text.isEmpty ? null : onSave,
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testConnection(String toolType) async {
    if (!_formKey.currentState!.validate()) return;

    void Function(bool?) setTestResult;

    switch (toolType) {
      case 'bocha':
        setTestResult = (v) => _bochaTestResult = v;
        break;
      case 'baidu':
        setTestResult = (v) => _baiduTestResult = v;
        break;
      case 'tavily':
        setTestResult = (v) => _tavilyTestResult = v;
        break;
      case 'serpapi':
        setTestResult = (v) => _serpApiTestResult = v;
        break;
      case 'serper':
      default:
        setTestResult = (v) => _serperTestResult = v;
        break;
    }

    setState(() {
      setTestResult(null);
      if (toolType == 'bocha') {
        _bochaTesting = true;
      } else if (toolType == 'baidu') {
        _baiduTesting = true;
      } else if (toolType == 'tavily') {
        _tavilyTesting = true;
      } else if (toolType == 'serpapi') {
        _serpApiTesting = true;
      } else {
        _serperTesting = true;
      }
    });

    try {
      final viewModel = context.read<UnifiedChatViewModel>();

      // 临时设置API密钥进行测试
      final apiKey = switch (toolType) {
        'bocha' => _bochaController.text,
        'baidu' => _baiduController.text,
        'tavily' => _tavilyController.text,
        'serpapi' => _serpApiController.text,
        _ => _serperController.text,
      };

      await viewModel.setSearchApiKey(toolType, apiKey);
      final result = await viewModel.testSearchToolConnection(toolType);

      setState(() {
        setTestResult(result);
      });

      if (mounted) {
        ToastUtils.showInfo(result ? '连接测试成功' : '连接测试失败');
      }
    } catch (e) {
      setState(() {
        setTestResult(false);
      });

      if (mounted) {
        ToastUtils.showError('测试失败: $e');
      }
    } finally {
      setState(() {
        if (toolType == 'bocha') {
          _bochaTesting = false;
        } else if (toolType == 'baidu') {
          _baiduTesting = false;
        } else if (toolType == 'tavily') {
          _tavilyTesting = false;
        } else if (toolType == 'serpapi') {
          _serpApiTesting = false;
        } else {
          _serperTesting = false;
        }
      });
    }
  }

  Future<void> _saveApiKey(String toolType, String apiKey) async {
    if (!_formKey.currentState!.validate()) return;
    if (apiKey.isEmpty) return;

    try {
      final viewModel = context.read<UnifiedChatViewModel>();
      await viewModel.setSearchApiKey(toolType, apiKey);

      if (mounted) {
        ToastUtils.showInfo('API密钥保存成功');
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError('保存失败: $e');
      }
    }
  }

  /// 构建工具优先级选择项
  Widget _buildToolPriorityOption(
    BuildContext context, {
    required String toolType,
    required String title,
    required String description,
    required bool isSelected,
    required bool isAvailable,
    required VoidCallback onSelected,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: RadioGroup<bool>(
          groupValue: isSelected,
          onChanged: (value) {
            if (value == true) onSelected();
          },
          child: Radio<bool>(value: true, enabled: isAvailable),
        ),
        title: Row(
          children: [
            Text(title, style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            if (isAvailable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '已配置',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '未配置',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
          ],
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: isAvailable ? null : Colors.grey,
          ),
        ),
        enabled: isAvailable,
        onTap: isAvailable ? onSelected : null,
      ),
    );
  }

  /// 设置首选搜索工具
  Future<void> _setPreferredTool(String toolType) async {
    final viewModel = Provider.of<UnifiedChatViewModel>(context, listen: false);
    try {
      await viewModel.setPreferredSearchTool(toolType);
      setState(() {});
      if (mounted) {
        ToastUtils.showInfo('已设置 $toolType 为首选搜索工具');
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError('设置失败: $e');
      }
    }
  }

  /// 清除首选搜索工具设置
  Future<void> _clearPreferredTool() async {
    final viewModel = Provider.of<UnifiedChatViewModel>(context, listen: false);
    try {
      await viewModel.clearPreferredSearchTool();
      setState(() {});
      if (mounted) {
        ToastUtils.showInfo('已清除首选搜索工具设置');
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError('清除设置失败: $e');
      }
    }
  }

  /// 2026-09-09 切换百度搜索模式(纯检索/智能搜索生成)
  Future<void> _setBaiduMode(bool useIntelligent) async {
    final viewModel = Provider.of<UnifiedChatViewModel>(context, listen: false);
    try {
      await viewModel.setBaiduSearchMode(
        useIntelligent ? 'intelligent' : 'retrieval',
      );
      setState(() => _baiduUseIntelligent = useIntelligent);
      if (mounted) {
        ToastUtils.showInfo(useIntelligent ? '已切换为智能搜索生成模式' : '已切换为纯检索模式');
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError('设置失败: $e');
      }
    }
  }

  /// 2026-09-09 平台自带联网搜索策略卡片
  /// 动态列出注册了自带搜索适配器的平台(见builtin_web_search_registry.dart)，
  /// 后续适配新平台时此处自动出现对应配置项
  Widget _buildSearchModeCard(
    BuildContext context,
    UnifiedChatViewModel viewModel,
  ) {
    final platforms = viewModel.builtinSearchPlatforms;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '平台自带联网搜索策略',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '以下平台的联网搜索为平台付费服务(阿里按次计费、智谱0.01~0.05元/次)。选择"自动"时，若已配置任一第三方搜索Key则优先使用第三方工具调用，否则使用平台自带搜索；也可强制指定某个平台走自带搜索或第三方工具。',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            for (final entry in platforms.entries)
              _buildPlatformModeRow(context, viewModel, entry.key, entry.value),
          ],
        ),
      ),
    );
  }

  /// 单个平台的搜索策略选择行
  Widget _buildPlatformModeRow(
    BuildContext context,
    UnifiedChatViewModel viewModel,
    String platformId,
    String displayName,
  ) {
    // 2026-09-09 平台前置条件提示(如火山方舟自带搜索基于Responses API开发中)
    final setupHint = BuiltinWebSearchRegistry.setupHintFor(platformId);

    // 如果是火山方舟，暂时不显示
    if (setupHint != null) {
      return SizedBox.shrink();
    }

    return FutureBuilder<BuiltinWebSearchMode>(
      future: viewModel.getPlatformSearchMode(platformId),
      builder: (context, snapshot) {
        final mode = snapshot.data ?? BuiltinWebSearchMode.auto;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildModeChip(
                          context,
                          label: '自动',
                          mode: BuiltinWebSearchMode.auto,
                          currentMode: mode,
                          onSelected: () => _setPlatformMode(
                            viewModel,
                            platformId,
                            BuiltinWebSearchMode.auto,
                          ),
                        ),
                        _buildModeChip(
                          context,
                          label: '平台自带',
                          mode: BuiltinWebSearchMode.builtinOnly,
                          currentMode: mode,
                          onSelected: () => _setPlatformMode(
                            viewModel,
                            platformId,
                            BuiltinWebSearchMode.builtinOnly,
                          ),
                        ),
                        _buildModeChip(
                          context,
                          label: '第三方',
                          mode: BuiltinWebSearchMode.thirdPartyOnly,
                          currentMode: mode,
                          onSelected: () => _setPlatformMode(
                            viewModel,
                            platformId,
                            BuiltinWebSearchMode.thirdPartyOnly,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (setupHint != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 72, right: 8),
                  child: Text(
                    setupHint,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeChip(
    BuildContext context, {
    required String label,
    required BuiltinWebSearchMode mode,
    required BuiltinWebSearchMode currentMode,
    required VoidCallback onSelected,
  }) {
    final isSelected = mode == currentMode;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      checkmarkColor: isSelected ? Colors.white : null,
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected ? Colors.white : null,
      ),
      selectedColor: Theme.of(context).primaryColor,
    );
  }

  Future<void> _setPlatformMode(
    UnifiedChatViewModel viewModel,
    String platformId,
    BuiltinWebSearchMode mode,
  ) async {
    try {
      await viewModel.setPlatformSearchMode(platformId, mode);
      setState(() {});
      if (mounted) {
        ToastUtils.showInfo(
          '已更新${viewModel.builtinSearchPlatforms[platformId] ?? platformId}的搜索策略',
        );
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError('设置失败: $e');
      }
    }
  }
}
