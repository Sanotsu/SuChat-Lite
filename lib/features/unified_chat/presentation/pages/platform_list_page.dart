import 'package:flutter/material.dart';

import '../../../../shared/widgets/image_preview_helper.dart';
import '../../../../shared/widgets/simple_tool_widget.dart';
import '../../../../shared/widgets/toast_utils.dart';
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
      print("测试连接报错$e");
      await _chatDao.savePlatformSpec(platform.copyWith(isActive: false));
    }
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
        width: 40,
        height: 40,
        child: _getPlatformIcon(platform) != ''
            ? buildNetworkOrFileImage(_getPlatformIcon(platform, isSmall: true))
            : CircleAvatar(
                backgroundColor: Colors.blue,
                radius: 20,
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
            tooltip: '刷新',
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

                final platform = _platforms[index];
                final isBuiltIn = platform.isBuiltIn;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: _buildPlatformIcon(platform),
                    title: Text(
                      platform.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: Theme.of(context).colorScheme.surface,
                  ),
                );
              },
            ),
    );
  }
}
