import 'package:flutter/material.dart';

import '../../../core/storage/cus_get_storage.dart';
import '../../../core/utils/screen_helper.dart';
import '../../../shared/services/unified_llm_service.dart';
import '../../../shared/widgets/toast_utils.dart';

/// AI 翻译模型选择页(0.1.5)：
/// 指定页面内嵌 AI 翻译(MAL 详情页标题/简介等经 TranslationService
/// 调用的场景)使用的模型。此前固定取统一库第一个可用对话模型，
/// 用户不可控；选择"跟随默认"则恢复原行为。
class AiTranslationModelPage extends StatefulWidget {
  const AiTranslationModelPage({super.key});

  @override
  State<AiTranslationModelPage> createState() => _AiTranslationModelPageState();
}

class _AiTranslationModelPageState extends State<AiTranslationModelPage> {
  bool _loading = true;
  List<UnifiedModelEntry> _entries = [];
  // 当前偏好(空 = 跟随默认)
  String? _prefPlatformId;
  String? _prefModelId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pref = CusGetStorage().getAiTranslationModel();
    final entries = await UnifiedLLMService.loadModelEntries();
    if (!mounted) return;
    setState(() {
      _prefPlatformId = pref?['platformId'];
      _prefModelId = pref?['modelId'];
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _select(String? platformId, String? modelId) async {
    if (platformId == null || modelId == null) {
      await CusGetStorage().setAiTranslationModel(null);
    } else {
      await CusGetStorage().setAiTranslationModel({
        'platformId': platformId,
        'modelId': modelId,
      });
    }
    if (!mounted) return;
    setState(() {
      _prefPlatformId = platformId;
      _prefModelId = modelId;
    });
    ToastUtils.showSuccess(platformId == null ? '已恢复跟随默认模型' : 'AI 翻译模型已更新');
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ScreenHelper.isDesktop();
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 翻译模型'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 560 : double.infinity,
                ),
                child: _entries.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          Icon(
                            Icons.smart_toy_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '暂无可用对话模型，请先在聊天页-平台管理中配置平台与 API Key',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      )
                    : ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Text(
                              '页面内 AI 翻译(如 MAL 详情页标题/简介翻译按钮)使用的模型。'
                              '快速翻译页面的模型选择不受此处影响。\n'
                              '建议选择非思考模型，翻译响应更快；',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          // RadioGroup 统一管理选中值(RadioListTile 的
                          // groupValue/onChanged 已废弃)
                          RadioGroup<String>(
                            groupValue: _prefModelId == null
                                ? ''
                                : '$_prefPlatformId|$_prefModelId',
                            onChanged: (value) {
                              if (value == null || value.isEmpty) {
                                _select(null, null);
                              } else {
                                final i = value.indexOf('|');
                                _select(
                                  value.substring(0, i),
                                  value.substring(i + 1),
                                );
                              }
                            },
                            child: Column(
                              children: [
                                RadioListTile<String>(
                                  value: '',
                                  title: const Text('跟随默认'),
                                  subtitle: const Text('使用统一库第一个可用对话模型'),
                                ),
                                const Divider(),
                                ..._entries.map(
                                  (e) => RadioListTile<String>(
                                    key: ValueKey('ai_tl_${e.model.id}'),
                                    value: '${e.platform.id}|${e.model.id}',
                                    title: Text(
                                      e.model.displayName.isNotEmpty
                                          ? e.model.displayName
                                          : e.model.modelName,
                                    ),
                                    subtitle: Text(e.platform.displayName),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
              ),
            ),
    );
  }
}
