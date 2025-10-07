import 'package:flutter/material.dart';

import '../../data/models/unified_platform_spec.dart';

/// 添加自定义平台对话框
class AddPlatformDialog extends StatefulWidget {
  const AddPlatformDialog({super.key});

  @override
  State<AddPlatformDialog> createState() => _AddPlatformDialogState();
}

class _AddPlatformDialogState extends State<AddPlatformDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final platform = UnifiedPlatformSpec(
        id: _nameController.text.toLowerCase().replaceAll(' ', '_'),
        displayName: _nameController.text.trim(),
        // 新建平台时只需要名称，在详情页填写必要栏位
        hostUrl: 'https://',
        apiPrefix: '/v1/chat/completions',
        description: _descriptionController.text.trim(),
        extraParams: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      Navigator.of(context).pop(platform);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加模型提供平台', style: TextStyle(fontSize: 20)),
      // 调整水平内边距，让弹窗更大些
      insetPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '平台名称',
                    hintText: '例如：阿里百炼',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入平台名称';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: '描述',
                    hintText: '例如：阿里云百炼平台',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '自定义平台需要兼容OpenAI API格式',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('添加')),
      ],
    );
  }
}
