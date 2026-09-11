import 'package:flutter/material.dart';

import '../../../../shared/widgets/cus_content_width.dart';
import '../../../../shared/widgets/image_preview_helper.dart';
import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../data/database/unified_chat_dao.dart';
import '../../data/models/unified_chat_partner.dart';
import '../../data/models/unified_model_spec.dart';
import 'partner_edit_page.dart';

/// 搭档详情页
/// 2026-09-07 新增：内置/自制搭档均可在完整页面中查看全部字段
/// (提示词/角色卡等人设内容多时弹窗无法完整展示)；
/// 编辑、删除、收藏操作收敛到此页，外层列表项不再摆放操作按钮
class PartnerDetailPage extends StatefulWidget {
  final UnifiedChatPartner partner;

  const PartnerDetailPage({super.key, required this.partner});

  @override
  State<PartnerDetailPage> createState() => _PartnerDetailPageState();
}

class _PartnerDetailPageState extends State<PartnerDetailPage> {
  final UnifiedChatDao _chatDao = UnifiedChatDao();

  late UnifiedChatPartner _partner;

  /// 2026-09-07 模型id -> "模型名 · 平台名"(直读数据库，
  /// 不依赖 viewModel.availableModels 的AK过滤与初始化时机)
  final Map<String, String> _modelNames = {};

  @override
  void initState() {
    super.initState();
    _partner = widget.partner;
    _loadModelNames();
  }

  Future<void> _loadModelNames() async {
    try {
      final platforms = await _chatDao.getPlatformSpecs(isActive: true);
      final platformNames = {
        for (final plat in platforms) plat.id: plat.displayName,
      };
      final models = (await _chatDao.getModelSpecs(
        platformIds: platforms.map((plat) => plat.id).toList(),
      )).where((element) => element.type == UnifiedModelType.cc).toList();

      if (!mounted) return;
      setState(() {
        for (final m in models) {
          final platformName = platformNames[m.platformId];
          _modelNames[m.id] = (platformName == null || platformName.isEmpty)
              ? m.displayName
              : '${m.displayName} · $platformName';
        }
      });
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    await _chatDao.togglePartnerFavorite(_partner.id);
    if (!mounted) return;
    setState(() {
      _partner = _partner.copyWith(
        isFavorite: !_partner.isFavorite,
        updatedAt: DateTime.now(),
      );
    });
  }

  Future<void> _editPartner() async {
    final result = await Navigator.push<UnifiedChatPartner>(
      context,
      MaterialPageRoute(
        builder: (context) => PartnerEditPage(partner: _partner),
      ),
    );

    if (result != null) {
      await _chatDao.saveChatPartner(result);
      if (!mounted) return;
      ToastUtils.showSuccess('搭档已保存');
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _deletePartner() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除搭档'),
        content: Text('确定要删除搭档"${_partner.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _chatDao.deleteChatPartner(_partner.id);
      if (!mounted) return;
      ToastUtils.showSuccess('搭档已删除');
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 2026-09-10 与其他桌面端页面统一：CusContentWidth.form包在Scaffold外层，
    // 整个页面(AppBar+内容)限宽居中，窄屏原样铺满
    return CusContentWidth.form(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_partner.isBuiltIn ? '内置搭档详情' : '搭档详情'),
          actions: [
            IconButton(
              onPressed: _partner.isBuiltIn ? null : _toggleFavorite,
              icon: Icon(
                _partner.isFavorite ? Icons.star : Icons.star_border,
                color: _partner.isFavorite ? Colors.orange : null,
              ),
              tooltip: _partner.isFavorite ? '取消收藏' : '收藏',
            ),
            if (!_partner.isBuiltIn)
              IconButton(
                onPressed: _editPartner,
                icon: const Icon(Icons.edit),
                tooltip: '编辑',
              ),
            if (!_partner.isBuiltIn)
              IconButton(
                onPressed: _deletePartner,
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: '删除',
              ),
            const SizedBox(width: 4),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(),
            _buildSection('人物设定（Prompt）', _partner.prompt),
            if (_partner.description != null)
              _buildSection('角色背景描述', _partner.description!),
            if (_partner.personality != null)
              _buildSection('性格特点', _partner.personality!),
            if (_partner.scenario != null)
              _buildSection('场景设定', _partner.scenario!),
            if (_partner.firstMessage != null)
              _buildSection('开场白', _partner.firstMessage!),
            if (_partner.exampleDialogue != null)
              _buildSection('对话示例', _partner.exampleDialogue!),
            if (_partner.tagList.isNotEmpty) _buildTags(),
            _buildBackgroundSection(),
            _buildParamsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          buildUserCircleAvatar(
            _partner.avatarUrl,
            backgroundColor: Colors.blue,
            radius: 32,
            defaultAvatar: Text(
              _partner.name.isNotEmpty ? _partner.name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _partner.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: Text(
                        _partner.isBuiltIn ? '内置' : '自制',
                        style: const TextStyle(fontSize: 12),
                      ),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: _partner.isBuiltIn
                          ? Colors.blue.withValues(alpha: 0.15)
                          : Colors.green.withValues(alpha: 0.15),
                    ),
                    if (_partner.preferredModelId != null)
                      Builder(
                        builder: (context) {
                          final modelName =
                              _modelNames[_partner.preferredModelId] ??
                              _partner.preferredModelId!;
                          return Chip(
                            label: Text(
                              '偏好模型: $modelName',
                              style: const TextStyle(fontSize: 12),
                            ),
                            visualDensity: VisualDensity.compact,
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            // 长文本完整展示且可选中复制
            SelectableText(
              content,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTags() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '标签',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _partner.tagList
                  .map(
                    (t) => Chip(
                      label: Text(t),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundSection() {
    final bg = _partner.background;
    if (bg == null || bg.trim().isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '专属背景',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: buildNetworkOrFileImage(bg, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '不透明度: ${((_partner.backgroundOpacity ?? 0.35) * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParamsSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '对话参数',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            // 2026-09-09 null=不限制上下文(携带全部历史)；0=仅最新一条
            _buildParamRow(
              '上下文消息数',
              _partner.contextMessageLength?.toString() ?? '不限制',
            ),
            // 2026-09-09 null=未设置(请求不传该参数，由平台API默认值生效)
            _buildParamRow(
              '温度 temperature',
              _partner.temperature?.toString() ?? '未设置(平台默认)',
            ),
            _buildParamRow('top_p', _partner.topP?.toString() ?? '未设置(平台默认)'),
            _buildParamRow(
              '最大Token',
              _partner.maxTokens?.toString() ?? '未设置(平台默认)',
            ),
            _buildParamRow('流式输出', _partner.isStream == true ? '开' : '关'),
          ],
        ),
      ),
    );
  }

  Widget _buildParamRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor),
          ),
        ],
      ),
    );
  }
}
