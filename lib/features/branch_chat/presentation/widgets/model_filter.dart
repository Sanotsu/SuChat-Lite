import 'package:flutter/material.dart';

import '../../../../core/entities/cus_llm_model.dart';
import '../../../../shared/constants/constant_llm_enum.dart';

/// 模型过滤器
/// 分支的对话主页面顶部切换模型类型的组件
/// 在类型切换后，会立马触发模型选择器model_selector去选择分类后的实际模型
class ModelTypeFilter extends StatelessWidget {
  final List<CusLLMSpec> models;
  final LLModelType selectedType;
  final Function(LLModelType)? onTypeChanged;
  final VoidCallback? onModelSelect;
  final bool isStreaming;
  final List<LLModelType> supportedTypes;
  // 2025-03-25 是否使用自定义Chip
  // 简洁版不使用，高级版使用
  final bool isCusChip;

  const ModelTypeFilter({
    super.key,
    required this.models,
    required this.selectedType,
    required this.onTypeChanged,
    this.onModelSelect,
    this.isStreaming = false,
    this.supportedTypes = const [],
    this.isCusChip = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayTypes =
        supportedTypes.isEmpty ? LLModelType.values : supportedTypes;

    return Container(
      height: 40,
      padding: EdgeInsets.only(left: 8),
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children:
                  displayTypes.map((type) {
                    final count =
                        models.where((m) => m.modelType == type).length;

                    if (count > 0) {
                      return isCusChip
                          ? Center(child: _buildCusChip(context, type, count))
                          : _buildFilterChip(context, type, count);
                    }
                    return const SizedBox.shrink();
                  }).toList(),
            ),
          ),
          if (!isCusChip)
            IconButton(
              icon: const Icon(Icons.expand_more),
              onPressed: isStreaming ? null : onModelSelect,
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, LLModelType type, int count) {
    return Padding(
      padding: EdgeInsets.only(right: 8),
      // // 自定义 Chip，可以自定义内边距、标签内边距、形状
      // child: RawChip(
      //   label: Text("${MT_NAME_MAP[type]}($count)"),
      //   selected: type == selectedType,
      //   onSelected: isStreaming
      //       ? null
      //       : (_) {
      //           onTypeChanged?.call(type);
      //           onModelSelect?.call();
      //         },
      //   // 选中时颜色
      //   selectedColor: Theme.of(context).primaryColorLight,
      //   // 自定义内边距
      //   padding: EdgeInsets.all(4),
      //   // 自定义标签内边距
      //   labelPadding: EdgeInsets.symmetric(horizontal: 4),
      //   // 自定义圆弧
      //   shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.circular(8),
      //   ),
      // ),

      // 系统默认 Chip，内边距不够小
      child: FilterChip(
        // padding: EdgeInsets.all(1),
        // labelPadding: EdgeInsets.all(1),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        label: Text("${MT_NAME_MAP[type]}($count)"),
        selected: type == selectedType,
        onSelected:
            isStreaming
                ? null
                : (_) {
                  onTypeChanged?.call(type);
                  onModelSelect?.call();
                },
      ),
    );
  }

  Widget _buildCusChip(BuildContext context, LLModelType type, int count) {
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: InkWell(
        onTap:
            isStreaming
                ? null
                : () {
                  onTypeChanged?.call(type);
                  onModelSelect?.call();
                },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            // color: type == selectedType
            //     ? Theme.of(context).primaryColorLight
            //     : Colors.transparent,
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  type == selectedType
                      ? Theme.of(context).primaryColorLight
                      : Colors.transparent,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              "${MT_NAME_MAP[type]}($count)",
              style: TextStyle(
                color:
                    type == selectedType
                        ? Theme.of(context).primaryColor
                        : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );

    // 2025-03-13 使用RawChip 不知道怎么设置透明背景色，改用上面简单代替一下
    // return Padding(
    //   padding: EdgeInsets.only(right: 8),
    //   // 自定义 Chip，可以自定义内边距、标签内边距、形状

    //   child: RawChip(
    //     color:
    //         WidgetStateProperty.all<Color?>(Colors.transparent),
    //     label: Text("${MT_NAME_MAP[type]}($count)"),
    //     selected: type == selectedType,
    //     onSelected: isStreaming
    //         ? null
    //         : (_) {
    //             onTypeChanged?.call(type);
    //             onModelSelect?.call();
    //           },
    //     // 选中时颜色
    //     selectedColor: Theme.of(context).primaryColorLight,
    //     backgroundColor: Colors.transparent,
    //     // 自定义内边距
    //     padding: EdgeInsets.all(4),
    //     // 自定义标签内边距
    //     labelPadding: EdgeInsets.symmetric(horizontal: 4),
    //     // 自定义圆弧
    //     shape: RoundedRectangleBorder(
    //       borderRadius: BorderRadius.circular(8),
    //     ),
    //   ),
    // );
  }
}
