import 'package:material_ui/material_ui.dart';
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
  return _DropdownButton2<T>(
    items: items,
    value: value,
    onChanged: onChanged,
    itemToString: itemToString,
    itemToId: itemToId,
    height: height,
    itemMaxHeight: itemMaxHeight,
    labelSize: labelSize,
    labelMaxLines: labelMaxLines,
    alignment: alignment,
    hintLabel: hintLabel,
    backgroundColor: backgroundColor,
    itemsEmptyHint: itemsEmptyHint,
  );
}

class _DropdownButton2<T> extends StatefulWidget {
  const _DropdownButton2({
    required this.items,
    this.value,
    this.onChanged,
    this.itemToString,
    this.itemToId,
    this.height,
    this.itemMaxHeight,
    this.labelSize,
    this.labelMaxLines,
    this.alignment,
    this.hintLabel,
    this.backgroundColor,
    this.itemsEmptyHint,
  });

  final List<T> items;
  final T? value;
  final Function(T?)? onChanged;
  final String Function(dynamic)? itemToString;
  final String Function(dynamic)? itemToId;
  final double? height;
  final double? itemMaxHeight;
  final double? labelSize;
  final int? labelMaxLines;
  final AlignmentGeometry? alignment;
  final String? hintLabel;
  final Color? backgroundColor;
  final String? itemsEmptyHint;

  @override
  State<_DropdownButton2<T>> createState() => _DropdownButton2State<T>();
}

class _DropdownButton2State<T> extends State<_DropdownButton2<T>> {
  late final ValueNotifier<T?> _valueListenable;

  T? _resolveValue(T? value) {
    if (value == null || widget.itemToId == null) {
      return value;
    }
    final valueId = widget.itemToId!(value);
    for (final item in widget.items) {
      if (widget.itemToId!(item) == valueId) {
        return item;
      }
    }
    return value;
  }

  @override
  void initState() {
    super.initState();
    _valueListenable = ValueNotifier<T?>(_resolveValue(widget.value));
  }

  @override
  void didUpdateWidget(covariant _DropdownButton2<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _valueListenable.value = _resolveValue(widget.value);
  }

  @override
  void dispose() {
    _valueListenable.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.black26),
          color: widget.backgroundColor ?? Colors.white,
        ),
        height: widget.height ?? 30,
        child: Center(child: Text(widget.itemsEmptyHint ?? '尚无可选列表')),
      );
    }

    return DropdownButtonHideUnderline(
      child: DropdownButton2<T>(
        isExpanded: true,
        // 提示词
        hint: Text(widget.hintLabel ?? '请选择', style: TextStyle(fontSize: 14)),
        // 下拉选择
        items: widget.items
            .map(
              (e) => DropdownItem<T>(
                value: e,
                height: 48, // 方便超过1行的模型名显示，所以设置高点
                alignment: widget.alignment ?? AlignmentDirectional.center,
                child: Text(
                  widget.itemToString != null
                      ? widget.itemToString!(e)
                      : e.toString(),
                  style: TextStyle(
                    fontSize: widget.labelSize ?? 15,
                    color: Colors.blue,
                  ),
                  maxLines: widget.labelMaxLines ?? 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        // 下拉按钮当前被选中的值
        valueListenable: _valueListenable,
        // 当值切换时触发的函数
        onChanged: widget.onChanged,
        // 默认的按钮的样式(下拉框旋转的样式)
        buttonStyleData: ButtonStyleData(
          height: widget.height ?? 30,
          // width: 190,
          padding: EdgeInsets.all(0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.black26),
            // color: Colors.blue[50],
            // color: Colors.white,
            color: widget.backgroundColor ?? Colors.white,
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
          maxHeight: widget.itemMaxHeight ?? 300,
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
          padding: EdgeInsets.symmetric(horizontal: 5),
        ),
      ),
    );
  }
}
