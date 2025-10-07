import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/unified_model_spec.dart';
import '../../data/models/unified_platform_spec.dart';
import '../../data/database/unified_chat_dao.dart';
import '../viewmodels/unified_chat_viewmodel.dart';
import 'platform_icon.dart';

/// 模型选择器底部弹窗 - 支持收藏和分平台显示
class ModelSelectorBottomSheet extends StatefulWidget {
  final UnifiedModelSpec? currentModel;
  final Function(UnifiedModelSpec) onModelSelected;

  const ModelSelectorBottomSheet({
    super.key,
    this.currentModel,
    required this.onModelSelected,
  });

  @override
  State<ModelSelectorBottomSheet> createState() =>
      _ModelSelectorBottomSheetState();
}

class _ModelSelectorBottomSheetState extends State<ModelSelectorBottomSheet> {
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
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected ? Colors.blue.withAlpha(40) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: (inFavorite && _platforms[model.platformId] != null)
            ? buildPlatformIcon(_platforms[model.platformId]!)
            : null,
        title: Text(
          model.displayName,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
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
        ),
        ..._favoriteModels.map(
          (model) => _buildModelItem(model, inFavorite: true),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              buildPlatformIcon(platform),
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
        ),
        ...models.map(_buildModelItem),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部拖动指示器
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  '选择模型',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 内容区域
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
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
        ],
      ),
    );
  }
}
