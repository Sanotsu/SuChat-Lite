import 'package:flutter/material.dart';

/// 外观设置辅助组件(2026-09-01 0.1.5 从旧版 branch_chat/_small_tool_widgets 迁入)
/// 调整对话列表中显示的文本大小(存储key与旧版共用)
void adjustTextScale(
  BuildContext context,
  double textScaleFactor,
  Function(double) onTextScaleChanged,
) async {
  var tempScaleFactor = textScaleFactor;
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('调整对话列表中文字大小', style: TextStyle(fontSize: 18)),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: tempScaleFactor,
                  min: 0.6,
                  max: 2.0,
                  divisions: 14,
                  label: tempScaleFactor.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      tempScaleFactor = value;
                    });
                  },
                ),
                Text(
                  '当前文字比例: ${tempScaleFactor.toStringAsFixed(1)}',
                  textScaler: TextScaler.linear(tempScaleFactor),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            child: const Text('取消'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('确定'),
            onPressed: () async {
              // 点击确定时，才把缩放比例存入缓存，并更新当前比例值
              onTextScaleChanged(tempScaleFactor);
            },
          ),
        ],
      );
    },
  );
}
