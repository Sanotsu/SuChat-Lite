import 'package:flutter/material.dart';

import '../../data/models/unified_model_spec.dart';

// 构建模型分类图标，更方便了解模型类型
class ModelTypeIcon extends StatelessWidget {
  final UnifiedModelType type;
  final double? size;

  const ModelTypeIcon({super.key, required this.type, this.size = 20.0});

  // 定义模型类型的颜色主题
  static Color _getColor(UnifiedModelType type) {
    switch (type) {
      case UnifiedModelType.cc:
        return Colors.blue.shade600; // 对话使用蓝色
      case UnifiedModelType.embedding:
        return Colors.purple.shade600; // 嵌入使用紫色
      case UnifiedModelType.reranker:
        return Colors.orange.shade600; // 重排使用橙色
      case UnifiedModelType.tti:
        return Colors.green.shade600; // 文生图使用绿色
      case UnifiedModelType.iti:
        return Colors.teal.shade600; // 图生图使用青色
      case UnifiedModelType.tts:
        return Colors.red.shade600; // 文本转语音使用红色
      case UnifiedModelType.asr:
        return Colors.indigo.shade600; // 语音识别使用靛蓝色
      // case UnifiedModelType.ttv:
      //   return Colors.deepOrange.shade600; // 文生视频使用深橙色
      // case UnifiedModelType.itv:
      //   return Colors.pink.shade600; // 图生视频使用粉色
    }
  }

  // 定义图标映射
  static IconData _getIcon(UnifiedModelType type) {
    switch (type) {
      case UnifiedModelType.cc:
        return Icons.chat_bubble_outline; // 对话气泡
      case UnifiedModelType.embedding:
        return Icons.integration_instructions; // 嵌入代码
      case UnifiedModelType.reranker:
        return Icons.import_export; // 排序交换
      case UnifiedModelType.tti:
        return Icons.texture; // 文字转纹理
      case UnifiedModelType.iti:
        return Icons.photo_library; // 图片库
      case UnifiedModelType.tts:
        return Icons.record_voice_over; // 语音输出
      case UnifiedModelType.asr:
        return Icons.keyboard_voice; // 语音输入
      // case UnifiedModelType.ttv:
      //   return Icons.video_camera_back; // 视频相机
      // case UnifiedModelType.itv:
      //   return Icons.slideshow; // 幻灯片播放
    }
  }

  @override
  Widget build(BuildContext context) {
    return Icon(_getIcon(type), color: _getColor(type), size: size);
  }
}

// 使用方式
Widget buildModelTypeIcon(UnifiedModelSpec model, {double? size}) {
  return ModelTypeIcon(type: model.type, size: size);
}

// 带有工具提示的增强版本
Widget buildModelTypeIconWithTooltip(UnifiedModelSpec model, {double? size}) {
  String tooltipText = _getTooltipText(model.type);

  return Tooltip(
    message: tooltipText,
    child: ModelTypeIcon(type: model.type, size: size),
  );
}

String _getTooltipText(UnifiedModelType type) {
  switch (type) {
    case UnifiedModelType.cc:
      return '对话完成模型';
    case UnifiedModelType.embedding:
      return '文本嵌入模型';
    case UnifiedModelType.reranker:
      return '重排序模型';
    case UnifiedModelType.tti:
      return '文生图模型';
    case UnifiedModelType.iti:
      return '图生图模型';
    case UnifiedModelType.tts:
      return '文本转语音';
    case UnifiedModelType.asr:
      return '语音识别';
    // case UnifiedModelType.ttv:
    //   return '文生视频';
    // case UnifiedModelType.itv:
    //   return '图生视频';
  }
}
