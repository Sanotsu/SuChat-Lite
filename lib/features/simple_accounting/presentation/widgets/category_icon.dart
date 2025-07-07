import 'package:flutter/material.dart';

import '../../domain/entities/bill_category.dart';

/// 分类图标组件
class CategoryIcon extends StatelessWidget {
  final BillCategory category;
  final double size;
  final bool showName;
  final bool selected;
  final bool showDefaultBgColor;
  final bool showDefaultIconColor;

  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 40,
    this.showName = false,
    this.selected = false,
    this.showDefaultBgColor = true,
    this.showDefaultIconColor = false,
  });

  @override
  Widget build(BuildContext context) {
    double iSize = size;
    if (size < 24) iSize = 24;

    /// 分类在数据库中默认有颜色，如果显示默认颜色，则不显示背景色，但需要显示边框颜色

    // 根据分类类型选择颜色(收入为红色，支出为绿色)
    final Color baseColor = category.type == 0 ? Colors.red : Colors.green;

    // 背景色（选中状态时颜色更深）
    final Color backgroundColor =
        showDefaultBgColor
            ? (selected ? baseColor : baseColor.withValues(alpha: 0.5))
            : Colors.transparent;

    // 边框色（选中状态时颜色更深）
    final Color borderColor =
        showDefaultIconColor
            ? (selected ? baseColor : baseColor.withValues(alpha: 0.5))
            : Colors.transparent;

    // 图标颜色（不显示时统一为白色）
    final Color iconColor =
        showDefaultIconColor ? category.getColor() : Colors.white;

    // 获取图标
    IconData iconData = category.getIconData();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iSize,
          height: iSize,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
          ),
          child: Icon(iconData, color: iconColor, size: iSize * 0.5),
        ),
        if (showName) ...[
          SizedBox(height: 1),
          Text(
            category.name,
            style: TextStyle(
              fontSize: iSize * 0.36,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
          ),
        ],
      ],
    );
  }
}
