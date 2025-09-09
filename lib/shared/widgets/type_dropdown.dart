import 'package:flutter/material.dart';

import '../constants/constants.dart';
import 'cus_dropdown_button.dart';

///
/// 固定的分类下拉框
/// 已经确定类型为 CusLabel，栏位提示为"分类"
///
class TypeDropdown extends StatelessWidget {
  final CusLabel? selectedValue;
  final List<CusLabel> items;
  final String? label;
  final String? hintLabel;
  // 下拉框宽度
  final double? width;
  final Function(CusLabel?) onChanged;

  const TypeDropdown({
    super.key,
    required this.selectedValue,
    required this.items,
    this.label,
    this.hintLabel,
    this.width,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            label ?? "分类: ",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            width: width ?? 80,
            child: buildDropdownButton2<CusLabel>(
              value: selectedValue,
              items: items,
              hintLabel: hintLabel ?? "选择分类",
              onChanged: onChanged,
              itemToString: (e) => (e as CusLabel).cnLabel,
            ),
          ),
        ],
      ),
    );
  }
}
