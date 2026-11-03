import 'package:flutter/material.dart';

import '../../../core/storage/cus_get_storage.dart';
import '../../../core/utils/screen_helper.dart';
import '../../../shared/widgets/toast_utils.dart';

/// 内容源 API 配置(0.1.5)：
/// 更多功能中的 TMDB / USDA FDC / NewsAPI 默认使用内置共享 Key，
/// 用户量大时容易触发平台限流；此处允许用户填自己的 Key，
/// 服务读取侧(getStoredUserKey)会优先使用用户 Key，未填回退内置。
/// Key 名与旧版"API配置"导入 json 保持一致，旧版迁移的用户值直接生效。
class ContentSourceKeysPage extends StatefulWidget {
  const ContentSourceKeysPage({super.key});

  @override
  State<ContentSourceKeysPage> createState() => _ContentSourceKeysPageState();
}

class _ContentSourceKeysPageState extends State<ContentSourceKeysPage> {
  // 与 getStoredUserKey 调用点一致的存储 key 名，勿改
  static const _kTmdbKey = 'USER_TMDB_API_KEY';
  static const _kTmdbToken = 'USER_TMDB_ACCESS_TOKEN';
  static const _kDataGovKey = 'USER_DATA_GOV_API_KEY';
  static const _kNewsApiKey = 'USER_NEWSAPI_API_KEY';

  final _tmdbKeyCtrl = TextEditingController();
  final _tmdbTokenCtrl = TextEditingController();
  final _dataGovCtrl = TextEditingController();
  final _newsApiCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    final akMap = CusGetStorage().getUserAKMap();
    _tmdbKeyCtrl.text = akMap[_kTmdbKey] ?? '';
    _tmdbTokenCtrl.text = akMap[_kTmdbToken] ?? '';
    _dataGovCtrl.text = akMap[_kDataGovKey] ?? '';
    _newsApiCtrl.text = akMap[_kNewsApiKey] ?? '';
  }

  @override
  void dispose() {
    _tmdbKeyCtrl.dispose();
    _tmdbTokenCtrl.dispose();
    _dataGovCtrl.dispose();
    _newsApiCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveKey(String keyName, String value) async {
    final akMap = CusGetStorage().getUserAKMap();
    if (value.trim().isEmpty) {
      akMap.remove(keyName);
    } else {
      akMap[keyName] = value.trim();
    }
    await CusGetStorage().setUserAKMap(akMap);
  }

  Future<void> _saveAll() async {
    await _saveKey(_kTmdbKey, _tmdbKeyCtrl.text);
    await _saveKey(_kTmdbToken, _tmdbTokenCtrl.text);
    await _saveKey(_kDataGovKey, _dataGovCtrl.text);
    await _saveKey(_kNewsApiKey, _newsApiCtrl.text);
    if (!mounted) return;
    ToastUtils.showSuccess('内容源 API Key 已保存');
  }

  Future<void> _clearAll() async {
    setState(() {
      _tmdbKeyCtrl.clear();
      _tmdbTokenCtrl.clear();
      _dataGovCtrl.clear();
      _newsApiCtrl.clear();
    });
    await _saveAll();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ScreenHelper.isDesktop();
    return Scaffold(
      appBar: AppBar(
        title: const Text('内容源 API 配置'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            key: const ValueKey('content_source_keys_clear'),
            tooltip: '清除全部自定义 Key(恢复使用内置)',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _clearAll,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: l10n ? 560 : double.infinity),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '更多功能中的部分内容源服务默认使用作者提供的共享 API Key，'
                    '有调用频率限制且可能随时失效。在此配置自己的 Key 后优'
                    '先使用(留空则回退内置 Key)。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => setState(() => _obscure = !_obscure),
                        child: Text(
                          _obscure ? '隐藏已填写的 Key' : '显示已填写的 Key',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    'TMDB(影视数据)',
                    'https://www.themoviedb.org/settings/api',
                    [
                      _buildField(_tmdbKeyCtrl, 'API Key (v3 auth)'),
                      _buildField(_tmdbTokenCtrl, 'Access Token (v4 auth)'),
                    ],
                  ),
                  _buildSection(
                    'USDA FoodData Central(美国食品营养数据)',
                    'https://fdc.nal.usda.gov/api-key-signup',
                    [_buildField(_dataGovCtrl, 'DATA_GOV API Key')],
                  ),
                  _buildSection('NewsAPI(国际新闻)', 'https://newsapi.org/login', [
                    _buildField(_newsApiCtrl, 'API Key'),
                  ]),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const ValueKey('content_source_keys_save'),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('保存配置'),
                      onPressed: _saveAll,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String url, List<Widget> fields) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                InkWell(
                  onTap: () => ToastUtils.showInfo('申请地址：$url'),
                  child: Icon(
                    Icons.link,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...fields,
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        key: ValueKey('content_source_${label.hashCode}'),
        controller: ctrl,
        obscureText: _obscure,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
