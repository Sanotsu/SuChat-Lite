import 'package:flutter/material.dart';

import 'simple_tool_widget.dart';

///
/// 固定的关键字输入框行
///
class KeywordInputArea extends StatelessWidget {
  final TextEditingController searchController;
  final String hintText;
  final VoidCallback? onSearchPressed;
  final void Function(String)? textOnChanged;
  final double? height;
  final String? buttonHintText;

  const KeywordInputArea({
    super.key,
    required this.searchController,
    required this.hintText,
    this.onSearchPressed,
    this.height,
    this.buttonHintText,
    this.textOnChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? 32,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // 边框圆角
                    borderSide: const BorderSide(
                      color: Colors.blue, // 边框颜色
                      width: 2.0, // 边框宽度
                    ),
                  ),
                  contentPadding: EdgeInsets.only(left: 10),
                  // 设置透明底色
                  filled: true,
                  fillColor: Colors.transparent,
                ),
                onChanged: textOnChanged,
              ),
            ),
            SizedBox(width: 10),
            SizedBox(
              width: 80,
              child: ElevatedButton(
                style: buildFunctionButtonStyle(),
                onPressed: onSearchPressed,
                child: Text(buttonHintText ?? "搜索"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
