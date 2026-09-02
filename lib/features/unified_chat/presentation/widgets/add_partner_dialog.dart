import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/screen_helper.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../data/models/unified_chat_partner.dart';
import '../viewmodels/unified_chat_viewmodel.dart';

/// 添加/编辑搭档对话框
/// 2026-08-31 合并旧版角色卡系统：
/// 基础模式=轻量搭档(名称/设定/头像)，展开"角色卡高级设置"后可配置
/// 结构化人设(背景/性格/场景/示例)、开场白、专属背景、偏好模型
class AddPartnerDialog extends StatefulWidget {
  final UnifiedChatPartner? partner;

  const AddPartnerDialog({super.key, this.partner});

  @override
  State<AddPartnerDialog> createState() => _AddPartnerDialogState();
}

class _AddPartnerDialogState extends State<AddPartnerDialog> {
  late TextEditingController _nameController;
  late TextEditingController _promptController;
  late TextEditingController _avatarController;

  // 角色卡高级字段
  late TextEditingController _descriptionController;
  late TextEditingController _personalityController;
  late TextEditingController _scenarioController;
  late TextEditingController _exampleDialogueController;
  late TextEditingController _firstMessageController;
  late TextEditingController _tagsController;
  late TextEditingController _backgroundController;

  /// 专属背景不透明度
  double _backgroundOpacity = 0.35;

  /// 偏好模型id(null=不指定)
  String? _preferredModelId;

  bool _advancedExpanded = false;

  @override
  void initState() {
    super.initState();
    final p = widget.partner;
    _nameController = TextEditingController(text: p?.name ?? '');
    _promptController = TextEditingController(text: p?.prompt ?? '');
    _avatarController = TextEditingController(text: p?.avatarUrl ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _personalityController = TextEditingController(text: p?.personality ?? '');
    _scenarioController = TextEditingController(text: p?.scenario ?? '');
    _exampleDialogueController = TextEditingController(
      text: p?.exampleDialogue ?? '',
    );
    _firstMessageController = TextEditingController(
      text: p?.firstMessage ?? '',
    );
    _tagsController = TextEditingController(text: p?.tagList.join(','));
    _backgroundController = TextEditingController(text: p?.background ?? '');
    _backgroundOpacity = p?.backgroundOpacity ?? 0.35;
    _preferredModelId = p?.preferredModelId;
    _advancedExpanded = p?.hasStructuredProfile == true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _promptController.dispose();
    _avatarController.dispose();
    _descriptionController.dispose();
    _personalityController.dispose();
    _scenarioController.dispose();
    _exampleDialogueController.dispose();
    _firstMessageController.dispose();
    _tagsController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  bool _hasStructuredFields() {
    return _descriptionController.text.trim().isNotEmpty ||
        _personalityController.text.trim().isNotEmpty ||
        _scenarioController.text.trim().isNotEmpty ||
        _exampleDialogueController.text.trim().isNotEmpty;
  }

  void _handleSave() {
    if (_nameController.text.trim().isEmpty) {
      ToastUtils.showInfo('请输入搭档名称');
      return;
    }

    final hasStructured = _hasStructuredFields();

    // 未配置结构化人设时，人物设定必填(轻量搭档模式)
    if (!hasStructured && _promptController.text.trim().isEmpty) {
      ToastUtils.showInfo('请输入人物设定，或展开高级设置填写角色卡信息');
      return;
    }

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final personality = _personalityController.text.trim();
    final scenario = _scenarioController.text.trim();
    final exampleDialogue = _exampleDialogueController.text.trim();
    final firstMessage = _firstMessageController.text.trim();
    final background = _backgroundController.text.trim();
    final avatar = _avatarController.text.trim();

    // 标签：逗号分隔转JSON数组字符串
    String? tagsJson;
    final tagsText = _tagsController.text.trim();
    if (tagsText.isNotEmpty) {
      final tags = tagsText
          .split(RegExp(r'[,，]'))
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      if (tags.isNotEmpty) tagsJson = jsonEncode(tags);
    }

    final now = DateTime.now();
    final partner = UnifiedChatPartner(
      id: widget.partner?.id ?? const Uuid().v4(),
      name: name,
      // 配置了结构化人设时自动生成系统提示词(与旧版角色卡一致)，否则用填写的Prompt
      prompt: hasStructured
          ? UnifiedChatPartner(
              id: 'tmp',
              name: name,
              prompt: '',
              description: description,
              personality: personality,
              scenario: scenario,
              exampleDialogue: exampleDialogue,
              tags: tagsJson,
              createdAt: now,
              updatedAt: now,
            ).generateSystemPrompt()
          : _promptController.text.trim(),
      avatarUrl: avatar.isEmpty ? null : avatar,
      isBuiltIn: widget.partner?.isBuiltIn ?? false,
      isActive: true,
      isFavorite: widget.partner?.isFavorite ?? false,
      createdAt: widget.partner?.createdAt ?? now,
      updatedAt: now,
      contextMessageLength: widget.partner?.contextMessageLength ?? 6,
      temperature: widget.partner?.temperature ?? 0.7,
      topP: widget.partner?.topP ?? 1.0,
      maxTokens: widget.partner?.maxTokens ?? 4096,
      description: description.isEmpty ? null : description,
      personality: personality.isEmpty ? null : personality,
      scenario: scenario.isEmpty ? null : scenario,
      firstMessage: firstMessage.isEmpty ? null : firstMessage,
      exampleDialogue: exampleDialogue.isEmpty ? null : exampleDialogue,
      tags: tagsJson,
      preferredModelId: _preferredModelId,
      background: background.isEmpty ? null : background,
      backgroundOpacity: background.isEmpty ? null : _backgroundOpacity,
    );

    Navigator.of(context).pop(partner);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.partner != null;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Text(isEditing ? '编辑搭档' : '创建搭档'),
        ],
      ),
      content: SizedBox(
        // 桌面限宽为紧凑弹窗，避免超宽横条(移动端满宽)
        width: ScreenHelper.isDesktop() ? 520.0 : double.maxFinite,
        height: ScreenHelper.isDesktop() ? 600.0 : 0.7.sh,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 搭档名称
              const Text('搭档名称', style: TextStyle(color: Colors.grey)),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(8),
                  hintText: '给你的搭档起个名字',
                ),
              ),
              const SizedBox(height: 8),

              // 人物设定 (Prompt)
              const Text('人物设定（Prompt）', style: TextStyle(color: Colors.grey)),
              TextField(
                controller: _promptController,
                maxLines: 5,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.all(8),
                  hintText: _hasStructuredFields()
                      ? '已配置角色卡信息，Prompt将自动生成(可留空)'
                      : '描述你的搭档的角色、性格、专长等...',
                ),
              ),
              const SizedBox(height: 8),

              // 搭档头像链接
              const Text('搭档头像链接', style: TextStyle(color: Colors.grey)),
              TextField(
                controller: _avatarController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(8),
                  hintText: '输入头像图片链接（可选）',
                ),
              ),
              const SizedBox(height: 8),

              // 角色卡高级设置
              ExpansionTile(
                title: const Text('角色卡高级设置', style: TextStyle(fontSize: 14)),
                subtitle: const Text(
                  '结构化人设/开场白/专属背景/偏好模型',
                  style: TextStyle(fontSize: 12),
                ),
                initiallyExpanded: _advancedExpanded,
                children: [
                  _buildLabel('角色背景描述'),
                  _buildTextField(
                    _descriptionController,
                    '角色的身份、经历、知识背景等',
                    maxLines: 3,
                  ),
                  _buildLabel('性格特点'),
                  _buildTextField(_personalityController, '角色的性格、说话风格等'),
                  _buildLabel('场景设定'),
                  _buildTextField(_scenarioController, '对话发生的场景/世界观'),
                  _buildLabel('对话示例'),
                  _buildTextField(
                    _exampleDialogueController,
                    '示例对话，帮助模型理解角色语气',
                    maxLines: 3,
                  ),
                  _buildLabel('开场白'),
                  _buildTextField(
                    _firstMessageController,
                    '开始新对话时自动发送的开场白(不调用模型)',
                    maxLines: 3,
                  ),
                  _buildLabel('标签(逗号分隔)'),
                  _buildTextField(_tagsController, '如: 虚拟, 角色扮演, 助手'),
                  _buildLabel('专属背景(图片路径或链接)'),
                  _buildTextField(_backgroundController, '该搭档对话时优先使用此背景图'),
                  if (_backgroundController.text.trim().isNotEmpty)
                    Row(
                      children: [
                        const Text('背景不透明度'),
                        Expanded(
                          child: Slider(
                            value: _backgroundOpacity,
                            min: 0.1,
                            max: 1.0,
                            label: '${(_backgroundOpacity * 100).toInt()}%',
                            onChanged: (v) =>
                                setState(() => _backgroundOpacity = v),
                          ),
                        ),
                        Text('${(_backgroundOpacity * 100).toInt()}%'),
                      ],
                    ),
                  _buildLabel('偏好模型'),
                  _buildPreferredModelSelector(),
                  const SizedBox(height: 8),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _handleSave,
          child: Text(isEditing ? '保存' : '创建'),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.all(8),
        hintText: hint,
        isDense: true,
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  /// 偏好模型下拉(选择该搭档时自动切换到该模型)
  Widget _buildPreferredModelSelector() {
    return Consumer<UnifiedChatViewModel>(
      builder: (context, viewModel, _) {
        final models = viewModel.availableModels;
        if (models.isEmpty) {
          return const Text(
            '暂无可用模型(配置后可选)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          );
        }
        return DropdownButtonFormField<String?>(
          initialValue: models.any((m) => m.id == _preferredModelId)
              ? _preferredModelId
              : null,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            isDense: true,
          ),
          isExpanded: true,
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('不指定')),
            ...models.map(
              (m) => DropdownMenuItem<String?>(
                value: m.id,
                child: Text(m.displayName, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _preferredModelId = v),
        );
      },
    );
  }
}
