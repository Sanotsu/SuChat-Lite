import 'package:flutter/material.dart';

import '../../../../core/utils/screen_helper.dart';
import '../../../../core/entities/cus_llm_model.dart';
import '../../../../shared/constants/constant_llm_enum.dart';

/// 平台自适应的模型选择器
/// 根据平台特性自动选择最合适的显示方式：
/// - 移动端：底部弹出式
/// - 桌面端：对话框式
class ModelSelector {
  /// 显示模型选择器
  ///
  /// [context] 上下文
  /// [models] 可用的模型列表
  /// [selectedModel] 当前选中的模型
  /// [title] 标题
  static Future<CusLLMSpec?> show({
    required BuildContext context,
    required List<CusLLMSpec> models,
    CusLLMSpec? selectedModel,
    String title = '选择模型',
  }) async {
    // 根据平台选择不同的展示方式
    if (ScreenHelper.isMobile()) {
      // 移动端使用底部弹出式
      return _showMobileSelector(
        context: context,
        models: models,
        selectedModel: selectedModel,
        title: title,
      );
    } else {
      // 桌面端使用对话框式
      return _showDesktopSelector(
        context: context,
        models: models,
        selectedModel: selectedModel,
        title: title,
      );
    }
  }

  /// 显示移动端风格的底部弹出选择器
  static Future<CusLLMSpec?> _showMobileSelector({
    required BuildContext context,
    required List<CusLLMSpec> models,
    CusLLMSpec? selectedModel,
    required String title,
  }) async {
    return showModalBottomSheet<CusLLMSpec>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder:
          (context) => SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: MobileModelSelector(
              models: models,
              selectedModel: selectedModel,
              onModelChanged: (model) => Navigator.pop(context, model),
            ),
          ),
    );
  }

  /// 显示桌面端风格的对话框选择器
  static Future<CusLLMSpec?> _showDesktopSelector({
    required BuildContext context,
    required List<CusLLMSpec> models,
    CusLLMSpec? selectedModel,
    required String title,
  }) async {
    // 计算合适的对话框尺寸
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width * 0.6; // 屏幕宽度的40%
    final dialogHeight = size.height * 0.8; // 屏幕高度的60%

    return showDialog<CusLLMSpec>(
      context: context,
      builder:
          (context) => DesktopModelSelector(
            models: models,
            selectedModel: selectedModel,
            title: title,
            width: dialogWidth,
            height: dialogHeight,
          ),
    );
  }
}

// 普通移动端模型选择器对话框
class MobileModelSelector extends StatefulWidget {
  final List<CusLLMSpec> models;
  final CusLLMSpec? selectedModel;
  final ValueChanged<CusLLMSpec?> onModelChanged;

  const MobileModelSelector({
    super.key,
    required this.models,
    this.selectedModel,
    required this.onModelChanged,
  });

  @override
  State<MobileModelSelector> createState() => _MobileModelSelectorState();
}

class _MobileModelSelectorState extends State<MobileModelSelector> {
  // 添加搜索关键字状态
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    // 监听搜索输入
    _searchController.addListener(() {
      setState(() {
        _searchKeyword = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 过滤模型列表
  List<CusLLMSpec> get _filteredModels {
    if (_searchKeyword.isEmpty) return widget.models;

    return widget.models.where((model) {
      return (model.name?.toLowerCase().contains(_searchKeyword) ?? false) ||
          (CP_NAME_MAP[model.platform]!.toLowerCase().contains(
            _searchKeyword,
          )) ||
          (model.modelType.name.toLowerCase().contains(_searchKeyword));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Text(
                  '选择模型',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索模型...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredModels.length,
              itemBuilder: (context, index) {
                final model = _filteredModels[index];
                // 自定义导入未预设平台的模型，平台名称从url中取
                var cusPlat = CP_NAME_MAP[model.platform];
                if (model.baseUrl != null && model.baseUrl!.isNotEmpty) {
                  var temps = model.baseUrl!.split('/');
                  if (temps.length > 2) {
                    cusPlat = temps[2];
                  }
                }
                return ListTile(
                  leading: SizedBox(
                    width: 32,
                    height: 32,
                    child: PlatformLogo(
                      platform: model.platform,
                      modelType: model.modelType,
                      size: Size(32, 32),
                    ),
                  ),
                  // title: Text(cusPlat ?? '<未知>'),
                  // subtitle: Column(
                  //   crossAxisAlignment: CrossAxisAlignment.start,
                  //   children: [Text(model.name ?? model.model)],
                  // ),
                  title: Text(model.name ?? model.model),
                  subtitle: Text(cusPlat ?? '<未知>'),
                  selected: model == widget.selectedModel,
                  onTap: () => widget.onModelChanged(model),
                  trailing:
                      model == widget.selectedModel
                          ? const Icon(Icons.check)
                          : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 桌面端样式的模型选择器对话框
class DesktopModelSelector extends StatefulWidget {
  final List<CusLLMSpec> models;
  final CusLLMSpec? selectedModel;
  final String title;
  final double width;
  final double height;

  const DesktopModelSelector({
    super.key,
    required this.models,
    this.selectedModel,
    required this.title,
    required this.width,
    required this.height,
  });

  @override
  State<DesktopModelSelector> createState() => _DesktopModelSelectorState();
}

class _DesktopModelSelectorState extends State<DesktopModelSelector> {
  // 添加搜索关键字状态
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';
  CusLLMSpec? _selectedModel;
  LLModelType? _selectedType;

  @override
  void initState() {
    super.initState();
    // 监听搜索输入
    _searchController.addListener(() {
      setState(() {
        _searchKeyword = _searchController.text.toLowerCase();
      });
    });

    _selectedModel = widget.selectedModel;
    _selectedType = widget.selectedModel?.modelType;

    // 如果没有选择类型，则使用模型列表中第一个模型的类型
    if (_selectedType == null && widget.models.isNotEmpty) {
      _selectedType = widget.models.first.modelType;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 过滤模型列表
  List<CusLLMSpec> get _filteredModels {
    var models = widget.models;

    // 先按类型过滤
    if (_selectedType != null) {
      models =
          models.where((model) => model.modelType == _selectedType).toList();
    }

    // 再按搜索关键字过滤
    if (_searchKeyword.isEmpty) return models;

    return models.where((model) {
      return (model.name?.toLowerCase().contains(_searchKeyword) ?? false) ||
          (CP_NAME_MAP[model.platform]!.toLowerCase().contains(
            _searchKeyword,
          )) ||
          (model.modelType.name.toLowerCase().contains(_searchKeyword));
    }).toList();
  }

  // 获取可用的模型类型列表
  List<LLModelType> get _availableTypes {
    final types = <LLModelType>{};
    for (final model in widget.models) {
      types.add(model.modelType);
    }
    // Set转List再按name排序
    return types.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: widget.width,
        height: widget.height,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 标题和关闭按钮
            Row(
              children: [
                Text(
                  widget.title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            // 搜索框
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索模型...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),

            // 模型类型选择
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    _availableTypes.map((type) {
                      final count =
                          widget.models
                              .where((m) => m.modelType == type)
                              .length;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text("${MT_NAME_MAP[type]}($count)"),
                          selected: type == _selectedType,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedType = type);
                            }
                          },
                        ),
                      );
                    }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // 模型列表
            Expanded(
              child: ListView.builder(
                itemCount: _filteredModels.length,
                itemBuilder: (context, index) {
                  final model = _filteredModels[index];

                  // 自定义导入未预设平台的模型，平台名称从url中取
                  var cusPlat = CP_NAME_MAP[model.platform];
                  if (model.baseUrl != null && model.baseUrl!.isNotEmpty) {
                    var temps = model.baseUrl!.split('/');
                    if (temps.length > 2) {
                      cusPlat = temps[2];
                    }
                  }

                  return ListTile(
                    leading: SizedBox(
                      width: 120,
                      height: 40,
                      child: PlatformLogo(
                        platform: model.platform,
                        modelType: model.modelType,
                      ),
                    ),
                    title: Text(model.name ?? model.model),
                    subtitle: Text(cusPlat ?? '<未知>'),
                    selected: model == _selectedModel,
                    selectedTileColor: Colors.grey.shade200,
                    onTap: () {
                      setState(() => _selectedModel = model);
                    },
                    trailing:
                        model == _selectedModel
                            ? Icon(
                              Icons.check,
                              color: Theme.of(context).primaryColor,
                            )
                            : null,
                  );
                },
              ),
            ),

            // 按钮
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('取消'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context, _selectedModel),
                    child: Text('确定'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 平台图标组件
/// 按优先级尝试加载：
/// 1. 本地资源图片
/// 2. 网络图片
/// 3. 占位图标
class PlatformLogo extends StatelessWidget {
  final ApiPlatform? platform;
  final LLModelType? modelType;
  final Size size;

  const PlatformLogo({
    super.key,
    required this.platform,
    this.modelType,
    this.size = const Size(120.0, 40.0),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(6),
        ),
        width: size.width,
        height: size.height,
        child: Image.asset(
          _getPlatformIcon(isSmall: size.width == size.height),
          width: size.width,
          height: size.height,
          fit: BoxFit.fitWidth,
          errorBuilder: (context, error, stackTrace) {
            // 网络图片加载失败，显示占位图标
            return Center(
              child: Icon(
                _getFallbackIcon(),
                size: size.width * 0.7,
                color: _getModelTypeColor(),
              ),
            );
          },
        ),
      ),
    );
  }

  // 根据平台获取本地图标
  String _getPlatformIcon({bool isSmall = false}) {
    var commonIcon =
        isSmall ? 'assets/platform_icons/small/' : 'assets/platform_icons/';
    switch (platform) {
      case ApiPlatform.lingyiwanwu:
        return '${commonIcon}lingyiwanwu.png';
      case ApiPlatform.deepseek:
        return '${commonIcon}deepseek.png';
      case ApiPlatform.zhipu:
        return '${commonIcon}zhipu.png';
      case ApiPlatform.baidu:
        return '${commonIcon}baidu.png';
      case ApiPlatform.volcengine:
      case ApiPlatform.volcesBot:
        return '${commonIcon}volcengine.png';
      case ApiPlatform.tencent:
        return '${commonIcon}tencent.png';
      case ApiPlatform.aliyun:
        return '${commonIcon}aliyun.png';
      case ApiPlatform.siliconCloud:
        return '${commonIcon}siliconcloud.png';
      case ApiPlatform.infini:
        return '${commonIcon}infini.png';
      default:
        return 'assets/images/no_image.png';
    }
  }

  // 获取备用图标
  IconData _getFallbackIcon() {
    switch (platform) {
      case ApiPlatform.lingyiwanwu:
        return Icons.chat_bubble_outline;
      case ApiPlatform.deepseek:
        return Icons.bolt;
      case ApiPlatform.zhipu:
        return Icons.psychology;
      case ApiPlatform.baidu:
        return Icons.cloud_outlined;
      case ApiPlatform.volcengine:
      case ApiPlatform.volcesBot:
        return Icons.rocket_launch;
      case ApiPlatform.tencent:
        return Icons.diamond_outlined;
      case ApiPlatform.aliyun:
        return Icons.auto_awesome;
      case ApiPlatform.siliconCloud:
      case ApiPlatform.infini:
        return Icons.smart_toy_outlined;
      default:
        return Icons.smart_toy;
    }
  }

  // 获取模型类型对应的颜色
  Color _getModelTypeColor() {
    switch (modelType) {
      case LLModelType.cc:
        return Colors.blue;
      case LLModelType.reasoner:
        return Colors.purple;
      case LLModelType.vision:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // 获取背景颜色
  Color _getBackgroundColor() {
    return Colors.grey.withValues(alpha: 0.1);
  }
}
