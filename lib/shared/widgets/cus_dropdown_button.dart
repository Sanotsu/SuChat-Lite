import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

///
/// 使用 DropdownButton2 构建的自定义下拉框
///
Widget buildDropdownButton2<T>({
  required List<T> items,
  T? value,
  Function(T?)? onChanged,
  // 如何从传入的类型中获取显示的字符串
  final String Function(dynamic)? itemToString,
  // 如何获取传入类型的唯一ID，用于比较是否是同一个项目
  final String Function(dynamic)? itemToId,
  // 下拉框的高度
  double? height,
  // 选项列表的最大高度
  double? itemMaxHeight,
  // 标签的字号
  double? labelSize,
  // 标签显示的最大行数
  int? labelMaxLines,
  // 标签对齐方式(默认居中，像模型列表靠左，方便对比)
  AlignmentGeometry? alignment,
  // 提示词
  String? hintLabel,
  // 背景色
  Color? backgroundColor,
  // 没有列表时的提示词
  String? itemsEmptyHint,
}) {
  if (items.isEmpty) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.black26),
        color: backgroundColor ?? Colors.white,
      ),
      height: height ?? 30,
      child: Center(child: Text(itemsEmptyHint ?? '尚无可选列表')),
    );
  }

  // 处理模型和平台对象相等性的问题
  // 如果提供了itemToId函数，则使用它来确定当前选中项
  T? selectedValue = value;
  if (value != null && itemToId != null) {
    final valueId = itemToId(value);
    // 在items列表中查找ID匹配的项
    for (var item in items) {
      if (itemToId(item) == valueId) {
        selectedValue = item;
        break;
      }
    }
  }

  return DropdownButtonHideUnderline(
    child: DropdownButton2<T>(
      isExpanded: true,
      // 提示词
      hint: Text(hintLabel ?? '请选择', style: TextStyle(fontSize: 14)),
      // 下拉选择
      items: items
          .map(
            (e) => DropdownMenuItem<T>(
              value: e,
              alignment: alignment ?? AlignmentDirectional.center,
              child: Text(
                itemToString != null ? itemToString(e) : e.toString(),
                style: TextStyle(fontSize: labelSize ?? 15, color: Colors.blue),
                maxLines: labelMaxLines ?? 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      // 下拉按钮当前被选中的值
      value: selectedValue,
      // 当值切换时触发的函数
      onChanged: onChanged,
      // 默认的按钮的样式(下拉框旋转的样式)
      buttonStyleData: ButtonStyleData(
        height: height ?? 30,
        // width: 190,
        padding: EdgeInsets.all(0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.black26),
          // color: Colors.blue[50],
          // color: Colors.white,
          color: backgroundColor ?? Colors.white,
        ),
        elevation: 0,
      ),
      // 按钮后面的图标的样式(默认也有个下三角)
      iconStyleData: IconStyleData(
        icon: const Icon(Icons.arrow_drop_down),
        iconSize: 20,
        iconEnabledColor: Colors.blue,
        iconDisabledColor: Colors.grey,
      ),
      // 下拉选项列表区域的样式
      dropdownStyleData: DropdownStyleData(
        maxHeight: itemMaxHeight ?? 300,
        // 不设置且isExpanded为true就是外部最宽
        // width: 190, // 可以根据下面的offset偏移和上面按钮的长度来调整
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Colors.white,
        ),
        // offset: const Offset(-20, 0),
        offset: const Offset(0, 0),
        scrollbarTheme: ScrollbarThemeData(
          radius: Radius.circular(40),
          thickness: WidgetStateProperty.all(6),
          thumbVisibility: WidgetStateProperty.all(true),
        ),
      ),
      // 下拉选项单个选项的样式
      menuItemStyleData: MenuItemStyleData(
        height: 48, // 方便超过1行的模型名显示，所有设置高点
        padding: EdgeInsets.symmetric(horizontal: 5),
      ),
    ),
  );
}
