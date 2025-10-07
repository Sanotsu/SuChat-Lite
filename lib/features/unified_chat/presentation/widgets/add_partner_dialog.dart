import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

import '../../../../shared/widgets/toast_utils.dart';
import '../../data/models/unified_chat_partner.dart';

/// 添加/编辑搭档对话框
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.partner?.name ?? '');
    _promptController = TextEditingController(
      text: widget.partner?.prompt ?? '',
    );
    _avatarController = TextEditingController(
      text: widget.partner?.avatarUrl ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _promptController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_nameController.text.trim().isEmpty) {
      ToastUtils.showInfo('请输入搭档名称');
      return;
    }

    if (_promptController.text.trim().isEmpty) {
      ToastUtils.showInfo('请输入人物设定');
      return;
    }

    final now = DateTime.now();
    final partner = UnifiedChatPartner(
      id: widget.partner?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      prompt: _promptController.text.trim(),
      avatarUrl: _avatarController.text.trim().isEmpty
          ? null
          : _avatarController.text.trim(),
      isBuiltIn: widget.partner?.isBuiltIn ?? false,
      isActive: true,
      isFavorite: widget.partner?.isFavorite ?? false,
      createdAt: widget.partner?.createdAt ?? now,
      updatedAt: now,
      contextMessageLength: widget.partner?.contextMessageLength ?? 6,
      temperature: widget.partner?.temperature ?? 0.7,
      topP: widget.partner?.topP ?? 1.0,
      maxTokens: widget.partner?.maxTokens ?? 4096,
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
        width: double.maxFinite,
        height: 0.6.sh,
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
                maxLines: 8,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(8),
                  hintText: '描述你的搭档的角色、性格、专长等...',
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
              const SizedBox(height: 16),
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
}
