// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import '../components/advanced_options_bottom_sheet.dart';
import '../components/advanced_options_dialog.dart';
import '../components/advanced_options_panel.dart';
import '../components/toast_utils.dart';
import '../llm_spec/constant_llm_enum.dart';
import '../constants/advanced_options_presets.dart';
import '../utils/screen_helper.dart';

/// 高级选项结果
class AdvancedOptionsResult {
  /// 是否启用高级选项
  final bool enabled;

  /// 高级选项参数值
  final Map<String, dynamic> options;

  const AdvancedOptionsResult({required this.enabled, required this.options});
}

/// 高级选项工具类
class AdvancedOptionsUtils {
  /// 显示高级选项弹窗
  static Future<AdvancedOptionsResult?> showAdvancedOptions({
    required BuildContext context,
    required ApiPlatform platform,
    required LLModelType modelType,
    required bool currentEnabled,
    required Map<String, dynamic> currentOptions,
  }) async {
    final List<AdvancedOption> options =
        AdvancedOptionsManager.getAvailableOptions(platform, modelType);

    for (var i = 0; i < options.length; i++) {
      print('显示高级选项弹窗中的参数 $i: ${options[i].key}');
    }

    if (options.isEmpty) {
      ToastUtils.showWarning('当前模型没有可配置的高级参数');
      return null;
    }

    // 根据平台类型选择不同的显示方式
    if (ScreenHelper.isMobile()) {
      // 移动平台使用底部弹窗
      return await _showMobileBottomSheet(
        context: context,
        currentEnabled: currentEnabled,
        currentOptions: currentOptions,
        options: options,
      );
    } else {
      // 桌面平台使用对话框
      return await _showDesktopDialog(
        context: context,
        currentEnabled: currentEnabled,
        currentOptions: currentOptions,
        options: options,
      );
    }
  }

  // 在移动平台上显示底部弹窗
  static Future<AdvancedOptionsResult?> _showMobileBottomSheet({
    required BuildContext context,
    required bool currentEnabled,
    required Map<String, dynamic> currentOptions,
    required List<AdvancedOption> options,
  }) async {
    return await showModalBottomSheet<AdvancedOptionsResult>(
      context: context,
      isScrollControlled: true, // 允许弹窗内容滚动
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7, // 初始高度为屏幕的70%
          minChildSize: 0.5, // 最小高度为50%
          maxChildSize: 0.95, // 最大高度为95%
          expand: false,
          builder: (context, scrollController) {
            return AdvancedOptionsBottomSheet(
              enabled: currentEnabled,
              currentOptions: currentOptions,
              options: options,
            );
          },
        );
      },
    );
  }

  // 在桌面平台上显示对话框
  static Future<AdvancedOptionsResult?> _showDesktopDialog({
    required BuildContext context,
    required bool currentEnabled,
    required Map<String, dynamic> currentOptions,
    required List<AdvancedOption> options,
  }) async {
    return await showDialog<AdvancedOptionsResult>(
      context: context,
      builder:
          (context) => AdvancedOptionsDialog(
            enabled: currentEnabled,
            currentOptions: currentOptions,
            options: options,
          ),
    );
  }
}
