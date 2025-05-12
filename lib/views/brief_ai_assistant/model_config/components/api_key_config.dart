import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../common/components/toast_utils.dart';
import '../../../../common/llm_spec/constant_llm_enum.dart';
import '../../../../common/utils/file_picker_helper.dart';
import '../../../../common/utils/screen_helper.dart';
import '../../../../services/cus_get_storage.dart';

class ApiKeyConfig extends StatefulWidget {
  const ApiKeyConfig({super.key});

  @override
  State<ApiKeyConfig> createState() => _ApiKeyConfigState();
}

class _ApiKeyConfigState extends State<ApiKeyConfig> {
  bool _obscureText = true;
  Map<String, String> _apiKeys = {};

  ApiPlatformAKLabel? _selectedPlatformKeyLabel;

  @override
  void initState() {
    super.initState();
    // 使用 Future.microtask 确保在构建完成后加载数据
    Future.microtask(() => _loadApiKeys());
  }

  void _loadApiKeys() {
    final keys = MyGetStorage().getUserAKMap();
    if (mounted) {
      setState(() => _apiKeys = keys);
    }
  }

  Future<void> _importFromJson() async {
    File? file = await FilePickerHelper.pickAndSaveFile(
      fileType: CusFileType.custom,
      allowedExtensions: ['json'],
      overwrite: true,
    );

    if (file == null) return;

    try {
      final jsonStr = await file.readAsString();
      final Map<String, dynamic> json = jsonDecode(jsonStr);

      // 保存到缓存
      await MyGetStorage().setUserAKMap(
        json.map((key, value) => MapEntry(key, value.toString())),
      );

      _loadApiKeys();

      ToastUtils.showSuccess('API KEY 导入成功');
    } catch (e) {
      ToastUtils.showError('导入失败: $e', duration: Duration(seconds: 5));
    }
  }

  Future<void> _clearAllKeys() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('确认清除'),
            content: const Text('确定要清除所有 API Key 吗？这将影响使用自定义模型的功能。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('确定'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await MyGetStorage().clearUserAKMap();
      _loadApiKeys(); // 重新加载数据
      ToastUtils.showSuccess('已清除所有 API Key');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenHelper.isDesktop()
        ? _buildDesktopLayout()
        : _buildMobileLayout();
  }

  // 桌面端布局
  Widget _buildDesktopLayout() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 16),
          Expanded(
            child: Card(
              elevation: 2,
              color: Colors.white,
              shadowColor: Colors.black.withValues(alpha: 0.05),
              child:
                  _apiKeys.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.vpn_key_outlined,
                              size: 64,
                              color: Colors.grey.withValues(alpha: 0.5),
                            ),
                            SizedBox(height: 16),
                            Text(
                              '暂无配置的 API Key',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 24),
                            ElevatedButton.icon(
                              icon: Icon(Icons.upload_file),
                              label: Text('导入配置json'),
                              onPressed: _importFromJson,
                            ),
                          ],
                        ),
                      )
                      : ListView(
                        padding: EdgeInsets.all(12),
                        children: _buildApiKeyList(),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  // 移动端布局
  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        SizedBox(height: 16),
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(vertical: 1),
            children: [
              if (_apiKeys.isEmpty)
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.vpn_key_outlined,
                          size: 48,
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '暂无配置的 API Key',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._buildApiKeyList(),
            ],
          ),
        ),
      ],
    );
  }

  // 标题栏
  Widget _buildHeader() {
    return Row(
      children: [
        Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            'API Key 配置',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => _showAddEditKeyDialog(context),
          tooltip: '添加新密钥',
        ),
        IconButton(
          icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscureText = !_obscureText),
          tooltip: _obscureText ? '显示密钥' : '隐藏密钥',
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: _clearAllKeys,
          tooltip: '清除所有密钥',
        ),
        IconButton(
          icon: const Icon(Icons.upload_file),
          onPressed: _importFromJson,
          tooltip: '导入配置json',
        ),
      ],
    );
  }

  List<Widget> _buildApiKeyList() {
    return _apiKeys.entries.map((entry) {
      return Container(
        decoration: BoxDecoration(
          // 仅顶部边框
          border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          title: Text(
            entry.key,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 4),
            child: SelectableText(
              _obscureText ? '••••••••••••••••' : entry.value,
              style: TextStyle(
                color: Colors.green.shade700,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: Colors.blue.shade300, size: 20),
                onPressed:
                    () => _showAddEditKeyDialog(
                      context,
                      existingPlatform: entry.key,
                      existingKey: entry.value,
                    ),
                tooltip: '编辑此密钥',
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red.shade300, size: 20),
                onPressed: () async {
                  final newKeys = Map<String, String>.from(_apiKeys)
                    ..remove(entry.key);
                  await MyGetStorage().setUserAKMap(newKeys);
                  _loadApiKeys();
                },
                tooltip: '删除此密钥',
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildPlatformKeyLabelDropdown() {
    return DropdownButtonFormField<ApiPlatformAKLabel>(
      value: _selectedPlatformKeyLabel,
      decoration: InputDecoration(
        labelText: '选择平台',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      ),

      menuMaxHeight: 0.5.sh,
      items:
          ApiPlatformAKLabel.values.map((platform) {
            return DropdownMenuItem(
              value: platform,
              child: Row(
                children: [
                  Text(
                    CP_LABLE_NAME_MAP[platform] ?? platform.name,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            );
          }).toList(),
      onChanged: (value) {
        setState(() => _selectedPlatformKeyLabel = value);
      },
      validator: (value) {
        if (value == null) return '请选择平台';
        return null;
      },
      isExpanded: true,
    );
  }

  // 显示添加/编辑API Key的对话框
  Future<void> _showAddEditKeyDialog(
    BuildContext context, {
    String? existingPlatform,
    String? existingKey,
  }) async {
    final isDesktop = ScreenHelper.isDesktop();
    final isEditing = existingPlatform != null;

    _selectedPlatformKeyLabel =
        ApiPlatformAKLabel.values
            .where((e) => e.name == existingPlatform)
            .firstOrNull;

    final keyController = TextEditingController(text: existingKey ?? '');
    bool showKey = false;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? '编辑 API Key' : '添加新 API Key'),
              content: SizedBox(
                width: isDesktop ? 640 : double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPlatformKeyLabelDropdown(),
                    SizedBox(height: 16),
                    TextField(
                      controller: keyController,
                      obscureText: !showKey,

                      minLines: 1,
                      decoration: InputDecoration(
                        labelText: 'API Key',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showKey ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () => setState(() => showKey = !showKey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final key = keyController.text.trim();
                    var platform = _selectedPlatformKeyLabel?.name;

                    if (platform == null || platform.isEmpty || key.isEmpty) {
                      ToastUtils.showError('平台名称和API Key不能为空');
                      return;
                    }

                    Navigator.pop(context, {platform: key});
                  },
                  child: Text(isEditing ? '保存' : '添加'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      final platform = result.keys.first;
      final key = result.values.first;

      // 更新或添加新的API Key
      final newKeys = Map<String, String>.from(_apiKeys);

      if (isEditing && platform != existingPlatform) {
        // 如果编辑时更改了平台名称（虽然UI禁止了这种情况），则先删除旧的
        newKeys.remove(existingPlatform);
      }

      newKeys[platform] = key;
      await MyGetStorage().setUserAKMap(newKeys);
      _loadApiKeys();

      ToastUtils.showSuccess(isEditing ? 'API Key已更新' : '新API Key已添加');
    }
  }
}
