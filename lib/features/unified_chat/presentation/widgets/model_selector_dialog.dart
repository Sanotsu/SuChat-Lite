import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/screen_helper.dart';
import '../../data/models/unified_model_spec.dart';
import '../../data/models/unified_platform_spec.dart';
import '../../data/database/unified_chat_dao.dart';
import '../viewmodels/unified_chat_viewmodel.dart';
import 'model_type_icon.dart';
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

  /// 搜索关键词(按模型名/平台名过滤，2026-08-31 从旧版选择器补齐)
  String _searchQuery = '';

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

  @override
  Widget build(BuildContext context) {
    // 搜索过滤：匹配模型显示名/模型名/平台显示名(不区分大小写)
    final query = _searchQuery.trim().toLowerCase();
    final filteredFavorites = query.isEmpty
        ? _favoriteModels
        : _favoriteModels.where((m) => _matchesQuery(m, query)).toList();
    final filteredByPlatform = <String, List<UnifiedModelSpec>>{};
    for (final entry in _modelsByPlatform.entries) {
      if (query.isEmpty) {
        filteredByPlatform[entry.key] = entry.value;
      } else {
        final hits = entry.value.where((m) => _matchesQuery(m, query)).toList();
        if (hits.isNotEmpty) filteredByPlatform[entry.key] = hits;
      }
    }
    final hasResults =
        filteredFavorites.isNotEmpty || filteredByPlatform.isNotEmpty;

    return AlertDialog(
      title: const Text('选择模型'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      content: SizedBox(
        // 桌面限宽为紧凑弹窗，避免超宽单列(移动端满宽)
        width: ScreenHelper.isDesktop() ? 500.0 : double.maxFinite,
        height: ScreenHelper.isDesktop() ? 560.0 : 0.6.sh,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // 搜索框
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, size: 20),
                      hintText: '搜索模型或平台名称',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () =>
                                  setState(() => _searchQuery = ''),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 模型列表
                  Expanded(
                    child: hasResults
                        ? SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 收藏模型区域
                                if (filteredFavorites.isNotEmpty)
                                  _buildFavoriteSection(filteredFavorites),

                                // 按平台分组的模型
                                ...filteredByPlatform.entries.map((entry) {
                                  return _buildPlatformSection(
                                    entry.key,
                                    entry.value,
                                  );
                                }),
                              ],
                            ),
                          )
                        : const Center(child: Text('没有匹配的模型')),
                  ),
                ],
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

  /// 模型是否匹配搜索关键词
  bool _matchesQuery(UnifiedModelSpec model, String lowerQuery) {
    final platform = _platforms[model.platformId];
    return model.displayName.toLowerCase().contains(lowerQuery) ||
        model.modelName.toLowerCase().contains(lowerQuery) ||
        (platform?.displayName.toLowerCase().contains(lowerQuery) ?? false);
  }

  Widget _buildFavoriteSection(List<UnifiedModelSpec> favorites) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star, color: Colors.blue, size: 24),
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
        ...favorites.map((model) => _buildModelItem(model, inFavorite: true)),
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

  Widget _buildModelItem(UnifiedModelSpec model, {bool inFavorite = false}) {
    final isSelected = widget.currentModel?.id == model.id;

    // InkWell 提供桌面 hover 高亮与点击反馈
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      height: 36,
      child: InkWell(
        onTap: () {
          widget.onModelSelected(model);
          Navigator.of(context).pop();
        },
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey,
              width: isSelected ? 2 : 1,
            ),
            color: isSelected ? Colors.blue.withValues(alpha: 0.1) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 8),
              (inFavorite && _platforms[model.platformId] != null)
                  ? buildPlatformIcon(_platforms[model.platformId]!, size: 18)
                  // : ModelTypeIcon(type: model.type),
                  : buildModelTypeIconWithTooltip(model, size: 18),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  model.displayName,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),

              IconButton(
                onPressed: () => _toggleFavorite(model),
                style: IconButton.styleFrom(
                  minimumSize: Size(24, 24),
                  padding: EdgeInsets.zero,
                ),
                icon: Icon(
                  model.isFavorite ? Icons.star : Icons.star_border,
                  color: model.isFavorite ? Colors.blue : Colors.grey,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
