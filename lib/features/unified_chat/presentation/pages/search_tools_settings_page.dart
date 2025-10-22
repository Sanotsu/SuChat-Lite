import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/toast_utils.dart';
import '../../data/services/unified_secure_storage.dart';
import '../viewmodels/unified_chat_viewmodel.dart';

/// 搜索工具设置页面
class SearchToolsSettingsPage extends StatefulWidget {
  const SearchToolsSettingsPage({super.key});

  @override
  State<SearchToolsSettingsPage> createState() =>
      _SearchToolsSettingsPageState();
}

class _SearchToolsSettingsPageState extends State<SearchToolsSettingsPage> {
  final _tavilyController = TextEditingController();
  final _serpApiController = TextEditingController();
  final _serperController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _tavilyTesting = false;
  bool _serpApiTesting = false;
  bool _serperTesting = false;
  bool? _tavilyTestResult;
  bool? _serpApiTestResult;
  bool? _serperTestResult;

  // 添加一个控制API Key是否显示的标志
  bool _obscureApiKey = true;

  @override
  void dispose() {
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
    final tavilyApiKey = await UnifiedSecureStorage.getSearchApiKey('tavily');
    final serpApiKey = await UnifiedSecureStorage.getSearchApiKey('serpapi');
    final serperApiKey = await UnifiedSecureStorage.getSearchApiKey('serper');

    setState(() {
      _tavilyController.text = tavilyApiKey ?? '';
      _serpApiController.text = serpApiKey ?? '';
      _serperController.text = serperApiKey ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('搜索工具设置'), elevation: 0),
      body: Consumer<UnifiedChatViewModel>(
        builder: (context, viewModel, child) {
          final toolStatus = viewModel.getSearchToolStatus();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 功能说明
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '联网搜索功能',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: Icon(
                                  _obscureApiKey
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Theme.of(context).primaryColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureApiKey = !_obscureApiKey;
                                  });
                                },
                                tooltip: _obscureApiKey
                                    ? '显示 API Key'
                                    : '隐藏 API Key',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '配置搜索API密钥后，大模型将能够通过工具调用进行实时联网搜索，获取最新信息。支持Tavily、Serper和SerpApi三种搜索服务。',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tavily设置
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
                  const SizedBox(height: 24),

                  // Serper设置
                  _buildToolSection(
                    context,
                    title: 'Serper API',
                    description:
                        "The World's Fastest & Cheapest Google Search API",
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
                  const SizedBox(height: 24),

                  // SerpApi设置
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
                    onSave: () =>
                        _saveApiKey('serpapi', _serpApiController.text),
                    validator: (value) {
                      if (value == null || value.isEmpty) return null;
                      if (value.length < 32) {
                        return 'SerpApi密钥长度应至少32位';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // 搜索工具优先级设置
                  if (viewModel.hasAvailableSearchTools())
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '搜索工具优先级',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
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
                                      toolType: 'tavily',
                                      title: 'Tavily Search',
                                      description: '专为AI设计的搜索API，响应快速',
                                      isSelected: preferredTool == 'tavily',
                                      isAvailable:
                                          toolStatus['tavily'] ?? false,
                                      onSelected: () =>
                                          _setPreferredTool('tavily'),
                                    ),
                                    _buildToolPriorityOption(
                                      context,
                                      toolType: 'serper',
                                      title: 'Serper API',
                                      description: '经济实惠的Google搜索API',
                                      isSelected: preferredTool == 'serper',
                                      isAvailable:
                                          toolStatus['serper'] ?? false,
                                      onSelected: () =>
                                          _setPreferredTool('serper'),
                                    ),
                                    _buildToolPriorityOption(
                                      context,
                                      toolType: 'serpapi',
                                      title: 'SerpApi',
                                      description: '功能丰富的搜索结果API',
                                      isSelected: preferredTool == 'serpapi',
                                      isAvailable:
                                          toolStatus['serpapi'] ?? false,
                                      onSelected: () =>
                                          _setPreferredTool('serpapi'),
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
                    ),

                  const SizedBox(height: 16),

                  // 使用说明
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '使用说明',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          const Text('1. 至少配置一个搜索API密钥'),
                          const SizedBox(height: 4),
                          const Text('2. 在对话中开启"联网搜索"功能'),
                          const SizedBox(height: 4),
                          const Text('3. 如果有多个搜索工具，可指定使用哪一个'),
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
                                  'API密钥获取：Tavily (tavily.com) | SerpApi (serpapi.com) | Serper (serper.dev)',
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
                ],
              ),
            ),
          );
        },
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
                // 测试按钮
                // suffixIcon: Row(
                //   mainAxisSize: MainAxisSize.min,
                //   children: [
                //     // 测试结果指示器
                //     if (testResult != null)
                //       Icon(
                //         testResult ? Icons.check_circle : Icons.error,
                //         color: testResult ? Colors.green : Colors.red,
                //         size: 20,
                //       ),
                //     const SizedBox(width: 8),
                //     // 测试按钮
                //     if (controller.text.isNotEmpty)
                //       IconButton(
                //         onPressed: isTesting ? null : onTest,
                //         icon: isTesting
                //             ? const SizedBox(
                //                 width: 16,
                //                 height: 16,
                //                 child: CircularProgressIndicator(
                //                   strokeWidth: 2,
                //                 ),
                //               )
                //             : const Icon(Icons.wifi_protected_setup),
                //         tooltip: '测试连接',
                //       ),
                //   ],
                // ),
              ),
              validator: validator,
              obscureText: _obscureApiKey,
              onChanged: (value) {
                setState(() {
                  // 清除测试结果
                  if (controller == _tavilyController) {
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

            // 保存按钮
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

    setState(() {
      if (toolType == 'tavily') {
        _tavilyTesting = true;
        _tavilyTestResult = null;
      } else if (toolType == 'serpapi') {
        _serpApiTesting = true;
        _serpApiTestResult = null;
      } else if (toolType == 'serper') {
        _serperTesting = true;
        _serperTestResult = null;
      }
    });

    try {
      final viewModel = context.read<UnifiedChatViewModel>();

      // 临时设置API密钥进行测试
      final apiKey = toolType == 'tavily'
          ? _tavilyController.text
          : toolType == 'serpapi'
          ? _serpApiController.text
          : _serperController.text;

      await viewModel.setSearchApiKey(toolType, apiKey);
      final result = await viewModel.testSearchToolConnection(toolType);

      setState(() {
        if (toolType == 'tavily') {
          _tavilyTestResult = result;
        } else if (toolType == 'serpapi') {
          _serpApiTestResult = result;
        } else if (toolType == 'serper') {
          _serperTestResult = result;
        }
      });

      if (mounted) {
        ToastUtils.showInfo(result ? '连接测试成功' : '连接测试失败');
      }
    } catch (e) {
      setState(() {
        if (toolType == 'tavily') {
          _tavilyTestResult = false;
        } else if (toolType == 'serpapi') {
          _serpApiTestResult = false;
        } else if (toolType == 'serper') {
          _serperTestResult = false;
        }
      });

      if (mounted) {
        ToastUtils.showError('测试失败: $e');
      }
    } finally {
      setState(() {
        if (toolType == 'tavily') {
          _tavilyTesting = false;
        } else if (toolType == 'serpapi') {
          _serpApiTesting = false;
        } else if (toolType == 'serper') {
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
        leading: Radio<bool>(
          value: true,
          groupValue: isSelected,
          onChanged: isAvailable ? (_) => onSelected() : null,
        ),
        title: Row(
          children: [
            Text(title),
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
}
