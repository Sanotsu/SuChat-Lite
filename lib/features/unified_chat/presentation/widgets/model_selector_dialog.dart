import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../data/models/unified_model_spec.dart';
import '../../data/models/unified_platform_spec.dart';
import '../../data/database/unified_chat_dao.dart';
import '../viewmodels/unified_chat_viewmodel.dart';
import 'platform_icon.dart';

/// 模型选择器弹窗
class ModelSelectorDialog extends StatefulWidget {
  final UnifiedModelSpec? currentModel;
  final Function(UnifiedModelSpec) onModelSelected;

  const ModelSelectorDialog({
    super.key,
    this.currentModel,
    required this.onModelSelected,
  });

  @override
  State<ModelSelectorDialog> createState() => _ModelSelectorDialogState();
}

class _ModelSelectorDialogState extends State<ModelSelectorDialog> {
  final UnifiedChatDao _chatDao = UnifiedChatDao();

  List<UnifiedModelSpec> _favoriteModels = [];
  Map<String, List<UnifiedModelSpec>> _modelsByPlatform = {};
  Map<String, UnifiedPlatformSpec> _platforms = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 加载所有激活的平台和模型(理论上我只需要获取可用的平台和模型，在这里不会更新)
      final viewModel = Provider.of<UnifiedChatViewModel>(
        context,
        listen: false,
      );

      // 不先手动刷新一下，无法获取到可用平台和模型列表（奇怪？？？）
      await viewModel.refreshPlatformsAndModels();

      // 加载平台和模型信息
      final platforms = viewModel.availablePlatforms;
      final models = viewModel.availableModels;

      final platformMap = <String, UnifiedPlatformSpec>{};
      for (final platform in platforms) {
        platformMap[platform.id] = platform;
      }

      // 分组模型
      final favoriteModels = models.where((m) => m.isFavorite).toList();
      final modelsByPlatform = <String, List<UnifiedModelSpec>>{};

      for (final model in models) {
        if (!modelsByPlatform.containsKey(model.platformId)) {
          modelsByPlatform[model.platformId] = [];
        }
        modelsByPlatform[model.platformId]!.add(model);
      }

      setState(() {
        _favoriteModels = favoriteModels;
        _modelsByPlatform = modelsByPlatform;
        _platforms = platformMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFavorite(UnifiedModelSpec model) async {
    try {
      final updatedModel = model.copyWith(isFavorite: !model.isFavorite);
      await _chatDao.saveModelSpec(updatedModel);
      _loadData();
    } catch (e) {
      // 处理错误
    }
  }

  // 如果是收藏分类，模型才显示平台图标
  Widget _buildModelItem(UnifiedModelSpec model, {bool inFavorite = false}) {
    final isSelected = widget.currentModel?.id == model.id;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected ? Colors.blue.withValues(alpha: 0.1) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 8),
        dense: true,
        leading: (inFavorite && _platforms[model.platformId] != null)
            ? buildPlatformIcon(_platforms[model.platformId]!)
            : null,
        title: Text(
          model.displayName,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            // fontSize: 12,
          ),
        ),
        trailing: IconButton(
          onPressed: () => _toggleFavorite(model),
          icon: Icon(
            model.isFavorite ? Icons.star : Icons.star_border,
            color: model.isFavorite ? Colors.blue : Colors.grey,
            size: 20,
          ),
        ),
        onTap: () {
          widget.onModelSelected(model);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Widget _buildFavoriteSection() {
    if (_favoriteModels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 8),
            Text(
              '收藏',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._favoriteModels.map(
          (model) => _buildModelItem(model, inFavorite: true),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPlatformSection(
    String platformId,
    List<UnifiedModelSpec> models,
  ) {
    final platform = _platforms[platformId];
    if (platform == null || models.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (_platforms[platformId] != null)
              buildPlatformIcon(_platforms[platformId]!),
            const SizedBox(width: 8),
            Text(
              platform.displayName.toUpperCase(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...models.map(_buildModelItem),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择模型'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      content: SizedBox(
        width: double.maxFinite,
        height: 0.6.sh,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 收藏模型区域
                    _buildFavoriteSection(),

                    // 按平台分组的模型
                    ..._modelsByPlatform.entries.map((entry) {
                      return _buildPlatformSection(entry.key, entry.value);
                    }),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ],
    );
  }
}
