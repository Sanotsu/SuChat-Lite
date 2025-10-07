import 'package:flutter/material.dart';

import '../../data/models/unified_model_spec.dart';

/// 编辑(新增或修改)模型对话框
class EditModelDialog extends StatefulWidget {
  // 如果传入是模型，则为修改
  final UnifiedModelSpec? model;
  // 如果传入是平台编号，则为新增
  final String? platformId;

  const EditModelDialog({super.key, this.model, this.platformId});

  @override
  State<EditModelDialog> createState() => _EditModelDialogState();
}

class _EditModelDialogState extends State<EditModelDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _idController;
  late final TextEditingController _displayNameController;

  late String _selectedModelType;
  late bool _supportsVision;
  late bool _supportsThinking;
  late bool _supportsToolCalling;

  @override
  void initState() {
    super.initState();
    if (widget.model != null) {
      _idController = TextEditingController(text: widget.model!.modelName);
      _displayNameController = TextEditingController(
        text: widget.model!.displayName,
      );
      // 初始化
      _selectedModelType = widget.model!.modelType;
      _supportsVision = widget.model!.supportsVision;
      _supportsThinking = widget.model!.supportsThinking;
      _supportsToolCalling = widget.model!.supportsToolCalling;
    } else {
      _idController = TextEditingController();
      _displayNameController = TextEditingController();
      _selectedModelType = UnifiedModelType.cc.name;
      _supportsVision = false;
      _supportsThinking = false;
      _supportsToolCalling = false;
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      UnifiedModelSpec model;

      if (widget.model != null) {
        model = widget.model!.copyWith(
          modelName: _idController.text.trim(),
          displayName: _displayNameController.text.trim().isNotEmpty
              ? _displayNameController.text.trim()
              : _idController.text.trim(),
          modelType: _selectedModelType,
          supportsThinking: _supportsThinking,
          supportsVision: _supportsVision,
          supportsToolCalling: _supportsToolCalling,
          updatedAt: DateTime.now(),
        );
      } else if (widget.platformId != null) {
        model = UnifiedModelSpec(
          id: _idController.text.trim(),
          platformId: widget.platformId!,
          modelName: _idController.text.trim(),
          displayName: _displayNameController.text.trim().isNotEmpty
              ? _displayNameController.text.trim()
              : _idController.text.trim(),
          modelType: _selectedModelType,
          supportsThinking: _supportsThinking,
          supportsVision: _supportsVision,
          supportsToolCalling: _supportsToolCalling,
          isFavorite: false,
          isBuiltIn: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        throw Exception('未正确传入模块或平台编号');
      }

      Navigator.of(context).pop(model);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑模型'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 模型ID字段
                TextFormField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: '*模型ID',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入模型ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 显示名称字段
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: '显示名称(可选)',
                    hintText: '可选',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // 模型类型下拉框
                DropdownButtonFormField<String>(
                  value: _selectedModelType,
                  decoration: const InputDecoration(
                    labelText: '模型类型',
                    border: OutlineInputBorder(),
                  ),
                  items: UnifiedModelType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type.name,
                          child: Text(UMT_NAME_MAP[type]!),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedModelType = value!;
                      if (value != UnifiedModelType.cc.name) {
                        _supportsVision = false;
                        _supportsThinking = false;
                        _supportsToolCalling = false;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),

                // 能力标题
                if (_selectedModelType == UnifiedModelType.cc.name) ...[
                  const Text(
                    '能力',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),

                  // 能力复选框
                  Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: CheckboxListTile(
                          title: const Text('视觉'),
                          value: _supportsVision,
                          onChanged: (value) =>
                              setState(() => _supportsVision = value ?? false),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: CheckboxListTile(
                          title: const Text('推理'),
                          value: _supportsThinking,
                          onChanged: (value) => setState(
                            () => _supportsThinking = value ?? false,
                          ),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('工具使用'),
                          value: _supportsToolCalling,
                          onChanged: (value) => setState(
                            () => _supportsToolCalling = value ?? false,
                          ),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                    ],
                  ),
                ],
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
        ElevatedButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }
}
