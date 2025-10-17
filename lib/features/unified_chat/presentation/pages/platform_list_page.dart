import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/file_picker_utils.dart';
import '../../../../core/utils/simple_tools.dart';
import '../../../../shared/widgets/image_preview_helper.dart';
import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../../../shared/widgets/toast_utils.dart';
import '../../data/models/unified_model_spec.dart';
import '../../data/models/unified_platform_spec.dart';
import '../../data/database/unified_chat_dao.dart';
import '../../data/services/unified_chat_service.dart';
import '../../data/services/unified_secure_storage.dart';
import '../widgets/add_platform_dialog.dart';
import 'platform_detail_page.dart';

/// 平台列表页面
class PlatformListPage extends StatefulWidget {
  const PlatformListPage({super.key});

  @override
  State<PlatformListPage> createState() => _PlatformListPageState();
}

class _PlatformListPageState extends State<PlatformListPage> {
  final UnifiedChatDao _chatDao = UnifiedChatDao();
  final UnifiedChatService _chatService = UnifiedChatService();

  List<UnifiedPlatformSpec> _platforms = [];
  bool _isLoading = true;
  bool _isImporting = false;

  String get note =>
      '''
导入的json文件**必填**栏位如下:
```json
[
  {
    "platform": "aliyun",
    "model": "qwen-tts-latest",
    "modelType": "tts",
  },
  // ...
]
```
其中，**platform**可选值:

${UnifiedPlatformId.values.map((e) => e.name).join(", ")}

**modelType**可选值:

${UnifiedModelType.values.map((e) => e.name).join(", ")}
''';

  @override
  void initState() {
    super.initState();
    _loadPlatforms();
  }

  Future<void> _loadPlatforms() async {
    setState(() => _isLoading = true);
    try {
      final platforms = await _chatDao.getPlatformSpecs();
      setState(() {
        _platforms = platforms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);

      ToastUtils.showError('加载平台列表失败: $e');
      rethrow;
    }
  }

  // 重新加载内置平台和模型
  Future<void> _reloadBuiltInPlatforms() async {
    setState(() => _isLoading = true);
    try {
      await _chatDao.reloadBuiltInPlatforms();

      final platforms = await _chatDao.getPlatformSpecs();

      // 检查每个平台的连接状态
      for (var i = 0; i < platforms.length; i++) {
        var plat = platforms[i];
        await _testConnection(plat);
      }

      // 重新查询，获取更新后激活状态
      final newPlatforms = await _chatDao.getPlatformSpecs();

      setState(() {
        _platforms = newPlatforms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);

      ToastUtils.showError('加载平台列表失败: $e');
      rethrow;
    }
  }

  // 从JSON文件导入模型
  Future<void> _importFromJson() async {
    File? file = await FilePickerUtils.pickAndSaveFile(
      fileType: CusFileType.custom,
      allowedExtensions: ['json'],
      overwrite: true,
    );

    if (file == null) return;

    setState(() => _isImporting = true);
    try {
      final jsonStr = await file.readAsString();
      final jsonList = json.decode(jsonStr) as List;

      // 验证模型配置
      for (final item in jsonList) {
        if (!validateModelConfig(item)) {
          throw '模型配置格式错误';
        }
      }

      // 默认导入的json文件中是没有模型规格编号的，而该类为必要属性，所以需要先生成一个
      for (final item in jsonList) {
        item['id'] = item['model'] ?? const Uuid().v4();

        // 模型类型需要统一
        String type = item['modelType'] ?? 'cc';
        // 这几个都是cc，模型需要自行指定功能支持
        if (['cc', 'reasoner', 'vision', 'vision_reasoner'].contains(type)) {
          item['modelType'] = 'cc';
        }
      }

      // 转换为模型列表(json格式名称简单点，但和数据库中的不一致)
      // json文件只需要 platform model modelType ,其他属性猜着来
      var models = jsonList.map((e) {
        return UnifiedModelSpec(
          id: e['id'] as String,
          platformId: e['platform'] as String,
          modelName: e['model'] as String,
          displayName: e['name'] ?? capitalizeWords(e['model']),
          modelType: e['modelType'] as String,
          // 这几个默认都没有，用户自行修改
          supportsThinking: (e['supportsThinking'] as int? ?? 0) == 1,
          supportsVision: (e['supportsVision'] as int? ?? 0) == 1,
          supportsToolCalling: (e['supportsToolCalling'] as int? ?? 0) == 1,
          isActive: true,
          isBuiltIn: false,
          isFavorite: false,
          description: e['description'] as String?,
          extraConfig: e['extraConfig'] != null
              ? Map<String, dynamic>.from(json.decode(e['extraConfig']))
              : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }).toList();

      // 查询是否存在同名模型
      List<UnifiedModelSpec> duplicateModels = [];
      // 不支持的模型(按照模型类型类)
      List<UnifiedModelSpec> notSupportModels = [];
      final existModels = await _chatDao.getModelSpecs();
      for (final model in models) {
        if (existModels.any(
          (e) =>
              e.platformId == model.platformId &&
              e.modelName == model.modelName,
        )) {
          duplicateModels.add(model);
        } else {
          if (!UnifiedModelType.values.any((e) => e.name == model.modelType)) {
            notSupportModels.add(model);
          } else {
            await _chatDao.saveModelSpec(model);
          }
        }
      }

      if (!mounted) return;
      commonHintDialog(context, '导入成功', """成功导入 ${models.length} 个模型，其中
          \n ${duplicateModels.length} 个模型 [名称已存在]
          \n ${notSupportModels.length} 个模型 [类型不支持]
          \n实际导入 ${models.length - duplicateModels.length - notSupportModels.length} 个模型。
          """);

      _loadPlatforms();
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, "导入失败", e.toString());
      _loadPlatforms();
    } finally {
      setState(() => _isImporting = false);
    }
  }

  // 检测导入的json格式是否正确
  bool validateModelConfig(Map<String, dynamic> json) {
    try {
      // 验证平台是否支持（这里找不到就会报错，在catch中会抛出）
      UnifiedPlatformId.values.firstWhere(
        (e) => e.name == json['platform'],
        orElse: () => throw Exception('不支持的云平台'),
      );

      // 2025-03-07 字段验证简化一下，就平台、模型、模型类型即可
      if (json['platform'] == null ||
          (json['platform'] as String).trim().isEmpty ||
          json['model'] == null ||
          (json['model'] as String).trim().isEmpty ||
          json['modelType'] == null ||
          (json['modelType'] as String).trim().isEmpty) {
        return false;
      }

      return true;
    } catch (e) {
      rethrow;
    }
  }

  // 测试连接状态
  // 1 从缓存中获取到指定平台的密钥
  // 2 测试该平台的连接
  //  2.1 如果能连接，则更新该平台规格连接状态为true
  //  2.2 如果不能连接，则更新该平台规格连接状态为false
  Future<void> _testConnection(UnifiedPlatformSpec platform) async {
    unfocusHandle();

    try {
      // 连接测试
      final result = await _chatService.testApiConnection(
        platform.id,
        type: "text",
      );

      if (result) {
        await _chatDao.savePlatformSpec(platform.copyWith(isActive: true));
      } else {
        // 连接失败，要手动确认重置激活状态为false
        await _chatDao.savePlatformSpec(platform.copyWith(isActive: false));
        await UnifiedSecureStorage.storeApiKey(platform.id, "");
      }
    } catch (e) {
      // 连接测试报错
      await _chatDao.savePlatformSpec(platform.copyWith(isActive: false));
      ToastUtils.showError('连接测试失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _reloadBuiltInPlatforms,
            icon: const Icon(Icons.refresh),
            tooltip: '重新加载内置平台和模型',
          ),
          if (_isImporting)
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.upload_file_outlined),
              onPressed: () => _importFromJson(),
              tooltip: '导入模型配置json',
            ),

          IconButton(
            onPressed: () {
              commonMarkdwonHintDialog(
                context,
                "使用说明",
                note,
                insetPadding: const EdgeInsets.symmetric(horizontal: 16),
              );
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              // 下方有添加按钮，所以长度+1
              itemCount: _platforms.length + 1,
              itemBuilder: (context, index) {
                if (index == _platforms.length) {
                  // 添加平台按钮
                  return Container(
                    margin: const EdgeInsets.only(top: 16),
                    child: OutlinedButton.icon(
                      onPressed: _showAddPlatformDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('添加'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  );
                }

                return _buildPlatformItem(_platforms[index]);
              },
            ),
    );
  }

  Widget _buildPlatformItem(UnifiedPlatformSpec platform) {
    final isBuiltIn = platform.isBuiltIn;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: _buildPlatformIcon(platform),
        title: Text(
          platform.displayName,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        subtitle: isBuiltIn
            ? null
            : Text(
                platform.hostUrl,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (platform.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '已激活',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            if (isBuiltIn)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '内置',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
        onTap: () => _navigateToPlatformDetail(platform),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  Future<void> _showAddPlatformDialog() async {
    final result = await showDialog<UnifiedPlatformSpec>(
      context: context,
      builder: (context) => const AddPlatformDialog(),
    );

    if (result != null) {
      try {
        await _chatDao.savePlatformSpec(result);
        _loadPlatforms();
        ToastUtils.showSuccess('平台添加成功');
      } catch (e) {
        ToastUtils.showError('添加平台失败: $e');
      }
    }
  }

  void _navigateToPlatformDetail(UnifiedPlatformSpec platform) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => PlatformDetailPage(platform: platform),
          ),
        )
        .then((_) => _loadPlatforms()); // 返回时刷新列表
  }

  // 根据平台获取本地图标
  String _getPlatformIcon(
    UnifiedPlatformSpec platform, {
    bool isSmall = false,
  }) {
    var commonIcon = isSmall
        ? 'assets/platform_icons/small/'
        : 'assets/platform_icons/';
    switch (platform.id) {
      case 'lingyiwanwu':
        return '${commonIcon}lingyiwanwu.png';
      case 'deepseek':
        return '${commonIcon}deepseek.png';
      case 'zhipu':
        return '${commonIcon}zhipu.png';
      case 'baidu':
        return '${commonIcon}baidu.png';
      case 'volcengine':
      case 'volcesBot':
        return '${commonIcon}volcengine.png';
      case 'tencent':
        return '${commonIcon}tencent.png';
      case 'aliyun':
        return '${commonIcon}aliyun.png';
      case 'siliconCloud':
        return '${commonIcon}siliconcloud.png';
      case 'infini':
        return '${commonIcon}infini.png';
      default:
        return '';
    }
  }

  Widget _buildPlatformIcon(UnifiedPlatformSpec platform) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
        width: 32,
        height: 32,
        child: _getPlatformIcon(platform) != ''
            ? buildNetworkOrFileImage(_getPlatformIcon(platform, isSmall: true))
            : CircleAvatar(
                backgroundColor: Colors.blue,
                radius: 16,
                child: Text(
                  platform.displayName.isNotEmpty
                      ? platform.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(color: Colors.white),
                ),
              ),
      ),
    );
  }
}
