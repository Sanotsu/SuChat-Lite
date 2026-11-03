import 'package:flutter/material.dart';

import '../../../../shared/widgets/image_preview_helper.dart';

/// 聊天背景组件
class ChatBackground extends StatelessWidget {
  final String? backgroundImage;
  final double opacity;

  const ChatBackground({super.key, this.backgroundImage, this.opacity = 0.35});

  @override
  Widget build(BuildContext context) {
    if (backgroundImage == null || backgroundImage!.trim().isEmpty) {
      return Container(color: Colors.transparent);
    }

    return Positioned.fill(
      child: Opacity(
        opacity: opacity,
        child: buildNetworkOrFileImage(backgroundImage!, fit: BoxFit.cover),
      ),
    );
  }
}
