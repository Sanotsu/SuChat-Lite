import 'package:flutter/material.dart';

import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../data/models/unified_platform_spec.dart';
import '../../data/models/unified_model_spec.dart';
import '../../data/database/unified_chat_dao.dart';
import '../../data/services/unified_chat_service.dart';
import '../../data/services/unified_secure_storage.dart';
import '../widgets/edit_model_dialog.dart';
import '../widgets/fetch_models_dialog.dart';

/// 平台详情页面
class PlatformDetailPage extends StatefulWidget {
  final UnifiedPlatformSpec platform;

  const PlatformDetailPage({super.key, required this.platform});

  @override
  State<PlatformDetailPage> createState() => _PlatformDetailPageState();
}

class _PlatformDetailPageState extends State<PlatformDetailPage> {
  final UnifiedChatDao _chatDao = UnifiedChatDao();
  final UnifiedChatService _chatService = UnifiedChatService();
  final _formKey = GlobalKey<FormState>();

  // 表单控制器
  late TextEditingController _nameController;
  late TextEditingController _apiKeyController;
  late TextEditingController _hostUrlController;
  late TextEditingController _apiPerfixController;
  late TextEditingController _searchController;

  // 状态变量
  String _selectedApiMode = 'OpenAI API 兼容';
  bool _isApiKeyVisible = false;
  String? _connectionStatus;
  List<UnifiedModelSpec> _models = [];
  List<UnifiedModelSpec> _filteredModels = [];
  bool _isLoadingModels = true;

  // 标记表单是否有修改
  bool _isFormModified = false;

  // 是否显示请求地址和端点
  bool _isUrlVisible = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadData();
  }

  void _initControllers() {
    _nameController = TextEditingController(text: widget.platform.displayName);
    _apiKeyController = TextEditingController();
    _hostUrlController = TextEditingController(text: widget.platform.hostUrl);
    _apiPerfixController = TextEditingController(
      text: widget.platform.ccPrefix,
    );
    _searchController = TextEditingController();

    _searchController.addListener(_filterModels);

    // 添加监听器来标记表单修改状态
    _nameController.addListener(_markFormAsModified);
    _hostUrlController.addListener(_markFormAsModified);
    _apiPerfixController.addListener(_markFormAsModified);
  }

  void _markFormAsModified() {
    if (!_isFormModified) {
      setState(() {
        _isFormModified = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _apiKeyController.dispose();
    _hostUrlController.dispose();
    _apiPerfixController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadApiKey(), _loadModels()]);
  }

  Future<void> _loadApiKey() async {
    try {
      final apiKey = await UnifiedSecureStorage.getApiKey(widget.platform.id);
      if (mounted) {
        setState(() {
          _apiKeyController.text = apiKey ?? '';
        });
      }
    } catch (e) {
      // 忽略加载错误
    }
  }

  // 加载模型
  Future<void> _loadModels() async {
    setState(() => _isLoadingModels = true);
    try {
      final models = await _chatDao.getModelSpecsByPlatformId(
        widget.platform.id,
      );

      setState(() {
        _models = models;
        _filteredModels = models;
        _isLoadingModels = false;
      });
    } catch (e) {
      setState(() => _isLoadingModels = false);
      ToastUtils.showError('加载模型列表失败: $e');
    }
  }

  // 重置模型
  Future<void> _resetModels() async {
    setState(() => _isLoadingModels = true);
    try {
      // 先删除指定平台非内置模型
      await _chatDao.deleteNonBuiltInModelSpecs(widget.platform.id);

      // 再重新添加内置模型（可以简单点，重新加载所有内置平台模型）
      var platforms = UnifiedPlatformId.values
          .where((p) => p.name == widget.platform.id)
          .toList();

      if (platforms.isEmpty) {
        await _chatDao.reloadBuiltInPlatforms();
      } else {
        await _chatDao.reloadBuiltInPlatforms(platformId: platforms.first);
      }

      // 然后重新查询模型
      final models = await _chatDao.getModelSpecsByPlatformId(
        widget.platform.id,
      );
      if (!mounted) return;
      setState(() {
        _models = models;
        _filteredModels = models;
        _isLoadingModels = false;
      });
    } catch (e) {
      setState(() => _isLoadingModels = false);
      ToastUtils.showError('加载模型列表失败: $e');
    }
  }

  // 清空所有自定义和内置模型
  Future<void> _clearModels() async {
    setState(() => _isLoadingModels = true);
    try {
      // 先删除指定平台所有模型
      await _chatDao.deleteAllModelSpecs(widget.platform.id);

      // 然后重新查询模型
      final models = await _chatDao.getModelSpecsByPlatformId(
        widget.platform.id,
      );
      if (!mounted) return;
      setState(() {
        _models = models;
        _filteredModels = models;
        _isLoadingModels = false;
      });
    } catch (e) {
      setState(() => _isLoadingModels = false);
      ToastUtils.showError('加载模型列表失败: $e');
    }
  }

  void _filterModels() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredModels = _models.where((model) {
        return model.displayName.toLowerCase().contains(query) ||
            model.modelName.toLowerCase().contains(query);
      }).toList();
    });
  }

  // 保存平台信息
  Future<void> _savePlatform() async {
    if (_formKey.currentState!.validate()) {
      try {
        final platform = widget.platform.copyWith(
          displayName: _nameController.text.trim(),
          hostUrl: _hostUrlController.text.trim(),
          ccPrefix: _apiPerfixController.text.trim(),
        );

        await _chatDao.savePlatformSpec(platform);

        setState(() {
          _isFormModified = false;
        });

        ToastUtils.showSuccess('平台信息保存成功');
      } catch (e) {
        ToastUtils.showError('保存平台信息失败: $e');
      }
    }
  }

  // 删除平台
  Future<void> _deletePlatform() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除平台'),
        content: Text('确定要删除平台 "${widget.platform.displayName}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _chatDao.deletePlatformSpec(widget.platform.id);
        if (!mounted) return;
        Navigator.of(context).pop();
        ToastUtils.showSuccess('平台删除成功');
      } catch (e) {
        ToastUtils.showError('删除平台失败: $e');
      }
    }
  }

  Future<void> _testConnection() async {
    unfocusHandle();

    if (_apiKeyController.text.isEmpty) {
      ToastUtils.showError('请先输入API密钥');
      return;
    }

    setState(() => _connectionStatus = 'testing');

    // 连接测试
    final result = await _chatService.testApiConnection(
      widget.platform.id,
      type: "text",
    );

    if (result) {
      setState(() => _connectionStatus = 'success');
      ToastUtils.showSuccess('连接成功！');

      // 只有连接成功的才将该平台的是否激活设置为true，同时再次保存密钥
      await _chatDao.savePlatformSpec(
        widget.platform.copyWith(
          isActive: true,
          displayName: _nameController.text.trim(),
          hostUrl: _hostUrlController.text.trim(),
          ccPrefix: _apiPerfixController.text.trim(),
        ),
      );
      await _saveApiKey();
    } else {
      setState(() => _connectionStatus = 'failed');
      ToastUtils.showError('连接失败！');

      // 连接失败，要手动确认重置激活状态为false
      await _chatDao.savePlatformSpec(
        widget.platform.copyWith(isActive: false),
      );
    }
  }

  Future<void> _saveApiKey() async {
    if (_apiKeyController.text.trim().isNotEmpty) {
      try {
        await UnifiedSecureStorage.storeApiKey(
          widget.platform.id,
          _apiKeyController.text.trim(),
        );
      } catch (e) {
        ToastUtils.showError('保存API密钥失败: $e');
      }
    }
  }

  Future<void> _showAddModelDialog() async {
    final result = await showDialog<UnifiedModelSpec>(
      context: context,
      builder: (context) => EditModelDialog(platformId: widget.platform.id),
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

  Future<void> _showEditModelDialog(UnifiedModelSpec model) async {
    final result = await showDialog<UnifiedModelSpec>(
      context: context,
      builder: (context) => EditModelDialog(model: model),
    );

    if (result != null) {
      try {
        await _chatDao.saveModelSpec(result);
        _loadModels();
        ToastUtils.showSuccess('模型更新成功');
      } catch (e) {
        ToastUtils.showError('更新模型失败: $e');
      }
    }
  }

  Future<void> _deleteModel(UnifiedModelSpec model) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除模型'),
        content: Text('确定要删除模型 "${model.displayName}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _chatDao.deleteModelSpec(model.id);
        _loadModels();
        ToastUtils.showSuccess('模型删除成功');
      } catch (e) {
        ToastUtils.showError('删除模型失败: $e');
      }
    }
  }

  Future<void> _resetModelsDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置模型'),
        content: const Text('确定要重置模型吗？这将删除所有自定义模型，并重新加载内置模型。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('重置', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 重置及只保留内置模型
      await _resetModels();
      ToastUtils.showSuccess('模型已重置');
    }
  }

  Future<void> _fetchModelsDialog() async {
    if (_apiKeyController.text.isEmpty) {
      ToastUtils.showError('请先输入API密钥');
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => FetchModelsDialog(platform: widget.platform),
    );

    _loadModels();
  }

  Future<void> _clearModelsDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空模型'),
        content: const Text('确定要清空所有模型吗？这将删除所有内置和自定义模型。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('清空', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 清空所有模型
      await _clearModels();
      ToastUtils.showSuccess('模型已清空');
    }
  }

  // 取消修改
  void _cancelChanges() {
    _nameController.text = widget.platform.displayName;
    _hostUrlController.text = widget.platform.hostUrl;
    _apiPerfixController.text = widget.platform.ccPrefix;

    setState(() {
      _isFormModified = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          // 保存按钮
          if (_isFormModified && !widget.platform.isBuiltIn) ...[
            TextButton(
              onPressed: _cancelChanges,
              child: const Text('取消', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: _savePlatform,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('保存'),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: buildPlatformForm(),
        ),
      ),
    );
  }

  Widget buildPlatformForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 平台标题和删除按钮
        Row(
          children: [
            Expanded(
              child: Text(
                widget.platform.displayName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() => _isUrlVisible = !_isUrlVisible);
              },
              icon: Icon(
                _isUrlVisible ? Icons.visibility_off : Icons.visibility,
              ),
              tooltip: _isUrlVisible ? '隐藏地址和端点' : '显示地址和端点',
            ),
            IconButton(
              onPressed: _deletePlatform,
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 名称字段
        // 如果是内置平台，不需要修改
        if (!widget.platform.isBuiltIn) ...[
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '名称',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // API模式下拉框
        // 如果是内置平台，不需要修改
        if (!widget.platform.isBuiltIn) ...[
          DropdownButtonFormField<String>(
            value: _selectedApiMode,
            decoration: const InputDecoration(
              labelText: 'API模式',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'OpenAI API 兼容',
                child: Text('OpenAI API 兼容'),
              ),
            ],
            onChanged: (value) {
              setState(() => _selectedApiMode = value!);
            },
          ),
          const SizedBox(height: 16),
        ],

        // API密钥字段
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  labelText: 'API密钥',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => _isApiKeyVisible = !_isApiKeyVisible);
                    },
                    icon: Icon(
                      _isApiKeyVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
                obscureText: !_isApiKeyVisible,
                onChanged: (_) => _saveApiKey(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _testConnection,
              style: ElevatedButton.styleFrom(
                backgroundColor: _connectionStatus == 'success'
                    ? Colors.green
                    : Colors.blue,
              ),
              child: _connectionStatus == 'testing'
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('检查', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),

        // 连接成功提示
        if (_connectionStatus == 'success')
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              '连接成功！',
              style: TextStyle(color: Colors.green, fontSize: 12),
            ),
          ),
        const SizedBox(height: 16),

        // API主机和路径
        // 如果是内置平台，不需要修改
        if (!widget.platform.isBuiltIn) ...[
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _hostUrlController,
                  decoration: const InputDecoration(
                    labelText: 'API主机',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _apiPerfixController,
                  decoration: const InputDecoration(
                    labelText: 'API路径',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          Text(_hostUrlController.text + _apiPerfixController.text),
          const SizedBox(height: 16),
        ],

        // 如果是内置平台，条件显示地址和端点
        if (widget.platform.isBuiltIn && _isUrlVisible) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              "基础请求地址: ${widget.platform.hostUrl}"
              "\n对话完成端点: ${widget.platform.ccPrefix}"
              "\n图片生成端点: ${(widget.platform.imgGenPrefix ?? '不支持')}"
              "\n语音合成端点: ${(widget.platform.ttsPrefix ?? '不支持')}"
              "\n语音识别端点: ${(widget.platform.asrPrefix ?? '不支持')}",
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],

        // 模型管理相关
        ...buildModelList(),
      ],
    );
  }

  List<Widget> buildModelList() {
    return [
      // 模型管理标题和按钮
      Row(
        children: [
          const Text(
            '模型',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _showAddModelDialog,
            style: TextButton.styleFrom(
              minimumSize: Size(24, 24),
              padding: EdgeInsets.symmetric(horizontal: 8),
            ),
            icon: const Icon(Icons.add, color: Colors.blue),
            label: const Text('新建', style: TextStyle(color: Colors.blue)),
          ),
          TextButton.icon(
            onPressed: _resetModelsDialog,
            style: TextButton.styleFrom(
              minimumSize: Size(24, 24),
              padding: EdgeInsets.symmetric(horizontal: 8),
            ),
            icon: const Icon(Icons.refresh, color: Colors.orange),
            label: const Text('重置', style: TextStyle(color: Colors.orange)),
          ),
          TextButton.icon(
            onPressed: _clearModelsDialog,
            style: TextButton.styleFrom(
              minimumSize: Size(24, 24),
              padding: EdgeInsets.symmetric(horizontal: 8),
            ),
            icon: const Icon(Icons.remove_circle, color: Colors.red),
            label: const Text('清除', style: TextStyle(color: Colors.red)),
          ),
          TextButton.icon(
            onPressed: _fetchModelsDialog,
            style: TextButton.styleFrom(
              minimumSize: Size(24, 24),
              padding: EdgeInsets.symmetric(horizontal: 8),
            ),
            icon: const Icon(Icons.download, color: Colors.green),
            label: const Text('获取', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
      const SizedBox(height: 16),

      // 模型搜索框
      TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: '搜索模型...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 16),

      // 模型列表
      _isLoadingModels
          ? const Center(child: CircularProgressIndicator())
          : _filteredModels.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  '没有可用模型',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            )
          : Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: _filteredModels.map(buildModelItem).toList(),
              ),
            ),
    ];
  }

  Widget buildModelItem(UnifiedModelSpec model) {
    buildTooltip(String message, IconData icon, Color color) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Tooltip(
          message: message,
          child: Icon(icon, color: color, size: 20),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Wrap(
              children: [
                Text(model.modelName),

                if (model.supportsThinking)
                  buildTooltip('推理', Icons.psychology_outlined, Colors.orange),
                if (model.supportsVision)
                  buildTooltip('视觉', Icons.visibility_outlined, Colors.blue),
                if (model.supportsToolCalling)
                  buildTooltip('工具调用', Icons.build_outlined, Colors.green),
              ],
            ),
          ),

          InkWell(
            onTap: () => _showEditModelDialog(model),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.settings,
                size: 20,
                color: Theme.of(context).disabledColor,
              ),
            ),
          ),
          InkWell(
            onTap: () => _deleteModel(model),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.remove_circle, size: 20, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
