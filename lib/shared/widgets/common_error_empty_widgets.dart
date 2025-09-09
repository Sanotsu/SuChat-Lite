import 'package:flutter/material.dart';

/// 构建错误提示
Widget buildCommonErrorWidget({
  String? error,
  VoidCallback? onRetry,
  bool showBack = false,
  BuildContext? context,
}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text('加载失败', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
        const SizedBox(height: 8),
        Text(
          error ?? '未知错误',
          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: onRetry, child: const Text('重试')),
        if (showBack && context != null)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('返回'),
          ),
      ],
    ),
  );
}

/// 构建空数据提示
Widget buildCommonEmptyWidget({
  IconData? icon,
  String? message,
  String? subMessage,
}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon ?? Icons.person, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          message ?? '暂无数据',
          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Text(
          subMessage ?? '请稍后再试',
          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
        ),
      ],
    ),
  );
}
