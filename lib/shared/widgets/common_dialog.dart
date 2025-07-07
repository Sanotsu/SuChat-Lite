import 'package:flutter/material.dart';
import '../../core/utils/screen_helper.dart';

class CommonDialog extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;

  const CommonDialog({super.key, required this.child, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ScreenHelper.isDesktop();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: width ?? screenWidth * (isDesktop ? 0.5 : 0.95),
        height: height ?? screenHeight * (isDesktop ? 0.7 : 0.8),
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
