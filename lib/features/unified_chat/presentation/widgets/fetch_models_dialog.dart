import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/toast_utils.dart';
import '../../data/models/unified_model_spec.dart';
import '../../data/models/unified_platform_spec.dart';
import '../../data/database/unified_chat_dao.dart';
import '../../data/services/unified_chat_service.dart';
import 'edit_model_dialog.dart';

/// 获取模型列表弹窗
class FetchModelsDialog extends StatefulWidget {
  final UnifiedPlatformSpec platform;

  const FetchModelsDialog({super.key, required this.platform});

  @override
  State<FetchModelsDialog> createState() => _FetchModelsDialogState();
}

class _FetchModelsDialogState extends State<FetchModelsDialog> {
  final UnifiedChatDao _chatDao = UnifiedChatDao();
  final UnifiedChatService _chatService = UnifiedChatService();
  final TextEditingController _searchController = TextEditingController();

  List<String> _availableModels = [];
  List<String> _filteredModels = [];
  List<UnifiedModelSpec> _existingModels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterModels);
    _loadModels();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterModels() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredModels = List.from(_availableModels);
      } else {
        _filteredModels = _availableModels
            .where((model) => model.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _loadModels() async {
    setState(() => _isLoading = true);

    try {
      // 获取平台现有模型
      final existingModels = await _chatDao.getModelSpecsByPlatformId(
        widget.platform.id,
      );

      // 获取API模型列表
      final apiModels = await _chatService.getPlatformModels(
        widget.platform.id,
      );

      if (!mounted) return;
      setState(() {
        _existingModels = existingModels;
        _availableModels = apiModels;
        _filteredModels = List.from(apiModels);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ToastUtils.showError('获取模型列表失败: $e');
    }
  }

  bool _isModelExists(String modelName) {
    return _existingModels.any((model) => model.modelName == modelName);
  }

  List<String> _getExistingFilteredModels() {
    return _filteredModels
        .where((modelName) => _isModelExists(modelName))
        .toList();
  }

  List<String> _getNotExistingFilteredModels() {
    return _filteredModels
        .where((modelName) => !_isModelExists(modelName))
        .toList();
  }

  Future<void> _addModel(String modelName) async {
    // 这里是将获取到的模型id添加到指定平台，但是需要传递模型id。
    // 修改模型弹窗组件不支持直接传入模型id，所以这里直接构建一个模型对象用于修改
    final model = UnifiedModelSpec(
      id: modelName,
      modelName: modelName,
      platformId: widget.platform.id,
      displayName: modelName,
      isBuiltIn: false,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await showDialog<UnifiedModelSpec>(
      context: context,
      builder: (context) => EditModelDialog(model: model),
    );

    if (result != null) {
      try {
        await _chatDao.saveModelSpec(result);
        _loadModels();
        ToastUtils.showSuccess('模型添加成功');
      } catch (e) {
        ToastUtils.showError('添加模型失败: $e');
      }
    }
  }

  Future<void> _removeModel(String modelName) async {
    final model = _existingModels.firstWhere(
      (model) => model.modelName == modelName,
    );

    try {
      await _chatDao.deleteModelSpec(model.id);
      _loadModels();
      ToastUtils.showSuccess('模型移除成功');
    } catch (e) {
      ToastUtils.showError('移除模型失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        '编辑模型',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      content: SizedBox(
        width: double.maxFinite,
        height: 0.5.sh,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // 搜索框
                  Padding(
                    padding: const EdgeInsets.all(0),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: '搜索模型...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(4),
                      ),
                    ),
                  ),
                  // 模型列表
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        // 已添加的模型
                        if (_getExistingFilteredModels().isNotEmpty) ...[
                          Text(
                            '已添加的模型',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),

                          ..._getExistingFilteredModels().map(
                            (modelName) => _buildModelItem(modelName, true),
                          ),
                        ],

                        // 未添加的模型
                        if (_getNotExistingFilteredModels().isNotEmpty) ...[
                          Text(
                            '未添加的模型',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          ..._getNotExistingFilteredModels().map(
                            (modelName) => _buildModelItem(modelName, false),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  // 构建模型项
  Widget _buildModelItem(String modelName, bool exists) {
    return Row(
      children: [
        Expanded(child: Text(modelName)),
        IconButton(
          onPressed: () {
            if (exists) {
              _removeModel(modelName);
            } else {
              _addModel(modelName);
            }
          },
          icon: Icon(
            exists ? Icons.remove_circle : Icons.add_circle,
            color: exists ? Colors.red : Colors.green,
            size: 20,
          ),
        ),
      ],
    );
  }
}
